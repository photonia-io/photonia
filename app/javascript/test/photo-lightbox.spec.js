import { describe, it, expect, beforeEach, afterEach, vi } from "vitest";
import { mount } from "@vue/test-utils";
import { nextTick } from "vue";
import PhotoLightbox from "../photos/photo-lightbox.vue";

const mockPhoto = {
  title: "Test Photo",
  extralargeImageUrl: "https://example.com/photo.jpg",
};

describe("PhotoLightbox", () => {
  let wrapper;
  const closeHandler = vi.fn();

  beforeEach(() => {
    wrapper = mount(PhotoLightbox, {
      props: {
        photo: mockPhoto,
        isOpen: true,
      },
      attrs: {
        onClose: closeHandler,
      },
    });
    closeHandler.mockClear();
  });

  it("renders when open", () => {
    expect(wrapper.find(".lightbox-overlay").exists()).toBe(true);
    expect(wrapper.text()).toContain("Test Photo");
  });

  it("does not render when closed", async () => {
    await wrapper.setProps({ isOpen: false });
    expect(wrapper.find(".lightbox-overlay").exists()).toBe(false);
  });

  it("emits close when close button is clicked", async () => {
    const closeBtn = wrapper.find('[data-testid="close-button"]');
    await closeBtn.trigger("click");
    expect(wrapper.emitted().close).toBeTruthy();
  });

  it("zooms in and out with buttons", async () => {
    const zoomInBtn = wrapper.find('[data-testid="zoom-in-button"]');
    const zoomOutBtn = wrapper.find('[data-testid="zoom-out-button"]');
    const img = wrapper.find("img");

    // Initial scale
    expect(img.element.style.transform).toContain("scale(1)");

    await zoomInBtn.trigger("click");
    // After zoom in, transform should include scale > 1
    const scaleMatch = img.element.style.transform.match(/scale\(([\d.]+)\)/);
    expect(scaleMatch).toBeTruthy();
    expect(parseFloat(scaleMatch[1])).toBeGreaterThan(1);

    await zoomOutBtn.trigger("click");
    // After zoom out, should be back to scale(1)
    const newScaleMatch =
      img.element.style.transform.match(/scale\(([\d.]+)\)/);
    expect(newScaleMatch).toBeTruthy();
    expect(parseFloat(newScaleMatch[1])).toBe(1);
  });

  it("shows the photo image", () => {
    const img = wrapper.find("img");
    expect(img.exists()).toBe(true);
    expect(img.attributes("src")).toBe(mockPhoto.extralargeImageUrl);
    expect(img.attributes("alt")).toBe(mockPhoto.title);
  });
});

// 3:2, like most photos: in happy-dom's 1024x768 viewport the frame is
// 1024px wide, exactly the large derivative's width.
const photoWithVariants = (slug) => ({
  id: slug,
  title: `Photo ${slug}`,
  largeImageUrl: `https://example.com/${slug}-large.jpg`,
  largeDimensions: { width: 1024, height: 683 },
  extralargeImageUrl: `https://example.com/${slug}-extralarge.jpg`,
  extralargeDimensions: { width: 2048, height: 1365 },
});

const nextFrame = () =>
  new Promise((resolve) => requestAnimationFrame(resolve));

