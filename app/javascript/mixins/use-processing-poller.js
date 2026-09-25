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

// Polls the server for each photo's upload-pipeline stage (Rekognition
// tagging, then derivatives). Not ActionCable - a single batched GraphQL
// query on a timer, so there's no websocket/channel infrastructure to add.
export function useProcessingPoller({
  fetchStatus,
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
    let results = [];
    try {
      const batches = await Promise.all(
        chunk(slugs, CHUNK_SIZE).map((batch) => fetchStatus(batch)),
      );
      results = batches.flat();
    } catch {
      // Network hiccup: try again next tick, no state change.
      scheduleNext();
      return;
    }

    const statusBySlug = new Map(results.map((status) => [status.id, status]));
    let completedCount = 0;

    for (let i = tracked.length - 1; i >= 0; i--) {
      const item = tracked[i];
      const status = statusBySlug.get(item.slug);
      if (!status) continue;

      item.labeled = status.labeled;

      if (status.processingFailed) {
        item.processingFailed = true;
        item.processingTimedOut = false;
        tracked.splice(i, 1);
        completedCount++;
      } else if (status.processed) {
        item.processed = true;
        item.processingTimedOut = false;
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
    item.labeled = false;
    item.processed = false;
    item.processingFailed = false;
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
