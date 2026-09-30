<template>
  <div class="search-box">
    <form @submit.prevent="submit">
      <div class="dropdown" :class="{ 'is-active': isDropdownActive && hasMenu }">
        <div class="dropdown-trigger">
          <div class="field has-addons">
            <div class="control is-expanded">
              <input
                id="search-box-input"
                type="text"
                class="input"
                placeholder="Find a photo"
                autocomplete="off"
                v-model="query"
                @input="onInput"
                @focus="onFocus"
                @blur="onBlur"
                @keydown.down.prevent="selectNext"
                @keydown.up.prevent="selectPrevious"
                @keydown.enter.prevent="onEnter"
                @keydown.esc="isDropdownActive = false"
              />
            </div>
            <div class="control">
              <input type="submit" class="button" value="Search" />
            </div>
            <div class="control">
              <router-link :to="advancedSearchLink" class="button" title="Advanced search">
                <span class="icon"><i class="fas fa-sliders-h"></i></span>
              </router-link>
            </div>
          </div>
        </div>
        <div class="dropdown-menu" role="menu" v-if="hasMenu">
          <div class="dropdown-content">
            <template v-if="showRecent">
              <p class="dropdown-item has-text-weak is-size-7">Recent</p>
              <a
                v-for="(item, index) in flatItems"
                :key="`recent-${index}`"
                class="dropdown-item"
                :class="{ 'is-active': index === selectedIndex }"
                @mousedown.prevent="choose(item)"
                @mouseover="selectedIndex = index"
              >
                <span class="icon-text">
                  <span class="icon"><i class="fas fa-history"></i></span>
                  <span>{{ item.text }}</span>
                </span>
              </a>
            </template>
            <template v-else>
              <template v-if="searches.length">
                <p class="dropdown-item has-text-weak is-size-7">Searches</p>
                <a
                  v-for="index in groupIndexes.searches"
                  :key="`search-${index}`"
                  class="dropdown-item"
                  :class="{ 'is-active': index === selectedIndex }"
                  @mousedown.prevent="choose(flatItems[index])"
                  @mouseover="selectedIndex = index"
                >
                  <span class="icon-text">
                    <span class="icon"><i class="fas fa-search"></i></span>
                    <span>{{ flatItems[index].text }}</span>
                  </span>
                </a>
              </template>
              <template v-if="terms.length">
                <p class="dropdown-item has-text-weak is-size-7">Terms</p>
                <a
                  v-for="index in groupIndexes.terms"
                  :key="`term-${index}`"
                  class="dropdown-item"
                  :class="{ 'is-active': index === selectedIndex }"
                  @mousedown.prevent="choose(flatItems[index])"
                  @mouseover="selectedIndex = index"
                >
                  <span class="icon-text">
                    <span class="icon"><i class="fas fa-tag"></i></span>
                    <span>{{ flatItems[index].text }}</span>
                  </span>
                </a>
              </template>
              <template v-if="photos.length">
                <p class="dropdown-item has-text-weak is-size-7">Photos</p>
                <a
                  v-for="index in groupIndexes.photos"
                  :key="`photo-${index}`"
                  class="dropdown-item"
                  :class="{ 'is-active': index === selectedIndex }"
                  @mousedown.prevent="choose(flatItems[index])"
                  @mouseover="selectedIndex = index"
                >
                  <span class="icon-text">
                    <span class="icon"><i class="fas fa-image"></i></span>
                    <span>{{ flatItems[index].text }}</span>
                  </span>
                </a>
              </template>
            </template>
            <hr class="dropdown-divider" v-if="showAdvancedSearchItem" />
            <a
              class="dropdown-item"
              v-if="showAdvancedSearchItem"
              :class="{ 'is-active': selectedIndex === advancedSearchIndex }"
              @mousedown.prevent="goToAdvancedSearch"
              @mouseover="selectedIndex = advancedSearchIndex"
            >
              Advanced search for &ldquo;{{ trimmedQuery }}&rdquo;
            </a>
          </div>
        </div>
      </div>
    </form>
  </div>
</template>


<script setup>
import { ref, computed, watch, onUnmounted } from "vue";
import gql from "graphql-tag";
import { useQuery } from "@vue/apollo-composable";
import { useRoute, useRouter } from "vue-router";
import { useUserStore } from "@/stores/user";

const STORAGE_KEY = "search-box:recent";
const MAX_RECENT = 5;
const MIN_CHARS = 2;
const DEBOUNCE_MS = 300;
const BLUR_DELAY_MS = 200;

const route = useRoute();
const router = useRouter();
const userStore = useUserStore();

const query = ref(route.query.q || "");
const isDropdownActive = ref(false);
const selectedIndex = ref(-1);
const suggestionsQueryEnabled = ref(false);
let debounceTimeout = null;
let blurTimeout = null;

watch(
  () => route.query.q,
  (q) => {
    query.value = q || "";
  },
  { immediate: true },
);

onUnmounted(() => {
  clearTimeout(debounceTimeout);
  clearTimeout(blurTimeout);
});

function loadRecentFromStorage() {
  try {
    const raw = localStorage.getItem(STORAGE_KEY);
    const parsed = raw ? JSON.parse(raw) : [];
    return Array.isArray(parsed) ? parsed : [];
  } catch {
    return [];
  }
}

function saveRecentToStorage(list) {
  try {
    localStorage.setItem(STORAGE_KEY, JSON.stringify(list));
  } catch {
    // Storage unavailable (private browsing, quota). Not fatal, just not remembered.
  }
}

