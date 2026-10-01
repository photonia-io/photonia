import { describe, it, expect, afterEach, vi } from "vitest";

import { waitForElement } from "../../helpers/wait-for-element";

afterEach(() => {
  document.body.innerHTML = "";
  vi.useRealTimers();
});

describe("waitForElement", () => {
  it("resolves immediately when the element exists", async () => {
    document.body.innerHTML = '<div id="here"></div>';

    expect(await waitForElement("#here")).toBe(document.getElementById("here"));
  });

  it("resolves once the element is added later", async () => {
    const promise = waitForElement("#later");
    const el = document.createElement("div");
    el.id = "later";
    document.body.appendChild(el);

    expect(await promise).toBe(el);
  });

  it("resolves null after the timeout", async () => {
    vi.useFakeTimers();
    const promise = waitForElement("#never", 1000);
    vi.advanceTimersByTime(1000);

    expect(await promise).toBeNull();
  });
});
