import { describe, it, expect } from "vitest";

import {
  fromRouteQuery,
  toRouteQuery,
  hasSearch,
  toVariables,
  isFilled,
  describeSearch,
} from "../../photos/search-params.js";

describe("fromRouteQuery", () => {
  it("reads plain string values", () => {
    expect(fromRouteQuery({ q: "lake", make: "Canon" })).toMatchObject({
      q: "lake",
      make: "Canon",
    });
  });

  it("drops empty string values", () => {
    expect(fromRouteQuery({ q: "" })).not.toHaveProperty("q");
  });

  it("parses numbers", () => {
    expect(fromRouteQuery({ isoMin: "100" })).toMatchObject({ isoMin: 100 });
  });

  it("ignores an unparseable number", () => {
    expect(fromRouteQuery({ isoMin: "abc" })).not.toHaveProperty("isoMin");
  });

  it("parses booleans from the '1' convention", () => {
    const state = fromRouteQuery({ untagged: "1" });
    expect(state.untagged).toBe(true);
    expect(state.noTitle).toBe(false);
  });

  it("turns a single array-key value into a one-element array", () => {
    expect(fromRouteQuery({ tags: "sunset" })).toMatchObject({ tags: ["sunset"] });
  });

  it("keeps a multi-value array-key value as an array", () => {
    expect(fromRouteQuery({ tags: ["sunset", "lake"] })).toMatchObject({
      tags: ["sunset", "lake"],
    });
  });

  it("defaults an absent array key to an empty array", () => {
    expect(fromRouteQuery({})).toMatchObject({ tags: [], excludeTags: [], labels: [] });
  });
});

describe("toRouteQuery", () => {
  it("round-trips through fromRouteQuery", () => {
    const query = {
      q: "lake",
      tags: ["sunset", "mountains"],
      isoMin: "100",
      untagged: "1",
    };

    expect(toRouteQuery(fromRouteQuery(query))).toEqual(query);
  });

  it("drops false booleans and blank/undefined values instead of writing them", () => {
    const query = toRouteQuery({ q: "", untagged: false, isoMin: undefined });

    expect(query).toEqual({});
  });

  it("writes an array-key with one value as an array", () => {
    expect(toRouteQuery({ tags: ["sunset"] })).toEqual({ tags: ["sunset"] });
  });
});

describe("hasSearch", () => {
  it("is false for an empty state", () => {
    expect(hasSearch({})).toBe(false);
  });

  it("is true when q is set", () => {
    expect(hasSearch({ q: "lake" })).toBe(true);
  });

  it("is true when a tag is set", () => {
    expect(hasSearch({ tags: ["sunset"] })).toBe(true);
  });

  it("is true when a missing-data checkbox is set", () => {
    expect(hasSearch({ untagged: true })).toBe(true);
  });

  it("is true when a numeric filter is set, even zero", () => {
    expect(hasSearch({ isoMin: 0 })).toBe(true);
  });

  it("is true when a scalar filter like album is set", () => {
    expect(hasSearch({ album: "some-album" })).toBe(true);
  });
});

describe("toVariables", () => {
  it("maps route keys to the photoSearch filter names", () => {
    const state = {
      q: "lake",
      tags: ["sunset"],
      tagsMode: "any",
      make: "Canon",
      isoMin: 100,
      license: "CC0 1.0",
      album: "my-album",
      privacy: "private",
      untagged: true,
    };

    expect(toVariables(state, 2)).toEqual({
      filters: {
        query: "lake",
        tags: ["sunset"],
        tagsMode: "ANY",
        cameraMake: "Canon",
        isoMin: 100,
        license: "CC0 1.0",
        albumId: "my-album",
        privacy: "PRIVATE",
        untagged: true,
      },
      sort: "RELEVANCE",
      direction: "DESC",
      page: 2,
    });
  });

  it("uppercases a multi-word privacy value", () => {
    const { filters } = toVariables({ privacy: "friends_and_family" }, 1);
    expect(filters.privacy).toBe("FRIENDS_AND_FAMILY");
  });

  it("defaults sort and direction when absent", () => {
    const { sort, direction } = toVariables({}, 1);
    expect(sort).toBe("RELEVANCE");
    expect(direction).toBe("DESC");
  });

  it("omits a boolean filter that is false", () => {
    const { filters } = toVariables({ scanned: false }, 1);
    expect(filters).not.toHaveProperty("scanned");
  });
});

describe("isFilled", () => {
  it("is false for an absent string key and true once set", () => {
    expect(isFilled({}, "q")).toBe(false);
    expect(isFilled({ q: "lake" }, "q")).toBe(true);
  });

  it("is false for an empty array and true once it has an item", () => {
    expect(isFilled({ tags: [] }, "tags")).toBe(false);
    expect(isFilled({ tags: ["sunset"] }, "tags")).toBe(true);
  });

  it("is false for an unset boolean and true once checked", () => {
    expect(isFilled({}, "untagged")).toBe(false);
    expect(isFilled({ untagged: true }, "untagged")).toBe(true);
  });

  it("treats 0 as filled for a numeric key, unlike a falsy check", () => {
    expect(isFilled({ isoMin: 0 }, "isoMin")).toBe(true);
    expect(isFilled({}, "isoMin")).toBe(false);
  });
});

describe("describeSearch", () => {
  it("is empty for an empty state", () => {
    expect(describeSearch({})).toBe("");
  });

  it("describes a text query", () => {
    expect(describeSearch({ q: "lake" })).toBe('Photos matching "lake".');
  });

  it("describes tags with the ANY/ALL mode", () => {
    expect(describeSearch({ tags: ["sunset", "lake"], tagsMode: "any" })).toBe(
      "Photos tagged with any of sunset and lake.",
    );
    expect(describeSearch({ tags: ["sunset"], tagsMode: "all" })).toBe(
      "Photos tagged with all of sunset.",
    );
  });

  it("describes a date range with only one side set", () => {
    expect(describeSearch({ takenFrom: "2020-01-01" })).toBe("Photos taken on or after 2020-01-01.");
    expect(describeSearch({ takenTo: "2020-12-31" })).toBe("Photos taken on or before 2020-12-31.");
  });

  it("resolves a camera's friendly name from the options list", () => {
    const description = describeSearch(
      { make: "Canon", model: "EOS R5" },
      { cameras: [{ make: "Canon", model: "EOS R5", friendlyName: "Canon EOS R5" }] },
    );
    expect(description).toBe("Photos shot on a Canon EOS R5.");
  });

  it("describes a numeric range with units", () => {
    expect(describeSearch({ fMin: 2, fMax: 4 })).toBe("Photos an f-number between f/2 and f/4.");
    expect(describeSearch({ flMin: 50 })).toBe("Photos a focal length of at least 50mm.");
  });

  it("resolves an album's title from the options list", () => {
    const description = describeSearch(
      { album: "my-album" },
      { albums: [{ id: "my-album", title: "My Album" }] },
    );
    expect(description).toBe('Photos in the album "My Album".');
  });

  it("describes noAlbum instead of the album filter", () => {
    expect(describeSearch({ noAlbum: true, album: "my-album" })).toBe("Photos not in any album.");
  });

  it("joins several clauses with commas and a final and", () => {
    expect(describeSearch({ untagged: true, noTitle: true, scanned: true })).toBe(
      "Photos with no tags, with no title, and that are scanned.",
    );
  });
});
