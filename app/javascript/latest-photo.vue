<template>
  <div class="block">
    <h1 class="title">Latest photo</h1>
    <a href="<%= photo_path(@latest_photo) %>">
      <img src="<%= @latest_photo.image_url(:extralarge) %>" class="image is-fullwidth" />
    </a>
    <div class="level mt-3">
      <div class="level-left">
        <a href="<%= photo_path(@latest_photo) %>"><span class="title is-5"><%= @latest_photo.name %></span></a>
      </div>
      <div class="level-right">
        <a href="<%= photos_path %>" class="button">See all photos...</a>
      </div>
    </div>
  </div>
</template>
