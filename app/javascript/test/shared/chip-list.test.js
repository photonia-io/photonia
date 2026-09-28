import { mount } from "@vue/test-utils";

import ChipList from "@/shared/chip-list.vue";

describe("shared/chip-list.vue", () => {
  it("renders one chip per item", () => {
    const wrapper = mount(ChipList, { props: { items: ["sunset", "lake"] } });

    const tags = wrapper.findAll(".tag:not(.is-delete)");
    expect(tags.map((tag) => tag.text())).toEqual(["sunset", "lake"]);
  });

  it("emits remove with the clicked item", async () => {
    const wrapper = mount(ChipList, { props: { items: ["sunset", "lake"] } });

    await wrapper.findAll(".is-delete")[0].trigger("click");

    expect(wrapper.emitted("remove")).toEqual([["sunset"]]);
  });

  it("renders nothing for an empty list", () => {
    const wrapper = mount(ChipList, { props: { items: [] } });

    expect(wrapper.findAll(".tag").length).toBe(0);
  });
});
