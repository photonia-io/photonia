import { describe, it, expect, afterEach, beforeEach, vi } from "vitest";
import { mount, flushPromises, RouterLinkStub } from "@vue/test-utils";
import { createPinia, setActivePinia } from "pinia";

import CommentItem from "../../../shared/comments/comment-item.vue";
import { useUserStore } from "../../../stores/user";

// CommentItem loads this as defineAsyncComponent() (see #1096) - importing
// it statically here means it's already resolved by the time a test mounts
// CommentItem, so a single flushPromises() is enough to render it.
import "../../../shared/comments/comment-form.vue";

const mockRoute = vi.hoisted(() => ({ path: "/photos/a-photo", query: {} }));
vi.mock("vue-router", () => ({ useRoute: () => mockRoute }));

const toasterMock = vi.hoisted(() => vi.fn());
vi.mock("../../../mixins/toaster", () => ({ default: toasterMock }));

let wrapper;

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

function mountItem(props = {}) {
  const pinia = createPinia();
  setActivePinia(pinia);

  wrapper = mount(CommentItem, {
    global: { plugins: [pinia], stubs: { RouterLink: RouterLinkStub } },
    props: { comment: baseComment(), canReply: true, ...props },
  });
  return wrapper;
}

beforeEach(() => {
  mockRoute.query = {};
  toasterMock.mockClear();
});

afterEach(() => {
  wrapper?.unmount();
});

