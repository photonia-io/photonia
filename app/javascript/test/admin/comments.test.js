import { describe, it, expect, beforeEach, afterEach, vi } from "vitest";
import { mount } from "@vue/test-utils";
import { createPinia, setActivePinia } from "pinia";
import { ref } from "vue";

vi.mock("../../mixins/toaster", () => ({ default: vi.fn() }));
vi.mock("vue-page-title", () => ({ useTitle: vi.fn() }));

const adminSettingsResult = ref({
  adminSettings: {
    id: "admin-settings",
    commentingEnabled: true,
    photoCommentingEnabled: true,
    albumCommentingEnabled: false,
  },
});

const mutate = vi.fn();
let doneHandler;
let capturedOptionsFn;

vi.mock("@vue/apollo-composable", () => ({
  useQuery: () => ({ result: adminSettingsResult }),
  // The component calls mutate() from a bare @submit.prevent="submit", so
  // Vue passes it the native SubmitEvent - exactly like the rest of this
  // app's admin/settings forms. The real variables come from the reactive
  // options function (2nd arg), which is what's worth asserting against.
  useMutation: (_document, optionsFn) => {
    capturedOptionsFn = optionsFn;
    return {
      mutate,
      onDone: (cb) => (doneHandler = cb),
      onError: () => {},
    };
  },
}));

import AdminComments from "../../admin/comments.vue";
import { useApplicationStore } from "../../stores/application";

let wrapper;

function mountComments() {
  const pinia = createPinia();
  setActivePinia(pinia);
  wrapper = mount(AdminComments, { global: { plugins: [pinia] } });
  return wrapper;
}

beforeEach(() => {
  mutate.mockClear();
  adminSettingsResult.value = {
    adminSettings: {
      id: "admin-settings",
      commentingEnabled: true,
      photoCommentingEnabled: true,
      albumCommentingEnabled: false,
    },
  };
});

afterEach(() => {
  wrapper?.unmount();
});

describe("Admin Comments settings", () => {
  it("shows the three toggles with their current values", () => {
    mountComments();
    const checkboxes = wrapper.findAll('input[type="checkbox"]');

    expect(checkboxes).toHaveLength(3);
    expect(checkboxes[0].element.checked).toBe(true); // commenting
    expect(checkboxes[1].element.checked).toBe(true); // photo
    expect(checkboxes[2].element.checked).toBe(false); // album
  });

  it("warns on navigation once a toggle is changed (marks the app as editing)", async () => {
    mountComments();
    const applicationStore = useApplicationStore();
    expect(applicationStore.editing).toBe(false);

    await wrapper.findAll('input[type="checkbox"]')[2].setValue(true);

    expect(applicationStore.editing).toBe(true);
  });

  it("stops warning once the change is reverted back to the saved value", async () => {
    mountComments();
    const applicationStore = useApplicationStore();
    const albumCheckbox = wrapper.findAll('input[type="checkbox"]')[2];

    await albumCheckbox.setValue(true);
    expect(applicationStore.editing).toBe(true);

    await albumCheckbox.setValue(false);
    expect(applicationStore.editing).toBe(false);
  });

  it("stops warning once the settings are saved", async () => {
    mountComments();
    const applicationStore = useApplicationStore();

    await wrapper.findAll('input[type="checkbox"]')[2].setValue(true);
    expect(applicationStore.editing).toBe(true);

    doneHandler({});
    await wrapper.vm.$nextTick();

    expect(applicationStore.editing).toBe(false);
  });

  it("carries the changed field's new value and the others' saved values into the mutation variables", async () => {
    mountComments();
    await wrapper.findAll('input[type="checkbox"]')[2].setValue(true);

    expect(capturedOptionsFn().variables).toEqual({
      commentingEnabled: true,
      photoCommentingEnabled: true,
      albumCommentingEnabled: true,
    });
  });

  it("stops warning on unmount", async () => {
    mountComments();
    const applicationStore = useApplicationStore();
    await wrapper.findAll('input[type="checkbox"]')[2].setValue(true);
    expect(applicationStore.editing).toBe(true);

    wrapper.unmount();

    expect(applicationStore.editing).toBe(false);
  });
});
