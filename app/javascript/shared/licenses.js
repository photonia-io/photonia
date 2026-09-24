// Single source of truth for the license picker (photo licenses and the
// user's default) and for how a license value is displayed. Keep this in
// sync with License::VALUES in app/models/license.rb.
export const ALL_RIGHTS_RESERVED = "All Rights Reserved";

export const LICENSE_OPTIONS = [
  {
    value: ALL_RIGHTS_RESERVED,
    label: "All Rights Reserved",
    icons: ["fas fa-copyright"],
    description:
      "No permissions beyond viewing are granted. All rights are reserved by the photographer.",
    url: null,
  },
  {
    value: "CC BY 4.0",
    label: "CC BY 4.0",
    name: "Attribution",
    icons: ["fab fa-creative-commons", "fab fa-creative-commons-by"],
    description:
      "May be copied, distributed, remixed, and built upon, even commercially, as long as credit is given to the photographer.",
    url: "https://creativecommons.org/licenses/by/4.0/",
  },
  {
    value: "CC BY-SA 4.0",
    label: "CC BY-SA 4.0",
    name: "Attribution-ShareAlike",
    icons: [
      "fab fa-creative-commons",
      "fab fa-creative-commons-by",
      "fab fa-creative-commons-sa",
    ],
    description:
      "May be remixed and built upon, even commercially, as long as credit is given and new creations are licensed under identical terms.",
    url: "https://creativecommons.org/licenses/by-sa/4.0/",
  },
  {
    value: "CC BY-ND 4.0",
    label: "CC BY-ND 4.0",
    name: "Attribution-NoDerivatives",
    icons: [
      "fab fa-creative-commons",
      "fab fa-creative-commons-by",
      "fab fa-creative-commons-nd",
    ],
    description:
      "May be copied and redistributed in its original, unmodified form, even commercially, as long as credit is given.",
    url: "https://creativecommons.org/licenses/by-nd/4.0/",
  },
  {
    value: "CC BY-NC 4.0",
    label: "CC BY-NC 4.0",
    name: "Attribution-NonCommercial",
    icons: [
      "fab fa-creative-commons",
      "fab fa-creative-commons-by",
      "fab fa-creative-commons-nc",
    ],
    description:
      "May be remixed and built upon for non-commercial purposes, as long as credit is given.",
    url: "https://creativecommons.org/licenses/by-nc/4.0/",
  },
  {
    value: "CC BY-NC-SA 4.0",
    label: "CC BY-NC-SA 4.0",
    name: "Attribution-NonCommercial-ShareAlike",
    icons: [
      "fab fa-creative-commons",
      "fab fa-creative-commons-by",
      "fab fa-creative-commons-nc",
      "fab fa-creative-commons-sa",
    ],
    description:
      "May be remixed and built upon for non-commercial purposes, as long as credit is given and new creations are licensed under identical terms.",
    url: "https://creativecommons.org/licenses/by-nc-sa/4.0/",
  },
  {
    value: "CC BY-NC-ND 4.0",
    label: "CC BY-NC-ND 4.0",
    name: "Attribution-NonCommercial-NoDerivatives",
    icons: [
      "fab fa-creative-commons",
      "fab fa-creative-commons-by",
      "fab fa-creative-commons-nc",
      "fab fa-creative-commons-nd",
    ],
    description:
      "The most restrictive CC license. May be downloaded and shared as long as credit is given, but not changed or used commercially.",
    url: "https://creativecommons.org/licenses/by-nc-nd/4.0/",
  },
  {
    value: "CC0 1.0",
    label: "CC0 1.0",
    name: "Public Domain Dedication",
    icons: ["fab fa-creative-commons", "fab fa-creative-commons-zero"],
    description:
      "The photographer has waived all rights to this photo, to the extent allowed by law. It may be copied, modified, and distributed, even commercially, without asking permission.",
    url: "https://creativecommons.org/publicdomain/zero/1.0/",
  },
];

const LICENSE_BY_VALUE = Object.fromEntries(
  LICENSE_OPTIONS.map((option) => [option.value, option]),
);

// A blank license (nothing picked yet, or a photo predating this feature)
// is legally equivalent to All Rights Reserved, so it displays as such. Any
// other value that isn't in the list is a legacy string (Flickr import) -
// still displayed, just without an icon or a deed link.
export function licenseDisplay(value) {
  if (!value) return LICENSE_BY_VALUE[ALL_RIGHTS_RESERVED];
  return LICENSE_BY_VALUE[value] ?? { value, label: value, icons: [] };
}
