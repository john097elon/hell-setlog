/**
 * ELO-13 E2E: real media upload, private access control, and workout recovery.
 *
 * Request-based (mirrors core-loop.spec.ts) so it exercises the real HTTP
 * contract. Requires the live stack — set E2E_API_URL (default :8001).
 */
import { test, expect } from '@playwright/test';

const base = process.env.E2E_API_URL || 'http://localhost:8001';

// Minimal valid PNG (signature + IHDR-ish bytes) — enough for magic-byte sniffing.
const PNG = Buffer.from([
  0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a,
  0x00, 0x00, 0x00, 0x0d, 0x49, 0x48, 0x44, 0x52,
]);

async function newUser(request: any, name: string) {
  let hash = 0;
  for (const character of name) hash = ((hash << 5) - hash + character.charCodeAt(0)) | 0;
  const headers = {
    'X-Forwarded-For': `192.0.${Math.abs(hash >> 8) % 254}.${Math.abs(hash) % 254 + 1}`,
  };
  await request.post(`${base}/api/auth/register`, {
    headers,
    data: { username: name, email: `${name}@test.com`, password: 'pass1234' },
  });
  const res = await request.post(`${base}/api/auth/login`, {
    headers,
    data: { username: name, password: 'pass1234' },
  });
  return (await res.json()).access_token as string;
}

test('upload photo-only setlog and read it back as owner; outsider is denied', async ({ request }) => {
  const uid = Date.now();
  const owner = await newUser(request, `media${uid}`);
  const outsider = await newUser(request, `spy${uid}`);
  const auth = (t: string) => ({ Authorization: `Bearer ${t}` });

  // Upload media
  const up = await request.post(`${base}/api/media`, {
    headers: auth(owner),
    multipart: { file: { name: 'p.png', mimeType: 'image/png', buffer: PNG } },
  });
  expect(up.status()).toBe(201);
  const { key } = await up.json();
  expect(key).toMatch(/^users\/\d+\/.*\.png$/);

  // Start workout + photo-only setlog
  const w = await request.post(`${base}/api/workouts/`, { headers: auth(owner), data: {} });
  const { id: wid } = await w.json();
  const sl = await request.post(`${base}/api/workouts/${wid}/setlogs`, {
    headers: auth(owner),
    data: { type: 'mid', content: '', file_path: key },
  });
  expect(sl.status()).toBe(201);

  // Owner can read the bytes; outsider cannot
  const okGet = await request.get(`${base}/api/media/${key}`, { headers: auth(owner) });
  expect(okGet.status()).toBe(200);
  const denied = await request.get(`${base}/api/media/${key}`, { headers: auth(outsider) });
  expect(denied.status()).toBe(404);
});

test('one active workout policy and cancel transition', async ({ request }) => {
  const uid = Date.now() + 1;
  const token = await newUser(request, `dom${uid}`);
  const auth = { Authorization: `Bearer ${token}` };

  const first = await request.post(`${base}/api/workouts/`, { headers: auth, data: {} });
  expect(first.status()).toBe(201);
  const { id: wid } = await first.json();

  // Second active workout rejected
  const second = await request.post(`${base}/api/workouts/`, { headers: auth, data: {} });
  expect(second.status()).toBe(409);

  // Cancel frees the slot
  const cancel = await request.post(`${base}/api/workouts/${wid}/cancel`, { headers: auth });
  expect(cancel.status()).toBe(200);
  expect((await cancel.json()).status).toBe('cancelled');

  const third = await request.post(`${base}/api/workouts/`, { headers: auth, data: {} });
  expect(third.status()).toBe(201);
});
