import { createRouter, createWebHistory } from 'vue-router'
import store from '@/store'

// Vues principales
import Dashboard from '@/views/Dashboard.vue'
import Journal from '@/views/Journal.vue'
import JournalEntry from '@/views/JournalEntry.vue'
import JournalCreate from '@/views/JournalCreate.vue'
import Analysis from '@/views/Analysis.vue'
import GitHub from '@/views/GitHub.vue'
import Jira from '@/views/Jira.vue'
import Notion from '@/views/Notion.vue'
import Settings from '@/views/Settings.vue'
import Notifications from '@/views/Notifications.vue'
import Search from '@/views/Search.vue'
import Login from '@/views/Login.vue'

const routes = [
  {
    path: '/',
    name: 'dashboard',
    component: Dashboard,
    meta: {
      title: 'Dashboard',
      requiresAuth: true
    }
  },
  {
    path: '/journal',
    name: 'journal',
    component: Journal,
    meta: {
      title: 'Journal de Bord',
      requiresAuth: true
    }
  },
  {
    path: '/journal/entry/:id',
    name: 'journal-entry',
    component: JournalEntry,
    meta: {
      title: 'Entrée du Journal',
      requiresAuth: true
    }
  },
  {
    path: '/journal/create',
    name: 'journal-create',
    component: JournalCreate,
    meta: {
      title: 'Nouvelle Entrée',
      requiresAuth: true
    }
  },
  {
    path: '/analysis',
    name: 'analysis',
    component: Analysis,
    meta: {
      title: 'Analyse',
      requiresAuth: true
    }
  },
  {
    path: '/github',
    name: 'github',
    component: GitHub,
    meta: {
      title: 'GitHub',
      requiresAuth: true
    }
  },
  {
    path: '/jira',
    name: 'jira',
    component: Jira,
    meta: {
      title: 'Jira',
      requiresAuth: true
    }
  },
  {
    path: '/notion',
    name: 'notion',
    component: Notion,
    meta: {
      title: 'Notion',
      requiresAuth: true
    }
  },
  {
    path: '/settings',
    name: 'settings',
    component: Settings,
    meta: {
      title: 'Paramètres',
      requiresAuth: true
    }
  },
  {
    path: '/notifications',
    name: 'notifications',
    component: Notifications,
    meta: {
      title: 'Notifications',
      requiresAuth: true
    }
  },
  {
    path: '/search',
    name: 'search',
    component: Search,
    meta: {
      title: 'Recherche',
      requiresAuth: true
    }
  },
  {
    path: '/login',
    name: 'login',
    component: Login,
    meta: {
      title: 'Connexion',
      requiresAuth: false
    }
  }
]

const router = createRouter({
  history: createWebHistory(process.env.BASE_URL),
  routes
})

// Navigation guard
router.beforeEach((to, from, next) => {
  // Mettre à jour le titre de la page
  document.title = `${to.meta.title || 'Journal RAG'} - Journal de Bord RAG`

  // Désactiver temporairement la vérification d'authentification pour le développement
  // const requiresAuth = to.matched.some(record => record.meta.requiresAuth)
  // const isAuthenticated = store.getters.isAuthenticated

  // if (requiresAuth && !isAuthenticated) {
  //   next('/login')
  // } else {
  //   next()
  // }

  // Toujours autoriser la navigation en mode développement
  next()
})

export default router
