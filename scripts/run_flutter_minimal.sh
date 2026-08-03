#!/bin/bash

set -euo pipefail

script_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
ce_root="$( cd "$script_dir/.." &> /dev/null && pwd )"
example_dir="$ce_root/examples/flutter/flutter_minimal"

device=""
sdk_path="${SHENAI_FLUTTER_SDK_PATH:-}"
flutter_args=()

print_usage() {
  echo "Usage: $0 [--device <id-or-name>] [--sdk-path <path>] [-- <flutter args>]"
  echo
  echo "Environment:"
  echo "  SHENAI_API_KEY                 Required by the app at runtime."
  echo "  SHENAI_USER_ID                 Optional user ID."
  echo "  SHENAI_LANGUAGE                en, de, es, fr, or pl."
  echo "  SHENAI_FLUTTER_SDK_PATH        Optional path to an extracted shenai_sdk Flutter package."
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
    --sdk-path)
      if [[ -z "${2:-}" ]]; then
        echo "Missing value for --sdk-path" >&2
        print_usage
        exit 1
      fi
      sdk_path="$2"
      shift 2
      ;;
    -h|--help)
      print_usage
      exit 0
      ;;
    --)
      shift
      flutter_args+=("$@")
      break
      ;;
    *)
      flutter_args+=("$1")
      shift
      ;;
  esac
done

if [[ -n "$sdk_path" ]]; then
  if [[ ! -d "$sdk_path" ]]; then
    echo "SDK path does not exist or is not a directory: $sdk_path" >&2
    exit 1
  fi

  sdk_path="$( cd "$sdk_path" &> /dev/null && pwd )"

  if [[ ! -f "$sdk_path/pubspec.yaml" ]]; then
    echo "Expected an extracted Flutter SDK package with pubspec.yaml at $sdk_path" >&2
    exit 1
  fi

  if [[ -e "$example_dir/shenai_sdk" && ! -L "$example_dir/shenai_sdk" ]]; then
    echo "$example_dir/shenai_sdk already exists and is not a symlink." >&2
    echo "Move it aside before passing --sdk-path." >&2
    exit 1
  fi

  rm -f "$example_dir/shenai_sdk"
  ln -s "$sdk_path" "$example_dir/shenai_sdk"
fi

if [[ ! -e "$example_dir/shenai_sdk" ]]; then
  echo "Missing $example_dir/shenai_sdk" >&2
  echo "Extract the Shen.AI (CE) Flutter SDK there or pass --sdk-path." >&2
  exit 1
fi

if [[ ! -f "$example_dir/shenai_sdk/pubspec.yaml" ]]; then
  echo "Missing $example_dir/shenai_sdk/pubspec.yaml" >&2
  echo "Use a complete extracted Shen.AI (CE) Flutter SDK package with pubspec.yaml." >&2
  exit 1
fi

flutter_cmd=(flutter)
if command -v fvm &> /dev/null && [[ -f "$example_dir/.fvm/fvm_config.json" ]]; then
  flutter_cmd=(fvm flutter)
  ( cd "$example_dir" && fvm install )
fi

run_args=(run)
if [[ -n "$device" ]]; then
  run_args+=("-d" "$device")
fi
run_args+=(
  "--dart-define=SHENAI_API_KEY=${SHENAI_API_KEY:-}"
  "--dart-define=SHENAI_USER_ID=${SHENAI_USER_ID:-ce-flutter-minimal-example}"
  "--dart-define=SHENAI_LANGUAGE=${SHENAI_LANGUAGE:-en}"
)
if [[ ${#flutter_args[@]} -gt 0 ]]; then
  run_args+=("${flutter_args[@]}")
fi

cd "$example_dir"
"${flutter_cmd[@]}" pub get
"${flutter_cmd[@]}" "${run_args[@]}"
