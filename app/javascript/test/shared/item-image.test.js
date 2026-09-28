import { describe, it, expect } from "vitest";
import { mount } from "@vue/test-utils";

import ItemImage from "../../shared/item-image.vue";

describe("ItemImage", () => {
  it("renders the image with the photo's title as alt text", () => {
    const wrapper = mount(ItemImage, {
      props: {
        photo: {
          title: "A mountain lake",
          intelligentOrSquareMediumImageUrl: "https://example.com/photo.jpg",
        },
      },
    });

    expect(wrapper.find("img").attributes("alt")).toBe("A mountain lake");
  });

  it("renders a placeholder, not an img, when there is no image URL", () => {
    const wrapper = mount(ItemImage, {
      props: { photo: { title: "A mountain lake" } },
    });

    expect(wrapper.find("img").exists()).toBe(false);
  });
});
