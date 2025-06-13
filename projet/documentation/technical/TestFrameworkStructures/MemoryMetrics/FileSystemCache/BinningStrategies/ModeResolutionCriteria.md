# Critères de résolution minimale requise pour les modes dans les histogrammes de latence

## 1. Vue d'ensemble

Ce document établit les critères de résolution minimale requise pour représenter fidèlement les modes dans les distributions de latence des lectures aléatoires de blocs de 2KB. Les modes, qui correspondent aux pics locaux de densité de probabilité, contiennent des informations essentielles sur les différents régimes de performance et les composants du système. Une résolution insuffisante dans les histogrammes peut masquer ces caractéristiques importantes, conduisant à des interprétations erronées et à des décisions d'optimisation sous-optimales. Ce document définit des critères quantitatifs et qualitatifs pour déterminer la résolution minimale nécessaire pour préserver l'intégrité des modes dans différents contextes d'analyse.

## 2. Fondements théoriques de la résolution des modes

### 2.1 Définition formelle de la résolution

Dans le contexte des histogrammes, la résolution peut être définie comme la capacité à distinguer et à caractériser avec précision des caractéristiques distinctes de la distribution sous-jacente. Pour les modes, la résolution implique plusieurs aspects :

| Aspect | Définition mathématique | Interprétation |
|--------|-------------------------|----------------|
| **Résolution spatiale** | Δx = largeur_bin / largeur_mode | Nombre de bins couvrant un mode |
| **Résolution d'amplitude** | Δy = hauteur_bin / hauteur_mode | Capacité à distinguer les variations d'amplitude |
| **Résolution de séparation** | Δs = largeur_bin / distance_entre_modes | Capacité à distinguer des modes adjacents |
| **Résolution de forme** | Δf = largeur_bin / rayon_de_courbure | Capacité à capturer la forme du mode |

### 2.2 Théorème d'échantillonnage de Nyquist-Shannon appliqué aux histogrammes

Le théorème de Nyquist-Shannon, adapté aux histogrammes, suggère qu'une caractéristique de largeur W doit être échantillonnée par au moins 2 bins pour être détectée, et par au moins 4-5 bins pour être caractérisée avec précision.

Pour un mode de largeur W (typiquement mesurée comme la largeur à mi-hauteur, FWHM), les critères minimaux sont :

| Objectif | Critère de Nyquist | Application aux modes |
|----------|-------------------|----------------------|
| **Détection** | largeur_bin ≤ W/2 | Au moins 2 bins par mode |
| **Caractérisation basique** | largeur_bin ≤ W/4 | Au moins 4 bins par mode |
| **Caractérisation précise** | largeur_bin ≤ W/8 | Au moins 8 bins par mode |
| **Analyse fine** | largeur_bin ≤ W/16 | Au moins 16 bins par mode |

## 3. Critères de résolution minimale pour différents objectifs d'analyse

### 3.1 Critères généraux par objectif

| Objectif d'analyse | Résolution spatiale minimale | Résolution de séparation minimale | Justification |
|--------------------|------------------------------|-----------------------------------|---------------|
| **Détection de présence** | 2 bins/mode | 1 bin entre modes | <ul><li>Minimum absolu pour détecter l'existence d'un mode</li><li>Insuffisant pour toute analyse quantitative</li><li>Risque élevé de faux négatifs</li></ul> |
| **Localisation approximative** | 3-4 bins/mode | 2 bins entre modes | <ul><li>Permet d'estimer la position du mode avec une précision modérée</li><li>Erreur typique de localisation: ±0.5 × largeur_bin</li><li>Suffisant pour analyses exploratoires</li></ul> |
| **Caractérisation de base** | 5-7 bins/mode | 3 bins entre modes | <ul><li>Permet d'estimer la largeur et l'amplitude avec une précision acceptable</li><li>Erreur typique sur les paramètres: 15-25%</li><li>Suffisant pour la plupart des analyses opérationnelles</li></ul> |
| **Analyse détaillée** | 8-12 bins/mode | 4-5 bins entre modes | <ul><li>Permet de caractériser la forme du mode avec bonne précision</li><li>Erreur typique sur les paramètres: 5-15%</li><li>Nécessaire pour analyses comparatives fines</li></ul> |
| **Analyse de précision** | >12 bins/mode | >6 bins entre modes | <ul><li>Permet de détecter des asymétries et structures fines</li><li>Erreur typique sur les paramètres: <5%</li><li>Nécessaire pour recherche et optimisation avancée</li></ul> |