describe("CommentItem", () => {
  it("renders the site author's display name and body HTML verbatim", () => {
    mountItem({ comment: baseComment({ bodyHtml: "<p>Nice <strong>shot</strong></p>" }) });

    expect(wrapper.text()).toContain("Jane Doe");
    expect(wrapper.find(".content").html()).toContain("<strong>shot</strong>");
  });

  it("falls back to \"Deleted user\" when there is no author and no Flickr user", () => {
    mountItem({ comment: baseComment({ author: null }) });

    expect(wrapper.text()).toContain("Deleted user");
  });

  it("renders a Flickr-imported comment with its Flickr identity", () => {
    mountItem({
      comment: baseComment({
        author: null,
        flickrUser: {
          nsid: "123@N00",
          username: "flickrperson",
          realname: null,
          profileurl: "https://flickr.com/people/123",
          iconfarm: null,
          iconserver: null,
          claimable: false,
        },
      }),
    });

    expect(wrapper.text()).toContain("flickrperson");
    expect(wrapper.find("a.flickr-link").attributes("href")).toBe("https://flickr.com/people/123");
    expect(wrapper.text()).not.toContain("Deleted user");
  });

  it("hides the claim link when the viewer is signed out, even if claimable", () => {
    mountItem({
      comment: baseComment({
        author: null,
        flickrUser: {
          nsid: "123@N00",
          username: "flickrperson",
          realname: null,
          profileurl: "https://flickr.com/people/123",
          iconfarm: null,
          iconserver: null,
          claimable: true,
        },
      }),
    });

    expect(wrapper.find(".claim-link").exists()).toBe(false);
  });

  it("emits claim with the Flickr user when the claim link is clicked", async () => {
    const flickrUser = {
      nsid: "123@N00",
      username: "flickrperson",
      realname: null,
      profileurl: "https://flickr.com/people/123",
      iconfarm: null,
      iconserver: null,
      claimable: true,
    };
    mountItem({ comment: baseComment({ author: null, flickrUser }) });
    useUserStore().signedIn = true;
    await wrapper.vm.$nextTick();

    await wrapper.find(".claim-link a").trigger("click");

    expect(wrapper.emitted().claim[0]).toEqual([flickrUser]);
  });

  it("shows Reply only when canReply is true", () => {
    mountItem({ canReply: true });
    expect(wrapper.text()).toContain("Reply");

    mountItem({ canReply: false });
    expect(wrapper.text()).not.toContain("Reply");
  });

  it("shows Edit and Delete only when canEdit/canDelete are true", () => {
    mountItem({ comment: baseComment({ canEdit: false, canDelete: false }) });
    expect(wrapper.text()).not.toContain("Edit");
    expect(wrapper.text()).not.toContain("Delete");

    mountItem({ comment: baseComment({ canEdit: true, canDelete: true }) });
    expect(wrapper.text()).toContain("Edit");
    expect(wrapper.text()).toContain("Delete");
  });

  it("emits start-reply with the comment id when Reply is clicked", async () => {
    mountItem({ comment: baseComment({ id: "42" }) });

    await wrapper.find(".comment-actions a").trigger("click");

    expect(wrapper.emitted()["start-reply"][0]).toEqual(["42"]);
  });

  it("emits request-delete with the comment when Delete is clicked", async () => {
    const comment = baseComment({ canDelete: true });
    mountItem({ comment });

    const deleteLink = wrapper.findAll(".comment-actions a").find((a) => a.text() === "Delete");
    await deleteLink.trigger("click");

    expect(wrapper.emitted()["request-delete"][0]).toEqual([comment]);
  });

  it("switches to an edit form when editTargetId matches, showing the current body", async () => {
    mountItem({ comment: baseComment({ id: "7", body: "Original text", canEdit: true }), editTargetId: "7" });
    await flushPromises();

    expect(wrapper.find(".content").exists()).toBe(false);
    expect(wrapper.find("textarea").element.value).toBe("Original text");
  });

  it("shows a reply form when replyTargetId matches this comment", async () => {
    mountItem({ comment: baseComment({ id: "9" }), replyTargetId: "9" });
    await flushPromises();

    const textareas = wrapper.findAll("textarea");
    expect(textareas.length).toBeGreaterThan(0);
  });

  it("renders nested replies and forwards their events upward", async () => {
    const reply = baseComment({
      id: "2",
      body: "A reply",
      bodyHtml: "<p>A reply</p>",
      author: { id: "u2", displayName: "Bob" },
      canDelete: true,
    });
    mountItem({ comment: baseComment({ id: "1", replies: [reply] }) });

    expect(wrapper.text()).toContain("Bob");
    expect(wrapper.text()).toContain("A reply");

    // Scoped to the nested replies container, not the parent's own actions.
    const repliesContainer = wrapper.find(".replies");
    const deleteLink = repliesContainer.findAll(".comment-actions a").find((a) => a.text() === "Delete");
    await deleteLink.trigger("click");

    expect(wrapper.emitted()["request-delete"][0]).toEqual([reply]);
  });

  it("never shows a Reply link on a nested reply", () => {
    const reply = baseComment({ id: "2" });
    mountItem({ comment: baseComment({ id: "1", replies: [reply] }) });

    const repliesContainer = wrapper.find(".replies");
    expect(repliesContainer.text()).not.toContain("Reply");
  });

  describe("permalinks", () => {
    it("gives the comment and its replies anchor ids", () => {
      mountItem({
        comment: baseComment({ id: "7", replies: [baseComment({ id: "8" })] }),
      });

      expect(wrapper.find("#comment-7").exists()).toBe(true);
      expect(wrapper.find("#comment-8").exists()).toBe(true);
    });

    it("links the timestamp to the comment, keeping the existing query", () => {
      mockRoute.query = { inAlbum: "an-album" };
      mountItem();

      expect(wrapper.findComponent(RouterLinkStub).props("to")).toEqual({
        path: "/photos/a-photo",
        query: { inAlbum: "an-album", highlightComment: "1" },
      });
    });

    it("copies the canonical permalink and confirms with a toast", async () => {
      mockRoute.query = { inAlbum: "an-album" };
      const writeText = vi.fn().mockResolvedValue();
      vi.stubGlobal("navigator", { clipboard: { writeText } });
      mountItem();

      const copy = wrapper.findAll(".comment-actions a").find((a) => a.text() === "Copy link");
      await copy.trigger("click");
      await flushPromises();

      expect(writeText).toHaveBeenCalledWith(
        `${window.location.origin}/photos/a-photo?highlightComment=1`,
      );
      expect(toasterMock).toHaveBeenCalledWith("Link copied");
      vi.unstubAllGlobals();
    });

    it("highlights only the targeted comment", () => {
      mockRoute.query = { highlightComment: "8" };
      mountItem({
        comment: baseComment({ id: "7", replies: [baseComment({ id: "8" })] }),
      });

      expect(wrapper.find("#comment-7").classes()).not.toContain("is-target");
      expect(wrapper.find("#comment-8").classes()).toContain("is-target");
    });
  });
});
