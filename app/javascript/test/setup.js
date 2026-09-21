import { Storage } from "happy-dom";

// Node 25 defines its own localStorage/sessionStorage getters on globalThis that
// return an inert plain object (no getItem) unless --localstorage-file is given a
// valid path. Those shadow happy-dom's working Storage, so anything reading web
// storage at import time crashes — @vue/devtools-kit, pulled in by Pinia, does.
// Only replaces storage that is already broken, so this is a no-op on Node 22.
for (const key of ["localStorage", "sessionStorage"]) {
  if (typeof globalThis[key]?.getItem !== "function") {
    Object.defineProperty(globalThis, key, {
      value: new Storage(),
      configurable: true,
      writable: true,
    });
  }
}
