<template>
  <section class="section-pt-pb-0">
    <div class="container">
      <h1 class="title mt-5 mb-0">Admin</h1>
      <hr class="mt-2 mb-4" />
      <div class="tabs">
        <ul>
          <li :class="{ 'is-active': $route.name === 'admin-general' }">
            <router-link :to="{ name: 'admin-general' }">General</router-link>
          </li>
          <li :class="{ 'is-active': $route.name === 'admin-homepage' }">
            <router-link :to="{ name: 'admin-homepage' }">Homepage</router-link>
          </li>
          <li :class="{ 'is-active': $route.name === 'admin-comments' }">
            <router-link :to="{ name: 'admin-comments' }">Comments</router-link>
          </li>
          <li :class="{ 'is-active': $route.name === 'admin-system' }">
            <router-link :to="{ name: 'admin-system' }">System</router-link>
          </li>
          <li
            :class="{
              'is-active':
                $route.name === 'admin-users' ||
                $route.name === 'admin-show-user',
            }"
          >
            <router-link :to="{ name: 'admin-users' }">Users</router-link>
          </li>
        </ul>
      </div>
      <router-view></router-view>
    </div>
  </section>
</template>

<script setup>
import { useTitle } from "vue-page-title";

useTitle("Admin");
</script>
