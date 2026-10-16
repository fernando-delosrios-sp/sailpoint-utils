/**
 * Run `fn` over `items` with at most `limit` in flight, preserving input order
 * in the result. The ISC gateway allows 100 requests per client per 10s, so
 * every caller here stays well under that; IscClient also caps total in-flight
 * requests, which is the real backstop when several of these run at once.
 */
export async function mapLimit(items, limit, fn) {
  const list = [...items];
  const results = new Array(list.length);
  let next = 0;

  async function worker() {
    for (;;) {
      const index = next++;
      if (index >= list.length) return;
      results[index] = await fn(list[index], index);
    }
  }

  const workers = Array.from(
    { length: Math.max(1, Math.min(limit, list.length)) },
    () => worker(),
  );
  await Promise.all(workers);
  return results;
}

/** Caps how many async operations run at once across unrelated callers. */
export class Semaphore {
  constructor(max = 8) {
    this.max = Math.max(1, max);
    this.active = 0;
    this.waiters = [];
  }

  async acquire() {
    if (this.active < this.max) {
      this.active += 1;
      return;
    }
    await new Promise((resolve) => this.waiters.push(resolve));
  }

  release() {
    const next = this.waiters.shift();
    // Hand the slot straight to a waiter instead of freeing it: releasing first
    // would let a new caller claim the slot before the woken waiter resumes,
    // putting max+1 requests in flight.
    if (next) next();
    else this.active -= 1;
  }

  async run(fn) {
    await this.acquire();
    try {
      return await fn();
    } finally {
      this.release();
    }
  }
}
