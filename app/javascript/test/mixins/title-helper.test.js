import { describe, it, expect } from "vitest";
import { ref } from "vue";

import titleHelper from "../../mixins/title-helper";

describe("titleHelper", () => {
  it("returns an empty string when there is no data yet", () => {
    expect(titleHelper(ref({}))).toBe("");
    expect(titleHelper(ref(undefined))).toBe("");
  });

  it("falls back to a placeholder once data has arrived with no title", () => {
    expect(titleHelper(ref({ id: "some-slug", title: "" }))).toBe(
      "(no title)",
    );
  });

  it("returns the title once data has arrived", () => {
    expect(titleHelper(ref({ id: "some-slug", title: "Sunset" }))).toBe(
      "Sunset",
    );
  });
});
