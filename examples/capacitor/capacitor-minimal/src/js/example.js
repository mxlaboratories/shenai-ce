import {
  InitializationMode,
  InitializationResult,
  ShenaiSdkCapacitor
} from "capacitor-shenai-sdk";

const env = import.meta.env ?? {};
const query = new URLSearchParams(window.location.search);
const status = document.getElementById("status");

const apiKey = env.VITE_SHENAI_API_KEY || query.get("apiKey") || "";
const userId = env.VITE_SHENAI_USER_ID || query.get("userId") || "ce-capacitor-minimal-example";
const language = env.VITE_SHENAI_LANGUAGE || query.get("language") || "en";

let initialized = false;

initializeSdk();

window.initShenai = initializeSdk;

window.addEventListener("beforeunload", () => {
  if (initialized) {
    void ShenaiSdkCapacitor.deinitialize();
  }
});

async function initializeSdk() {
  if (!apiKey) {
    status.textContent = "Missing SHENAI_API_KEY";
    return;
  }

  try {
    const result = unwrap(
      await ShenaiSdkCapacitor.initialize({
        apiKey,
        userId,
        settings: {
          initializationMode: InitializationMode.MEASUREMENT
        }
      })
    );

    if (result !== InitializationResult.OK) {
      status.textContent = `Initialization failed: ${initializationResultName(result)} (${result})`;
      return;
    }

    initialized = true;
    await ShenaiSdkCapacitor.setLanguage({ language });
    await ShenaiSdkCapacitor.setOverlaysWebview({ overlay: false }).catch(() => {});
    status.hidden = true;
  } catch (error) {
    status.textContent = error instanceof Error ? error.message : String(error);
  }
}

function unwrap(value) {
  return value && typeof value === "object" && "value" in value ? value.value : value;
}

function initializationResultName(result) {
  return InitializationResult[result] ?? String(result);
}
