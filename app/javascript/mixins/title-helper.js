const noTitle = "(no title)";

/**
 * Helper function to get the title of a photo or album
 * @param {import('vue').Ref<{id?: string, title?: string}>} object - Ref containing photo or album object
 * @returns {string} The title, "(no title)" if empty, or "" if there is no data yet
 */
const titleHelper = (object) => {
  const value = object.value;
  if (!value?.id) return "";
  return value.title || noTitle;
};

export default titleHelper;
