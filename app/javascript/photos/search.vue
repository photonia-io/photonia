<template>
  <section class="section-pt-pb-0">
    <div class="container">
      <div class="level mb-0 mt-5">
        <div class="level-left">
          <div class="level-item">
            <h1 class="title">Search</h1>
          </div>
        </div>
      </div>
      <hr class="mt-2 mb-4" />

      <div class="columns">
        <div class="column is-4">
          <form class="box" @submit.prevent="submit">
            <label class="label" :class="{ 'is-filled': filled('q') }" for="search-q">Text</label>
            <input id="search-q" class="input" type="text" v-model="form.q" placeholder="Search text" />

            <hr class="mt-4 mb-4" />

            <label class="label" :class="{ 'is-filled': filled('tags') }">Tags</label>
            <ChipList :items="form.tags" @remove="removeTag" />
            <div class="field is-grouped mt-1">
              <label class="radio mr-2">
                <input type="radio" value="all" v-model="form.tagsMode" />
                All of these tags
              </label>
              <label class="radio">
                <input type="radio" value="any" v-model="form.tagsMode" />
                Any of these tags
              </label>
            </div>
            <AutocompleteInput
              source="tags"
              placeholder="Add a tag..."
              :excludeNames="form.tags"
              @add="addTag"
            />

            <label class="label mt-4" :class="{ 'is-filled': filled('excludeTags') }">
              Exclude tags
            </label>
            <ChipList :items="form.excludeTags" @remove="removeExcludeTag" />
            <AutocompleteInput
              source="tags"
              placeholder="Exclude a tag..."
              :excludeNames="form.excludeTags"
              @add="addExcludeTag"
            />

            <hr class="mt-4 mb-4" />

            <label class="label" :class="{ 'is-filled': filled('takenFrom') || filled('takenTo') }">
              Date Taken
            </label>
            <div class="fixed-grid has-2-cols">
              <div class="grid">
                <div class="cell">
                  <label class="label is-small" :class="{ 'is-filled': filled('takenFrom') }" for="taken-from">
                    From
                  </label>
                  <input id="taken-from" class="input" type="date" v-model="form.takenFrom" />
                </div>
                <div class="cell">
                  <label class="label is-small" :class="{ 'is-filled': filled('takenTo') }" for="taken-to">
                    To
                  </label>
                  <input id="taken-to" class="input" type="date" v-model="form.takenTo" />
                </div>
              </div>
            </div>

            <label class="label mt-4" :class="{ 'is-filled': filled('postedFrom') || filled('postedTo') }">
              Date Posted
            </label>
            <div class="fixed-grid has-2-cols">
              <div class="grid">
                <div class="cell">
                  <label class="label is-small" :class="{ 'is-filled': filled('postedFrom') }" for="posted-from">
                    From
                  </label>
                  <input id="posted-from" class="input" type="date" v-model="form.postedFrom" />
                </div>
                <div class="cell">
                  <label class="label is-small" :class="{ 'is-filled': filled('postedTo') }" for="posted-to">
                    To
                  </label>
                  <input id="posted-to" class="input" type="date" v-model="form.postedTo" />
                </div>
              </div>
            </div>

            <hr class="mt-4 mb-4" />

            <label class="label" :class="{ 'is-filled': cameraSelection !== '' }">Camera</label>
            <div class="select is-fullwidth mb-3">
              <select v-model="cameraSelection">
                <option value="">Any</option>
                <option v-for="(camera, index) in cameras" :key="index" :value="String(index)">
                  {{ camera.friendlyName }} ({{ camera.count }})
                </option>
              </select>
            </div>
            <label
              class="label is-clickable camera-toggle-label"
              :class="{ 'is-filled': cameraAdvancedFilled }"
              @click="cameraAdvancedOpen = !cameraAdvancedOpen"
            >
              <span class="icon camera-chevron" :class="{ 'is-open': cameraAdvancedOpen }">
                <i class="fas fa-chevron-right" aria-hidden="true"></i>
              </span>
              <span>Detailed Camera Settings</span>
            </label>

            <div class="collapse" :class="{ 'is-open': cameraAdvancedOpen }">
              <div class="collapse-inner">
                <div class="fixed-grid has-2-cols mt-3">
                  <div class="grid">
                    <div class="cell">
                      <label class="label is-small" :class="{ 'is-filled': filled('isoMin') }" for="iso-min">
                        ISO min
                      </label>
                      <input id="iso-min" class="input" type="number" v-model.number="form.isoMin" />
                    </div>
                    <div class="cell">
                      <label class="label is-small" :class="{ 'is-filled': filled('isoMax') }" for="iso-max">
                        ISO max
                      </label>
                      <input id="iso-max" class="input" type="number" v-model.number="form.isoMax" />
                    </div>
                  </div>
                </div>
                <div class="fixed-grid has-2-cols mt-3">
                  <div class="grid">
                    <div class="cell">
                      <label class="label is-small" :class="{ 'is-filled': filled('fMin') }" for="f-min">
                        f-number min
                      </label>
                      <input id="f-min" class="input" type="number" step="0.1" v-model.number="form.fMin" />
                    </div>
                    <div class="cell">
                      <label class="label is-small" :class="{ 'is-filled': filled('fMax') }" for="f-max">
                        f-number max
                      </label>
                      <input id="f-max" class="input" type="number" step="0.1" v-model.number="form.fMax" />
                    </div>
                  </div>
                </div>
                <div class="fixed-grid has-2-cols mt-3">
                  <div class="grid">
                    <div class="cell">
                      <label class="label is-small" :class="{ 'is-filled': filled('flMin') }" for="fl-min">
                        Focal length min (mm)
                      </label>
                      <input id="fl-min" class="input" type="number" v-model.number="form.flMin" />
                    </div>
                    <div class="cell">
                      <label class="label is-small" :class="{ 'is-filled': filled('flMax') }" for="fl-max">
                        Focal length max (mm)
                      </label>
                      <input id="fl-max" class="input" type="number" v-model.number="form.flMax" />
                    </div>
                  </div>
                </div>
              </div>
            </div>

            <hr class="mt-4 mb-4" />

            <label class="label" :class="{ 'is-filled': filled('labels') }">Labels</label>
            <ChipList :items="form.labels" @remove="removeLabel" />
            <AutocompleteInput
              source="labels"
              placeholder="Add a label..."
              :excludeNames="form.labels"
              @add="addLabel"
            />

            <hr class="mt-4 mb-4" />

            <label class="label" :class="{ 'is-filled': filled('license') }" for="license-select">
              License
            </label>
            <div class="select is-fullwidth">
              <select id="license-select" v-model="form.license">
                <option value="">Any</option>
                <option v-for="option in LICENSE_OPTIONS" :key="option.value" :value="option.value">
                  {{ option.label }}
                </option>
              </select>
            </div>

            <hr class="mt-4 mb-4" />

            <label class="label" :class="{ 'is-filled': albumSelection !== '' }" for="album-select">
              Album
            </label>
            <div class="select is-fullwidth">
              <select id="album-select" v-model="albumSelection">
                <option value="">Any</option>
                <option value="__no_album__">Not in any album</option>
                <option v-for="album in albumOptions" :key="album.id" :value="album.id">
                  {{ album.title }}
                </option>
              </select>
            </div>

            <template v-if="userStore.admin">
              <hr class="mt-4 mb-4" />

              <label class="label" :class="{ 'is-filled': filled('privacy') }" for="privacy-select">
                Privacy
              </label>
              <div class="select is-fullwidth">
                <select id="privacy-select" v-model="form.privacy">
                  <option value="">Any</option>
                  <option value="public">Public</option>
                  <option value="private">Private</option>
                  <option value="friends_and_family">Friends &amp; Family</option>
                </select>
              </div>
            </template>

            <hr class="mt-4 mb-4" />

            <label class="label" :class="{ 'is-filled': missingDataFilled }">
              Search for photos which:
            </label>
            <label class="checkbox is-block" :class="{ 'is-filled': filled('noAlbum') }">
              <input type="checkbox" v-model="form.noAlbum" />
              Do not belong to any <strong>album</strong>
            </label>
            <label class="checkbox is-block" :class="{ 'is-filled': filled('untagged') }">
              <input type="checkbox" v-model="form.untagged" />
              Have no <strong>tags</strong>
            </label>
            <label class="checkbox is-block" :class="{ 'is-filled': filled('noTitle') }">
              <input type="checkbox" v-model="form.noTitle" />
              Have no <strong>title</strong>
            </label>
            <label class="checkbox is-block" :class="{ 'is-filled': filled('noDescription') }">
              <input type="checkbox" v-model="form.noDescription" />
              Have no <strong>description</strong>
            </label>
            <label class="checkbox is-block" :class="{ 'is-filled': filled('unknownDate') }">
              <input type="checkbox" v-model="form.unknownDate" />
              Have an unknown <strong>date</strong>
            </label>
            <label class="checkbox is-block" :class="{ 'is-filled': filled('approximateDate') }">
              <input type="checkbox" v-model="form.approximateDate" />
              Have an approximate <strong>date</strong>
            </label>
            <label class="checkbox is-block" :class="{ 'is-filled': filled('scanned') }">
              <input type="checkbox" v-model="form.scanned" />
              Are <strong>scanned</strong> from a print or negative
            </label>

            <hr class="mt-4 mb-4" />

            <div class="field is-grouped mt-4">
              <div class="control">
                <button type="submit" class="button is-primary">Search</button>
              </div>
              <div class="control">
                <button type="button" class="button" @click="reset">Reset</button>
              </div>
            </div>
          </form>
        </div>

        <div class="column">
          <template v-if="hasResults">
            <div class="level mb-1">
              <div class="level-left">
                <div class="level-item">
                  <p>
                    {{ result.photoSearch.metadata.totalCount }}
                    {{ result.photoSearch.metadata.totalCount === 1 ? "photo" : "photos" }} found
                  </p>
                </div>
              </div>
              <div class="level-right" v-if="result.photoSearch.metadata.totalCount > 0">
                <div class="level-item">
                  <label class="label is-small mr-2 mb-0" for="sort-select">Sort by</label>
                  <div class="select is-small">
                    <select id="sort-select" v-model="form.sort">
                      <option value="relevance" :disabled="!form.q">Relevance</option>
                      <option value="taken_at">Date taken</option>
                      <option value="posted_at">Date posted</option>
                      <option value="impressions_count">Views</option>
                      <option value="flickr_faves">Flickr faves</option>
                    </select>
                  </div>
                </div>
                <div class="level-item">
                  <label class="label is-small mr-2 mb-0" for="dir-select">Direction</label>
                  <div class="select is-small">
                    <select id="dir-select" v-model="form.dir">
                      <option value="desc">Descending</option>
                      <option value="asc">Ascending</option>
                    </select>
                  </div>
                </div>
                <div class="level-item">
                  <button type="button" class="button is-small is-primary" @click="submit">
                    Update Results
                  </button>
                </div>
              </div>
            </div>

            <hr class="mt-4 mb-2" />

            <p v-if="searchDescription" class="has-text-weak mb-2">{{ searchDescription }}</p>

            <hr class="mt-1 mb-4" />
          </template>

          <div class="columns is-1 is-multiline">
            <PhotoItem
              v-if="hasResults"
              v-for="photo in result.photoSearch.collection"
              :photo="photo"
              :key="photo.id"
            />
          </div>
          <hr v-if="hasResults" class="mt-1 mb-4" />
          <Pagination
            v-if="hasResults"
            :metadata="result.photoSearch.metadata"
            :additionalQueryParams="submittedQuery"
            routeName="photos-search"
          />
        </div>
      </div>
    </div>
  </section>
