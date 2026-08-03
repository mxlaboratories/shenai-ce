# Shen.AI (CE) Capacitor minimal example

This example shows the smallest practical Capacitor integration for Shen.AI
(CE):

- initialize the SDK with an API key and user ID
- use the supported `MEASUREMENT` mode and language
- display the native SDK UI from a Capacitor app

## Running

The app expects the Capacitor SDK package to be available in this directory:

```text
examples/capacitor/capacitor-minimal/capacitor-shenai-sdk
```

Extract or copy the SDK package there before running the example.

From the repository root:

```bash
SHENAI_API_KEY=your_shenai_api_key \
  ./scripts/run_capacitor_minimal.sh --platform android
```

Use `--platform ios` to run on iOS:

```bash
IOS_DEVELOPMENT_TEAM=your_apple_team_id \
SHENAI_API_KEY=your_shenai_api_key \
  ./scripts/run_capacitor_minimal.sh --platform ios
```

You can also pass the team ID as `--ios-team <team-id>`. The launcher writes it
to an ignored local Xcode config file, so the team ID is not committed.

Add `--device <device-id>` to target a specific Android device, iOS device, or
simulator. Add `--sync-only` to build the web app and sync the native project
without launching it.

Android Gradle builds should run with JDK 21 through 24. On macOS, the launcher
uses an installed JDK 21 automatically if the default Java is too new for the
Android build.

If you already have `capacitor-shenai-sdk` in
`examples/capacitor/capacitor-minimal/`, you can run the Capacitor commands
directly:

```bash
cd examples/capacitor/capacitor-minimal
npm install
VITE_SHENAI_API_KEY=your_shenai_api_key npm run build
npx cap sync android
npx cap run android
```

Set `SHENAI_USER_ID` to partition local measurement history for a specific
user. Shen.AI (CE) always initializes in `MEASUREMENT` mode. Set
`SHENAI_LANGUAGE` to `en`, `de`, `es`, `fr`, or `pl`.

If the SDK package is in another location, pass `--sdk-path <path>` to link it
as `capacitor-shenai-sdk`.
