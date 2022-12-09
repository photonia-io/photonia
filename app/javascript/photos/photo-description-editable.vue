<template>
  <div
    v-if="!editing"
    class="content"
    @click="startEditing"
  >
    {{ description }}
  </div>
  <div
    v-else
    class="field is-grouped level-item is-flex-grow-1"
  >
    <p class="control is-expanded">
      <input
        v-model="description"
        class="input"
        type="text"
        placeholder="Enter a description for this photo"
      />
    </p>
    <p class="control">
      <button
        class="button is-info"
        @click="updateDescription"
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
    description: {
      type: String,
      required: true
    }
  })
  
  const emit = defineEmits(['updateDescription'])

  const editing = ref(false)
  var oldDescription = ''
  
  const startEditing = () => {
    oldDescription = props.description
    editing.value = true
  }

  const updateDescription = () => {
    if(oldDescription != props.description) {
      emit('updateDescription', { id: props.id, description: props.description })
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