#!/bin/bash

set -euo pipefail

script_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
ce_root="$( cd "$script_dir/.." &> /dev/null && pwd )"
example_dir="$ce_root/examples/maui/maui_minimal"
project_file="$example_dir/Shenai.Ce.Maui.Minimal.csproj"
bundle_id="ai.mxlabs.shenai.ce.maui.minimal"

platform="${MAUI_PLATFORM:-android}"
device="${MAUI_DEVICE:-}"
configuration="${MAUI_CONFIGURATION:-Debug}"
sdk_path="${SHENAI_MAUI_SDK_PATH:-}"
ios_target_platform_version="${MAUI_IOS_TARGET_PLATFORM_VERSION:-18.0}"
ios_install_timeout="${MAUI_IOS_INSTALL_TIMEOUT:-180}"
build_only=false
no_run=false
dotnet_args=()

print_usage() {
  echo "Usage: $0 [--platform android|ios] [--device <id>] [--configuration <Debug|Release>] [--sdk-path <path>] [--build-only] [--no-run] [-- <dotnet build args>]"
  echo
  echo "By default, the SDK package is read from:"
  echo "  examples/maui/maui_minimal/Shenai.Maui.SDK"
  echo
  echo "Environment:"
  echo "  SHENAI_API_KEY                 Required by the app at runtime."
  echo "  SHENAI_USER_ID                 Optional user ID."
  echo "  SHENAI_LANGUAGE                en, de, es, fr, or pl."
  echo "  SHENAI_MAUI_SDK_PATH           Optional path to an extracted Shen.AI (CE) MAUI SDK package."
  echo "  MAUI_PLATFORM                  android or ios; defaults to android."
  echo "  MAUI_DEVICE                    Optional Android serial or iOS UDID."
  echo "  MAUI_CONFIGURATION             Debug or Release; defaults to Debug."
  echo "  MAUI_IOS_TARGET_PLATFORM_VERSION  Optional iOS SDK platform version; defaults to 18.0."
  echo "  MAUI_IOS_INSTALL_TIMEOUT       Optional devicectl install timeout in seconds; defaults to 180."
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
      dotnet_args+=("$@")
      break
      ;;
    *)
      dotnet_args+=("$1")
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

if ! command -v dotnet &> /dev/null; then
  echo "dotnet not found in PATH. Install .NET SDK 9 and the MAUI workload first." >&2
  exit 1
fi

if [[ -n "$sdk_path" ]]; then
  if [[ ! -d "$sdk_path" ]]; then
    echo "SDK path does not exist or is not a directory: $sdk_path" >&2
    exit 1
  fi

  sdk_path="$( cd "$sdk_path" &> /dev/null && pwd )"
  if [[ -d "$sdk_path/Shenai.Maui.SDK" && ! -f "$sdk_path/src/Shenai.Maui/Shenai.Maui.csproj" ]]; then
    sdk_path="$( cd "$sdk_path/Shenai.Maui.SDK" &> /dev/null && pwd )"
  fi

  if [[ ! -f "$sdk_path/src/Shenai.Maui/Shenai.Maui.csproj" ]]; then
    echo "Expected a MAUI SDK package at $sdk_path" >&2
    exit 1
  fi

  if [[ -e "$example_dir/Shenai.Maui.SDK" && ! -L "$example_dir/Shenai.Maui.SDK" ]]; then
    echo "$example_dir/Shenai.Maui.SDK already exists and is not a symlink." >&2
    echo "Move it aside before passing --sdk-path." >&2
    exit 1
  fi

  rm -f "$example_dir/Shenai.Maui.SDK"
  ln -s "$sdk_path" "$example_dir/Shenai.Maui.SDK"
fi

if [[ ! -e "$example_dir/Shenai.Maui.SDK" ]]; then
  echo "Missing $example_dir/Shenai.Maui.SDK" >&2
  echo "Extract the Shen.AI (CE) MAUI SDK there or pass --sdk-path." >&2
  exit 1
fi

sdk_dir="$( cd "$example_dir/Shenai.Maui.SDK" &> /dev/null && pwd -P )"