### 3.2 Critères spécifiques pour les distributions de latence de blocs de 2KB

Pour les distributions de latence de blocs de 2KB, qui présentent typiquement 3-4 modes correspondant aux différents niveaux de la hiérarchie de stockage :

| Mode | Largeur typique (FWHM) | Résolution minimale recommandée | Largeur de bin maximale |
|------|------------------------|--------------------------------|-------------------------|
| **Mode L1/L2** (50-100 µs) | 20-30 µs | 6-8 bins/mode | 3-5 µs |
| **Mode L3/Mémoire** (150-250 µs) | 40-60 µs | 6-8 bins/mode | 5-10 µs |
| **Mode Cache Système** (400-700 µs) | 100-150 µs | 5-7 bins/mode | 15-30 µs |
| **Mode Stockage** (1500-3000 µs) | 500-1000 µs | 4-6 bins/mode | 100-250 µs |

### 3.3 Représentation JSON des critères de résolution

```json
{
  "modeResolutionCriteria": {
    "general": {
      "detectionOnly": {
        "spatialResolution": 2,
        "separationResolution": 1,
        "errorRate": {
          "falseNegative": "high",
          "parameterEstimation": "very high"
        }
      },
      "basicAnalysis": {
        "spatialResolution": 6,
        "separationResolution": 3,
        "errorRate": {
          "falseNegative": "very low",
          "parameterEstimation": "medium"
        }
      },
      "detailedAnalysis": {
        "spatialResolution": 10,
        "separationResolution": 5,
        "errorRate": {
          "falseNegative": "negligible",
          "parameterEstimation": "low"
        }
      }
    },
    "specific2KBLatency": {
      "l1l2Cache": {
        "typicalWidth": 25,
        "recommendedBinsPerMode": 8,
        "maxBinWidth": 3,
        "typicalRange": [50, 100]
      },
      "l3Memory": {
        "typicalWidth": 50,
        "recommendedBinsPerMode": 8,
        "maxBinWidth": 6,
        "typicalRange": [150, 250]
      },
      "systemCache": {
        "typicalWidth": 120,
        "recommendedBinsPerMode": 6,
        "maxBinWidth": 20,
        "typicalRange": [400, 700]
      },
      "storage": {
        "typicalWidth": 750,
        "recommendedBinsPerMode": 5,
        "maxBinWidth": 150,
        "typicalRange": [1500, 3000]
      }
    }
  }
}
```plaintext
## 4. Facteurs influençant les besoins en résolution

### 4.1 Caractéristiques des modes

| Caractéristique | Impact sur les besoins en résolution | Ajustement recommandé |
|-----------------|-------------------------------------|------------------------|
| **Étroitesse** | Modes plus étroits nécessitent une résolution plus fine | Réduire la largeur de bin proportionnellement à la largeur du mode |
| **Proximité** | Modes proches nécessitent une meilleure résolution de séparation | Assurer au moins 3 bins entre les modes adjacents |
| **Asymétrie** | Modes asymétriques nécessitent plus de bins pour caractérisation | Augmenter de 30-50% le nombre de bins par mode |
| **Amplitude relative** | Modes secondaires de faible amplitude nécessitent plus de résolution | Dimensionner pour le mode le plus faible avec un facteur de sécurité |
| **Superposition** | Modes superposés nécessitent une résolution très fine | Doubler la résolution minimale standard |

### 4.2 Contexte d'analyse

