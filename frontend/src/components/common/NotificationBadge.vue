<template>
  <div class="notification-badge" @click="openNotificationCenter">
    <i class="fas fa-bell"></i>
    <span v-if="unreadCount > 0" class="badge">{{ formattedCount }}</span>
  </div>
</template>

<script>
import { mapGetters, mapActions } from 'vuex';

export default {
  name: 'NotificationBadge',
  computed: {
    ...mapGetters(['unreadNotifications']),
    unreadCount() {
      return this.unreadNotifications.length;
    },
    formattedCount() {
      return this.unreadCount > 99 ? '99+' : this.unreadCount;
    }
  },
  methods: {
    ...mapActions(['toggleNotificationCenter']),
    openNotificationCenter() {
      this.toggleNotificationCenter(true);
    }
  }
}
</script>

<style scoped>
.notification-badge {
  @apply relative cursor-pointer text-gray-300 hover:text-white;
}

.badge {
  @apply absolute -top-1 -right-1 bg-red-500 text-white text-xs rounded-full h-5 min-w-[1.25rem] flex items-center justify-center px-1;
}
</style>
