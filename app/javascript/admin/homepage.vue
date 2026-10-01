<template>
  <div>
    <div class="card">
      <div class="card-content">
        <form @submit.prevent="submit">
          <p class="help mb-4">
            The latest photo and "More of the latest" always show. Switch off any
            of the other sections you don't want.
          </p>
          <div
            v-for="section in SECTIONS"
            :key="section.field"
            class="field is-horizontal"
          >
            <div class="field-label">
              <label class="label">{{ section.label }}</label>
            </div>
            <div class="field-body">
              <div class="field">
                <div class="control">
                  <label class="checkbox">
                    <input type="checkbox" v-model="form[section.field]" />
                    Enabled
                  </label>
                </div>
                <p v-if="section.help" class="help">{{ section.help }}</p>
                <div
                  v-if="section.field === 'homepageAlbumSpotlightEnabled'"
                  class="control mt-2"
                >
                  <div class="select">
                    <select
                      v-model="form.homepageSpotlightAlbumId"
                      :disabled="!form.homepageAlbumSpotlightEnabled"
                      aria-label="Spotlighted album"
                    >
                      <option value="">Latest album (default)</option>
                      <option v-if="unavailablePick" :value="form.homepageSpotlightAlbumId">
                        Unavailable album (showing the latest)
                      </option>
                      <option v-for="album in albumChoices" :key="album.id" :value="album.id">
                        {{ album.title }}
                      </option>
                    </select>
                  </div>
                </div>
              </div>
            </div>
          </div>
          <hr />
          <div class="field is-horizontal">
            <div class="field-label">
              <!-- Left empty for spacing -->
            </div>
            <div class="field-body">
              <div class="field">
                <div class="field is-grouped">
                  <div class="control">
                    <button type="submit" class="button is-primary">
                      <span>Save</span>
                    </button>
                  </div>
                  <div class="control">
                    <button
                      class="button is-warning"
                      v-if="showReloadButton"
                      @click.prevent="reloadApplication()"
                    >
                      <span>Reload Application</span>
                    </button>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </form>
      </div>
    </div>
  </div>
</template>

<script setup>
import { reactive, ref, computed, watch, onBeforeUnmount } from "vue";
import gql from "graphql-tag";
import { useQuery, useMutation } from "@vue/apollo-composable";
import { useTitle } from "vue-page-title";
import toaster from "../mixins/toaster";
import { useApplicationStore } from "@/stores/application";

useTitle("Admin - Homepage");

const applicationStore = useApplicationStore();

// In homepage order. `field` is the GraphQL name of the toggle.
const SECTIONS = [
  { field: "homepageStatsEnabled", label: "Stats line", help: "Photo, album and year totals under the hero." },
  { field: "homepageLatestAlbumsEnabled", label: "Latest albums" },
  {
    field: "homepageAlbumSpotlightEnabled",
    label: "Album spotlight",
    help: "One album shown with a few of its photos. Without a pick, the latest album is spotlighted.",
  },
  { field: "homepageRandomEnabled", label: "Random photos" },
  { field: "homepageOnThisDayEnabled", label: "On this day", help: "Photos taken on today's date in earlier years." },
  { field: "homepageThisMonthEnabled", label: "This month over the years" },
  {
    field: "homepagePopularEnabled",
    label: "Trending / most viewed",
    help: "Trending this week, or all-time most viewed when there is little recent traffic.",
  },
  { field: "homepageHiddenGemsEnabled", label: "Hidden gems", help: "Photos few people have seen." },
  { field: "homepageRecentlyCommentedEnabled", label: "Recently commented" },
  { field: "homepageRecentCommentsEnabled", label: "Latest comments" },
  { field: "homepageYearsEnabled", label: "Browse by year" },
  { field: "homepageTagsEnabled", label: "Most used tags" },
];

const FIELDS = [...SECTIONS.map((section) => section.field), "homepageSpotlightAlbumId"];

const ADMIN_SETTINGS_QUERY = gql`
  query AdminHomepageSettingsQuery {
    adminSettings {
      id
      ${FIELDS.join("\n      ")}
      spotlightAlbumChoices {
        id
        title
      }
    }
  }
`;

const { result } = useQuery(ADMIN_SETTINGS_QUERY);

const saved = computed(() => result.value?.adminSettings ?? null);
const albumChoices = computed(() => saved.value?.spotlightAlbumChoices ?? []);

// Local edits, reset to the saved values whenever those change (first load, save)
const form = reactive({});
watch(
  saved,
  (settings) => {
    if (settings) FIELDS.forEach((field) => (form[field] = settings[field]));
  },
  { immediate: true },
);

// A pick that is no longer a public album with public photos
const unavailablePick = computed(
  () =>
    !!form.homepageSpotlightAlbumId &&
    !albumChoices.value.some((album) => album.id === form.homepageSpotlightAlbumId),
);

// Warns before navigating away with unsaved changes, via the same router
// guard the other admin tabs use.
const dirty = computed(
  () => !!saved.value && FIELDS.some((field) => form[field] !== saved.value[field]),
);

watch(dirty, (isDirty) => {
  if (isDirty) {
    applicationStore.startEditing();
  } else {
    applicationStore.stopEditing();
  }
});

onBeforeUnmount(() => {
  applicationStore.stopEditing();
});

const showReloadButton = ref(false);

const { mutate, onDone, onError } = useMutation(gql`
  mutation AdminHomepageSettingsMutation(
    ${SECTIONS.map((section) => `$${section.field}: Boolean`).join("\n    ")}
    $homepageSpotlightAlbumId: String
  ) {
    updateAdminSettings(
      ${FIELDS.map((field) => `${field}: $${field}`).join("\n      ")}
    ) {
      id
      ${FIELDS.join("\n      ")}
    }
  }
`);

const submit = () => mutate(Object.fromEntries(FIELDS.map((field) => [field, form[field]])));

onDone(() => {
  showReloadButton.value = true;
  toaster("Settings saved");
});

onError(() => {
  toaster("Error saving settings", "is-danger");
});

const reloadApplication = () => {
  window.location = "/";
};
</script>
