import { ref } from "vue";

const photoTitle = (photo, loading = ref(false)) => {
  const noTitle = "(no title)";
  return loading.value ? "Loading..." : photo.value.title || noTitle;
};

export default photoTitle;
