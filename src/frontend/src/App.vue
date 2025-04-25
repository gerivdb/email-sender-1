<template>
  <div class="app-container">
    <Sidebar v-if="isAuthenticated" />
    <div class="main-content">
      <Header v-if="isAuthenticated" />
      <div class="content-wrapper">
        <router-view />
      </div>
    </div>
  </div>
</template>

<script>
import Sidebar from '@/components/common/Sidebar.vue';
import Header from '@/components/common/Header.vue';
import { mapGetters } from 'vuex';

export default {
  name: 'App',
  components: {
    Sidebar,
    Header
  },
  computed: {
    ...mapGetters(['isAuthenticated'])
  }
}
</script>

<style>
@import 'tailwindcss/base';
@import 'tailwindcss/components';
@import 'tailwindcss/utilities';

.app-container {
  @apply flex h-screen bg-gray-100;
}

.main-content {
  @apply flex-1 flex flex-col overflow-hidden;
}

.content-wrapper {
  @apply flex-1 overflow-y-auto p-4;
}
</style>
