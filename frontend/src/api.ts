import axios from 'axios';
import type { AxiosError, InternalAxiosRequestConfig } from 'axios';

/**
 * Extended config for idempotency / retry.
 */
interface ApiConfig extends InternalAxiosRequestConfig {
  _retryCount?: number;
  _idempotencyKey?: string;
}

const MAX_RETRIES = 2;

const api = axios.create({
  baseURL: '/api',
  headers: {
    'Content-Type': 'application/json',
  },
  timeout: 15000,
});

/**
 * Simple idempotency key generator.
 * Used for POST requests that should not be duplicated.
 */
function idempotencyKey(): string {
  const arr = new Uint8Array(16);
  crypto.getRandomValues(arr);
  return Array.from(arr, (b) => b.toString(16).padStart(2, '0')).join('');
}

/**
 * Set of in-flight POST request keys to prevent duplicates.
 */
const inflightKeys = new Set<string>();

// ─── Request interceptor ──────────────────────────────────────────────────────

api.interceptors.request.use((config: ApiConfig) => {
  // Attach auth token
  const token = localStorage.getItem('token');
  if (token) {
    config.headers.Authorization = `Bearer ${token}`;
  }

  // Add idempotency key to POST /workouts/.../setlogs to prevent duplicates
  if (
    config.method === 'post' &&
    typeof config.url === 'string' &&
    config.url.includes('/setlogs')
  ) {
    // Skip if retry (keep the original key)
    if (!config._idempotencyKey) {
      config._idempotencyKey = idempotencyKey();
    }
    config.headers['X-Idempotency-Key'] = config._idempotencyKey;

    // Prevent duplicate in-flight requests with same key
    const dedupKey = `${config.method}:${config.url}:${config._idempotencyKey}`;
    if (inflightKeys.has(dedupKey)) {
      return Promise.reject(new axios.Cancel(`Duplicate request: ${dedupKey}`));
    }
    inflightKeys.add(dedupKey);

    // Clean up when done
    (config as any)._inflightDedupKey = dedupKey;
  }

  return config;
});

// ─── Response interceptor ─────────────────────────────────────────────────────

api.interceptors.response.use(
  (response) => {
    // Cleanup inflight tracking
    const key = (response.config as any)._inflightDedupKey;
    if (key) inflightKeys.delete(key);
    return response;
  },
  async (error: AxiosError) => {
    const config = error.config as ApiConfig | undefined;

    // Cleanup inflight tracking
    if (config) {
      const key = (config as any)._inflightDedupKey;
      if (key) inflightKeys.delete(key);
    }

    // Handle 401 - clear token and redirect
    if (error.response?.status === 401) {
      localStorage.removeItem('token');
      window.location.href = '/login';
      return Promise.reject(error);
    }

    // Retry on network errors or 5xx server errors (but not 409 conflict)
    if (
      config &&
      !axios.isCancel(error) &&
      (error.code === 'ERR_NETWORK' ||
       error.code === 'ECONNABORTED' ||
       (error.response && error.response.status >= 500 && error.response.status !== 409))
    ) {
      config._retryCount = (config._retryCount || 0) + 1;
      if (config._retryCount <= MAX_RETRIES) {
        const delay = Math.min(1000 * Math.pow(2, config._retryCount - 1), 4000);
        await new Promise((resolve) => setTimeout(resolve, delay));
        return api(config);
      }
    }

    return Promise.reject(error);
  },
);

export default api;
