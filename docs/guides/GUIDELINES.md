# GUIDELINES

## Principes généraux
- Toutes les fonctions doivent suivre les conventions de nommage PowerShell (verbes approuvés)
- Utiliser la structure Private/Public pour organiser les fonctions
- Implémenter ShouldProcess pour les fonctions qui modifient l'état du système
- Assurer la compatibilité avec PowerShell 5.1 et 7
- Vérifier les valeurs null avec `$null -eq $variable` (et non l'inverse)
- Gestion robuste des erreurs, particulièrement pour les opérations sur les fichiers

## Inspection des variables
- Chaque fonction d'inspection doit:
  - Accepter une variable en entrée via le pipeline
  - Fournir une sortie formatée et lisible
  - Inclure des options pour différents niveaux de détail
  - Gérer tous les types de données courants
  - Documenter clairement son utilisation avec des exemples
  - Inclure des tests unitaires complets

## Performance
- Mesurer le temps d'exécution des fonctions critiques
- Surveiller l'utilisation de la mémoire
- Optimiser les opérations sur les grandes structures de données
- Utiliser des techniques comme Runspace Pools pour les opérations parallèles quand approprié

## Tests
- Chaque fonction doit avoir des tests unitaires correspondants
- Les tests doivent couvrir les cas normaux et les cas limites
- Utiliser Pester pour les tests
- Maintenir une couverture de code élevée

## Documentation
- Chaque fonction doit inclure une aide complète (comment-based help)
- Documenter les paramètres, entrées, sorties et exemples
- Maintenir un journal des modifications
