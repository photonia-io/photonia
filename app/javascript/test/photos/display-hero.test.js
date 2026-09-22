import { describe, it, expect, beforeEach, afterEach, vi } from "vitest";
import { mount, RouterLinkStub } from "@vue/test-utils";
import { createPinia, setActivePinia } from "pinia";
import { nextTick } from "vue";

import DisplayHero from "../../photos/display-hero.vue";

const nextFrame = () =>
  new Promise((resolve) => requestAnimationFrame(resolve));

const ratioOf = (wrapper) =>
  wrapper.find("#image-wrapper").element.style.getPropertyValue(
    "--photo-ratio",
  );

const portraitPhoto = {
  id: "portrait-slug",
  title: "Portrait",
  extralargeImageUrl: "https://example.com/portrait.jpg",
  extralargeDimensions: { width: 1000, height: 2000 },
};

const landscapePhoto = {
  id: "landscape-slug",
  title: "Landscape",
  extralargeImageUrl: "https://example.com/landscape.jpg",
  extralargeDimensions: { width: 2000, height: 1000 },
};

let mountedWrapper;

function mountDisplayHero(props = {}) {
  const pinia = createPinia();
  setActivePinia(pinia);

  const wrapper = mount(DisplayHero, {
    global: {
      plugins: [pinia],
      stubs: { RouterLink: RouterLinkStub },
    },
    props,
  });
  mountedWrapper = wrapper;

  return wrapper;
}

describe("DisplayHero", () => {
  afterEach(() => {
    mountedWrapper?.unmount();
    mountedWrapper = undefined;
  });

  describe("box sizing", () => {
    it("reserves a plausible landscape box before any dimensions are known", () => {
      const wrapper = mountDisplayHero({ photo: {}, loading: true });
      expect(ratioOf(wrapper)).toBe("1.5");
    });

    it("sizes the box from the displayed derivative's own dimensions", async () => {
      const wrapper = mountDisplayHero({ photo: portraitPhoto });
      await nextTick();
      expect(ratioOf(wrapper)).toBe("0.5");
    });

    it("holds the previous shape rather than reverting to the fallback while new dimensions are unknown", async () => {
      const wrapper = mountDisplayHero({ photo: portraitPhoto });
      await nextTick();
      expect(ratioOf(wrapper)).toBe("0.5");

      // Simulates a navigation with keepPreviousResult: the incoming photo
      // hasn't reported dimensions yet.
      await wrapper.setProps({ photo: { id: "next-slug" } });
      expect(ratioOf(wrapper)).toBe("0.5");
    });

    it("does not transition the very first ratio it applies", () => {
      const wrapper = mountDisplayHero({ photo: portraitPhoto });
      expect(wrapper.find("#image-wrapper").classes()).not.toContain(
        "is-animated",
      );
    });

    it("enables the transition once the first real ratio has settled in", async () => {
      const wrapper = mountDisplayHero({ photo: portraitPhoto });
      await nextTick();
      await nextFrame();
      expect(wrapper.find("#image-wrapper").classes()).toContain(
        "is-animated",
      );
    });
  });

  describe("image rendering", () => {
    it("renders no img element until an image URL is available", () => {
      const wrapper = mountDisplayHero({ photo: {} });
      expect(wrapper.find("img").exists()).toBe(false);
    });

    it("renders the image once a URL is available", () => {
      const wrapper = mountDisplayHero({ photo: portraitPhoto });
      expect(wrapper.find("img").attributes("src")).toBe(
        portraitPhoto.extralargeImageUrl,
      );
    });

    it("wraps the image in a router-link on the homepage", () => {
      const wrapper = mountDisplayHero({
        photo: portraitPhoto,
        isHomepage: true,
      });
      expect(
        wrapper.findComponent(RouterLinkStub).find("img").exists(),
      ).toBe(true);
    });
  });

  describe("opacity states", () => {
    it("hides the image while it is still downloading", () => {
      const wrapper = mountDisplayHero({ photo: portraitPhoto });
      expect(wrapper.find("img").element.style.opacity).toBe("0");
    });

    it("shows the image at full opacity once it has loaded", async () => {
      const wrapper = mountDisplayHero({ photo: portraitPhoto });
      await wrapper.find("img").trigger("load");
      expect(wrapper.find("img").element.style.opacity).toBe("1");
    });

    it("dims the previous photo rather than hiding it while the next one is loading", async () => {
      const wrapper = mountDisplayHero({ photo: portraitPhoto });
      await wrapper.find("img").trigger("load");

      // A navigation has started, but keepPreviousResult means the photo
      // prop itself hasn't changed yet.
      await wrapper.setProps({ loading: true });
      expect(wrapper.find("img").element.style.opacity).toBe("0.6");
    });

    it("hides the outgoing image once the incoming photo's data has arrived", async () => {
      const wrapper = mountDisplayHero({ photo: portraitPhoto });
      await wrapper.find("img").trigger("load");

      await wrapper.setProps({ photo: landscapePhoto, loading: false });
      expect(wrapper.find("img").element.style.opacity).toBe("0");
    });
  });

  describe("loading spinner", () => {
    it("is shown as soon as a navigation starts, even though the old photo is still on screen", async () => {
      const wrapper = mountDisplayHero({ photo: portraitPhoto });
      await wrapper.find("img").trigger("load");
      expect(wrapper.find(".loading-spinner").exists()).toBe(false);

      await wrapper.setProps({ loading: true });
      expect(wrapper.find(".loading-spinner").exists()).toBe(true);
    });

    it("stays visible until the incoming image finishes decoding", async () => {
      const wrapper = mountDisplayHero({ photo: portraitPhoto });
      await wrapper.find("img").trigger("load");

      await wrapper.setProps({ photo: landscapePhoto, loading: false });
      expect(wrapper.find(".loading-spinner").exists()).toBe(true);

      await wrapper.find("img").trigger("load");
      expect(wrapper.find(".loading-spinner").exists()).toBe(false);
    });
  });
});
