import { describe, it, expect, beforeEach, vi } from "vitest";
import { mount, RouterLinkStub } from "@vue/test-utils";
import { createPinia, setActivePinia } from "pinia";
import { ref } from "vue";

vi.mock("vue-page-title", () => ({ useTitle: vi.fn() }));
vi.mock("vue-chartjs", () => ({
  Line: { props: ["data", "options"], render: () => null },
}));

const useQuery = vi.fn();
vi.mock("@vue/apollo-composable", () => ({ useQuery: (...args) => useQuery(...args) }));

import { Line } from "vue-chartjs";
import Stats from "../../stats/index.vue";
import { useApplicationStore } from "@/stores/application";

const counts = [
  { date: "2026-10-01", count: 3 },
  { date: "2026-10-02", count: 5 },
];

const mostViewedOnDate = {
  photos: [
    { count: 2, photo: { id: "p1", title: "A photo", intelligentOrSquareMediumImageUrl: "p.jpg" } },
  ],
  albums: [
    { count: 1, album: { id: "a1", title: "An album", coverPhoto: null } },
  ],
};

const mountStats = (mostViewed = undefined) => {
  useQuery.mockReset();
  useQuery
    .mockReturnValueOnce({
      result: ref({
        photoImpressionCountsByDate: counts,
        albumImpressionCountsByDate: counts,
      }),
    })
    .mockReturnValueOnce({ result: ref(mostViewed ? { mostViewedOnDate: mostViewed } : null) });
  return mount(Stats, { global: { stubs: { RouterLink: RouterLinkStub } } });
};

const chart = (wrapper) => wrapper.findComponent(Line);

beforeEach(() => {
  setActivePinia(createPinia());
});

describe("Stats", () => {
  it("charts photo and album views only", () => {
    const wrapper = mountStats();

    expect(chart(wrapper).props("data").datasets.map((d) => d.label)).toEqual([
      "Photo Views",
      "Album Views",
    ]);
  });

  it("draws readable lines and text in dark mode", () => {
    const wrapper = mountStats();
    const store = useApplicationStore();

    store.setUserColorScheme("light");
    const light = chart(wrapper).props("options");
    store.setUserColorScheme("dark");
    const dark = mountStats();
    const darkOptions = chart(dark).props("options");

    expect(darkOptions.color).not.toBe(light.color);
    expect(darkOptions.scales.x.ticks.color).toBe("#e0e0e0");
    expect(chart(dark).props("data").datasets.every((d) => d.borderColor)).toBe(true);
  });

  it("shows a hint until a date is clicked, then the most viewed lists", async () => {
    const wrapper = mountStats(mostViewedOnDate);
    expect(wrapper.text()).toContain("Click a date on the chart");

    const options = chart(wrapper).props("options");
    options.onClick({}, [{ index: 1 }], { data: { labels: ["2026-10-01", "2026-10-02"] } });
    await wrapper.vm.$nextTick();

    expect(wrapper.text()).toContain("Most viewed on Friday, October 2, 2026");
    expect(wrapper.text()).toContain("A photo");
    expect(wrapper.text()).toContain("2 views");
    expect(wrapper.text()).toContain("An album");
    expect(wrapper.text()).toContain("1 view");
  });
  it("only queries the most viewed lists once a date is picked", async () => {
    const wrapper = mountStats(mostViewedOnDate);
    const [, variables, options] = useQuery.mock.calls[1];

    expect(options().enabled).toBe(false);

    chart(wrapper).props("options").onClick({}, [{ index: 0 }], {
      data: { labels: ["2026-10-01", "2026-10-02"] },
    });
    await wrapper.vm.$nextTick();

    expect(variables()).toEqual({ date: "2026-10-01" });
    expect(options().enabled).toBe(true);
  });

  it("shows a pointer cursor while hovering a date", () => {
    const wrapper = mountStats();
    const { onHover } = chart(wrapper).props("options");
    const target = { style: {} };

    onHover({ native: { target } }, [{ index: 0 }]);
    expect(target.style.cursor).toBe("pointer");

    onHover({ native: { target } }, []);
    expect(target.style.cursor).toBe("default");

    expect(() => onHover({}, [])).not.toThrow();
  });
});
