#!/bin/bash

set -euo pipefail

script_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
ce_root="$( cd "$script_dir/.." &> /dev/null && pwd )"
example_dir="$ce_root/examples/react_native/react_native_minimal"

platform="${REACT_NATIVE_PLATFORM:-android}"
device="${REACT_NATIVE_DEVICE:-}"
ios_development_team="${IOS_DEVELOPMENT_TEAM:-}"
sdk_path="${SHENAI_REACT_NATIVE_SDK_PATH:-}"
no_run=false
rn_args=()
metro_port="${REACT_NATIVE_METRO_PORT:-8081}"
metro_log_path="${REACT_NATIVE_METRO_LOG:-/tmp/shenai-react-native-metro.log}"

java_major_version() {
  local java_bin="$1"
  "$java_bin" -version 2>&1 | awk -F'[\".]' '/version/ { print ($2 == "1" ? $3 : $2); exit }'
}

java_home_for_bin() {
  local java_bin="$1"
  "$java_bin" -XshowSettings:properties -version 2>&1 | awk -F'= ' '/java.home =/ { print $2; exit }'
}

is_supported_react_native_java_major() {
  local major="$1"
  [[ "$major" =~ ^[0-9]+$ && "$major" -ge 17 && "$major" -le 20 ]]
}

use_java_home_from_bin() {
  local java_bin="$1"
  if [[ ! -x "$java_bin" ]]; then
    return 1
  fi

  local major=""
  major="$(java_major_version "$java_bin" || true)"
  if ! is_supported_react_native_java_major "$major"; then
    return 1
  fi

  local detected_java_home=""
  detected_java_home="$(java_home_for_bin "$java_bin" || true)"
  if [[ -z "$detected_java_home" || ! -x "$detected_java_home/bin/java" ]]; then
    return 1
  fi

  export JAVA_HOME="$detected_java_home"
  export PATH="$JAVA_HOME/bin:$PATH"
  echo "Using JAVA_HOME=$JAVA_HOME for the React Native Android build."
  return 0
}

configure_android_java_home() {
  if [[ "$platform" != "android" ]]; then
    return
  fi

  local java_bin="java"
  if [[ -n "${JAVA_HOME:-}" && -x "$JAVA_HOME/bin/java" ]]; then
    java_bin="$JAVA_HOME/bin/java"
  fi

  local major=""
  major="$(java_major_version "$java_bin" || true)"
  if is_supported_react_native_java_major "$major"; then
    return
  fi

  if command -v java >/dev/null && use_java_home_from_bin "$(command -v java)"; then
    return
  fi

  if [[ "$(uname -s)" == "Darwin" && -x /usr/libexec/java_home ]]; then
    local java_home_17=""
    if java_home_17="$(/usr/libexec/java_home -v 17 2>/dev/null)" && use_java_home_from_bin "$java_home_17/bin/java"; then
      return
    fi

    if use_java_home_from_bin "/opt/homebrew/opt/openjdk@17/bin/java"; then
      return
    fi

    if use_java_home_from_bin "/usr/local/opt/openjdk@17/bin/java"; then
      return
    fi
  fi

  echo "React Native Android builds with this Gradle wrapper require JDK 17 through 20. Set JAVA_HOME to a supported JDK if the build fails." >&2
}

configure_ios_signing() {
  if [[ "$platform" != "ios" || -z "$ios_development_team" ]]; then
    return
  fi

  if [[ ! "$ios_development_team" =~ ^[A-Za-z0-9]+$ ]]; then
    echo "IOS_DEVELOPMENT_TEAM should contain only letters and digits." >&2
    exit 1
  fi

  local signing_xcconfig="$example_dir/ios/LocalSigning.xcconfig"
  {
    echo "DEVELOPMENT_TEAM = $ios_development_team"
    echo "CODE_SIGN_STYLE = Automatic"
  } > "$signing_xcconfig"
  export XCODE_XCCONFIG_FILE="$signing_xcconfig"
}

configure_ios_toolchain() {
  if [[ "$platform" != "ios" ]]; then
    return
  fi

  unset CC CXX CPP LD AR NM RANLIB
  unset CFLAGS CXXFLAGS CPPFLAGS LDFLAGS
}

