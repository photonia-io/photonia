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
    it("sets slug, processed and processingTimedOut from the item's response", () => {
      const fetchProcessed = vi.fn().mockResolvedValue([]);
      const { track } = setup({ fetchProcessed });

      const item = successItem("one");
      track(item);

      expect(item.slug).toBe("one");
      expect(item.processed).toBe(false);
      expect(item.processingTimedOut).toBe(false);
    });

    it("does nothing for an item with no slug in its response", async () => {
      const fetchProcessed = vi.fn().mockResolvedValue([]);
      const { track } = setup({ fetchProcessed });

      track({ response: null });
      await vi.advanceTimersByTimeAsync(INTERVAL);

      expect(fetchProcessed).not.toHaveBeenCalled();
    });

    it("does not track the same item twice", async () => {
      const fetchProcessed = vi.fn().mockResolvedValue([]);
      const { track } = setup({ fetchProcessed });

      const item = successItem("one");
      track(item);
      track(item);
      await vi.advanceTimersByTimeAsync(INTERVAL);

      expect(fetchProcessed).toHaveBeenCalledTimes(1);
      expect(fetchProcessed).toHaveBeenCalledWith(["one"]);
    });
  });

  describe("polling", () => {
    it("polls after the interval and marks a completed item processed", async () => {
      const onCompleted = vi.fn();
      const fetchProcessed = vi.fn().mockResolvedValue(["one"]);
      const { track } = setup({ fetchProcessed, onCompleted });

      const item = successItem("one");
      track(item);
      expect(fetchProcessed).not.toHaveBeenCalled();

      await vi.advanceTimersByTimeAsync(INTERVAL);

      expect(fetchProcessed).toHaveBeenCalledWith(["one"]);
      expect(item.processed).toBe(true);
      expect(onCompleted).toHaveBeenCalledWith(1);
    });

    it("stops polling once every tracked item has completed", async () => {
      const fetchProcessed = vi.fn().mockResolvedValue(["one"]);
      const { track } = setup({ fetchProcessed });

      track(successItem("one"));
      await vi.advanceTimersByTimeAsync(INTERVAL);
      expect(fetchProcessed).toHaveBeenCalledTimes(1);

      await vi.advanceTimersByTimeAsync(INTERVAL * 5);
      expect(fetchProcessed).toHaveBeenCalledTimes(1);
    });

    it("backs off (doubling, capped) while nothing completes, and resets on a completion", async () => {
      const fetchProcessed = vi.fn().mockResolvedValue([]);
      // A stall timeout far beyond this test's timeline, so backoff can be
      // observed for a few ticks without the stall wiping tracked items out.
      const { track } = setup({ fetchProcessed, stallTimeout: 1000000 });

      const item = successItem("one");
      track(item);

      await vi.advanceTimersByTimeAsync(INTERVAL); // tick 1: at 1000
      expect(fetchProcessed).toHaveBeenCalledTimes(1);

      await vi.advanceTimersByTimeAsync(INTERVAL * 2); // tick 2: backed off to 2000
      expect(fetchProcessed).toHaveBeenCalledTimes(2);

      await vi.advanceTimersByTimeAsync(INTERVAL * 4); // tick 3: backed off to 4000
      expect(fetchProcessed).toHaveBeenCalledTimes(3);

      // Tick 3 already scheduled tick 4 at +8000 (its own backoff, doubled
      // from 4000); the mocked resolution only takes effect once that tick
      // actually runs.
      fetchProcessed.mockResolvedValueOnce(["one"]);
      await vi.advanceTimersByTimeAsync(INTERVAL * 8);
      expect(fetchProcessed).toHaveBeenCalledTimes(4);
      expect(item.processed).toBe(true);
    });

    it("chunks requests at 100 slugs per call", async () => {
      const fetchProcessed = vi.fn().mockResolvedValue([]);
      const { track } = setup({ fetchProcessed });

      const items = Array.from({ length: 150 }, (_, i) => successItem(`p${i}`));
      items.forEach(track);

      await vi.advanceTimersByTimeAsync(INTERVAL);

      expect(fetchProcessed).toHaveBeenCalledTimes(2);
      expect(fetchProcessed.mock.calls[0][0]).toHaveLength(100);
      expect(fetchProcessed.mock.calls[1][0]).toHaveLength(50);
    });

    it("survives a fetch rejection and retries on the next tick", async () => {
      const fetchProcessed = vi
        .fn()
        .mockRejectedValueOnce(new Error("network"))
        .mockResolvedValueOnce(["one"]);
      const { track } = setup({ fetchProcessed });

      const item = successItem("one");
      track(item);

      await vi.advanceTimersByTimeAsync(INTERVAL);
      expect(fetchProcessed).toHaveBeenCalledTimes(1);
      expect(item.processed).toBe(false);

      await vi.advanceTimersByTimeAsync(INTERVAL);
      expect(fetchProcessed).toHaveBeenCalledTimes(2);
      expect(item.processed).toBe(true);
    });
  });

  describe("stall timeout", () => {
    it("marks remaining items timed out and stops polling after the stall timeout", async () => {
      const fetchProcessed = vi.fn().mockResolvedValue([]);
      const { track } = setup({ fetchProcessed });

      const item = successItem("one");
      track(item);

      // Ticks back off (1000, 2000, 4000...) while nothing completes, so the
      // tick that finally notices the stall lands well past stallTimeout
      // itself - advance generously past it.
      await vi.advanceTimersByTimeAsync(STALL_TIMEOUT * 3);

      expect(item.processingTimedOut).toBe(true);

      const callsAtTimeout = fetchProcessed.mock.calls.length;
      await vi.advanceTimersByTimeAsync(INTERVAL * 10);
      expect(fetchProcessed).toHaveBeenCalledTimes(callsAtTimeout);
    });
  });

  describe("untrack", () => {
    it("stops polling for that item", async () => {
      const fetchProcessed = vi.fn().mockResolvedValue([]);
      const { track, untrack } = setup({ fetchProcessed });

      const item = successItem("one");
      track(item);
      untrack(item);

      await vi.advanceTimersByTimeAsync(INTERVAL * 3);
      expect(fetchProcessed).not.toHaveBeenCalled();
    });

    it("leaves other tracked items polling", async () => {
      const fetchProcessed = vi.fn().mockResolvedValue([]);
      const { track, untrack } = setup({ fetchProcessed });

      const one = successItem("one");
      const two = successItem("two");
      track(one);
      track(two);
      untrack(one);

      await vi.advanceTimersByTimeAsync(INTERVAL);
      expect(fetchProcessed).toHaveBeenCalledWith(["two"]);
    });

    it("does nothing for an item that isn't tracked", () => {
      const { untrack } = setup({ fetchProcessed: vi.fn() });
      expect(() => untrack(successItem("ghost"))).not.toThrow();
    });
  });

  it("clears the pending timer when the scope is disposed", async () => {
    const fetchProcessed = vi.fn().mockResolvedValue([]);
    const { track } = setup({ fetchProcessed });

    track(successItem("one"));
    scope.stop();

    await vi.advanceTimersByTimeAsync(INTERVAL * 3);
    expect(fetchProcessed).not.toHaveBeenCalled();
  });
});
