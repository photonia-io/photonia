import { vi } from "vitest";

// Minimal XMLHttpRequest stand-in for tests that drive use-upload-queue's
// XHR-based transport. Tracks the instances created so a test can find the
// one it wants to respond to.
export class FakeXHR {
  static instances = [];

  constructor() {
    this.method = null;
    this.url = null;
    this.headers = {};
    this.body = null;
    this.status = 0;
    this.responseText = "";
    this.upload = {};
    this.aborted = false;
    FakeXHR.instances.push(this);
  }

  open(method, url) {
    this.method = method;
    this.url = url;
  }

  setRequestHeader(name, value) {
    this.headers[name] = value;
  }

  send(body) {
    this.body = body;
  }

  abort() {
    this.aborted = true;
    this.onabort?.();
  }

  progress(loaded, total) {
    this.upload.onprogress?.({ lengthComputable: true, loaded, total });
  }

  respond(status, body) {
    this.status = status;
    this.responseText =
      body === undefined ? "" : typeof body === "string" ? body : JSON.stringify(body);
    this.onload?.();
  }

  fail() {
    this.onerror?.();
  }
}

export function installFakeXHR() {
  FakeXHR.instances = [];
  vi.stubGlobal("XMLHttpRequest", FakeXHR);
}
