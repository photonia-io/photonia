import { describe, it, expect } from "vitest";
import { mount, RouterLinkStub } from "@vue/test-utils";

import MostUsedTags from "../../homepage/most-used-tags.vue";

describe("MostUsedTags", () => {
  const tags = [
    { id: "tree", name: "tree", taggingsCount: 27 },
    { id: "cat", name: "cat", taggingsCount: 47 },
  ];

  it("shows each tag with its count, linked to the tag page", () => {
    const wrapper = mount(MostUsedTags, {
      props: { tags },
      global: { stubs: { RouterLink: RouterLinkStub } },
    });

    expect(wrapper.text()).toContain("tree");
    expect(wrapper.text()).toContain("47");
    expect(wrapper.findAllComponents(RouterLinkStub).map((link) => link.props("to"))).toContainEqual({
      name: "tags-show",
      params: { id: "cat" },
    });
  });

  it("links to the tags page from the header", () => {
    const wrapper = mount(MostUsedTags, {
      props: { tags },
      global: { stubs: { RouterLink: RouterLinkStub } },
    });

    expect(wrapper.text()).toContain("See tags page...");
    expect(wrapper.findAllComponents(RouterLinkStub)[0].props("to")).toEqual({ name: "tags-index" });
  });
});
