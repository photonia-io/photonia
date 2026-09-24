import { describe, it, expect, vi, beforeEach } from "vitest";
import { ref } from "vue";

const { push, routeRef } = vi.hoisted(() => ({
  push: vi.fn(),
  routeRef: { current: {} },
}));

vi.mock("vue-router", () => ({
  useRoute: () => routeRef.current,
  useRouter: () => ({ push }),
}));

import {
  isTypingTarget,
  useAlbumNavigation,
} from "../../mixins/use-album-navigation";

const album = {
  id: "sunset-trip",
  title: "Sunset trip",
  previousPhotoInAlbum: { id: "photo-1" },
  nextPhotoInAlbum: { id: "photo-3" },
  photoPositionInAlbum: { position: 2, total: 3, page: 1 },
};

const photoIn = (albums) => ref({ id: "photo-2", albums });

// `inAlbum` is the album slug currently being navigated, if any
function setup({ inAlbum, albums = [album] } = {}) {
  routeRef.current = {
    params: { id: "photo-2" },
    query: inAlbum ? { inAlbum } : {},
  };

  return useAlbumNavigation(photoIn(albums));
}

beforeEach(() => {
  push.mockClear();
});

describe("useAlbumNavigation", () => {
  describe("inAlbumId", () => {
    it("is null when the param is absent", () => {
      expect(setup().inAlbumId.value).toBeNull();
    });

    it("reads the album slug from the query param", () => {
      expect(setup({ inAlbum: "sunset-trip" }).inAlbumId.value).toBe(
        "sunset-trip",
      );
    });
  });

  describe("navigatingAlbum", () => {
    it("is null when no album is being navigated", () => {
      expect(setup().navigatingAlbum.value).toBeNull();
    });

    it("resolves the album the photo is in", () => {
      expect(setup({ inAlbum: "sunset-trip" }).navigatingAlbum.value).toEqual(
        album,
      );
    });

    // The dormant case: we left the album via global navigation, so the param
    // is still set but the current photo is not in that album.
    it("is null when the current photo is not in the named album", () => {
      const { navigatingAlbum } = setup({
        inAlbum: "some-other-album",
      });

      expect(navigatingAlbum.value).toBeNull();
    });

    it("is null when the photo has no albums at all", () => {
      const { navigatingAlbum } = setup({
        inAlbum: "sunset-trip",
        albums: null,
      });

      expect(navigatingAlbum.value).toBeNull();
    });
  });

  describe("navigationQuery", () => {
    it("is empty when not navigating an album", () => {
      expect(setup().navigationQuery.value).toEqual({});
    });

    it("carries the album slug so the mode survives global navigation", () => {
      expect(setup({ inAlbum: "sunset-trip" }).navigationQuery.value).toEqual({
        inAlbum: "sunset-trip",
      });
    });

    // Still carried while dormant, so navigating back into the album resumes
    it("carries the album slug even when dormant", () => {
      expect(setup({ inAlbum: "gone-album" }).navigationQuery.value).toEqual({
        inAlbum: "gone-album",
      });
    });
  });

  describe("navigateToPhoto", () => {
    it("preserves the album navigation param", () => {
      setup({ inAlbum: "sunset-trip" }).navigateToPhoto({ id: "photo-9" });

      expect(push).toHaveBeenCalledWith({
        name: "photos-show",
        params: { id: "photo-9" },
        query: { inAlbum: "sunset-trip" },
      });
    });

    it("does nothing without a target", () => {
      setup().navigateToPhoto(null);

      expect(push).not.toHaveBeenCalled();
    });
  });

  describe("in-album navigation", () => {
    it("moves to the next photo in the album", () => {
      setup({ inAlbum: "sunset-trip" }).navigateToNextPhotoInAlbum();

      expect(push).toHaveBeenCalledWith({
        name: "photos-show",
        params: { id: "photo-3" },
        query: { inAlbum: "sunset-trip" },
      });
    });

    it("moves to the previous photo in the album", () => {
      setup({ inAlbum: "sunset-trip" }).navigateToPreviousPhotoInAlbum();

      expect(push).toHaveBeenCalledWith({
        name: "photos-show",
        params: { id: "photo-1" },
        query: { inAlbum: "sunset-trip" },
      });
    });

    it("does nothing when no album is being navigated", () => {
      const navigation = setup();

      navigation.navigateToNextPhotoInAlbum();
      navigation.navigateToPreviousPhotoInAlbum();

      expect(push).not.toHaveBeenCalled();
    });

    it("does nothing while dormant", () => {
      const navigation = setup({ inAlbum: "some-other-album" });

      navigation.navigateToNextPhotoInAlbum();
      navigation.navigateToPreviousPhotoInAlbum();

      expect(push).not.toHaveBeenCalled();
    });

    it("stops at the ends of the album", () => {
      const navigation = setup({
        inAlbum: "sunset-trip",
        albums: [
          {
            id: "sunset-trip",
            previousPhotoInAlbum: null,
            nextPhotoInAlbum: null,
          },
        ],
      });

      navigation.navigateToNextPhotoInAlbum();
      navigation.navigateToPreviousPhotoInAlbum();

      expect(push).not.toHaveBeenCalled();
    });
  });

  describe("startNavigatingAlbum", () => {
    it("sets the param on the photo we are already viewing", () => {
      setup().startNavigatingAlbum("sunset-trip");

      expect(push).toHaveBeenCalledWith({
        name: "photos-show",
        params: { id: "photo-2" },
        query: { inAlbum: "sunset-trip" },
      });
    });

    it("switches to another album", () => {
      setup({ inAlbum: "sunset-trip" }).startNavigatingAlbum("winter-trip");

      expect(push).toHaveBeenCalledWith({
        name: "photos-show",
        params: { id: "photo-2" },
        query: { inAlbum: "winter-trip" },
      });
    });
  });

  describe("stopNavigatingAlbum", () => {
    it("drops the param", () => {
      setup({ inAlbum: "sunset-trip" }).stopNavigatingAlbum();

      expect(push).toHaveBeenCalledWith({
        name: "photos-show",
        params: { id: "photo-2" },
      });
    });
  });

  describe("albumRoute", () => {
    it("links to the first page without a page param", () => {
      expect(setup().albumRoute(album)).toEqual({
        name: "albums-show",
        params: { id: "sunset-trip" },
        query: {},
      });
    });

    it("links to the page the photo is actually on", () => {
      const route = setup().albumRoute({
        id: "sunset-trip",
        photoPositionInAlbum: { position: 42, total: 87, page: 3 },
      });

      expect(route.query).toEqual({ page: 3 });
    });

    it("omits the page when the position is unknown", () => {
      expect(setup().albumRoute({ id: "sunset-trip" }).query).toEqual({});
    });
  });
});

