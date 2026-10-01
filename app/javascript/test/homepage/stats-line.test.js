import { describe, it, expect } from "vitest";
import { mount, RouterLinkStub } from "@vue/test-utils";

import StatsLine from "../../homepage/stats-line.vue";

const mountLine = (stats) =>
  mount(StatsLine, {
    props: { stats },
    global: { stubs: { RouterLink: RouterLinkStub } },
  });

// The line is a flex row, so read its items rather than whitespace-joined text
const textOf = (stats) =>
  mountLine(stats)
    .findAll("p > *")
    .map((item) => item.text())
    .join(" ");

describe("StatsLine", () => {
  it("summarises photos, albums, year span and views, separated by rhombuses", () => {
    expect(
      textOf({
        photosCount: 14213,
        albumsCount: 312,
        firstYear: 2001,
        lastYear: 2026,
        viewsCount: 1200000,
      }),
    ).toBe("14,213 photos ◆ 312 albums ◆ 2001 - 2026 ◆ 1.2M views");
  });

  it("shows a single year once, and omits views when there are none", () => {
    expect(
      textOf({
        photosCount: 3,
        albumsCount: 1,
        firstYear: 2020,
        lastYear: 2020,
        viewsCount: 0,
      }),
    ).toBe("3 photos ◆ 1 albums ◆ 2020");
  });

  it("links the photo count to the photos page and the album count to albums", () => {
    const links = mountLine({
      photosCount: 3,
      albumsCount: 1,
      firstYear: 2020,
      lastYear: 2020,
      viewsCount: 0,
    }).findAllComponents(RouterLinkStub);

    expect(links.map((link) => link.props("to"))).toEqual([
      { name: "photos-index" },
      { name: "albums-index" },
    ]);
  });

  it("keeps an empty line while the stats are loading", () => {
    const wrapper = mountLine(null);

    expect(wrapper.find("p").exists()).toBe(true);
    expect(wrapper.text()).toBe("");
  });
});
