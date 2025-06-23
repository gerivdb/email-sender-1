# VersionManagerImpl

- **Rôle :** Gestion centralisée des versions documentaires ou applicatives : comparaison, compatibilité, récupération de versions, sélection optimale.
- **Interfaces :**
  - `CompareVersions(v1, v2 string) int`
  - `IsCompatible(version string, constraints []string) bool`
  - `GetLatestVersion(ctx context.Context, packageName string) (string, error)`
  - `GetLatestStableVersion(ctx context.Context, packageName string) (string, error)`
  - `FindBestVersion(versions []string, constraints []string) (string, error)`
- **Utilisation :** Suivi, comparaison, validation et sélection de versions pour les dépendances ou documents ; utilisé par les managers de dépendances, migration, etc.
- **Entrée/Sortie :**
  - Entrées : versions, contraintes, contextes d’exécution, noms de packages.
  - Sorties : résultats de comparaison, versions compatibles, erreurs éventuelles.

---

[Retour à l’index des managers](INDEX.md) | [Vue d’ensemble de l’architecture](../ARCHITECTURE/ecosystem-overview.md)
