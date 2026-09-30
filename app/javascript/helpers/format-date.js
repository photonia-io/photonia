// A drop-in for the one moment.js format string this app used
// ("dddd, MMMM Do YYYY, H:mm" and its year/month/day precision variants,
// see #1096), built on Intl instead of bundling the whole library.

const WEEKDAY_MONTH_DAY_YEAR = new Intl.DateTimeFormat("en-US", {
  weekday: "long",
  month: "long",
  day: "numeric",
  year: "numeric",
});
const MONTH_YEAR = new Intl.DateTimeFormat("en-US", {
  month: "long",
  year: "numeric",
});
const YEAR = new Intl.DateTimeFormat("en-US", { year: "numeric" });
const ORDINALS = new Intl.PluralRules("en-US", { type: "ordinal" });

const ORDINAL_SUFFIXES = { one: "st", two: "nd", few: "rd", other: "th" };

function ordinal(day) {
  return `${day}${ORDINAL_SUFFIXES[ORDINALS.select(day)]}`;
}

// Intl's en-US long format puts a comma before the year ("Saturday, August
// 31, 1985"); moment's "dddd, MMMM Do YYYY" didn't ("Saturday, August 31st
// 1985"). Walk the parts so only that one comma is dropped and the day gets
// its ordinal suffix, without depending on the exact formatted string.
function withOrdinalDay(date, formatter) {
  const parts = formatter.formatToParts(date);
  let result = "";
  for (let i = 0; i < parts.length; i++) {
    const part = parts[i];
    if (part.type === "day") {
      result += ordinal(Number(part.value));
    } else if (part.type === "literal" && parts[i - 1]?.type === "day") {
      result += " ";
    } else {
      result += part.value;
    }
  }
  return result;
}

function timeOfDay(date) {
  const hour = date.getHours();
  const minute = String(date.getMinutes()).padStart(2, "0");
  return `${hour}:${minute}`;
}

// precision: "year" | "month" | "day" | "full" (default)
export function formatDateTime(date, precision = "full") {
  switch (precision) {
    case "year":
      return YEAR.format(date);
    case "month":
      return MONTH_YEAR.format(date);
    case "day":
      return withOrdinalDay(date, WEEKDAY_MONTH_DAY_YEAR);
    default:
      return `${withOrdinalDay(date, WEEKDAY_MONTH_DAY_YEAR)}, ${timeOfDay(date)}`;
  }
}
