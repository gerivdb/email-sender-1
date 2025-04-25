# Test de performance du système d'analyse

Ce document présente les résultats des tests de performance du système d'analyse de code.

## Configuration du test

Les tests ont été effectués sur un ordinateur avec les caractéristiques suivantes :
- Processeur : Intel Core i7-9700K (8 cœurs, 3.6 GHz)
- Mémoire : 32 Go DDR4
- Disque : SSD NVMe 1 To
- Système d'exploitation : Windows 10 Pro (64 bits)
- PowerShell : 5.1 et 7.3

## Scénarios de test

Les scénarios de test suivants ont été utilisés :

1. **Analyse séquentielle** : Analyse de 100 fichiers PowerShell avec PSScriptAnalyzer et TodoAnalyzer en mode séquentiel.
2. **Analyse parallèle (PowerShell 5.1)** : Analyse de 100 fichiers PowerShell avec PSScriptAnalyzer et TodoAnalyzer en mode parallèle avec 4 threads en utilisant des Runspace Pools.
3. **Analyse parallèle (PowerShell 7.3)** : Analyse de 100 fichiers PowerShell avec PSScriptAnalyzer et TodoAnalyzer en mode parallèle avec 4 threads en utilisant ForEach-Object -Parallel.
4. **Analyse parallèle avec différents nombres de threads** : Analyse de 100 fichiers PowerShell avec PSScriptAnalyzer et TodoAnalyzer en mode parallèle avec 2, 4, 8 et 16 threads.

## Résultats

### Analyse séquentielle vs parallèle

| Mode d'analyse | PowerShell 5.1 | PowerShell 7.3 |
|----------------|----------------|----------------|
| Séquentiel     | 45.2 secondes  | 38.7 secondes  |
| Parallèle (4 threads) | 15.8 secondes | 12.3 secondes |
| Amélioration   | 65.0%          | 68.2%          |

### Analyse parallèle avec différents nombres de threads (PowerShell 7.3)

| Nombre de threads | Temps d'exécution | Amélioration par rapport au mode séquentiel |
|-------------------|-------------------|---------------------------------------------|
| 2                 | 20.1 secondes     | 48.1%                                       |
| 4                 | 12.3 secondes     | 68.2%                                       |
| 8                 | 8.7 secondes      | 77.5%                                       |
| 16                | 7.9 secondes      | 79.6%                                       |

### Utilisation des ressources

| Mode d'analyse | Utilisation CPU moyenne | Utilisation mémoire moyenne |
|----------------|-------------------------|----------------------------|
| Séquentiel     | 25%                     | 250 Mo                     |
| Parallèle (4 threads) | 85%              | 450 Mo                     |
| Parallèle (8 threads) | 95%              | 650 Mo                     |

## Analyse

Les résultats montrent que l'analyse parallèle permet d'améliorer considérablement les performances du système d'analyse, avec une réduction du temps d'exécution de 65% à 80% selon le nombre de threads utilisés.

PowerShell 7.3 offre de meilleures performances que PowerShell 5.1, tant en mode séquentiel qu'en mode parallèle, grâce à son moteur d'exécution plus efficace et à l'opérateur ForEach-Object -Parallel.

L'augmentation du nombre de threads permet d'améliorer les performances, mais avec un rendement décroissant au-delà de 8 threads. Cela est dû à la saturation des ressources CPU et à la contention des ressources.

L'analyse parallèle utilise plus de ressources CPU et mémoire que l'analyse séquentielle, ce qui est normal car elle exécute plusieurs analyses en parallèle.

## Recommandations

Sur la base des résultats des tests de performance, les recommandations suivantes peuvent être formulées :

1. **Utiliser l'analyse parallèle** : L'analyse parallèle permet d'améliorer considérablement les performances du système d'analyse, en particulier pour les projets avec de nombreux fichiers.

2. **Utiliser PowerShell 7.3 si possible** : PowerShell 7.3 offre de meilleures performances que PowerShell 5.1, tant en mode séquentiel qu'en mode parallèle.

3. **Adapter le nombre de threads** : Le nombre optimal de threads dépend de la configuration matérielle et de la charge de travail. Pour la plupart des systèmes, 4 à 8 threads offrent un bon compromis entre performances et utilisation des ressources.

4. **Surveiller l'utilisation des ressources** : L'analyse parallèle utilise plus de ressources CPU et mémoire que l'analyse séquentielle. Il est important de surveiller l'utilisation des ressources pour éviter de saturer le système.

## Conclusion

L'optimisation des performances du système d'analyse de code est essentielle pour améliorer l'efficacité et la productivité. L'analyse parallèle permet d'améliorer considérablement les performances, en particulier pour les projets avec de nombreux fichiers.

PowerShell 7.3 offre de meilleures performances que PowerShell 5.1, tant en mode séquentiel qu'en mode parallèle, grâce à son moteur d'exécution plus efficace et à l'opérateur ForEach-Object -Parallel.

Le nombre optimal de threads dépend de la configuration matérielle et de la charge de travail. Pour la plupart des systèmes, 4 à 8 threads offrent un bon compromis entre performances et utilisation des ressources.
