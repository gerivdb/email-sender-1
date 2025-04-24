# Gestion des erreurs et intégrité

Ce document décrit les stratégies de gestion des erreurs et les principes d'intégrité à respecter.

## ERRORS
- **PREVENT** : 
  - `detect_input_size_error()` : Détecter les erreurs de taille d'entrée

- **REACTIVE_SEGMENT** : 
  - `if(error==too_large) → split_now()` : Si l'erreur est due à une taille excessive, diviser immédiatement

- **LOG** : 
  - `each_error(ctx, fix)` : Journaliser chaque erreur avec son contexte et sa correction

- **FALLBACK** : 
  - `always_alt_paths()` : Toujours prévoir des chemins alternatifs

- **CONTINUITY** : 
  - `progress_despite_errors(ctx_safe)` : Continuer à progresser malgré les erreurs, en préservant le contexte

## INTÉGRITÉ
- **ASSERT** : 
  - `complete_task ⇒ if(verified==TRUE)` : Considérer une tâche comme terminée uniquement si elle est vérifiée
  - `list_files ⇒ if(files_created==TRUE)` : Lister les fichiers uniquement s'ils ont été créés

- **IF(error || user_fix)** : 
  - `ACK + FIX(no_justif)` : Reconnaître et corriger sans justification

- **SEPARATE** : 
  - `actual={code,files}, potential={suggest}` : Séparer ce qui est réel (code, fichiers) de ce qui est potentiel (suggestions)

- **FORMAT** : 
  - `[IMPLEMENTED]=ok` : Marquer ce qui est implémenté comme "ok"
  - `[SUGGESTED]=idea` : Marquer ce qui est suggéré comme "idea"
  - `[INCOMPLETE]=partial` : Marquer ce qui est incomplet comme "partial"

- **STATUS_UPDATE** : 
  - `check_impl + tests_required` : Vérifier l'implémentation et les tests requis

- **TASK_DONE** : 
  - `if(code==ok && tests==pass && doc==done)` : Considérer une tâche comme terminée uniquement si le code est correct, les tests passent et la documentation est complète

- **ROADMAP** : 
  - `each_step=user_confirmed + individually_validated` : Chaque étape doit être confirmée par l'utilisateur et validée individuellement

- **DIRECTIVE** : 
  - `trust_preservation==TOP` : La préservation de la confiance est la priorité absolue
