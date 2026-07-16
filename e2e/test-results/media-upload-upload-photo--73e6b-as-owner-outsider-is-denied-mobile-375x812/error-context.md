# Instructions

- Following Playwright test failed.
- Explain why, be concise, respect Playwright best practices.
- Provide a snippet of code with the fix, if possible.

# Test info

- Name: media-upload.spec.ts >> upload photo-only setlog and read it back as owner; outsider is denied
- Location: tests\media-upload.spec.ts:27:5

# Error details

```
Error: expect(received).toBe(expected) // Object.is equality

Expected: 201
Received: 422
```

# Test source

```ts
  1  | /**
  2  |  * ELO-13 E2E: real media upload, private access control, and workout recovery.
  3  |  *
  4  |  * Request-based (mirrors core-loop.spec.ts) so it exercises the real HTTP
  5  |  * contract. Requires the live stack — set E2E_API_URL (default :8001).
  6  |  */
  7  | import { test, expect } from '@playwright/test';
  8  | 
  9  | const base = process.env.E2E_API_URL || 'http://localhost:8001';
  10 | 
  11 | // Minimal valid PNG (signature + IHDR-ish bytes) — enough for magic-byte sniffing.
  12 | const PNG = Buffer.from([
  13 |   0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a,
  14 |   0x00, 0x00, 0x00, 0x0d, 0x49, 0x48, 0x44, 0x52,
  15 | ]);
  16 | 
  17 | async function newUser(request: any, name: string) {
  18 |   await request.post(`${base}/api/auth/register`, {
  19 |     data: { username: name, email: `${name}@test.com`, password: 'pass1234' },
  20 |   });
  21 |   const res = await request.post(`${base}/api/auth/login`, {
  22 |     data: { username: name, password: 'pass1234' },
  23 |   });
  24 |   return (await res.json()).access_token as string;
  25 | }
  26 | 
  27 | test('upload photo-only setlog and read it back as owner; outsider is denied', async ({ request }) => {
  28 |   const uid = Date.now();
  29 |   const owner = await newUser(request, `media${uid}`);
  30 |   const outsider = await newUser(request, `spy${uid}`);
  31 |   const auth = (t: string) => ({ Authorization: `Bearer ${t}` });
  32 | 
  33 |   // Upload media
  34 |   const up = await request.post(`${base}/api/media`, {
  35 |     headers: auth(owner),
  36 |     multipart: { file: { name: 'p.png', mimeType: 'image/png', buffer: PNG } },
  37 |   });
  38 |   expect(up.status()).toBe(201);
  39 |   const { key } = await up.json();
  40 |   expect(key).toMatch(/^users\/\d+\/.*\.png$/);
  41 | 
  42 |   // Start workout + photo-only setlog
  43 |   const w = await request.post(`${base}/api/workouts/`, { headers: auth(owner), data: {} });
  44 |   const { id: wid } = await w.json();
  45 |   const sl = await request.post(`${base}/api/workouts/${wid}/setlogs`, {
  46 |     headers: auth(owner),
  47 |     data: { type: 'mid', content: '', file_path: key },
  48 |   });
> 49 |   expect(sl.status()).toBe(201);
     |                       ^ Error: expect(received).toBe(expected) // Object.is equality
  50 | 
  51 |   // Owner can read the bytes; outsider cannot
  52 |   const okGet = await request.get(`${base}/api/media/${key}`, { headers: auth(owner) });
  53 |   expect(okGet.status()).toBe(200);
  54 |   const denied = await request.get(`${base}/api/media/${key}`, { headers: auth(outsider) });
  55 |   expect(denied.status()).toBe(404);
  56 | });
  57 | 
  58 | test('one active workout policy and cancel transition', async ({ request }) => {
  59 |   const uid = Date.now() + 1;
  60 |   const token = await newUser(request, `dom${uid}`);
  61 |   const auth = { Authorization: `Bearer ${token}` };
  62 | 
  63 |   const first = await request.post(`${base}/api/workouts/`, { headers: auth, data: {} });
  64 |   expect(first.status()).toBe(201);
  65 |   const { id: wid } = await first.json();
  66 | 
  67 |   // Second active workout rejected
  68 |   const second = await request.post(`${base}/api/workouts/`, { headers: auth, data: {} });
  69 |   expect(second.status()).toBe(409);
  70 | 
  71 |   // Cancel frees the slot
  72 |   const cancel = await request.post(`${base}/api/workouts/${wid}/cancel`, { headers: auth });
  73 |   expect(cancel.status()).toBe(200);
  74 |   expect((await cancel.json()).status).toBe('cancelled');
  75 | 
  76 |   const third = await request.post(`${base}/api/workouts/`, { headers: auth, data: {} });
  77 |   expect(third.status()).toBe(201);
  78 | });
  79 | 
```