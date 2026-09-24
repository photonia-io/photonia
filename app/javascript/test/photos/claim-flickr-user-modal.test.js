import { describe, it, expect, beforeEach, afterEach, vi } from "vitest";
import { mount, DOMWrapper } from "@vue/test-utils";
import { nextTick } from "vue";

// Capture each mutation's onDone callback so the test can feed it a server response.
const doneCallbacks = [];
vi.mock("@vue/apollo-composable", () => ({
  useMutation: () => {
    const handlers = {};
    doneCallbacks.push(handlers);
    return {
      mutate: vi.fn(),
      onDone: (cb) => (handlers.done = cb),
      onError: (cb) => (handlers.error = cb),
    };
  },
}));

import ClaimFlickrUserModal from "../../photos/claim-flickr-user-modal.vue";

// The modal is teleported to #modal-root, so query it through the document body.
const body = () => new DOMWrapper(document.body);

const flickrUser = { nsid: "12345678@N00", username: "flickr_person", realname: null };

describe("ClaimFlickrUserModal", () => {
  let modalRoot;
  let wrapper;

  beforeEach(() => {
    doneCallbacks.length = 0;
    modalRoot = document.createElement("div");
    modalRoot.id = "modal-root";
    document.body.appendChild(modalRoot);
    wrapper = mount(ClaimFlickrUserModal, {
      attachTo: document.body,
      props: { flickrUser, isActive: true },
    });
  });

  afterEach(() => {
    wrapper.unmount();
    modalRoot.remove();
  });

  it("shows the server error when the automatic claim request is rejected", async () => {
    await body().find("button.is-primary").trigger("click");

    // First useMutation call in the component is requestAutomaticFlickrClaim.
    doneCallbacks[0].done({
      data: { requestAutomaticFlickrClaim: { claim: null, errors: ["already claimed"] } },
    });
    await nextTick();

    const notification = body().find(".notification.is-danger");
    expect(notification.exists()).toBe(true);
    expect(notification.text()).toContain("already claimed");
    expect(body().text()).not.toContain("Your verification code");
    expect(body().find("button.is-primary").text()).toBe("Start Verification");
  });
});
