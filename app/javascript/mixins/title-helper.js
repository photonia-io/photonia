import { ref } from "vue";

const noTitle = "(no title)";

/**
 * Helper function to get the title of a photo or album
 * @param {import('vue').Ref<{title?: string}>} object - Ref containing photo or album object
 * @param {import('vue').Ref<boolean>} [loading] - Optional loading state
 * @returns {string} The title, "(no title)" if empty, or "Loading..." if loading
 */
const defaultLoading = ref(false);
const titleHelper = (object, loading = defaultLoading) =>
  loading.value ? "Loading..." : object.value.title || noTitle;

export default titleHelper;
