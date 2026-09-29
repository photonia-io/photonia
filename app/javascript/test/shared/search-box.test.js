import { ref, nextTick } from "vue";
import { mount, RouterLinkStub } from "@vue/test-utils";
import { createPinia, setActivePinia } from "pinia";
import { useQuery } from "@vue/apollo-composable";
import { useRoute, useRouter } from "vue-router";
import { useUserStore } from "@/stores/user";

const { pushMock } = vi.hoisted(() => ({ pushMock: vi.fn() }));

vi.mock("@vue/apollo-composable", () => ({
  useQuery: vi.fn(),
}));

vi.mock("vue-router", () => ({
  useRoute: vi.fn(),
  useRouter: () => ({ push: pushMock }),
}));

import SearchBox from "@/shared/search-box.vue";

function resultWith({ searches = [], terms = [], photos = [], recent = [] } = {}) {
  return ref({ searchSuggestions: { searches, terms, photos, recent } });
}

function mountBox(routeQuery = {}, { admin = false, signedIn = false, result } = {}) {
  useRoute.mockReturnValue({ query: routeQuery });
  const refetch = vi.fn();
  useQuery.mockReturnValue({ result: result || resultWith(), refetch });

  const pinia = createPinia();
  setActivePinia(pinia);
  const userStore = useUserStore();
  userStore.admin = admin;
  userStore.signedIn = signedIn;

  return {
    wrapper: mount(SearchBox, {
      global: {
        plugins: [pinia],
        stubs: { RouterLink: RouterLinkStub },
      },
    }),
    refetch,
  };
}

beforeEach(() => {
  globalThis.gql_queries = { search_suggestions: "query { searchSuggestions { searches { text count } } }" };
  pushMock.mockClear();
  localStorage.clear();
});

