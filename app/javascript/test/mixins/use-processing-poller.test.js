import { describe, it, expect, vi, beforeEach, afterEach } from "vitest";
import { effectScope } from "vue";

import { useProcessingPoller } from "../../mixins/use-processing-poller";

const INTERVAL = 1000;
const STALL_TIMEOUT = 5000;

let scope;

function setup(overrides = {}) {
  scope = effectScope();
  return scope.run(() =>
    useProcessingPoller({
      interval: INTERVAL,
      stallTimeout: STALL_TIMEOUT,
      ...overrides,
    }),
  );
}

function successItem(slug) {
  return { response: { photo: { id: slug } } };
}

// A fetchStatus result for one slug, defaulting to "still labeling".
function status(id, overrides = {}) {
  return { id, labeled: false, processed: false, processingFailed: false, ...overrides };
}

beforeEach(() => {
  vi.useFakeTimers();
});

afterEach(() => {
  scope?.stop();
  scope = undefined;
  vi.useRealTimers();
});

describe("useProcessingPoller", () => {
  describe("track", () => {
    it("sets slug, labeled, processed, processingFailed and processingTimedOut from the item's response", () => {
      const fetchStatus = vi.fn().mockResolvedValue([]);
      const { track } = setup({ fetchStatus });

      const item = successItem("one");
      track(item);

      expect(item.slug).toBe("one");
      expect(item.labeled).toBe(false);
      expect(item.processed).toBe(false);
      expect(item.processingFailed).toBe(false);
      expect(item.processingTimedOut).toBe(false);
    });

    it("does nothing for an item with no slug in its response", async () => {
      const fetchStatus = vi.fn().mockResolvedValue([]);
      const { track } = setup({ fetchStatus });

      track({ response: null });
      await vi.advanceTimersByTimeAsync(INTERVAL);

      expect(fetchStatus).not.toHaveBeenCalled();
    });

    it("does not track the same item twice", async () => {
      const fetchStatus = vi.fn().mockResolvedValue([]);
      const { track } = setup({ fetchStatus });

      const item = successItem("one");
      track(item);
      track(item);
      await vi.advanceTimersByTimeAsync(INTERVAL);

      expect(fetchStatus).toHaveBeenCalledTimes(1);
      expect(fetchStatus).toHaveBeenCalledWith(["one"]);
    });
  });

  describe("polling", () => {
    it("polls after the interval and marks a completed item processed", async () => {
      const onCompleted = vi.fn();
      const fetchStatus = vi.fn().mockResolvedValue([status("one", { labeled: true, processed: true })]);
      const { track } = setup({ fetchStatus, onCompleted });

      const item = successItem("one");
      track(item);
      expect(fetchStatus).not.toHaveBeenCalled();

      await vi.advanceTimersByTimeAsync(INTERVAL);

      expect(fetchStatus).toHaveBeenCalledWith(["one"]);
      expect(item.processed).toBe(true);
      expect(onCompleted).toHaveBeenCalledWith(1);
    });

    it("updates labeled while still polling, without untracking the item", async () => {
      const fetchStatus = vi.fn().mockResolvedValue([status("one", { labeled: true })]);
      const { track } = setup({ fetchStatus });

      const item = successItem("one");
      track(item);
      await vi.advanceTimersByTimeAsync(INTERVAL);

      expect(item.labeled).toBe(true);
      expect(item.processed).toBe(false);

      // Nothing completed on that tick, so the interval backed off to 2x.
      await vi.advanceTimersByTimeAsync(INTERVAL * 2);
      expect(fetchStatus).toHaveBeenCalledTimes(2); // still being polled
    });

    it("marks a permanently failed item processingFailed and stops polling it, without marking it processed", async () => {
      const onCompleted = vi.fn();
      const fetchStatus = vi
        .fn()
        .mockResolvedValue([status("one", { labeled: true, processingFailed: true })]);
      const { track } = setup({ fetchStatus, onCompleted });

      const item = successItem("one");
      track(item);
      await vi.advanceTimersByTimeAsync(INTERVAL);

      expect(item.processingFailed).toBe(true);
      expect(item.processed).toBe(false);
      expect(onCompleted).toHaveBeenCalledWith(1);

      await vi.advanceTimersByTimeAsync(INTERVAL * 5);
      expect(fetchStatus).toHaveBeenCalledTimes(1); // untracked, no more polls
    });

    it("stops polling once every tracked item has completed", async () => {
      const fetchStatus = vi.fn().mockResolvedValue([status("one", { labeled: true, processed: true })]);
      const { track } = setup({ fetchStatus });

      track(successItem("one"));
      await vi.advanceTimersByTimeAsync(INTERVAL);
      expect(fetchStatus).toHaveBeenCalledTimes(1);

      await vi.advanceTimersByTimeAsync(INTERVAL * 5);
      expect(fetchStatus).toHaveBeenCalledTimes(1);
    });

    it("backs off (doubling, capped) while nothing completes, and resets on a completion", async () => {
      const fetchStatus = vi.fn().mockResolvedValue([]);
      // A stall timeout far beyond this test's timeline, so backoff can be
      // observed for a few ticks without the stall wiping tracked items out.
      const { track } = setup({ fetchStatus, stallTimeout: 1000000 });

      const item = successItem("one");
      track(item);

      await vi.advanceTimersByTimeAsync(INTERVAL); // tick 1: at 1000
      expect(fetchStatus).toHaveBeenCalledTimes(1);

      await vi.advanceTimersByTimeAsync(INTERVAL * 2); // tick 2: backed off to 2000
      expect(fetchStatus).toHaveBeenCalledTimes(2);

      await vi.advanceTimersByTimeAsync(INTERVAL * 4); // tick 3: backed off to 4000
      expect(fetchStatus).toHaveBeenCalledTimes(3);

      // Tick 3 already scheduled tick 4 at +8000 (its own backoff, doubled
      // from 4000); the mocked resolution only takes effect once that tick
      // actually runs.
      fetchStatus.mockResolvedValueOnce([status("one", { labeled: true, processed: true })]);
      await vi.advanceTimersByTimeAsync(INTERVAL * 8);
      expect(fetchStatus).toHaveBeenCalledTimes(4);
      expect(item.processed).toBe(true);
    });

    it("chunks requests at 100 slugs per call", async () => {
      const fetchStatus = vi.fn().mockResolvedValue([]);
      const { track } = setup({ fetchStatus });

      const items = Array.from({ length: 150 }, (_, i) => successItem(`p${i}`));
      items.forEach(track);

      await vi.advanceTimersByTimeAsync(INTERVAL);

      expect(fetchStatus).toHaveBeenCalledTimes(2);
      expect(fetchStatus.mock.calls[0][0]).toHaveLength(100);
      expect(fetchStatus.mock.calls[1][0]).toHaveLength(50);
    });

    it("survives a fetch rejection and retries on the next tick", async () => {
      const fetchStatus = vi
        .fn()
        .mockRejectedValueOnce(new Error("network"))
        .mockResolvedValueOnce([status("one", { labeled: true, processed: true })]);
      const { track } = setup({ fetchStatus });

      const item = successItem("one");
      track(item);

      await vi.advanceTimersByTimeAsync(INTERVAL);
      expect(fetchStatus).toHaveBeenCalledTimes(1);
      expect(item.processed).toBe(false);

      await vi.advanceTimersByTimeAsync(INTERVAL);
      expect(fetchStatus).toHaveBeenCalledTimes(2);
      expect(item.processed).toBe(true);
    });
  });

  describe("stall timeout", () => {
    it("marks remaining items timed out but keeps polling them", async () => {
      const fetchStatus = vi.fn().mockResolvedValue([]);
      const { track } = setup({ fetchStatus });

      const item = successItem("one");
      track(item);

      // Ticks back off (1000, 2000, 4000...) while nothing completes, so the
      // tick that finally notices the stall lands well past stallTimeout
      // itself - advance generously past it.
      await vi.advanceTimersByTimeAsync(STALL_TIMEOUT * 3);

      expect(item.processingTimedOut).toBe(true);
      const callsAtTimeout = fetchStatus.mock.calls.length;
      expect(callsAtTimeout).toBeGreaterThan(0);

      // A slow Sidekiq backlog can still finish after the stall warning -
      // polling shouldn't have stopped, so a later completion still lands.
      fetchStatus.mockResolvedValueOnce([status("one", { labeled: true, processed: true })]);
      await vi.advanceTimersByTimeAsync(INTERVAL * 10);

      expect(fetchStatus.mock.calls.length).toBeGreaterThan(callsAtTimeout);
      expect(item.processed).toBe(true);
      // Completing clears the stall flag too, or the row would keep
      // showing "still processing" beside its Complete badge.
      expect(item.processingTimedOut).toBe(false);
    });

    it("gives a newly tracked item its own clock, not the whole batch's", async () => {
      const fetchStatus = vi.fn().mockResolvedValue([]);
      // A stall timeout well past the (10s-capped) poll interval, so there's
      // room to observe a tick without "fresh" stalling on its own merits.
      const bigStallTimeout = 20000;
      const { track } = setup({ fetchStatus, stallTimeout: bigStallTimeout });

      const stale = successItem("stale");
      track(stale);
      await vi.advanceTimersByTimeAsync(bigStallTimeout * 3);
      expect(stale.processingTimedOut).toBe(true);

      // Tracked well after that stall - shouldn't inherit it on the next
      // tick just because the shared "last progress" clock is old.
      const fresh = successItem("fresh");
      track(fresh);
      await vi.advanceTimersByTimeAsync(12000); // one tick, short of its own stall

      expect(fresh.processingTimedOut).toBe(false);
      expect(stale.processingTimedOut).toBe(true); // still flagged, unaffected
    });
  });

  describe("untrack", () => {
    it("stops polling for that item", async () => {
      const fetchStatus = vi.fn().mockResolvedValue([]);
      const { track, untrack } = setup({ fetchStatus });

      const item = successItem("one");
      track(item);
      untrack(item);

      await vi.advanceTimersByTimeAsync(INTERVAL * 3);
      expect(fetchStatus).not.toHaveBeenCalled();
    });

    it("leaves other tracked items polling", async () => {
      const fetchStatus = vi.fn().mockResolvedValue([]);
      const { track, untrack } = setup({ fetchStatus });

      const one = successItem("one");
      const two = successItem("two");
      track(one);
      track(two);
      untrack(one);

      await vi.advanceTimersByTimeAsync(INTERVAL);
      expect(fetchStatus).toHaveBeenCalledWith(["two"]);
    });

    it("does nothing for an item that isn't tracked", () => {
      const { untrack } = setup({ fetchStatus: vi.fn() });
      expect(() => untrack(successItem("ghost"))).not.toThrow();
    });
  });

  it("clears the pending timer when the scope is disposed", async () => {
    const fetchStatus = vi.fn().mockResolvedValue([]);
    const { track } = setup({ fetchStatus });

    track(successItem("one"));
    scope.stop();

    await vi.advanceTimersByTimeAsync(INTERVAL * 3);
    expect(fetchStatus).not.toHaveBeenCalled();
  });
});
