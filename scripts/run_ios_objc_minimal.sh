#!/bin/bash

set -euo pipefail

script_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
ce_root="$( cd "$script_dir/.." &> /dev/null && pwd )"
example_dir="$ce_root/examples/ios/ios-objc-minimal"
app_dir="$example_dir/ios-objc-minimal"
project_path="$example_dir/ios-objc-minimal.xcodeproj"
scheme="ios-objc-minimal"
bundle_id="ai.mxlabs.shenai.ce.iosobjc.minimal"
config_template_path="$app_dir/CeConfig.h.in"
config_path="$app_dir/CeConfig.h"

device="${IOS_OBJC_DEVICE:-}"
platform="${IOS_OBJC_PLATFORM:-simulator}"
configuration="${IOS_OBJC_CONFIGURATION:-Debug}"
ios_development_team="${IOS_DEVELOPMENT_TEAM:-}"
sdk_path="${SHENAI_IOS_SDK_PATH:-}"
xcframework_path="${SHENAI_IOS_SDK_XCFRAMEWORK:-}"
framework_path="${SHENAI_IOS_SDK_FRAMEWORK:-}"
build_only=false
no_run=false
xcodebuild_args=()

print_usage() {
  echo "Usage: $0 [--device <simulator name|udid>] [--platform <simulator|device>] [--ios-team <team-id>] [--configuration <Debug|Release>] [--sdk-path <path> | --xcframework-path <path> | --framework-path <path>] [--build-only] [--no-run] [-- <xcodebuild args>]"
  echo
  echo "By default, the SDK package is read from:"
  echo "  examples/ios/ios-objc-minimal/ios-objc-minimal/ShenaiSDK.xcframework"
  echo
  echo "Environment:"
  echo "  SHENAI_API_KEY                 Required by the app at runtime."
  echo "  SHENAI_USER_ID                 Optional user ID."
  echo "  SHENAI_LANGUAGE                en, de, es, fr, or pl."
  echo "  SHENAI_IOS_SDK_PATH            Optional path to ShenaiSDK.xcframework/framework or a directory containing it."
  echo "  SHENAI_IOS_SDK_XCFRAMEWORK     Optional path to ShenaiSDK.xcframework."
  echo "  SHENAI_IOS_SDK_FRAMEWORK       Optional path to a platform-specific ShenaiSDK.framework."
  echo "  IOS_OBJC_DEVICE                Optional simulator name or UDID."
  echo "  IOS_OBJC_PLATFORM              simulator or device; defaults to simulator."
  echo "  IOS_OBJC_CONFIGURATION         Debug or Release; defaults to Debug."
  echo "  IOS_DEVELOPMENT_TEAM           Optional Apple Development Team ID for device builds."
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
    --platform)
      if [[ -z "${2:-}" ]]; then
        echo "Missing value for --platform" >&2
        print_usage
        exit 1
      fi
      platform="$2"
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
    --xcframework-path)
      if [[ -z "${2:-}" ]]; then
        echo "Missing value for --xcframework-path" >&2
        print_usage
        exit 1
      fi
      xcframework_path="$2"
      shift 2
      ;;
    --framework-path)
      if [[ -z "${2:-}" ]]; then
        echo "Missing value for --framework-path" >&2
        print_usage
        exit 1
      fi
      framework_path="$2"
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
      xcodebuild_args+=("$@")
      break
      ;;
    *)
      xcodebuild_args+=("$1")
      shift
      ;;
  esac
done

case "$configuration" in
  Debug|Release)
    ;;
  debug)
    configuration="Debug"
    ;;
  release)
    configuration="Release"
    ;;
  *)
    echo "Unsupported configuration: $configuration" >&2
    print_usage
    exit 1
    ;;
esac

case "$platform" in
  simulator|device)
    ;;
  *)
    echo "Unsupported platform: $platform" >&2
    print_usage
    exit 1
    ;;
esac

if [[ -z "$sdk_path" && -z "$xcframework_path" && -z "$framework_path" ]]; then
  if [[ -d "$app_dir/ShenaiSDK.xcframework" ]]; then
    xcframework_path="$app_dir/ShenaiSDK.xcframework"
  elif [[ -d "$app_dir/ShenaiSDK.framework" ]]; then
    framework_path="$app_dir/ShenaiSDK.framework"
  fi
