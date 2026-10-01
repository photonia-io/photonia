import { describe, it, expect } from "vitest";
import { mount, RouterLinkStub } from "@vue/test-utils";

import SectionRow from "../../homepage/section-row.vue";

const mountRow = (props = {}) =>
  mount(SectionRow, {
    props: { title: "Latest albums", ...props },
    slots: { default: '<div class="real-tile">tile</div>' },
    global: { stubs: { RouterLink: RouterLinkStub } },
  });

describe("SectionRow", () => {
  it("renders its slot when not loading", () => {
    const wrapper = mountRow();

    expect(wrapper.find(".real-tile").exists()).toBe(true);
    expect(wrapper.findAll(".home-skeleton")).toHaveLength(0);
  });

  it("renders five grey skeleton tiles instead of the slot while loading", () => {
    const wrapper = mountRow({ loading: true });

    expect(wrapper.findAll(".home-skeleton")).toHaveLength(5);
    expect(wrapper.find(".real-tile").exists()).toBe(false);
  });

  it("shows the header link only when given a route", () => {
    expect(mountRow().find("a").exists()).toBe(false);

    const wrapper = mountRow({
      to: { name: "albums-index" },
      linkLabel: "See all albums...",
    });

    expect(wrapper.find("a").text()).toBe("See all albums...");
  });
});
