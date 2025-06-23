# ModeManager

- **Rôle :** Gestion centralisée des modes d’exécution ou de configuration documentaire : changement de mode, gestion de l’état, préférences, transitions, événements et historique.
- **Interfaces :**
  - `SwitchMode(targetMode NavigationMode) tea.Cmd`
  - `SwitchModeAdvanced(targetMode NavigationMode, options *TransitionOptions) tea.Cmd`
  - `GetCurrentMode() NavigationMode`
  - `GetModeConfig(mode NavigationMode) (*ModeConfig, error)`
  - `UpdateModeConfig(mode NavigationMode, config *ModeConfig) error`
  - `GetModeState(mode NavigationMode) (*ModeState, error)`
  - `RestoreState(state *ModeState) tea.Cmd`
  - `AddEventHandler(mode NavigationMode, handler ModeEventHandler) error`
  - `TriggerEvent(eventType ModeEventType, data map[string]interface{}) []tea.Cmd`
  - `GetAvailableModes() []NavigationMode`
  - `GetTransitionHistory() []ModeTransition`
  - `SetPreferences(prefs *ModePreferences)`
  - `GetPreferences() *ModePreferences`
- **Utilisation :** Changement et suivi des modes, gestion avancée des transitions, gestion de l’état et de l’historique, intégration UI, gestion des préférences utilisateur, gestion des événements et de la résilience (circuit breaker, ErrorManager).
- **Entrée/Sortie :**
  - Entrées : modes, configurations, options de transition, événements, préférences, états, contextes d’exécution.
  - Sorties : statuts, logs, historiques de transitions, états de mode, commandes UI, erreurs.

---

[Retour à l’index des managers](INDEX.md) | [Vue d’ensemble de l’architecture](../ARCHITECTURE/ecosystem-overview.md)
