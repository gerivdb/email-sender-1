# Interface Web - Documentation Technique

## Vue d'ensemble

L'interface web fournit un accès unifié à toutes les fonctionnalités du système de journal de bord. Elle permet de visualiser les entrées, d'effectuer des recherches, d'explorer les analyses et d'interagir avec l'intégration GitHub.

## Architecture

L'interface web est basée sur une architecture client-serveur:

```plaintext
┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│  Frontend   │ ◄─► │  API REST   │ ◄─► │  Backend    │
│  (Browser)  │     │  (FastAPI)  │     │  (Python)   │
└─────────────┘     └─────────────┘     └─────────────┘
                                              │
                                              ▼
                                        ┌─────────────┐
                                        │  Journal    │
                                        │  de Bord    │
                                        └─────────────┘
```plaintext
## Backend (FastAPI)

Le backend est implémenté avec FastAPI, un framework web Python moderne et performant.

### Script principal: web_app.py

Ce script implémente l'API REST:

```python
# Démarrer l'application web

python scripts/python/journal/web_app.py
```plaintext
### Structure modulaire

L'API est organisée en modules:

- **web_app.py**: Point d'entrée principal
- **web_routes/journal_routes.py**: Routes pour le journal
- **web_routes/analysis_routes.py**: Routes pour l'analyse
- **web_routes/github_routes.py**: Routes pour l'intégration GitHub

### Points d'entrée API

L'API expose les points d'entrée suivants:

#### Journal

```plaintext
GET /api/journal/entries - Liste les entrées du journal
POST /api/journal/search - Recherche dans le journal
POST /api/journal/rag - Interroge le système RAG
GET /api/journal/tags - Récupère tous les tags
GET /api/journal/entry/{filename} - Récupère une entrée spécifique
```plaintext
#### Analyse

```plaintext
GET /api/analysis/term-frequency - Analyse de fréquence des termes
GET /api/analysis/word-cloud - Nuage de mots
GET /api/analysis/tag-evolution - Évolution des tags
GET /api/analysis/topic-trends - Tendances des sujets
GET /api/analysis/clusters - Clustering des entrées
GET /api/analysis/insights - Insights extraits du journal
```plaintext
#### GitHub

```plaintext
GET /api/github/commits - Commits récents
GET /api/github/issues - Issues GitHub
GET /api/github/commit-entries - Associations commit-entrées
GET /api/github/issue-entries - Associations issue-entrées
POST /api/github/create-entry-from-issue - Crée une entrée à partir d'une issue
```plaintext
### Modèles de données

L'API utilise des modèles Pydantic pour valider les données:

```python
class SearchQuery(BaseModel):
    query: str
    limit: int = 10

class IssueRequest(BaseModel):
    issue_number: int
```plaintext
### Fichiers statiques

L'API sert également des fichiers statiques:

```python
app.mount("/static", StaticFiles(directory=str(static_dir)), name="static")
```plaintext
## Frontend

Le frontend est conçu pour être simple et intuitif, permettant aux utilisateurs d'accéder facilement à toutes les fonctionnalités du système.

### Pages principales

- **Journal**: Affiche les entrées du journal et permet la recherche
- **Analyse**: Affiche les analyses et visualisations
- **GitHub**: Affiche les commits, issues et leurs relations avec le journal

### Composants

- **JournalView**: Affiche les entrées du journal
- **SearchBar**: Permet de rechercher dans le journal
- **AnalysisView**: Affiche les analyses et visualisations
- **GitHubView**: Affiche les commits, issues et leurs relations avec le journal

### Exemple de composant: AnalysisView

