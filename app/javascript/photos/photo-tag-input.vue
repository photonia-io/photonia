<template>
  <div class="field mt-2">
    <div class="control">
      <div class="dropdown" :class="{ 'is-active': isDropdownActive }">
        <div class="dropdown-trigger">
          <div class="field has-addons">
            <div class="control is-expanded">
              <input
                class="input is-small"
                type="text"
                placeholder="Add a tag..."
                v-model="tagName"
                :disabled="isAddingTag"
                @input="onInput"
                @blur="onBlur"
                @keydown.enter.prevent="addTag"
                @keydown.esc="isDropdownActive = false"
                @keydown.down.prevent="selectNextSuggestion"
                @keydown.up.prevent="selectPreviousSuggestion"
              />
            </div>
            <div class="control">
              <button
                class="button is-primary is-small"
                @click.prevent="addTag"
                :disabled="!tagName.trim() || isAddingTag"
              >
                <span class="icon" v-if="isAddingTag">
                  <i class="fas fa-spinner fa-spin"></i>
                </span>
                <span class="icon" v-else>
                  <i class="fas fa-plus"></i>
                </span>
              </button>
            </div>
          </div>
        </div>
        <div class="dropdown-menu" v-if="suggestions.length > 0">
          <div class="dropdown-content">
            <a
              v-for="(suggestion, index) in suggestions"
              :key="suggestion.id"
              class="dropdown-item"
              :class="{ 'is-active': index === selectedIndex }"
              @mousedown.prevent="selectSuggestion(suggestion)"
              @mouseover="selectedIndex = index"
            >
              {{ suggestion.name }}
            </a>
          </div>
        </div>
      </div>
    </div>
    <div v-if="relatedTagsSuggestions.length > 0" class="mt-2">
      <span class="has-text-grey-light is-size-7">Suggested tags: </span>
      <a
        v-for="tag in relatedTagsSuggestions"
        :key="tag.id"
        class="tag is-small is-link is-light mr-1"
        @click.prevent="addSuggestedTag(tag.name)"
      >
        {{ tag.name }}
      </a>
    </div>
  </div>
</template>

<script setup>
import { ref, watch, computed, onUnmounted } from "vue";
import gql from "graphql-tag";
import { useQuery } from "@vue/apollo-composable";
import toaster from "../mixins/toaster";

const props = defineProps({
  userTags: {
    type: Array,
    default: () => [],
  },
  machineTags: {
    type: Array,
    default: () => [],
  },
  isAddingTag: {
    type: Boolean,
    default: false,
  },
});

const emit = defineEmits(['add-tag']);

const tagName = ref("");
const suggestions = ref([]);
const isDropdownActive = ref(false);
const selectedIndex = ref(-1);
const minCharsForSuggestions = 3;
const suggestionsQueryEnabled = ref(false);
const relatedTagsSuggestions = ref([]);
const relatedTagsQueryEnabled = ref(false);
let debounceTimeout = null;

onUnmounted(() => {
  clearTimeout(debounceTimeout);
});

// Query for tag suggestions
const { result: suggestionsResult, refetch: fetchSuggestions } = useQuery(
  gql`
    query TagSuggestions($query: String!, $limit: Int) {
      tags(query: $query, limit: $limit) {
        id
        name
      }
    }
  `,
  {
    query: tagName,
    limit: 10,
  },
  {
    enabled: suggestionsQueryEnabled,
  },
);

// Compute tag IDs for related tags query
const userTagIds = computed(() => {
  if (!props.userTags || props.userTags.length === 0) {
    return [];
  }
  return props.userTags.map((tag) => tag.id);
});

// Query for related tags
const { result: relatedTagsResult, refetch: fetchRelatedTags } = useQuery(
  gql`
    query RelatedTags($ids: [ID!]!, $limit: Int) {
      relatedTags(ids: $ids, limit: $limit) {
        id
        name
      }
    }
  `,
  () => ({
    ids: userTagIds.value,
    limit: 5,
  }),
  {
    enabled: relatedTagsQueryEnabled,
  },
);

const existingTags = computed(
  () =>
    new Set([
      ...(props.userTags || []).map((tag) => tag.name),
      ...(props.machineTags || []).map((tag) => tag.name),
    ]),
);

// Watch for suggestion results
watch(suggestionsResult, (value) => {
  if (value && value.tags) {
    suggestions.value = value.tags.filter(
      (tag) => !existingTags.value.has(tag.name),
    );
    selectedIndex.value = -1;
    isDropdownActive.value = suggestions.value.length > 0;
  }
});

// Watch for related tags results
watch(relatedTagsResult, (value) => {
  if (value && value.relatedTags && props.userTags && props.userTags.length > 0) {
    relatedTagsSuggestions.value = value.relatedTags.filter(
      (tag) => !existingTags.value.has(tag.name),
    );
  }
});

// Watch userTags to fetch related tags when they change
watch(
  () => props.userTags,
  async (newUserTags) => {
    if (!newUserTags || newUserTags.length === 0) {
      relatedTagsQueryEnabled.value = false;
      relatedTagsSuggestions.value = [];
      return;
    }

    try {
      relatedTagsQueryEnabled.value = true;
      await fetchRelatedTags();
    } catch (error) {
      // Silently fail for related tags as they're suggestions
      relatedTagsSuggestions.value = [];
    }
  },
  { immediate: true, deep: true },
);

// Handle input changes
const onInput = async () => {
  clearTimeout(debounceTimeout);
  debounceTimeout = setTimeout(async () => {
    await handleInputChange();
  }, 300);
};

const handleInputChange = async () => {
  if (tagName.value.length < minCharsForSuggestions) {
    suggestionsQueryEnabled.value = false;
    suggestions.value = [];
    isDropdownActive.value = false;
    return;
  }

  try {
    suggestionsQueryEnabled.value = true;
    await fetchSuggestions();
  } catch (error) {
    toaster(`Error fetching suggestions: ${error.message}`, "is-danger");
  }
};

const onBlur = () => {
  // Delay hiding the dropdown to allow clicking on suggestions
  setTimeout(() => {
    isDropdownActive.value = false;
  }, 200);
};

const selectSuggestion = (suggestion) => {
  tagName.value = suggestion.name;
  isDropdownActive.value = false;
  addTag();
};

const selectNextSuggestion = () => {
  if (suggestions.value.length === 0) return;
  selectedIndex.value = (selectedIndex.value + 1) % suggestions.value.length;
};

const selectPreviousSuggestion = () => {
  if (suggestions.value.length === 0) return;
  selectedIndex.value =
    (selectedIndex.value - 1 + suggestions.value.length) %
    suggestions.value.length;
};

const addTag = () => {
  if (!tagName.value.trim() || props.isAddingTag) return;

  // If a suggestion is selected, use that
  if (selectedIndex.value >= 0 && suggestions.value[selectedIndex.value]) {
    tagName.value = suggestions.value[selectedIndex.value].name;
  }

  const tagToAdd = tagName.value.trim();

  // Emit event to parent component
  emit('add-tag', tagToAdd);

  // Clear the input
  tagName.value = "";
  suggestions.value = [];
  suggestionsQueryEnabled.value = false;
  isDropdownActive.value = false;
};

const addSuggestedTag = (name) => {
  if (props.isAddingTag) return;

  // Emit event to parent component
  emit('add-tag', name);
};
</script>

<style scoped>
.dropdown {
  width: 100%;
}
.dropdown-trigger {
  width: 100%;
}
</style>