describe("PhotoLightbox variants and animation", () => {
  let wrapper;
  const originalDevicePixelRatio = window.devicePixelRatio;

  const setDevicePixelRatio = (value) => {
    Object.defineProperty(window, "devicePixelRatio", {
      value,
      configurable: true,
    });
  };

  // Mounted closed, then opened - the same sequence as the hero click, since
  // the open-time setup lives in the isOpen watcher.
  const openLightbox = async (props = {}) => {
    wrapper = mount(PhotoLightbox, {
      props: { photo: photoWithVariants("a"), isOpen: false, ...props },
    });
    await wrapper.setProps({ isOpen: true });
    await nextTick();
    return wrapper;
  };

  const mainImage = () => wrapper.find("img:not(.hires-preload)");
  const badge = () => wrapper.find(".hires-badge");
  const preload = () => wrapper.find(".hires-preload");

  beforeEach(() => setDevicePixelRatio(1));

  afterEach(() => {
    wrapper?.unmount();
    wrapper = undefined;
    setDevicePixelRatio(originalDevicePixelRatio);
    vi.restoreAllMocks();
  });

  describe("displayed source", () => {
    it("starts from the image the hero was showing, visible straight away", async () => {
      await openLightbox({ initialSrc: "https://example.com/a-large.jpg" });

      expect(mainImage().attributes("src")).toBe(
        "https://example.com/a-large.jpg",
      );
      expect(mainImage().element.style.opacity).toBe("1");
    });

    it("falls back to the large derivative, hidden until it loads", async () => {
      await openLightbox();

      expect(mainImage().attributes("src")).toBe(
        "https://example.com/a-large.jpg",
      );
      expect(mainImage().element.style.opacity).toBe("0");
    });
  });

  describe("upgrade to extralarge", () => {
    it("keeps large and shows no badge when large already covers the frame", async () => {
      await openLightbox({ initialSrc: "https://example.com/a-large.jpg" });

      expect(badge().exists()).toBe(false);
      expect(preload().exists()).toBe(false);
    });

    it("keeps large on screen with a badge while extralarge loads, then swaps", async () => {
      setDevicePixelRatio(2);
      await openLightbox({ initialSrc: "https://example.com/a-large.jpg" });

      expect(badge().text()).toBe("Loading higher resolution image...");
      expect(preload().attributes("src")).toBe(
        "https://example.com/a-extralarge.jpg",
      );
      expect(mainImage().attributes("src")).toBe(
        "https://example.com/a-large.jpg",
      );

      await preload().trigger("load");

      expect(mainImage().attributes("src")).toBe(
        "https://example.com/a-extralarge.jpg",
      );
      expect(badge().exists()).toBe(false);
    });

    it("keeps large and drops the badge if extralarge fails to load", async () => {
      setDevicePixelRatio(2);
      await openLightbox({ initialSrc: "https://example.com/a-large.jpg" });

      await preload().trigger("error");

      expect(badge().exists()).toBe(false);
      expect(mainImage().attributes("src")).toBe(
        "https://example.com/a-large.jpg",
      );
    });

    it("starts the upgrade when zooming in past what large covers", async () => {
      await openLightbox({ initialSrc: "https://example.com/a-large.jpg" });
      expect(badge().exists()).toBe(false);

      await wrapper.find('[data-testid="zoom-in-button"]').trigger("click");
      await nextTick();

      expect(badge().exists()).toBe(true);
    });

    it("ignores a late load from the previous photo's extralarge", async () => {
      setDevicePixelRatio(2);
      await openLightbox({ initialSrc: "https://example.com/a-large.jpg" });
      const stalePreload = preload().element;

      await wrapper.setProps({ photo: photoWithVariants("b") });
      await nextTick();
      stalePreload.dispatchEvent(new Event("load"));
      await nextTick();

      expect(mainImage().attributes("src")).toBe(
        "https://example.com/b-large.jpg",
      );
    });

    it("upgrades again when reopened after a close", async () => {
      setDevicePixelRatio(2);
      await openLightbox({ initialSrc: "https://example.com/a-large.jpg" });

      await wrapper.setProps({ isOpen: false });
      await wrapper.setProps({ isOpen: true });
      await nextTick();

      expect(badge().exists()).toBe(true);
    });
  });

  describe("open and close animation", () => {
    // Half the frame's 1024px width.
    const originRect = { left: 100, top: 50, width: 512, height: 341 };
    const frameStyle = () => wrapper.find(".image-frame").element.style;

    it("mounts the frame already shrunk onto the hero's rect, then grows it", async () => {
      await openLightbox({ originRect });

      expect(frameStyle().transform).toContain("scale(0.5)");
      expect(frameStyle().transition).toBe("none");

      await nextFrame();
      await nextFrame();
      await nextTick();

      expect(frameStyle().transform).toBe("none");
      expect(frameStyle().transition).toBe("transform 350ms ease");
    });

    it("opens without animating when reduced motion is preferred", async () => {
      vi.spyOn(window, "matchMedia").mockReturnValue({ matches: true });
      await openLightbox({ originRect });

      expect(frameStyle().transform).toBe("");
    });

    it("shrinks back onto the hero's rect before emitting close", async () => {
      await openLightbox({ originRect });
      await nextFrame();
      await nextFrame();
      // happy-dom has no layout; close measures the frame's live rect.
      vi.spyOn(
        wrapper.find(".image-frame").element,
        "getBoundingClientRect",
      ).mockReturnValue({ left: 0, top: 43, width: 1024, height: 683 });

      await wrapper.find('[data-testid="close-button"]').trigger("click");

      expect(frameStyle().transform).toContain("scale(0.5)");
      expect(wrapper.emitted().close).toBeFalsy();

      wrapper.find(".image-frame").element.dispatchEvent(new Event("transitionend"));
      await nextTick();

      expect(wrapper.emitted().close).toBeTruthy();
    });
  });
});
