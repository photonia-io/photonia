import { describe, it, expect, vi, beforeEach } from "vitest";
import { mount, RouterLinkStub } from "@vue/test-utils";
import { createPinia, setActivePinia } from "pinia";
import { ref } from "vue";

const routeState = vi.hoisted(() => ({
  current: { name: "photos-index", params: {}, query: {} },
}));

vi.mock("vue-router", () => ({
  useRoute: () => routeState.current,
}));

vi.mock("@vue/apollo-composable", () => ({
  useMutation: vi.fn(() => ({
    mutate: vi.fn(),
    onDone: vi.fn(),
    onError: vi.fn(),
  })),
  useQuery: vi.fn(() => ({ result: ref(null) })),
}));

import SelectionBar from "../../shared/selection-bar.vue";
import { useSelectionStore } from "../../stores/selection";
import { useUserStore } from "../../stores/user";

function mountBar(route = { name: "photos-index", params: {}, query: {} }) {
  routeState.current = route;

  const pinia = createPinia();
  setActivePinia(pinia);

  const userStore = useUserStore();
  userStore.signedIn = true;
  userStore.email = "owner@example.com";

  const selectionStore = useSelectionStore();

  const wrapper = mount(SelectionBar, {
    global: {
      plugins: [pinia],
      provide: { apolloClient: { cache: { reset: vi.fn() } } },
      stubs: { RouterLink: RouterLinkStub, teleport: true },
    },
  });

  return { wrapper, selectionStore };
}

describe("SelectionBar", () => {
  beforeEach(() => {
    localStorage.clear();
  });

  it("renders nothing while the selection is empty", () => {
    const { wrapper } = mountBar();

    expect(wrapper.find(".selection-bar").exists()).toBe(false);
  });

  it("shows the count and core actions once something is selected", async () => {
    const { wrapper, selectionStore } = mountBar();
    selectionStore.setContext("photos-index");
    selectionStore.add({ id: "a", title: "A" });
    await wrapper.vm.$nextTick();

    expect(wrapper.find(".selection-bar").exists()).toBe(true);
    expect(wrapper.text()).toContain("1");
    expect(wrapper.text()).toContain("selected");
    expect(wrapper.text()).not.toContain("Remove From This Album");
    expect(wrapper.text()).not.toContain("Set As Cover");
  });

  it("shows album-specific actions only on an album context", async () => {
    const { wrapper, selectionStore } = mountBar({
      name: "albums-show",
      params: { id: "sunset-trip" },
      query: {},
    });
    selectionStore.add({ id: "a", title: "A" });
    await wrapper.vm.$nextTick();

    expect(wrapper.text()).toContain("Remove From This Album");
    // Only offered with exactly one photo selected.
    expect(wrapper.text()).toContain("Set As Cover");

    selectionStore.add({ id: "b", title: "B" });
    await wrapper.vm.$nextTick();
    expect(wrapper.text()).not.toContain("Set As Cover");
  });

  it("selects and deselects everything on the current page", async () => {
    const { wrapper, selectionStore } = mountBar();
    selectionStore.setPageCollection([{ id: "a", title: "A" }, { id: "b", title: "B" }]);
    selectionStore.setContext("photos-index");
    selectionStore.add({ id: "a", title: "A" });
    await wrapper.vm.$nextTick();

    await wrapper.findAll("button").find((b) => b.text().includes("Select All On Page")).trigger("click");
    expect(selectionStore.count).toBe(2);

    await wrapper.findAll("button").find((b) => b.text().includes("Deselect All On Page")).trigger("click");
    expect(selectionStore.count).toBe(0);
  });

  it("opens the selection drawer", async () => {
    const { wrapper, selectionStore } = mountBar();
    selectionStore.setContext("photos-index");
    selectionStore.add({ id: "a", title: "A" });
    await wrapper.vm.$nextTick();

    expect(wrapper.findComponent({ name: "SelectionDrawer" }).exists()).toBe(false);

    await wrapper.findAll("button").find((b) => b.text().includes("View Selected")).trigger("click");
    expect(wrapper.findComponent({ name: "SelectionDrawer" }).exists()).toBe(true);
  });
});
