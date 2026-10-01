// Resolves with the element once it exists, or null after timeoutMs.
export function waitForElement(selector, timeoutMs = 5000) {
  return new Promise((resolve) => {
    const found = document.querySelector(selector);
    if (found) return resolve(found);

    const finish = (el) => {
      observer.disconnect();
      clearTimeout(timer);
      resolve(el);
    };
    const observer = new MutationObserver(() => {
      const el = document.querySelector(selector);
      if (el) finish(el);
    });
    const timer = setTimeout(() => finish(null), timeoutMs);
    observer.observe(document.body, { childList: true, subtree: true });
  });
}
