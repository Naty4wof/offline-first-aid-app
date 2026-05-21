type CacheEntry<T> = {
  value?: T;
  promise?: Promise<T>;
  expiresAt: number;
};

const cache = new Map<string, CacheEntry<unknown>>();

export async function cacheFetch<T>(
  key: string,
  fetcher: () => Promise<T>,
  ttlMs = 300000,
  forceRefresh = false,
): Promise<T> {
  const now = Date.now();
  const entry = cache.get(key) as CacheEntry<T> | undefined;

  if (!forceRefresh && entry?.value && entry.expiresAt > now) {
    return entry.value;
  }

  if (!forceRefresh && entry?.promise) {
    return entry.promise;
  }

  const promise = fetcher();
  cache.set(key, { promise, expiresAt: now + ttlMs });

  try {
    const value = await promise;
    cache.set(key, { value, expiresAt: now + ttlMs });
    return value;
  } catch (error) {
    cache.delete(key);
    throw error;
  }
}

export function clearCache(key?: string) {
  if (key) {
    cache.delete(key);
  } else {
    cache.clear();
  }
}
