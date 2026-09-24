const noDescription = "(no description)";

const descriptionHelper = (object) => {
  const value = object.value;
  if (!value?.id) return "";
  return value.description || noDescription;
};

const descriptionHtmlHelper = (object) => {
  const value = object.value;
  if (!value?.id) return "";
  return value.descriptionHtml || noDescription;
};

export { descriptionHelper, descriptionHtmlHelper };
