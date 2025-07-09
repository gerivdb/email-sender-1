# Spécification du ContextManager étendu pour Jan

Spécification de l'API et du schéma de données pour le ContextManager, adapté à l'orchestration séquentielle multi-personas avec Jan.

## API

### `StoreDialogueHistory`
- **Description**: Stocke un message dans l'historique de dialogue d'un persona spécifique.
- **Paramètres**:
  - `persona`: `string (identifiant unique du persona)`
  - `message`: `string (le message à stocker)`
- **Retourne**: `void`

### `GetDialogueContext`
- **Description**: Récupère les 'n' derniers messages de l'historique de dialogue d'un persona.
- **Paramètres**:
  - `persona`: `string (identifiant unique du persona)`
  - `n`: `int (nombre de messages à récupérer)`
- **Retourne**: `[]string (slice de messages)`

### `GetGlobalContext`
- **Description**: Récupère le contexte global partagé entre tous les personas.
- **Paramètres**:
  - Aucun
- **Retourne**: `map[string]interface{} (contexte global)`

### `UpdateGlobalContext`
- **Description**: Met à jour le contexte global partagé avec de nouvelles données.
- **Paramètres**:
  - `value`: `interface{} (valeur de la donnée)`
  - `key`: `string (clé de la donnée)`
- **Retourne**: `void`

### `ClearDialogueHistory`
- **Description**: Efface l'historique de dialogue d'un persona ou de tous les personas.
- **Paramètres**:
  - `persona`: `string (optionnel, si vide efface tout)`
- **Retourne**: `void`

## Schéma des Données Internes

| Propriété | Type | Description |
|---|---|---|
| `history` | `map[string][]string` | Historique des dialogues, clé: persona, valeur: liste de messages. |
| `globalContext` | `map[string]interface{}` | Contexte global partagé entre tous les personas. |

## Hooks (Points d'extension)

| Hook | Description | Quand |
|---|---|---|
| `OnBeforeStore` | Exécuté avant le stockage d'un message. | before |
| `OnAfterStore` | Exécuté après le stockage d'un message. | after |
| `OnContextRetrieval` | Exécuté lors de la récupération du contexte. | after |

## Critères de Validation
- La spécification est complète et cohérente.
- Le format JSON est valide.
- Le fichier `spec_contextmanager_jan.md` est généré.
- Le schéma des données, l'API et les hooks sont clairement définis.
- La spécification est validée par des tests de structure (via ce script) et une revue humaine.
