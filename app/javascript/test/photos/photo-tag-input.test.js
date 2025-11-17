import { describe, it, expect, beforeEach, vi } from "vitest";
import { mount } from "@vue/test-utils";
import { ref, nextTick } from "vue";

// Create refs for Apollo mocks at module level
const suggestionsResultRef = ref(null);
const relatedTagsResultRef = ref(null);
const mockSuggestionsRefetch = vi.fn();
const mockRelatedTagsRefetch = vi.fn();

// Mock the toaster
vi.mock("../../mixins/toaster", () => ({
  default: vi.fn(),
}));

// Mock Apollo composable
vi.mock("@vue/apollo-composable", () => ({
  useQuery: vi.fn((query) => {
    // Check if this is the relatedTags query or suggestions query
    const queryString = query.loc?.source?.body || "";
    if (queryString.includes("relatedTags")) {
      return {
        result: relatedTagsResultRef,
        refetch: mockRelatedTagsRefetch,
      };
    }
    return {
      result: suggestionsResultRef,
      refetch: mockSuggestionsRefetch,
    };
  }),
}));

import PhotoTagInput from "../../photos/photo-tag-input.vue";

describe("PhotoTagInput", () => {
  let wrapper;

  beforeEach(() => {
    // Reset mocks
    vi.clearAllMocks();
    mockSuggestionsRefetch.mockClear();
    mockRelatedTagsRefetch.mockClear();
    suggestionsResultRef.value = null;
    relatedTagsResultRef.value = null;

    wrapper = mount(PhotoTagInput, {
      props: {
        userTags: [
          { id: "1", name: "existing-tag" },
          { id: "2", name: "another-tag" },
        ],
        machineTags: [{ id: "3", name: "machine-tag" }],
      },
    });
  });

  describe("Rendering", () => {
    it("renders the component", () => {
      expect(wrapper.exists()).toBe(true);
    });

    it("renders an input field", () => {
      const input = wrapper.find('input[type="text"]');
      expect(input.exists()).toBe(true);
      expect(input.attributes("placeholder")).toBe("Add a tag...");
    });

    it("renders an add button", () => {
      const button = wrapper.find("button");
      expect(button.exists()).toBe(true);
      expect(button.find(".fa-plus").exists()).toBe(true);
    });

    it("disables add button when input is empty", () => {
      const button = wrapper.find("button");
      expect(button.attributes("disabled")).toBeDefined();
    });

    it("enables add button when input has text", async () => {
      const input = wrapper.find('input[type="text"]');
      await input.setValue("new-tag");

      const button = wrapper.find("button");
      expect(button.attributes("disabled")).toBeUndefined();
    });

    it("does not show dropdown initially", () => {
      const dropdown = wrapper.find(".dropdown");
      expect(dropdown.classes()).not.toContain("is-active");
    });
  });

  describe("Props", () => {
    it("accepts userTags prop", () => {
      expect(wrapper.props("userTags")).toHaveLength(2);
      expect(wrapper.props("userTags")[0].name).toBe("existing-tag");
    });

    it("accepts machineTags prop", () => {
      expect(wrapper.props("machineTags")).toHaveLength(1);
      expect(wrapper.props("machineTags")[0].name).toBe("machine-tag");
    });

    it("accepts isAddingTag prop", () => {
      expect(wrapper.props("isAddingTag")).toBe(false);
    });

    it("uses default empty arrays when props are not provided", () => {
      const wrapperWithoutProps = mount(PhotoTagInput);
      expect(wrapperWithoutProps.props("userTags")).toEqual([]);
      expect(wrapperWithoutProps.props("machineTags")).toEqual([]);
      expect(wrapperWithoutProps.props("isAddingTag")).toBe(false);
    });
  });

  describe("Adding Tags", () => {
    it("emits add-tag event when button is clicked", async () => {
      const input = wrapper.find('input[type="text"]');
      await input.setValue("new-tag");

      const button = wrapper.find("button");
      await button.trigger("click");

      expect(wrapper.emitted("add-tag")).toBeTruthy();
      expect(wrapper.emitted("add-tag")[0]).toEqual(["new-tag"]);
    });

    it("emits add-tag event when Enter is pressed", async () => {
      const input = wrapper.find('input[type="text"]');
      await input.setValue("new-tag");
      await input.trigger("keydown.enter");

      expect(wrapper.emitted("add-tag")).toBeTruthy();
      expect(wrapper.emitted("add-tag")[0]).toEqual(["new-tag"]);
    });

    it("trims whitespace from tag name", async () => {
      const input = wrapper.find('input[type="text"]');
      await input.setValue("  new-tag  ");

      const button = wrapper.find("button");
      await button.trigger("click");

      expect(wrapper.emitted("add-tag")[0]).toEqual(["new-tag"]);
    });

    it("clears input after emitting add-tag", async () => {
      const input = wrapper.find('input[type="text"]');
      await input.setValue("new-tag");

      const button = wrapper.find("button");
      await button.trigger("click");

      await nextTick();
      expect(input.element.value).toBe("");
    });

    it("does not emit when input is empty", async () => {
      const button = wrapper.find("button");
      await button.trigger("click");

      expect(wrapper.emitted("add-tag")).toBeFalsy();
    });

    it("does not emit when input contains only whitespace", async () => {
      const input = wrapper.find('input[type="text"]');
      await input.setValue("   ");

      const button = wrapper.find("button");
      await button.trigger("click");

      expect(wrapper.emitted("add-tag")).toBeFalsy();
    });
  });

  describe("Loading State", () => {
    it("disables button when isAddingTag is true", async () => {
      await wrapper.setProps({ isAddingTag: true });

      const button = wrapper.find("button");
      expect(button.attributes("disabled")).toBeDefined();
    });

    it("disables input when isAddingTag is true", async () => {
      await wrapper.setProps({ isAddingTag: true });

      const input = wrapper.find('input[type="text"]');
      expect(input.attributes("disabled")).toBeDefined();
    });

    it("shows spinner icon when isAddingTag is true", async () => {
      await wrapper.setProps({ isAddingTag: true });

      const spinner = wrapper.find(".fa-spinner");
      const plusIcon = wrapper.find(".fa-plus");

      expect(spinner.exists()).toBe(true);
      expect(plusIcon.exists()).toBe(false);
    });

    it("shows plus icon when isAddingTag is false", () => {
      const spinner = wrapper.find(".fa-spinner");
      const plusIcon = wrapper.find(".fa-plus");

      expect(spinner.exists()).toBe(false);
      expect(plusIcon.exists()).toBe(true);
    });

    it("does not emit add-tag when isAddingTag is true", async () => {
      const input = wrapper.find('input[type="text"]');
      await input.setValue("new-tag");
      await wrapper.setProps({ isAddingTag: true });

      const button = wrapper.find("button");
      await button.trigger("click");

      expect(wrapper.emitted("add-tag")).toBeFalsy();
    });

    it("does not emit add-tag on Enter when isAddingTag is true", async () => {
      const input = wrapper.find('input[type="text"]');
      await input.setValue("new-tag");
      await wrapper.setProps({ isAddingTag: true });

      await input.trigger("keydown.enter");

      expect(wrapper.emitted("add-tag")).toBeFalsy();
    });
  });

  describe("Tag Suggestions", () => {
    it("shows dropdown when suggestions are available", async () => {
      const input = wrapper.find('input[type="text"]');
      await input.setValue("test");

      // Simulate suggestions being returned
      wrapper.vm.suggestions = [
        { id: "s1", name: "test-suggestion-1" },
        { id: "s2", name: "test-suggestion-2" },
      ];
      wrapper.vm.isDropdownActive = true;
      await nextTick();

      const dropdown = wrapper.find(".dropdown");
      expect(dropdown.classes()).toContain("is-active");
      expect(wrapper.findAll(".dropdown-item")).toHaveLength(2);
    });

    it("filters out existing user tags from suggestions", async () => {
      // Set up suggestions that include existing tags
      wrapper.vm.suggestions = [];

      const allSuggestions = [
        { id: "s1", name: "existing-tag" },
        { id: "s2", name: "new-suggestion" },
        { id: "s3", name: "machine-tag" },
      ];

      // Manually trigger the filtering logic
      suggestionsResultRef.value = { tags: allSuggestions };
      await nextTick();

      // After watch is triggered, only new-suggestion should be in suggestions
      const filteredSuggestions = wrapper.vm.suggestions;
      expect(filteredSuggestions).toHaveLength(1);
      expect(filteredSuggestions[0].name).toBe("new-suggestion");
    });

    it("selects suggestion on click", async () => {
      const input = wrapper.find('input[type="text"]');
      await input.setValue("test");

      // Set up suggestions
      wrapper.vm.suggestions = [
        { id: "s1", name: "test-suggestion" },
      ];
      wrapper.vm.isDropdownActive = true;
      await nextTick();

      const suggestion = wrapper.find(".dropdown-item");
      await suggestion.trigger("mousedown");

      expect(wrapper.emitted("add-tag")).toBeTruthy();
      expect(wrapper.emitted("add-tag")[0]).toEqual(["test-suggestion"]);
    });

    it("hides dropdown on escape key", async () => {
      const input = wrapper.find('input[type="text"]');
      wrapper.vm.isDropdownActive = true;
      await nextTick();

      await input.trigger("keydown.esc");
      expect(wrapper.vm.isDropdownActive).toBe(false);
    });

    it("hides dropdown on blur", async () => {
      const input = wrapper.find('input[type="text"]');
      wrapper.vm.isDropdownActive = true;
      await nextTick();

      await input.trigger("blur");

      // Wait for the setTimeout delay
      await new Promise((resolve) => setTimeout(resolve, 250));

      expect(wrapper.vm.isDropdownActive).toBe(false);
    });
  });

  describe("Keyboard Navigation", () => {
    beforeEach(async () => {
      // Set up suggestions for navigation tests
      wrapper.vm.suggestions = [
        { id: "s1", name: "suggestion-1" },
        { id: "s2", name: "suggestion-2" },
        { id: "s3", name: "suggestion-3" },
      ];
      wrapper.vm.isDropdownActive = true;
      await nextTick();
    });

    it("starts with no suggestion selected", () => {
      expect(wrapper.vm.selectedIndex).toBe(-1);
    });

    it("selects next suggestion on down arrow", async () => {
      const input = wrapper.find('input[type="text"]');
      await input.trigger("keydown.down");

      expect(wrapper.vm.selectedIndex).toBe(0);
      expect(wrapper.findAll(".dropdown-item")[0].classes()).toContain(
        "is-active",
      );
    });

    it("cycles through suggestions on repeated down arrow", async () => {
      const input = wrapper.find('input[type="text"]');

      await input.trigger("keydown.down");
      expect(wrapper.vm.selectedIndex).toBe(0);

      await input.trigger("keydown.down");
      expect(wrapper.vm.selectedIndex).toBe(1);

      await input.trigger("keydown.down");
      expect(wrapper.vm.selectedIndex).toBe(2);

      // Should wrap around to 0
      await input.trigger("keydown.down");
      expect(wrapper.vm.selectedIndex).toBe(0);
    });

    it("selects previous suggestion on up arrow", async () => {
      const input = wrapper.find('input[type="text"]');
      wrapper.vm.selectedIndex = 2;
      await nextTick();

      await input.trigger("keydown.up");
      expect(wrapper.vm.selectedIndex).toBe(1);
    });

    it("wraps around to last suggestion on up arrow from first", async () => {
      const input = wrapper.find('input[type="text"]');
      wrapper.vm.selectedIndex = 0;
      await nextTick();

      await input.trigger("keydown.up");
      expect(wrapper.vm.selectedIndex).toBe(2);
    });

    it("uses selected suggestion when Enter is pressed", async () => {
      const input = wrapper.find('input[type="text"]');
      await input.setValue("test");

      // Select second suggestion
      wrapper.vm.selectedIndex = 1;
      await nextTick();

      await input.trigger("keydown.enter");

      expect(wrapper.emitted("add-tag")).toBeTruthy();
      expect(wrapper.emitted("add-tag")[0]).toEqual(["suggestion-2"]);
    });

    it("highlights suggestion on mouseover", async () => {
      const suggestions = wrapper.findAll(".dropdown-item");
      await suggestions[1].trigger("mouseover");

      expect(wrapper.vm.selectedIndex).toBe(1);
      expect(suggestions[1].classes()).toContain("is-active");
    });
  });

  describe("Input Debouncing", () => {
    it("does not trigger suggestions for short inputs", async () => {
      const input = wrapper.find('input[type="text"]');
      await input.setValue("ab"); // Less than 3 characters

      await input.trigger("input");

      expect(wrapper.vm.suggestionsQueryEnabled).toBe(false);
    });

    it("triggers suggestions for inputs of 3+ characters", async () => {
      const input = wrapper.find('input[type="text"]');
      await input.setValue("abc"); // 3 characters

      await input.trigger("input");

      // Wait for debounce
      await new Promise((resolve) => setTimeout(resolve, 350));

      expect(wrapper.vm.suggestionsQueryEnabled).toBe(true);
    });
  });

  describe("Component Cleanup", () => {
    it("clears suggestions when adding a tag", async () => {
      wrapper.vm.suggestions = [
        { id: "s1", name: "suggestion-1" },
      ];
      wrapper.vm.isDropdownActive = true;

      const input = wrapper.find('input[type="text"]');
      await input.setValue("new-tag");

      const button = wrapper.find("button");
      await button.trigger("click");

      expect(wrapper.vm.suggestions).toEqual([]);
      expect(wrapper.vm.isDropdownActive).toBe(false);
      expect(wrapper.vm.suggestionsQueryEnabled).toBe(false);
    });
  });

  describe("Edge Cases", () => {
    it("handles empty props gracefully", () => {
      const wrapperEmpty = mount(PhotoTagInput, {
        props: {
          userTags: [],
          machineTags: [],
        },
      });

      expect(wrapperEmpty.exists()).toBe(true);
      const dropdown = wrapperEmpty.find(".dropdown");
      expect(dropdown.exists()).toBe(true);
    });

    it("handles null tags in props", () => {
      const wrapperNull = mount(PhotoTagInput, {
        props: {
          userTags: null,
          machineTags: null,
        },
      });

      // Component should still work with default empty arrays
      expect(wrapperNull.exists()).toBe(true);
    });

    it("handles very long tag names", async () => {
      const longTagName = "a".repeat(200);
      const input = wrapper.find('input[type="text"]');
      await input.setValue(longTagName);

      const button = wrapper.find("button");
      await button.trigger("click");

      expect(wrapper.emitted("add-tag")).toBeTruthy();
      expect(wrapper.emitted("add-tag")[0]).toEqual([longTagName]);
    });

    it("handles special characters in tag names", async () => {
      const specialTag = "tag-with-$pec!al_ch@rs";
      const input = wrapper.find('input[type="text"]');
      await input.setValue(specialTag);

      const button = wrapper.find("button");
      await button.trigger("click");

      expect(wrapper.emitted("add-tag")).toBeTruthy();
      expect(wrapper.emitted("add-tag")[0]).toEqual([specialTag]);
    });
  });

  describe("Related Tags (Suggested Tags)", () => {
    it("does not show suggested tags initially when there are no related tags", () => {
      expect(wrapper.text()).not.toContain("Suggested tags:");
    });

    it("shows suggested tags when relatedTags are available", async () => {
      // Simulate related tags being returned
      relatedTagsResultRef.value = {
        relatedTags: [
          { id: "r1", name: "related-tag-1" },
          { id: "r2", name: "related-tag-2" },
        ],
      };
      await nextTick();

      expect(wrapper.text()).toContain("Suggested tags:");
      expect(wrapper.text()).toContain("related-tag-1");
      expect(wrapper.text()).toContain("related-tag-2");
    });

    it("filters out existing user tags from related tags suggestions", async () => {
      // Set up related tags that include existing tags
      relatedTagsResultRef.value = {
        relatedTags: [
          { id: "r1", name: "existing-tag" },
          { id: "r2", name: "new-related-tag" },
          { id: "r3", name: "machine-tag" },
        ],
      };
      await nextTick();

      // Only new-related-tag should be shown
      expect(wrapper.text()).toContain("new-related-tag");
      expect(wrapper.text()).not.toContain("existing-tag");
      expect(wrapper.text()).not.toContain("machine-tag");
    });

    it("emits add-tag event when a suggested tag is clicked", async () => {
      // Set up related tags
      relatedTagsResultRef.value = {
        relatedTags: [
          { id: "r1", name: "suggested-tag" },
        ],
      };
      await nextTick();

      // Find and click the suggested tag
      const suggestedTags = wrapper.findAll(".tag.is-link");
      expect(suggestedTags.length).toBeGreaterThan(0);
      await suggestedTags[0].trigger("click");

      expect(wrapper.emitted("add-tag")).toBeTruthy();
      expect(wrapper.emitted("add-tag")[0]).toEqual(["suggested-tag"]);
    });

    it("does not emit add-tag when clicking suggested tag while isAddingTag is true", async () => {
      // Set up related tags
      relatedTagsResultRef.value = {
        relatedTags: [
          { id: "r1", name: "suggested-tag" },
        ],
      };
      await wrapper.setProps({ isAddingTag: true });
      await nextTick();

      // Find and click the suggested tag
      const suggestedTags = wrapper.findAll(".tag.is-link");
      expect(suggestedTags.length).toBeGreaterThan(0);
      await suggestedTags[0].trigger("click");

      expect(wrapper.emitted("add-tag")).toBeFalsy();
    });

    it("does not show suggested tags when userTags is empty", async () => {
      const wrapperEmpty = mount(PhotoTagInput, {
        props: {
          userTags: [],
          machineTags: [],
        },
      });

      // Even if we set related tags, they shouldn't show when there are no user tags
      relatedTagsResultRef.value = {
        relatedTags: [
          { id: "r1", name: "related-tag" },
        ],
      };
      await nextTick();

      expect(wrapperEmpty.text()).not.toContain("Suggested tags:");
    });

    it("hides suggested tags when userTags becomes empty", async () => {
      // Start with some user tags and related tags
      relatedTagsResultRef.value = {
        relatedTags: [
          { id: "r1", name: "related-tag" },
        ],
      };
      await nextTick();

      expect(wrapper.text()).toContain("Suggested tags:");

      // Remove user tags
      await wrapper.setProps({ userTags: [] });
      await nextTick();

      expect(wrapper.vm.relatedTagsSuggestions).toEqual([]);
    });
  });
});
