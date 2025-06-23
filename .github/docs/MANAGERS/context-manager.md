# ContextManager

- **Rôle :** Gestion centralisée du contexte documentaire ou applicatif : persistance, restauration, sauvegarde automatique, gestion des snapshots et de l’état des panels/UI.
- **Interfaces :**
  - `SaveState(pm *PanelManager, fm *FloatingManager, minimizer *PanelMinimizer) error`
  - `LoadLatestState() (*ContextState, error)`
  - `LoadStateByTime(timestamp time.Time) (*ContextState, error)`
  - `RestoreState(state *ContextState, pm *PanelManager, fm *FloatingManager, minimizer *PanelMinimizer) error`
  - `ListSavedStates() ([]time.Time, error)`
  - `SetMaxSnapshots(max int)`
  - `SetAutoSaveInterval(interval time.Duration)`
  - `MarkDirty()`
  - `ShouldAutoSave() bool`
  - `DeleteState(timestamp time.Time) error`
  - `GetStateInfo(timestamp time.Time) (*ContextState, error)`
- **Utilisation :** Centralisation et gestion du contexte d’exécution, sauvegarde/restauration d’état, gestion de l’historique et des snapshots, intégration UI (panels, fenêtres, navigation), gestion de la persistance et de la sécurité (compression, chiffrement).
- **Entrée/Sortie :**
  - Entrées : panels, managers, états UI, timestamps, configurations de sauvegarde.
  - Sorties : contextes restaurés, listes de snapshots, statuts, logs, erreurs.

---

[Retour à l’index des managers](INDEX.md) | [Vue d’ensemble de l’architecture](../ARCHITECTURE/ecosystem-overview.md)
