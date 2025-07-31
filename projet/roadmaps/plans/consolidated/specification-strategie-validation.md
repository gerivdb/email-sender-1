# Spécification technique – Nouvelle stratégie de validation écriture/lecture

## Objectif
Remplacer la validation basée sur lecture immédiate ou exécutable externe par une stratégie robuste :
- Signal de succès explicite après écriture
- Attente contrôlée avec tentatives et timeout

## Option A : Callback/événement
- Après chaque écriture réussie (`writeFile`), déclencher un callback ou un événement système.
- Le workflow attend ce signal avant de procéder à la validation.
- Permet de garantir que l’opération disque est réellement terminée.

## Option B : Attente contrôlée
- Après écriture, lancer une boucle de lecture avec :
  - Nombre maximal de tentatives (ex : 5)
  - Intervalle d’attente entre chaque tentative (ex : 100ms)
  - Timeout global (ex : 1s)
- Si la lecture réussit dans le délai imparti, validation OK ; sinon, échec explicite.

## Implémentation recommandée
- Privilégier l’option A si l’environnement permet la gestion d’événements/callbacks.
- Sinon, utiliser l’option B avec logs détaillés pour chaque tentative.

## Critères de validation
- La stratégie doit être testée dans les workflows concernés.
- Les logs doivent tracer chaque étape (écriture, signal, validation).
- La solution doit être validée par l’équipe technique.
