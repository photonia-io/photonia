import { ref } from "vue";

const noTitle = "(no title)";

// object can be a ref or reactive photo or album object
const titleHelper = (object, loading = ref(false)) =>
  loading.value ? "Loading..." : object.value.title || noTitle;

export default titleHelper;
