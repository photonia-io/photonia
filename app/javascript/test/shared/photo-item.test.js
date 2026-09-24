import { describe, it, expect, beforeEach } from "vitest";
import { mount, RouterLinkStub } from "@vue/test-utils";
import { createPinia, setActivePinia } from "pinia";

import PhotoItem from "../../shared/photo-item.vue";
import { useApplicationStore } from "../../stores/application";

const photo = {
  id: "some-slug",
  title: "A photo",
  intelligentOrSquareMediumImageUrl: "https://example.com/photo.jpg",
  canEdit: false,
};

function mountPhotoItem(props = {}) {
  const pinia = createPinia();
  setActivePinia(pinia);

  const wrapper = mount(PhotoItem, {
    global: {
      plugins: [pinia],
      stubs: { RouterLink: RouterLinkStub },
    },
    props: { photo, ...props },
  });

  return { wrapper, applicationStore: useApplicationStore() };
}

const photoLinks = (wrapper) =>
  wrapper.findAllComponents(RouterLinkStub).map((link) => link.props().to);

describe("PhotoItem", () => {
  describe("outside an album", () => {
    it("links to the photo with no query", () => {
      const { wrapper } = mountPhotoItem();

      expect(photoLinks(wrapper)).toEqual([
        { name: "photos-show", params: { id: "some-slug" } },
      ]);
    });
  });

  describe("inside an album", () => {
    it("starts album navigation on the photo link", () => {
      const { wrapper } = mountPhotoItem({
        inAlbum: true,
        albumId: "sunset-trip",
      });

      expect(photoLinks(wrapper)).toEqual([
        {
          name: "photos-show",
          params: { id: "some-slug" },
          query: { inAlbum: "sunset-trip" },
        },
      ]);
    });

    // `inAlbum` only picks the selection store - the album slug is what decides
    // whether the link carries navigation context.
    it("omits the query when no album slug is given", () => {
      const { wrapper } = mountPhotoItem({ inAlbum: true });

      expect(photoLinks(wrapper)).toEqual([
        { name: "photos-show", params: { id: "some-slug" } },
      ]);
    });

    it("carries the album slug in selection mode too", () => {
      const { wrapper, applicationStore } = mountPhotoItem({
        inAlbum: true,
        albumId: "sunset-trip",
      });

      applicationStore.enterSelectionMode();

      return wrapper.vm.$nextTick().then(() => {
        expect(photoLinks(wrapper)).toEqual([
          {
            name: "photos-show",
            params: { id: "some-slug" },
            query: { inAlbum: "sunset-trip" },
          },
        ]);
      });
    });
  });
});
