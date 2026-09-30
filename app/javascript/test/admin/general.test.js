import { describe, it, expect, beforeEach, afterEach, vi } from "vitest";
import { mount } from "@vue/test-utils";
import { createPinia, setActivePinia } from "pinia";
import { ref } from "vue";

vi.mock("../../mixins/toaster", () => ({ default: vi.fn() }));
vi.mock("vue-page-title", () => ({ useTitle: vi.fn() }));

const adminSettingsResult = ref({
  adminSettings: {
    id: "admin-settings",
    siteName: "Photonia",
    siteDescription: "A gallery",
    siteTrackingCode: "",
    continueWithGoogleEnabled: false,
    continueWithFacebookEnabled: false,
  },
});

let doneHandler;
let capturedOptionsFn;

vi.mock("@vue/apollo-composable", () => ({
  useQuery: () => ({ result: adminSettingsResult }),
  useMutation: (_document, optionsFn) => {
    capturedOptionsFn = optionsFn;
    return { mutate: vi.fn(), onDone: (cb) => (doneHandler = cb), onError: () => {} };
  },
}));

import AdminGeneral from "../../admin/general.vue";
import { useApplicationStore } from "../../stores/application";

let wrapper;

function mountGeneral() {
  const pinia = createPinia();
  setActivePinia(pinia);
  wrapper = mount(AdminGeneral, { global: { plugins: [pinia] } });
  return wrapper;
}

beforeEach(() => {
  adminSettingsResult.value = {
    adminSettings: {
      id: "admin-settings",
      siteName: "Photonia",
      siteDescription: "A gallery",
      siteTrackingCode: "",
      continueWithGoogleEnabled: false,
      continueWithFacebookEnabled: false,
    },
  };
});

afterEach(() => {
  wrapper?.unmount();
});

describe("Admin General settings", () => {
  it("warns on navigation once a field changes, and stops once reverted", async () => {
    mountGeneral();
    const applicationStore = useApplicationStore();
    const siteNameInput = wrapper.find('input[type="text"]');

    await siteNameInput.setValue("New Name");
    expect(applicationStore.editing).toBe(true);

    await siteNameInput.setValue("Photonia");
    expect(applicationStore.editing).toBe(false);
  });

  it("stops warning once saved", async () => {
    mountGeneral();
    const applicationStore = useApplicationStore();
    await wrapper.find('input[type="text"]').setValue("New Name");
    expect(applicationStore.editing).toBe(true);

    doneHandler({});
    await wrapper.vm.$nextTick();

    expect(applicationStore.editing).toBe(false);
  });

  it("carries the changed field and the other saved values into the mutation variables", async () => {
    mountGeneral();
    await wrapper.find('input[type="text"]').setValue("New Name");

    expect(capturedOptionsFn().variables).toEqual({
      siteName: "New Name",
      siteDescription: "A gallery",
      siteTrackingCode: "",
      continueWithGoogleEnabled: false,
      continueWithFacebookEnabled: false,
    });
  });
});
