import { expect, test, type APIRequestContext, type Page } from '@playwright/test';

const apiBase = process.env.E2E_API_URL || 'http://localhost:8001';
const password = 'pass1234';
const auth = (token: string) => ({ Authorization: `Bearer ${token}` });

type Session = { token: string; username: string };

function clientIp(seed: string) {
  let hash = 0;
  for (const character of seed) hash = ((hash << 5) - hash + character.charCodeAt(0)) | 0;
  return `203.0.${Math.abs(hash >> 8) % 254}.${Math.abs(hash) % 254 + 1}`;
}

async function newUser(request: APIRequestContext, prefix: string): Promise<Session> {
  const username = `${prefix}${Date.now()}${Math.random().toString(16).slice(2, 8)}`;
  const headers = { 'X-Forwarded-For': clientIp(username) };
  const register = await request.post(`${apiBase}/api/auth/register`, {
    headers,
    data: { username, email: `${username}@test.com`, password },
  });
  expect(register.status()).toBe(201);
  const login = await request.post(`${apiBase}/api/auth/login`, {
    headers,
    data: { username, password },
  });
  expect(login.status()).toBe(200);
  return { token: (await login.json()).access_token as string, username };
}

async function useSession(page: Page, token: string) {
  await page.addInitScript((value) => localStorage.setItem('token', value), token);
}

async function expectNoHorizontalOverflow(page: Page) {
  const metrics = await page.evaluate(() => ({
    viewport: window.innerWidth,
    documentWidth: document.documentElement.scrollWidth,
    bodyWidth: document.body.scrollWidth,
  }));
  expect(metrics.documentWidth).toBeLessThanOrEqual(metrics.viewport + 1);
  expect(metrics.bodyWidth).toBeLessThanOrEqual(metrics.viewport + 1);
}

async function expectTouchTargets(page: Page, selector: string) {
  const targets = await page.locator(selector).evaluateAll((elements) =>
    elements
      .filter((element) => {
        const style = getComputedStyle(element);
        const rect = element.getBoundingClientRect();
        return style.display !== 'none' && style.visibility !== 'hidden' && rect.width > 0;
      })
      .map((element) => {
        const rect = element.getBoundingClientRect();
        return { width: rect.width, height: rect.height };
      }),
  );
  expect(targets.length).toBeGreaterThan(0);
  for (const target of targets) {
    expect(target.width).toBeGreaterThanOrEqual(44);
    expect(target.height).toBeGreaterThanOrEqual(44);
  }
}

test.beforeEach(async ({ page }, testInfo) => {
  if (testInfo.project.metadata.standalone) {
    await page.addInitScript(() => {
      const original = window.matchMedia.bind(window);
      Object.defineProperty(window, 'matchMedia', {
        configurable: true,
        value: (query: string) => {
          if (query !== '(display-mode: standalone)') return original(query);
          return {
            matches: true,
            media: query,
            onchange: null,
            addListener: () => undefined,
            removeListener: () => undefined,
            addEventListener: () => undefined,
            removeEventListener: () => undefined,
            dispatchEvent: () => true,
          };
        },
      });
    });
  }
});

