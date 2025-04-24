# Optimisations

Ce document décrit les différentes stratégies d'optimisation pour les entrées, la communication et l'exécution.

## INPUT_OPTIM
- **PREVALIDATE** : 
  - `UTF8ByteCount(input), strict_limit=5KB` : Compter les octets UTF-8 de l'entrée, avec une limite stricte de 5KB

- **SEGMENT** : 
  - `if(size>5KB) → split_by_function` : Si la taille dépasse 5KB, diviser par fonction

- **COMPRESS** : 
  - `strip(comments, spaces)` if needed : Supprimer les commentaires et les espaces si nécessaire

- **DETECT** : 
  - `byte_counter(auto)` : Compter automatiquement les octets

- **PREVENT** : 
  - `max_4KB/tool_call` : Limiter à 4KB par appel d'outil

- **INCREMENTAL** : 
  - `if(multiple_funcs) → implement_one_by_one` : Si plusieurs fonctions, implémenter une par une

## COMMUNICATION
- **FORMAT** : 
  - `predefined_struct(max_ratio=info/verbosity)` : Utiliser une structure prédéfinie avec un ratio maximal d'information/verbosité

- **SYNTHESIS** : 
  - `only(important_diffs, key_decisions)` : Ne synthétiser que les différences importantes et les décisions clés

- **METADATA** : 
  - `attach(complete%, complexity_score)` : Joindre le pourcentage d'achèvement et le score de complexité

- **LANGUAGE** : 
  - `fr_concis(algonotation_opt)` : Utiliser un français concis avec notation algorithmique optionnelle

- **FEEDBACK** : 
  - `input_size, validation_status=visible` : Rendre visible la taille de l'entrée et le statut de validation

## AI_OPTIM
- **ONE_SHOT** : 
  - `complete_func_per_call` : Compléter une fonction par appel

- **PROGRESSION** : 
  - `no_confirmation_next_step()` : Progresser sans demander de confirmation pour l'étape suivante

- **METRIC** : 
  - `complexity/size ratio → optimize_split()` : Optimiser la division en fonction du ratio complexité/taille

- **ADAPT** : 
  - `if(feedback || latency) → adjust_granularity()` : Ajuster la granularité en fonction du feedback ou de la latence

- **SPLIT** : 
  - `pre_split_if(anticipate_failure)` : Diviser à l'avance si un échec est anticipé

## META_OPTIM
- **LEARN** : 
  - `cache(success_patterns)` : Mettre en cache les modèles de réussite

- **SELF_EVAL** : 
  - `tune_after(measure_efficiency)` : Ajuster après avoir mesuré l'efficacité

- **ANTICIPATE** : 
  - `prebuffer(next_step)` : Préparer à l'avance l'étape suivante

- **RESILIENCE** : 
  - `keep_state(recoverable)` : Conserver l'état pour pouvoir récupérer

- **LOGGING** : 
  - `journal(errors_only)` : Journaliser uniquement les erreurs