print_usage() {
  echo "Usage: $0 [--platform android|ios] [--device <id>] [--ios-team <team-id>] [--sdk-path <path>] [--no-run] [-- <react-native args>]"
  echo
  echo "By default, the SDK package is read from:"
  echo "  examples/react_native/react_native_minimal/react-native-shenai-sdk"
  echo
  echo "Environment:"
  echo "  SHENAI_API_KEY                 Required by the app at runtime."
  echo "  SHENAI_USER_ID                 Optional user ID."
  echo "  SHENAI_LANGUAGE                en, de, es, fr, or pl."
  echo "  SHENAI_REACT_NATIVE_SDK_PATH   Optional path to an extracted React Native SDK package."
  echo "  IOS_DEVELOPMENT_TEAM           Optional Apple Development Team ID for iOS CLI runs."
  echo "  REACT_NATIVE_PLATFORM          android or ios; defaults to android."
  echo "  REACT_NATIVE_DEVICE            Optional device ID passed to react-native run-*."
  echo "  REACT_NATIVE_METRO_PORT        Optional Metro port for Android debug builds; defaults to 8081."
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --platform)
      if [[ -z "${2:-}" ]]; then
        echo "Missing value for --platform" >&2
        print_usage
        exit 1
      fi
      platform="$2"
      shift 2
      ;;
    --device)
      if [[ -z "${2:-}" ]]; then
        echo "Missing value for --device" >&2
        print_usage
        exit 1
      fi
      device="$2"
      shift 2
      ;;
    --ios-team)
      if [[ -z "${2:-}" ]]; then
        echo "Missing value for --ios-team" >&2
        print_usage
        exit 1
      fi
      ios_development_team="$2"
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
      rn_args+=("$@")
      break
      ;;
    *)
      rn_args+=("$1")
      shift
      ;;
  esac
done

case "$platform" in
  android|ios)
    ;;
  *)
    echo "Unsupported platform: $platform" >&2
    print_usage
    exit 1
    ;;
esac

configure_android_java_home
configure_ios_toolchain
configure_ios_signing

if [[ -n "$sdk_path" ]]; then
  if [[ ! -d "$sdk_path" ]]; then
    echo "SDK path does not exist or is not a directory: $sdk_path" >&2
    exit 1
  fi

  sdk_path="$( cd "$sdk_path" &> /dev/null && pwd )"

  if [[ ! -f "$sdk_path/package.json" ]]; then
    echo "Expected an extracted React Native SDK package with package.json at $sdk_path" >&2
    exit 1
  fi

  if [[ -e "$example_dir/react-native-shenai-sdk" && ! -L "$example_dir/react-native-shenai-sdk" ]]; then
    echo "$example_dir/react-native-shenai-sdk already exists and is not a symlink." >&2
    echo "Move it aside before passing --sdk-path." >&2
    exit 1
  fi

  rm -f "$example_dir/react-native-shenai-sdk"
  ln -s "$sdk_path" "$example_dir/react-native-shenai-sdk"
fi

if [[ ! -e "$example_dir/react-native-shenai-sdk" ]]; then
  echo "Missing $example_dir/react-native-shenai-sdk" >&2
  echo "Extract the Shen.AI (CE) React Native SDK there or pass --sdk-path." >&2
  exit 1
fi

json_string() {
  node -e 'process.stdout.write(JSON.stringify(process.argv[1] ?? ""))' "$1"
}

write_config() {
  local api_key_json user_id_json language_json config_template
  api_key_json="$(json_string "${SHENAI_API_KEY:-}")"
  user_id_json="$(json_string "${SHENAI_USER_ID:-ce-react-native-minimal-example}")"
  language_json="$(json_string "${SHENAI_LANGUAGE:-en}")"

  config_template="$(< "$example_dir/ceConfig.ts.in")"
  config_template="${config_template/\"SHENAI_API_KEY_VALUE\"/$api_key_json}"
  config_template="${config_template/\"SHENAI_USER_ID_VALUE\"/$user_id_json}"
  config_template="${config_template/\"SHENAI_LANGUAGE_VALUE\"/$language_json}"
  printf "%s\n" "$config_template" > "$example_dir/ceConfig.ts"
}

install_node_deps() {
  local dir="$1"
  if command -v yarn &> /dev/null && [[ -f "$dir/yarn.lock" ]]; then
    ( cd "$dir" && yarn install --check-files )
  else
    ( cd "$dir" && npm install --no-fund --no-audit )
  fi
}

metro_is_running() {
  if ! command -v curl >/dev/null 2>&1; then
    return 1
  fi

  local status=""
  status="$(curl -fsS "http://localhost:$metro_port/status" 2>/dev/null || true)"
  [[ "$status" == *"packager-status:running"* ]]
}

