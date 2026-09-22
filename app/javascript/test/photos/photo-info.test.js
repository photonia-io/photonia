import { describe, it, expect, beforeEach, afterEach } from "vitest";
import { mount, DOMWrapper } from "@vue/test-utils";
import { createPinia, setActivePinia } from "pinia";

import PhotoInfo from "../../photos/photo-info.vue";
import { useApplicationStore } from "../../stores/application";

// The privacy modal is teleported to #modal-root, outside the component's
// own DOM tree, so it must be queried through the document body rather
// than through the mounted wrapper.
const body = () => new DOMWrapper(document.body);

const basePhoto = {
  id: "some-slug",
  impressionsCount: 42,
  takenAt: "2024-01-01T00:00:00Z",
  postedAt: "2024-01-02T00:00:00Z",
  isTakenAtFromExif: false,
  rekognitionLabelModelVersion: "",
  privacy: "private",
};

let mountedWrapper;

function mountPhotoInfo(props = {}) {
  const pinia = createPinia();
  setActivePinia(pinia);

  const wrapper = mount(PhotoInfo, {
    attachTo: document.body,
    global: { plugins: [pinia] },
    props: {
      photo: basePhoto,
      loading: false,
      canEdit: true,
      ...props,
    },
  });
  mountedWrapper = wrapper;

  return { wrapper, applicationStore: useApplicationStore() };
}

describe("PhotoInfo", () => {
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

  describe("Privacy row visibility", () => {
    it("is absent when canEdit is false", () => {
      const { wrapper } = mountPhotoInfo({ canEdit: false });
      expect(wrapper.text()).not.toContain("Privacy:");
    });

    it("is shown when canEdit is true", () => {
      const { wrapper } = mountPhotoInfo({ canEdit: true });
      expect(wrapper.text()).toContain("Privacy:");
    });
  });

  describe("Privacy label", () => {
    it.each([
      ["public", "Public"],
      ["private", "Private"],
      ["friends_and_family", "Friends & Family"],
    ])("renders %s as %s", (privacy, label) => {
      const { wrapper } = mountPhotoInfo({
        photo: { ...basePhoto, privacy },
      });
      expect(wrapper.text()).toContain(label);
    });
  });

  describe("Privacy modal", () => {
    it("is not active initially", () => {
      mountPhotoInfo();
      expect(body().find(".modal").classes()).not.toContain("is-active");
    });

    it("renders the privacy trigger as a native button", () => {
      const { wrapper } = mountPhotoInfo();
      expect(wrapper.find(".is-underlined").element.tagName).toBe("BUTTON");
    });

    it("closes on Escape and restores navigation shortcuts", async () => {
      const { wrapper, applicationStore } = mountPhotoInfo({
        photo: { ...basePhoto, privacy: "private" },
      });
      await wrapper.find(".is-underlined").trigger("click");
      expect(body().find(".modal").classes()).toContain("is-active");

      document.dispatchEvent(new KeyboardEvent("keydown", { key: "Escape" }));
      await wrapper.vm.$nextTick();

      expect(body().find(".modal").classes()).not.toContain("is-active");
      expect(applicationStore.navigationShortcutsEnabled).toBe(true);
    });

    it("moves focus into the modal on open and restores it to the trigger on close", async () => {
      const { wrapper } = mountPhotoInfo({
        photo: { ...basePhoto, privacy: "private" },
      });
      const trigger = wrapper.find(".is-underlined");
      await trigger.trigger("click");
      await wrapper.vm.$nextTick();

      expect(document.activeElement).toBe(body().find(".modal-card").element);

      await body().find(".button.is-info").trigger("click");

      expect(document.activeElement).toBe(trigger.element);
    });

    it("re-enables navigation shortcuts if unmounted while the modal is open", async () => {
      const { wrapper, applicationStore } = mountPhotoInfo({
        photo: { ...basePhoto, privacy: "private" },
      });
      await wrapper.find(".is-underlined").trigger("click");
      expect(applicationStore.navigationShortcutsEnabled).toBe(false);

      wrapper.unmount();
      mountedWrapper = undefined;

      expect(applicationStore.navigationShortcutsEnabled).toBe(true);
    });

    it("opens when the privacy value is clicked and disables navigation shortcuts", async () => {
      const { wrapper, applicationStore } = mountPhotoInfo({
        photo: { ...basePhoto, privacy: "private" },
      });

      await wrapper.find(".is-underlined").trigger("click");

      expect(body().find(".modal").classes()).toContain("is-active");
      expect(applicationStore.navigationShortcutsEnabled).toBe(false);
    });

    it("disables the friends_and_family option", async () => {
      const { wrapper } = mountPhotoInfo();
      await wrapper.find(".is-underlined").trigger("click");

      const friendsRadio = body().find(
        'input[type="radio"][value="friends_and_family"]',
      );
      expect(friendsRadio.attributes("disabled")).toBeDefined();
    });

    it("checks the existing value, even if it is friends_and_family", async () => {
      const { wrapper } = mountPhotoInfo({
        photo: { ...basePhoto, privacy: "friends_and_family" },
      });
      await wrapper.find(".is-underlined").trigger("click");

      const friendsRadio = body().find(
        'input[type="radio"][value="friends_and_family"]',
      );
      expect(friendsRadio.element.checked).toBe(true);
    });

    it("emits updatePrivacy with the new value when confirmed", async () => {
      const { wrapper } = mountPhotoInfo({
        photo: { ...basePhoto, privacy: "private" },
      });
      await wrapper.find(".is-underlined").trigger("click");

      const publicRadio = body().find('input[type="radio"][value="public"]');
      await publicRadio.setValue(true);

      await body().find(".button.is-primary").trigger("click");

      expect(wrapper.emitted("updatePrivacy")).toBeTruthy();
      expect(wrapper.emitted("updatePrivacy")[0]).toEqual([
        { id: "some-slug", privacy: "public" },
      ]);
      expect(body().find(".modal").classes()).not.toContain("is-active");
    });

    it("does not emit updatePrivacy when the selection is unchanged", async () => {
      const { wrapper } = mountPhotoInfo({
        photo: { ...basePhoto, privacy: "private" },
      });
      await wrapper.find(".is-underlined").trigger("click");

      await body().find(".button.is-primary").trigger("click");

      expect(wrapper.emitted("updatePrivacy")).toBeFalsy();
    });

    it("emits nothing and re-enables navigation shortcuts on cancel", async () => {
      const { wrapper, applicationStore } = mountPhotoInfo({
        photo: { ...basePhoto, privacy: "private" },
      });
      await wrapper.find(".is-underlined").trigger("click");

      const publicRadio = body().find('input[type="radio"][value="public"]');
      await publicRadio.setValue(true);

      await body().find(".button.is-info").trigger("click");

      expect(wrapper.emitted("updatePrivacy")).toBeFalsy();
      expect(body().find(".modal").classes()).not.toContain("is-active");
      expect(applicationStore.navigationShortcutsEnabled).toBe(true);
    });
  });
});
