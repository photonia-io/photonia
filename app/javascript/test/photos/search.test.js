import { ref } from "vue";
import { mount } from "@vue/test-utils";
import { createPinia, setActivePinia } from "pinia";
import { useQuery } from "@vue/apollo-composable";
import { useRoute, useRouter } from "vue-router";
import { useUserStore } from "@/stores/user";
import { useTitle } from "vue-page-title";

const { pushMock } = vi.hoisted(() => ({ pushMock: vi.fn() }));

vi.mock("@vue/apollo-composable", () => ({
  useQuery: vi.fn(),
}));

vi.mock("vue-router", () => ({
  useRoute: vi.fn(),
  useRouter: () => ({ push: pushMock }),
}));

vi.mock("vue-page-title", () => ({
  useTitle: vi.fn(),
}));

import PhotosSearch from "@/photos/search.vue";

function emptyResult() {
  return ref({ photoSearch: null, cameras: [], albums: { collection: [] } });
}

function resultWithPhotos(count = 1) {
  return ref({
    photoSearch: {
      collection: Array.from({ length: count }, (_, i) => ({ id: String(i), canEdit: false })),
      metadata: { totalPages: 1, totalCount: count, currentPage: 1, limitValue: 20 },
    },
    cameras: [],
    albums: { collection: [] },
  });
}

function mountSearch(query = {}, { admin = false, result } = {}) {
  useRoute.mockReturnValue({ query });
  useQuery.mockReturnValue({ result: result || emptyResult() });

  const pinia = createPinia();
  setActivePinia(pinia);
  useUserStore().admin = admin;

  return mount(PhotosSearch, {
    global: {
      plugins: [pinia],
      stubs: {
        "router-link": true,
        AutocompleteInput: true,
        ChipList: true,
        PhotoItem: true,
        Pagination: true,
      },
    },
  });
}

beforeEach(() => {
  globalThis.settings = {};
  globalThis.gql_queries = { photos_search: "query { photoSearch { collection { id } } }", photos_search_options: "query { cameras { make } }" };
  pushMock.mockClear();
});

describe("photos/search.vue", () => {
  it("sets the page title to Search", () => {
    mountSearch();
    expect(useTitle).toHaveBeenCalledWith("Search");
  });

  it("hydrates the text field from the route query", () => {
    const wrapper = mountSearch({ q: "lake" });
    expect(wrapper.find("#search-q").element.value).toBe("lake");
  });

  it("disables the Relevance sort option when there is no text query", () => {
    const wrapper = mountSearch({}, { result: resultWithPhotos() });
    expect(wrapper.find('option[value="relevance"]').attributes("disabled")).toBeDefined();
  });

  it("enables the Relevance sort option when there is a text query", () => {
    const wrapper = mountSearch({ q: "lake" }, { result: resultWithPhotos() });
    expect(wrapper.find('option[value="relevance"]').attributes("disabled")).toBeUndefined();
  });

  it("only shows sort/direction and the update button once photos are found", () => {
    const noResults = mountSearch({ q: "lake" }, { result: resultWithPhotos(0) });
    expect(noResults.find("#sort-select").exists()).toBe(false);

    const withResults = mountSearch({ q: "lake" }, { result: resultWithPhotos(1) });
    expect(withResults.find("#sort-select").exists()).toBe(true);
    expect(withResults.find("#dir-select").exists()).toBe(true);
  });

  it("shows a natural-language description of the submitted search", () => {
    const wrapper = mountSearch({ q: "lake", untagged: "1" }, { result: resultWithPhotos(1) });
    expect(wrapper.text()).toContain('Photos matching "lake" and with no tags.');
  });

  it("shows the privacy select only for an admin", () => {
    const asVisitor = mountSearch({}, { admin: false });
    expect(asVisitor.find("#privacy-select").exists()).toBe(false);

    const asAdmin = mountSearch({}, { admin: true });
    expect(asAdmin.find("#privacy-select").exists()).toBe(true);
  });

  it("pushes the expected route query when the form is submitted", async () => {
    const wrapper = mountSearch({});

    await wrapper.find("#search-q").setValue("lake");
    await wrapper.find("form").trigger("submit");

    expect(pushMock).toHaveBeenCalledWith({
      name: "photos-search",
      query: { q: "lake", tagsMode: "all", sort: "relevance", dir: "desc" },
    });
  });

  it("resets by pushing an empty query", async () => {
    const wrapper = mountSearch({ q: "lake" });

    const resetButton = wrapper.findAll("button").find((button) => button.text() === "Reset");
    await resetButton.trigger("click");

    expect(pushMock).toHaveBeenCalledWith({ name: "photos-search", query: {} });
  });

  it("highlights a field's label once it has a value, and not before", () => {
    const empty = mountSearch({});
    expect(empty.find('label[for="search-q"]').classes()).not.toContain("is-filled");

    const filled = mountSearch({ q: "lake" });
    expect(filled.find('label[for="search-q"]').classes()).toContain("is-filled");
  });

  it("keeps the detailed camera settings collapsed by default", () => {
    const wrapper = mountSearch({});
    expect(wrapper.find(".collapse").classes()).not.toContain("is-open");
  });

  it("opens the detailed camera settings on load when one of its filters is already set", () => {
    const wrapper = mountSearch({ isoMin: "100" });
    expect(wrapper.find(".collapse").classes()).toContain("is-open");
  });
});
