# Shen.AI (CE) Android Kotlin minimal example

Minimal Android Kotlin app that initializes the Shen.AI (CE) SDK and renders
`ShenAIView`.

## Running

Place the Shen.AI (CE) Android SDK AAR at:

```text
examples/android/android-kotlin-minimal/libs/shenai_sdk.aar
```

Then run from the repository root:

```sh
SHENAI_API_KEY=your_shenai_api_key \
  ./scripts/run_android_kotlin_minimal.sh
```

If the AAR is in another location, pass `--aar-path /path/to/shenai_sdk.aar`;
the launcher will link it into `libs/shenai_sdk.aar`.

Optional environment:

- `SHENAI_USER_ID`
- `SHENAI_LANGUAGE` (`en`, `de`, `es`, `fr`, or `pl`)

Shen.AI (CE) always initializes in `MEASUREMENT` mode.