| Contexte | Impact sur les besoins en résolution | Recommandation |
|----------|-------------------------------------|----------------|
| **Monitoring opérationnel** | Priorité à la détection rapide des anomalies | 4-6 bins par mode principal |
| **Analyse comparative** | Nécessite une caractérisation précise pour comparaisons | 8-10 bins par mode |
| **Optimisation système** | Requiert une localisation précise des goulots d'étranglement | 6-8 bins par mode |
| **Recherche et développement** | Nécessite une caractérisation complète de la distribution | 10-16 bins par mode |
| **Rapports et documentation** | Équilibre entre précision et lisibilité | 5-8 bins par mode |

### 4.3 Contraintes pratiques

| Contrainte | Impact | Stratégie d'adaptation |
|------------|--------|------------------------|
| **Volume de données** | Échantillons limités créent des bins bruités | Réduire le nombre de bins pour maintenir >30 observations/bin |
| **Espace de visualisation** | Écrans limités réduisent la lisibilité des histogrammes détaillés | Utiliser des techniques de zoom ou focus+contexte |
| **Performance computationnelle** | Trop de bins augmente le coût de calcul et stockage | Utiliser des structures de données optimisées pour histogrammes creux |
| **Intégration système** | Compatibilité avec systèmes existants peut limiter la flexibilité | Adapter la résolution aux contraintes du système tout en maintenant les minimums absolus |

## 5. Méthodes d'évaluation de l'adéquation de la résolution

### 5.1 Tests quantitatifs

| Test | Description | Critère de succès |
|------|-------------|-------------------|
| **Test de Hartigan pour unimodalité** | Vérifie si l'histogramme détecte correctement la multimodalité | p-value < 0.05 indique multimodalité correctement détectée |
| **Test de conservation des moments** | Compare les moments statistiques entre distribution et histogramme | Erreur relative < 5% sur les 4 premiers moments |
| **Test de conservation des percentiles** | Compare les percentiles clés entre distribution et histogramme | Erreur relative < 3% sur les percentiles p10, p50, p90 |
| **Test de séparabilité des modes** | Vérifie si les modes adjacents sont clairement séparés | Vallée entre modes < 80% de la hauteur du mode le plus petit |
| **Test de localisation des maxima** | Compare la position des modes entre distribution et histogramme | Erreur de localisation < 0.25 × largeur du mode |

### 5.2 Indicateurs visuels d'insuffisance de résolution

| Indicateur | Description | Interprétation |
|------------|-------------|----------------|
| **Plateaux artificiels** | Régions plates au sommet des modes | Résolution insuffisante pour capturer le pic |
| **Asymétrie artificielle** | Asymétrie non présente dans les données sous-jacentes | Effet d'alignement des bins avec les modes |
| **Modes manquants** | Modes secondaires absents de l'histogramme | Résolution insuffisante pour détecter les modes mineurs |
| **Oscillations artificielles** | Variations non monotones sur les flancs des modes | Artefacts d'échantillonnage dus à une résolution inadéquate |
| **Fusion de modes** | Un seul pic là où les données brutes montrent plusieurs | Résolution insuffisante pour séparer les modes |

### 5.3 Procédure d'évaluation recommandée

1. **Analyse préliminaire des données brutes**
   - Estimer le nombre et les caractéristiques des modes (position, largeur, amplitude)
   - Identifier les régions critiques nécessitant une attention particulière

2. **Calcul des résolutions minimales requises**
   - Appliquer les critères du tableau 3.2 pour chaque mode identifié
   - Sélectionner la résolution la plus fine requise par n'importe quel mode

3. **Construction d'histogrammes à différentes résolutions**
   - Créer des histogrammes avec résolution croissante (ex: 50%, 100%, 150%, 200% de la résolution minimale calculée)

4. **Application des tests quantitatifs**
   - Appliquer les tests de la section 5.1 à chaque histogramme
   - Identifier la résolution minimale qui passe tous les tests

