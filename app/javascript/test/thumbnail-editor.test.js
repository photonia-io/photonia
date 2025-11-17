import { describe, it, expect, beforeEach, vi } from "vitest";
import { mount } from "@vue/test-utils";
import ThumbnailEditor from "../photos/thumbnail-editor.vue";

// Mock photo data
const mockPhoto = {
  title: "Test Photo",
  extralargeImageUrl: "https://example.com/photo.jpg",
  userThumbnail: null,
  intelligentThumbnail: null,
};

const mockPhotoWithUserThumbnail = {
  ...mockPhoto,
  userThumbnail: {
    top: 0.3,
    left: 0.2,
    width: 0.4,
    height: 0.4,
  },
};

const mockPhotoWithIntelligentThumbnail = {
  ...mockPhoto,
  intelligentThumbnail: {
    boundingBox: {
      top: 0.25,
      left: 0.25,
      width: 0.5,
      height: 0.5,
    },
  },
};

describe("ThumbnailEditor", () => {
  let wrapper;

  beforeEach(() => {
    // Mock getBoundingClientRect for image element
    Element.prototype.getBoundingClientRect = vi.fn(() => ({
      width: 800,
      height: 600,
    }));

    // Mock window.addEventListener and removeEventListener
    window.addEventListener = vi.fn();
    window.removeEventListener = vi.fn();
  });

  afterEach(() => {
    vi.restoreAllMocks();
  });

  describe("Rendering", () => {
    it("renders when editMode is true", () => {
      wrapper = mount(ThumbnailEditor, {
        props: {
          photo: mockPhoto,
          editMode: true,
        },
      });

      expect(wrapper.find(".thumbnail-editor").exists()).toBe(true);
      expect(wrapper.find(".editor-container").exists()).toBe(true);
      expect(wrapper.find(".image-wrapper").exists()).toBe(true);
      expect(wrapper.find(".editor-controls").exists()).toBe(true);
    });

    it("does not render when editMode is false", () => {
      wrapper = mount(ThumbnailEditor, {
        props: {
          photo: mockPhoto,
          editMode: false,
        },
      });

      expect(wrapper.find(".thumbnail-editor").exists()).toBe(false);
    });

    it("renders the photo image", () => {
      wrapper = mount(ThumbnailEditor, {
        props: {
          photo: mockPhoto,
          editMode: true,
        },
      });

      const img = wrapper.find("img");
      expect(img.exists()).toBe(true);
      expect(img.attributes("src")).toBe(mockPhoto.extralargeImageUrl);
      expect(img.attributes("alt")).toBe("Photo for thumbnail editing");
    });

    it("renders save and cancel buttons", () => {
      wrapper = mount(ThumbnailEditor, {
        props: {
          photo: mockPhoto,
          editMode: true,
        },
      });

      const buttons = wrapper.findAll("button");
      expect(buttons.length).toBe(2);

      const saveButton = wrapper.find(".button.is-success");
      const cancelButton = wrapper.find(".button:not(.is-success)");

      expect(saveButton.exists()).toBe(true);
      expect(saveButton.text()).toContain("Save Thumbnail");
      expect(cancelButton.exists()).toBe(true);
      expect(cancelButton.text()).toContain("Cancel");
    });

    it("shows thumbnail box after image loads", async () => {
      wrapper = mount(ThumbnailEditor, {
        props: {
          photo: mockPhoto,
          editMode: true,
        },
      });

      // Initially thumbnail box should not be visible
      expect(wrapper.find(".thumbnail-box").exists()).toBe(false);

      // Trigger image load
      const img = wrapper.find("img");
      await img.trigger("load");

      // Now thumbnail box should be visible
      expect(wrapper.find(".thumbnail-box").exists()).toBe(true);
      expect(wrapper.find(".resize-handle").exists()).toBe(true);
    });
  });

  describe("Thumbnail Initialization", () => {
    it("initializes with default thumbnail when no existing data", async () => {
      wrapper = mount(ThumbnailEditor, {
        props: {
          photo: mockPhoto,
          editMode: true,
        },
      });

      const img = wrapper.find("img");
      await img.trigger("load");

      // For landscape image (800x600), should use full height and center horizontally
      const thumbnailBox = wrapper.find(".thumbnail-box");
      expect(thumbnailBox.exists()).toBe(true);

      // Check that thumbnail is positioned correctly for landscape
      const style = thumbnailBox.attributes("style");
      expect(style).toContain("top: 0px"); // Full height starts at top
      expect(style).toContain("height: 600px"); // Full height
    });

    it("initializes with user thumbnail data when available", async () => {
      wrapper = mount(ThumbnailEditor, {
        props: {
          photo: mockPhotoWithUserThumbnail,
          editMode: true,
        },
      });

      const img = wrapper.find("img");
      await img.trigger("load");

      const thumbnailBox = wrapper.find(".thumbnail-box");
      expect(thumbnailBox.exists()).toBe(true);

      // Should use the user thumbnail position
      const style = thumbnailBox.attributes("style");
      expect(style).toContain("top: 180px"); // 0.3 * 600
      expect(style).toContain("left: 160px"); // 0.2 * 800
    });

    it("initializes with intelligent thumbnail data when available", async () => {
      wrapper = mount(ThumbnailEditor, {
        props: {
          photo: mockPhotoWithIntelligentThumbnail,
          editMode: true,
        },
      });

      const img = wrapper.find("img");
      await img.trigger("load");

      const thumbnailBox = wrapper.find(".thumbnail-box");
      expect(thumbnailBox.exists()).toBe(true);

      // Should use the intelligent thumbnail position
      const style = thumbnailBox.attributes("style");
      expect(style).toContain("top: 150px"); // 0.25 * 600
      expect(style).toContain("left: 200px"); // 0.25 * 800
    });
  });

  describe("Event Handling", () => {
    beforeEach(() => {
      wrapper = mount(ThumbnailEditor, {
        props: {
          photo: mockPhoto,
          editMode: true,
        },
      });

      // Load the image
      const img = wrapper.find("img");
      img.trigger("load");
    });

    it("emits save event with thumbnail data when save button is clicked", async () => {
      const saveButton = wrapper.find(".button.is-success");
      await saveButton.trigger("click");

      expect(wrapper.emitted("save")).toBeTruthy();
      expect(wrapper.emitted("save")[0]).toEqual([
        {
          top: expect.any(Number),
          left: expect.any(Number),
          width: expect.any(Number),
          height: expect.any(Number),
        },
      ]);
    });

    it("emits cancel event when cancel button is clicked", async () => {
      const cancelButton = wrapper.find(".button:not(.is-success)");
      await cancelButton.trigger("click");

      expect(wrapper.emitted("cancel")).toBeTruthy();
      expect(wrapper.emitted("cancel").length).toBe(1);
    });

    it("sets up event listeners on mount", () => {
      expect(window.addEventListener).toHaveBeenCalledWith(
        "mousemove",
        expect.any(Function),
      );
      expect(window.addEventListener).toHaveBeenCalledWith(
        "mouseup",
        expect.any(Function),
      );
      expect(window.addEventListener).toHaveBeenCalledWith(
        "resize",
        expect.any(Function),
      );
    });

    it("removes event listeners on unmount", () => {
      wrapper.unmount();
      expect(window.removeEventListener).toHaveBeenCalledWith(
        "mousemove",
        expect.any(Function),
      );
      expect(window.removeEventListener).toHaveBeenCalledWith(
        "mouseup",
        expect.any(Function),
      );
      expect(window.removeEventListener).toHaveBeenCalledWith(
        "resize",
        expect.any(Function),
      );
    });
  });

  describe("Drag Functionality", () => {
    beforeEach(() => {
      wrapper = mount(ThumbnailEditor, {
        props: {
          photo: mockPhoto,
          editMode: true,
        },
      });

      // Load the image
      const img = wrapper.find("img");
      img.trigger("load");
    });

    it("starts dragging when mousedown is triggered on thumbnail box", async () => {
      const thumbnailBox = wrapper.find(".thumbnail-box");
      await thumbnailBox.trigger("mousedown", {
        clientX: 100,
        clientY: 100,
      });

      expect(wrapper.vm.isDragging).toBe(true);
      expect(wrapper.vm.dragStartX).toBe(100);
      expect(wrapper.vm.dragStartY).toBe(100);
    });

    it("updates thumbnail position during drag", async () => {
      const thumbnailBox = wrapper.find(".thumbnail-box");

      // Start drag from a position that allows movement
      await thumbnailBox.trigger("mousedown", {
        clientX: 400,
        clientY: 300,
      });

      // Get initial position
      const initialLeft = wrapper.vm.thumbnail.left;
      const initialTop = wrapper.vm.thumbnail.top;

      // Simulate mouse move with a reasonable delta
      const mouseMoveHandler = window.addEventListener.mock.calls.find(
        (call) => call[0] === "mousemove",
      )[1];

      mouseMoveHandler({ clientX: 350, clientY: 250 }); // Move up and left

      // Check that thumbnail position was updated from initial position
      // Note: If the thumbnail is at the edge, it might not move in that direction
      // So we check if at least one of the positions changed
      const positionChanged =
        wrapper.vm.thumbnail.left !== initialLeft ||
        wrapper.vm.thumbnail.top !== initialTop;

      expect(positionChanged).toBe(true);
    });

    it("stops dragging on mouse up", async () => {
      const thumbnailBox = wrapper.find(".thumbnail-box");

      // Start drag
      await thumbnailBox.trigger("mousedown", {
        clientX: 100,
        clientY: 100,
      });

      // Simulate mouse up
      const mouseUpHandler = window.addEventListener.mock.calls.find(
        (call) => call[0] === "mouseup",
      )[1];

      mouseUpHandler();

      expect(wrapper.vm.isDragging).toBe(false);
    });

    it("constrains thumbnail position within image bounds", async () => {
      const thumbnailBox = wrapper.find(".thumbnail-box");

      // Start drag from center
      await thumbnailBox.trigger("mousedown", {
        clientX: 400,
        clientY: 300,
      });

      // Try to drag far outside bounds
      const mouseMoveHandler = window.addEventListener.mock.calls.find(
        (call) => call[0] === "mousemove",
      )[1];

      mouseMoveHandler({ clientX: -1000, clientY: -1000 });

      // Position should be constrained to 0,0
      expect(wrapper.vm.thumbnail.left).toBeGreaterThanOrEqual(0);
      expect(wrapper.vm.thumbnail.top).toBeGreaterThanOrEqual(0);
    });
  });

  describe("Resize Functionality", () => {
    beforeEach(() => {
      wrapper = mount(ThumbnailEditor, {
        props: {
          photo: mockPhoto,
          editMode: true,
        },
      });

      // Load the image
      const img = wrapper.find("img");
      img.trigger("load");
    });

    it("starts resizing when mousedown is triggered on resize handle", async () => {
      const resizeHandle = wrapper.find(".resize-handle");
      await resizeHandle.trigger("mousedown", {
        clientX: 100,
        clientY: 100,
      });

      expect(wrapper.vm.isResizing).toBe(true);
      expect(wrapper.vm.dragStartX).toBe(100);
      expect(wrapper.vm.dragStartY).toBe(100);
    });

    it("updates thumbnail size during resize", async () => {
      const resizeHandle = wrapper.find(".resize-handle");

      // Start resize
      await resizeHandle.trigger("mousedown", {
        clientX: 100,
        clientY: 100,
      });

      // Get initial size
      const initialWidth = wrapper.vm.thumbnail.width;
      const initialHeight = wrapper.vm.thumbnail.height;

      // Simulate mouse move to decrease size (since it's already at max size)
      const mouseMoveHandler = window.addEventListener.mock.calls.find(
        (call) => call[0] === "mousemove",
      )[1];

      mouseMoveHandler({ clientX: 50, clientY: 50 }); // Move up and left to decrease size

      // Check that thumbnail size was updated from initial size
      // Note: If the thumbnail is at minimum size, it might not decrease further
      // So we check if the size changed in either direction
      const sizeChanged =
        wrapper.vm.thumbnail.width !== initialWidth ||
        wrapper.vm.thumbnail.height !== initialHeight;

      expect(sizeChanged).toBe(true);
    });

    it("constrains thumbnail size to minimum and maximum", async () => {
      const resizeHandle = wrapper.find(".resize-handle");

      // Start resize
      await resizeHandle.trigger("mousedown", {
        clientX: 100,
        clientY: 100,
      });

      // Try to resize very small
      const mouseMoveHandler = window.addEventListener.mock.calls.find(
        (call) => call[0] === "mousemove",
      )[1];

      mouseMoveHandler({ clientX: -1000, clientY: -1000 });

      // Size should be constrained to minimum (0.1)
      expect(wrapper.vm.thumbnail.width).toBeGreaterThanOrEqual(0.1);
      expect(wrapper.vm.thumbnail.height).toBeGreaterThanOrEqual(0.1);
    });
  });

  describe("Watchers", () => {
    it("reinitializes thumbnail when editMode changes to true", async () => {
      wrapper = mount(ThumbnailEditor, {
        props: {
          photo: mockPhoto,
          editMode: false,
        },
      });

      // The component doesn't render when editMode is false, so we need to
      // change editMode to true first, then trigger image load
      await wrapper.setProps({ editMode: true });

      // Now trigger image load
      const img = wrapper.find("img");
      await img.trigger("load");

      // Should trigger onImageLoad
      expect(wrapper.vm.imageLoaded).toBe(true);
    });
  });

  describe("Helper Functions", () => {
    beforeEach(() => {
      wrapper = mount(ThumbnailEditor, {
        props: {
          photo: mockPhoto,
          editMode: true,
        },
      });

      // Load the image
      const img = wrapper.find("img");
      img.trigger("load");
    });

    it("calculates square size correctly", () => {
      const uniformSize = 0.5;
      const squareSize = wrapper.vm.calculateSquareSize(uniformSize);

      // Should be the smaller of width and height calculations
      const expectedWidth = uniformSize * 800; // 400
      const expectedHeight = uniformSize * 600; // 300
      const expected = Math.min(expectedWidth, expectedHeight); // 300

      expect(squareSize).toBe(expected);
    });

    it("constrains position within bounds", () => {
      const uniformSize = 0.5;

      // Test position within bounds
      const validPosition = wrapper.vm.constrainPosition(0.3, 0.3, uniformSize);
      expect(validPosition.left).toBe(0.3);
      expect(validPosition.top).toBe(0.3);

      // Test position outside bounds
      const invalidPosition = wrapper.vm.constrainPosition(
        1.5,
        1.5,
        uniformSize,
      );
      expect(invalidPosition.left).toBeLessThanOrEqual(1 - 300 / 800); // Max valid left
      expect(invalidPosition.top).toBeLessThanOrEqual(1 - 300 / 600); // Max valid top
    });
  });

  describe("Portrait Image Handling", () => {
    beforeEach(() => {
      // Mock portrait image dimensions
      Element.prototype.getBoundingClientRect = vi.fn(() => ({
        width: 600,
        height: 800,
      }));
    });

    it("handles portrait images correctly", async () => {
      wrapper = mount(ThumbnailEditor, {
        props: {
          photo: mockPhoto,
          editMode: true,
        },
      });

      const img = wrapper.find("img");
      await img.trigger("load");

      // For portrait image (600x800), should use full width and center vertically
      const thumbnailBox = wrapper.find(".thumbnail-box");
      const style = thumbnailBox.attributes("style");

      expect(style).toContain("left: 0px"); // Full width starts at left
      expect(style).toContain("width: 600px"); // Full width
    });
  });
});
