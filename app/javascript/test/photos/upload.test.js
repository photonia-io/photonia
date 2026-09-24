import { describe, it, expect, vi, beforeEach, afterEach } from "vitest";
import { mount } from "@vue/test-utils";
import { createPinia, setActivePinia } from "pinia";

import { installFakeXHR, FakeXHR } from "../support/fake-xhr";

const { onBeforeRouteLeaveMock } = vi.hoisted(() => ({
  onBeforeRouteLeaveMock: vi.fn(),
}));

vi.mock("vue-page-title", () => ({
  useTitle: vi.fn(),
}));

vi.mock("vue-router", () => ({
  onBeforeRouteLeave: onBeforeRouteLeaveMock,
}));

import Upload from "../../photos/upload.vue";

function makeFile(name, type = "image/jpeg") {
  return new File([new Uint8Array(1024)], name, { type });
}

// happy-dom's DataTransfer doesn't carry `types`/`files` the way real drag
// events do, so build a minimal stand-in for dispatched drag/drop events.
function dragEvent(type, files = []) {
  const event = new Event(type, { bubbles: true, cancelable: true });
  event.dataTransfer = {
    types: ["Files"],
    files,
  };
  return event;
}

let cacheReset;
let apolloQuery;
let mountedWrapper;

function mountUpload() {
  const pinia = createPinia();
  setActivePinia(pinia);
  cacheReset = vi.fn();
  apolloQuery = vi.fn().mockResolvedValue({ data: { photosByIds: [] } });

  const wrapper = mount(Upload, {
    attachTo: document.body,
    global: {
      plugins: [pinia],
      provide: {
        apolloClient: { cache: { reset: cacheReset }, query: apolloQuery },
      },
      stubs: {
        RouterLink: { template: "<a><slot /></a>", props: ["to"] },
      },
    },
  });
  mountedWrapper = wrapper;
  return wrapper;
}

async function addFile(wrapper, name = "one.jpg") {
  const input = wrapper.find("input[type=file]");
  Object.defineProperty(input.element, "files", {
    value: [makeFile(name)],
    configurable: true,
  });
  await input.trigger("change");
}

function findButton(wrapper, text) {
  return wrapper.findAll("button").find((b) => b.text().includes(text));
}

async function uploadAndRespond(wrapper, name, status, body) {
  await addFile(wrapper, name);
  await findButton(wrapper, "Upload All").trigger("click");
  await Promise.resolve();
  await Promise.resolve();
  FakeXHR.instances.at(-1).respond(status, body);
  await Promise.resolve();
  await Promise.resolve();
  await Promise.resolve();
}

beforeEach(() => {
  installFakeXHR();
  globalThis.gql_queries = {
    photos_processing: `
      query PhotosProcessingQuery($ids: [ID!]!) {
        photosByIds(ids: $ids) {
          id
          processed
        }
      }
    `,
  };
});

afterEach(() => {
  mountedWrapper?.unmount();
  mountedWrapper = undefined;
  vi.useRealTimers();
});

