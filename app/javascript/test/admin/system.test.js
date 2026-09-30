import { describe, it, expect, beforeEach, afterEach, vi } from "vitest";
import { mount } from "@vue/test-utils";
import { createPinia, setActivePinia } from "pinia";
import { ref } from "vue";

vi.mock("../../mixins/toaster", () => ({ default: vi.fn() }));
vi.mock("vue-page-title", () => ({ useTitle: vi.fn() }));

const adminSettingsResult = ref({
  adminSettings: { id: "admin-settings", rekognitionEnabled: true },
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

import AdminSystem from "../../admin/system.vue";
import { useApplicationStore } from "../../stores/application";

let wrapper;

function mountSystem() {
  const pinia = createPinia();
  setActivePinia(pinia);
  wrapper = mount(AdminSystem, { global: { plugins: [pinia] } });
  return wrapper;
}

beforeEach(() => {
  adminSettingsResult.value = { adminSettings: { id: "admin-settings", rekognitionEnabled: true } };
});

afterEach(() => {
  wrapper?.unmount();
});

describe("Admin System settings", () => {
  it("warns on navigation once the toggle changes, and stops once reverted", async () => {
    mountSystem();
    const applicationStore = useApplicationStore();
    const checkbox = wrapper.find('input[type="checkbox"]');

    await checkbox.setValue(false);
    expect(applicationStore.editing).toBe(true);

    await checkbox.setValue(true);
    expect(applicationStore.editing).toBe(false);
  });

  it("stops warning once saved", async () => {
    mountSystem();
    const applicationStore = useApplicationStore();
    await wrapper.find('input[type="checkbox"]').setValue(false);
    expect(applicationStore.editing).toBe(true);

    doneHandler({});
    await wrapper.vm.$nextTick();

    expect(applicationStore.editing).toBe(false);
  });

  it("sends the changed value in the mutation variables", async () => {
    mountSystem();
    await wrapper.find('input[type="checkbox"]').setValue(false);

    expect(capturedOptionsFn().variables).toEqual({ rekognitionEnabled: false });
  });
});
