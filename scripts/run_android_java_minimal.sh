#!/bin/bash

set -euo pipefail

script_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
ce_root="$( cd "$script_dir/.." &> /dev/null && pwd )"
example_dir="$ce_root/examples/android/android-java-minimal"
app_id="ai.mxlabs.shenai.ce.androidjava.minimal"

device="${ANDROID_JAVA_DEVICE:-}"
configuration="${ANDROID_JAVA_CONFIGURATION:-Debug}"
aar_path="${SHENAI_ANDROID_AAR_PATH:-}"
sdk_path="${SHENAI_ANDROID_SDK_PATH:-}"
build_only=false
no_run=false
gradle_args=()

java_major_version() {
  local java_bin="$1"
  "$java_bin" -version 2>&1 | awk -F'[\".]' '/version/ { print ($2 == "1" ? $3 : $2); exit }'
}

java_home_for_bin() {
  local java_bin="$1"
  "$java_bin" -XshowSettings:properties -version 2>&1 | awk -F'= ' '/java.home =/ { print $2; exit }'
}

is_supported_android_java_major() {
  local major="$1"
  [[ "$major" =~ ^[0-9]+$ && "$major" -ge 21 && "$major" -le 24 ]]
}

use_java_home_from_bin() {
  local java_bin="$1"
  if [[ ! -x "$java_bin" ]]; then
    return 1
  fi

  local major=""
  major="$(java_major_version "$java_bin" || true)"
  if ! is_supported_android_java_major "$major"; then
    return 1
  fi

  local detected_java_home=""
  detected_java_home="$(java_home_for_bin "$java_bin" || true)"
  if [[ -z "$detected_java_home" || ! -x "$detected_java_home/bin/java" ]]; then
    return 1
  fi

  export JAVA_HOME="$detected_java_home"
  export PATH="$JAVA_HOME/bin:$PATH"
  echo "Using JAVA_HOME=$JAVA_HOME for the Android Gradle build."
  return 0
}

configure_android_java_home() {
  local java_bin="java"
  if [[ -n "${JAVA_HOME:-}" && -x "$JAVA_HOME/bin/java" ]]; then
    java_bin="$JAVA_HOME/bin/java"
  fi

  local major=""
  major="$(java_major_version "$java_bin" || true)"
  if is_supported_android_java_major "$major"; then
    return
  fi

  if command -v java >/dev/null && use_java_home_from_bin "$(command -v java)"; then
    return
  fi

  if [[ "$(uname -s)" == "Darwin" && -x /usr/libexec/java_home ]]; then
    local java_home_21=""
    if java_home_21="$(/usr/libexec/java_home -v 21 2>/dev/null)" && use_java_home_from_bin "$java_home_21/bin/java"; then
      return
    fi

    if use_java_home_from_bin "/opt/homebrew/opt/openjdk@21/bin/java"; then
      return
    fi

    if use_java_home_from_bin "/usr/local/opt/openjdk@21/bin/java"; then
      return
    fi
  fi

  echo "Android Gradle builds require JDK 21 through 24. Set JAVA_HOME to a supported JDK if the build fails with an unsupported class file version." >&2
}

print_usage() {
  echo "Usage: $0 [--device <id>] [--configuration <Debug|Release>] [--sdk-path <path> | --aar-path <path>] [--build-only] [--no-run] [-- <gradle args>]"
  echo
  echo "By default, the SDK AAR is read from:"
  echo "  examples/android/android-java-minimal/libs/shenai_sdk.aar"
  echo
  echo "Environment:"
  echo "  SHENAI_API_KEY                 Required by the app at runtime."
  echo "  SHENAI_USER_ID                 Optional user ID."
  echo "  SHENAI_LANGUAGE                en, de, es, fr, or pl."
  echo "  SHENAI_ANDROID_AAR_PATH        Optional path to shenai_sdk.aar."
  echo "  SHENAI_ANDROID_SDK_PATH        Optional path to shenai_sdk.aar or a directory containing it."
  echo "  ANDROID_JAVA_DEVICE            Optional adb device serial."
  echo "  ANDROID_JAVA_CONFIGURATION     Debug or Release; defaults to Debug."
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --device)
      if [[ -z "${2:-}" ]]; then
        echo "Missing value for --device" >&2
        print_usage
        exit 1
      fi
      device="$2"
      shift 2
      ;;
    --configuration|-c)
      if [[ -z "${2:-}" ]]; then
        echo "Missing value for --configuration" >&2
        print_usage
        exit 1
      fi
      configuration="$2"
      shift 2
      ;;
    --sdk-path)
      if [[ -z "${2:-}" ]]; then
        echo "Missing value for --sdk-path" >&2
        print_usage
        exit 1
      fi
      sdk_path="$2"
      shift 2
      ;;
    --aar-path)
      if [[ -z "${2:-}" ]]; then
        echo "Missing value for --aar-path" >&2
        print_usage
        exit 1
      fi
      aar_path="$2"
      shift 2
      ;;
    --build-only)
      build_only=true
      shift
      ;;
    --no-run)
      no_run=true
      shift
      ;;
    -h|--help)
      print_usage
      exit 0
      ;;
    --)
      shift
      gradle_args+=("$@")
      break
      ;;
    *)
      gradle_args+=("$1")
      shift
      ;;
  esac
