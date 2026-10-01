import { describe, it, expect, beforeEach, afterEach, vi } from "vitest";
import { mount, RouterLinkStub, flushPromises } from "@vue/test-utils";
import { createPinia, setActivePinia } from "pinia";

vi.mock("../../../mixins/toaster", () => ({ default: vi.fn() }));
vi.mock("vue-router", () => ({ useRoute: () => ({ path: "/photos/photo-1", query: {} }) }));

// Captures each useMutation() call in the order comments-section.vue makes
// them: createComment, updateComment, deleteComment.
const mutationCalls = [];
vi.mock("@vue/apollo-composable", () => ({
  useMutation: () => {
    const handlers = {};
    const call = { mutate: vi.fn(), handlers };
    mutationCalls.push(call);
    return {
      mutate: call.mutate,
      onDone: (cb) => (handlers.done = cb),
      onError: (cb) => (handlers.error = cb),
    };
  },
}));

import CommentsSection from "../../../shared/comments/comments-section.vue";
import { useUserStore } from "../../../stores/user";
import toaster from "../../../mixins/toaster";

// CommentsSection loads this as defineAsyncComponent() (see #1096) -
// importing it statically here means it's already resolved by the time a
// test mounts CommentsSection, so a single flushPromises() is enough to
// render it.
import "../../../shared/comments/comment-form.vue";

const [createCall, updateCall, deleteCall] = [0, 1, 2];

function baseComment(overrides = {}) {
  return {
    id: "1",
    body: "Hello there",
    bodyHtml: "<p>Hello there</p>",
    bodyEdited: false,
    bodyLastEditedAt: null,
    createdAt: "2026-01-01T12:00:00Z",
    canEdit: false,
    canDelete: false,
    author: { id: "u1", displayName: "Jane Doe" },
    flickrUser: null,
    replies: [],
    ...overrides,
  };
}

let wrapper;
let modalRoot;

function mountSection(props = {}) {
  const pinia = createPinia();
  setActivePinia(pinia);

  wrapper = mount(CommentsSection, {
    attachTo: document.body,
    global: {
      plugins: [pinia],
      stubs: { RouterLink: RouterLinkStub },
    },
    props: {
      commentable: { id: "photo-1", comments: [] },
      commentableType: "Photo",
      loading: false,
      ...props,
    },
  });
  return wrapper;
}

beforeEach(() => {
  mutationCalls.length = 0;
  window.settings = {
    commenting_enabled: true,
    photo_commenting_enabled: true,
    album_commenting_enabled: true,
  };
  modalRoot = document.createElement("div");
  modalRoot.id = "modal-root";
  document.body.appendChild(modalRoot);
});

afterEach(() => {
  wrapper?.unmount();
  modalRoot.remove();
  vi.clearAllMocks();
});

