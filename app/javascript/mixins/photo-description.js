import { ref } from "vue";

const noDescription = "(no description)";

const photoDescription = (photo, loading = ref(false)) =>
  loading.value ? "Loading..." : photo.value.description || noDescription;

const photoDescriptionHtml = (photo, loading = ref(false)) =>
  loading.value ? "Loading..." : photo.value.descriptionHtml || noDescription;

export { photoDescription, photoDescriptionHtml };
