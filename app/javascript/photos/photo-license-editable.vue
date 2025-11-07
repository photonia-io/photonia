<template>
  <div class="field is-horizontal">
    <div class="field-label is-normal">
      <label class="label">License</label>
    </div>
    <div class="field-body">
      <div class="field is-expanded">
        <div class="control">
          <div class="select is-fullwidth">
            <select v-model="localLicense" @change="updateLicense">
              <option value="">None</option>
              <option value="CC BY 4.0">CC BY 4.0 - Attribution</option>
              <option value="CC BY-SA 4.0">CC BY-SA 4.0 - Attribution-ShareAlike</option>
              <option value="CC BY-ND 4.0">CC BY-ND 4.0 - Attribution-NoDerivatives</option>
              <option value="CC BY-NC 4.0">CC BY-NC 4.0 - Attribution-NonCommercial</option>
              <option value="CC BY-NC-SA 4.0">CC BY-NC-SA 4.0 - Attribution-NonCommercial-ShareAlike</option>
              <option value="CC BY-NC-ND 4.0">CC BY-NC-ND 4.0 - Attribution-NonCommercial-NoDerivatives</option>
              <option value="CC0 1.0">CC0 1.0 - Public Domain Dedication</option>
              <option value="Public Domain">Public Domain</option>
            </select>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, toRefs, watch } from "vue";

const props = defineProps({
  photo: {
    type: Object,
    required: true,
  },
});

const { photo } = toRefs(props);

const emit = defineEmits(["updateLicense"]);

const localLicense = ref(photo.value.license || "");

watch(photo, (newPhoto) => {
  localLicense.value = newPhoto.license || "";
});

const updateLicense = () => {
  emit("updateLicense", { id: photo.value.id, license: localLicense.value });
};
</script>
