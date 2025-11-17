<template>
  <section class="section-pt-pb-0">
    <div class="container">
      <h1 class="title mt-5 mb-0">Admin</h1>
      <hr class="mt-2 mb-4" />
      <div class="tabs">
        <ul>
          <li :class="{ 'is-active': $route.name === 'admin-settings' }">
            <router-link :to="{ name: 'admin-settings' }">Settings</router-link>
          </li>
          <li :class="{ 'is-active': $route.name === 'admin-users' || $route.name === 'admin-show-user' }">
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
