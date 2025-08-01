# Spécification API — Move Files

> **Version** : 1.0  
> **Auteur** : Roo  
> **Date** : 2025-08-01  
> **Description** : API REST pour piloter le déplacement de fichiers selon une configuration YAML, avec support dry-run, rollback, audit, validation.

---

## Sommaire

- [Vue d’ensemble](#vue-densemble)
- [Endpoints](#endpoints)
- [Schémas](#schémas)
- [Exemples de requêtes/réponses](#exemples)
- [Codes d’erreur](#codes-derreur)
- [Sécurité](#sécurité)
- [Liens utiles](#liens-utiles)

---

## Vue d’ensemble

Cette API permet :
- de lancer un déplacement de fichiers selon une config YAML,
- de simuler l’opération (dry-run),
- d’annuler le dernier déplacement (rollback),
- de consulter l’audit/log,
- de valider une configuration.

---

## Endpoints

### 1. Lancer un déplacement

- **POST** `/api/move-files`
- **Body** : `application/x-yaml` ou `application/json`
- **Query** : `?dryRun=true` (optionnel)
- **Réponse** : 200 OK, 400 erreur validation, 500 erreur interne

### 2. Rollback

- **POST** `/api/move-files/rollback`
- **Réponse** : 200 OK, 404 rien à annuler, 500 erreur

### 3. Audit

- **GET** `/api/move-files/audit`
- **Réponse** : 200 OK, log text/plain ou JSON

### 4. Validation de configuration

- **POST** `/api/move-files/validate`
- **Body** : `application/x-yaml` ou `application/json`
- **Réponse** : 200 OK (valide), 400 (invalide)

---

## Schémas

### Configuration YAML attendue

```yaml
moves:
  - src: chemin/source.txt
    dst: chemin/destination.txt
  - src: dossier/a.txt
    dst: dossier/b.txt
```

### Réponse standard

```json
{
  "success": true,
  "details": [
    {"src": "a.txt", "dst": "b.txt", "status": "done"}
  ],
  "errors": []
}
```

---

## Exemples

### Lancer un déplacement

```http
POST /api/move-files?dryRun=true
Content-Type: application/x-yaml

moves:
  - src: "a.txt"
    dst: "b.txt"
```

**Réponse :**

```json
{
  "success": true,
  "details": [
    {"src": "a.txt", "dst": "b.txt", "status": "dry-run"}
  ]
}
```

### Rollback

```http
POST /api/move-files/rollback
```

**Réponse :**

```json
{
  "success": true,
  "restored": [
    {"from": "b.txt", "to": "a.txt"}
  ]
}
```

### Audit

```http
GET /api/move-files/audit
```

**Réponse :**

```
[2025-08-01T11:00:00] Déplacé : a.txt -> b.txt
[2025-08-01T11:01:00] Rollback : b.txt -> a.txt
```

---

## Codes d’erreur

| Code | Description                       |
|------|-----------------------------------|
| 200  | Succès                            |
| 400  | Erreur de validation (YAML, etc.) |
| 404  | Ressource non trouvée             |
| 500  | Erreur interne serveur            |

---

## Sécurité

- Authentification par clé API ou token recommandée.
- Validation stricte des chemins (pas de traversée de répertoire).
- Logging/audit de toutes les opérations.

---

## Liens utiles

- [README.file-moves.md](README.file-moves.md)
- [file-moves.schema.yaml](file-moves.schema.yaml)
- [AGENTS.md](AGENTS.md)
- [rules.md](.roo/rules/rules.md)

---