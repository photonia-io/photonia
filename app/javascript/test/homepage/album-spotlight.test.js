import { describe, it, expect } from "vitest";
import { mount, RouterLinkStub } from "@vue/test-utils";

import AlbumSpotlight from "../../homepage/album-spotlight.vue";

const photo = (n) => ({
  id: `photo-${n}`,
  title: `Photo ${n}`,
  intelligentOrSquareMediumImageUrl: `p${n}.jpg`,
});

const album = {
  id: "lake-trip",
  title: "Lake trip",
  descriptionHtml: "<p>A week by the lake</p>",
  photosCount: 42,
  photos: { collection: [1, 2, 3, 4, 5, 6, 7].map(photo) },
};

const mountSpotlight = (props) =>
  mount(AlbumSpotlight, {
    props,
    global: { stubs: { RouterLink: RouterLinkStub } },
  });

describe("AlbumSpotlight", () => {
  it("shows the album title, description and a link to the album", () => {
    const wrapper = mountSpotlight({ album });

    expect(wrapper.find("h2").text()).toBe("Album Spotlight");
    expect(wrapper.find("h3").text()).toBe("Lake trip");
    expect(wrapper.text()).toContain("A week by the lake");
    expect(wrapper.text()).toContain("View album...");
    expect(wrapper.findAllComponents(RouterLinkStub)[0].props("to")).toEqual({
      name: "albums-show",
      params: { id: "lake-trip" },
    });
  });

  it("shows only the first five photos, linked within the album", () => {
    const wrapper = mountSpotlight({ album });

    expect(wrapper.findAll("img")).toHaveLength(5);
    expect(wrapper.findAllComponents(RouterLinkStub)[1].props("to")).toEqual({
      name: "photos-show",
      params: { id: "photo-1" },
      query: { inAlbum: "lake-trip" },
    });
  });

  it("shows skeleton tiles while loading", () => {
    const wrapper = mountSpotlight({ album: null, loading: true });

    expect(wrapper.findAll(".home-skeleton")).toHaveLength(5);
  });

  it("renders nothing once loaded without an album", () => {
    expect(mountSpotlight({ album: null }).find("section").exists()).toBe(false);
  });
});
