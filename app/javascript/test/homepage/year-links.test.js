import { describe, it, expect } from "vitest";
import { mount, RouterLinkStub } from "@vue/test-utils";

import YearLinks from "../../homepage/year-links.vue";

describe("YearLinks", () => {
  it("links each year to the advanced search for that calendar year", () => {
    const wrapper = mount(YearLinks, {
      props: {
        years: [
          { year: 2015, count: 4 },
          { year: 2009, count: 120 },
        ],
      },
      global: { stubs: { RouterLink: RouterLinkStub } },
    });

    const links = wrapper.findAllComponents(RouterLinkStub);

    expect(links).toHaveLength(2);
    expect(links[1].props("to")).toEqual({
      name: "photos-search",
      query: { takenFrom: "2009-01-01", takenTo: "2009-12-31" },
    });
    expect(wrapper.text()).toContain("120");
  });
});
