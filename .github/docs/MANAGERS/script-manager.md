# ScriptManager

- **Rôle :** Orchestration complète de l’exécution, du suivi, du rechargement et de la gestion des scripts (PowerShell, etc.) avec intégration ErrorManager.
- **Interfaces :**
  - `ExecuteScript(scriptID string, parameters map[string]interface{}) (*ExecutionResult, error)`
  - `ListScripts() []*ManagedScript`
  - `GetScript(scriptID string) (*ManagedScript, error)`
  - `CreateScriptFromTemplate(templateID, scriptName string, parameters map[string]interface{}) (*ManagedScript, error)`
  - `Shutdown() error`
- **Utilisation :** Centralise l’exécution, la découverte, la création et la gestion des scripts et templates. Utilisé par d’autres modules pour automatiser des tâches via scripts.
- **Entrée/Sortie :**
  - Entrées : identifiants de scripts, paramètres d’exécution, templates, contexte d’exécution.
  - Sorties : résultats d’exécution, erreurs, logs, scripts générés.

---

[Retour à l’index des managers](INDEX.md) | [Vue d’ensemble de l’architecture](../ARCHITECTURE/ecosystem-overview.md)
