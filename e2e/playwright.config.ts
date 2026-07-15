import { defineConfig, devices } from '@playwright/test';

export default defineConfig({
  testDir: './tests',
  timeout: 30_000,
  fullyParallel: false, // serial by default — tests share DB state via live server
  forbidOnly: !!process.env.CI,
  retries: process.env.CI ? 1 : 0,
  reporter: process.env.CI ? 'github' : 'list',
  use: {
    baseURL: process.env.E2E_BASE_URL || 'http://localhost:5173',
    trace: 'on-first-retry',
  },
  projects: [
    { name: 'chromium', use: { ...devices['Desktop Chrome'] } },
  ],
  // Start dev server + backend before tests when running locally
  webServer: process.env.CI
    ? undefined
    : [
        {
          command: 'cd ../backend && uvicorn main:app --port 8001 --reload',
          url: 'http://localhost:8001/api/health',
          reuseExistingServer: true,
          timeout: 15_000,
        },
        {
          command: 'cd ../frontend && npm run dev',
          url: 'http://localhost:5173',
          reuseExistingServer: true,
          timeout: 15_000,
        },
      ],
});
