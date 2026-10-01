import { describe, it, expect, beforeEach, vi } from "vitest";
import { mount, RouterLinkStub } from "@vue/test-utils";
import { ref } from "vue";

const useTitle = vi.fn();
vi.mock("vue-page-title", () => ({ useTitle: (...args) => useTitle(...args) }));

const useQuery = vi.fn();
vi.mock("@vue/apollo-composable", () => ({ useQuery: (...args) => useQuery(...args) }));

import TagsIndex from "../../tags/index.vue";
import SectionRow from "../../homepage/section-row.vue";

const tag = (name, taggingsCount) => ({ id: name, name, taggingsCount });

const mountIndex = (result) => {
  useQuery.mockReturnValue({ result: ref(result) });
  return mount(TagsIndex, { global: { stubs: { RouterLink: RouterLinkStub } } });
};

beforeEach(() => {
  useQuery.mockReset();
  useTitle.mockReset();
  globalThis.gql_queries = { tags_index: "query { __typename }" };
});

describe("Tags index", () => {
  it("sets the page title", () => {
    mountIndex({});

    expect(useTitle).toHaveBeenCalledWith("Tags");
  });

  it("renders the four sections with the smaller subheaders", () => {
    const wrapper = mountIndex({});
    const rows = wrapper.findAllComponents(SectionRow);

    expect(rows.map((row) => row.props("title"))).toEqual([
      "Most used",
      "Least used",
      "Most used AI tags",
      "Least used AI tags",
    ]);
    expect(rows.every((row) => row.find("h2").classes("is-5"))).toBe(true);
  });

  it("renders without data while the query is loading", () => {
    const wrapper = mountIndex(undefined);

    expect(wrapper.findAllComponents(SectionRow)).toHaveLength(4);
    expect(wrapper.text()).not.toContain("undefined");
  });

  it("puts each tag, linked to its page, in its own section", () => {
    const wrapper = mountIndex({
      mostUsedUserTags: [tag("cat", 47)],
      leastUsedUserTags: [tag("tree", 1)],
      mostUsedMachineTags: [tag("plant", 90)],
      leastUsedMachineTags: [tag("fog", 2)],
    });
    const [most, least, mostAi, leastAi] = wrapper.findAllComponents(SectionRow);

    expect(most.text()).toContain("cat");
    expect(most.text()).toContain("47");
    expect(least.text()).toContain("tree");
    expect(mostAi.text()).toContain("plant");
    expect(leastAi.text()).toContain("fog");
    expect(most.text()).not.toContain("tree");
    expect(most.findComponent(RouterLinkStub).props("to")).toEqual({
      name: "tags-show",
      params: { id: "cat" },
    });
  });
});
