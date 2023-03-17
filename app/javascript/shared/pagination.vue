<template>
  <nav class="pagination is-centered" role="navigation" aria-label="pagination">
    <!-- previous page router-link -->
    <router-link
      v-if="previousPage > 0"
      :to="{ name: routeName, params: routeParams, query: { ...additionalQueryParams, page: previousPage } }"
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
      :to="{ name: routeName, params: routeParams, query: { ...additionalQueryParams, page: nextPage } }"
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
          :to="{ name: routeName, params: routeParams, query: { ...additionalQueryParams, page: page } }"
          class="pagination-link is-current"
        >
          {{ page }}
        </router-link>
        <span
          v-else-if="page === '…'"
          class="pagination-ellipsis"
        >
          …
        </span>
        <router-link
          v-else
          :to="{ name: routeName, params: routeParams, query: { ...additionalQueryParams, page: page } }"
          class="pagination-link"
        >
          {{ page }}
        </router-link>
      </li>
        <!-- <a href="/photos?page=2" rel="next" class="pagination-link" aria-label="goto page 2">2</a> -->
    </ul>
  </nav>
</template>

<script setup>
  import { computed, toRefs } from 'vue'

  const pad = 3
  const padFirst = 0
  const padLast = 0

  const props = defineProps({
    metadata: {
      type: Object,
      required: true
    },
    routeName: {
      type: String,
      required: true
    },
    routeParams: {
      type: Object,
      required: false
    },
    additionalQueryParams: {
      type: Object,
      required: false
    }
  })

  const { metadata, routeName, routeParams, additionalQueryParams } = toRefs(props)

  const pages = computed(
    function() {
      const pages = []
      for (let i = 1; i <= metadata.value.totalPages; i++) {
        let addPage = false
        if(i == 1 || i == metadata.value.totalPages) {
          addPage = true
        } else if(i >= metadata.value.currentPage - pad && i <= metadata.value.currentPage + pad) {
          addPage = true
        } else if(i <= padFirst + 1) {
          addPage = true
        } else if(i >= metadata.value.totalPages - padLast) {
          addPage = true
        }

        if(addPage) {
          pages.push(i)
        } else if(pages[pages.length - 1] != '…') {
          pages.push('…')
        }
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