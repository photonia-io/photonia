<template>
  <h1
    v-if="!editing"
    class="title level-item mb-0"
    @click="startEditing"
  >
    {{ title }}
  </h1>
  <div
    v-else
    class="field is-grouped level-item is-flex-grow-1"
  >
    <p class="control is-expanded">
      <input
        v-model="title"
        class="input"
        type="text"
        placeholder="Enter a title for this photo"
      />
    </p>
    <p class="control">
      <button
        class="button is-info"
        @click="updateTitle"
      >
        Save
      </button>
    </p>
  </div>
</template>

<script setup>
  import { ref } from 'vue'

  const props = defineProps({
    id: {
      type: String,
      required: true
    },
    title: {
      type: String,
      required: true
    }
  })
  
  const emit = defineEmits(['updateTitle'])

  const editing = ref(false)
  var oldTitle = ''
  
  const startEditing = () => {
    oldTitle = props.title
    editing.value = true
  }

  const updateTitle = () => {
    if(oldTitle != props.title) {
      emit('updateTitle', { id: props.id, title: props.title })
    }
    editing.value = false
  }
</script>

<style scoped>
  /* [contenteditable="true"]:focus {
    background: green;
    min-width: 50%;
  } */
</style>