# Règles de Filtrage des Logs — CacheManager v74

## 1. Niveaux de logs

- Seuls les logs de niveau >= configuré (ex : INFO, WARN, ERROR, FATAL) sont stockés par défaut.
- Les logs DEBUG sont conservés uniquement si le mode debug est activé.

## 2. Inclusion/Exclusion

- Inclusion : tous les modules/managers listés dans la whitelist sont toujours loggés.
- Exclusion : modules/scripts en blacklist (ex : tests temporaires, scripts de debug) sont ignorés sauf si override.

## 3. Quotas & Volumétrie

- Limite de taille par fichier log (ex : 10 Mo, rotation automatique).
- Quota de logs par source (ex : max 1000 logs/heure/module).
- Suppression automatique des logs les plus anciens si quota dépassé.

## 4. Masquage & Sécurité

- Masquage automatique des champs sensibles (ex : mots de passe, tokens, secrets) via regex.
- Les logs contenant des patterns sensibles sont tronqués ou anonymisés.

## 5. Règles dynamiques

- Possibilité d’activer/désactiver dynamiquement des règles via API (ex : activer logs DEBUG pour un module donné).
- Application immédiate sans redémarrage du service.

## 6. Exceptions

- Les logs d’erreur système (niveau ERROR/FATAL) sont toujours stockés, même si la source est en blacklist.
- Les logs critiques sont envoyés en priorité à LMCache et central-terminal.log.

---

*À adapter selon les besoins lors de l’implémentation effective.*
