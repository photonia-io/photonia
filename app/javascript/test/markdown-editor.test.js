import { describe, it, expect, beforeEach, vi } from "vitest";
import { mount } from "@vue/test-utils";
import MarkdownEditor from "../shared/markdown-editor.vue";

describe("MarkdownEditor", () => {
  let wrapper;

  beforeEach(() => {
    wrapper = mount(MarkdownEditor, {
      props: {
        modelValue: "Test content",
        placeholder: "Enter text...",
        startInPreview: false,
      },
    });
  });

  describe("Rendering", () => {
    it("renders the component", () => {
      expect(wrapper.exists()).toBe(true);
    });

    it("renders textarea in editor mode", () => {
      expect(wrapper.find("textarea").exists()).toBe(true);
      expect(wrapper.find(".content").exists()).toBe(false);
    });

    it("renders preview when startInPreview is true", async () => {
      await wrapper.setProps({ startInPreview: true });
      expect(wrapper.find("textarea").exists()).toBe(false);
      expect(wrapper.find(".content").exists()).toBe(true);
    });

    it("displays placeholder text", () => {
      expect(wrapper.find("textarea").attributes("placeholder")).toBe(
        "Enter text...",
      );
    });

    it("displays the modelValue in textarea", () => {
      expect(wrapper.find("textarea").element.value).toBe("Test content");
    });
  });

  describe("Editor/Preview Toggle", () => {
    it("shows Editor and Preview buttons", () => {
      const buttons = wrapper.findAll("button");
      const buttonTexts = buttons.map((btn) => btn.text());
      expect(buttonTexts).toContain("Editor");
      expect(buttonTexts).toContain("Preview");
    });

    it("toggles to preview mode when Preview button is clicked", async () => {
      const previewBtn = wrapper
        .findAll("button")
        .find((btn) => btn.text() === "Preview");
      await previewBtn.trigger("click");
      expect(wrapper.find(".content").exists()).toBe(true);
      expect(wrapper.find("textarea").exists()).toBe(false);
    });

    it("toggles to editor mode when Editor button is clicked", async () => {
      await wrapper.setProps({ startInPreview: true });
      const editorBtn = wrapper
        .findAll("button")
        .find((btn) => btn.text() === "Editor");
      await editorBtn.trigger("click");
      expect(wrapper.find("textarea").exists()).toBe(true);
      expect(wrapper.find(".content").exists()).toBe(false);
    });

    it("highlights active mode button with is-dark class", async () => {
      const editorBtn = wrapper
        .findAll("button")
        .find((btn) => btn.text() === "Editor");
      expect(editorBtn.classes()).toContain("is-dark");

      const previewBtn = wrapper
        .findAll("button")
        .find((btn) => btn.text() === "Preview");
      await previewBtn.trigger("click");
      expect(previewBtn.classes()).toContain("is-dark");
      expect(editorBtn.classes()).not.toContain("is-dark");
    });
  });

  describe("Formatting Buttons", () => {
    it("shows Bold and Italic buttons in editor mode", () => {
      const boldBtn = wrapper.find('[title="Bold"]');
      const italicBtn = wrapper.find('[title="Italic"]');
      expect(boldBtn.exists()).toBe(true);
      expect(italicBtn.exists()).toBe(true);
    });

    it("hides formatting buttons in preview mode", async () => {
      const previewBtn = wrapper
        .findAll("button")
        .find((btn) => btn.text() === "Preview");
      await previewBtn.trigger("click");
      expect(wrapper.find('[title="Bold"]').exists()).toBe(false);
      expect(wrapper.find('[title="Italic"]').exists()).toBe(false);
    });
  });

  describe("Bold Formatting", () => {
    beforeEach(() => {
      // Mock document.execCommand
      document.execCommand = vi.fn((command, showUI, value) => {
        const textarea = wrapper.find("textarea").element;
        const start = textarea.selectionStart;
        const end = textarea.selectionEnd;
        const currentValue = textarea.value;
        const newValue =
          currentValue.substring(0, start) +
          value +
          currentValue.substring(end);
        textarea.value = newValue;
        wrapper.vm.$emit("update:modelValue", newValue);
        return true;
      });
    });

    it("inserts bold markers when no text is selected", async () => {
      const textarea = wrapper.find("textarea").element;
      textarea.setSelectionRange(0, 0);

      const boldBtn = wrapper.find('[title="Bold"]');
      await boldBtn.trigger("click");

      expect(document.execCommand).toHaveBeenCalledWith(
        "insertText",
        false,
        "****",
      );
    });

    it("wraps selected text with bold markers", async () => {
      const textarea = wrapper.find("textarea").element;
      textarea.setSelectionRange(0, 4); // Select "Test"

      const boldBtn = wrapper.find('[title="Bold"]');
      await boldBtn.trigger("click");

      expect(document.execCommand).toHaveBeenCalledWith(
        "insertText",
        false,
        "**Test**",
      );
    });

    it("removes bold markers when selection is surrounded by them", async () => {
      await wrapper.setProps({ modelValue: "**bold text**" });
      const textarea = wrapper.find("textarea").element;
      textarea.setSelectionRange(2, 11); // Select "bold text" (between markers)

      const boldBtn = wrapper.find('[title="Bold"]');
      await boldBtn.trigger("click");

      // Should select from position 0 to 13 (including markers) and replace with "bold text"
      expect(document.execCommand).toHaveBeenCalledWith(
        "insertText",
        false,
        "bold text",
      );
    });

    it("removes bold markers when selection includes them", async () => {
      await wrapper.setProps({ modelValue: "**bold text**" });
      const textarea = wrapper.find("textarea").element;
      textarea.setSelectionRange(0, 13); // Select "**bold text**"

      const boldBtn = wrapper.find('[title="Bold"]');
      await boldBtn.trigger("click");

      expect(document.execCommand).toHaveBeenCalledWith(
        "insertText",
        false,
        "bold text",
      );
    });
  });

  describe("Italic Formatting", () => {
    beforeEach(() => {
      // Mock document.execCommand
      document.execCommand = vi.fn((command, showUI, value) => {
        const textarea = wrapper.find("textarea").element;
        const start = textarea.selectionStart;
        const end = textarea.selectionEnd;
        const currentValue = textarea.value;
        const newValue =
          currentValue.substring(0, start) +
          value +
          currentValue.substring(end);
        textarea.value = newValue;
        wrapper.vm.$emit("update:modelValue", newValue);
        return true;
      });
    });

    it("inserts italic markers when no text is selected", async () => {
      const textarea = wrapper.find("textarea").element;
      textarea.setSelectionRange(0, 0);

      const italicBtn = wrapper.find('[title="Italic"]');
      await italicBtn.trigger("click");

      expect(document.execCommand).toHaveBeenCalledWith(
        "insertText",
        false,
        "**",
      );
    });

    it("wraps selected text with italic markers", async () => {
      const textarea = wrapper.find("textarea").element;
      textarea.setSelectionRange(0, 4); // Select "Test"

      const italicBtn = wrapper.find('[title="Italic"]');
      await italicBtn.trigger("click");

      expect(document.execCommand).toHaveBeenCalledWith(
        "insertText",
        false,
        "*Test*",
      );
    });

    it("removes italic markers when selection is surrounded by them", async () => {
      await wrapper.setProps({ modelValue: "*italic text*" });
      const textarea = wrapper.find("textarea").element;
      textarea.setSelectionRange(1, 12); // Select "italic text" (between markers)

      const italicBtn = wrapper.find('[title="Italic"]');
      await italicBtn.trigger("click");

      expect(document.execCommand).toHaveBeenCalledWith(
        "insertText",
        false,
        "italic text",
      );
    });

    it("removes italic markers when selection includes them", async () => {
      await wrapper.setProps({ modelValue: "*italic text*" });
      const textarea = wrapper.find("textarea").element;
      textarea.setSelectionRange(0, 13); // Select "*italic text*"

      const italicBtn = wrapper.find('[title="Italic"]');
      await italicBtn.trigger("click");

      expect(document.execCommand).toHaveBeenCalledWith(
        "insertText",
        false,
        "italic text",
      );
    });
  });

  describe("v-model", () => {
    it("emits update:modelValue when textarea changes", async () => {
      const textarea = wrapper.find("textarea");
      await textarea.setValue("New content");

      expect(wrapper.emitted("update:modelValue")).toBeTruthy();
      expect(wrapper.emitted("update:modelValue")[0]).toEqual(["New content"]);
    });

    it("updates textarea when modelValue prop changes", async () => {
      await wrapper.setProps({ modelValue: "Updated content" });
      expect(wrapper.find("textarea").element.value).toBe("Updated content");
    });
  });

  describe("Actions Slot", () => {
    it("renders actions slot content", () => {
      const wrapperWithSlot = mount(MarkdownEditor, {
        props: {
          modelValue: "Test",
          startInPreview: false,
        },
        slots: {
          actions: '<button class="save-btn">Save</button>',
        },
      });

      expect(wrapperWithSlot.find(".save-btn").exists()).toBe(true);
      expect(wrapperWithSlot.find(".save-btn").text()).toBe("Save");
    });
  });

  describe("Exposed Methods", () => {
    it("exposes focusTextarea method", () => {
      expect(wrapper.vm.focusTextarea).toBeDefined();
      expect(typeof wrapper.vm.focusTextarea).toBe("function");
    });

    it("exposes showPreview ref", () => {
      expect(wrapper.vm.showPreview).toBeDefined();
    });

    it("focusTextarea focuses the textarea element", async () => {
      const textarea = wrapper.find("textarea").element;
      const focusSpy = vi.spyOn(textarea, "focus");

      wrapper.vm.focusTextarea();
      await wrapper.vm.$nextTick();

      expect(focusSpy).toHaveBeenCalled();
    });
  });

  describe("Markdown Preview", () => {
    it("renders markdown as HTML in preview mode", async () => {
      await wrapper.setProps({
        modelValue: "**bold** and *italic*",
        startInPreview: true,
      });

      const preview = wrapper.find(".content");
      expect(preview.html()).toContain("<strong>bold</strong>");
      expect(preview.html()).toContain("<em>italic</em>");
    });
  });
});