done

configure_android_java_home

if [[ -n "$sdk_path" && -z "$aar_path" ]]; then
  if [[ -f "$sdk_path" ]]; then
    aar_path="$sdk_path"
  elif [[ -f "$sdk_path/shenai_sdk.aar" ]]; then
    aar_path="$sdk_path/shenai_sdk.aar"
  elif [[ -f "$sdk_path/libs/shenai_sdk.aar" ]]; then
    aar_path="$sdk_path/libs/shenai_sdk.aar"
  elif [[ -f "$sdk_path/android/libs/shenai_sdk.aar" ]]; then
    aar_path="$sdk_path/android/libs/shenai_sdk.aar"
  else
    echo "Could not find shenai_sdk.aar under $sdk_path" >&2
    exit 1
  fi
fi

if [[ -n "$aar_path" ]]; then
  if [[ ! -f "$aar_path" ]]; then
    echo "AAR path does not exist or is not a file: $aar_path" >&2
    exit 1
  fi

  aar_path="$( cd "$( dirname "$aar_path" )" &> /dev/null && pwd )/$( basename "$aar_path" )"
  if [[ -e "$example_dir/libs/shenai_sdk.aar" && ! -L "$example_dir/libs/shenai_sdk.aar" ]]; then
    echo "$example_dir/libs/shenai_sdk.aar already exists and is not a symlink." >&2
    echo "Move it aside before passing --aar-path or --sdk-path." >&2
    exit 1
  fi

  mkdir -p "$example_dir/libs"
  rm -f "$example_dir/libs/shenai_sdk.aar"
  ln -s "$aar_path" "$example_dir/libs/shenai_sdk.aar"
fi

if [[ ! -f "$example_dir/libs/shenai_sdk.aar" ]]; then
  echo "Missing $example_dir/libs/shenai_sdk.aar" >&2
  echo "Extract or copy the Shen.AI (CE) Android SDK AAR into that path before running this script." >&2
  exit 1
fi

java_string() {
  local value="$1"
  value="${value//\\/\\\\}"
  value="${value//\"/\\\"}"
  value="${value//$'\r'/}"
  value="${value//$'\n'/\\n}"
  printf '"%s"' "$value"
}

api_key_literal="$(java_string "${SHENAI_API_KEY:-}")"
user_id_literal="$(java_string "${SHENAI_USER_ID:-ce-android-java-minimal-example}")"
language_literal="$(java_string "${SHENAI_LANGUAGE:-en}")"

config_template="$(< "$example_dir/src/main/java/ai/mxlabs/shenai/ce/androidjava/minimal/CeConfig.java.in")"
config_template="${config_template/\"SHENAI_API_KEY_VALUE\"/$api_key_literal}"
config_template="${config_template/\"SHENAI_USER_ID_VALUE\"/$user_id_literal}"
config_template="${config_template/\"SHENAI_LANGUAGE_VALUE\"/$language_literal}"
printf "%s\n" "$config_template" \
  > "$example_dir/src/main/java/ai/mxlabs/shenai/ce/androidjava/minimal/CeConfig.java"

if [[ "$no_run" == true ]]; then
  echo "Prepared Android Java example in $example_dir"
  exit 0
fi

variant="$(printf "%s" "$configuration" | tr '[:upper:]' '[:lower:]')"
case "$variant" in
  debug|release)
    ;;
  *)
    echo "Unsupported configuration: $configuration" >&2
    print_usage
    exit 1
    ;;
esac
task_suffix="$(printf "%s%s" "$(printf "%s" "${variant:0:1}" | tr '[:lower:]' '[:upper:]')" "${variant:1}")"

cd "$example_dir"

run_gradle() {
  local task="$1"
  if [[ ${#gradle_args[@]} -gt 0 ]]; then
    ./gradlew "$task" "${gradle_args[@]}"
  else
    ./gradlew "$task"
  fi
}

if [[ "$build_only" == true ]]; then
  run_gradle "assemble$task_suffix"
  exit 0
fi

run_gradle "install$task_suffix"

adb_args=(adb)
if [[ -n "$device" ]]; then
  adb_args+=("-s" "$device")
fi

"${adb_args[@]}" shell am start -n "$app_id/.MainActivity"
