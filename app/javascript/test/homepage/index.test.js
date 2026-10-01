import { describe, it, expect, beforeEach, vi } from "vitest";
import { mount, shallowMount, RouterLinkStub } from "@vue/test-utils";
import { ref } from "vue";

vi.mock("vue-page-title", () => ({ useTitle: vi.fn() }));

const useQuery = vi.fn();
vi.mock("@vue/apollo-composable", () => ({ useQuery: (...args) => useQuery(...args) }));

import Homepage from "../../homepage/index.vue";
import StatsLine from "../../homepage/stats-line.vue";
import RandomPhotos from "../../homepage/random-photos.vue";
import AlbumSpotlight from "../../homepage/album-spotlight.vue";
import YearLinks from "../../homepage/year-links.vue";

const mountHomepage = (result = {}) => {
  useQuery.mockReturnValue({ result: ref(result), loading: ref(false) });
  return shallowMount(Homepage);
};

const variablesSent = () => useQuery.mock.calls.at(-1)[1];

beforeEach(() => {
  useQuery.mockReset();
  globalThis.gql_queries = { homepage_index: "query { __typename }" };
  window.settings = { homepage: {} };
});

describe("Homepage", () => {
  it("shows and queries every section when nothing is switched off", () => {
    const wrapper = mountHomepage({ homepageStats: { years: [{ year: 2020, count: 1 }] } });

    expect(wrapper.findComponent(StatsLine).exists()).toBe(true);
    expect(wrapper.findComponent(RandomPhotos).exists()).toBe(true);
    expect(wrapper.findComponent(AlbumSpotlight).exists()).toBe(true);
    expect(wrapper.findComponent(YearLinks).exists()).toBe(true);
    expect(Object.values(variablesSent()).every(Boolean)).toBe(true);
  });

  it("hides and does not query the sections the admin switched off", () => {
    window.settings = {
      homepage: { random: false, album_spotlight: false, on_this_day: false, tags: false, stats: false },
    };

    const wrapper = mountHomepage({ homepageStats: { years: [{ year: 2020, count: 1 }] } });

    expect(wrapper.findComponent(RandomPhotos).exists()).toBe(false);
    expect(wrapper.findComponent(AlbumSpotlight).exists()).toBe(false);
    expect(wrapper.findComponent(StatsLine).exists()).toBe(false);
    expect(variablesSent()).toMatchObject({
      spotlight: false,
      onThisDay: false,
      tags: false,
      latestAlbums: true,
    });
  });

  it("still fetches the stats for the year links when only the stats line is off", () => {
    window.settings = { homepage: { stats: false } };

    const wrapper = mountHomepage({ homepageStats: { years: [{ year: 2020, count: 1 }] } });

    expect(variablesSent().stats).toBe(true);
    expect(wrapper.findComponent(StatsLine).exists()).toBe(false);
    expect(wrapper.findComponent(YearLinks).exists()).toBe(true);
  });

  it("drops the year links and the stats query when both are off", () => {
    window.settings = { homepage: { stats: false, years: false } };

    const wrapper = mountHomepage();

    expect(variablesSent().stats).toBe(false);
    expect(wrapper.findComponent(YearLinks).exists()).toBe(false);
  });
});

