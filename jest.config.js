module.exports = {
  collectCoverage: false,
  modulePathIgnorePatterns: [
    "<rootDir>/vendor", // don't go to the gems vendor folder. EVER.
    "<rootDir>/tmp",
    "<rootDir>/vendor",
    "<rootDir>/storage",
    "<rootDir>/log",
    "<rootDir>/.vscode",
  ],
  moduleFileExtensions: ["ts", "tsx", "js", "jsx", "json", "node"],
  setupFiles: ["<rootDir>/setupTests.js", "jest-date-mock"],
  setupFilesAfterEnv: ['jest-extended/all'],
  snapshotSerializers: ["enzyme-to-json/serializer"],
  testEnvironmentOptions: {
    enzymeAdapter: "react16",
  },
  testPathIgnorePatterns: [
    "<rootDir>/node_modules/",
    "<rootDir>/config/webpack/test.js",
    "<rootDir>/vendor/",
    "<rootDir>/tmp/",
    "<rootDir>/public/",
    "<rootDir>/storage/",
    "<rootDir>/log/",
    "<rootDir>/coverage/",
    "<rootDir>/.vscode/",
  ],
  testRegex: "(/__tests__/.*|(\\.|/)(test|spec))\\.(jsx?|tsx?)$",
  transform: {
    "^.+\\.tsx?$": "ts-jest",
  },
  transformIgnorePatterns: [
    "<rootDir>/node_modules/(?!lodash-joins/)",
    "<rootDir>/config/webpack/test.js",
    "<rootDir>/vendor/",
    "<rootDir>/tmp/",
    "<rootDir>/public/",
    "<rootDir>/storage/",
    "<rootDir>/log/",
    "<rootDir>/coverage/",
    "<rootDir>/.vscode/",
  ],
};
