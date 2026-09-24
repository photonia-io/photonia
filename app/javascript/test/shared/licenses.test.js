import { describe, it, expect } from "vitest";

import {
  LICENSE_OPTIONS,
  ALL_RIGHTS_RESERVED,
  licenseDisplay,
} from "../../shared/licenses.js";

describe("licenseDisplay", () => {
  it("returns All Rights Reserved for a blank value", () => {
    expect(licenseDisplay(null).value).toBe(ALL_RIGHTS_RESERVED);
    expect(licenseDisplay(undefined).value).toBe(ALL_RIGHTS_RESERVED);
    expect(licenseDisplay("").value).toBe(ALL_RIGHTS_RESERVED);
  });

  it("returns the matching option for a known license", () => {
    const display = licenseDisplay("CC BY-SA 4.0");

    expect(display.label).toBe("CC BY-SA 4.0");
    expect(display.url).toBe("https://creativecommons.org/licenses/by-sa/4.0/");
    expect(display.icons.length).toBeGreaterThan(1);
  });

  it("falls back to the raw string with no icons for an unrecognized legacy value", () => {
    const display = licenseDisplay("Some old Flickr license");

    expect(display.label).toBe("Some old Flickr license");
    expect(display.icons).toEqual([]);
    expect(display.url).toBeUndefined();
  });

  it("lists every value exactly once", () => {
    const values = LICENSE_OPTIONS.map((option) => option.value);
    expect(new Set(values).size).toBe(values.length);
    expect(values).toContain(ALL_RIGHTS_RESERVED);
  });
});
