<template>
  <teleport to="#modal-root">
    <div :class="['modal', isActive ? 'is-active' : null]">
      <div class="modal-background" @click="close"></div>
      <div class="modal-card">
        <header class="modal-card-head">
          <p class="modal-card-title">Creative Commons Licenses</p>
          <button class="delete" aria-label="close" @click="close"></button>
        </header>
        <section class="modal-card-body">
          <div class="content">
            <p class="mb-4">
              Creative Commons licenses provide a standardized way to grant
              copyright permissions to your creative work. Here's what each
              license means:
            </p>

            <div
              class="license-info mb-4"
              :class="{ 'is-current': currentLicense === 'CC BY 4.0' }"
            >
              <h3 class="license-title">CC BY 4.0 - Attribution</h3>
              <p>
                Others can copy, distribute, remix, and build upon your work,
                even commercially, as long as they credit you for the original
                creation. This is the most accommodating license offered.
              </p>
            </div>

            <div
              class="license-info mb-4"
              :class="{ 'is-current': currentLicense === 'CC BY-SA 4.0' }"
            >
              <h3 class="license-title">
                CC BY-SA 4.0 - Attribution-ShareAlike
              </h3>
              <p>
                Others can remix, adapt, and build upon your work even for
                commercial purposes, as long as they credit you and license
                their new creations under identical terms.
              </p>
            </div>

            <div
              class="license-info mb-4"
              :class="{ 'is-current': currentLicense === 'CC BY-ND 4.0' }"
            >
              <h3 class="license-title">
                CC BY-ND 4.0 - Attribution-NoDerivatives
              </h3>
              <p>
                Others can copy and distribute your work in its original form
                only, even commercially, but they cannot create derivative works
                based on it.
              </p>
            </div>

            <div
              class="license-info mb-4"
              :class="{ 'is-current': currentLicense === 'CC BY-NC 4.0' }"
            >
              <h3 class="license-title">
                CC BY-NC 4.0 - Attribution-NonCommercial
              </h3>
              <p>
                Others can remix, adapt, and build upon your work
                non-commercially. Their new works must also acknowledge you and
                be non-commercial, but they don't have to license their
                derivative works on the same terms.
              </p>
            </div>

            <div
              class="license-info mb-4"
              :class="{ 'is-current': currentLicense === 'CC BY-NC-SA 4.0' }"
            >
              <h3 class="license-title">
                CC BY-NC-SA 4.0 - Attribution-NonCommercial-ShareAlike
              </h3>
              <p>
                Others can remix, adapt, and build upon your work
                non-commercially, as long as they credit you and license their
                new creations under identical terms.
              </p>
            </div>

            <div
              class="license-info mb-4"
              :class="{ 'is-current': currentLicense === 'CC BY-NC-ND 4.0' }"
            >
              <h3 class="license-title">
                CC BY-NC-ND 4.0 - Attribution-NonCommercial-NoDerivatives
              </h3>
              <p>
                This is the most restrictive license. It only allows others to
                download your works and share them with others as long as they
                credit you, but they can't change them in any way or use them
                commercially.
              </p>
            </div>

            <div
              class="license-info mb-4"
              :class="{ 'is-current': currentLicense === 'CC0 1.0' }"
            >
              <h3 class="license-title">CC0 1.0 - Public Domain Dedication</h3>
              <p>
                You waive all your rights to the work worldwide under copyright
                law, including all related and neighboring rights, to the extent
                allowed by law. Others can copy, modify, distribute and perform
                the work, even for commercial purposes, all without asking
                permission.
              </p>
            </div>

            <div class="notification is-info is-light">
              <p>
                <strong>Learn more:</strong> Visit
                <a
                  href="https://creativecommons.org/share-your-work/cclicenses/"
                  target="_blank"
                  rel="noopener noreferrer"
                  >creativecommons.org</a
                >
                for detailed information about Creative Commons licenses.
              </p>
            </div>
          </div>
        </section>
        <footer class="modal-card-foot">
          <button class="button" @click="close">Close</button>
        </footer>
      </div>
    </div>
  </teleport>
</template>

<script setup>
import { computed } from "vue";

const props = defineProps({
  modelValue: {
    type: Boolean,
    required: true,
  },
  currentLicense: {
    type: String,
    default: "",
  },
});

const emit = defineEmits(["update:modelValue"]);

const isActive = computed(() => props.modelValue);

const close = () => {
  emit("update:modelValue", false);
};
</script>

<style scoped>
.license-info {
  padding-left: 1rem;
  padding-top: 1rem;
  padding-bottom: 1rem;
  border-left: 3px solid #f5f5f5;
  transition: all 0.2s ease;
}

.license-title {
  font-size: 1.25rem;
  margin-bottom: 0.5rem;
}

.license-info.is-current {
  background-color: #eff5fb;
  border-left-color: #3273dc;
  border-radius: 4px;
  padding-right: 1rem;
  box-shadow: 0 2px 4px rgba(50, 115, 220, 0.1);
}

.license-info.is-current .license-title {
  color: #3273dc;
}

.modal-card {
  max-width: 800px;
}

.modal-card-body {
  max-height: calc(100vh - 200px);
  overflow-y: auto;
}
</style>