describe("isTypingTarget", () => {
  it.each(["INPUT", "TEXTAREA", "SELECT"])("is true for %s", (tagName) => {
    expect(isTypingTarget({ tagName })).toBe(true);
  });

  it.each(["text", "email", "url", "tel", "number", "password", "search"])(
    "is true for an input of type %s",
    (type) => {
      expect(isTypingTarget({ tagName: "INPUT", type })).toBe(true);
    },
  );

  // A checkbox keeps focus after a click, so treating it as typing would
  // leave the navigation shortcuts dead until the user clicked elsewhere.
  it.each(["checkbox", "radio", "button", "submit", "reset", "file", "range"])(
    "is false for an input of type %s",
    (type) => {
      expect(isTypingTarget({ tagName: "INPUT", type })).toBe(false);
    },
  );

  it("ignores the case of the input type", () => {
    expect(isTypingTarget({ tagName: "INPUT", type: "CheckBox" })).toBe(false);
  });

  it("is true for a contenteditable element", () => {
    expect(isTypingTarget({ tagName: "DIV", isContentEditable: true })).toBe(
      true,
    );
  });

  it("is false for an ordinary element", () => {
    expect(isTypingTarget({ tagName: "DIV" })).toBe(false);
  });

  it("is false without a target", () => {
    expect(isTypingTarget(null)).toBeFalsy();
  });
});
