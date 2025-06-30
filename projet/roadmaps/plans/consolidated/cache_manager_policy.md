# Politique d’orchestration multi-backend — CacheManager v74

## Règles principales

- LMCache est le backend prioritaire pour tous les logs et contextes (stockage et lecture)
- Si LMCache échoue, fallback automatique sur Redis, puis sur SQLite
- Les logs critiques (ERROR/FATAL) sont stockés sur tous les backends disponibles
- Les contextes LLM sont toujours stockés dans LMCache et Redis (redondance)
- Les logs de niveau DEBUG ne sont stockés que si le mode debug est activé (flag)
- Les quotas, filtrage et masquage sont appliqués avant l’écriture sur chaque backend

## Exceptions

- Si tous les backends échouent, une erreur critique est remontée et loggée localement
- Les logs système (audit, rollback) sont toujours stockés dans SQLite en plus de LMCache

## Implémentation

- La méthode StoreLog du CacheManager tente chaque backend dans l’ordre de priorité
- La méthode GetLogs interroge LMCache en priorité, puis fallback sur Redis/SQLite si besoin
- Les tests d’intégration doivent simuler la panne d’un backend et vérifier le fallback

---

*Document validé, à versionner et à aligner avec le code Go du CacheManager.*
