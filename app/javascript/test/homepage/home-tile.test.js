import { describe, it, expect } from "vitest";
import { mount, RouterLinkStub } from "@vue/test-utils";

import HomeTile from "../../homepage/home-tile.vue";

const mountTile = (props) =>
  mount(HomeTile, {
    props: { to: { name: "photos-show", params: { id: "a" } }, ...props },
    global: { stubs: { RouterLink: RouterLinkStub } },
  });

describe("HomeTile", () => {
  it("renders the image and title", () => {
    const wrapper = mountTile({
      title: "A lake",
      imageUrl: "https://example.com/lake.jpg",
    });

    expect(wrapper.find("img").attributes("alt")).toBe("A lake");
    expect(wrapper.text()).toContain("A lake");
  });

  it("falls back to a placeholder without an image URL", () => {
    const wrapper = mountTile({ title: "A lake" });

    expect(wrapper.find("img").exists()).toBe(false);
  });

  it("shows the count badge only when a count is given", () => {
    expect(mountTile({ title: "x", count: 12 }).text()).toContain("12");
    expect(mountTile({ title: "x" }).find(".tag").exists()).toBe(false);
  });
});
