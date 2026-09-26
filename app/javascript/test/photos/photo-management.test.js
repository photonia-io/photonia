import { describe, it, expect, beforeEach, afterEach } from "vitest";
import { mount, DOMWrapper } from "@vue/test-utils";
import { createPinia, setActivePinia } from "pinia";

import PhotoManagement from "../../photos/photo-management.vue";

// The delete confirmation is teleported to #modal-root, outside the mounted
// component's own tree.
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

  it("offers the thumbnail and delete actions", () => {
    const { wrapper } = mountPhotoManagement();

    expect(findButton(wrapper, "Edit Thumbnail")).toBeTruthy();
    expect(findButton(wrapper, "Delete Photo")).toBeTruthy();
  });

  it("emits editThumbnail straight away", async () => {
    const { wrapper } = mountPhotoManagement();

    await findButton(wrapper, "Edit Thumbnail").trigger("click");

    expect(wrapper.emitted("editThumbnail")).toBeTruthy();
  });

  it("emits deletePhoto only once the deletion is confirmed", async () => {
    const { wrapper } = mountPhotoManagement();

    await findButton(wrapper, "Delete Photo").trigger("click");
    expect(wrapper.emitted("deletePhoto")).toBeUndefined();

    await findButton(body(), "Delete").trigger("click");
    expect(wrapper.emitted("deletePhoto")).toEqual([[{ id: "some-slug" }]]);
  });

  it("emits nothing when the deletion is cancelled", async () => {
    const { wrapper } = mountPhotoManagement();

    await findButton(wrapper, "Delete Photo").trigger("click");
    await findButton(body(), "Cancel").trigger("click");

    expect(wrapper.emitted("deletePhoto")).toBeUndefined();
  });
});
