import { describe, it, expect, beforeEach, afterEach, vi } from "vitest";
import { mount } from "@vue/test-utils";
import { createPinia, setActivePinia } from "pinia";
import { ref } from "vue";

vi.mock("../../mixins/toaster", () => ({ default: vi.fn() }));
vi.mock("vue-page-title", () => ({ useTitle: vi.fn() }));

const SECTION_FIELDS = [
  "homepageStatsEnabled",
  "homepageLatestAlbumsEnabled",
  "homepageAlbumSpotlightEnabled",
  "homepageRandomEnabled",
  "homepageOnThisDayEnabled",
  "homepageThisMonthEnabled",
  "homepagePopularEnabled",
  "homepageHiddenGemsEnabled",
  "homepageRecentlyCommentedEnabled",
  "homepageRecentCommentsEnabled",
  "homepageYearsEnabled",
  "homepageTagsEnabled",
];

const savedSettings = () => ({
  adminSettings: {
    id: "admin-settings",
    ...Object.fromEntries(SECTION_FIELDS.map((field) => [field, true])),
    homepageSpotlightAlbumId: "",
    spotlightAlbumChoices: [
      { id: "lake-trip", title: "Lake trip" },
      { id: "city-break", title: "City break" },
    ],
  },
});

const adminSettingsResult = ref(savedSettings());
const mutate = vi.fn();

vi.mock("@vue/apollo-composable", () => ({
  useQuery: () => ({ result: adminSettingsResult }),
  useMutation: () => ({ mutate, onDone: () => {}, onError: () => {} }),
}));

import AdminHomepage from "../../admin/homepage.vue";
import { useApplicationStore } from "../../stores/application";

let wrapper;

const mountHomepage = () => {
  const pinia = createPinia();
  setActivePinia(pinia);
  wrapper = mount(AdminHomepage, { global: { plugins: [pinia] } });
  return wrapper;
};

beforeEach(() => {
  mutate.mockClear();
  adminSettingsResult.value = savedSettings();
});

afterEach(() => {
  wrapper?.unmount();
});

describe("Admin Homepage settings", () => {
  it("shows one toggle per optional section, with their saved values", () => {
    adminSettingsResult.value.adminSettings.homepageRandomEnabled = false;
    mountHomepage();
    const checkboxes = wrapper.findAll('input[type="checkbox"]');

    expect(checkboxes).toHaveLength(SECTION_FIELDS.length);
    expect(checkboxes[3].element.checked).toBe(false); // random
    expect(checkboxes[0].element.checked).toBe(true);
  });

  it("offers the latest album as the default spotlight, then the choices", () => {
    mountHomepage();
    const options = wrapper.findAll("select option").map((option) => option.text());

    expect(options).toEqual(["Latest album (default)", "Lake trip", "City break"]);
  });

  it("disables the album picker while the spotlight is off", async () => {
    mountHomepage();
    const select = wrapper.find("select");
    expect(select.element.disabled).toBe(false);

    await wrapper.findAll('input[type="checkbox"]')[2].setValue(false);

    expect(select.element.disabled).toBe(true);
  });

  it("marks the app as editing only while there are unsaved changes", async () => {
    mountHomepage();
    const applicationStore = useApplicationStore();
    const checkbox = wrapper.findAll('input[type="checkbox"]')[0];

    await checkbox.setValue(false);
    expect(applicationStore.editing).toBe(true);

    await checkbox.setValue(true);
    expect(applicationStore.editing).toBe(false);
  });

  it("flags a saved pick that is no longer available", () => {
    adminSettingsResult.value.adminSettings.homepageSpotlightAlbumId = "gone-album";
    mountHomepage();

    expect(wrapper.find("select").text()).toContain("Unavailable album");
  });

  it("saves only the homepage fields, including the picked album", async () => {
    mountHomepage();

    await wrapper.findAll('input[type="checkbox"]')[1].setValue(false);
    await wrapper.find("select").setValue("lake-trip");
    await wrapper.find("form").trigger("submit");

    expect(mutate).toHaveBeenCalledTimes(1);
    const variables = mutate.mock.calls[0][0];
    expect(Object.keys(variables).sort()).toEqual(
      [...SECTION_FIELDS, "homepageSpotlightAlbumId"].sort(),
    );
    expect(variables.homepageLatestAlbumsEnabled).toBe(false);
    expect(variables.homepageSpotlightAlbumId).toBe("lake-trip");
  });
});
