// Pure functions defining the /photos/search URL contract (#1101): every
// filter lives in the route query, so a search is shareable and
// shared/pagination.vue's additionalQueryParams carries it across pages.

const ARRAY_KEYS = ["tags", "excludeTags", "labels"];
const BOOLEAN_KEYS = [
  "noAlbum",
  "untagged",
  "noTitle",
  "noDescription",
  "unknownDate",
  "approximateDate",
  "scanned",
];
const STRING_KEYS = [
  "q",
  "tagsMode",
  "takenFrom",
  "takenTo",
  "postedFrom",
  "postedTo",
  "make",
  "model",
  "license",
  "album",
  "privacy",
  "sort",
  "dir",
];
const NUMBER_KEYS = ["isoMin", "isoMax", "fMin", "fMax", "flMin", "flMax"];

function toArray(value) {
  if (value === undefined || value === null) return [];
  return [].concat(value);
}

// route.query -> form state. Booleans come back as "1"/absent, numbers and
// arrays are parsed, everything else stays a string.
export function fromRouteQuery(query) {
  const state = {};

  STRING_KEYS.forEach((key) => {
    if (query[key] !== undefined && query[key] !== "") state[key] = query[key];
  });

  NUMBER_KEYS.forEach((key) => {
    if (query[key] === undefined || query[key] === "") return;
    const number = Number(query[key]);
    if (!Number.isNaN(number)) state[key] = number;
  });

  BOOLEAN_KEYS.forEach((key) => {
    state[key] = query[key] === "1";
  });

  ARRAY_KEYS.forEach((key) => {
    state[key] = toArray(query[key]).filter(Boolean);
  });

  return state;
}

// form state -> route.query. Defaults/blanks are dropped so the URL stays
// clean; arrays stay arrays (vue-router serializes as ?tags=a&tags=b).
export function toRouteQuery(state) {
  const query = {};

  STRING_KEYS.forEach((key) => {
    if (state[key]) query[key] = state[key];
  });

  NUMBER_KEYS.forEach((key) => {
    if (state[key] !== undefined && state[key] !== null && state[key] !== "") {
      query[key] = String(state[key]);
    }
  });

  BOOLEAN_KEYS.forEach((key) => {
    if (state[key]) query[key] = "1";
  });

  ARRAY_KEYS.forEach((key) => {
    const values = (state[key] || []).filter(Boolean);
    if (values.length > 0) query[key] = values;
  });

  return query;
}

// Whether there's enough here to run a search at all - a bare visit to
// /photos/search shouldn't fire a query with no filters.
export function hasSearch(state) {
  if (state.q) return true;
  if (ARRAY_KEYS.some((key) => (state[key] || []).length > 0)) return true;
  if (BOOLEAN_KEYS.some((key) => state[key])) return true;
  if (NUMBER_KEYS.some((key) => state[key] !== undefined && state[key] !== null)) return true;

  const scalarKeys = [
    "takenFrom",
    "takenTo",
    "postedFrom",
    "postedTo",
    "make",
    "model",
    "license",
    "album",
    "privacy",
  ];
  return scalarKeys.some((key) => !!state[key]);
}

// form state + page -> photoSearch's GraphQL variables
export function toVariables(state, page) {
  const filters = {};

  if (state.q) filters.query = state.q;
  if (state.tags?.length) filters.tags = state.tags;
  if (state.tagsMode) filters.tagsMode = state.tagsMode.toUpperCase();
  if (state.excludeTags?.length) filters.excludeTags = state.excludeTags;

  if (state.takenFrom) filters.takenAtFrom = state.takenFrom;
  if (state.takenTo) filters.takenAtTo = state.takenTo;
  if (state.postedFrom) filters.postedAtFrom = state.postedFrom;
  if (state.postedTo) filters.postedAtTo = state.postedTo;

  if (state.make) filters.cameraMake = state.make;
  if (state.model) filters.cameraModel = state.model;
  if (state.isoMin !== undefined) filters.isoMin = state.isoMin;
  if (state.isoMax !== undefined) filters.isoMax = state.isoMax;
  if (state.fMin !== undefined) filters.fNumberMin = state.fMin;
  if (state.fMax !== undefined) filters.fNumberMax = state.fMax;
  if (state.flMin !== undefined) filters.focalLengthMin = state.flMin;
  if (state.flMax !== undefined) filters.focalLengthMax = state.flMax;

  if (state.labels?.length) filters.labels = state.labels;

  if (state.license) filters.license = state.license;
  if (state.album) filters.albumId = state.album;
  if (state.privacy) filters.privacy = state.privacy.toUpperCase();

  if (state.noAlbum) filters.noAlbum = true;
  if (state.untagged) filters.untagged = true;
  if (state.noTitle) filters.noTitle = true;
  if (state.noDescription) filters.noDescription = true;
  if (state.unknownDate) filters.unknownDate = true;
  if (state.approximateDate) filters.approximateDate = true;
  if (state.scanned) filters.scanned = true;

  return {
    filters,
    sort: (state.sort || "relevance").toUpperCase(),
    direction: (state.dir || "desc").toUpperCase(),
    page,
  };
}

