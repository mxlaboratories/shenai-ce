# Shen.AI (CE) SDK JavaScript minimal web example

This is a minimal browser example for the Shen.AI SDK.

## Running

The app expects the Web SDK package to be available as
`examples/web/js-minimal/shenai-sdk`.

From this example directory:

```sh
npm run start
```

Open the printed URL with your API key as a query parameter:

```text
http://localhost:3000/?apiKey=your_shenai_api_key
```

You can also set `userId` and `language` in the query string. Shen.AI (CE)
always uses the `MEASUREMENT` initialization mode. `language` supports `en`,
`de`, `es`, `fr`, and `pl`.

## Using the app

When the app is running you should see the measurement window and camera stream.
Messages on the screen should give you instructions how to take your first
measurement.

## Documentation

To understand better the integration with Shen.AI SDK, please see the
[Web documentation](https://developer.shen.ai/clinical/platforms/web).
