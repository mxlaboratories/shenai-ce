# Shen.AI (CE) SDK examples

This repository contains minimal integration examples for the Shen.AI (CE)
SDK distribution.

Each example focuses on the smallest practical setup for one platform:
initializing the SDK with an API key in the supported `MEASUREMENT` mode and
rendering the native or web SDK UI. Platform-specific setup and run
instructions are documented in each example directory.

## Requirements

To run these examples, you need:

- a Shen.AI (CE) SDK package for the target platform
- an API key from the Shen.AI Developer Portal
- the platform toolchain required by the selected example, such as Flutter,
  Node.js, Android Studio, Xcode, CocoaPods, or .NET MAUI

For SDK documentation, visit the Shen.AI Developer Portal:

- [developer.shen.ai/clinical](https://developer.shen.ai/clinical)

## Available Examples

Runnable examples currently included in this repository:

- [JavaScript web minimal](./examples/web/js-minimal/) for browser integration
- [Android Java minimal](./examples/android/android-java-minimal/) for native
  Android integration in Java
- [Android Kotlin minimal](./examples/android/android-kotlin-minimal/) for native
  Android integration in Kotlin
- [iOS Swift minimal](./examples/ios/ios-swift-minimal/) for native iOS
  integration in Swift
- [iOS Objective-C minimal](./examples/ios/ios-objc-minimal/) for native iOS
  integration in Objective-C
- [Flutter minimal](./examples/flutter/flutter_minimal/) for Android and iOS
- [React Native minimal](./examples/react_native/react_native_minimal/) for
  Android and iOS
- [Capacitor minimal](./examples/capacitor/capacitor-minimal/) for Android and
  iOS
- [.NET MAUI minimal](./examples/maui/maui_minimal/) for Android and iOS

## Integration problems, questions and issues

For SDK integration problems or questions, contact Shen.AI through the business
channels opened as part of your contract. If the issue can be discussed
publicly, you can also use GitHub Issues.
