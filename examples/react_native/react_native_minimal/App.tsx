import React, { useEffect, useState } from "react"
import { SafeAreaView, StyleSheet, Text, View } from "react-native"

import {
  deinitialize,
  initialize,
  InitializationMode,
  InitializationResult,
  setLanguage,
  ShenaiSdkView
} from "react-native-shenai-sdk"

import { apiKey, language, userId } from "./ceConfig"

const App = () => {
  const [initialized, setInitialized] = useState(false)
  const [error, setError] = useState<string | null>(null)

  useEffect(() => {
    let mounted = true
    let sdkInitialized = false

    async function initSdk() {
      if (!apiKey) {
        setError("Missing SHENAI_API_KEY")
        return
      }

      const result = await initialize(apiKey, userId, {
        initializationMode: InitializationMode.MEASUREMENT
      })

      if (result === InitializationResult.OK) {
        sdkInitialized = true
        if (!mounted) {
          await deinitialize()
          sdkInitialized = false
          return
        }

        await setLanguage(language)
        if (mounted) {
          setInitialized(true)
        }
      } else {
        if (!mounted) {
          return
        }
        setError(`Initialization failed: ${result}`)
      }
    }

    initSdk().catch(err => {
      if (mounted) {
        setError(err instanceof Error ? err.message : String(err))
      }
    })

    return () => {
      mounted = false
      if (sdkInitialized) {
        void deinitialize()
      }
    }
  }, [])

  if (error) {
    return (
      <SafeAreaView style={styles.center}>
        <Text>{error}</Text>
      </SafeAreaView>
    )
  }

  if (!initialized) {
    return (
      <SafeAreaView style={styles.center}>
        <Text>Initializing SDK</Text>
      </SafeAreaView>
    )
  }

  return (
    <View style={styles.root}>
      <ShenaiSdkView style={styles.root} />
    </View>
  )
}

const styles = StyleSheet.create({
  root: {
    flex: 1
  },
  center: {
    flex: 1,
    alignItems: "center",
    justifyContent: "center"
  }
})

export default App
