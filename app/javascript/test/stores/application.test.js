import { describe, it, expect, beforeEach, vi, afterEach } from "vitest";
import { createPinia, setActivePinia } from "pinia";
import { nextTick } from "vue";

import { useApplicationStore } from "../../stores/application";

function setUpStore({ systemDark = false } = {}) {
  window.matchMedia = vi.fn().mockReturnValue({ matches: systemDark });
  setActivePinia(createPinia());
  return useApplicationStore();
}

describe("application store color scheme", () => {
  beforeEach(() => {
    // happy-dom's localStorage isn't reset between tests in the same file.
    localStorage.clear();
  });

  afterEach(() => {
    vi.restoreAllMocks();
  });

  it("follows the system scheme when there is no stored choice", () => {
    expect(setUpStore({ systemDark: false }).colorScheme).toBe("light");
    expect(setUpStore({ systemDark: true }).colorScheme).toBe("dark");
  });

  it("lets the user's choice override the system scheme", () => {
    const store = setUpStore({ systemDark: true });

    store.setUserColorScheme("light");

    expect(store.colorScheme).toBe("light");
  });

  it("persists the choice to localStorage", async () => {
    const store = setUpStore();

    store.setUserColorScheme("dark");
    await nextTick();

    expect(localStorage.getItem("userColorScheme")).toBe("dark");
  });

  it("restores a stored choice over the system scheme", () => {
    localStorage.setItem("userColorScheme", "light");

    expect(setUpStore({ systemDark: true }).colorScheme).toBe("light");
  });
});
