import { describe, it, expect } from "vitest";
import { ref } from "vue";

import {
  descriptionHelper,
  descriptionHtmlHelper,
} from "../../mixins/description-helper";

describe("descriptionHelper", () => {
  it("returns an empty string when there is no data yet", () => {
    expect(descriptionHelper(ref({}))).toBe("");
    expect(descriptionHelper(ref(undefined))).toBe("");
  });

  it("falls back to a placeholder once data has arrived with no description", () => {
    expect(
      descriptionHelper(ref({ id: "some-slug", description: "" })),
    ).toBe("(no description)");
  });

  it("returns the description once data has arrived", () => {
    expect(
      descriptionHelper(
        ref({ id: "some-slug", description: "A lovely sunset" }),
      ),
    ).toBe("A lovely sunset");
  });
});

describe("descriptionHtmlHelper", () => {
  it("returns an empty string when there is no data yet", () => {
    expect(descriptionHtmlHelper(ref({}))).toBe("");
  });

  it("returns the HTML description once data has arrived", () => {
    expect(
      descriptionHtmlHelper(
        ref({ id: "some-slug", descriptionHtml: "<p>Hi</p>" }),
      ),
    ).toBe("<p>Hi</p>");
  });
});
