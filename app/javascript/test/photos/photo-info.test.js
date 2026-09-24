import { describe, it, expect, beforeEach, afterEach } from "vitest";
import { mount, DOMWrapper } from "@vue/test-utils";
import { createPinia, setActivePinia } from "pinia";

import PhotoInfo from "../../photos/photo-info.vue";
import { useApplicationStore } from "../../stores/application";

// Both modals are teleported to #modal-root, outside the component's own
// DOM tree, so they must be queried through the document body rather than
// through the mounted wrapper.
const body = () => new DOMWrapper(document.body);

// Disambiguates the teleported ".modal" divs (privacy, Date Taken, License).
const takenAtModal = () =>
  body()
    .findAll(".modal")
    .find((modal) => modal.find('[aria-label="Photo Date Taken"]').exists());

const licenseModal = () =>
  body()
    .findAll(".modal")
    .find((modal) => modal.find('[aria-label="Photo License"]').exists());

const basePhoto = {
  id: "some-slug",
  impressionsCount: 42,
  takenAt: "2024-01-01T00:00:00Z",
  takenAtInfo: {
    year: 2024,
    month: 1,
    day: 1,
    hour: 0,
    minute: 0,
    precision: "minute",
    source: "exif",
    approximate: false,
    exifAvailable: true,
  },
  scanned: false,
  postedAt: "2024-01-02T00:00:00Z",
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

  describe("Date Taken trigger", () => {
    it("renders as plain text when canEdit is false", () => {
      const { wrapper } = mountPhotoInfo({ canEdit: false });
      expect(wrapper.find(".taken-at-trigger").exists()).toBe(false);
      expect(wrapper.text()).toContain("Date Taken:");
    });

    it("renders as a button when canEdit is true", () => {
      const { wrapper } = mountPhotoInfo({ canEdit: true });
      expect(wrapper.find(".taken-at-trigger").element.tagName).toBe(
        "BUTTON",
      );
    });
  });

  describe("Date Taken formatting", () => {
    it.each([
      ["year", { year: 1985 }, "1985"],
      ["month", { year: 1985, month: 8 }, "August 1985"],
      ["day", { year: 1985, month: 8, day: 31 }, "Saturday, August 31st 1985"],
      [
        "minute",
        { year: 1985, month: 8, day: 31, hour: 17, minute: 5 },
        "Saturday, August 31st 1985, 17:05",
      ],
    ])("formats %s precision as %s", (precision, parts, expected) => {
      const { wrapper } = mountPhotoInfo({
        photo: {
          ...basePhoto,
          takenAtInfo: {
            ...basePhoto.takenAtInfo,
            year: null,
            month: null,
            day: null,
            hour: null,
            minute: null,
            ...parts,
            precision,
          },
        },
      });
      expect(wrapper.find(".taken-at-trigger").text()).toBe(expected);
    });
  });

  describe("Date Taken chips", () => {
    it("shows an EXIF chip when the source is exif", () => {
      const { wrapper } = mountPhotoInfo({
        photo: { ...basePhoto, takenAtInfo: { ...basePhoto.takenAtInfo, source: "exif" } },
      });
      expect(wrapper.text()).toContain("EXIF");
      expect(wrapper.text()).not.toContain("User Set");
    });

    it("shows a User Set chip when the source is user", () => {
      const { wrapper } = mountPhotoInfo({
        photo: { ...basePhoto, takenAtInfo: { ...basePhoto.takenAtInfo, source: "user" } },
      });
      expect(wrapper.text()).toContain("User Set");
    });

    it("shows no source chip when the source is unknown", () => {
      const { wrapper } = mountPhotoInfo({
        photo: { ...basePhoto, takenAtInfo: { ...basePhoto.takenAtInfo, source: "unknown" } },
      });
      expect(wrapper.text()).not.toContain("EXIF");
      expect(wrapper.text()).not.toContain("User Set");
    });

    it("shows a Scan chip when the photo is scanned", () => {
      const { wrapper } = mountPhotoInfo({
        photo: { ...basePhoto, scanned: true },
      });
      expect(wrapper.text()).toContain("Scan");
    });

    it("shows an Approximate chip when the date is approximate", () => {
      const { wrapper } = mountPhotoInfo({
        photo: {
          ...basePhoto,
          takenAtInfo: { ...basePhoto.takenAtInfo, approximate: true },
        },
      });
      expect(wrapper.text()).toContain("Approximate");
    });

    it("shows all three chips together", () => {
      const { wrapper } = mountPhotoInfo({
        photo: {
          ...basePhoto,
          scanned: true,
          takenAtInfo: {
            ...basePhoto.takenAtInfo,
            source: "user",
            approximate: true,
          },
        },
      });
      expect(wrapper.text()).toContain("User Set");
      expect(wrapper.text()).toContain("Scan");
      expect(wrapper.text()).toContain("Approximate");
    });

    it("gives each chip an explanatory title attribute", () => {
      const { wrapper } = mountPhotoInfo({
        photo: {
          ...basePhoto,
          scanned: true,
          takenAtInfo: {
            ...basePhoto.takenAtInfo,
            source: "user",
            approximate: true,
          },
        },
      });
      const chips = wrapper.findAll(".taken-at-chip");
      const titles = chips.map((chip) => chip.attributes("title"));
      expect(titles).toEqual([
        "This date was entered manually.",
        "This is a scan of a print or negative.",
        "This date is not exact.",
      ]);
    });
  });

  describe("Date Taken modal wiring", () => {
    it("opens the modal when the date is clicked", async () => {
      const { wrapper } = mountPhotoInfo();
      await wrapper.find(".taken-at-trigger").trigger("click");

      expect(
        body().find('[aria-label="Photo Date Taken"]').exists(),
      ).toBe(true);
    });

    it("emits updateTakenAt with the id when the modal saves", async () => {
      const { wrapper } = mountPhotoInfo();
      await wrapper.find(".taken-at-trigger").trigger("click");

      await body()
        .find('[aria-label="Photo Date Taken"] .button.is-primary')
        .trigger("click");

      expect(wrapper.emitted("updateTakenAt")).toBeTruthy();
      expect(wrapper.emitted("updateTakenAt")[0][0]).toMatchObject({
        id: "some-slug",
      });
    });

    it("emits resetTakenAt with the id when reset is clicked", async () => {
      const { wrapper } = mountPhotoInfo({
        photo: {
          ...basePhoto,
          takenAtInfo: { ...basePhoto.takenAtInfo, source: "user" },
        },
      });
      await wrapper.find(".taken-at-trigger").trigger("click");

      const resetButton = body()
        .findAll('[aria-label="Photo Date Taken"] .button.is-light')
        .find((btn) => btn.text().includes("Reset"));
      await resetButton.trigger("click");

      expect(wrapper.emitted("resetTakenAt")).toEqual([
        [{ id: "some-slug" }],
      ]);
    });

    it("returns focus to the trigger on close", async () => {
      const { wrapper } = mountPhotoInfo();
      const trigger = wrapper.find(".taken-at-trigger");
      await trigger.trigger("click");
      await wrapper.vm.$nextTick();

      const cancelButton = body()
        .findAll('[aria-label="Photo Date Taken"] .button')
        .find((btn) => btn.text() === "Cancel");
      await cancelButton.trigger("click");

      expect(document.activeElement).toBe(trigger.element);
    });

    it("stays open after saving, since show.vue owns the mutation result", async () => {
      const { wrapper } = mountPhotoInfo();
      await wrapper.find(".taken-at-trigger").trigger("click");

      await body()
        .find('[aria-label="Photo Date Taken"] .button.is-primary')
        .trigger("click");

      expect(takenAtModal().classes()).toContain("is-active");
    });

    it("exposes closeTakenAtModal for show.vue to call once the mutation succeeds", async () => {
      const { wrapper } = mountPhotoInfo();
      const trigger = wrapper.find(".taken-at-trigger");
      await trigger.trigger("click");
      expect(takenAtModal().classes()).toContain("is-active");

      wrapper.vm.closeTakenAtModal();
      await wrapper.vm.$nextTick();

      expect(takenAtModal().classes()).not.toContain("is-active");
      expect(document.activeElement).toBe(trigger.element);
    });
  });

  describe("License row", () => {
    it("is shown even when canEdit is false", () => {
      const { wrapper } = mountPhotoInfo({ canEdit: false });
      expect(wrapper.text()).toContain("License:");
    });

    it("defaults to All Rights Reserved when the license is blank", () => {
      const { wrapper } = mountPhotoInfo({
        canEdit: false,
        photo: { ...basePhoto, license: null },
      });
      expect(wrapper.text()).toContain("All Rights Reserved");
    });

    it("links visitors to the license deed when one exists", () => {
      const { wrapper } = mountPhotoInfo({
        canEdit: false,
        photo: { ...basePhoto, license: "CC BY 4.0" },
      });
      const link = wrapper
        .findAll("a")
        .find((a) => a.text() === "CC BY 4.0");
      expect(link.attributes("href")).toBe(
        "https://creativecommons.org/licenses/by/4.0/",
      );
    });

    it("renders a legacy license with no deed as plain text", () => {
      const { wrapper } = mountPhotoInfo({
        canEdit: false,
        photo: { ...basePhoto, license: "Some old Flickr license" },
      });
      expect(wrapper.text()).toContain("Some old Flickr license");
      expect(
        wrapper.findAll("a").some((a) => a.text() === "Some old Flickr license"),
      ).toBe(false);
    });

    it("renders the license trigger as a native button when canEdit is true", () => {
      const { wrapper } = mountPhotoInfo({ canEdit: true });
      expect(wrapper.find(".license-trigger").element.tagName).toBe("BUTTON");
    });
  });

  describe("License modal", () => {
    it("opens when the license trigger is clicked", async () => {
      const { wrapper } = mountPhotoInfo({
        photo: { ...basePhoto, license: "CC BY 4.0" },
      });
      await wrapper.find(".license-trigger").trigger("click");

      expect(licenseModal().classes()).toContain("is-active");
    });

    it("checks the photo's current license", async () => {
      const { wrapper } = mountPhotoInfo({
        photo: { ...basePhoto, license: "CC BY-SA 4.0" },
      });
      await wrapper.find(".license-trigger").trigger("click");

      const checked = licenseModal().find(
        'input[type="radio"][value="CC BY-SA 4.0"]',
      );
      expect(checked.element.checked).toBe(true);
    });

    it("emits updateLicense with the new value when confirmed", async () => {
      const { wrapper } = mountPhotoInfo({
        photo: { ...basePhoto, license: "CC BY 4.0" },
      });
      await wrapper.find(".license-trigger").trigger("click");

      const cc0Radio = licenseModal().find(
        'input[type="radio"][value="CC0 1.0"]',
      );
      await cc0Radio.setValue(true);
      await licenseModal().find(".button.is-primary").trigger("click");

      expect(wrapper.emitted("updateLicense")).toEqual([
        [{ id: "some-slug", license: "CC0 1.0" }],
      ]);
      expect(licenseModal().classes()).not.toContain("is-active");
    });

    it("does not emit updateLicense when the selection is unchanged", async () => {
      const { wrapper } = mountPhotoInfo({
        photo: { ...basePhoto, license: "CC BY 4.0" },
      });
      await wrapper.find(".license-trigger").trigger("click");

      await licenseModal().find(".button.is-primary").trigger("click");

      expect(wrapper.emitted("updateLicense")).toBeFalsy();
    });

    it("returns focus to the trigger on cancel", async () => {
      const { wrapper } = mountPhotoInfo({
        photo: { ...basePhoto, license: "CC BY 4.0" },
      });
      const trigger = wrapper.find(".license-trigger");
      await trigger.trigger("click");

      await licenseModal().find(".button.is-info").trigger("click");

      expect(document.activeElement).toBe(trigger.element);
    });

    it("closes on Escape and restores navigation shortcuts", async () => {
      const { wrapper, applicationStore } = mountPhotoInfo({
        photo: { ...basePhoto, license: "CC BY 4.0" },
      });
      await wrapper.find(".license-trigger").trigger("click");

      document.dispatchEvent(new KeyboardEvent("keydown", { key: "Escape" }));
      await wrapper.vm.$nextTick();

      expect(licenseModal().classes()).not.toContain("is-active");
      expect(applicationStore.navigationShortcutsEnabled).toBe(true);
    });
  });
});
