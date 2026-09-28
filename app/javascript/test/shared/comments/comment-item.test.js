import { describe, it, expect, afterEach, beforeEach } from "vitest";
import { mount } from "@vue/test-utils";
import { createPinia, setActivePinia } from "pinia";

import CommentItem from "../../../shared/comments/comment-item.vue";
import { useUserStore } from "../../../stores/user";

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
    global: { plugins: [pinia] },
    props: { comment: baseComment(), canReply: true, ...props },
  });
  return wrapper;
}

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

  it("switches to an edit form when editTargetId matches, showing the current body", () => {
    mountItem({ comment: baseComment({ id: "7", body: "Original text", canEdit: true }), editTargetId: "7" });

    expect(wrapper.find(".content").exists()).toBe(false);
    expect(wrapper.find("textarea").element.value).toBe("Original text");
  });

  it("shows a reply form when replyTargetId matches this comment", () => {
    mountItem({ comment: baseComment({ id: "9" }), replyTargetId: "9" });

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
});
