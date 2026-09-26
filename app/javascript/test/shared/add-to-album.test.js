import { describe, it, expect, vi } from "vitest";
import { mount } from "@vue/test-utils";
import { createPinia, setActivePinia } from "pinia";
import { ref } from "vue";

vi.mock("@vue/apollo-composable", () => ({
  useQuery: vi.fn(() => ({
    result: ref({ currentUser: { albums: [], albumsWithPhotos: [] } }),
  })),
}));

import AddToAlbumButton from "../../shared/buttons/add-to-album.vue";

function mountButton(props = {}) {
  const pinia = createPinia();
  setActivePinia(pinia);

  return mount(AddToAlbumButton, {
    global: { plugins: [pinia], stubs: { teleport: true } },
    props: { photos: [{ id: "a" }], ...props },
  });
}

describe("AddToAlbumButton", () => {
  it("applies buttonClass to the trigger", () => {
    const wrapper = mountButton({ buttonClass: "is-fullwidth" });
    const classes = wrapper.find("button").classes();

    expect(classes).toContain("button");
    expect(classes).toContain("is-fullwidth");
  });

  it("shows the default label, and an overridden one", () => {
    expect(mountButton().find("button").text()).toBe("Add To Album");
    expect(mountButton({ label: "Add Photo to an Album" }).find("button").text()).toBe(
      "Add Photo to an Album",
    );
  });

  it("puts the icon and label side by side, not in an .icon-text wrapper", () => {
    const wrapper = mountButton();
    const button = wrapper.find("button");

    expect(button.find(".icon-text").exists()).toBe(false);
    expect(button.find(".icon").exists()).toBe(true);
  });
});
