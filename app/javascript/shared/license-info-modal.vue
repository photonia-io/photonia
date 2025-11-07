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

            <div class="license-info mb-4">
              <h3 class="title is-5">
                <span class="icon-text">
                  <span class="icon has-text-success">
                    <i class="fas fa-creative-commons"></i>
                  </span>
                  <span>CC BY 4.0 - Attribution</span>
                </span>
              </h3>
              <p>
                Others can copy, distribute, remix, and build upon your work,
                even commercially, as long as they credit you for the original
                creation. This is the most accommodating license offered.
              </p>
            </div>

            <div class="license-info mb-4">
              <h3 class="title is-5">
                <span class="icon-text">
                  <span class="icon has-text-success">
                    <i class="fas fa-creative-commons"></i>
                  </span>
                  <span>CC BY-SA 4.0 - Attribution-ShareAlike</span>
                </span>
              </h3>
              <p>
                Others can remix, adapt, and build upon your work even for
                commercial purposes, as long as they credit you and license
                their new creations under identical terms.
              </p>
            </div>

            <div class="license-info mb-4">
              <h3 class="title is-5">
                <span class="icon-text">
                  <span class="icon has-text-info">
                    <i class="fas fa-creative-commons"></i>
                  </span>
                  <span>CC BY-ND 4.0 - Attribution-NoDerivatives</span>
                </span>
              </h3>
              <p>
                Others can copy and distribute your work in its original form
                only, even commercially, but they cannot create derivative works
                based on it.
              </p>
            </div>

            <div class="license-info mb-4">
              <h3 class="title is-5">
                <span class="icon-text">
                  <span class="icon has-text-warning">
                    <i class="fas fa-creative-commons"></i>
                  </span>
                  <span>CC BY-NC 4.0 - Attribution-NonCommercial</span>
                </span>
              </h3>
              <p>
                Others can remix, adapt, and build upon your work
                non-commercially. Their new works must also acknowledge you and
                be non-commercial, but they don't have to license their
                derivative works on the same terms.
              </p>
            </div>

            <div class="license-info mb-4">
              <h3 class="title is-5">
                <span class="icon-text">
                  <span class="icon has-text-warning">
                    <i class="fas fa-creative-commons"></i>
                  </span>
                  <span>CC BY-NC-SA 4.0 - Attribution-NonCommercial-ShareAlike</span>
                </span>
              </h3>
              <p>
                Others can remix, adapt, and build upon your work
                non-commercially, as long as they credit you and license their
                new creations under identical terms.
              </p>
            </div>

            <div class="license-info mb-4">
              <h3 class="title is-5">
                <span class="icon-text">
                  <span class="icon has-text-danger">
                    <i class="fas fa-creative-commons"></i>
                  </span>
                  <span>CC BY-NC-ND 4.0 - Attribution-NonCommercial-NoDerivatives</span>
                </span>
              </h3>
              <p>
                This is the most restrictive license. It only allows others to
                download your works and share them with others as long as they
                credit you, but they can't change them in any way or use them
                commercially.
              </p>
            </div>

            <div class="license-info mb-4">
              <h3 class="title is-5">
                <span class="icon-text">
                  <span class="icon has-text-link">
                    <i class="fas fa-universal-access"></i>
                  </span>
                  <span>CC0 1.0 - Public Domain Dedication</span>
                </span>
              </h3>
              <p>
                You waive all your rights to the work worldwide under copyright
                law, including all related and neighboring rights, to the extent
                allowed by law. Others can copy, modify, distribute and perform
                the work, even for commercial purposes, all without asking
                permission.
              </p>
            </div>

            <div class="license-info mb-4">
              <h3 class="title is-5">
                <span class="icon-text">
                  <span class="icon has-text-link">
                    <i class="fas fa-globe"></i>
                  </span>
                  <span>Public Domain</span>
                </span>
              </h3>
              <p>
                The work is not protected by copyright and may be freely used by
                anyone for any purpose without restriction.
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
  border-left: 3px solid #f5f5f5;
}

.modal-card {
  max-width: 800px;
}

.modal-card-body {
  max-height: calc(100vh - 200px);
  overflow-y: auto;
}
</style>
