import { ref } from "vue";

const testTagName = "Test Tag";

vi.mock("@vue/apollo-composable", () => {
  return {
    useQuery: () => {
      return {
        result: ref({
          tag: {
            id: 1,
            name: testTagName,
            photos: {
              collection: [],
            },
            relatedTags: [],
          },
        }),
        loading: ref(false),
      };
    },
  };
});

vi.mock("vue-router", () => ({
  useRoute: () => ({
    params: {
      id: 1,
    },
    query: {
      page: 1,
    },
  }),
}));

vi.mock("@/shared/gql_queries", () => ({
  default: {
    tags_show:
      "query TagsShowQuery($id: ID!, $page: Int) { tag(id: $id) { id name } }",
  },
}));

vi.mock("vue-page-title", () => ({
  useTitle: vi.fn((title) => title.value),
}));

import TagsShow from "@/tags/show.vue";
import { shallowMount } from "@vue/test-utils";
import { useTitle } from "vue-page-title";

test("it sets the correct page title", () => {
  shallowMount(TagsShow, { global: { stubs: { "router-link": true } } });
  expect(useTitle).toHaveBeenCalled();
  expect(useTitle).toHaveReturnedWith("Tag: " + testTagName);
});