test.describe('mobile core journeys', () => {
  test('records sets through the UI, shows history, and renders body-part growth', async ({ page, request }) => {
    const session = await newUser(request, 'matrix-record-');
    const workout = await request.post(`${apiBase}/api/workouts/`, {
      headers: auth(session.token),
      data: { notes: 'mobile matrix record' },
    });
    expect(workout.status()).toBe(201);
    await useSession(page, session.token);

    await page.goto('/workout');
    await expect(page.getByRole('heading', { name: "Today's workout" })).toBeVisible();
    await expectNoHorizontalOverflow(page);
    await expectTouchTargets(
      page,
      '.record-tabs button, .exercise-option[aria-selected="true"], .save-button, .session-link',
    );

    const reps = page.getByLabel('Set 1 reps');
    await reps.fill('10');
    await page.getByLabel('Set 1 weight').fill('20');
    await reps.focus();
    await reps.scrollIntoViewIfNeeded();
    const focusedBottom = await reps.evaluate((element) => element.getBoundingClientRect().bottom);
    const visibleHeight = await page.evaluate(() => visualViewport?.height ?? innerHeight);
    // Chromium may report a sub-pixel difference between layout and visual viewport.
    expect(focusedBottom).toBeLessThanOrEqual(visibleHeight + 1);

    const save = page.getByRole('button', { name: 'Save workout' });
    await save.scrollIntoViewIfNeeded();
    await expect(save).toBeVisible();
    await save.click();
    await expect(page.getByRole('status')).toContainText('saved');

    await page.getByRole('tab', { name: 'History' }).click();
    await expect(page.locator('.history-card')).toHaveCount(1);
    await expect(page.getByRole('button', { name: /1 records/ })).toBeVisible();
    await expectNoHorizontalOverflow(page);

    await page.getByRole('link', { name: 'Open session' }).click();
    await page.getByRole('button', { name: 'End workout' }).click();
    await expect(page.getByLabel(/XP out of 100/).first()).toBeVisible();
    await expectNoHorizontalOverflow(page);
  });

  test('shows a party video inline and keeps non-members out of playback', async ({ page, request }) => {
    const owner = await newUser(request, 'matrix-video-owner-');
    const outsider = await newUser(request, 'matrix-video-outsider-');
    const party = await request.post(`${apiBase}/api/parties/`, {
      headers: auth(owner.token),
      data: { name: 'Mobile matrix party' },
    });
    expect(party.status()).toBe(201);
    const partyId = (await party.json()).id as number;
    const upload = await request.post(`${apiBase}/api/media`, {
      headers: auth(owner.token),
      multipart: {
        party_id: String(partyId),
        file: {
          name: 'matrix.mp4',
          mimeType: 'video/mp4',
          buffer: Buffer.from('matrix-video'),
        },
      },
    });
    expect(upload.status()).toBe(201);
    const key = (await upload.json()).key as string;
    const workout = await request.post(`${apiBase}/api/workouts/`, {
      headers: auth(owner.token),
      data: { party_id: partyId },
    });
    expect(workout.status()).toBe(201);
    const workoutId = (await workout.json()).id as number;
    const setlog = await request.post(`${apiBase}/api/workouts/${workoutId}/setlogs`, {
      headers: auth(owner.token),
      data: { type: 'mid', content: 'party video', file_path: key },
    });
    expect(setlog.status()).toBe(201);

    const denied = await request.get(`${apiBase}/api/media/${key}/playback`, {
      headers: auth(outsider.token),
    });
    expect(denied.status()).toBe(403);

    await useSession(page, owner.token);
    await page.goto(`/party/${partyId}`);
    const video = page.locator('video[playsinline]').first();
    await expect(video).toBeVisible();
    await expect(video).toHaveAttribute('controls', '');
    await expect(video).not.toHaveAttribute('autoplay', '');
    const bounds = await video.boundingBox();
    expect(bounds).not.toBeNull();
    expect(bounds!.width).toBeLessThanOrEqual(await page.evaluate(() => innerWidth));
    await expectNoHorizontalOverflow(page);
  });

  test('honors PWA, safe-area, reduced-motion, text zoom, and touch sizing', async ({ page }, testInfo) => {
    await page.emulateMedia({ reducedMotion: 'reduce' });
    await page.goto('/login');
    await expect(page).toHaveTitle(/setlog/i);
    await expectTouchTargets(page, 'button, input');
    await expectNoHorizontalOverflow(page);

    const transitionDuration = await page.locator('button').first().evaluate(
      (element) => getComputedStyle(element).transitionDuration,
    );
    expect(transitionDuration).toBe('0s');

    const cssText = await page.evaluate(() =>
      Array.from(document.styleSheets)
        .flatMap((sheet) => {
          try {
            return Array.from(sheet.cssRules, (rule) => rule.cssText);
          } catch {
            return [];
          }
        })
        .join('\n'),
    );
    expect(cssText).toContain('safe-area-inset-bottom');

    await page.addStyleTag({ content: 'html { font-size: 200% !important; }' });
    await expectNoHorizontalOverflow(page);

    const manifestHref = await page.locator('link[rel="manifest"]').getAttribute('href');
    expect(manifestHref).toBeTruthy();
    const manifest = await page.evaluate(async (href) => {
      const response = await fetch(href!);
      return response.json();
    }, manifestHref);
    expect(manifest.display).toBe('standalone');
    if (testInfo.project.metadata.standalone) {
      expect(await page.evaluate(() => matchMedia('(display-mode: standalone)').matches)).toBe(true);
    }
  });
});