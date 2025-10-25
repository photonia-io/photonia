// Utilities for responsive social auth buttons: width calculation and resize observers

/**
 * Compute responsive width for a mounted button element.
 * - Fills the parent exactly when parent width ≤ 400px
 * - Caps at 400px when parent width is larger
 * @param {HTMLElement|null} mountEl
 * @returns {number}
 */
export const computeResponsiveWidth = (mountEl) => {
  if (!mountEl) return 0;
  const parentEl = mountEl.parentElement;
  const parentWidth = parentEl ? parentEl.clientWidth : 0;
  return parentWidth <= 400 ? Math.floor(parentWidth) : 400;
};

/**
 * Simple debounce helper.
 * @template T
 * @param {(this: T, ...args:any[]) => void} fn
 * @param {number} wait
 * @returns {(this: T, ...args:any[]) => void}
 */
export const debounce = (fn, wait = 150) => {
  let t = null;
  return function debounced(...args) {
    clearTimeout(t);
    t = setTimeout(() => fn.apply(this, args), wait);
  };
};

/**
 * Set up responsive re-rendering using ResizeObserver with window resize fallback.
 * Returns a teardown function that removes observers and listeners.
 *
 * Usage:
 *   const teardown = setupResizeObservers(mount.value, renderFn, 150)
 *   onBeforeUnmount(teardown)
 *
 * @param {HTMLElement|null} mountEl
 * @param {() => void} renderFn - function that re-renders the button
 * @param {number} wait - debounce delay in ms
 * @returns {() => void} teardown function
 */
export const setupResizeObservers = (mountEl, renderFn, wait = 150) => {
  const debounced = debounce(renderFn, wait);
  let ro = null;
  let winHandler = null;

  const parentEl = mountEl?.parentElement;
  if (parentEl && typeof ResizeObserver !== "undefined") {
    ro = new ResizeObserver(() => {
      debounced();
    });
    ro.observe(parentEl);
  } else {
    winHandler = () => debounced();
    window.addEventListener("resize", winHandler);
  }

  return () => {
    if (ro) {
      ro.disconnect();
      ro = null;
    }
    if (winHandler) {
      window.removeEventListener("resize", winHandler);
      winHandler = null;
    }
  };
};
