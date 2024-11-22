import { ref } from "vue";

const noTitle = "(no title)";

const photoTitle = (photo, loading = ref(false)) =>
  loading.value ? "Loading..." : photo.value.title || noTitle;

export default photoTitle;