5. **Vérification visuelle**
   - Examiner les histogrammes pour détecter les indicateurs d'insuffisance de résolution
   - Vérifier que tous les modes sont correctement représentés

6. **Validation finale**
   - Confirmer que l'histogramme final répond aux objectifs d'analyse spécifiques
   - Documenter les choix de résolution et leurs justifications

## 6. Application aux distributions de latence de blocs de 2KB

### 6.1 Analyse des modes typiques

Les distributions de latence de blocs de 2KB présentent typiquement une structure multimodale avec les caractéristiques suivantes :

| Mode | Position typique | Largeur (FWHM) | Amplitude relative | Caractéristiques |
|------|------------------|----------------|-------------------|------------------|
| **L1/L2 Cache** | 70-90 µs | 20-30 µs | 0.5-1.0 | <ul><li>Étroit et bien défini</li><li>Parfois bimodal (L1 vs L2)</li><li>Légèrement asymétrique (queue droite)</li></ul> |
| **L3/Mémoire** | 180-220 µs | 40-60 µs | 0.8-1.0 | <ul><li>Mode principal dans de nombreux systèmes</li><li>Relativement symétrique</li><li>Bien séparé des autres modes</li></ul> |
| **Cache Système** | 500-600 µs | 100-150 µs | 0.3-0.6 | <ul><li>Plus large que les modes précédents</li><li>Asymétrique (queue droite prononcée)</li><li>Amplitude variable selon configuration</li></ul> |
| **Stockage** | 2000-2500 µs | 500-1000 µs | 0.1-0.3 | <ul><li>Très large et diffus</li><li>Fortement asymétrique</li><li>Parfois multimodal (différents types d'accès)</li></ul> |

### 6.2 Résolutions minimales requises par cas d'utilisation

| Cas d'utilisation | L1/L2 Cache | L3/Mémoire | Cache Système | Stockage | Nombre total de bins recommandé |
|-------------------|-------------|------------|---------------|----------|--------------------------------|
| **Monitoring en temps réel** | 4 bins/mode<br>(~7 µs/bin) | 4 bins/mode<br>(~15 µs/bin) | 3 bins/mode<br>(~50 µs/bin) | 2 bins/mode<br>(~500 µs/bin) | 20-25 bins avec largeur variable |
| **Analyse des performances** | 8 bins/mode<br>(~3 µs/bin) | 8 bins/mode<br>(~7 µs/bin) | 6 bins/mode<br>(~25 µs/bin) | 4 bins/mode<br>(~250 µs/bin) | 40-50 bins avec largeur variable |
| **Optimisation système** | 6 bins/mode<br>(~5 µs/bin) | 6 bins/mode<br>(~10 µs/bin) | 5 bins/mode<br>(~30 µs/bin) | 3 bins/mode<br>(~330 µs/bin) | 30-35 bins avec largeur variable |
| **Recherche avancée** | 12 bins/mode<br>(~2 µs/bin) | 10 bins/mode<br>(~5 µs/bin) | 8 bins/mode<br>(~18 µs/bin) | 6 bins/mode<br>(~170 µs/bin) | 60-70 bins avec largeur variable |

### 6.3 Exemple d'implémentation pour l'analyse des performances

```python
def calculate_optimal_bins_for_2kb_latency(latency_data, use_case="performance_analysis"):
    """
    Calcule les bins optimaux pour une distribution de latence de blocs de 2KB
    en fonction du cas d'utilisation.
    
    Args:
        latency_data: Array des mesures de latence en microsecondes
        use_case: Cas d'utilisation ("monitoring", "performance_analysis", 
                  "optimization", "research")
        
    Returns:
        bin_edges: Limites des bins optimisées
    """
    # Paramètres de résolution par cas d'utilisation

    resolution_params = {
        "monitoring": {
            "l1l2": {"bins_per_mode": 4, "approx_width": 25},
            "l3mem": {"bins_per_mode": 4, "approx_width": 50},
            "syscache": {"bins_per_mode": 3, "approx_width": 120},
            "storage": {"bins_per_mode": 2, "approx_width": 750}
        },
        "performance_analysis": {
            "l1l2": {"bins_per_mode": 8, "approx_width": 25},
            "l3mem": {"bins_per_mode": 8, "approx_width": 50},
            "syscache": {"bins_per_mode": 6, "approx_width": 120},
            "storage": {"bins_per_mode": 4, "approx_width": 750}
        },
        "optimization": {
            "l1l2": {"bins_per_mode": 6, "approx_width": 25},
            "l3mem": {"bins_per_mode": 6, "approx_width": 50},
            "syscache": {"bins_per_mode": 5, "approx_width": 120},
            "storage": {"bins_per_mode": 3, "approx_width": 750}
        },
        "research": {
            "l1l2": {"bins_per_mode": 12, "approx_width": 25},
            "l3mem": {"bins_per_mode": 10, "approx_width": 50},
            "syscache": {"bins_per_mode": 8, "approx_width": 120},
            "storage": {"bins_per_mode": 6, "approx_width": 750}
        }
    }
    
    params = resolution_params.get(use_case, resolution_params["performance_analysis"])
    
    # Définir les régions approximatives pour chaque mode

    regions = [
        {"name": "l1l2", "start": 50, "end": 100},
        {"name": "l3mem", "start": 150, "end": 250},
        {"name": "syscache", "start": 400, "end": 700},
        {"name": "storage", "start": 1500, "end": 3000}
    ]
    
    # Calculer les largeurs de bin optimales pour chaque région

    bin_edges = [0]  # Commencer à 0

    
    for region in regions:
        region_name = region["name"]
        region_start = region["start"]
        region_end = region["end"]
        
        # Ajouter une bin de transition si nécessaire

        if bin_edges[-1] < region_start:
            bin_edges.append(region_start)
        
        # Calculer la largeur de bin optimale pour cette région

        mode_width = params[region_name]["approx_width"]
        bins_per_mode = params[region_name]["bins_per_mode"]
        bin_width = mode_width / bins_per_mode
        
        # Créer les bins pour cette région

        current = bin_edges[-1]
        while current < region_end:
            current += bin_width
            bin_edges.append(current)
    
    # Ajouter une bin finale pour les valeurs extrêmes

    max_val = np.max(latency_data)
    if bin_edges[-1] < max_val:
        bin_edges.append(max_val * 1.1)  # 10% de marge

    
    return np.array(bin_edges)
```plaintext
## 7. Conclusion

L'établissement de critères de résolution minimale pour les modes dans les histogrammes de latence est essentiel pour garantir une représentation fidèle et informative des distributions de performance. Les points clés à retenir sont :

1. **Fondements théoriques solides** : Le théorème de Nyquist-Shannon adapté aux histogrammes fournit une base théorique pour déterminer la résolution minimale nécessaire (au moins 2 bins par mode pour la détection, 4+ pour la caractérisation).

2. **Critères adaptés au contexte** : Les besoins en résolution varient selon l'objectif d'analyse, les caractéristiques des modes et les contraintes pratiques, nécessitant une approche flexible et adaptative.

3. **Spécificités des latences de 2KB** : Les distributions de latence de blocs de 2KB présentent une structure multimodale complexe avec des modes de largeurs très différentes, nécessitant des résolutions variables selon les régions.

4. **Méthodes d'évaluation rigoureuses** : Des tests quantitatifs et des indicateurs visuels permettent d'évaluer l'adéquation de la résolution et d'ajuster les paramètres en conséquence.

5. **Recommandations pratiques** : Pour une analyse de performance standard des latences de 2KB, une approche à largeur de bin variable avec 40-50 bins au total est recommandée, avec une résolution plus fine dans les régions de cache (3-7 µs/bin) et plus grossière dans les régions de stockage (250 µs/bin).

Ces critères de résolution minimale constituent une base solide pour concevoir des histogrammes qui capturent fidèlement les caractéristiques importantes des distributions de latence, permettant une analyse précise et des décisions d'optimisation éclairées.