describe("Upload", () => {
  it("shows only Select Files when the queue is empty", () => {
    const wrapper = mountUpload();
    const buttons = wrapper.findAll("button").map((b) => b.text());
    expect(buttons).toContain("Select Files");
    expect(buttons.some((t) => t.includes("Upload All"))).toBe(false);
  });

  it("enables Upload All once a file is pending, and disables it once uploading", async () => {
    const wrapper = mountUpload();
    await addFile(wrapper);

    const uploadAll = findButton(wrapper, "Upload All");
    expect(uploadAll.attributes("disabled")).toBeUndefined();

    await uploadAll.trigger("click");
    await Promise.resolve();
    await Promise.resolve();

    expect(findButton(wrapper, "Stop Upload")).toBeTruthy();
  });

  it("leaves the form usable after a failed upload, and Retry re-queues it", async () => {
    const wrapper = mountUpload();
    await uploadAndRespond(wrapper, "one.jpg", 422, {
      errors: ["Title can't be blank"],
    });

    expect(wrapper.text()).toContain("Title can't be blank");
    expect(wrapper.text()).toContain("Failed");

    const select = findButton(wrapper, "Select Files");
    const removeAll = findButton(wrapper, "Remove All");
    const retry = wrapper.find('button[title="Retry"]');

    expect(select.attributes("disabled")).toBeUndefined();
    expect(removeAll.attributes("disabled")).toBeUndefined();
    expect(retry.exists()).toBe(true);

    await retry.trigger("click");
    await Promise.resolve();
    await Promise.resolve();

    expect(FakeXHR.instances).toHaveLength(2);
  });

  it("shows the drop overlay on a window drag and hides it on drop", async () => {
    const wrapper = mountUpload();

    window.dispatchEvent(dragEvent("dragenter"));
    await wrapper.vm.$nextTick();
    expect(document.querySelector(".drop-active").style.display).not.toBe(
      "none",
    );

    window.dispatchEvent(dragEvent("drop", [makeFile("dropped.jpg")]));
    await wrapper.vm.$nextTick();

    expect(document.querySelector(".drop-active").style.display).toBe(
      "none",
    );
    expect(
      wrapper.find(".upload-fields input[type=text]").element.value,
    ).toBe("dropped.jpg");
  });

  it("uploads a second batch after the first finishes, without reloading", async () => {
    const wrapper = mountUpload();
    await uploadAndRespond(wrapper, "one.jpg", 201, { photo: { id: "one" } });

    await addFile(wrapper, "two.jpg");
    await findButton(wrapper, "Upload All").trigger("click");
    await Promise.resolve();
    await Promise.resolve();

    expect(FakeXHR.instances).toHaveLength(2);
    FakeXHR.instances[1].respond(201, { photo: { id: "two" } });
    await Promise.resolve();
    await Promise.resolve();
    await Promise.resolve();

    expect(wrapper.findAll(".upload-item")).toHaveLength(2);
  });

  it("shows a running summary of the batch", async () => {
    const wrapper = mountUpload();
    await addFile(wrapper, "one.jpg");
    await addFile(wrapper, "two.jpg");

    expect(wrapper.find(".upload-summary").text()).toContain("0 of 2 uploaded");
  });

  describe("batch operations", () => {
    it("appears as soon as a file is queued, and stays through the batch", async () => {
      const wrapper = mountUpload();
      expect(wrapper.find(".upload-batch-box").exists()).toBe(false);

      await uploadAndRespond(wrapper, "one.jpg", 201, {
        photo: { id: "one" },
      });
      expect(wrapper.find(".upload-batch-box").exists()).toBe(true);
    });

    it("disables its fields once nothing is pending", async () => {
      const wrapper = mountUpload();
      await uploadAndRespond(wrapper, "one.jpg", 201, {
        photo: { id: "one" },
      });

      const box = wrapper.find(".upload-batch-box");
      expect(box.find('input[placeholder="Title"]').attributes("disabled")).toBeDefined();
      expect(findButton(wrapper, "Apply to 0 pending").attributes("disabled")).toBeDefined();
    });

    it("sets the title on every pending item, leaving a finished one alone", async () => {
      const wrapper = mountUpload();
      await uploadAndRespond(wrapper, "one.jpg", 201, {
        photo: { id: "one" },
      });
      await addFile(wrapper, "two.jpg");
      await addFile(wrapper, "three.jpg");

      const box = wrapper.find(".upload-batch-box");
      await box.find('input[placeholder="Title"]').setValue("Batch title");
      await findButton(wrapper, "Apply to 2 pending").trigger("click");

      const titleInputs = wrapper
        .findAll(".upload-fields input[type=text]")
        .map((i) => i.element.value);
      expect(titleInputs).toEqual(["one.jpg", "Batch title", "Batch title"]);
    });
  });

  describe("processing status", () => {
    beforeEach(() => {
      vi.useFakeTimers();
    });

    it("shows Processing after upload, then polls and shows Complete", async () => {
      const wrapper = mountUpload();
      await uploadAndRespond(wrapper, "one.jpg", 201, {
        photo: { id: "one" },
      });

      expect(wrapper.text()).toContain("Processing");
      expect(cacheReset).not.toHaveBeenCalled();

      apolloQuery.mockResolvedValueOnce({
        data: { photosByIds: [{ id: "one", processed: true }] },
      });
      await vi.advanceTimersByTimeAsync(3000);
      await Promise.resolve();
      await Promise.resolve();

      expect(apolloQuery).toHaveBeenCalledWith(
        expect.objectContaining({ variables: { ids: ["one"] } }),
      );
      expect(wrapper.text()).toContain("Complete");
      expect(cacheReset).toHaveBeenCalledTimes(1);
    });

    it("does not poll or reset the cache after a failed upload", async () => {
      const wrapper = mountUpload();
      await uploadAndRespond(wrapper, "one.jpg", 422, { errors: ["bad"] });

      await vi.advanceTimersByTimeAsync(10000);

      expect(apolloQuery).not.toHaveBeenCalled();
      expect(cacheReset).not.toHaveBeenCalled();
    });

    it("shows a View photo link once processed", async () => {
      const wrapper = mountUpload();
      await uploadAndRespond(wrapper, "one.jpg", 201, {
        photo: { id: "one" },
      });

      apolloQuery.mockResolvedValueOnce({
        data: { photosByIds: [{ id: "one", processed: true }] },
      });
      await vi.advanceTimersByTimeAsync(3000);
      await Promise.resolve();
      await Promise.resolve();

      const link = wrapper.find(".upload-status a");
      expect(link.text()).toBe("View photo");
    });
  });

  describe("leave-page guard", () => {
    it("lets navigation through when nothing is pending or uploading", () => {
      mountUpload();
      const guard = onBeforeRouteLeaveMock.mock.calls[0][0];
      expect(guard()).toBe(true);
    });

    it("confirms before leaving with pending files, and stops on cancel", async () => {
      const wrapper = mountUpload();
      await addFile(wrapper);
      const guard = onBeforeRouteLeaveMock.mock.calls[0][0];

      window.confirm = vi.fn().mockReturnValue(false);
      expect(guard()).toBe(false);
      expect(window.confirm).toHaveBeenCalled();

      window.confirm.mockReturnValue(true);
      expect(guard()).toBe(true);
    });
  });

  it("warns on beforeunload only while something is pending or uploading", async () => {
    const wrapper = mountUpload();

    const emptyEvent = new Event("beforeunload", { cancelable: true });
    window.dispatchEvent(emptyEvent);
    expect(emptyEvent.defaultPrevented).toBe(false);

    await addFile(wrapper);
    const pendingEvent = new Event("beforeunload", { cancelable: true });
    window.dispatchEvent(pendingEvent);
    expect(pendingEvent.defaultPrevented).toBe(true);
  });
});
