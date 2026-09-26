import { describe, it, expect, vi, beforeEach, afterEach } from "vitest";
import { mount, DOMWrapper } from "@vue/test-utils";
import { createPinia, setActivePinia } from "pinia";
import { ref } from "vue";

vi.mock("@vue/apollo-composable", () => ({
  useQuery: vi.fn(() => ({
    result: ref({
      currentUser: {
        albums: [{ id: "sunset-trip", title: "Sunset Trip", photosCount: 3 }],
      },
    }),
  })),
}));

import PhotoManagement from "../../photos/photo-management.vue";

// The Add To Album modal is teleported to #modal-root, outside the mounted
// component's tree.
const body = () => new DOMWrapper(document.body);

const photo = { id: "some-slug", title: "A photo" };

let mountedWrapper;

function mountPhotoManagement() {
  const pinia = createPinia();
  setActivePinia(pinia);

  const wrapper = mount(PhotoManagement, {
    attachTo: document.body,
    global: { plugins: [pinia] },
    props: { photo },
  });
  mountedWrapper = wrapper;

  return { wrapper };
}

const findButton = (wrapper, label) =>
  wrapper.findAll("button").find((b) => b.text().includes(label));

describe("PhotoManagement", () => {
  let modalRoot;

  beforeEach(() => {
    modalRoot = document.createElement("div");
    modalRoot.id = "modal-root";
    document.body.appendChild(modalRoot);
  });

  afterEach(() => {
    mountedWrapper?.unmount();
    mountedWrapper = undefined;
    modalRoot.remove();
  });

  it("offers Add To Album alongside the existing actions", () => {
    const { wrapper } = mountPhotoManagement();

    expect(findButton(wrapper, "Add To Album")).toBeTruthy();
    expect(findButton(wrapper, "Edit Thumbnail")).toBeTruthy();
    expect(findButton(wrapper, "Delete Photo")).toBeTruthy();
  });

  it("re-emits addPhotosToAlbum for this photo alone when an album is picked", async () => {
    const { wrapper } = mountPhotoManagement();

    await findButton(wrapper, "Add To Album").trigger("click");
    await body().find("select").setValue("sunset-trip");
    await findButton(body(), "Add").trigger("click");

    expect(wrapper.emitted("addPhotosToAlbum")).toEqual([
      [{ albumId: "sunset-trip", photoIds: ["some-slug"] }],
    ]);
    expect(wrapper.emitted("createAlbumWithPhotos")).toBeUndefined();
  });

  it("re-emits createAlbumWithPhotos when a new album title is entered", async () => {
    const { wrapper } = mountPhotoManagement();

    await findButton(wrapper, "Add To Album").trigger("click");
    await body().find('input[type="text"]').setValue("Holiday");
    await findButton(body(), "Add").trigger("click");

    expect(wrapper.emitted("createAlbumWithPhotos")).toEqual([
      [{ title: "Holiday", photoIds: ["some-slug"] }],
    ]);
    expect(wrapper.emitted("addPhotosToAlbum")).toBeUndefined();
  });

  it("still emits deletePhoto once the deletion is confirmed", async () => {
    const { wrapper } = mountPhotoManagement();

    await findButton(wrapper, "Delete Photo").trigger("click");
    await findButton(body(), "Delete").trigger("click");

    expect(wrapper.emitted("deletePhoto")).toEqual([[{ id: "some-slug" }]]);
  });
});