</template>

<script setup>
import { reactive, ref, computed, watch } from "vue";
import { useRoute, useRouter } from "vue-router";
import gql from "graphql-tag";
import { useQuery } from "@vue/apollo-composable";
import { useTitle } from "vue-page-title";
import { useUserStore } from "@/stores/user";
import { useSelectionStore } from "@/stores/selection";
import { useSelectionContext } from "@/mixins/use-selection-context";
import { LICENSE_OPTIONS } from "@/shared/licenses.js";
import {
  fromRouteQuery,
  toRouteQuery,
  toVariables,
  hasSearch,
  isFilled,
  describeSearch,
} from "./search-params.js";

import PhotoItem from "@/shared/photo-item.vue";
import Pagination from "@/shared/pagination.vue";
import AutocompleteInput from "@/shared/autocomplete-input.vue";
import ChipList from "@/shared/chip-list.vue";

useTitle("Search");

const route = useRoute();
const router = useRouter();
const userStore = useUserStore();
const selectionStore = useSelectionStore();
useSelectionContext();

// Form state: what the user is editing. Hydrated from the route on mount
// and on every external route change (e.g. a "Search within this album"
// link while already here); submitting pushes it back to the route, which
// re-hydrates it right back (a lossless round trip - see search-params.js's
// tests) so the two never drift apart.
const form = reactive({});

