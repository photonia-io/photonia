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

// Keeps each mutation's mutate/onDone/onError reachable from the tests, keyed
// by the operation its document calls.
const mutations = vi.hoisted(() => ({ registry: {} }));

vi.mock("@vue/apollo-composable", () => ({
  useMutation: (document) => {
    const body = document?.loc?.source?.body ?? "";
    const name =
      [
        "addPhotosToAlbum",
        "createAlbumWithPhotos",
        "removePhotosFromAlbum",
        "setAlbumCoverPhoto",
        "deletePhotos",
      ].find((operation) => body.includes(`${operation}(`)) ?? "unknown";

    const entry = { mutate: vi.fn(), done: null, error: null };
    mutations.registry[name] = entry;

    return {
      mutate: entry.mutate,
      onDone: (callback) => {
        entry.done = callback;
      },
      onError: (callback) => {
        entry.error = callback;
      },
    };
  },
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
    mutations.registry = {};
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
    // Context first, page second — that is the real order, and switching
    // context drops whatever page was loaded for the previous one.
    selectionStore.setContext("photos-index");
    selectionStore.setPageCollection([
      { id: "a", title: "A", canEdit: true },
      { id: "b", title: "B", canEdit: true },
    ]);
    selectionStore.add({ id: "a", title: "A" });
    await wrapper.vm.$nextTick();

    await wrapper.findAll("button").find((b) => b.text().includes("Select All On Page")).trigger("click");
    expect(selectionStore.count).toBe(2);

    await wrapper.findAll("button").find((b) => b.text().includes("Deselect All On Page")).trigger("click");
    expect(selectionStore.count).toBe(0);
  });

  it("leaves photos the user cannot edit out of select all", async () => {
    const { wrapper, selectionStore } = mountBar();
    selectionStore.setContext("photos-index");
    selectionStore.setPageCollection([
      { id: "a", title: "A", canEdit: true },
      { id: "b", title: "B", canEdit: false },
    ]);
    selectionStore.add({ id: "a", title: "A" });
    await wrapper.vm.$nextTick();

    await wrapper.findAll("button").find((b) => b.text().includes("Select All On Page")).trigger("click");
    expect(selectionStore.selected.map((p) => p.id)).toEqual(["a"]);
  });

  describe("Remove From This Album", () => {
    const albumContext = { name: "albums-show", params: { id: "sunset-trip" }, query: {} };

    async function confirmRemoval(wrapper) {
      await wrapper.findAll("button").find((b) => b.text().includes("Remove From This Album")).trigger("click");
      await wrapper.findAll("button").find((b) => b.text() === "Yes, remove").trigger("click");
    }

    it("deselects the photos once the removal comes back clean", async () => {
      const { wrapper, selectionStore } = mountBar(albumContext);
      selectionStore.addMany([{ id: "a", title: "A" }, { id: "b", title: "B" }]);
      await wrapper.vm.$nextTick();

      await confirmRemoval(wrapper);
      expect(mutations.registry.removePhotosFromAlbum.mutate).toHaveBeenCalledWith({
        albumId: "sunset-trip",
        photoIds: ["a", "b"],
      });
      expect(selectionStore.count).toBe(2);

      mutations.registry.removePhotosFromAlbum.done({
        data: { removePhotosFromAlbum: { errors: [], album: { id: "sunset-trip", title: "Sunset" } } },
      });
      expect(selectionStore.count).toBe(0);
    });

    it("keeps the selection when the removal fails", async () => {
      const { wrapper, selectionStore } = mountBar(albumContext);
      selectionStore.addMany([{ id: "a", title: "A" }, { id: "b", title: "B" }]);
      await wrapper.vm.$nextTick();

      await confirmRemoval(wrapper);
      mutations.registry.removePhotosFromAlbum.done({
        data: { removePhotosFromAlbum: { errors: ["Nope"], album: null } },
      });

      expect(selectionStore.count).toBe(2);
    });

    it("leaves the selection alone for a removal from some other album", async () => {
      const { wrapper, selectionStore } = mountBar(albumContext);
      selectionStore.addMany([{ id: "a", title: "A" }]);
      await wrapper.vm.$nextTick();

      // The dropdown button removes from an album the user picks, which is not
      // the one being browsed, so nothing should be deselected.
      mutations.registry.removePhotosFromAlbum.done({
        data: { removePhotosFromAlbum: { errors: [], album: { id: "other-album", title: "Other" } } },
      });

      expect(selectionStore.count).toBe(1);
    });
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
