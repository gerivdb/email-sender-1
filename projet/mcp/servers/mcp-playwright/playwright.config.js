const config = {
  use: {
    headless: false,
    viewport: { width: 1280, height: 720 },
    launchOptions: {
      slowMo: 100
    }
  },
  testDir: './',
  reporter: 'list'
};

module.exports = config;
