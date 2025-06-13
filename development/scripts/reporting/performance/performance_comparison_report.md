# Rapport de comparaison des tests de performance

## RÃ©sumÃ© des tests

| MÃ©trique | Faible concurrence (1) | Concurrence moyenne (3) | Concurrence Ã©levÃ©e (5) |
|----------|------------------------|--------------------------|------------------------|
| RequÃªtes totales | 3 | 7 | 13 |
| Temps d'exÃ©cution total (s) | 1.58 | 2.98 | 6.17 |
| Temps de rÃ©ponse moyen (ms) | 936.22 | 1489.78 | 3253.80 |
| RequÃªtes par seconde | 1.90 | 2.35 | 2.11 |

## Analyse

1. **Nombre de requÃªtes** : Le nombre de requÃªtes augmente avec la concurrence, ce qui est attendu car plus de requÃªtes peuvent Ãªtre traitÃ©es simultanÃ©ment.

2. **Temps d'exÃ©cution total** : Le temps d'exÃ©cution total augmente avec la concurrence, mais pas de maniÃ¨re linÃ©aire. Cela suggÃ¨re que le systÃ¨me commence Ã  atteindre ses limites avec une concurrence plus Ã©levÃ©e.

3. **Temps de rÃ©ponse moyen** : Le temps de rÃ©ponse moyen augmente significativement avec la concurrence, ce qui indique une contention des ressources. Avec une concurrence de 5, le temps de rÃ©ponse moyen est plus de 3 fois supÃ©rieur Ã  celui avec une concurrence de 1.

4. **RequÃªtes par seconde** : Le dÃ©bit (requÃªtes par seconde) augmente de la concurrence 1 Ã  3, mais diminue lÃ©gÃ¨rement de la concurrence 3 Ã  5. Cela suggÃ¨re que la concurrence optimale pour ce systÃ¨me se situe autour de 3.

## Conclusion

Les tests montrent que le systÃ¨me peut gÃ©rer efficacement jusqu'Ã  3 requÃªtes concurrentes, mais au-delÃ , les performances commencent Ã  se dÃ©grader. Pour optimiser les performances, il est recommandÃ© de limiter la concurrence Ã  3 pour ce type de charge de travail.

## Recommandations

1. **Optimisation de la concurrence** : Limiter la concurrence Ã  3 pour obtenir le meilleur Ã©quilibre entre dÃ©bit et temps de rÃ©ponse.

2. **Surveillance des ressources** : Surveiller l'utilisation des ressources (CPU, mÃ©moire) pendant les tests pour identifier les goulots d'Ã©tranglement.

3. **Tests supplÃ©mentaires** : Effectuer des tests supplÃ©mentaires avec diffÃ©rentes tailles de donnÃ©es pour Ã©valuer l'impact sur les performances.

4. **Optimisation du code** : Analyser le code pour identifier les opportunitÃ©s d'optimisation, en particulier pour les opÃ©rations qui sont exÃ©cutÃ©es frÃ©quemment.
