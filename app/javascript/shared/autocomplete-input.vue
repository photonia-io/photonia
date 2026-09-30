<template>
  <div class="dropdown" :class="{ 'is-active': isDropdownActive }">
    <div class="dropdown-trigger">
      <div class="field has-addons">
        <div class="control is-expanded">
          <input
            class="input"
            type="text"
            :placeholder="placeholder"
            v-model="inputValue"
            @input="onInput"
            @blur="onBlur"
            @keydown.enter.prevent="addFromInput"
            @keydown.esc="isDropdownActive = false"
            @keydown.down.prevent="selectNextSuggestion"
            @keydown.up.prevent="selectPreviousSuggestion"
          />
        </div>
        <div class="control">
          <button
            class="button"
            @click.prevent="addFromInput"
            :disabled="!inputValue.trim()"
          >
            <span class="icon"><i class="fas fa-plus"></i></span>
          </button>
        </div>
      </div>
    </div>
    <div class="dropdown-menu" v-if="suggestions.length > 0">
      <div class="dropdown-content">
        <a
          v-for="(suggestion, index) in suggestions"
          :key="suggestion.name"
          class="dropdown-item"
          :class="{ 'is-active': index === selectedIndex }"
          @mousedown.prevent="selectSuggestion(suggestion)"
          @mouseover="selectedIndex = index"
        >
          {{ suggestion.name }}
          <span v-if="suggestion.count !== undefined" class="has-text-weak">
            ({{ suggestion.count }})
          </span>
        </a>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, watch, onUnmounted } from "vue";
import gql from "graphql-tag";
import { useQuery } from "@vue/apollo-composable";

// Tag/label name autocomplete for the advanced search form. Pared down
// from photos/photo-tag-input.vue: no related-tags block, no add-tag
// mutation - selection is purely local, the parent decides what "add"
// means (a chip in a filter list).
const props = defineProps({
  source: {
    type: String,
    required: true,
    validator: (value) => ["tags", "labels"].includes(value),
  },
  excludeNames: {
    type: Array,
    default: () => [],
  },
  placeholder: {
    type: String,
    default: "Add...",
  },
});

const emit = defineEmits(["add"]);

const inputValue = ref("");
const suggestions = ref([]);
const isDropdownActive = ref(false);
const selectedIndex = ref(-1);
const minCharsForSuggestions = 3;
const queryEnabled = ref(false);
let debounceTimeout = null;

onUnmounted(() => {
  clearTimeout(debounceTimeout);
});

const query =
  props.source === "tags"
    ? gql`
        query AutocompleteTags($query: String!, $limit: Int) {
          tags(query: $query, limit: $limit) {
            id
            name
          }
        }
      `
    : gql`
        query AutocompleteLabels($query: String!, $limit: Int) {
          labelNames(query: $query, limit: $limit) {
            name
            count
          }
        }
      `;

const { result, refetch: fetchSuggestions } = useQuery(
  query,
  { query: inputValue, limit: 10 },
  { enabled: queryEnabled },
);

const excludeSet = computed(() => new Set(props.excludeNames));

watch(result, (value) => {
  const items = props.source === "tags" ? value?.tags : value?.labelNames;
  if (items) {
    suggestions.value = items.filter((item) => !excludeSet.value.has(item.name));
    selectedIndex.value = -1;
    isDropdownActive.value = suggestions.value.length > 0;
  }
});

const onInput = () => {
  clearTimeout(debounceTimeout);
  debounceTimeout = setTimeout(handleInputChange, 300);
};

const handleInputChange = async () => {
  if (inputValue.value.length < minCharsForSuggestions) {
    queryEnabled.value = false;
    suggestions.value = [];
    isDropdownActive.value = false;
    return;
  }

  queryEnabled.value = true;
  await fetchSuggestions();
};

const onBlur = () => {
  // Delay hiding the dropdown to allow clicking on a suggestion
  setTimeout(() => {
    isDropdownActive.value = false;
  }, 200);
};

const addValue = (value) => {
  const trimmed = value.trim();
  if (!trimmed) return;

  emit("add", trimmed);
  inputValue.value = "";
  suggestions.value = [];
  queryEnabled.value = false;
  isDropdownActive.value = false;
};

const addFromInput = () => {
  if (selectedIndex.value >= 0 && suggestions.value[selectedIndex.value]) {
    addValue(suggestions.value[selectedIndex.value].name);
  } else {
    addValue(inputValue.value);
  }
};

const selectSuggestion = (suggestion) => addValue(suggestion.name);

const selectNextSuggestion = () => {
  if (suggestions.value.length === 0) return;
  selectedIndex.value = (selectedIndex.value + 1) % suggestions.value.length;
};

const selectPreviousSuggestion = () => {
  if (suggestions.value.length === 0) return;
  selectedIndex.value =
    (selectedIndex.value - 1 + suggestions.value.length) % suggestions.value.length;
};
</script>

<style scoped>
.dropdown,
.dropdown-trigger {
  width: 100%;
}
</style>
