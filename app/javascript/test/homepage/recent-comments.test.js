import { describe, it, expect } from "vitest";
import { mount, RouterLinkStub } from "@vue/test-utils";

import RecentComments from "../../homepage/recent-comments.vue";

const photoComment = {
  id: "1",
  snippet: "Lovely light",
  authorName: "Ana",
  createdAt: new Date(Date.now() - 2 * 24 * 3600 * 1000).toISOString(),
  photo: {
    id: "a-photo",
    title: "A photo",
    intelligentOrSquareMediumImageUrl: "p.jpg",
  },
  album: null,
};

const albumComment = {
  id: "2",
  snippet: "Great trip",
  authorName: "Bob",
  createdAt: new Date().toISOString(),
  photo: null,
  album: {
    id: "an-album",
    title: "An album",
    coverPhoto: { intelligentOrSquareMediumImageUrl: "c.jpg" },
  },
};

const mountList = () =>
  mount(RecentComments, {
    props: { comments: [photoComment, albumComment] },
    global: { stubs: { RouterLink: RouterLinkStub } },
  });

describe("RecentComments", () => {
  it("shows author, target title, snippet and relative time", () => {
    const text = mountList().text();

    expect(text).toContain("Ana");
    expect(text).toContain("A photo");
    expect(text).toContain("Lovely light");
    expect(text).toContain("2 days ago");
  });

  it("links photo comments to the photo and album comments to the album", () => {
    const routes = mountList()
      .findAllComponents(RouterLinkStub)
      .map((link) => link.props("to"));

    expect(routes).toContainEqual({ name: "photos-show", params: { id: "a-photo" } });
    expect(routes).toContainEqual({ name: "albums-show", params: { id: "an-album" } });
  });

  it("uses the album's cover as its thumbnail", () => {
    const sources = mountList()
      .findAll("img")
      .map((img) => img.attributes("src"));

    expect(sources).toEqual(["p.jpg", "c.jpg"]);
  });
});