describe("CommentsSection", () => {
  it('shows "There are no comments yet" when there are none', () => {
    mountSection();
    expect(wrapper.text()).toContain("There are no comments yet.");
  });

  it("renders a comment item per top-level comment", () => {
    mountSection({
      commentable: { id: "photo-1", comments: [baseComment({ id: "1" }), baseComment({ id: "2", author: { id: "u2", displayName: "Bob" } })] },
    });

    expect(wrapper.text()).toContain("Jane Doe");
    expect(wrapper.text()).toContain("Bob");
  });

  it("shows nothing while loading", () => {
    mountSection({ loading: true, commentable: { id: "photo-1", comments: [] } });
    expect(wrapper.text()).not.toContain("There are no comments yet.");
  });

  describe("the compose form", () => {
    it("is shown when signed in and commenting is enabled", async () => {
      mountSection();
      useUserStore().signedIn = true;
      await flushPromises();

      expect(wrapper.find("textarea").exists()).toBe(true);
    });

    it("shows a sign-in prompt when signed out and commenting is enabled", async () => {
      mountSection();
      await wrapper.vm.$nextTick();

      expect(wrapper.text()).toContain("Sign in");
      expect(wrapper.text()).toContain("to leave a comment");
      const link = wrapper.findComponent(RouterLinkStub);
      expect(link.props().to).toEqual({ name: "users-sign-in" });
    });

    it("shows neither the form nor the sign-in prompt when commenting is disabled globally", async () => {
      window.settings = { commenting_enabled: false, photo_commenting_enabled: true, album_commenting_enabled: true };
      mountSection();
      const userStore = useUserStore();
      userStore.signedIn = true;
      await wrapper.vm.$nextTick();

      expect(wrapper.find("textarea").exists()).toBe(false);
      expect(wrapper.text()).not.toContain("Sign in");
    });

    it("hides the form on a photo when photo commenting is off, even with the global switch on", async () => {
      window.settings = { commenting_enabled: true, photo_commenting_enabled: false, album_commenting_enabled: true };
      mountSection({ commentableType: "Photo" });
      useUserStore().signedIn = true;
      await wrapper.vm.$nextTick();

      expect(wrapper.find("textarea").exists()).toBe(false);
    });

    it("hides the form on an album when album commenting is off, even with the global switch on", async () => {
      window.settings = { commenting_enabled: true, photo_commenting_enabled: true, album_commenting_enabled: false };
      mountSection({ commentableType: "Album" });
      useUserStore().signedIn = true;
      await wrapper.vm.$nextTick();

      expect(wrapper.find("textarea").exists()).toBe(false);
    });

    it("shows the form on a photo when album commenting is off but photo commenting is on", async () => {
      window.settings = { commenting_enabled: true, photo_commenting_enabled: true, album_commenting_enabled: false };
      mountSection({ commentableType: "Photo" });
      useUserStore().signedIn = true;
      await flushPromises();

      expect(wrapper.find("textarea").exists()).toBe(true);
    });

    it("posts a new comment with the commentable's type and id", async () => {
      mountSection({ commentable: { id: "photo-1", comments: [] } });
      const userStore = useUserStore();
      userStore.signedIn = true;
      await flushPromises();

      await wrapper.find("textarea").setValue("A new comment");
      await wrapper.find("button.is-primary").trigger("click");

      expect(mutationCalls[createCall].mutate).toHaveBeenCalledWith({
        commentableType: "Photo",
        commentableId: "photo-1",
        body: "A new comment",
      });
    });

    it("emits refresh and toasts once the mutation completes", () => {
      mountSection();
      mutationCalls[createCall].handlers.done();

      expect(wrapper.emitted().refresh).toBeTruthy();
      expect(toaster).toHaveBeenCalledWith("Comment posted");
    });

    it("toasts an error message when the mutation fails", () => {
      mountSection();
      mutationCalls[createCall].handlers.error({ message: "boom" });

      expect(toaster).toHaveBeenCalledWith(expect.stringContaining("boom"), "is-danger");
    });
  });

  describe("editing", () => {
    it("submits the edited body via updateComment", async () => {
      mountSection({
        commentable: { id: "photo-1", comments: [baseComment({ id: "5", canEdit: true, body: "Original" })] },
      });

      const editLink = wrapper.findAll(".comment-actions a").find((a) => a.text() === "Edit");
      await editLink.trigger("click");
      await flushPromises();

      await wrapper.find("textarea").setValue("Updated body");
      await wrapper.find("button.is-primary").trigger("click");

      expect(mutationCalls[updateCall].mutate).toHaveBeenCalledWith({ id: "5", body: "Updated body" });
    });
  });

  describe("deleting", () => {
    it("opens a confirmation modal and calls deleteComment when confirmed", async () => {
      mountSection({
        commentable: { id: "photo-1", comments: [baseComment({ id: "9", canDelete: true })] },
      });

      const deleteLink = wrapper.findAll(".comment-actions a").find((a) => a.text() === "Delete");
      await deleteLink.trigger("click");

      const modal = document.querySelector(".modal.is-active");
      expect(modal).toBeTruthy();
      expect(modal.textContent).toContain("Are you sure you want to delete this comment?");

      const confirmButton = [...modal.querySelectorAll("button")].find((b) => b.textContent === "Yes, delete");
      confirmButton.click();

      expect(mutationCalls[deleteCall].mutate).toHaveBeenCalledWith({ id: "9" });
    });

    it("mentions replies in the confirmation when the comment has any", async () => {
      mountSection({
        commentable: {
          id: "photo-1",
          comments: [baseComment({ id: "9", canDelete: true, replies: [baseComment({ id: "10" })] })],
        },
      });

      const deleteLink = wrapper.findAll(".comment-actions a").find((a) => a.text() === "Delete");
      await deleteLink.trigger("click");

      const modal = document.querySelector(".modal.is-active");
      expect(modal.textContent).toContain("will be deleted too");
    });
  });
});
