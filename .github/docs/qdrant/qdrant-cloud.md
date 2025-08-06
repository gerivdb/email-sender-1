# Qdrant Cloud — Guide d’intégration Roo Code

> **Version dédiée Qdrant Cloud**  
> Ce guide complète la documentation générale Qdrant pour l’écosystème Roo Code. Il détaille la configuration, la sécurité et les bonnes pratiques spécifiques à l’utilisation de Qdrant Cloud comme backend vectoriel.

---

## Présentation

Qdrant Cloud permet d’héberger une base vectorielle managée, idéale pour l’indexation sémantique Roo Code (codebase indexing, recherche intelligente, etc.).  
Ce mode d’intégration est recommandé pour :
- Les équipes souhaitant mutualiser l’indexation
- Les environnements CI/CD ou multi-utilisateurs
- Les cas où la haute disponibilité et la sécurité sont prioritaires

---

## Paramètres de connexion (non confidentiels)

- **Nom du cluster** : (exemple : `qdrant-cloud-free-tier`)
- **Endpoint** : `https://<cluster-id>.cloud.qdrant.io`
- **Embedder provider** : Google Gemini, OpenAI, Ollama, etc.
- **Port** : 443 (HTTPS)

**À ne jamais documenter** :  
- Clé API Qdrant (voir section Sécurité)
- Clé API embedder

---

## Configuration Roo Code

1. **Créer un cluster Qdrant Cloud**  
   - Inscription sur [Qdrant Cloud](https://cloud.qdrant.io/)
   - Création du cluster (free tier possible)
   - Récupération de l’endpoint et de la clé API

2. **Configurer Roo Code**  
   - Ouvrir la configuration de l’indexeur (VSIX ou YAML)
   - Renseigner :
     - Qdrant URL : `https://<cluster-id>.cloud.qdrant.io`
     - Qdrant API Key : (à stocker dans un coffre ou VS Code secret storage)
     - Embedder provider et clé associée

3. **Bonnes pratiques**  
   - Stocker toutes les clés dans un coffre sécurisé (GitHub Actions, SecurityManager, etc.)
   - Ne jamais exposer les clés dans la documentation ou le code source
   - Limiter les permissions au strict nécessaire

---

## Sécurité et gestion des secrets

- **Clé API Qdrant** :  
  - À stocker dans un coffre (GitHub Actions, HashiCorp Vault, etc.)
  - Jamais dans le code ou la documentation
  - Rotation régulière recommandée

- **Gestion centralisée** :  
  - Utiliser le [`SecurityManager`](../../AGENTS.md:SecurityManager) Roo pour la gestion des secrets
  - Voir aussi [roles-integration.md](roles-integration.md#bonnes-pratiques-de-sécurité)

---

## Articulation avec Roo Code et mem0-analyser

- **QdrantManager** ([AGENTS.md:QdrantManager]) centralise l’accès à Qdrant Cloud pour tous les modules Roo Code.
- **mem0-analyser** ([../mem0-analysis/README.md]) : compatible Qdrant Cloud, configuration identique (endpoint, clé API).
- **Interopérabilité** :  
  - Les pipelines d’indexation (VSIX, mem0-analyser, scripts) peuvent pointer indifféremment vers le cloud ou le local via la configuration.
  - Les versions locales (Docker, binaire) restent supportées pour le développement ou la confidentialité maximale.

---

## Cas d’usage recommandés

- **Collaboration multi-utilisateurs**
- **CI/CD avec indexation partagée**
- **Déploiement SaaS ou cloud-native**

---

## Liens utiles et documentation croisée

- [Documentation générale Qdrant](README.md)
- [Guide sécurité Qdrant](roles-integration.md)
- [Guide installation Qdrant](installation.md)
- [Guide requirements Qdrant](requirements.md)
- [mem0-analyser](../mem0-analysis/README.md)
- [QdrantManager](../../AGENTS.md:QdrantManager)

---

## FAQ

**Q : Puis-je migrer de Qdrant local à Qdrant Cloud sans changer mon workflow ?**  
R : Oui, il suffit de modifier l’endpoint et la clé API dans la configuration.

**Q : Où stocker mes clés API ?**  
R : Toujours dans un coffre sécurisé ou le secret storage de VS Code/GitHub Actions.

**Q : Puis-je utiliser plusieurs clusters Qdrant Cloud ?**  
R : Oui, chaque pipeline peut cibler un cluster différent via la configuration.

---

> Pour toute question ou contribution, voir la documentation centrale Roo Code ou contacter l’équipe documentaire.