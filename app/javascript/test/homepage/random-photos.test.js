import { describe, it, expect, vi, beforeEach } from "vitest";
import { mount, RouterLinkStub } from "@vue/test-utils";

const { refetch, result, loading } = vi.hoisted(() => ({
  refetch: vi.fn(),
  result: { value: null },
  loading: { value: false },
}));

vi.mock("@vue/apollo-composable", () => ({
  useQuery: () => ({ result, loading, refetch }),
}));

import RandomPhotos from "../../homepage/random-photos.vue";

const mountRandomPhotos = () =>
  mount(RandomPhotos, {
    global: { stubs: { RouterLink: RouterLinkStub } },
  });

describe("RandomPhotos", () => {
  beforeEach(() => {
    globalThis.gql_queries = { homepage_random_photos: "query { __typename }" };
    refetch.mockReset();
    loading.value = false;
    result.value = {
      randomPhotos: {
        collection: [
          { id: "a", title: "One", intelligentOrSquareMediumImageUrl: "a.jpg" },
          { id: "b", title: "Two", intelligentOrSquareMediumImageUrl: "b.jpg" },
        ],
      },
    };
  });

  it("renders a tile per photo", () => {
    const wrapper = mountRandomPhotos();

    expect(wrapper.findAll("img")).toHaveLength(2);
  });

  it("refetches only this query when shuffled", async () => {
    const wrapper = mountRandomPhotos();

    await wrapper.find("button").trigger("click");

    expect(refetch).toHaveBeenCalledTimes(1);
  });

  it("renders nothing once loaded with no photos", () => {
    result.value = null;

    expect(mountRandomPhotos().find("section").exists()).toBe(false);
  });

  it("keeps the row as skeletons while the first load is in flight", () => {
    result.value = null;
    loading.value = true;

    const wrapper = mountRandomPhotos();

    expect(wrapper.findAll(".home-skeleton")).toHaveLength(5);
  });

  it("swaps the tiles for skeletons while shuffling, then restores them", async () => {
    let finish;
    refetch.mockReturnValue(new Promise((resolve) => (finish = resolve)));
    const wrapper = mountRandomPhotos();

    await wrapper.find("button").trigger("click");

    expect(wrapper.findAll(".home-skeleton")).toHaveLength(5);
    expect(wrapper.find("button").attributes("disabled")).toBeDefined();

    finish();
    await new Promise((resolve) => setTimeout(resolve));

    expect(wrapper.findAll(".home-skeleton")).toHaveLength(0);
    expect(wrapper.findAll("img")).toHaveLength(2);
  });
});
