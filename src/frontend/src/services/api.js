import axios from 'axios';

// Créer une instance axios avec la configuration de base
const api = axios.create({
  baseURL: process.env.VUE_APP_API_URL || 'http://localhost:8000/api',
  headers: {
    'Content-Type': 'application/json',
    'Accept': 'application/json'
  }
});

// Intercepteur pour les requêtes
api.interceptors.request.use(
  config => {
    // Ajouter le token d'authentification si disponible
    const token = localStorage.getItem('auth_token');
    if (token) {
      config.headers['Authorization'] = `Bearer ${token}`;
    }
    return config;
  },
  error => {
    return Promise.reject(error);
  }
);

// Intercepteur pour les réponses
api.interceptors.response.use(
  response => {
    return response;
  },
  error => {
    // Gérer les erreurs globalement
    if (error.response) {
      // Le serveur a répondu avec un code d'erreur
      if (error.response.status === 401) {
        // Non autorisé - déconnecter l'utilisateur
        localStorage.removeItem('auth_token');
        // Rediriger vers la page de connexion si nécessaire
      }
    }
    return Promise.reject(error);
  }
);

export default api;
