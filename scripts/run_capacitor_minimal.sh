#!/bin/bash

set -euo pipefail

script_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
ce_root="$( cd "$script_dir/.." &> /dev/null && pwd )"
example_dir="$ce_root/examples/capacitor/capacitor-minimal"

platform="${CAPACITOR_PLATFORM:-android}"
device="${CAPACITOR_DEVICE:-}"
sdk_path="${SHENAI_CAPACITOR_SDK_PATH:-}"
ios_development_team="${IOS_DEVELOPMENT_TEAM:-}"
sync_only=false
cap_args=()

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
  if [[ "$platform" != "android" ]]; then
    return
  fi

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

configure_ios_signing() {
  if [[ "$platform" != "ios" || -z "$ios_development_team" ]]; then
    return
  fi

  if [[ ! "$ios_development_team" =~ ^[A-Za-z0-9]+$ ]]; then
    echo "IOS_DEVELOPMENT_TEAM should contain only letters and digits." >&2
    exit 1
  fi

  local signing_xcconfig="$example_dir/ios/App/LocalSigning.xcconfig"
  {
    echo "DEVELOPMENT_TEAM = $ios_development_team"
    echo "CODE_SIGN_STYLE = Automatic"
  } > "$signing_xcconfig"
  export XCODE_XCCONFIG_FILE="$signing_xcconfig"
}

print_usage() {
  echo "Usage: $0 [--platform android|ios] [--device <id>] [--ios-team <team-id>] [--sdk-path <path>] [--sync-only] [-- <cap args>]"
  echo
  echo "By default, the SDK package is read from:"
  echo "  examples/capacitor/capacitor-minimal/capacitor-shenai-sdk"
  echo
  echo "Environment:"
  echo "  SHENAI_API_KEY                 Required by the app at runtime."
  echo "  SHENAI_USER_ID                 Optional user ID."
  echo "  SHENAI_LANGUAGE                en, de, es, fr, or pl."
  echo "  SHENAI_CAPACITOR_SDK_PATH      Optional path to an extracted Capacitor SDK package."
  echo "  IOS_DEVELOPMENT_TEAM           Optional Apple Development Team ID for iOS CLI runs."
  echo "  CAPACITOR_PLATFORM             android or ios; defaults to android."
  echo "  CAPACITOR_DEVICE               Optional device/simulator target passed to cap run."
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
    --sync-only)
      sync_only=true
      shift
      ;;
    -h|--help)
      print_usage
      exit 0
      ;;
    --)
      shift
      cap_args+=("$@")
      break
      ;;
    *)
      cap_args+=("$1")
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
configure_ios_signing

if [[ -n "$sdk_path" ]]; then
  if [[ ! -d "$sdk_path" ]]; then
    echo "SDK path does not exist or is not a directory: $sdk_path" >&2
    exit 1
  fi

  sdk_path="$( cd "$sdk_path" &> /dev/null && pwd )"

  if [[ ! -f "$sdk_path/package.json" ]]; then
    echo "Expected an extracted Capacitor SDK package with package.json at $sdk_path" >&2
    exit 1
  fi

  if [[ -e "$example_dir/capacitor-shenai-sdk" && ! -L "$example_dir/capacitor-shenai-sdk" ]]; then
    echo "$example_dir/capacitor-shenai-sdk already exists and is not a symlink." >&2
    echo "Move it aside before passing --sdk-path." >&2
    exit 1
  fi

  rm -f "$example_dir/capacitor-shenai-sdk"
  ln -s "$sdk_path" "$example_dir/capacitor-shenai-sdk"
fi

if [[ ! -e "$example_dir/capacitor-shenai-sdk" ]]; then
  echo "Missing $example_dir/capacitor-shenai-sdk" >&2
  echo "Extract the Shen.AI (CE) Capacitor SDK into that directory before running this script." >&2
  exit 1
fi

sdk_dir="$( cd "$example_dir/capacitor-shenai-sdk" &> /dev/null && pwd -P )"

if [[ ! -f "$sdk_dir/package.json" ]]; then
  echo "Missing $sdk_dir/package.json" >&2
  echo "Use a complete extracted Shen.AI (CE) Capacitor SDK package with package.json." >&2
  exit 1
fi

if [[ ! -f "$sdk_dir/dist/esm/index.js" || ! -f "$sdk_dir/dist/plugin.cjs.js" ]]; then
  echo "Missing built Capacitor plugin files under $sdk_dir/dist" >&2
  echo "Use a complete extracted Shen.AI (CE) Capacitor SDK package that includes built JavaScript artifacts." >&2
  exit 1
fi

if [[ "$platform" == "android" && ! -f "$sdk_dir/android/libs/shenai_sdk.aar" ]]; then
  echo "Missing $sdk_dir/android/libs/shenai_sdk.aar" >&2
  echo "Use a complete extracted Shen.AI (CE) Capacitor SDK package that includes the Android AAR." >&2
  exit 1
fi

if [[ "$platform" == "ios" && ! -d "$sdk_dir/ios/ShenaiSDK.xcframework" ]]; then
  echo "Missing $sdk_dir/ios/ShenaiSDK.xcframework" >&2
  echo "Use a complete extracted Shen.AI (CE) Capacitor SDK package that includes the iOS XCFramework." >&2
  exit 1
fi

cd "$example_dir"

if [[ ! -d node_modules ]]; then
  npm install
fi

VITE_SHENAI_API_KEY="${SHENAI_API_KEY:-}" \
VITE_SHENAI_USER_ID="${SHENAI_USER_ID:-ce-capacitor-minimal-example}" \
VITE_SHENAI_LANGUAGE="${SHENAI_LANGUAGE:-en}" \
  npm run build

npx cap sync "$platform"

if [[ "$sync_only" == true ]]; then
  echo "Synced $platform project in $example_dir"
  exit 0
fi

run_args=(npx cap run "$platform")
if [[ -n "$device" ]]; then
  run_args+=("--target" "$device")
fi
if [[ ${#cap_args[@]} -gt 0 ]]; then
  run_args+=("${cap_args[@]}")
fi

"${run_args[@]}"
