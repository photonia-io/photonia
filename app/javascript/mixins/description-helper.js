import { ref } from "vue";

const noDescription = "(no description)";

const descriptionHelper = (object, loading = ref(false)) =>
  loading.value ? "Loading..." : object.value.description || noDescription;

const descriptionHtmlHelper = (object, loading = ref(false)) =>
  loading.value ? "Loading..." : object.value.descriptionHtml || noDescription;

export { descriptionHelper, descriptionHtmlHelper };