start_metro_if_needed() {
  if [[ "$platform" != "android" ]]; then
    return
  fi

  if metro_is_running; then
    echo "Metro is already running on port $metro_port."
    return
  fi

  echo "Starting Metro on port $metro_port. Logs: $metro_log_path"
  ( cd "$example_dir" && nohup npx react-native start --port "$metro_port" --host 0.0.0.0 > "$metro_log_path" 2>&1 & )

  local attempt
  for attempt in 1 2 3 4 5 6 7 8 9 10; do
    sleep 1
    if metro_is_running; then
      echo "Metro is ready on port $metro_port."
      return
    fi
  done

  echo "Metro did not report ready on port $metro_port yet. Check $metro_log_path if the app cannot load JavaScript." >&2
}

find_adb() {
  if command -v adb >/dev/null 2>&1; then
    command -v adb
    return
  fi

  local sdk_root
  for sdk_root in "${ANDROID_HOME:-}" "${ANDROID_SDK_ROOT:-}"; do
    if [[ -n "$sdk_root" && -x "$sdk_root/platform-tools/adb" ]]; then
      echo "$sdk_root/platform-tools/adb"
      return
    fi
  done

  return 1
}

configure_android_debug_server() {
  if [[ "$platform" != "android" ]]; then
    return
  fi

  local adb_bin=""
  if ! adb_bin="$(find_adb)"; then
    echo "adb was not found. If the app cannot connect to Metro, run adb reverse tcp:$metro_port tcp:$metro_port after installing Android platform tools." >&2
    return
  fi

  local adb_args=("$adb_bin")
  if [[ -n "$device" ]]; then
    adb_args+=("-s" "$device")
  fi

  if "${adb_args[@]}" reverse "tcp:$metro_port" "tcp:$metro_port"; then
    echo "Configured adb reverse tcp:$metro_port tcp:$metro_port."
  else
    echo "Could not configure adb reverse before launch. If an emulator starts later, rerun this script or run adb reverse tcp:$metro_port tcp:$metro_port manually." >&2
  fi
}

sdk_dir="$( cd "$example_dir/react-native-shenai-sdk" &> /dev/null && pwd -P )"

if [[ ! -f "$sdk_dir/package.json" ]]; then
  echo "Missing $sdk_dir/package.json" >&2
  echo "Use a complete extracted Shen.AI (CE) React Native SDK package with package.json." >&2
  exit 1
fi

write_config

if [[ ! -f "$sdk_dir/lib/module/index.js" ]]; then
  echo "Missing $sdk_dir/lib/module/index.js" >&2
  echo "Use a complete extracted Shen.AI (CE) React Native SDK package that includes built JavaScript artifacts." >&2
  exit 1
fi

if [[ "$platform" == "android" && ! -f "$sdk_dir/android/libs/shenai_sdk.aar" ]]; then
  echo "Missing $sdk_dir/android/libs/shenai_sdk.aar" >&2
  echo "Use a complete extracted Shen.AI (CE) React Native SDK package that includes the Android AAR." >&2
  exit 1
fi

if [[ "$platform" == "ios" && ! -d "$sdk_dir/ios/ShenaiSDK.xcframework" ]]; then
  echo "Missing $sdk_dir/ios/ShenaiSDK.xcframework" >&2
  echo "Use a complete extracted Shen.AI (CE) React Native SDK package that includes the iOS XCFramework." >&2
  exit 1
fi

if [[ "$no_run" == true ]]; then
  echo "Prepared React Native example in $example_dir"
  exit 0
fi

if [[ ! -d "$example_dir/node_modules" ]]; then
  install_node_deps "$example_dir"
fi

cd "$example_dir"

if [[ "$platform" == "ios" ]]; then
  ( cd ios && pod install )
  run_args=(npx react-native run-ios)
  if [[ -n "$device" ]]; then
    run_args+=("--udid" "$device")
  fi
else
  start_metro_if_needed
  configure_android_debug_server
  run_args=(npx react-native run-android)
  if [[ -n "$device" ]]; then
    run_args+=("--deviceId" "$device")
  fi
fi

if [[ ${#rn_args[@]} -gt 0 ]]; then
  run_args+=("${rn_args[@]}")
fi
"${run_args[@]}"

if [[ "$platform" == "android" ]]; then
  configure_android_debug_server
  echo "If the Android app was already open with a development-server error, reload it from the React Native dev menu."
fi