```javascript
// AnalysisView.vue (Vue.js)
<template>
  <div class="analysis-container">
    <h2 class="text-2xl font-bold mb-4">Analyse du Journal de Bord</h2>
    
    <div class="mb-6">
      <h3 class="text-xl font-semibold mb-2">Nuage de mots</h3>
      <div class="flex mb-2">
        <button @click="period = null" :class="{ 'bg-blue-500 text-white': period === null }" class="px-3 py-1 mr-2 rounded border">Tous</button>
        <button @click="period = 'month'" :class="{ 'bg-blue-500 text-white': period === 'month' }" class="px-3 py-1 mr-2 rounded border">Par mois</button>
        <button @click="period = 'week'" :class="{ 'bg-blue-500 text-white': period === 'week' }" class="px-3 py-1 rounded border">Par semaine</button>
      </div>
      <div v-if="wordCloudUrl" class="border p-4 rounded">
        <img :src="wordCloudUrl" alt="Nuage de mots" class="mx-auto" />
      </div>
    </div>
    
    <!-- Autres sections d'analyse -->
  </div>
</template>

<script>
export default {
  data() {
    return {
      period: null,
      wordCloudUrl: null,
      // Autres données
    }
  },
  mounted() {
    this.fetchWordCloud();
    // Autres initialisations
  },
  methods: {
    async fetchWordCloud() {
      try {
        const url = this.period 
          ? `/api/analysis/word-cloud?period=${this.period}` 
          : '/api/analysis/word-cloud';
        
        const response = await fetch(url);
        const data = await response.json();
        this.wordCloudUrl = data.image_url;
      } catch (error) {
        console.error('Erreur lors de la récupération du nuage de mots:', error);
      }
    },
    // Autres méthodes
  }
}
</script>
```plaintext
## Démarrage de l'application

Le script `start-journal-web.ps1` permet de configurer et démarrer l'application web:

```powershell
# Démarrer l'application web

.\scripts\cmd\start-journal-web.ps1
```plaintext
Ce script:
1. Installe les dépendances nécessaires
2. Vérifie que les répertoires requis existent
3. Génère les analyses si elles n'existent pas
4. Démarre l'application web

## Configuration CORS

L'API est configurée pour permettre les requêtes cross-origin:

```python
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # À restreindre en production

    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)
```plaintext
## Dépendances

L'interface web utilise plusieurs bibliothèques et frameworks:

- **FastAPI**: Framework web Python
- **Uvicorn**: Serveur ASGI pour FastAPI
- **Pydantic**: Validation des données
- **Vue.js** (prévu): Framework JavaScript pour le frontend
- **Tailwind CSS** (prévu): Framework CSS pour le styling

## Sécurité

L'interface web actuelle est conçue pour un usage local et ne comprend pas de mécanismes d'authentification ou d'autorisation. Pour un déploiement en production, il faudrait ajouter:

1. **Authentification**: Système de login/password ou OAuth
2. **Autorisation**: Contrôle d'accès basé sur les rôles
3. **HTTPS**: Chiffrement des communications
4. **Rate limiting**: Limitation du nombre de requêtes
5. **Validation des entrées**: Protection contre les injections

## Déploiement

L'application est actuellement conçue pour être exécutée localement. Pour un déploiement en production, plusieurs options sont possibles:

1. **Serveur dédié**: Déployer sur un serveur avec Nginx comme proxy inverse
2. **Docker**: Conteneuriser l'application pour un déploiement plus facile
3. **Cloud**: Déployer sur un service cloud comme Azure App Service ou AWS Elastic Beanstalk

## Limitations actuelles

1. **Frontend minimal**: L'interface utilisateur actuelle est basique
2. **Pas d'authentification**: Aucun mécanisme de sécurité n'est implémenté
3. **Performance**: Certaines opérations peuvent être lentes sur de grands volumes de données
4. **Pas de temps réel**: Les mises à jour ne sont pas propagées en temps réel

## Améliorations futures

1. **Frontend complet**: Développer un frontend complet avec Vue.js ou React
2. **Authentification**: Ajouter un système d'authentification
3. **Temps réel**: Utiliser WebSockets pour les mises à jour en temps réel
4. **Visualisations interactives**: Ajouter des visualisations interactives avec D3.js
5. **Mode hors ligne**: Permettre l'utilisation hors ligne avec un service worker
6. **Application mobile**: Développer une application mobile compagnon
7. **Intégration IDE**: Développer une extension VS Code pour une intégration plus profonde