// Whether a single field of the form has a value worth highlighting - used
// to mark up which of a long form's fields actually did something, since
// it's easy to lose track of what you filled in. `sort`/`dir`/`tagsMode`
// are excluded: they always have a value (a default), so "filled in" isn't
// a meaningful distinction for them.
export function isFilled(state, key) {
  if (ARRAY_KEYS.includes(key)) return (state[key] || []).length > 0;
  if (BOOLEAN_KEYS.includes(key)) return !!state[key];
  if (NUMBER_KEYS.includes(key)) return state[key] !== undefined && state[key] !== null;
  return !!state[key];
}

function listAnd(words) {
  if (words.length <= 1) return words.join("");
  if (words.length === 2) return `${words[0]} and ${words[1]}`;
  return `${words.slice(0, -1).join(", ")}, and ${words[words.length - 1]}`;
}

function rangeClause(label, min, max, { prefix = "", suffix = "" } = {}) {
  if (min !== undefined && max !== undefined) {
    return `${label} between ${prefix}${min}${suffix} and ${prefix}${max}${suffix}`;
  }
  if (min !== undefined) return `${label} of at least ${prefix}${min}${suffix}`;
  return `${label} of at most ${prefix}${max}${suffix}`;
}

function dateRangeClause(label, from, to) {
  if (from && to) return `${label} between ${from} and ${to}`;
  if (from) return `${label} on or after ${from}`;
  return `${label} on or before ${to}`;
}

// A natural-language summary of the submitted filters, shown under the
// result count - it's easy to forget what a long form's URL actually asked
// for. `cameras`/`albums` are the option lists (with friendly names/titles)
// so the description doesn't have to show a bare slug or raw EXIF string.
export function describeSearch(state, { cameras = [], albums = [] } = {}) {
  const clauses = [];

  if (state.q) clauses.push(`matching "${state.q}"`);

  if (state.tags?.length) {
    clauses.push(`tagged with ${state.tagsMode === "any" ? "any of" : "all of"} ${listAnd(state.tags)}`);
  }
  if (state.excludeTags?.length) clauses.push(`not tagged with ${listAnd(state.excludeTags)}`);

  if (state.takenFrom || state.takenTo) clauses.push(dateRangeClause("taken", state.takenFrom, state.takenTo));
  if (state.postedFrom || state.postedTo) {
    clauses.push(dateRangeClause("posted", state.postedFrom, state.postedTo));
  }

  if (state.make || state.model) {
    const camera = cameras.find((c) => c.make === state.make && c.model === state.model);
    const name = camera ? camera.friendlyName : [state.make, state.model].filter(Boolean).join(" ");
    clauses.push(`shot on a ${name}`);
  }

  if (state.isoMin !== undefined || state.isoMax !== undefined) {
    clauses.push(rangeClause("an ISO", state.isoMin, state.isoMax));
  }
  if (state.fMin !== undefined || state.fMax !== undefined) {
    clauses.push(rangeClause("an f-number", state.fMin, state.fMax, { prefix: "f/" }));
  }
  if (state.flMin !== undefined || state.flMax !== undefined) {
    clauses.push(rangeClause("a focal length", state.flMin, state.flMax, { suffix: "mm" }));
  }

  if (state.labels?.length) clauses.push(`labeled ${listAnd(state.labels)}`);

  if (state.license) clauses.push(`licensed "${state.license}"`);

  if (state.noAlbum) {
    clauses.push("not in any album");
  } else if (state.album) {
    const album = albums.find((a) => a.id === state.album);
    clauses.push(`in the album "${album ? album.title : state.album}"`);
  }

  if (state.privacy) clauses.push(`with ${state.privacy.replace(/_/g, " ")} privacy`);

  if (state.untagged) clauses.push("with no tags");
  if (state.noTitle) clauses.push("with no title");
  if (state.noDescription) clauses.push("with no description");
  if (state.unknownDate) clauses.push("with an unknown date");
  if (state.approximateDate) clauses.push("with an approximate date");
  if (state.scanned) clauses.push("that are scanned");

  if (clauses.length === 0) return "";

  return `Photos ${listAnd(clauses)}.`;
}
