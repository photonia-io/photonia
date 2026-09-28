import { describe, it, expect, afterEach } from "vitest";
import { mount } from "@vue/test-utils";
import { createPinia, setActivePinia } from "pinia";

import CommentForm from "../../../shared/comments/comment-form.vue";
import { useApplicationStore } from "../../../stores/application";

let wrapper;

function mountForm(props = {}) {
  const pinia = createPinia();
  setActivePinia(pinia);

  wrapper = mount(CommentForm, {
    global: { plugins: [pinia] },
    props,
  });
  return wrapper;
}

afterEach(() => {
  wrapper?.unmount();
});

describe("CommentForm", () => {
  it("disables submit until there is a non-blank draft", async () => {
    mountForm();
    const submitButton = wrapper.find("button.is-primary");
    expect(submitButton.attributes("disabled")).toBeDefined();

    await wrapper.find("textarea").setValue("   ");
    expect(submitButton.attributes("disabled")).toBeDefined();

    await wrapper.find("textarea").setValue("Hello");
    expect(submitButton.attributes("disabled")).toBeUndefined();
  });

  it("emits submit with the draft body when clicked", async () => {
    mountForm();
    await wrapper.find("textarea").setValue("A comment");

    await wrapper.find("button.is-primary").trigger("click");

    expect(wrapper.emitted().submit[0]).toEqual(["A comment"]);
  });

  it("only shows a Cancel button when showCancel is true", () => {
    mountForm({ showCancel: false });
    expect(wrapper.findAll("button").some((b) => b.text() === "Cancel")).toBe(false);

    mountForm({ showCancel: true });
    expect(wrapper.findAll("button").some((b) => b.text() === "Cancel")).toBe(true);
  });

  it("emits cancel when Cancel is clicked", async () => {
    mountForm({ showCancel: true });

    await wrapper.findAll("button").find((b) => b.text() === "Cancel").trigger("click");

    expect(wrapper.emitted().cancel).toBeTruthy();
  });

  it("starts editing (blocking navigation) once the draft becomes non-empty, and stops when it's cleared", async () => {
    mountForm();
    const applicationStore = useApplicationStore();
    expect(applicationStore.editing).toBe(false);

    await wrapper.find("textarea").setValue("Something");
    expect(applicationStore.editing).toBe(true);

    await wrapper.find("textarea").setValue("");
    expect(applicationStore.editing).toBe(false);
  });

  it("starts editing immediately when mounted with a pre-filled draft (edit mode)", () => {
    mountForm({ initialBody: "Existing body" });
    const applicationStore = useApplicationStore();

    expect(applicationStore.editing).toBe(true);
  });

  it("stops editing when the form unmounts with an unsaved draft", async () => {
    mountForm();
    const applicationStore = useApplicationStore();
    await wrapper.find("textarea").setValue("Draft");
    expect(applicationStore.editing).toBe(true);

    wrapper.unmount();

    expect(applicationStore.editing).toBe(false);
  });

  it("shows a loading state and disables submit while busy", () => {
    mountForm({ initialBody: "Ready to send", busy: true });

    const submitButton = wrapper.find("button.is-primary");
    expect(submitButton.classes()).toContain("is-loading");
    expect(submitButton.attributes("disabled")).toBeDefined();
  });
});
