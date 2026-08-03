# Shen.AI (CE) React Native minimal example

Minimal React Native app that initializes the Shen.AI (CE) SDK and renders
`ShenaiSdkView`.

## Running

Place the Shen.AI (CE) React Native SDK package at:

```text
examples/react_native/react_native_minimal/react-native-shenai-sdk
```

Then run from the repository root:

```sh
SHENAI_API_KEY=your_shenai_api_key \
  ./scripts/run_react_native_minimal.sh --platform android
```

Use `--platform ios` to run on iOS. If the SDK package is in another location,
pass `--sdk-path /path/to/react-native-shenai-sdk`.

Optional environment:

- `SHENAI_USER_ID`
- `SHENAI_LANGUAGE` (`en`, `de`, `es`, `fr`, or `pl`)
- `IOS_DEVELOPMENT_TEAM` for iOS device builds

Shen.AI (CE) always initializes in `MEASUREMENT` mode.

## Android development server

Android debug builds load JavaScript from Metro on port `8081`. The launcher
starts Metro when needed and configures:

```sh
adb reverse tcp:8081 tcp:8081
```

If an already installed app shows `Could not connect to development server`,
run the launcher again, or start Metro manually with `npm start`, run the
`adb reverse` command above, and reload the app from the React Native dev menu.
