// Single source of truth for the album share modal's radio options. Keep in
// sync with the share_mode enum in app/models/album.rb.
export const SHARE_MODE_OPTIONS = [
  {
    value: "off",
    label: "Off",
    icon: "fas fa-ban",
    description: "The share link doesn't work.",
  },
  {
    value: "public_photos",
    label: "Public photos only",
    icon: "fas fa-globe",
    description:
      "The link opens the album - even if it's private - but only shows its public photos.",
  },
  {
    value: "all_photos",
    label: "All photos",
    icon: "fas fa-unlock",
    description:
      "The link also shows this album's private and friends & family photos.",
  },
];
