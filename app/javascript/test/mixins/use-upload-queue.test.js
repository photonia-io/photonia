import { describe, it, expect, vi, beforeEach, afterEach } from "vitest";
import { effectScope } from "vue";
import { createPinia, setActivePinia } from "pinia";

import { installFakeXHR, FakeXHR } from "../support/fake-xhr";
import { useUploadQueue } from "../../mixins/use-upload-queue";
import { useTokenStore } from "../../stores/token";

function makeFile(name, type = "image/jpeg", size = 1024) {
  const file = new File([new Uint8Array(size)], name, { type });
  return file;
}

let scope;

function setup(opts) {
  scope = effectScope();
  return scope.run(() => useUploadQueue(opts));
}

beforeEach(() => {
  setActivePinia(createPinia());
  installFakeXHR();
  vi.stubGlobal("URL", {
    ...URL,
    createObjectURL: vi.fn(() => "blob:fake"),
    revokeObjectURL: vi.fn(),
  });
});

afterEach(() => {
  scope?.stop();
  scope = undefined;
  vi.unstubAllGlobals();
});

describe("useUploadQueue", () => {
  describe("add", () => {
    it("skips dotfiles and system files", () => {
      const queue = setup();
      queue.add([makeFile(".DS_Store"), makeFile("Thumbs.db"), makeFile("desktop.ini")]);
      expect(queue.items.value).toHaveLength(0);
    });

    it("skips files with a disallowed extension", () => {
      const queue = setup();
      queue.add([makeFile("shell.php", "image/jpeg")]);
      expect(queue.items.value).toHaveLength(0);
    });

    it("skips files with a disallowed MIME type", () => {
      const queue = setup();
      queue.add([makeFile("fake.jpg", "text/html")]);
      expect(queue.items.value).toHaveLength(0);
    });

    it("accepts a matching image file and defaults the title to the file name", () => {
      const queue = setup();
      queue.add([makeFile("one.jpg")]);
      expect(queue.items.value).toHaveLength(1);
      expect(queue.items.value[0].title).toBe("one.jpg");
      expect(queue.items.value[0].status).toBe("pending");
      expect(queue.items.value[0].previewUrl).toBe("blob:fake");
    });
  });

  describe("start", () => {
    it("sends one request at a time", async () => {
      const queue = setup();
      queue.add([makeFile("one.jpg"), makeFile("two.jpg")]);

      const startPromise = queue.start();
      await Promise.resolve();
      await Promise.resolve();

      expect(FakeXHR.instances).toHaveLength(1);
      expect(queue.items.value[0].status).toBe("uploading");

      FakeXHR.instances[0].respond(201, { photo: { id: "one" } });
      await Promise.resolve();
      await Promise.resolve();

      expect(FakeXHR.instances).toHaveLength(2);
      FakeXHR.instances[1].respond(201, { photo: { id: "two" } });

      const successCount = await startPromise;
      expect(successCount).toBe(2);
    });

    it("builds FormData at send time, including edits and extraFields", async () => {
      const queue = setup({
        extraFields: (item) => ({ "photo[album_ids][]": ["album-1", "album-2"] }),
      });
      queue.add([makeFile("one.jpg")]);
      queue.items.value[0].title = "Edited title";

      const startPromise = queue.start();
      await Promise.resolve();
      await Promise.resolve();

      const body = FakeXHR.instances[0].body;
      expect(body.get("photo[title]")).toBe("Edited title");
      expect(body.get("photo[image]")).toBeInstanceOf(File);
      expect(body.getAll("photo[album_ids][]")).toEqual(["album-1", "album-2"]);

      FakeXHR.instances[0].respond(201, { photo: { id: "one" } });
      await startPromise;
    });

    it("sends the Authorization header from the token store", async () => {
      useTokenStore().authorization = "Bearer abc123";
      const queue = setup();
      queue.add([makeFile("one.jpg")]);

      const startPromise = queue.start();
      await Promise.resolve();
      await Promise.resolve();

      expect(FakeXHR.instances[0].headers.Authorization).toBe("Bearer abc123");

      FakeXHR.instances[0].respond(201, { photo: { id: "one" } });
      await startPromise;
    });

    it("tracks progress", async () => {
      const queue = setup();
      queue.add([makeFile("one.jpg")]);

      const startPromise = queue.start();
      await Promise.resolve();
      await Promise.resolve();

      FakeXHR.instances[0].progress(50, 100);
      expect(queue.items.value[0].progress).toBe(50);

      FakeXHR.instances[0].respond(201, { photo: { id: "one" } });
      await startPromise;
    });

    it("marks an item successful on a 2xx JSON response", async () => {
      const queue = setup();
      queue.add([makeFile("one.jpg")]);

      const startPromise = queue.start();
      await Promise.resolve();
      await Promise.resolve();
      FakeXHR.instances[0].respond(201, { photo: { id: "one" } });
      await startPromise;

      expect(queue.items.value[0].status).toBe("success");
      expect(queue.items.value[0].response).toEqual({ photo: { id: "one" } });
    });

    it("shows the server's errors on a failure response", async () => {
      const queue = setup();
      queue.add([makeFile("one.jpg")]);

      const startPromise = queue.start();
      await Promise.resolve();
      await Promise.resolve();
      FakeXHR.instances[0].respond(422, { errors: ["Title can't be blank"] });
      await startPromise;

      expect(queue.items.value[0].status).toBe("error");
      expect(queue.items.value[0].errors).toEqual(["Title can't be blank"]);
    });

    it("falls back to a generic error when the failure response has no body", async () => {
      const queue = setup();
      queue.add([makeFile("one.jpg")]);

      const startPromise = queue.start();
      await Promise.resolve();
      await Promise.resolve();
      FakeXHR.instances[0].respond(500, undefined);
      await startPromise;

      expect(queue.items.value[0].status).toBe("error");
      expect(queue.items.value[0].errors).toEqual(["Upload failed (HTTP 500)"]);
    });

    it("treats invalid JSON on a 2xx response as an error", async () => {
      const queue = setup();
      queue.add([makeFile("one.jpg")]);

      const startPromise = queue.start();
      await Promise.resolve();
      await Promise.resolve();
      FakeXHR.instances[0].respond(201, "not json");
      await startPromise;

      expect(queue.items.value[0].status).toBe("error");
    });

    it("handles a network error", async () => {
      const queue = setup();
      queue.add([makeFile("one.jpg")]);

      const startPromise = queue.start();
      await Promise.resolve();
      await Promise.resolve();
      FakeXHR.instances[0].fail();
      await startPromise;

      expect(queue.items.value[0].status).toBe("error");
      expect(queue.items.value[0].errors).toEqual(["Network error"]);
    });
  });

  describe("stop", () => {
    it("aborts the in-flight request and puts the item back to pending", async () => {
      const queue = setup();
      queue.add([makeFile("one.jpg"), makeFile("two.jpg")]);

      const startPromise = queue.start();
      await Promise.resolve();
      await Promise.resolve();

      queue.stop();
      await startPromise;

      expect(FakeXHR.instances[0].aborted).toBe(true);
      expect(queue.items.value[0].status).toBe("pending");
      expect(queue.items.value[0].progress).toBe(0);
      expect(queue.items.value[1].status).toBe("pending");
      expect(queue.uploading.value).toBe(false);
    });
  });

  describe("retry", () => {
    it("moves an error item back to pending and clears its errors", async () => {
      const queue = setup();
      queue.add([makeFile("one.jpg")]);

      const startPromise = queue.start();
      await Promise.resolve();
      await Promise.resolve();
      FakeXHR.instances[0].respond(422, { errors: ["bad"] });
      await startPromise;

      queue.retry(queue.items.value[0]);
      expect(queue.items.value[0].status).toBe("pending");
      expect(queue.items.value[0].errors).toEqual([]);
    });

    it("does nothing for a non-error item", () => {
      const queue = setup();
      queue.add([makeFile("one.jpg")]);
      queue.retry(queue.items.value[0]);
      expect(queue.items.value[0].status).toBe("pending");
    });
  });

  describe("retryOne", () => {
    it("sends only the retried item, leaving other pending items untouched", async () => {
      const queue = setup();
      queue.add([makeFile("one.jpg")]);

      const startPromise = queue.start();
      await Promise.resolve();
      await Promise.resolve();
      FakeXHR.instances[0].respond(422, { errors: ["bad"] });
      await startPromise;

      // Added after the batch finished - never sent, still pending.
      queue.add([makeFile("two.jpg"), makeFile("three.jpg")]);

      queue.retryOne(queue.items.value[0]);
      await Promise.resolve();
      await Promise.resolve();

      // Only the retried item went out - not the other pending ones, which
      // uploadAll()'s full loop would have swept up too.
      expect(FakeXHR.instances).toHaveLength(2);
      expect(queue.items.value[1].status).toBe("pending");
      expect(queue.items.value[2].status).toBe("pending");

      FakeXHR.instances[1].respond(201, { photo: { id: "one" } });
      await Promise.resolve();
      await Promise.resolve();

      expect(queue.items.value[0].status).toBe("success");
      expect(queue.uploading.value).toBe(false);
      expect(FakeXHR.instances).toHaveLength(2); // still nothing else sent
    });

    it("just re-queues the item if something else is already uploading", async () => {
      const queue = setup();
      queue.add([makeFile("one.jpg"), makeFile("two.jpg")]);

      const startPromise = queue.start();
      await Promise.resolve();
      await Promise.resolve();
      FakeXHR.instances[0].respond(422, { errors: ["bad"] });
      await Promise.resolve();
      await Promise.resolve();
      // one.jpg failed; the loop moved straight on to two.jpg.
      expect(queue.items.value[1].status).toBe("uploading");

      queue.retryOne(queue.items.value[0]);
      expect(queue.items.value[0].status).toBe("pending");
      expect(FakeXHR.instances).toHaveLength(2); // no extra request fired

      FakeXHR.instances[1].respond(201, { photo: { id: "two" } });
      await Promise.resolve();
      await Promise.resolve();
      // one.jpg was re-queued as pending, so the still-running loop picks
      // it up next, on its own, once two.jpg is done.
      expect(FakeXHR.instances).toHaveLength(3);
      FakeXHR.instances[2].respond(201, { photo: { id: "one" } });

      await startPromise;
      expect(queue.items.value[0].status).toBe("success");
    });

    it("also sends a second item retried while the first retry is still in flight", async () => {
      const queue = setup();
      queue.add([makeFile("one.jpg"), makeFile("two.jpg")]);

      const startPromise = queue.start();
      await Promise.resolve();
      await Promise.resolve();
      FakeXHR.instances[0].respond(422, { errors: ["bad"] });
      await Promise.resolve();
      await Promise.resolve();
      FakeXHR.instances[1].respond(422, { errors: ["bad"] });
      await startPromise;
      expect(queue.items.value[0].status).toBe("error");
      expect(queue.items.value[1].status).toBe("error");

      queue.retryOne(queue.items.value[0]); // starts a standalone retry
      await Promise.resolve();
      await Promise.resolve();
      expect(FakeXHR.instances).toHaveLength(3);

      queue.retryOne(queue.items.value[1]); // clicked while the above is in flight
      expect(queue.items.value[1].status).toBe("pending");
      expect(FakeXHR.instances).toHaveLength(3); // not sent yet

      FakeXHR.instances[2].respond(201, { photo: { id: "one" } });
      await Promise.resolve();
      await Promise.resolve();

      // The still-running retry keeps going rather than stopping at one.
      expect(FakeXHR.instances).toHaveLength(4);
      FakeXHR.instances[3].respond(201, { photo: { id: "two" } });
      await Promise.resolve();
      await Promise.resolve();

      expect(queue.items.value[0].status).toBe("success");
      expect(queue.items.value[1].status).toBe("success");
      expect(queue.uploading.value).toBe(false);
    });

    it("does nothing for a non-error item", async () => {
      const queue = setup();
      queue.add([makeFile("one.jpg")]);
      await queue.retryOne(queue.items.value[0]);
      expect(FakeXHR.instances).toHaveLength(0);
    });
  });

  describe("revoking preview URLs", () => {
    it("revokes on remove", () => {
      const queue = setup();
      queue.add([makeFile("one.jpg")]);
      queue.remove(queue.items.value[0]);
      expect(URL.revokeObjectURL).toHaveBeenCalledWith("blob:fake");
      expect(queue.items.value).toHaveLength(0);
    });

    it("revokes only successful items on clearFinished, keeping errors", async () => {
      const queue = setup();
      queue.add([makeFile("one.jpg"), makeFile("two.jpg")]);

      const startPromise = queue.start();
      await Promise.resolve();
      await Promise.resolve();
      FakeXHR.instances[0].respond(201, { photo: { id: "one" } });
      await Promise.resolve();
      await Promise.resolve();
      FakeXHR.instances[1].respond(422, { errors: ["bad"] });
      await startPromise;

      queue.clearFinished();
      expect(queue.items.value).toHaveLength(1);
      expect(queue.items.value[0].name).toBe("two.jpg");
    });

    it("revokes all items on clearAll", () => {
      const queue = setup();
      queue.add([makeFile("one.jpg"), makeFile("two.jpg")]);
      queue.clearAll();
      expect(URL.revokeObjectURL).toHaveBeenCalledTimes(2);
      expect(queue.items.value).toHaveLength(0);
    });

    it("revokes remaining items when the scope is disposed", () => {
      const queue = setup();
      queue.add([makeFile("one.jpg")]);
      scope.stop();
      expect(URL.revokeObjectURL).toHaveBeenCalledWith("blob:fake");
    });
  });
});
