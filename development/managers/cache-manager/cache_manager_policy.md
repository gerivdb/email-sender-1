# Politique d’Orchestration — CacheManager v74

## 1. Priorité des backends

- LMCache est utilisé par défaut pour tous les logs/contextes.
- Redis est utilisé en fallback si LMCache est indisponible.
- SQLite est utilisé comme dernier recours (mode dégradé/local).

## 2. Critères de sélection

- Logs critiques (ERROR/FATAL) : toujours stockés dans LMCache et Redis.
- Logs volumineux ou analytiques : prioritairement Redis.
- Données contextuelles LLM : LMCache obligatoire.
- Mode offline : SQLite seul.

## 3. Routage dynamique

- La sélection du backend peut être ajustée dynamiquement via configuration ou API.
- Les quotas et règles de filtrage sont appliqués avant routage.

## 4. Robustesse

- Si un backend échoue, tentative automatique sur le suivant.
- Journalisation des erreurs de routage.

## 5. Audit & traçabilité

- Toutes les opérations de routage sont loguées (audit trail).
- Les changements de politique sont historisés.

---

*À adapter lors de l’implémentation effective.*
