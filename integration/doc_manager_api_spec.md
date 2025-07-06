# Spécifications de l'API du Doc Manager

## 1. Introduction
Ce document décrit l'API REST/gRPC (à déterminer) du Doc Manager, utilisée pour l'intégration et la synchronisation de la documentation.

## 2. Points d'intégration (Endpoints)

### 2.1. Authentification
- **Méthode:** (Ex: `POST /auth/login`)
- **Description:** Permet d'obtenir un jeton d'authentification.
- **Requête:**
  ```json
  {
    "username": "your_username",
    "password": "your_password"
  }
  ```
- **Réponse (Succès):**
  ```json
  {
    "token": "your_auth_token",
    "expires_in": 3600
  }
  ```
- **Réponse (Erreur):**
  ```json
  {
    "error": "Invalid credentials"
  }
  ```

### 2.2. Synchronisation de la Documentation
- **Méthode:** (Ex: `POST /docs/sync`)
- **Description:** Déclenche une synchronisation de la documentation.
- **Requête:**
  ```json
  {
    "source_path": "/path/to/docs",
    "force_update": false
  }
  ```
- **Réponse (Succès):**
  ```json
  {
    "status": "synchronization_started",
    "task_id": "sync-12345"
  }
  ```
- **Réponse (Erreur):**
  ```json
  {
    "error": "Synchronization failed",
    "details": "Permission denied"
  }
  ```

### 2.3. Mise à Jour Spécifique
- **Méthode:** (Ex: `PUT /docs/{doc_id}`)
- **Description:** Met à jour un document spécifique.
- **Requête:**
  ```json
  {
    "content": "New document content",
    "metadata": {
      "version": "1.1"
    }
  }
  ```
- **Réponse (Succès):**
  ```json
  {
    "status": "document_updated",
    "doc_id": "doc-abc"
  }
  ```
- **Réponse (Erreur):**
  ```json
  {
    "error": "Document not found"
  }
  ```

## 3. Modèles de Données

### 3.1. Document
```json
{
  "id": "string",
  "title": "string",
  "content": "string",
  "last_modified": "datetime",
  "metadata": "object"
}
```

## 4. Codes de Réponse HTTP
- `200 OK`: Requête réussie.
- `201 Created`: Ressource créée avec succès.
- `400 Bad Request`: Requête mal formée.
- `401 Unauthorized`: Authentification requise ou échouée.
- `403 Forbidden`: Accès refusé.
- `404 Not Found`: Ressource non trouvée.
- `500 Internal Server Error`: Erreur interne du serveur.

## 5. Exemples d'Utilisation
(Des exemples de requêtes `curl` ou de code Go/Python seront ajoutés ici.)
