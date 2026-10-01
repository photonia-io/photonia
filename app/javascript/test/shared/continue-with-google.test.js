import ContinueWithGoogle from "@/shared/buttons/continue-with-google.vue";
import { mount } from "@vue/test-utils";

afterEach(() => {
  delete window.google;
  delete window.continueWithGoogle;
});

const stubGoogle = () => {
  const id = { initialize: vi.fn(), renderButton: vi.fn() };
  window.google = { accounts: { id } };
  return id;
};

test("initializes Google sign-in and exposes the callback globally", () => {
  const id = stubGoogle();
  const onContinue = vi.fn();

  const wrapper = mount(ContinueWithGoogle, {
    props: { clientId: "client-123", onContinue },
  });

  expect(id.initialize).toHaveBeenCalledWith({
    client_id: "client-123",
    callback: onContinue,
    ux_mode: "popup",
  });
  expect(window.continueWithGoogle).toBe(onContinue);

  wrapper.unmount();
  expect(window.continueWithGoogle).toBeUndefined();
});

test("loads the Google script and initializes once it loads", () => {
  const append = vi
    .spyOn(document.body, "appendChild")
    .mockImplementation((node) => node);

  const onContinue = vi.fn();
  const wrapper = mount(ContinueWithGoogle, {
    props: { clientId: "client-123", onContinue },
  });

  const script = append.mock.calls[0][0];
  expect(script.src).toBe("https://accounts.google.com/gsi/client");

  const id = stubGoogle();
  script.onload();
  expect(id.initialize).toHaveBeenCalled();

  append.mockRestore();
  wrapper.unmount();
});