if [[ "$platform" == "android" && ! -f "$sdk_dir/src/Shenai.Android.Binding/Jars/ai.mxlabs.shenai_sdk.aar" ]]; then
  echo "Missing $sdk_dir/src/Shenai.Android.Binding/Jars/ai.mxlabs.shenai_sdk.aar" >&2
  echo "Use a complete extracted Shen.AI (CE) MAUI SDK package that includes the Android binding AAR." >&2
  exit 1
fi

if [[ "$platform" == "ios" && ! -d "$sdk_dir/src/Shenai.iOS.Binding/native/ShenaiSDK.xcframework" ]]; then
  echo "Missing $sdk_dir/src/Shenai.iOS.Binding/native/ShenaiSDK.xcframework" >&2
  echo "Use a complete extracted Shen.AI (CE) MAUI SDK package that includes the iOS XCFramework." >&2
  exit 1
fi

csharp_string() {
  local value="$1"
  value="${value//\\/\\\\}"
  value="${value//\"/\\\"}"
  value="${value//$'\r'/}"
  value="${value//$'\n'/\\n}"
  printf '"%s"' "$value"
}

api_key_literal="$(csharp_string "${SHENAI_API_KEY:-}")"
user_id_literal="$(csharp_string "${SHENAI_USER_ID:-ce-maui-minimal-example}")"
language_literal="$(csharp_string "${SHENAI_LANGUAGE:-en}")"

config_template="$(< "$example_dir/CeConfig.cs.in")"
config_template="${config_template/\"SHENAI_API_KEY_VALUE\"/$api_key_literal}"
config_template="${config_template/\"SHENAI_USER_ID_VALUE\"/$user_id_literal}"
config_template="${config_template/\"SHENAI_LANGUAGE_VALUE\"/$language_literal}"
printf "%s\n" "$config_template" > "$example_dir/CeConfig.cs"

if [[ "$no_run" == true ]]; then
  echo "Prepared MAUI example in $example_dir"
  exit 0
fi

cd "$example_dir"

framework="net9.0-$platform"
build_args=(build "$project_file" -f "$framework" "-p:TargetFramework=$framework" -c "$configuration")

if [[ "$platform" == "android" && -n "$device" ]]; then
  build_args+=("-p:AndroidDeviceSerial=$device")
elif [[ "$platform" == "ios" ]]; then
  restore_args=(restore "$project_file" "-p:TargetFramework=$framework" "-p:TargetPlatformVersion=$ios_target_platform_version" --disable-parallel)
  build_args+=("-p:TargetPlatformVersion=$ios_target_platform_version")
  if [[ -n "$device" ]]; then
    restore_args+=("-p:RuntimeIdentifier=ios-arm64")
    build_args+=("-p:RuntimeIdentifier=ios-arm64" "-p:_DeviceName=:v2:udid=$device")
  fi

  dotnet "${restore_args[@]}"
  build_args+=(--no-restore)
fi

if [[ "$build_only" != true && "$platform" != "ios" ]]; then
  build_args+=("-t:Run")
fi

if [[ ${#dotnet_args[@]} -gt 0 ]]; then
  build_args+=("${dotnet_args[@]}")
fi
dotnet "${build_args[@]}"

if [[ "$platform" == "ios" && "$build_only" != true ]]; then
  if [[ -z "$device" ]]; then
    echo "iOS device run requires --device <UDID>. Use --build-only to only build the app." >&2
    exit 1
  fi

  if ! command -v xcrun &> /dev/null; then
    echo "xcrun not found in PATH. Install Xcode command line tools first." >&2
    exit 1
  fi

  app_path="$example_dir/bin/$configuration/$framework/ios-arm64/Shenai.Ce.Maui.Minimal.app"
  if [[ ! -d "$app_path" ]]; then
    echo "Built iOS app was not found at $app_path" >&2
    exit 1
  fi

  xcrun devicectl device install app --device "$device" --timeout "$ios_install_timeout" "$app_path"
  xcrun devicectl device process launch --device "$device" --terminate-existing "$bundle_id"
fi
