import { defineConfig, devices } from '@playwright/test';

export default defineConfig({
  testDir: './tests',
  timeout: 30_000,
  fullyParallel: false,
  workers: 1,
  forbidOnly: !!process.env.CI,
  retries: process.env.CI ? 1 : 0,
  reporter: process.env.CI ? 'github' : 'list',
  use: { baseURL: process.env.E2E_BASE_URL || 'http://localhost:5173', trace: 'on-first-retry' },
  projects: [
    { name: 'chromium', use: { ...devices['Desktop Chrome'] } },
    { name: 'mobile-360x800', testMatch: '**/mobile-matrix.spec.ts', use: { ...devices['Pixel 5'], viewport: { width: 360, height: 800 } } },
    { name: 'mobile-375x812', testMatch: '**/mobile-matrix.spec.ts', use: { ...devices['iPhone 12'], viewport: { width: 375, height: 812 } } },
    { name: 'mobile-430x932', testMatch: '**/mobile-matrix.spec.ts', use: { ...devices['iPhone 14 Pro Max'], viewport: { width: 430, height: 932 } } },
    { name: 'mobile-landscape-844x390', testMatch: '**/mobile-matrix.spec.ts', use: { ...devices['iPhone 12'], viewport: { width: 844, height: 390 }, isMobile: true } },
    { name: 'pwa-standalone-375x812', testMatch: '**/mobile-matrix.spec.ts', use: { ...devices['iPhone 12'], viewport: { width: 375, height: 812 } }, metadata: { displayMode: 'standalone' } },
  ],
  webServer: process.env.CI ? undefined : [
    { command: 'cd ../backend && .venv/Scripts/uvicorn main:app --port 8001 --reload', url: 'http://localhost:8001/api/health', reuseExistingServer: true, timeout: 15_000 },
    { command: 'cd ../frontend && npm run dev', url: 'http://localhost:5173', reuseExistingServer: true, timeout: 15_000 },
  ],
});
