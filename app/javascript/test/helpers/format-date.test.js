import { describe, it, expect } from "vitest";

import { formatDateTime } from "../../helpers/format-date.js";

describe("formatDateTime", () => {
  it("formats the full precision like the old moment format", () => {
    expect(formatDateTime(new Date(1985, 7, 31, 17, 5), "full")).toBe(
      "Saturday, August 31st 1985, 17:05",
    );
  });

  it("pads minutes but not hours", () => {
    expect(formatDateTime(new Date(2024, 0, 1, 5, 5), "full")).toBe(
      "Monday, January 1st 2024, 5:05",
    );
  });

  it("formats day precision without a time", () => {
    expect(formatDateTime(new Date(1985, 7, 31), "day")).toBe(
      "Saturday, August 31st 1985",
    );
  });

  it("formats month precision", () => {
    expect(formatDateTime(new Date(1985, 7), "month")).toBe("August 1985");
  });

  it("formats year precision", () => {
    expect(formatDateTime(new Date(1985, 0), "year")).toBe("1985");
  });

  it.each([
    [1, "1st"],
    [2, "2nd"],
    [3, "3rd"],
    [4, "4th"],
    [11, "11th"],
    [12, "12th"],
    [13, "13th"],
    [21, "21st"],
    [22, "22nd"],
    [23, "23rd"],
    [24, "24th"],
    [31, "31st"],
  ])("gives day %i the ordinal suffix %s", (day, expected) => {
    expect(formatDateTime(new Date(2024, 0, day), "day")).toContain(expected);
  });

  it("accepts an ISO string parsed into a Date", () => {
    expect(formatDateTime(new Date("2024-01-02T00:00:00Z"), "full")).toMatch(
      /^\w+, January \d+\w{2} 2024, \d{1,2}:\d{2}$/,
    );
  });
});
