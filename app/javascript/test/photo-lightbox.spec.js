import { describe, it, expect, beforeEach, vi } from "vitest";
import { mount } from "@vue/test-utils";
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
