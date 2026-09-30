import { ref } from "vue";
import { mount } from "@vue/test-utils";
import { useQuery } from "@vue/apollo-composable";

vi.mock("@vue/apollo-composable", () => ({
  useQuery: vi.fn(),
}));

import AutocompleteInput from "@/shared/autocomplete-input.vue";

function mountInput(props = {}) {
  return mount(AutocompleteInput, { props: { source: "tags", ...props } });
}

beforeEach(() => {
  vi.useFakeTimers();
});

afterEach(() => {
  vi.useRealTimers();
});

describe("shared/autocomplete-input.vue", () => {
  it("does not query below the minimum character count", async () => {
    const refetch = vi.fn();
    useQuery.mockReturnValue({ result: ref(null), refetch });

    const wrapper = mountInput();
    await wrapper.find("input").setValue("ab");
    await vi.advanceTimersByTimeAsync(350);

    expect(refetch).not.toHaveBeenCalled();
  });

  it("queries and shows suggestions once the minimum is reached", async () => {
    const resultRef = ref(null);
    useQuery.mockReturnValue({ result: resultRef, refetch: vi.fn() });

    const wrapper = mountInput();
    await wrapper.find("input").setValue("sun");
    await vi.advanceTimersByTimeAsync(350);

    resultRef.value = { tags: [{ id: "1", name: "sunset" }] };
    await wrapper.vm.$nextTick();

    expect(wrapper.text()).toContain("sunset");
  });

  it("excludes already-selected names from the suggestions", async () => {
    const resultRef = ref(null);
    useQuery.mockReturnValue({ result: resultRef, refetch: vi.fn() });

    const wrapper = mountInput({ excludeNames: ["sunset"] });
    await wrapper.find("input").setValue("sun");
    await vi.advanceTimersByTimeAsync(350);

    resultRef.value = { tags: [{ id: "1", name: "sunset" }, { id: "2", name: "sunny" }] };
    await wrapper.vm.$nextTick();

    expect(wrapper.text()).not.toContain("sunset");
    expect(wrapper.text()).toContain("sunny");
  });

  it("emits add and clears the input when a suggestion is selected", async () => {
    const resultRef = ref(null);
    useQuery.mockReturnValue({ result: resultRef, refetch: vi.fn() });

    const wrapper = mountInput();
    await wrapper.find("input").setValue("sun");
    await vi.advanceTimersByTimeAsync(350);

    resultRef.value = { tags: [{ id: "1", name: "sunset" }] };
    await wrapper.vm.$nextTick();

    await wrapper.find(".dropdown-item").trigger("mousedown");

    expect(wrapper.emitted("add")).toEqual([["sunset"]]);
    expect(wrapper.find("input").element.value).toBe("");
  });

  it("emits add for free text typed and submitted without a suggestion highlighted", async () => {
    useQuery.mockReturnValue({ result: ref(null), refetch: vi.fn() });

    const wrapper = mountInput();
    await wrapper.find("input").setValue("brandnewtag");
    await wrapper.find("input").trigger("keydown.enter");

    expect(wrapper.emitted("add")).toEqual([["brandnewtag"]]);
  });

  it("queries labelNames when source is labels", async () => {
    const resultRef = ref(null);
    useQuery.mockReturnValue({ result: resultRef, refetch: vi.fn() });

    const wrapper = mountInput({ source: "labels" });
    await wrapper.find("input").setValue("dog");
    await vi.advanceTimersByTimeAsync(350);

    resultRef.value = { labelNames: [{ name: "Dog", count: 3 }] };
    await wrapper.vm.$nextTick();

    expect(wrapper.text()).toContain("Dog");
    expect(wrapper.text()).toContain("3");
  });
});
