# Shen.AI (CE) Flutter minimal example

This example shows the smallest practical Flutter integration for Shen.AI
(CE):

- initialize the SDK with an API key and user ID
- use the supported `MEASUREMENT` initialization mode
- embed `ShenaiView`

## Running

The app expects the Flutter SDK package to be available as
`examples/flutter/flutter_minimal/shenai_sdk`. The launcher script can create
that link for you from an extracted Flutter SDK package.

From the repository root:

```sh
SHENAI_API_KEY=your_shenai_api_key \
  ./scripts/run_flutter_minimal.sh --sdk-path /path/to/shenai_sdk
```

Add `--device <device-id>` to target a specific device or simulator:

```sh
SHENAI_API_KEY=your_shenai_api_key \
  ./scripts/run_flutter_minimal.sh --sdk-path /path/to/shenai_sdk --device <device-id>
```

If you already have `shenai_sdk` in `examples/flutter/flutter_minimal/`, you can
run Flutter directly:

```sh
cd examples/flutter/flutter_minimal
flutter pub get
flutter run --dart-define=SHENAI_API_KEY=your_shenai_api_key
```

Set `SHENAI_USER_ID` to partition local measurement history for a specific
user. Shen.AI (CE) always initializes in `MEASUREMENT` mode.
Set `SHENAI_LANGUAGE` to `en`, `de`, `es`, `fr`, or `pl`.
