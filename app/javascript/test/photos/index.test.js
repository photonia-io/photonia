import { ref } from "vue";
import { mount } from "@vue/test-utils";
import { createPinia, setActivePinia } from "pinia";
import { useQuery } from "@vue/apollo-composable";
import { useRoute } from "vue-router";

vi.mock("@vue/apollo-composable", () => ({
  useQuery: vi.fn(),
}));

vi.mock("vue-router", () => ({
  useRoute: vi.fn(),
  useRouter: vi.fn(() => ({ push: vi.fn() })),
}));

vi.mock("vue-page-title", () => ({
  useTitle: vi.fn(),
}));

import PhotosIndex from "@/photos/index.vue";
import { useTitle } from "vue-page-title";

function mountIndex(query = {}) {
  useRoute.mockReturnValue({ query });

  const pinia = createPinia();
  setActivePinia(pinia);

  return mount(PhotosIndex, {
    global: {
      plugins: [pinia],
      stubs: { "router-link": { template: "<a><slot /></a>" } },
    },
  });
}

beforeEach(() => {
  globalThis.settings = {};
  globalThis.gql_queries = { photos_index: "query PhotosIndexQuery { photos { collection { id } } }" };
});

describe("photos/index.vue", () => {
  it("titles the page 'Photos' and shows no refine link when there is no query", () => {
    useQuery.mockReturnValue({ result: ref({ photos: { collection: [], metadata: {} } }) });

    const wrapper = mountIndex({});

    expect(useTitle).toHaveBeenCalled();
    expect(useTitle.mock.calls[0][0].value).toBe("Photos");
    expect(wrapper.text()).not.toContain("Refine this search");
  });

  it("titles the page 'Search: <q>' and shows a refine link when a query is set", () => {
    useQuery.mockReturnValue({
      result: ref({ photos: { collection: [{ id: "1" }], metadata: {} } }),
    });

    const wrapper = mountIndex({ q: "lake" });

    expect(useTitle.mock.calls[0][0].value).toBe("Search: lake");
    expect(wrapper.text()).toContain("Refine this search");
  });

  it("renders matching albums and tags above the grid (#710)", () => {
    useQuery.mockReturnValue({
      result: ref({
        photos: { collection: [{ id: "1" }], metadata: {} },
        matchingAlbums: { collection: [{ id: "a1", title: "Lake trip", photosCount: 3 }] },
        matchingTags: [{ id: "lake", name: "lake" }],
      }),
    });

    const wrapper = mountIndex({ q: "lake" });

    expect(wrapper.text()).toContain("Albums matching");
    expect(wrapper.text()).toContain("Lake trip");
    expect(wrapper.text()).toContain("Tags matching");
  });

  it("shows an empty state with a refine link when a search has no results", () => {
    useQuery.mockReturnValue({
      result: ref({ photos: { collection: [], metadata: {} } }),
    });

    const wrapper = mountIndex({ q: "nonexistent" });

    expect(wrapper.text()).toContain("No photos found for");
    expect(wrapper.text()).toContain("nonexistent");
  });
});
