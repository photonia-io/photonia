import { describe, it, expect, beforeEach, vi } from "vitest";
import { shallowMount } from "@vue/test-utils";
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