describe("Homepage sections", () => {
  const tile = (n, extra = {}) => ({
    id: `photo-${n}`,
    title: `Photo ${n}`,
    intelligentOrSquareMediumImageUrl: `p${n}.jpg`,
    ...extra,
  });
  const collection = (items) => ({ collection: items });
  const thisYear = new Date().getFullYear();

  const fullMount = (result) => {
    useQuery.mockReturnValue({ result: ref(result), loading: ref(false) });
    return mount(Homepage, {
      global: { stubs: { RouterLink: RouterLinkStub, DisplayHero: true, RandomPhotos: true } },
    });
  };

  const rowText = (wrapper, title) =>
    wrapper
      .findAll("section.home-section")
      .find((section) => section.find("h2").text().startsWith(title));

  const routesIn = (row) => row.findAllComponents(RouterLinkStub).map((link) => link.props("to"));

  it("links a collapsed album's cover in the latest row to the album, with its title", () => {
    const wrapper = fullMount({
      latestPhotos: collection([
        tile(1, { feedAlbum: { id: "an-album", title: "An album", photosCount: 9 } }),
        tile(2),
      ]),
    });
    const row = rowText(wrapper, "More of the latest");

    expect(routesIn(row)).toContainEqual({ name: "albums-show", params: { id: "an-album" } });
    expect(routesIn(row)).toContainEqual({ name: "photos-show", params: { id: "photo-2" } });
    expect(row.text()).toContain("An album");
  });

  it("lists the latest albums with their cover", () => {
    const wrapper = fullMount({
      latestAlbums: collection([
        {
          id: "lake-trip",
          title: "Lake trip",
          photosCount: 3,
          coverPhoto: { intelligentOrSquareMediumImageUrl: "c.jpg" },
        },
      ]),
    });

    expect(rowText(wrapper, "Latest albums").find("img").attributes("src")).toBe("c.jpg");
  });

  it("captions on-this-day photos with how many years ago they were taken", () => {
    const wrapper = fullMount({
      onThisDay: collection([
        tile(1, { takenAt: `${thisYear - 1}-10-15T09:00:00` }),
        tile(2, { takenAt: `${thisYear - 7}-10-15T09:00:00` }),
        tile(3, { takenAt: null }),
      ]),
    });
    const text = rowText(wrapper, "On this day").text();

    expect(text).toContain("1 year ago");
    expect(text).toContain("7 years ago");
  });

  it("captions this month's photos with the year they were taken", () => {
    const wrapper = fullMount({
      thisMonth: collection([tile(1, { takenAt: "2019-10-03T09:00:00" })]),
    });

    expect(rowText(wrapper, "More from").text()).toContain("2019");
  });

  it("shows trending when there are enough trending photos", () => {
    const wrapper = fullMount({
      trending: collection([tile(1), tile(2), tile(3)]),
      mostViewed: collection([tile(9, { impressionsCount: 500 })]),
    });

    expect(rowText(wrapper, "Trending this week")).toBeTruthy();
    expect(rowText(wrapper, "Most viewed")).toBeUndefined();
  });

  it("falls back to most viewed, with view counts, when little is trending", () => {
    const wrapper = fullMount({
      trending: collection([tile(1)]),
      mostViewed: collection([tile(9, { impressionsCount: 12345 })]),
    });

    expect(rowText(wrapper, "Trending this week")).toBeUndefined();
    expect(rowText(wrapper, "Most viewed").text()).toContain("12,345 views");
  });

  it("shows hidden gems", () => {
    const wrapper = fullMount({ hiddenGems: collection([tile(1)]) });

    expect(rowText(wrapper, "Hidden gems").text()).toContain("Photo 1");
  });

  it("shows recently commented photos and albums with their comment counts", () => {
    const wrapper = fullMount({
      recentlyCommented: [
        { id: "1", commentsCount: 1, photo: tile(1), album: null },
        {
          id: "2",
          commentsCount: 4,
          photo: null,
          album: {
            id: "an-album",
            title: "An album",
            coverPhoto: { intelligentOrSquareMediumImageUrl: "c.jpg" },
          },
        },
      ],
    });
    const row = rowText(wrapper, "Recently commented");

    expect(row.text()).toContain("1 comment");
    expect(row.text()).toContain("4 comments");
    expect(routesIn(row)).toContainEqual({ name: "albums-show", params: { id: "an-album" } });
    expect(row.findAll("img").map((img) => img.attributes("src"))).toEqual(["p1.jpg", "c.jpg"]);
  });

  it("shows the latest comments and the year links", () => {
    const wrapper = fullMount({
      recentComments: [
        {
          id: "1",
          snippet: "Lovely",
          authorName: "Ana",
          createdAt: new Date().toISOString(),
          photo: tile(1),
          album: null,
        },
      ],
      homepageStats: { years: [{ year: 2020, count: 2 }] },
    });

    expect(rowText(wrapper, "Latest comments").text()).toContain("Lovely");
    expect(rowText(wrapper, "Browse by year").text()).toContain("2020");
  });

  it("shows the album spotlight and the tags", () => {
    const wrapper = fullMount({
      albumSpotlight: { id: "lake", title: "Lake", descriptionHtml: null, photosCount: 1, photos: collection([tile(1)]) },
      mostUsedTags: [{ id: "tree", name: "tree", taggingsCount: 3 }],
    });

    expect(rowText(wrapper, "Album Spotlight").text()).toContain("Lake");
    expect(rowText(wrapper, "Most used tags").text()).toContain("tree");
  });
});
