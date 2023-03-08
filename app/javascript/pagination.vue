<template>
  <nav class="pagination is-centered" role="navigation" aria-label="pagination">
    <!-- previous page router-link -->
    <router-link
      v-if="previousPage > 0"
      :to="{ name: 'photos-index', query: { page: previousPage } }"
      class="pagination-previous"
      rel="prev"
    >
      ‹ Prev
    </router-link>
    <a
      v-else
      class="pagination-previous is-disabled"
    >
      ‹ Prev
    </a>
    <!-- next page router-link -->
    <router-link
      v-if="nextPage <= metadata.totalPages"
      :to="{ name: 'photos-index', query: { page: nextPage } }"
      class="pagination-next"
      rel="next"
    >
      Next ›
    </router-link>
    <a
      v-else
      class="pagination-next is-disabled"
    >
      Next ›
    </a>
    <ul class="pagination-list">
      <li
        v-for="page in pages"        
      >
        <router-link
          v-if="page === metadata.currentPage"
          :to="{ name: 'photos-index', query: { page: page } }"
          class="pagination-link is-current"
        >
          {{ page }}
        </router-link>
        <router-link
          v-else
          :to="{ name: 'photos-index', query: { page: page } }"
          class="pagination-link"
        >
          {{ page }}
        </router-link>
      </li>
        <!-- <a href="/photos?page=1" class="pagination-link is-current" aria-label="page 1" aria-current="page">1</a> -->
        <!-- <a href="/photos?page=2" rel="next" class="pagination-link" aria-label="goto page 2">2</a> -->
        <!-- <span class="pagination-ellipsis">…</span> -->
    </ul>
  </nav>
</template>

<script setup>
  import { computed, toRefs } from 'vue'

  const props = defineProps({
    metadata: {
      type: Object,
      required: true
    },
    path: {
      type: String,
      required: true
    }
  })

  const { metadata, path } = toRefs(props)

  const pages = computed(
    function() {
      const pages = []
      for (let i = 1; i <= metadata.value.totalPages; i++) {
        pages.push(i)
      }
      return pages
    }
  )

  const previousPage = computed(
    function() {
      return metadata.value.currentPage - 1
    }
  )

  const nextPage = computed(
    function() {
      return metadata.value.currentPage + 1
    }
  )
</script>