import { describe, it, expect, beforeEach, afterEach } from "vitest";
import { mount, DOMWrapper } from "@vue/test-utils";
import { createPinia, setActivePinia } from "pinia";

import TakenAtModal from "../../photos/taken-at-modal.vue";

// The modal is teleported to #modal-root, outside the component's own DOM
// tree, so it must be queried through the document body.
const body = () => new DOMWrapper(document.body);

const baseTakenAtInfo = {
  year: 1985,
  month: 8,
  day: 31,
  hour: 17,
  minute: 25,
  precision: "minute",
  source: "user",
  approximate: false,
  exifAvailable: true,
};

let mountedWrapper;

function mountModal(props = {}) {
  const pinia = createPinia();
  setActivePinia(pinia);

  const wrapper = mount(TakenAtModal, {
    attachTo: document.body,
    global: { plugins: [pinia] },
    props: {
      active: true,
      takenAtInfo: baseTakenAtInfo,
      scanned: false,
      ...props,
    },
  });
  mountedWrapper = wrapper;
  return wrapper;
}

function yearInput() {
  return body().find("#taken-at-year");
}

function monthSelect() {
  return body().find("#taken-at-month");
}

function daySelect() {
  return body().find("#taken-at-day");
}

function timeCheckbox() {
  return body().find('input[type="checkbox"]');
}

describe("TakenAtModal", () => {
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

  describe("day options", () => {
    it("offers 31 days for August", async () => {
      mountModal({ takenAtInfo: { ...baseTakenAtInfo, month: 8, day: null } });
      await monthSelect().setValue("8");

      expect(daySelect().findAll("option").length).toBe(32); // 31 days + "Unknown"
    });

    it("offers 29 days for February in a leap year", async () => {
      mountModal({
        takenAtInfo: { ...baseTakenAtInfo, year: 2024, month: 2, day: null },
      });
      await monthSelect().setValue("2");

      expect(daySelect().findAll("option").length).toBe(30); // 29 days + "Unknown"
    });

    it("offers 28 days for February in a non-leap year", async () => {
      mountModal({
        takenAtInfo: { ...baseTakenAtInfo, year: 2023, month: 2, day: null },
      });
      await monthSelect().setValue("2");

      expect(daySelect().findAll("option").length).toBe(29); // 28 days + "Unknown"
    });
  });

  describe("unknown month/day", () => {
    it("disables and clears day when month is set to unknown", async () => {
      mountModal();
      await monthSelect().setValue("");

      expect(daySelect().attributes("disabled")).toBeDefined();
    });

    it("disables the time checkbox when day is unknown", async () => {
      mountModal({ takenAtInfo: { ...baseTakenAtInfo, day: null } });

      expect(timeCheckbox().attributes("disabled")).toBeDefined();
    });
  });

  describe("saving", () => {
    it("emits save with the full payload for a minute-precision date", async () => {
      const wrapper = mountModal();

      await body().find(".modal-card-foot .button.is-primary").trigger("click");

      expect(wrapper.emitted("save")).toEqual([
        [
          {
            year: 1985,
            month: 8,
            day: 31,
            hour: 17,
            minute: 25,
            approximate: false,
            scanned: false,
          },
        ],
      ]);
    });

    it("emits null month/day/hour/minute for a year-only date", async () => {
      const wrapper = mountModal({
        takenAtInfo: {
          year: 1985,
          month: null,
          day: null,
          hour: null,
          minute: null,
          precision: "year",
          source: "user",
          approximate: false,
          exifAvailable: false,
        },
      });

      await body().find(".modal-card-foot .button.is-primary").trigger("click");

      expect(wrapper.emitted("save")[0][0]).toMatchObject({
        year: 1985,
        month: null,
        day: null,
        hour: null,
        minute: null,
      });
    });

    it("omits hour/minute when the time checkbox is unchecked", async () => {
      const wrapper = mountModal();
      await timeCheckbox().setValue(false);

      await body().find(".modal-card-foot .button.is-primary").trigger("click");

      expect(wrapper.emitted("save")[0][0]).toMatchObject({
        hour: null,
        minute: null,
      });
    });

    it("includes the approximate and scanned flags", async () => {
      const wrapper = mountModal({ scanned: true });
      const checkboxes = body().findAll('input[type="checkbox"]');
      const approximateCheckbox = checkboxes[1];
      await approximateCheckbox.setValue(true);

      await body().find(".modal-card-foot .button.is-primary").trigger("click");

      expect(wrapper.emitted("save")[0][0]).toMatchObject({
        approximate: true,
        scanned: true,
      });
    });
  });

  describe("reset button", () => {
    it("is hidden when the source is not user", () => {
      mountModal({ takenAtInfo: { ...baseTakenAtInfo, source: "exif" } });
      expect(body().find(".button.is-light").exists()).toBe(false);
    });

    it('reads "Reset to EXIF date" when EXIF is available', () => {
      mountModal({
        takenAtInfo: { ...baseTakenAtInfo, source: "user", exifAvailable: true },
      });
      expect(body().find(".button.is-light").text()).toBe("Reset to EXIF date");
    });

    it('reads "Reset to upload date" when EXIF is not available', () => {
      mountModal({
        takenAtInfo: { ...baseTakenAtInfo, source: "user", exifAvailable: false },
      });
      expect(body().find(".button.is-light").text()).toBe(
        "Reset to upload date",
      );
    });

    it("emits reset when clicked", async () => {
      const wrapper = mountModal({
        takenAtInfo: { ...baseTakenAtInfo, source: "user" },
      });

      await body().find(".button.is-light").trigger("click");

      expect(wrapper.emitted("reset")).toBeTruthy();
    });
  });

  describe("cancel", () => {
    it("emits close and no save/reset", async () => {
      const wrapper = mountModal();

      await body().find(".button.is-info").trigger("click");

      expect(wrapper.emitted("close")).toBeTruthy();
      expect(wrapper.emitted("save")).toBeFalsy();
      expect(wrapper.emitted("reset")).toBeFalsy();
    });
  });
});