fi

if [[ -n "$sdk_path" && -z "$xcframework_path" && -z "$framework_path" ]]; then
  if [[ -d "$sdk_path" && "$( basename "$sdk_path" )" == "ShenaiSDK.xcframework" ]]; then
    xcframework_path="$sdk_path"
  elif [[ -d "$sdk_path" && "$( basename "$sdk_path" )" == "ShenaiSDK.framework" ]]; then
    framework_path="$sdk_path"
  elif [[ -d "$sdk_path/ShenaiSDK.xcframework" ]]; then
    xcframework_path="$sdk_path/ShenaiSDK.xcframework"
  elif [[ -d "$sdk_path/ShenaiSDK.framework" ]]; then
    framework_path="$sdk_path/ShenaiSDK.framework"
  elif [[ -d "$sdk_path/ios/ShenaiSDK.xcframework" ]]; then
    xcframework_path="$sdk_path/ios/ShenaiSDK.xcframework"
  elif [[ -d "$sdk_path/ios/ShenaiSDK.framework" ]]; then
    framework_path="$sdk_path/ios/ShenaiSDK.framework"
  else
    echo "Could not find ShenaiSDK.xcframework or ShenaiSDK.framework under $sdk_path" >&2
    exit 1
  fi
fi

select_framework_from_xcframework() {
  local xcframework="$1"
  local selected=""

  if [[ "$platform" == "simulator" ]]; then
    selected="$( find "$xcframework" -path "*/ShenaiSDK.framework" -type d | grep -E "(simulator|ios-arm64_x86_64-simulator|ios-arm64-simulator)" | head -n 1 || true )"
  else
    selected="$( find "$xcframework" -path "*/ShenaiSDK.framework" -type d | grep -Ev "(simulator)" | head -n 1 || true )"
  fi

  if [[ -z "$selected" ]]; then
    echo "Could not find a $platform ShenaiSDK.framework slice in $xcframework" >&2
    exit 1
  fi

  printf "%s" "$selected"
}

if [[ -n "$xcframework_path" ]]; then
  if [[ ! -d "$xcframework_path" ]]; then
    echo "XCFramework path does not exist or is not a directory: $xcframework_path" >&2
    exit 1
  fi
  framework_path="$( select_framework_from_xcframework "$xcframework_path" )"
fi

if [[ -n "$framework_path" ]]; then
  if [[ ! -d "$framework_path" ]]; then
    echo "Framework path does not exist or is not a directory: $framework_path" >&2
    exit 1
  fi

  framework_path="$( cd "$( dirname "$framework_path" )" &> /dev/null && pwd )/$( basename "$framework_path" )"
  if [[ -e "$app_dir/ShenaiSDK.framework" && ! -L "$app_dir/ShenaiSDK.framework" ]]; then
    echo "$app_dir/ShenaiSDK.framework already exists and is not a symlink." >&2
    echo "Move it aside before passing --framework-path, --xcframework-path, or --sdk-path." >&2
    exit 1
  fi

  rm -f "$app_dir/ShenaiSDK.framework"
  ln -s "$framework_path" "$app_dir/ShenaiSDK.framework"
fi

if [[ ! -d "$app_dir/ShenaiSDK.framework" ]]; then
  echo "Missing $app_dir/ShenaiSDK.framework" >&2
  echo "Extract the Shen.AI (CE) iOS SDK to $app_dir/ShenaiSDK.xcframework, or pass --framework-path, --xcframework-path, or --sdk-path." >&2
  exit 1
fi

framework_build_settings=()
framework_binary="$app_dir/ShenaiSDK.framework/ShenaiSDK"
if [[ "$platform" == "simulator" && -f "$framework_binary" ]] && command -v lipo >/dev/null 2>&1; then
  framework_archs="$( lipo -archs "$framework_binary" 2>/dev/null || true )"
  case "$framework_archs" in
    arm64)
      framework_build_settings+=("ARCHS=arm64")
      ;;
    x86_64)
      framework_build_settings+=("ARCHS=x86_64")
      ;;
  esac
fi

