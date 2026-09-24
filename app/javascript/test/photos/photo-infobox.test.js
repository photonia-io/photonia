import { describe, it, expect, afterEach } from "vitest";
import { mount } from "@vue/test-utils";

import PhotoInfobox from "../../photos/photo-infobox.vue";

let mountedWrapper;

function mountInfobox(props = {}) {
  const wrapper = mount(PhotoInfobox, {
    // isVisible() (used below to check v-show) needs computed styles, which
    // happy-dom only resolves reliably for elements attached to the document.
    attachTo: document.body,
    props,
    slots: {
      header: "<span>Title</span>",
      default: "<p>Body content</p>",
    },
  });
  mountedWrapper = wrapper;
  return wrapper;
}

afterEach(() => {
  mountedWrapper?.unmount();
  mountedWrapper = undefined;
});

describe("PhotoInfobox", () => {
  it("renders the header and body slots", () => {
    const wrapper = mountInfobox();
    expect(wrapper.find(".message-header").text()).toBe("Title");
    expect(wrapper.find(".message-body").text()).toBe("Body content");
  });

  describe("when not collapsible (the default)", () => {
    it("always shows the body, with no toggle affordance", () => {
      const wrapper = mountInfobox();
      expect(wrapper.find(".message-body").isVisible()).toBe(true);
      expect(wrapper.find(".infobox-toggle").exists()).toBe(false);
      expect(wrapper.find(".message-header").attributes("role")).toBeUndefined();
    });
  });

  describe("when collapsible", () => {
    it("starts expanded by default", () => {
      const wrapper = mountInfobox({ collapsible: true });
      expect(wrapper.find(".message-body").isVisible()).toBe(true);
      expect(wrapper.find(".message-header").attributes("aria-expanded")).toBe(
        "true",
      );
      expect(wrapper.find(".infobox-toggle").classes()).not.toContain(
        "is-collapsed",
      );
    });

    it("starts collapsed when defaultOpen is false", () => {
      const wrapper = mountInfobox({ collapsible: true, defaultOpen: false });
      expect(wrapper.find(".message-body").isVisible()).toBe(false);
      expect(wrapper.find(".message-header").attributes("aria-expanded")).toBe(
        "false",
      );
      expect(wrapper.find(".message-header").classes()).toContain(
        "is-collapsed",
      );
      expect(wrapper.find(".infobox-toggle").classes()).toContain(
        "is-collapsed",
      );
    });

    it("toggles on click", async () => {
      const wrapper = mountInfobox({ collapsible: true, defaultOpen: false });

      await wrapper.find(".message-header").trigger("click");
      expect(wrapper.find(".message-body").isVisible()).toBe(true);
      expect(wrapper.find(".message-header").attributes("aria-expanded")).toBe(
        "true",
      );

      await wrapper.find(".message-header").trigger("click");
      expect(wrapper.find(".message-body").isVisible()).toBe(false);
    });

    it("toggles on Enter and Space", async () => {
      const wrapper = mountInfobox({ collapsible: true });

      await wrapper.find(".message-header").trigger("keydown.enter");
      expect(wrapper.find(".message-body").isVisible()).toBe(false);

      await wrapper.find(".message-header").trigger("keydown.space");
      expect(wrapper.find(".message-body").isVisible()).toBe(true);
    });
  });
});