describe("shared/search-box.vue", () => {
  it("renders a text input with the expected placeholder", () => {
    const { wrapper } = mountBox();
    expect(wrapper.find("input[type='text']").attributes("placeholder")).toBe("Find a photo");
  });

  it("hydrates the input from the route's q param", () => {
    const { wrapper } = mountBox({ q: "lake" });
    expect(wrapper.find("input[type='text']").element.value).toBe("lake");
  });

  it("does not show the dropdown before the input is focused", () => {
    const { wrapper } = mountBox();
    expect(wrapper.find(".dropdown").classes()).not.toContain("is-active");
  });

  it("submits a plain search on form submit", async () => {
    const { wrapper } = mountBox();

    await wrapper.find("input[type='text']").setValue("lake");
    await wrapper.find("form").trigger("submit");

    expect(pushMock).toHaveBeenCalledWith({ name: "photos-index", query: { q: "lake" } });
  });

  it("submits an empty query when the input is blank", async () => {
    const { wrapper } = mountBox({ q: "lake" });

    await wrapper.find("input[type='text']").setValue("");
    await wrapper.find("form").trigger("submit");

    expect(pushMock).toHaveBeenCalledWith({ name: "photos-index", query: {} });
  });

  describe("suggestions", () => {
    it("shows the searches, terms, and photos groups once there's a prefix", async () => {
      const result = resultWith({
        searches: [{ text: "lake sunset", count: 3 }],
        terms: [{ text: "lakeside", count: 5 }],
        photos: [{ id: "p1", title: "A lake at dawn" }],
      });
      const { wrapper } = mountBox({}, { result });

      const input = wrapper.find("input[type='text']");
      await input.setValue("lak");
      await input.trigger("focus");
      await nextTick();

      expect(wrapper.text()).toContain("lake sunset");
      expect(wrapper.text()).toContain("lakeside");
      expect(wrapper.text()).toContain("A lake at dawn");
    });

    it('shows an "Advanced search for" item once the prefix is long enough', async () => {
      const { wrapper } = mountBox();

      const input = wrapper.find("input[type='text']");
      await input.setValue("lak");
      await input.trigger("focus");
      await nextTick();

      expect(wrapper.text()).toContain("Advanced search for “lak”");
    });

    it("does not show the advanced search item for a single character", async () => {
      const { wrapper } = mountBox();

      const input = wrapper.find("input[type='text']");
      await input.setValue("l");
      await input.trigger("focus");
      await nextTick();

      expect(wrapper.text()).not.toContain("Advanced search for");
    });

    it("shows the signed-in user's recent searches only when the input is empty", async () => {
      const result = resultWith({ recent: ["lake", "mountain"] });
      const { wrapper } = mountBox({}, { signedIn: true, result });

      await wrapper.find("input[type='text']").trigger("focus");
      await nextTick();

      expect(wrapper.text()).toContain("Recent");
      expect(wrapper.text()).toContain("lake");
      expect(wrapper.text()).toContain("mountain");
    });

    it("shows a visitor's own locally remembered recent searches", async () => {
      localStorage.setItem("search-box:recent", JSON.stringify(["sunset"]));
      const { wrapper } = mountBox();

      await wrapper.find("input[type='text']").trigger("focus");
      await nextTick();

      expect(wrapper.text()).toContain("sunset");
    });

    it("remembers a visitor's search locally after submitting", async () => {
      const { wrapper } = mountBox();

      await wrapper.find("input[type='text']").setValue("waterfall");
      await wrapper.find("form").trigger("submit");

      expect(JSON.parse(localStorage.getItem("search-box:recent"))).toContain("waterfall");
    });
  });

  describe("keyboard navigation", () => {
    function mountWithSearches() {
      const result = resultWith({ searches: [{ text: "lake", count: 2 }, { text: "lakeside", count: 1 }] });
      return mountBox({}, { result });
    }

    it("starts with nothing selected", async () => {
      const { wrapper } = mountWithSearches();
      const input = wrapper.find("input[type='text']");
      await input.setValue("lak");
      await input.trigger("focus");
      await nextTick();

      expect(wrapper.find(".dropdown-item.is-active").exists()).toBe(false);
    });

    it("moves the selection down and wraps around", async () => {
      const { wrapper } = mountWithSearches();
      const input = wrapper.find("input[type='text']");
      await input.setValue("lak");
      await input.trigger("focus");
      await nextTick();

      // 2 searches + the advanced-search item = 3 stops; a 4th wraps back to the first
      await input.trigger("keydown.down");
      await input.trigger("keydown.down");
      await input.trigger("keydown.down");
      await input.trigger("keydown.down");
      await nextTick();

      expect(wrapper.findAll(".dropdown-item.is-active")).toHaveLength(1);
      expect(wrapper.findAll(".dropdown-item.is-active")[0].text().trim()).toBe("lake");
    });

    it("navigates to a selected photo suggestion on enter", async () => {
      const result = resultWith({ photos: [{ id: "photo-slug", title: "A lake at dawn" }] });
      const { wrapper } = mountBox({}, { result });

      const input = wrapper.find("input[type='text']");
      await input.setValue("lak");
      await input.trigger("focus");
      await nextTick();

      await input.trigger("keydown.down");
      await input.trigger("keydown.enter");

      expect(pushMock).toHaveBeenCalledWith({ name: "photos-show", params: { id: "photo-slug" } });
    });
  });

  it("closes the dropdown on escape", async () => {
    const { wrapper } = mountBox();
    const input = wrapper.find("input[type='text']");
    await input.setValue("lak");
    await input.trigger("focus");
    await nextTick();
    expect(wrapper.find(".dropdown").classes()).toContain("is-active");

    await input.trigger("keydown.esc");
    await nextTick();

    expect(wrapper.find(".dropdown").classes()).not.toContain("is-active");
  });

  it("closes the dropdown shortly after a blur", async () => {
    vi.useFakeTimers();
    const { wrapper } = mountBox();
    const input = wrapper.find("input[type='text']");
    await input.setValue("lak");
    await input.trigger("focus");
    await nextTick();

    await input.trigger("blur");
    vi.advanceTimersByTime(250);
    await nextTick();

    expect(wrapper.find(".dropdown").classes()).not.toContain("is-active");
    vi.useRealTimers();
  });

  it("links the sliders button to the advanced search page with the current text", () => {
    const { wrapper } = mountBox({ q: "lake" });
    const link = wrapper.findComponent(RouterLinkStub);
    expect(link.props("to")).toEqual({ name: "photos-search", query: { q: "lake" } });
  });
});
