# Règles de filtrage, quotas et masquage — Logging & CacheManager v74

## 1. Niveaux de logs

- Seuls les logs de niveau >= configuré (ex : INFO, WARN, ERROR, FATAL) sont stockés par défaut
- Les logs DEBUG sont conservés uniquement si le mode debug est activé

## 2. Inclusion/Exclusion

- Inclusion : modules/managers listés dans la whitelist toujours loggés
- Exclusion : modules/scripts en blacklist ignorés sauf override

## 3. Quotas & volumétrie

- Limite de taille par fichier log (ex : 10 Mo, rotation automatique)
- Quota de logs par source (ex : max 1000 logs/heure/module)
- Suppression automatique des logs les plus anciens si quota dépassé

## 4. Masquage & sécurité

- Masquage automatique des champs sensibles (mots de passe, tokens, secrets) via regex
- Logs contenant des patterns sensibles tronqués ou anonymisés

## 5. Règles dynamiques

- Activation/désactivation dynamique via API (ex : logs DEBUG pour un module donné)
- Application immédiate sans redémarrage

## 6. Exceptions

- Logs d’erreur système (ERROR/FATAL) toujours stockés, même si source blacklistée
- Logs critiques envoyés en priorité à LMCache et central-terminal.log

## 7. Validation

- Tests automatisés sur le filtrage, quotas, masquage
- Revue croisée de la configuration
- Audit trail des changements de règles

---

*Document validé, à enrichir lors de l’implémentation réelle.*
