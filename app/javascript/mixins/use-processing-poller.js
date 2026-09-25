import { onScopeDispose } from "vue";

const BASE_INTERVAL = 3000;
const MAX_INTERVAL = 10000;
const CHUNK_SIZE = 100;

function chunk(array, size) {
  const chunks = [];
  for (let i = 0; i < array.length; i += size) {
    chunks.push(array.slice(i, i + size));
  }
  return chunks;
}

// Polls the server for photos whose upload pipeline (Rekognition tagging,
// then derivatives) has finished. Not ActionCable - a single batched GraphQL
// query on a timer, so there's no websocket/channel infrastructure to add.
export function useProcessingPoller({
  fetchProcessed,
  interval = BASE_INTERVAL,
  stallTimeout = 300000,
  onCompleted,
} = {}) {
  const tracked = [];
  let currentInterval = interval;
  let lastProgressAt = null;
  let timerId = null;

  function scheduleNext() {
    clearTimeout(timerId);
    if (tracked.length === 0) return;
    timerId = setTimeout(tick, currentInterval);
  }

  async function tick() {
    if (tracked.length === 0) return;

    const slugs = tracked.map((item) => item.slug);
    let processedSlugs = [];
    try {
      const results = await Promise.all(
        chunk(slugs, CHUNK_SIZE).map((batch) => fetchProcessed(batch)),
      );
      processedSlugs = results.flat();
    } catch {
      // Network hiccup: try again next tick, no state change.
      scheduleNext();
      return;
    }

    const processedSet = new Set(processedSlugs);
    let completedCount = 0;

    for (let i = tracked.length - 1; i >= 0; i--) {
      if (processedSet.has(tracked[i].slug)) {
        tracked[i].processed = true;
        tracked[i].processingTimedOut = false;
        tracked.splice(i, 1);
        completedCount++;
      }
    }

    if (completedCount > 0) {
      currentInterval = interval;
      lastProgressAt = Date.now();
      onCompleted?.(completedCount);
    } else if (Date.now() - lastProgressAt >= stallTimeout) {
      // Flag the stall, but keep tracking - a slow backlog can still finish later.
      tracked.forEach((item) => {
        item.processingTimedOut = true;
      });
    } else {
      currentInterval = Math.min(currentInterval * 2, MAX_INTERVAL);
    }

    scheduleNext();
  }

  function track(item) {
    if (!item.response?.photo?.id) return;

    item.slug = item.response.photo.id;
    item.processed = false;
    item.processingTimedOut = false;

    if (tracked.includes(item)) return;
    tracked.push(item);

    if (tracked.length === 1) {
      currentInterval = interval;
      lastProgressAt = Date.now();
      scheduleNext();
    }
  }

  function untrack(item) {
    const index = tracked.indexOf(item);
    if (index === -1) return;
    tracked.splice(index, 1);
    if (tracked.length === 0) clearTimeout(timerId);
  }

  onScopeDispose(() => clearTimeout(timerId));

  return { track, untrack };
}