function hydrate(query) {
  const fresh = fromRouteQuery(query);
  fresh.tagsMode ||= "all";
  fresh.sort ||= "relevance";
  fresh.dir ||= "desc";

  Object.keys(form).forEach((key) => delete form[key]);
  Object.assign(form, fresh);
}

watch(() => route.query, hydrate, { immediate: true });

// Collapsed by default; only open on page load if the search that brought
// us here already had one of these filters set. Doesn't re-collapse or
// re-open itself afterward - the user's toggle sticks.
const CAMERA_ADVANCED_KEYS = ["isoMin", "isoMax", "fMin", "fMax", "flMin", "flMax"];
const initialState = fromRouteQuery(route.query);
const cameraAdvancedOpen = ref(CAMERA_ADVANCED_KEYS.some((key) => initialState[key] !== undefined));

// It's a big form - easy to lose track of what's set. `filled(key)` drives
// a highlight on each field's label so scanning down shows what's active.
const filled = (key) => isFilled(form, key);
const cameraAdvancedFilled = computed(() => CAMERA_ADVANCED_KEYS.some((key) => filled(key)));
const MISSING_DATA_KEYS = [
  "noAlbum",
  "untagged",
  "noTitle",
  "noDescription",
  "unknownDate",
  "approximateDate",
  "scanned",
];
const missingDataFilled = computed(() => MISSING_DATA_KEYS.some((key) => filled(key)));

