# Shen.AI (CE) iOS Objective-C minimal example

Minimal Objective-C app that initializes the Shen.AI (CE) SDK and renders
`ShenaiView`.

## Running

Place the Shen.AI (CE) iOS SDK package at:

```text
examples/ios/ios-objc-minimal/ios-objc-minimal/ShenaiSDK.xcframework
```

Then run from the repository root:

```sh
SHENAI_API_KEY=your_shenai_api_key \
  ./scripts/run_ios_objc_minimal.sh
```

Pass `--device <simulator name|udid>` to install and launch; without a device
the script builds the generic iOS Simulator target.

If the SDK package is in another location, pass `--sdk-path /path/to/ShenaiSDK.xcframework`.

To build, install, and launch on a physical iPhone, pass `--platform device`
and the device UDID. If Xcode cannot infer signing automatically, also pass
`--ios-team <team-id>` or set `IOS_DEVELOPMENT_TEAM`.

Optional environment:

- `SHENAI_USER_ID`
- `SHENAI_LANGUAGE` (`en`, `de`, `es`, `fr`, or `pl`)
- `IOS_OBJC_DEVICE` (simulator name or UDID)
- `IOS_DEVELOPMENT_TEAM`

Shen.AI (CE) always initializes in `MEASUREMENT` mode.
