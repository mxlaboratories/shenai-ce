const { getDefaultConfig, mergeConfig } = require("@react-native/metro-config");
const fs = require("fs");
const path = require("path");

const sdkPath = path.resolve(__dirname, "react-native-shenai-sdk");

/**
 * Metro configuration
 * https://facebook.github.io/metro/docs/configuration
 *
 * @type {import('metro-config').MetroConfig}
 */
const config = {
  resolver: {
    // If you have other resolver settings, they would go here as well.
    extraNodeModules: new Proxy(
      {},
      {
        get: (target, name) => {
          // This redirects all modules to your project's node_modules, not just 'react'
          return path.join(process.cwd(), `node_modules/${name}`);
        }
      }
    )
  },
  watchFolders: [sdkPath].filter((folder) => fs.existsSync(folder))
};

module.exports = mergeConfig(getDefaultConfig(__dirname), config);