signing_build_settings=()
if [[ -n "$ios_development_team" ]]; then
  if [[ ! "$ios_development_team" =~ ^[A-Za-z0-9]+$ ]]; then
    echo "IOS_DEVELOPMENT_TEAM should contain only letters and digits." >&2
    exit 1
  fi
  signing_build_settings+=("DEVELOPMENT_TEAM=$ios_development_team" "CODE_SIGN_STYLE=Automatic")
fi

objc_string() {
  local value="$1"
  value="${value//\\/\\\\}"
  value="${value//\"/\\\"}"
  value="${value//$'\r'/}"
  value="${value//$'\n'/\\n}"
  printf '@"%s"' "$value"
}

api_key_literal="$(objc_string "${SHENAI_API_KEY:-}")"
user_id_literal="$(objc_string "${SHENAI_USER_ID:-ce-ios-objc-minimal-example}")"
language_literal="$(objc_string "${SHENAI_LANGUAGE:-en}")"

config_template="$(< "$config_template_path")"
config_template="${config_template/@\"SHENAI_API_KEY_VALUE\"/$api_key_literal}"
config_template="${config_template/@\"SHENAI_USER_ID_VALUE\"/$user_id_literal}"
config_template="${config_template/@\"SHENAI_LANGUAGE_VALUE\"/$language_literal}"
printf "%s\n" "$config_template" > "$config_path"

if [[ "$no_run" == true ]]; then
  echo "Prepared iOS Objective-C example in $example_dir"
  exit 0
fi

destination=()
simulator_id="$device"
if [[ "$platform" == "simulator" ]]; then
  if [[ -n "$device" ]]; then
    if [[ "$device" =~ ^[0-9A-Fa-f-]{36}$ ]]; then
      destination=(-destination "platform=iOS Simulator,id=$device")
    else
      destination=(-destination "platform=iOS Simulator,name=$device")
    fi
  else
    destination=(-destination "generic/platform=iOS Simulator")
    build_only=true
  fi
else
  if [[ -n "$device" ]]; then
    destination=(-destination "platform=iOS,id=$device")
  else
    destination=(-destination "generic/platform=iOS")
    build_only=true
  fi
fi

cd "$example_dir"

xcodebuild_command=(
  xcodebuild
  -project "$project_path" \
  -scheme "$scheme" \
  -configuration "$configuration" \
  -derivedDataPath "$example_dir/DerivedData" \
  "${destination[@]}" \
  build
)

if [[ ${#framework_build_settings[@]} -gt 0 ]]; then
  xcodebuild_command+=("${framework_build_settings[@]}")
fi

if [[ ${#signing_build_settings[@]} -gt 0 ]]; then
  xcodebuild_command+=("${signing_build_settings[@]}")
fi

if [[ ${#xcodebuild_args[@]} -gt 0 ]]; then
  xcodebuild_command+=("${xcodebuild_args[@]}")
fi

"${xcodebuild_command[@]}"

if [[ "$build_only" == true ]]; then
  exit 0
fi

if [[ "$platform" != "simulator" ]]; then
  if [[ -z "$device" ]]; then
    echo "Built the iOS device app. Pass --device <udid> to install and launch it from this script." >&2
    exit 0
  fi

  app_path="$example_dir/DerivedData/Build/Products/$configuration-iphoneos/$scheme.app"
  if [[ ! -d "$app_path" ]]; then
    echo "Built app not found at $app_path" >&2
    exit 1
  fi

  xcrun devicectl device install app --device "$device" "$app_path"
  xcrun devicectl device process launch --device "$device" "$bundle_id"
  exit 0
fi

if [[ -z "$simulator_id" ]]; then
  echo "Built the simulator app. Pass --device <simulator name|udid> to install and launch it." >&2
  exit 0
fi

app_path="$example_dir/DerivedData/Build/Products/$configuration-iphonesimulator/$scheme.app"
if [[ ! -d "$app_path" ]]; then
  echo "Built app not found at $app_path" >&2
  exit 1
fi

xcrun simctl boot "$simulator_id" >/dev/null 2>&1 || true
xcrun simctl install "$simulator_id" "$app_path"
xcrun simctl launch "$simulator_id" "$bundle_id"
