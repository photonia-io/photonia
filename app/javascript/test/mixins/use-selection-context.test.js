import { describe, it, expect } from "vitest";

import { resolveSelectionContext } from "../../mixins/use-selection-context.js";

describe("resolveSelectionContext", () => {
  it("returns a null context for an unrecognized route", () => {
    expect(resolveSelectionContext({ name: "root", query: {}, params: {} })).toEqual({
      type: null,
      key: null,
      param: null,
    });
  });

  it("keys photos-search on the filters, excluding page", () => {
    const context = resolveSelectionContext({
      name: "photos-search",
      query: { q: "lake", page: "2" },
      params: {},
    });

    expect(context.type).toBe("photos-search");
    expect(context.param).toBeNull();
    expect(context.key).not.toContain("page");
  });

  it("gives two different filter sets different keys", () => {
    const lake = resolveSelectionContext({ name: "photos-search", query: { q: "lake" }, params: {} });
    const forest = resolveSelectionContext({ name: "photos-search", query: { q: "forest" }, params: {} });

    expect(lake.key).not.toBe(forest.key);
  });

  it("gives the same filters the same key regardless of page", () => {
    const page1 = resolveSelectionContext({
      name: "photos-search",
      query: { q: "lake", page: "1" },
      params: {},
    });
    const page2 = resolveSelectionContext({
      name: "photos-search",
      query: { q: "lake", page: "2" },
      params: {},
    });

    expect(page1.key).toBe(page2.key);
  });
});
