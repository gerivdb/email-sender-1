# Rapport de comparaison des tests de performance

## Résumé des tests

| Métrique | Faible concurrence (1) | Concurrence moyenne (3) | Concurrence élevée (5) |
|----------|------------------------|--------------------------|------------------------|
| Requêtes totales | 3 | 7 | 13 |
| Temps d'exécution total (s) | 1.58 | 2.98 | 6.17 |
| Temps de réponse moyen (ms) | 936.22 | 1489.78 | 3253.80 |
| Requêtes par seconde | 1.90 | 2.35 | 2.11 |

## Analyse

1. **Nombre de requêtes** : Le nombre de requêtes augmente avec la concurrence, ce qui est attendu car plus de requêtes peuvent être traitées simultanément.

2. **Temps d'exécution total** : Le temps d'exécution total augmente avec la concurrence, mais pas de manière linéaire. Cela suggère que le système commence à atteindre ses limites avec une concurrence plus élevée.

3. **Temps de réponse moyen** : Le temps de réponse moyen augmente significativement avec la concurrence, ce qui indique une contention des ressources. Avec une concurrence de 5, le temps de réponse moyen est plus de 3 fois supérieur à celui avec une concurrence de 1.

4. **Requêtes par seconde** : Le débit (requêtes par seconde) augmente de la concurrence 1 à 3, mais diminue légèrement de la concurrence 3 à 5. Cela suggère que la concurrence optimale pour ce système se situe autour de 3.

## Conclusion

Les tests montrent que le système peut gérer efficacement jusqu'à 3 requêtes concurrentes, mais au-delà, les performances commencent à se dégrader. Pour optimiser les performances, il est recommandé de limiter la concurrence à 3 pour ce type de charge de travail.

## Recommandations

1. **Optimisation de la concurrence** : Limiter la concurrence à 3 pour obtenir le meilleur équilibre entre débit et temps de réponse.

2. **Surveillance des ressources** : Surveiller l'utilisation des ressources (CPU, mémoire) pendant les tests pour identifier les goulots d'étranglement.

3. **Tests supplémentaires** : Effectuer des tests supplémentaires avec différentes tailles de données pour évaluer l'impact sur les performances.

4. **Optimisation du code** : Analyser le code pour identifier les opportunités d'optimisation, en particulier pour les opérations qui sont exécutées fréquemment.
