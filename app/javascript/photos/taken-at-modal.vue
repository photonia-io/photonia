<template>
  <teleport to="#modal-root">
    <div :class="['modal', active ? 'is-active' : null]">
      <div class="modal-background"></div>
      <div
        ref="modalCard"
        class="modal-card"
        role="dialog"
        aria-modal="true"
        aria-label="Photo Date Taken"
        tabindex="-1"
      >
        <header class="modal-card-head">
          <p class="modal-card-title has-text-centered">Date Taken</p>
        </header>
        <div class="modal-card-body">
          <p class="mb-4">
            Enter as much of the date as you know — year alone is fine.
          </p>
          <div class="taken-at-date-fields">
            <div class="field">
              <label class="label" for="taken-at-year">Year</label>
              <div class="control">
                <input
                  id="taken-at-year"
                  type="number"
                  class="input"
                  v-model.number="year"
                />
              </div>
            </div>
            <div class="field">
              <label class="label" for="taken-at-month">Month</label>
              <div class="control">
                <div class="select is-fullwidth">
                  <select id="taken-at-month" v-model.number="month">
                    <option value="">— Unknown —</option>
                    <option
                      v-for="(name, index) in MONTH_NAMES"
                      :key="name"
                      :value="index + 1"
                    >
                      {{ name }}
                    </option>
                  </select>
                </div>
              </div>
            </div>
            <div class="field">
              <label class="label" for="taken-at-day">Day</label>
              <div class="control">
                <div class="select is-fullwidth">
                  <select
                    id="taken-at-day"
                    v-model.number="day"
                    :disabled="month === UNKNOWN"
                  >
                    <option value="">— Unknown —</option>
                    <option v-for="d in dayOptions" :key="d" :value="d">
                      {{ d }}
                    </option>
                  </select>
                </div>
              </div>
            </div>
          </div>
          <div class="field">
            <label class="checkbox">
              <input
                type="checkbox"
                v-model="hasTime"
                :disabled="day === UNKNOWN"
              />
              Set time of day
            </label>
          </div>
          <div v-if="hasTime" class="field is-grouped">
            <div class="control">
              <label class="label" for="taken-at-hour">Hour</label>
              <input
                id="taken-at-hour"
                type="number"
                min="0"
                max="23"
                class="input"
                v-model.number="hour"
              />
            </div>
            <div class="control">
              <label class="label" for="taken-at-minute">Minute</label>
              <input
                id="taken-at-minute"
                type="number"
                min="0"
                max="59"
                class="input"
                v-model.number="minute"
              />
            </div>
          </div>
          <div class="field">
            <label class="checkbox">
              <input type="checkbox" v-model="approximate" />
              This date is approximate
            </label>
          </div>
          <div class="field">
            <label class="checkbox">
              <input type="checkbox" v-model="scannedLocal" />
              This is a scan of a print or negative
            </label>
          </div>
          <template v-if="showReset">
            <hr />
            <p class="mb-4">
              You have set a custom date for this photo previously. Use the
              button below to reset it to the {{ resetSource }} date.
            </p>
            <button class="button is-light" @click="reset">
              {{ resetLabel }}
            </button>
          </template>
        </div>
        <footer class="modal-card-foot is-justify-content-center">
          <button class="button is-primary" @click="save">Set Date</button>
          <button class="button is-info" @click="close">Cancel</button>
        </footer>
      </div>
    </div>
  </teleport>
</template>

<script setup>
import { computed, ref, watch } from "vue";
import { useModal } from "../mixins/use-modal.js";

const props = defineProps({
  active: {
    type: Boolean,
    required: true,
  },
  takenAtInfo: {
    type: Object,
    default: null,
  },
  scanned: {
    type: Boolean,
    required: true,
  },
});

const emit = defineEmits(["save", "reset", "close"]);

const MONTH_NAMES = [
  "January",
  "February",
  "March",
  "April",
  "May",
  "June",
  "July",
  "August",
  "September",
  "October",
  "November",
  "December",
];

// "" (an empty select value) is the sentinel for "unknown" - simpler and
// more portable across environments than a bound null option value.
const UNKNOWN = "";

const year = ref(new Date().getFullYear());
const month = ref(UNKNOWN);
const day = ref(UNKNOWN);
const hasTime = ref(false);
const hour = ref(0);
const minute = ref(0);
const approximate = ref(false);
const scannedLocal = ref(false);

const dayOptions = computed(() => {
  if (month.value === UNKNOWN) return [];
  const daysInMonth = new Date(year.value, month.value, 0).getDate();
  return Array.from({ length: daysInMonth }, (_, i) => i + 1);
});

// Unknown month clears/disables day; unknown day clears/disables time - this
// is how precision is derived, with no separate precision control.
watch(month, (newMonth) => {
  if (newMonth === UNKNOWN) {
    day.value = UNKNOWN;
  } else if (day.value !== UNKNOWN && day.value > dayOptions.value.length) {
    day.value = dayOptions.value.length;
  }
});

watch(day, (newDay) => {
  if (newDay === UNKNOWN) {
    hasTime.value = false;
  }
});

const showReset = computed(() => props.takenAtInfo?.source === "user");
const resetSource = computed(() =>
  props.takenAtInfo?.exifAvailable ? "EXIF" : "upload",
);
const resetLabel = computed(() => `Reset to ${resetSource.value} date`);

const modal = useModal({ onClose: () => emit("close") });

function resetFormFromProps() {
  const info = props.takenAtInfo;
  year.value = info?.year ?? new Date().getFullYear();
  month.value = info?.month ?? UNKNOWN;
  day.value = info?.day ?? UNKNOWN;
  hasTime.value = info?.hour != null;
  hour.value = info?.hour ?? 0;
  minute.value = info?.minute ?? 0;
  approximate.value = info?.approximate ?? false;
  scannedLocal.value = props.scanned;
}

watch(
  () => props.active,
  (isActive) => {
    if (isActive) {
      resetFormFromProps();
      modal.open();
    } else if (modal.active.value) {
      modal.close();
    }
  },
  { immediate: true },
);

const modalCard = modal.modalCard;

// save()/reset() don't close the modal themselves - the mutation is async
// and owned by show.vue, so entered values stay on screen (and correctable)
// until show.vue confirms success and calls the exposed closeTakenAtModal.
function save() {
  emit("save", {
    year: year.value,
    month: month.value === UNKNOWN ? null : month.value,
    day: day.value === UNKNOWN ? null : day.value,
    hour: hasTime.value ? hour.value : null,
    minute: hasTime.value ? minute.value : null,
    approximate: approximate.value,
    scanned: scannedLocal.value,
  });
}

function reset() {
  emit("reset");
}

function close() {
  modal.close();
}
</script>

<style scoped lang="scss">
// Bulma's .is-grouped/.is-expanded grows each control from its own content
// width (e.g. "September" vs "31"), so they don't end up equal - a grid does.
.taken-at-date-fields {
  display: grid;
  grid-template-columns: repeat(3, 1fr);
  gap: 0 0.75rem;

  @media (max-width: 480px) {
    grid-template-columns: 1fr;
  }
}
</style>
