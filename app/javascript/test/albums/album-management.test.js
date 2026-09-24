import { describe, it, expect, vi, beforeEach, afterEach } from "vitest";
import { mount, DOMWrapper } from "@vue/test-utils";
import { createPinia, setActivePinia } from "pinia";

const { push } = vi.hoisted(() => ({ push: vi.fn() }));

vi.mock("vue-router", () => ({
  useRouter: () => ({ push }),
}));

import AlbumManagement from "../../albums/album-management.vue";
import { useApplicationStore } from "../../stores/application";

// The privacy modal is teleported to #modal-root, outside the component's
// own DOM tree, so it must be queried through the document body.
const body = () => new DOMWrapper(document.body);
const privacyModal = () =>
  body()
    .findAll(".modal")
    .find((modal) => modal.text().includes("Change Album Privacy"));

const baseAlbum = {
  id: "some-slug",
  privacy: "public",
  sortingType: "takenAt",
  sortingOrder: "asc",
  photosCount: 3,
};

let mountedWrapper;

function mountAlbumManagement(props = {}) {
  const pinia = createPinia();
  setActivePinia(pinia);

  const wrapper = mount(AlbumManagement, {
    attachTo: document.body,
    global: { plugins: [pinia] },
    props: {
      album: baseAlbum,
      ...props,
    },
  });
  mountedWrapper = wrapper;

  return { wrapper, applicationStore: useApplicationStore() };
}

describe("AlbumManagement", () => {
  let modalRoot;

  beforeEach(() => {
    modalRoot = document.createElement("div");
    modalRoot.id = "modal-root";
    document.body.appendChild(modalRoot);
  });

  afterEach(() => {
    mountedWrapper?.unmount();
    mountedWrapper = undefined;
    modalRoot.remove();
  });

  describe("privacy confirmation modal", () => {
    it("appears when changing a public album with photos to private", async () => {
      const { wrapper } = mountAlbumManagement({
        album: { ...baseAlbum, privacy: "public" },
      });

      await wrapper.find("#album-privacy").setValue("private");

      expect(privacyModal().classes()).toContain("is-active");
      expect(wrapper.emitted("setAlbumPrivacy")).toBeUndefined();
    });

    it("appears when changing a friends_and_family album with photos to private", async () => {
      const { wrapper } = mountAlbumManagement({
        album: { ...baseAlbum, privacy: "friends_and_family" },
      });

      await wrapper.find("#album-privacy").setValue("private");

      expect(privacyModal().classes()).toContain("is-active");
    });

    it("does not appear for an empty album", async () => {
      const { wrapper } = mountAlbumManagement({
        album: { ...baseAlbum, privacy: "public", photosCount: 0 },
      });

      await wrapper.find("#album-privacy").setValue("private");

      expect(privacyModal().classes()).not.toContain("is-active");
      expect(wrapper.emitted("setAlbumPrivacy")[0][0]).toEqual({
        id: baseAlbum.id,
        privacy: "private",
        updatePhotos: false,
      });
    });

    it("does not appear when changing to public", async () => {
      const { wrapper } = mountAlbumManagement({
        album: { ...baseAlbum, privacy: "private" },
      });

      await wrapper.find("#album-privacy").setValue("public");

      expect(privacyModal().classes()).not.toContain("is-active");
      expect(wrapper.emitted("setAlbumPrivacy")[0][0]).toEqual({
        id: baseAlbum.id,
        privacy: "public",
        updatePhotos: false,
      });
    });

    it("emits setAlbumPrivacy with updatePhotos true on confirm", async () => {
      const { wrapper } = mountAlbumManagement();

      await wrapper.find("#album-privacy").setValue("private");
      await privacyModal().find(".is-warning").trigger("click");

      expect(wrapper.emitted("setAlbumPrivacy")[0][0]).toEqual({
        id: baseAlbum.id,
        privacy: "private",
        updatePhotos: true,
      });
      expect(privacyModal().classes()).not.toContain("is-active");
    });

    it("reverts the select and emits nothing on cancel", async () => {
      const { wrapper, applicationStore } = mountAlbumManagement();

      await wrapper.find("#album-privacy").setValue("private");
      await privacyModal().find(".is-info").trigger("click");

      expect(wrapper.emitted("setAlbumPrivacy")).toBeUndefined();
      expect(wrapper.find("#album-privacy").element.value).toBe("public");
      expect(privacyModal().classes()).not.toContain("is-active");
      expect(applicationStore.navigationShortcutsEnabled).toBe(true);
    });
  });
});
