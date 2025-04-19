# Rapport de performance du module CycleDetector

## Résumé

Ce rapport présente les résultats des tests de performance du module CycleDetector sur différentes tailles de graphes et densités d'arêtes. Les tests ont été effectués sur un ordinateur avec les caractéristiques suivantes :

- Système d'exploitation : Windows
- PowerShell : 5.1

## Résultats

Les tests ont été effectués sur des graphes de tailles variées (10, 50, 100, 500, 1000, 5000 nœuds) avec différentes densités d'arêtes (0.01, 0.05, 0.1, 0.2). Pour chaque combinaison, nous avons testé des graphes avec et sans cycles.

### Observations principales

1. **Temps d'exécution** : Le temps d'exécution augmente de manière significative avec la taille du graphe et la densité des arêtes. Pour les graphes de grande taille (> 1000 nœuds), le temps d'exécution devient prohibitif.

2. **Utilisation de la mémoire** : L'utilisation de la mémoire augmente également avec la taille du graphe, mais reste relativement stable par rapport à la densité des arêtes.

3. **Efficacité du cache** : Le cache est efficace pour les appels répétés sur le même graphe, mais son impact est limité pour les grands graphes en raison du temps nécessaire pour calculer le hash du graphe.

4. **Algorithme itératif vs récursif** : L'algorithme itératif est plus efficace pour les grands graphes, mais l'algorithme récursif est plus rapide pour les petits graphes.

## Problèmes identifiés

1. **Calcul du hash du graphe** : Le calcul du hash du graphe est coûteux pour les grands graphes et peut annuler les bénéfices du cache.

2. **Allocation mémoire excessive** : L'algorithme actuel crée de nombreux objets temporaires, ce qui augmente la pression sur le garbage collector.

3. **Parcours redondant** : L'algorithme visite parfois les mêmes nœuds plusieurs fois, ce qui est inefficace pour les grands graphes.

4. **Seuil de basculement** : Le seuil actuel pour basculer entre l'algorithme récursif et itératif (1000 nœuds) pourrait ne pas être optimal.

## Recommandations d'optimisation

1. **Optimiser le calcul du hash** : Utiliser une méthode de hachage plus efficace ou mettre en cache les résultats intermédiaires.

2. **Réduire les allocations mémoire** : Réutiliser les structures de données existantes au lieu d'en créer de nouvelles.

3. **Améliorer la détection précoce** : Implémenter une détection précoce des cycles pour éviter de parcourir l'ensemble du graphe.

4. **Ajuster le seuil de basculement** : Déterminer empiriquement le seuil optimal pour basculer entre l'algorithme récursif et itératif.

5. **Paralléliser le traitement** : Pour les très grands graphes, envisager de paralléliser le traitement en utilisant les Runspace Pools de PowerShell.

## Conclusion

Le module CycleDetector fonctionne bien pour les petits et moyens graphes, mais des optimisations sont nécessaires pour améliorer ses performances sur les grands graphes. Les recommandations ci-dessus devraient permettre d'améliorer significativement les performances du module.
