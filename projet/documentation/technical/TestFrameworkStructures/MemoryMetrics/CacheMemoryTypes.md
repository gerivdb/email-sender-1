# Types de cache à mesurer

## 1. Vue d'ensemble

Ce document identifie et définit les différents types de cache mémoire qui doivent être mesurés dans le cadre des tests de performance. Les caches mémoire sont des composants essentiels qui influencent significativement les performances des applications, et leur surveillance permet d'identifier les goulots d'étranglement et d'optimiser l'utilisation des ressources.

## 2. Types de cache matériel (CPU)

### 2.1 Cache L1

Le cache L1 est le cache de premier niveau, intégré directement dans le cœur du processeur. Il est généralement divisé en deux parties : le cache d'instructions (L1i) et le cache de données (L1d).

**Caractéristiques typiques :**
- Taille : 32 Ko à 64 Ko par cœur (généralement 32 Ko pour L1i et 32 Ko pour L1d)
- Latence : 1 à 3 cycles d'horloge
- Associativité : 4 à 8 voies
- Taille de ligne : 64 octets

**Métriques à mesurer :**
- Taille totale et par cœur
- Taux de succès (hit rate)
- Taux d'échec (miss rate)
- Latence moyenne d'accès
- Taux d'utilisation
- Nombre d'accès par seconde
- Nombre d'évictions par seconde

### 2.2 Cache L2

Le cache L2 est le cache de deuxième niveau, généralement partagé entre quelques cœurs ou dédié à chaque cœur selon l'architecture.

**Caractéristiques typiques :**
- Taille : 256 Ko à 1 Mo par cœur
- Latence : 10 à 20 cycles d'horloge
- Associativité : 8 à 16 voies
- Taille de ligne : 64 octets

**Métriques à mesurer :**
- Taille totale et par cœur/groupe de cœurs
- Taux de succès (hit rate)
- Taux d'échec (miss rate)
- Latence moyenne d'accès
- Taux d'utilisation
- Nombre d'accès par seconde
- Nombre d'évictions par seconde
- Taux de préchargement (prefetch rate)

### 2.3 Cache L3

Le cache L3 est le cache de troisième niveau, généralement partagé entre tous les cœurs d'un même processeur.

**Caractéristiques typiques :**
- Taille : 4 Mo à 64 Mo (partagé)
- Latence : 40 à 75 cycles d'horloge
- Associativité : 16 voies ou plus
- Taille de ligne : 64 octets

**Métriques à mesurer :**
- Taille totale
- Taux de succès (hit rate)
- Taux d'échec (miss rate)
- Latence moyenne d'accès
- Taux d'utilisation
- Nombre d'accès par seconde
- Nombre d'évictions par seconde
- Taux de préchargement (prefetch rate)
- Trafic inter-cœurs

### 2.4 Cache L4 (si présent)

Certaines architectures modernes incluent un cache L4, souvent implémenté comme une mémoire tampon embarquée (eDRAM).

**Caractéristiques typiques :**
- Taille : 128 Mo ou plus
- Latence : 100 à 150 cycles d'horloge
- Associativité : variable
- Taille de ligne : 64 à 128 octets

**Métriques à mesurer :**
- Taille totale
- Taux de succès (hit rate)
- Taux d'échec (miss rate)
- Latence moyenne d'accès
- Taux d'utilisation
- Bande passante

### 2.5 TLB (Translation Lookaside Buffer)

Le TLB est un cache spécial qui stocke les traductions d'adresses virtuelles en adresses physiques.

**Types de TLB :**
- TLB d'instructions (iTLB)
- TLB de données (dTLB)
- TLB unifié (uTLB)
- TLB de second niveau (L2 TLB)

**Métriques à mesurer :**
- Nombre d'entrées
- Taux de succès (hit rate)
- Taux d'échec (miss rate)
- Latence des défauts de TLB
- Nombre de défauts de TLB par seconde

## 3. Types de cache logiciel

### 3.1 Cache de système de fichiers

Cache utilisé par le système d'exploitation pour stocker les données de fichiers fréquemment accédées.

**Sous-types :**
- Page Cache (Linux)
- Buffer Cache
- Unified Buffer Cache (macOS, BSD)
- System File Cache (Windows)

**Métriques à mesurer :**
- Taille totale allouée
- Taille utilisée
- Taux de succès (hit rate)
- Taux d'échec (miss rate)
- Nombre de pages propres/sales
- Taux de lecture/écriture
- Latence moyenne d'accès

### 3.2 Cache de disque

Cache intégré aux périphériques de stockage ou géré par les pilotes de périphériques.

**Sous-types :**
- Cache de contrôleur RAID
- Cache SSD
- Cache HDD
- Cache NVMe

**Métriques à mesurer :**
- Taille du cache
- Taux de succès en lecture/écriture
- Politique d'écriture (write-through, write-back)
- Taux d'utilisation
- Latence avec/sans cache

### 3.3 Cache d'application

Caches implémentés au niveau de l'application pour optimiser les performances.

**Sous-types :**
- Cache de données en mémoire
- Cache de résultats de calcul
- Cache d'objets
- Cache de requêtes

