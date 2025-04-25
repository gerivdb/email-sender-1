<template>
  <div class="notifications-panel">
    <div class="panel-header">
      <h3>Notifications</h3>
      <div class="header-actions">
        <button 
          v-if="unreadNotifications.length > 0"
          @click="markAllAsRead" 
          class="mark-all-button"
        >
          Tout marquer comme lu
        </button>
        <button @click="$emit('close')" class="close-button">
          <i class="fas fa-times"></i>
        </button>
      </div>
    </div>
    
    <div class="panel-content">
      <div v-if="loading" class="loading-state">
        <i class="fas fa-spinner fa-spin"></i>
        <p>Chargement des notifications...</p>
      </div>
      
      <div v-else-if="notifications.length === 0" class="empty-state">
        <i class="fas fa-bell-slash"></i>
        <p>Aucune notification</p>
      </div>
      
      <div v-else class="notifications-list">
        <div 
          v-for="notification in notifications" 
          :key="notification.id"
          class="notification-item"
          :class="{ 
            unread: !notification.read,
            'severity-high': notification.severity === 'high',
            'severity-medium': notification.severity === 'medium',
            'severity-low': notification.severity === 'low'
          }"
          @click="viewNotification(notification)"
        >
          <div class="notification-icon" :class="notification.type">
            <i :class="getNotificationIcon(notification)"></i>
          </div>
          
          <div class="notification-content">
            <div class="notification-message">{{ notification.message }}</div>
            <div class="notification-meta">
              <span class="notification-time">{{ formatTime(notification.timestamp) }}</span>
              <span v-if="!notification.read" class="unread-indicator"></span>
            </div>
          </div>
        </div>
      </div>
    </div>
    
    <div class="panel-footer">
      <button @click="openSettings" class="settings-button">
        <i class="fas fa-cog"></i>
        Paramètres
      </button>
    </div>
  </div>
</template>

<script>
import { mapGetters, mapActions } from 'vuex';

export default {
  name: 'NotificationsPanel',
  props: {
    maxNotifications: {
      type: Number,
      default: 10
    }
  },
  data() {
    return {
      selectedNotification: null
    };
  },
  computed: {
    ...mapGetters({
      allNotifications: 'notifications/notifications',
      unreadNotifications: 'notifications/unreadNotifications',
      loading: 'notifications/isLoading',
      error: 'notifications/error'
    }),
    
    notifications() {
      return this.allNotifications.slice(0, this.maxNotifications);
    }
  },
  mounted() {
    this.fetchNotifications();
  },
  methods: {
    ...mapActions({
      fetchNotifications: 'notifications/fetchNotifications',
      markNotificationAsRead: 'notifications/markNotificationAsRead',
      markAllNotificationsAsRead: 'notifications/markAllNotificationsAsRead'
    }),
    
    getNotificationIcon(notification) {
      switch (notification.type) {
        case 'term_frequency':
          return 'fas fa-chart-line';
        case 'sentiment':
          return notification.subtype === 'positive' ? 'fas fa-smile' : 'fas fa-frown';
        case 'topic':
          return 'fas fa-lightbulb';
        default:
          return 'fas fa-bell';
      }
    },
    
    formatTime(timestamp) {
      if (!timestamp) return '';
      
      const date = new Date(timestamp);
      const now = new Date();
      const diff = now - date;
      
      // Moins d'une minute
      if (diff < 60000) {
        return 'À l\'instant';
      }
      
      // Moins d'une heure
      if (diff < 3600000) {
        const minutes = Math.floor(diff / 60000);
        return `Il y a ${minutes} minute${minutes > 1 ? 's' : ''}`;
      }
      
      // Moins d'un jour
      if (diff < 86400000) {
        const hours = Math.floor(diff / 3600000);
        return `Il y a ${hours} heure${hours > 1 ? 's' : ''}`;
      }
      
      // Moins d'une semaine
      if (diff < 604800000) {
        const days = Math.floor(diff / 86400000);
        return `Il y a ${days} jour${days > 1 ? 's' : ''}`;
      }
      
      // Date complète
      return date.toLocaleDateString('fr-FR', {
        day: 'numeric',
        month: 'short',
        year: 'numeric'
      });
    },
    
    viewNotification(notification) {
      // Marquer comme lu
      if (!notification.read) {
        this.markNotificationAsRead(notification.id);
      }
      
      // Afficher les détails
      this.selectedNotification = notification;
      
      // Émettre un événement pour informer le parent
      this.$emit('view-notification', notification);
    },
    
    markAllAsRead() {
      this.markAllNotificationsAsRead();
    },
    
    openSettings() {
      this.$router.push({ name: 'settings', query: { tab: 'notifications' } });
      this.$emit('close');
    }
  }
};
</script>

<style scoped>
.notifications-panel {
  @apply flex flex-col bg-white border border-gray-200 rounded-lg shadow-lg overflow-hidden;
  width: 350px;
  max-height: 500px;
}

.panel-header {
  @apply flex justify-between items-center p-3 border-b border-gray-200 bg-gray-50;
}

.panel-header h3 {
  @apply text-lg font-semibold text-gray-800;
}

.header-actions {
  @apply flex items-center;
}

.mark-all-button {
  @apply text-xs text-blue-600 hover:text-blue-800 mr-2 focus:outline-none;
}

.close-button {
  @apply text-gray-500 hover:text-gray-700 focus:outline-none;
}

.panel-content {
  @apply flex-1 overflow-y-auto;
  max-height: 400px;
}

.loading-state, .empty-state {
  @apply flex flex-col items-center justify-center p-6 text-gray-500;
}

.loading-state i, .empty-state i {
  @apply text-2xl mb-2;
}

.notifications-list {
  @apply divide-y divide-gray-100;
}

.notification-item {
  @apply flex items-start p-3 hover:bg-gray-50 cursor-pointer;
}

.notification-item.unread {
  @apply bg-blue-50;
}

.notification-item.severity-high {
  @apply border-l-4 border-red-500;
}

.notification-item.severity-medium {
  @apply border-l-4 border-yellow-500;
}

.notification-item.severity-low {
  @apply border-l-4 border-green-500;
}

.notification-icon {
  @apply flex-shrink-0 w-8 h-8 flex items-center justify-center rounded-full mr-3;
}

.notification-icon.term_frequency {
  @apply bg-green-100 text-green-600;
}

.notification-icon.sentiment {
  @apply bg-blue-100 text-blue-600;
}

.notification-icon.topic {
  @apply bg-purple-100 text-purple-600;
}

.notification-content {
  @apply flex-1;
}

.notification-message {
  @apply text-sm text-gray-800 mb-1;
}

.notification-meta {
  @apply flex items-center text-xs text-gray-500;
}

.notification-time {
  @apply mr-2;
}

.unread-indicator {
  @apply w-2 h-2 bg-blue-500 rounded-full;
}

.panel-footer {
  @apply p-3 border-t border-gray-200 bg-gray-50;
}

.settings-button {
  @apply flex items-center text-sm text-gray-600 hover:text-gray-800 focus:outline-none;
}

.settings-button i {
  @apply mr-1;
}
</style>
