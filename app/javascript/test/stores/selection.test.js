import { describe, it, expect, beforeEach } from "vitest";
import { createPinia, setActivePinia } from "pinia";
import { nextTick } from "vue";

import { useSelectionStore } from "../../stores/selection";
import { useUserStore } from "../../stores/user";

const photo = (id, title = `Photo ${id}`) => ({
  id,
  title,
  intelligentOrSquareMediumImageUrl: `https://example.com/${id}.jpg`,
});

function setUpStores({ email = "owner@example.com" } = {}) {
  const pinia = createPinia();
  setActivePinia(pinia);

  const userStore = useUserStore();
  userStore.signedIn = true;
  userStore.email = email;

  return { userStore, selectionStore: useSelectionStore() };
}

describe("selection store", () => {
  beforeEach(() => {
    // happy-dom's localStorage isn't reset between tests in the same file.
    localStorage.clear();
  });

  describe("without an active context", () => {
    it("ignores adds and reports nothing selected", () => {
      const { selectionStore } = setUpStores();

      selectionStore.add(photo("a"));

      expect(selectionStore.count).toBe(0);
      expect(selectionStore.isSelected("a")).toBe(false);
    });
  });

  describe("add / remove / toggle", () => {
    it("adds, avoids duplicates, and removes by id", () => {
      const { selectionStore } = setUpStores();
      selectionStore.setContext("ctx-a");

      selectionStore.add(photo("a"));
      selectionStore.add(photo("a")); // duplicate, ignored
      selectionStore.add(photo("b"));

      expect(selectionStore.count).toBe(2);

      selectionStore.remove("a");
      expect(selectionStore.count).toBe(1);
      expect(selectionStore.isSelected("b")).toBe(true);
    });

    it("toggle flips selection state", () => {
      const { selectionStore } = setUpStores();
      selectionStore.setContext("ctx-a");

      selectionStore.toggle(photo("a"));
      expect(selectionStore.isSelected("a")).toBe(true);

      selectionStore.toggle(photo("a"));
      expect(selectionStore.isSelected("a")).toBe(false);
    });

    it("only stores id, title and thumbnailUrl, not the whole photo object", () => {
      const { selectionStore } = setUpStores();
      selectionStore.setContext("ctx-a");

      selectionStore.add({ ...photo("a"), canEdit: true, extraField: "should not persist" });

      expect(selectionStore.selected[0]).toEqual({
        id: "a",
        title: "Photo a",
        thumbnailUrl: "https://example.com/a.jpg",
      });
    });
  });

  describe("contexts", () => {
    it("scopes selection to the active context", () => {
      const { selectionStore } = setUpStores();

      selectionStore.setContext("ctx-a");
      selectionStore.add(photo("a"));

      selectionStore.setContext("ctx-b");
      expect(selectionStore.count).toBe(0);
      selectionStore.add(photo("b"));

      selectionStore.setContext("ctx-a");
      expect(selectionStore.count).toBe(1);
      expect(selectionStore.isSelected("a")).toBe(true);
      expect(selectionStore.isSelected("b")).toBe(false);
    });

    it("drops the page collection when the context changes", () => {
      const { selectionStore } = setUpStores();

      selectionStore.setContext("albums-show:first");
      selectionStore.setPageCollection([photo("a"), photo("b")]);

      // Views keep the outgoing album's photos until the next one loads, so
      // the stale page must not follow the context.
      selectionStore.setContext("albums-show:second");
      expect(selectionStore.pageCollection).toEqual([]);
    });

    it("remembers up to 3 contexts and evicts the least recently touched", () => {
      const { selectionStore } = setUpStores();

      selectionStore.setContext("ctx-a");
      selectionStore.add(photo("a"));

      selectionStore.setContext("ctx-b");
      selectionStore.add(photo("b"));

      selectionStore.setContext("ctx-c");
      selectionStore.add(photo("c"));

      // A 4th context evicts the oldest untouched one (ctx-a).
      selectionStore.setContext("ctx-d");
      selectionStore.add(photo("d"));

      selectionStore.setContext("ctx-a");
      expect(selectionStore.count).toBe(0);

      selectionStore.setContext("ctx-b");
      expect(selectionStore.count).toBe(1);
    });
  });

  describe("selectRange", () => {
    it("selects everything between the last toggle and the target, inclusive", () => {
      const { selectionStore } = setUpStores();
      selectionStore.setContext("ctx-a");
      selectionStore.setPageCollection([photo("a"), photo("b"), photo("c"), photo("d")]);

      selectionStore.toggle(photo("b"));
      selectionStore.selectRange("d");

      expect(selectionStore.selected.map((p) => p.id).sort()).toEqual(["b", "c", "d"]);
    });

    it("falls back to a plain toggle when there is no anchor", () => {
      const { selectionStore } = setUpStores();
      selectionStore.setContext("ctx-a");
      selectionStore.setPageCollection([photo("a"), photo("b")]);

      selectionStore.selectRange("b");

      expect(selectionStore.isSelected("b")).toBe(true);
      expect(selectionStore.count).toBe(1);
    });
  });

  describe("prune", () => {
    it("drops only the given ids, keeping the rest of the selection", () => {
      const { selectionStore } = setUpStores();
      selectionStore.setContext("ctx-a");
      selectionStore.addMany([photo("a"), photo("b"), photo("c")]);

      selectionStore.prune(["a", "c"]);

      expect(selectionStore.selected.map((p) => p.id)).toEqual(["b"]);
    });
  });

  describe("clear vs clearAll", () => {
    it("clear empties only the active context", () => {
      const { selectionStore } = setUpStores();

      selectionStore.setContext("ctx-a");
      selectionStore.add(photo("a"));
      selectionStore.setContext("ctx-b");
      selectionStore.add(photo("b"));

      selectionStore.clear();
      expect(selectionStore.count).toBe(0);

      selectionStore.setContext("ctx-a");
      expect(selectionStore.count).toBe(1);
    });

    it("clearAll empties every context", () => {
      const { selectionStore } = setUpStores();

      selectionStore.setContext("ctx-a");
      selectionStore.add(photo("a"));
      selectionStore.setContext("ctx-b");
      selectionStore.add(photo("b"));

      selectionStore.clearAll();

      selectionStore.setContext("ctx-a");
      expect(selectionStore.count).toBe(0);
      selectionStore.setContext("ctx-b");
      expect(selectionStore.count).toBe(0);
    });
  });

  describe("persistence", () => {
    it("survives being reloaded for the same signed-in user", async () => {
      const { selectionStore } = setUpStores();
      selectionStore.setContext("ctx-a");
      selectionStore.add(photo("a"));
      await nextTick(); // the deep watch that persists to localStorage is async

      // Simulate a reload: fresh pinia, same signed-in user.
      const pinia = createPinia();
      setActivePinia(pinia);
      const userStore = useUserStore();
      userStore.signedIn = true;
      userStore.email = "owner@example.com";
      const reloaded = useSelectionStore();
      reloaded.setContext("ctx-a");

      expect(reloaded.isSelected("a")).toBe(true);
    });

    it("never inherits another user's selection, and clears on sign-out", async () => {
      const first = setUpStores({ email: "first@example.com" });
      first.selectionStore.setContext("ctx-a");
      first.selectionStore.add(photo("a"));
      await nextTick(); // the deep watch that persists to localStorage is async

      const second = setUpStores({ email: "second@example.com" });
      second.selectionStore.setContext("ctx-a");
      expect(second.selectionStore.count).toBe(0);

      second.selectionStore.add(photo("b"));
      second.selectionStore.clearAll(); // what applicationStore.signOut() calls
      expect(second.selectionStore.count).toBe(0);

      // The first user's own data is untouched by the second user's sign-out.
      const pinia = createPinia();
      setActivePinia(pinia);
      const userStore = useUserStore();
      userStore.signedIn = true;
      userStore.email = "first@example.com";
      const reloaded = useSelectionStore();
      reloaded.setContext("ctx-a");
      expect(reloaded.isSelected("a")).toBe(true);
    });

    it("does not leave a stored selection behind after signing out", async () => {
      const { userStore, selectionStore } = setUpStores();
      selectionStore.setContext("ctx-a");
      selectionStore.add(photo("a"));
      await nextTick();

      // The real order: clearAll() runs first, then the identity goes away, so
      // the persisting watcher can no longer resolve the key it should erase.
      selectionStore.clearAll();
      userStore.signedIn = false;
      userStore.email = "";
      await nextTick();

      const pinia = createPinia();
      setActivePinia(pinia);
      const returning = useUserStore();
      returning.signedIn = true;
      returning.email = "owner@example.com";
      const reloaded = useSelectionStore();
      reloaded.setContext("ctx-a");

      expect(reloaded.count).toBe(0);
    });

    it("falls back to an empty selection when localStorage throws", () => {
      const original = Storage.prototype.getItem;
      Storage.prototype.getItem = () => {
        throw new Error("storage unavailable");
      };

      try {
        const { selectionStore } = setUpStores();
        selectionStore.setContext("ctx-a");
        expect(selectionStore.count).toBe(0);
        expect(() => selectionStore.add(photo("a"))).not.toThrow();
      } finally {
        Storage.prototype.getItem = original;
      }
    });
  });
});
