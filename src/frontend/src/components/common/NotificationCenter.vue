<template>
  <div class="notification-center-wrapper">
    <button class="notification-button" @click="toggleCenter">
      <i class="fas fa-bell"></i>
      <span v-if="unreadCount > 0" class="badge">{{ formattedCount }}</span>
    </button>
    
    <div v-if="isOpen" class="notification-center">
      <div class="notification-header">
        <h3>Notifications</h3>
        <div class="notification-actions">
          <button v-if="unreadCount > 0" @click="markAllAsRead" class="action-button">
            Tout marquer comme lu
          </button>
          <button @click="toggleCenter" class="close-button">
            <i class="fas fa-times"></i>
          </button>
        </div>
      </div>
      
      <div class="notification-tabs">
        <button 
          :class="['tab-button', { active: activeTab === 'all' }]"
          @click="activeTab = 'all'"
        >
          Toutes
        </button>
        <button 
          :class="['tab-button', { active: activeTab === 'unread' }]"
          @click="activeTab = 'unread'"
        >
          Non lues <span v-if="unreadCount > 0">({{ unreadCount }})</span>
        </button>
      </div>
      
      <div class="notification-list">
        <template v-if="filteredNotifications.length > 0">
          <div 
            v-for="notification in filteredNotifications" 
            :key="notification.id"
            :class="['notification-item', { unread: !notification.read }]"
            @click="viewNotification(notification)"
          >
            <div class="notification-icon" :class="notification.severity">
              <i :class="getIconClass(notification)"></i>
            </div>
            <div class="notification-content">
              <p class="notification-message">{{ notification.message }}</p>
              <p class="notification-time">{{ formatTime(notification.timestamp) }}</p>
            </div>
          </div>
        </template>
        <div v-else class="empty-state">
          <i class="fas fa-check-circle"></i>
          <p>Aucune notification {{ activeTab === 'unread' ? 'non lue' : '' }}</p>
        </div>
      </div>
      
      <div class="notification-footer">
        <router-link to="/notifications" @click="toggleCenter">
          Voir toutes les notifications
        </router-link>
        <router-link to="/settings/notifications" @click="toggleCenter">
          Paramètres
        </router-link>
      </div>
    </div>
  </div>
</template>

<script>
import { mapGetters, mapActions } from 'vuex';
import moment from 'moment';
import 'moment/locale/fr';

export default {
  name: 'NotificationCenter',
  data() {
    return {
      activeTab: 'all'
    }
  },
  computed: {
    ...mapGetters(['notifications', 'unreadNotifications', 'isNotificationCenterOpen']),
    isOpen() {
      return this.isNotificationCenterOpen;
    },
    unreadCount() {
      return this.unreadNotifications.length;
    },
    formattedCount() {
      return this.unreadCount > 99 ? '99+' : this.unreadCount;
    },
    filteredNotifications() {
      if (this.activeTab === 'unread') {
        return this.unreadNotifications;
      }
      return this.notifications;
    }
  },
  methods: {
    ...mapActions(['toggleNotificationCenter', 'markNotificationAsRead', 'markAllNotificationsAsRead']),
    toggleCenter() {
      this.toggleNotificationCenter(!this.isOpen);
    },
    viewNotification(notification) {
      if (!notification.read) {
        this.markNotificationAsRead(notification.id);
      }
      
      // Naviguer vers la page appropriée en fonction du type de notification
      switch (notification.type) {
        case 'term_frequency':
          this.$router.push({ name: 'analysis', query: { section: 'term-frequency' } });
          break;
        case 'sentiment':
          this.$router.push({ name: 'analysis', query: { section: 'sentiment' } });
          break;
        case 'topic':
          this.$router.push({ name: 'analysis', query: { section: 'topics' } });
          break;
        default:
          this.$router.push({ name: 'notifications' });
      }
      
      this.toggleCenter();
    },
    markAllAsRead() {
      this.markAllNotificationsAsRead();
    },
    formatTime(timestamp) {
      return moment(timestamp).fromNow();
    },
    getIconClass(notification) {
      switch (notification.type) {
        case 'term_frequency':
          return 'fas fa-font';
        case 'sentiment':
          return notification.subtype === 'positive' ? 'fas fa-smile' : 'fas fa-frown';
        case 'topic':
          return 'fas fa-lightbulb';
        default:
          return 'fas fa-bell';
      }
    }
  },
  created() {
    moment.locale('fr');
  }
}
</script>

<style scoped>
.notification-center-wrapper {
  @apply relative;
}

.notification-button {
  @apply relative p-2 text-gray-500 hover:text-gray-700 focus:outline-none;
}

.badge {
  @apply absolute -top-1 -right-1 bg-red-500 text-white text-xs rounded-full h-5 min-w-[1.25rem] flex items-center justify-center px-1;
}

.notification-center {
  @apply absolute right-0 top-full mt-2 w-80 bg-white rounded-lg shadow-lg overflow-hidden z-50;
}

.notification-header {
  @apply flex items-center justify-between p-4 border-b border-gray-200;
}

.notification-header h3 {
  @apply text-lg font-semibold text-gray-800;
}

.notification-actions {
  @apply flex items-center;
}

.action-button {
  @apply text-sm text-blue-500 hover:text-blue-700 mr-2;
}

.close-button {
  @apply text-gray-500 hover:text-gray-700 focus:outline-none;
}

.notification-tabs {
  @apply flex border-b border-gray-200;
}

.tab-button {
  @apply flex-1 py-2 text-center text-sm text-gray-600 hover:text-gray-800 focus:outline-none;
}

.tab-button.active {
  @apply text-blue-500 border-b-2 border-blue-500;
}

.notification-list {
  @apply max-h-80 overflow-y-auto;
}

.notification-item {
  @apply flex p-4 border-b border-gray-200 hover:bg-gray-50 cursor-pointer;
}

.notification-item.unread {
  @apply bg-blue-50;
}

.notification-icon {
  @apply flex-shrink-0 w-10 h-10 rounded-full flex items-center justify-center mr-3;
}

.notification-icon.high {
  @apply bg-red-100 text-red-500;
}

.notification-icon.medium {
  @apply bg-yellow-100 text-yellow-500;
}

.notification-icon.low {
  @apply bg-blue-100 text-blue-500;
}

.notification-content {
  @apply flex-1;
}

.notification-message {
  @apply text-sm text-gray-800 mb-1;
}

.notification-time {
  @apply text-xs text-gray-500;
}

.empty-state {
  @apply flex flex-col items-center justify-center py-8 text-gray-500;
}

.empty-state i {
  @apply text-2xl mb-2;
}

.notification-footer {
  @apply flex justify-between p-4 border-t border-gray-200 text-sm;
}

.notification-footer a {
  @apply text-blue-500 hover:text-blue-700;
}
</style>