function rememberRecent(text) {
  if (userStore.signedIn || !text) return;

  const list = [text, ...loadRecentFromStorage().filter((existing) => existing !== text)].slice(0, MAX_RECENT);
  saveRecentToStorage(list);
}

const { result, refetch } = useQuery(
  gql`${gql_queries.search_suggestions}`,
  () => ({ query: trimmedQuery.value, limit: 5 }),
  { enabled: suggestionsQueryEnabled },
);

const trimmedQuery = computed(() => query.value.trim());

const searches = computed(() => result.value?.searchSuggestions?.searches || []);
const terms = computed(() => result.value?.searchSuggestions?.terms || []);
const photos = computed(() => result.value?.searchSuggestions?.photos || []);

const showRecent = computed(() => trimmedQuery.value.length === 0);

const recentSuggestions = computed(() => {
  if (userStore.signedIn) return result.value?.searchSuggestions?.recent || [];
  return loadRecentFromStorage();
});

// One flat list driving keyboard navigation across every visible group, in
// the same top-to-bottom order the template renders them.
const flatItems = computed(() => {
  if (showRecent.value) {
    return recentSuggestions.value.map((text) => ({ type: "search", text }));
  }

  return [
    ...searches.value.map((s) => ({ type: "search", text: s.text })),
    ...terms.value.map((t) => ({ type: "search", text: t.text })),
    ...photos.value.map((p) => ({ type: "photo", text: p.title, id: p.id })),
  ];
});

// Index ranges within flatItems for each rendered group, so the template
// can look up the right item by its position without recomputing offsets.
const groupIndexes = computed(() => {
  if (showRecent.value) return { searches: [], terms: [], photos: [] };

  const searchesRange = searches.value.map((_, i) => i);
  const termsRange = terms.value.map((_, i) => searches.value.length + i);
  const photosRange = photos.value.map((_, i) => searches.value.length + terms.value.length + i);
  return { searches: searchesRange, terms: termsRange, photos: photosRange };
});

const showAdvancedSearchItem = computed(() => trimmedQuery.value.length >= MIN_CHARS);
const advancedSearchIndex = computed(() => flatItems.value.length);

const hasMenu = computed(() => {
  if (showRecent.value) return flatItems.value.length > 0;
  return flatItems.value.length > 0 || showAdvancedSearchItem.value;
});

const advancedSearchLink = computed(() => ({
  name: "photos-search",
  query: trimmedQuery.value ? { q: trimmedQuery.value } : {},
}));

function shouldFetch() {
  return trimmedQuery.value.length === 0 || trimmedQuery.value.length >= MIN_CHARS;
}

async function fetchSuggestions() {
  if (!shouldFetch()) return;

  try {
    suggestionsQueryEnabled.value = true;
    await refetch({ query: trimmedQuery.value, limit: 5 });
  } catch {
    // Suggestions are a nicety; a failed fetch just leaves the dropdown without extra groups.
  }
}

function onFocus() {
  isDropdownActive.value = true;
  selectedIndex.value = -1;
  fetchSuggestions();
}

function onInput() {
  isDropdownActive.value = true;
  selectedIndex.value = -1;
  clearTimeout(debounceTimeout);
  debounceTimeout = setTimeout(fetchSuggestions, DEBOUNCE_MS);
}

function onBlur() {
  blurTimeout = setTimeout(() => {
    isDropdownActive.value = false;
  }, BLUR_DELAY_MS);
}

function selectNext() {
  const count = flatItems.value.length + (showAdvancedSearchItem.value ? 1 : 0);
  if (count === 0) return;
  selectedIndex.value = (selectedIndex.value + 1) % count;
}

function selectPrevious() {
  const count = flatItems.value.length + (showAdvancedSearchItem.value ? 1 : 0);
  if (count === 0) return;
  selectedIndex.value = (selectedIndex.value - 1 + count) % count;
}

function onEnter() {
  if (selectedIndex.value >= 0 && selectedIndex.value === advancedSearchIndex.value) {
    goToAdvancedSearch();
    return;
  }

  if (selectedIndex.value >= 0 && flatItems.value[selectedIndex.value]) {
    choose(flatItems.value[selectedIndex.value]);
    return;
  }

  submit();
}

function choose(item) {
  isDropdownActive.value = false;

  if (item.type === "photo") {
    router.push({ name: "photos-show", params: { id: item.id } });
    return;
  }

  query.value = item.text;
  submit();
}

function goToAdvancedSearch() {
  isDropdownActive.value = false;
  router.push(advancedSearchLink.value);
}

function submit() {
  isDropdownActive.value = false;
  rememberRecent(trimmedQuery.value);
  router.push({ name: "photos-index", query: trimmedQuery.value ? { q: trimmedQuery.value } : {} });
}
</script>

<style scoped>
.dropdown,
.dropdown-trigger,
.dropdown-menu {
  width: 100%;
}

/* Bulma's default (20) sits below the photo hero's #label-list overlay
   (display-hero.vue, z-index: 100), which would otherwise paint over the
   dropdown when it's open on a photo page. */
.dropdown-menu {
  z-index: 110;
}

/* A photo title (or a long past search) shouldn't stretch or wrap the
   dropdown - clip it with an ellipsis instead. Bulma's .icon-text defaults
   to flex-wrap: wrap, which would otherwise wrap the icon and text onto
   separate lines before text-overflow ever gets a chance to apply. */
.dropdown-item .icon-text {
  display: flex;
  flex-wrap: nowrap;
  width: 100%;
}

.dropdown-item .icon-text > span:last-child {
  overflow: hidden;
  white-space: nowrap;
  text-overflow: ellipsis;
  min-width: 0;
}
</style>
