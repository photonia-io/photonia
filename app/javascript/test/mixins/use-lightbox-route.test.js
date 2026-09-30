import { describe, it, expect, vi, beforeEach } from "vitest";
import { createPinia, setActivePinia } from "pinia";

const { push, replace, back, routeRef } = vi.hoisted(() => ({
  push: vi.fn(),
  replace: vi.fn(),
  back: vi.fn(),
  routeRef: { current: {} },
}));

vi.mock("vue-router", () => ({
  useRoute: () => routeRef.current,
  useRouter: () => ({ push, replace, back }),
}));

import {
  LIGHTBOX_PARAM,
  onlyLightboxToggled,
  useLightboxRoute,
} from "../../mixins/use-lightbox-route";
import { useApplicationStore } from "../../stores/application";

function setup(query = {}) {
  routeRef.current = { path: "/photos/a", query };
  setActivePinia(createPinia());
  return {
    ...useLightboxRoute(),
    applicationStore: useApplicationStore(),
  };
}

beforeEach(() => {
  push.mockClear();
  replace.mockClear();
  back.mockClear();
});

describe("onlyLightboxToggled", () => {
  it("is true when only the lightbox param is added", () => {
    const from = { path: "/photos/a", query: { inAlbum: "x" } };
    const to = { path: "/photos/a", query: { inAlbum: "x", lightbox: "1" } };
    expect(onlyLightboxToggled(to, from)).toBe(true);
  });

  it("is true when only the lightbox param is removed", () => {
    const from = { path: "/photos/a", query: { lightbox: "1" } };
    const to = { path: "/photos/a", query: {} };
    expect(onlyLightboxToggled(to, from)).toBe(true);
  });

  it("is false for a different path", () => {
    const from = { path: "/photos/a", query: {} };
    const to = { path: "/photos/b", query: { lightbox: "1" } };
    expect(onlyLightboxToggled(to, from)).toBe(false);
  });

  it("is false when another query param also changes", () => {
    const from = { path: "/photos/a", query: { inAlbum: "x" } };
    const to = { path: "/photos/a", query: { inAlbum: "y", lightbox: "1" } };
    expect(onlyLightboxToggled(to, from)).toBe(false);
  });

  it("is true when nothing changes at all", () => {
    const from = { path: "/photos/a", query: { inAlbum: "x" } };
    const to = { path: "/photos/a", query: { inAlbum: "x" } };
    expect(onlyLightboxToggled(to, from)).toBe(true);
  });
});

describe("useLightboxRoute", () => {
  describe("lightboxRequested", () => {
    it("is false without the param", () => {
      expect(setup({}).lightboxRequested.value).toBe(false);
    });

    it("is true with the param", () => {
      expect(setup({ [LIGHTBOX_PARAM]: "1" }).lightboxRequested.value).toBe(
        true,
      );
    });
  });

  describe("openLightboxRoute", () => {
    it("pushes the param onto the current route, keeping other query keys", () => {
      const { openLightboxRoute, applicationStore } = setup({ inAlbum: "x" });

      openLightboxRoute();

      expect(push).toHaveBeenCalledWith({
        path: "/photos/a",
        query: { inAlbum: "x", lightbox: "1" },
      });
      expect(applicationStore.lightboxOpenedByPush).toBe(true);
    });
  });

  describe("acknowledgeLightboxFromUrl", () => {
    it("marks the open as not pushed by the app", () => {
      const { acknowledgeLightboxFromUrl, applicationStore } = setup({
        lightbox: "1",
      });
      applicationStore.lightboxOpenedByPush = true;

      acknowledgeLightboxFromUrl();

      expect(applicationStore.lightboxOpenedByPush).toBe(false);
    });
  });

  describe("leaveLightboxRoute", () => {
    it("goes back when the app pushed the entry", () => {
      const { leaveLightboxRoute, applicationStore } = setup({
        lightbox: "1",
      });
      applicationStore.lightboxOpenedByPush = true;

      leaveLightboxRoute();

      expect(back).toHaveBeenCalledOnce();
      expect(replace).not.toHaveBeenCalled();
    });

    it("replaces, dropping only the param, otherwise", () => {
      const { leaveLightboxRoute, applicationStore } = setup({
        lightbox: "1",
        inAlbum: "x",
      });
      applicationStore.lightboxOpenedByPush = false;

      leaveLightboxRoute();

      expect(replace).toHaveBeenCalledWith({
        path: "/photos/a",
        query: { inAlbum: "x" },
      });
      expect(back).not.toHaveBeenCalled();
    });
  });

  describe("stepInLightbox", () => {
    it("replaces to the target, then pushes its own lightbox entry, flagging the step throughout", async () => {
      const { stepInLightbox, applicationStore } = setup({ lightbox: "1" });
      const target = {
        name: "photos-show",
        params: { id: "b" },
        query: { inAlbum: "x" },
      };
      let steppingDuringReplace, steppingDuringPush;
      replace.mockImplementation(() => {
        steppingDuringReplace = applicationStore.lightboxStepping;
      });
      push.mockImplementation(() => {
        steppingDuringPush = applicationStore.lightboxStepping;
      });

      await stepInLightbox(target);

      expect(steppingDuringReplace).toBe(true);
      expect(steppingDuringPush).toBe(true);
      expect(replace).toHaveBeenCalledWith(target);
      expect(push).toHaveBeenCalledWith({
        ...target,
        query: { inAlbum: "x", lightbox: "1" },
      });
      expect(applicationStore.lightboxOpenedByPush).toBe(true);
      expect(applicationStore.lightboxStepping).toBe(false);
    });

    it("clears the stepping flag even if the navigation throws", async () => {
      const { stepInLightbox, applicationStore } = setup({ lightbox: "1" });
      replace.mockRejectedValueOnce(new Error("nope"));

      await expect(
        stepInLightbox({ name: "photos-show", params: { id: "b" }, query: {} }),
      ).rejects.toThrow("nope");

      expect(applicationStore.lightboxStepping).toBe(false);
    });
  });
});