**Métriques à mesurer :**
- Taille allouée
- Nombre d'entrées
- Taux de succès (hit rate)
- Taux d'éviction
- Temps moyen de résidence des entrées
- Latence moyenne d'accès
- Politique de remplacement

### 3.4 Cache de base de données

Caches spécifiques aux systèmes de gestion de bases de données.

**Sous-types :**
- Buffer Pool
- Query Cache
- Procedure Cache
- Metadata Cache

**Métriques à mesurer :**
- Taille allouée
- Taux de succès (hit rate)
- Taux d'éviction
- Nombre de pages propres/sales
- Taux de lecture/écriture
- Latence moyenne d'accès

### 3.5 Cache de réseau

Caches utilisés pour optimiser les communications réseau.

**Sous-types :**
- Cache DNS
- Cache ARP
- Cache de route
- Cache de socket

**Métriques à mesurer :**
- Nombre d'entrées
- Taux de succès (hit rate)
- Temps moyen de résidence des entrées
- Taux d'expiration/invalidation

## 4. Caches distribués

### 4.1 Cache de contenu distribué

Caches répartis sur plusieurs nœuds pour stocker du contenu fréquemment accédé.

**Sous-types :**
- CDN (Content Delivery Network)
- Cache de proxy inverse
- Cache de serveur Web

**Métriques à mesurer :**
- Taille totale
- Distribution par nœud
- Taux de succès global et par nœud
- Latence d'accès
- Taux de cohérence
- Bande passante économisée

### 4.2 Cache de données distribué

Systèmes de cache distribués pour stocker des données d'application.

**Exemples :**
- Redis
- Memcached
- Hazelcast
- Ehcache

**Métriques à mesurer :**
- Taille totale et par nœud
- Nombre d'entrées
- Taux de succès (hit rate)
- Latence d'accès
- Taux de cohérence
- Taux d'éviction
- Bande passante réseau utilisée

## 5. Caches spécialisés

### 5.1 Cache JIT (Just-In-Time)

Cache utilisé par les compilateurs JIT pour stocker le code natif généré.

**Métriques à mesurer :**
- Taille du cache
- Taux de succès (hit rate)
- Taux d'éviction
- Temps passé en compilation JIT

### 5.2 Cache de shaders GPU

Cache utilisé pour stocker les shaders compilés pour le GPU.

**Métriques à mesurer :**
- Taille du cache
- Taux de succès (hit rate)
- Temps de compilation évité
- Latence d'accès

### 5.3 Cache de textures GPU

Cache utilisé pour stocker les textures fréquemment utilisées par le GPU.

**Métriques à mesurer :**
- Taille du cache
- Taux de succès (hit rate)
- Bande passante économisée
- Latence d'accès

## 6. Structure de données pour les métriques de cache

La structure de données suivante est proposée pour représenter les métriques de cache dans les résultats de test :

```json
{
  "memory": {
    "cache": {
      "hardware": {
        "l1": {
          // Métriques du cache L1
        },
        "l2": {
          // Métriques du cache L2
        },
        "l3": {
          // Métriques du cache L3
        },
        "tlb": {
          // Métriques du TLB
        }
      },
      "software": {
        "filesystem": {
          // Métriques du cache de système de fichiers
        },
        "disk": {
          // Métriques du cache de disque
        },
        "application": {
          // Métriques du cache d'application
        },
        "database": {
          // Métriques du cache de base de données
        },
        "network": {
          // Métriques du cache réseau
        }
      },
      "distributed": {
        // Métriques des caches distribués
      },
      "specialized": {
        // Métriques des caches spécialisés
      }
    }
  }
}
```

## 7. Considérations pour la collecte des métriques

### 7.1 Disponibilité des métriques

Toutes les métriques ne sont pas disponibles sur toutes les plateformes ou pour tous les types de cache. La collecte doit s'adapter aux limitations de l'environnement :

- **Niveau matériel** : Dépend des compteurs de performance du processeur (PMC)
- **Niveau système d'exploitation** : Dépend des API et outils fournis par l'OS
- **Niveau application** : Dépend de l'instrumentation et des API exposées

### 7.2 Impact de la collecte

La collecte des métriques de cache peut elle-même affecter les performances du cache. Il est important de :

- Minimiser l'impact de la collecte sur les performances
- Documenter l'overhead potentiel de la collecte
- Adapter la fréquence d'échantillonnage en fonction de l'impact

### 7.3 Granularité temporelle

La granularité temporelle de la collecte doit être adaptée au type de cache et à l'objectif de l'analyse :

- Caches matériels : échantillonnage à haute fréquence (ms)
- Caches système : échantillonnage à fréquence moyenne (100ms - 1s)
- Caches distribués : échantillonnage à basse fréquence (1s - 10s)

## 8. Conclusion

Ce document a identifié les principaux types de cache qui doivent être mesurés dans le cadre des tests de performance. La collecte et l'analyse de ces métriques permettront d'identifier les goulots d'étranglement liés au cache et d'optimiser l'utilisation des ressources mémoire à tous les niveaux du système.
