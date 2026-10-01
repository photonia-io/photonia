import { describe, it, expect, vi } from "vitest";
import { mount, RouterLinkStub } from "@vue/test-utils";

vi.mock("vue-page-title", () => ({ useTitle: vi.fn() }));

import AdminIndex from "../../admin/index.vue";

const mountAdmin = (routeName) =>
  mount(AdminIndex, {
    global: {
      mocks: { $route: { name: routeName } },
      stubs: { RouterLink: RouterLinkStub, RouterView: true },
    },
  });

describe("Admin index", () => {
  it("has a Homepage tab between General and Comments", () => {
    const tabs = mountAdmin("admin-general")
      .findAll(".tabs li")
      .map((tab) => tab.text());

    expect(tabs).toEqual(["General", "Homepage", "Comments", "System", "Users"]);
  });

  it("marks the tab of the current route as active", () => {
    const active = mountAdmin("admin-homepage").findAll(".tabs li.is-active");

    expect(active).toHaveLength(1);
    expect(active[0].text()).toBe("Homepage");
  });
});
