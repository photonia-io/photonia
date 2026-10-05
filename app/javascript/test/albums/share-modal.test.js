import { describe, it, expect, vi, beforeEach, afterEach } from "vitest";
import { mount, DOMWrapper } from "@vue/test-utils";
import { createPinia, setActivePinia } from "pinia";

const { resolve } = vi.hoisted(() => ({
  resolve: vi.fn(({ params, query }) => ({
    href: `/albums/${params.id}${query?.share ? `?share=${query.share}` : ""}`,
  })),
}));

vi.mock("vue-router", () => ({
  useRouter: () => ({ resolve }),
}));

vi.mock("../../mixins/toaster", () => ({ default: vi.fn() }));

import ShareModal from "../../albums/share-modal.vue";
import toaster from "../../mixins/toaster";

// The modal is teleported to #modal-root, outside the component's own DOM
// tree, so it must be queried through the document body.
const body = () => new DOMWrapper(document.body);
const modalCard = () => body().find(".modal-card");
const radioFor = (label) =>
  body()
    .findAll(".share-mode-option")
    .find((option) => option.text().includes(label))
    .find("input[type='radio']");

const offAlbum = { id: "sunset-trip", shareMode: "off", shareToken: null };

let mountedWrapper;

function mountShareModal(props = {}) {
  const pinia = createPinia();
  setActivePinia(pinia);

  const wrapper = mount(ShareModal, {
    attachTo: document.body,
    global: { plugins: [pinia] },
    props: { active: true, album: offAlbum, ...props },
  });
  mountedWrapper = wrapper;

  return wrapper;
}

describe("ShareModal", () => {
  let modalRoot;

  beforeEach(() => {
    modalRoot = document.createElement("div");
    modalRoot.id = "modal-root";
    document.body.appendChild(modalRoot);

    // happy-dom's navigator.clipboard is a getter-only accessor.
    Object.defineProperty(navigator, "clipboard", {
      value: { writeText: vi.fn().mockResolvedValue(undefined) },
      configurable: true,
    });

    toaster.mockClear();
    resolve.mockClear();
  });

  afterEach(() => {
    mountedWrapper?.unmount();
    mountedWrapper = undefined;
    modalRoot.remove();
  });

  it("opens with the album's current mode selected", () => {
    mountShareModal({
      album: { id: "sunset-trip", shareMode: "public_photos", shareToken: "tok" },
    });

    expect(radioFor("Public photos only").element.checked).toBe(true);
  });

  it("defaults to off when the album has no share mode yet", () => {
    mountShareModal();

    expect(radioFor("Off").element.checked).toBe(true);
  });

  it("shows no link while off", () => {
    mountShareModal();

    expect(modalCard().find("input[type='text']").exists()).toBe(false);
    expect(modalCard().text()).toContain("Pick a mode above to create a link");
  });

  // A token survives being switched off (so turning sharing back on reuses
  // it), but there is nothing active to regenerate while off.
  it("hides the Regenerate Link button while off, even with an existing token", () => {
    mountShareModal({
      album: { id: "sunset-trip", shareMode: "off", shareToken: "secret-token" },
    });

    const regenerateButton = modalCard()
      .findAll("button")
      .find((b) => b.text() === "Regenerate Link");
    expect(regenerateButton).toBeUndefined();
  });

  it("emits setMode as soon as a radio is picked, without a Save step", async () => {
    const wrapper = mountShareModal();

    await radioFor("All photos").setValue(true);

    expect(wrapper.emitted("setMode")).toEqual([
      [{ id: "sunset-trip", mode: "all_photos" }],
    ]);
  });

  it("shows the share link once a token exists", () => {
    mountShareModal({
      album: { id: "sunset-trip", shareMode: "all_photos", shareToken: "secret-token" },
    });

    const input = modalCard().find("input[type='text']");
    expect(input.element.value).toContain("secret-token");
  });

  it("copies the link to the clipboard", async () => {
    mountShareModal({
      album: { id: "sunset-trip", shareMode: "all_photos", shareToken: "secret-token" },
    });

    await modalCard().find("button.button:not(.is-warning):not(.is-info)").trigger("click");

    expect(navigator.clipboard.writeText).toHaveBeenCalledWith(
      expect.stringContaining("secret-token"),
    );
    expect(toaster).toHaveBeenCalledWith("Link copied");
  });

  it("asks for confirmation before regenerating, and emits regenerate only once confirmed", async () => {
    const wrapper = mountShareModal({
      album: { id: "sunset-trip", shareMode: "all_photos", shareToken: "secret-token" },
    });

    const regenerateButton = modalCard()
      .findAll("button")
      .find((b) => b.text() === "Regenerate Link");
    await regenerateButton.trigger("click");

    expect(wrapper.emitted("regenerate")).toBeUndefined();
    expect(modalCard().text()).toContain("The current link will stop working");

    const confirmButton = modalCard()
      .findAll("button")
      .find((b) => b.text() === "Yes, regenerate");
    await confirmButton.trigger("click");

    expect(wrapper.emitted("regenerate")).toEqual([[{ id: "sunset-trip" }]]);
  });

  it("cancels the regenerate confirmation without emitting", async () => {
    const wrapper = mountShareModal({
      album: { id: "sunset-trip", shareMode: "all_photos", shareToken: "secret-token" },
    });

    await modalCard()
      .findAll("button")
      .find((b) => b.text() === "Regenerate Link")
      .trigger("click");

    await modalCard()
      .findAll("button")
      .find((b) => b.text() === "Cancel")
      .trigger("click");

    expect(modalCard().text()).not.toContain("The current link will stop working");
    expect(wrapper.emitted("regenerate")).toBeUndefined();
  });

  it("emits close when Done is clicked", async () => {
    const wrapper = mountShareModal();

    await modalCard()
      .findAll("button")
      .find((b) => b.text() === "Done")
      .trigger("click");

    expect(wrapper.emitted("close")).toBeTruthy();
  });
});
