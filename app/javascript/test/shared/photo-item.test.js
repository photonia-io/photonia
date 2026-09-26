import { describe, it, expect, vi, beforeEach } from "vitest";
import { mount, RouterLinkStub } from "@vue/test-utils";
import { createPinia, setActivePinia } from "pinia";

const { push } = vi.hoisted(() => ({ push: vi.fn() }));

vi.mock("vue-router", () => ({
  useRouter: () => ({ push }),
}));

import PhotoItem from "../../shared/photo-item.vue";
import { useUserStore } from "../../stores/user";
import { useSelectionStore } from "../../stores/selection";

const nonEditablePhoto = {
  id: "some-slug",
  title: "A photo",
  intelligentOrSquareMediumImageUrl: "https://example.com/photo.jpg",
  canEdit: false,
};

const editablePhoto = {
  id: "editable-slug",
  title: "An editable photo",
  intelligentOrSquareMediumImageUrl: "https://example.com/editable.jpg",
  canEdit: true,
};

function mountPhotoItem(props = {}, { signedIn = false, uploader = false } = {}) {
  const pinia = createPinia();
  setActivePinia(pinia);

  const userStore = useUserStore();
  userStore.signedIn = signedIn;
  userStore.uploader = uploader;
  if (signedIn) userStore.email = "owner@example.com";

  const selectionStore = useSelectionStore();
  selectionStore.setContext("test-context");

  const wrapper = mount(PhotoItem, {
    global: {
      plugins: [pinia],
      stubs: { RouterLink: RouterLinkStub },
    },
    props: { photo: nonEditablePhoto, ...props },
  });

  return { wrapper, userStore, selectionStore };
}

const photoLinks = (wrapper) =>
  wrapper.findAllComponents(RouterLinkStub).map((link) => link.props().to);

describe("PhotoItem", () => {
  beforeEach(() => {
    push.mockClear();
    // happy-dom's localStorage isn't reset between tests in the same file,
    // and the store persists selection per signed-in user.
    localStorage.clear();
  });

  describe("when the photo can't be selected (not editable, or not signed in)", () => {
    it("links to the photo with no query", () => {
      const { wrapper } = mountPhotoItem();

      expect(photoLinks(wrapper)).toEqual([
        { name: "photos-show", params: { id: "some-slug" } },
      ]);
    });

    it("starts album navigation on the photo link when an albumId is given", () => {
      const { wrapper } = mountPhotoItem({
        photo: nonEditablePhoto,
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

    it("omits the query when no album slug is given", () => {
      const { wrapper } = mountPhotoItem({ photo: nonEditablePhoto, inAlbum: true });

      expect(photoLinks(wrapper)).toEqual([
        { name: "photos-show", params: { id: "some-slug" } },
      ]);
    });

    it("shows no checkbox even for a signed-in uploader if the photo itself is not editable", () => {
      const { wrapper } = mountPhotoItem(
        { photo: nonEditablePhoto },
        { signedIn: true, uploader: true },
      );

      expect(wrapper.find(".item-checkbox-container").exists()).toBe(false);
    });
  });

  describe("when the photo is editable and the user can select", () => {
    it("renders a checkbox instead of a plain image link", () => {
      const { wrapper } = mountPhotoItem(
        { photo: editablePhoto },
        { signedIn: true, uploader: true },
      );

      expect(wrapper.find(".item-checkbox-container").exists()).toBe(true);
      // The title stays a real link either way.
      expect(photoLinks(wrapper)).toEqual([
        { name: "photos-show", params: { id: "editable-slug" } },
      ]);
    });

    it("toggles selection when the checkbox is clicked, without navigating", async () => {
      const { wrapper, selectionStore } = mountPhotoItem(
        { photo: editablePhoto },
        { signedIn: true, uploader: true },
      );

      await wrapper.find(".item-checkbox-container").trigger("click");

      expect(selectionStore.isSelected("editable-slug")).toBe(true);
      expect(push).not.toHaveBeenCalled();

      await wrapper.find(".item-checkbox-container").trigger("click");
      expect(selectionStore.isSelected("editable-slug")).toBe(false);
    });

    it("navigates on a plain click when nothing is selected", async () => {
      const { wrapper } = mountPhotoItem(
        { photo: editablePhoto },
        { signedIn: true, uploader: true },
      );

      await wrapper.find(".photo-card").trigger("click");

      expect(push).toHaveBeenCalledWith({
        name: "photos-show",
        params: { id: "editable-slug" },
      });
    });

    it("toggles instead of navigating once something is already selected", async () => {
      const { wrapper, selectionStore } = mountPhotoItem(
        { photo: editablePhoto },
        { signedIn: true, uploader: true },
      );

      selectionStore.add({ id: "other-slug", title: "Other" });

      await wrapper.find(".photo-card").trigger("click");

      expect(push).not.toHaveBeenCalled();
      expect(selectionStore.isSelected("editable-slug")).toBe(true);
    });

    it("toggles on a Ctrl/Cmd-click even with nothing else selected", async () => {
      const { wrapper, selectionStore } = mountPhotoItem(
        { photo: editablePhoto },
        { signedIn: true, uploader: true },
      );

      await wrapper.find(".photo-card").trigger("click.ctrl");

      expect(push).not.toHaveBeenCalled();
      expect(selectionStore.isSelected("editable-slug")).toBe(true);
    });

    it("activates on Enter and Space, since the card is focusable", async () => {
      const { wrapper, selectionStore } = mountPhotoItem(
        { photo: editablePhoto },
        { signedIn: true, uploader: true },
      );

      await wrapper.find(".photo-card").trigger("keydown.enter");
      expect(push).toHaveBeenCalledTimes(1);

      selectionStore.add({ id: "other-slug", title: "Other" });
      await wrapper.find(".photo-card").trigger("keydown.space");
      expect(selectionStore.isSelected("editable-slug")).toBe(true);
    });

    it("emits set-cover-photo when the cover star is clicked", async () => {
      const { wrapper } = mountPhotoItem(
        { photo: { ...editablePhoto, isCoverPhoto: false }, inAlbum: true, canEditAlbum: true },
        { signedIn: true, uploader: true },
      );

      await wrapper.find(".cover-photo-icon-container").trigger("click");

      expect(wrapper.emitted("set-cover-photo")).toBeTruthy();
      expect(push).not.toHaveBeenCalled();
    });
  });
});
