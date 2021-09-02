import Vue from 'vue/dist/vue.esm'
import Navigation from '../navigation.vue'

import VueRouter from 'vue-router'
Vue.use(VueRouter)

document.addEventListener('DOMContentLoaded', () => {
  // routes and router start

  const cj = window.configuration_json
  const cjda = cj.data.attributes

  console.log(cjda.photos_path)

  const routes = [
    { path: cjda.root_path, component: () => import('../root.vue') },
    { path: cjda.photos_path, name: 'photo-index', component: () => import('../photos/index.vue') },
    { path: cjda.photos_path + '/:id', name: 'photo-show', component: () => import('../photos/show.vue') },
    { path: cjda.albums_path, name: 'album-index', component: () => import('../albums/show.vue') },
    { path: cjda.albums_path + '/:id', name: 'album-show', component: () => import('../albums/show.vue') },
    { path: cjda.tags_path, name: 'tag-index', component: () => import('../tags/show.vue') },
    { path: cjda.tags_path + '/:id', name: 'tag-show', component: () => import('../tags/show.vue') },
  ]

  const router = new VueRouter({
    mode: 'history',
    routes
  })

  // go for Vue!

  const app = new Vue({
    el: '#app',
    router,
    components: { Navigation }
  })
})
