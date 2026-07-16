import { defineConfig, devices } from '@playwright/test';

const mobile = (name: string, width: number, height: number, standalone = false) => ({
  name,
  testMatch: /mobile-matrix\.spec\.ts/,
  metadata: { standalone },
  use: {
    ...devices['Pixel 5'],
    viewport: { width, height },
  },
});

export default defineConfig({
  testDir: './tests',
  timeout: 45_000,
  fullyParallel: false,
  forbidOnly: !!process.env.CI,
  retries: process.env.CI ? 1 : 0,
  workers: process.env.CI ? 1 : undefined,
  reporter: process.env.CI ? 'github' : 'list',
  use: {
    baseURL: process.env.E2E_BASE_URL || 'http://localhost:5173',
    trace: 'on-first-retry',
  },
  projects: [
    {
      name: 'desktop-regression',
      testIgnore: /mobile-matrix\.spec\.ts/,
      use: { ...devices['Desktop Chrome'] },
    },
    mobile('mobile-360x800', 360, 800),
    mobile('mobile-375x812', 375, 812),
    mobile('mobile-430x932', 430, 932),
    mobile('mobile-landscape-844x390', 844, 390),
    mobile('pwa-standalone-375x812', 375, 812, true),
  ],
  webServer: process.env.CI
    ? undefined
    : [
        {
          command: 'cd ../backend && alembic -c alembic.ini upgrade head && uvicorn main:app --port 8001 --reload',
          url: 'http://localhost:8001/api/health',
          reuseExistingServer: true,
          timeout: 30_000,
        },
        {
          command: 'cd ../frontend && npm run dev',
          url: 'http://localhost:5173',
          reuseExistingServer: true,
          timeout: 30_000,
        },
      ],
});