// The actually-submitted state (what's in the URL), decoupled from the
// in-progress `form` above so editing a filter doesn't refetch until Search
// is clicked.
const submittedState = computed(() => fromRouteQuery(route.query));
const submittedQuery = computed(() => toRouteQuery(submittedState.value));
const page = computed(() => parseInt(route.query.page) || 1);
const enabled = computed(() => hasSearch(submittedState.value));

const { result } = useQuery(
  gql`
    ${gql_queries.photos_search}
  `,
  () => toVariables(submittedState.value, page.value),
  { enabled },
);

const hasResults = computed(() => !!result.value?.photoSearch);

const { result: optionsResult } = useQuery(
  gql`
    ${gql_queries.photos_search_options}
  `,
);
const cameras = computed(() => optionsResult.value?.cameras || []);
const albumOptions = computed(() => optionsResult.value?.albums?.collection || []);

const searchDescription = computed(() =>
  describeSearch(submittedState.value, { cameras: cameras.value, albums: albumOptions.value }),
);

const cameraSelection = computed({
  get() {
    if (!form.make && !form.model) return "";
    const index = cameras.value.findIndex(
      (camera) => camera.make === form.make && camera.model === form.model,
    );
    return index === -1 ? "" : String(index);
  },
  set(value) {
    if (value === "") {
      form.make = undefined;
      form.model = undefined;
      return;
    }
    const camera = cameras.value[Number(value)];
    form.make = camera.make;
    form.model = camera.model;
  },
});

const albumSelection = computed({
  get() {
    if (form.noAlbum) return "__no_album__";
    return form.album || "";
  },
  set(value) {
    if (value === "__no_album__") {
      form.noAlbum = true;
      form.album = undefined;
    } else {
      form.noAlbum = false;
      form.album = value || undefined;
    }
  },
});

function addTag(name) {
  if (!form.tags.includes(name)) form.tags = [...form.tags, name];
}
function removeTag(name) {
  form.tags = form.tags.filter((tag) => tag !== name);
}
function addExcludeTag(name) {
  if (!form.excludeTags.includes(name)) form.excludeTags = [...form.excludeTags, name];
}
function removeExcludeTag(name) {
  form.excludeTags = form.excludeTags.filter((tag) => tag !== name);
}
function addLabel(name) {
  if (!form.labels.includes(name)) form.labels = [...form.labels, name];
}
function removeLabel(name) {
  form.labels = form.labels.filter((label) => label !== name);
}

function submit() {
  router.push({ name: "photos-search", query: toRouteQuery(form) });
}

function reset() {
  router.push({ name: "photos-search", query: {} });
}

watch(
  () => result.value?.photoSearch?.collection,
  (photos) => selectionStore.setPageCollection(photos || []),
  { immediate: true },
);
</script>

<style scoped>
/* Marks a field's label when it currently has a value, so a long form
   doesn't leave you guessing what you already filled in. */
.label.is-filled,
.checkbox.is-filled {
  color: var(--bulma-success);
  font-weight: 700;
}

/* Bulma's .icon-text is align-items: flex-start (see .claude/rules/frontend.md),
   which sits the icon high relative to the text - centering directly here
   instead. */
.camera-toggle-label {
  display: inline-flex;
  align-items: center;
  gap: 0.25em;
}

.camera-chevron {
  transition: transform 0.2s ease;
}

.camera-chevron.is-open {
  transform: rotate(90deg);
}

/* Grid-rows collapse trick: animates from 0 to content height without a
   fixed max-height guess or measuring the content in JS. */
.collapse {
  display: grid;
  grid-template-rows: 0fr;
  transition: grid-template-rows 0.25s ease;
}

.collapse.is-open {
  grid-template-rows: 1fr;
}

.collapse-inner {
  overflow: hidden;
  min-height: 0;
}

/* This page is the only user of Bulma's .fixed-grid/.grid/.cell, which
   otherwise costs a large chunk of CSS for column-count breakpoints and
   per-cell row/column spans this form never uses - a plain 2-column grid
   covers every instance here. See #1096. */
.fixed-grid.has-2-cols > .grid {
  display: grid;
  grid-template-columns: repeat(2, 1fr);
  gap: 0.75rem;
  margin-bottom: 1.5rem;
}
</style>
