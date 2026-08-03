# Shen.AI (CE) MAUI minimal example

Minimal .NET MAUI app that initializes the Shen.AI (CE) SDK and renders
`ShenaiSdkView`.

## Running

Place the Shen.AI (CE) MAUI SDK package at:

```text
examples/maui/maui_minimal/Shenai.Maui.SDK
```

From the repository root:

```sh
SHENAI_API_KEY=your_shenai_api_key \
  ./scripts/run_maui_minimal.sh --platform android
```

The Android manifest declares target SDK 35 so current Android devices do not
block the APK as an app targeting an older privacy model.

Use `--platform ios` to run on iOS. The launcher defaults to
`MAUI_IOS_TARGET_PLATFORM_VERSION=18.0`, which keeps the example compatible with
machines that have the newer .NET iOS workload installed but have not yet
updated Xcode to the newest matching version. Override it when needed, for
example `MAUI_IOS_TARGET_PLATFORM_VERSION=26.2`.

For physical iOS devices, the launcher builds the `.app` with `dotnet` and then
installs and launches it with `xcrun devicectl` to avoid long hangs in MSBuild's
`_InstallMobile` target.

If the SDK package is in another location, pass `--sdk-path /path/to/Shenai.Maui.SDK`.

Optional environment:

- `SHENAI_USER_ID`
- `SHENAI_LANGUAGE` (`en`, `de`, `es`, `fr`, or `pl`)
- `MAUI_IOS_TARGET_PLATFORM_VERSION` (defaults to `18.0`)
- `MAUI_IOS_INSTALL_TIMEOUT` (defaults to `180`)

Shen.AI (CE) always initializes in `MEASUREMENT` mode.
