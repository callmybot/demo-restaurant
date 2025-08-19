<template>
  <q-layout view="lhh Lpr lFf">
    <q-header class="bg-white container text-black">
      <q-toolbar>
        <AppIcon width="128" />
        <h1 class="text-h3">Restaurang Solgmit</h1>
      </q-toolbar>
    </q-header>
    <q-page-container>
      <router-view />
    </q-page-container>
  </q-layout>
</template>

<script setup lang="ts">
import AppIcon from 'src/vectors/AppIcon.vue'
</script>
