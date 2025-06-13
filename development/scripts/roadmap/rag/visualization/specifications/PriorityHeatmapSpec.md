# Spécification de la Carte de Chaleur des Priorités

*Version 1.0 - 2025-05-15*

## 1. Description Générale

La carte de chaleur des priorités est une visualisation de la distribution des priorités dans la roadmap, permettant d'identifier rapidement les zones nécessitant une attention particulière. Elle utilise une représentation spatiale et un codage couleur pour mettre en évidence les concentrations de tâches prioritaires et faciliter l'allocation des ressources.

## 2. Caractéristiques Clés

### 2.1 Représentation des Zones de Priorité

#### 2.1.1 Structure Spatiale

- **Layouts disponibles**:
  - Treemap: Rectangles imbriqués représentant la hiérarchie
  - Grid: Grille régulière avec regroupement par catégorie
  - Voronoi: Diagramme de Voronoi pour représentation organique
  - Calendar: Vue calendaire pour priorités temporelles
- **Organisation**:
  - Hiérarchique: Imbrication selon la structure du projet
  - Catégorielle: Regroupement par domaine ou type
  - Temporelle: Organisation par période ou jalon
- **Proportions**:
  - Taille proportionnelle à l'importance
  - Taille proportionnelle au nombre de tâches
  - Taille proportionnelle à l'effort estimé

#### 2.1.2 Représentation des Éléments

- **Forme des cellules**:
  - Rectangulaires: Pour treemap et grid
  - Polygonales: Pour Voronoi
  - Carrées: Pour calendar view
- **Bordures**:
  - Épaisseur: 1px par défaut
  - Couleur: Gris neutre ou couleur de la catégorie
  - Style: Continu pour séparations principales, pointillé pour sous-divisions
- **Étiquettes**:
  - Position: Centrée ou en haut à gauche
  - Taille: Adaptative selon la taille de la cellule
  - Visibilité: Automatique selon l'espace disponible

#### 2.1.3 Niveaux de Zoom

- **Vue globale**: Ensemble du projet
- **Vue intermédiaire**: Domaine ou catégorie spécifique
- **Vue détaillée**: Tâches individuelles
- **Comportement**:
  - Zoom sémantique: Affichage de détails supplémentaires
  - Zoom spatial: Agrandissement de la zone sélectionnée
  - Focus+contexte: Zone agrandie avec contexte préservé

### 2.2 Échelle de Couleurs et Légende

#### 2.2.1 Palettes de Couleurs

- **Séquentielle** (priorité croissante):
  - Monochrome: Du clair au foncé (ex: bleu clair → bleu foncé)
  - Multi-teinte: Dégradé progressif (ex: vert → jaune → orange → rouge)
- **Divergente** (écart par rapport à la normale):
  - Bi-directionnelle: Bleu → blanc → rouge
  - Tri-directionnelle: Vert → jaune → rouge
- **Catégorielle** (par type):
  - Palette distincte pour chaque catégorie
  - Saturation variable selon la priorité

#### 2.2.2 Encodage des Valeurs

- **Priorité absolue**:
  - Basse: Vert clair (#A9DFBF)

  - Moyenne: Jaune (#F9E79F)

  - Haute: Orange (#F5B041)

  - Critique: Rouge (#E74C3C)

- **Densité de priorité**:
  - Faible: Couleurs pâles
  - Moyenne: Couleurs intermédiaires
  - Élevée: Couleurs vives
- **Combinaison de facteurs**:
  - Teinte: Type de priorité
  - Saturation: Niveau de priorité
  - Luminosité: Statut d'avancement

#### 2.2.3 Légende Interactive

- **Composants**:
  - Échelle de couleurs avec étiquettes
  - Filtres rapides par niveau de priorité
  - Indicateurs statistiques (distribution)
- **Interactions**:
  - Clic sur niveau: Filtre les éléments correspondants
  - Survol: Met en évidence les éléments correspondants
  - Ajustement des seuils: Modification dynamique des plages

### 2.3 Règles de Regroupement des Tâches

#### 2.3.1 Critères de Regroupement

- **Hiérarchiques**:
  - Par niveau dans la structure du projet
  - Par relation parent-enfant
  - Par profondeur (niveaux 1-2, 3-4, etc.)
- **Fonctionnels**:
  - Par domaine métier
  - Par composant technique
  - Par équipe responsable
- **Temporels**:
  - Par sprint/itération
  - Par trimestre/semestre
  - Par phase du projet

#### 2.3.2 Algorithmes d'Agrégation

- **Somme**: Addition des valeurs de priorité
- **Moyenne**: Niveau moyen de priorité
- **Maximum**: Priorité la plus élevée du groupe
- **Pondéré**: Priorité ajustée selon l'importance
- **Densité**: Nombre de tâches prioritaires / total

#### 2.3.3 Règles de Subdivision

- **Équilibrée**: Taille similaire pour tous les groupes
- **Proportionnelle**: Taille selon l'importance relative
- **Hiérarchique**: Respect strict de la structure
- **Adaptative**: Ajustement selon la densité d'information

## 3. Métadonnées à Afficher

### 3.1 Informations Essentielles par Zone

- **Titre**: Nom du groupe ou de la catégorie
- **Statistiques globales**:
  - Nombre total de tâches
  - Répartition par niveau de priorité
  - Score de priorité agrégé
- **Indicateurs d'avancement**:
  - Pourcentage de complétion
  - Tendance (amélioration/dégradation)
  - Écart par rapport à la moyenne

### 3.2 Indicateurs de Concentration

- **Hotspots**:
  - Zones de concentration de tâches critiques
  - Mise en évidence visuelle (contour, pulsation)
  - Badge numérique indiquant l'intensité
- **Métriques de concentration**:
  - Indice de densité de priorité
  - Ratio tâches critiques/total
  - Score d'attention requis
- **Alertes**:
  - Seuils de concentration dépassés
  - Déséquilibres significatifs
  - Tendances préoccupantes

### 3.3 Informations Contextuelles

- **Au survol**:
  - Détail des tâches dans la zone
  - Statistiques détaillées
  - Actions rapides disponibles
- **En sélection**:
  - Liste complète des tâches
  - Graphique de répartition
  - Options de filtrage avancées
- **Comparaison**:
  - Écart par rapport à la période précédente
  - Benchmark avec d'autres zones
  - Prévisions d'évolution

## 4. Cas d'Utilisation Spécifiques

### 4.1 Identification des Zones Prioritaires

- **Objectif**: Repérer rapidement les zones nécessitant une attention immédiate
- **Fonctionnalités clés**:
  - Vue d'ensemble colorée par priorité
  - Mise en évidence des hotspots
  - Filtrage dynamique par niveau de priorité
- **Interactions**:
  - Zoom sur les zones critiques
  - Basculement entre différentes métriques
  - Recherche de patterns spécifiques

### 4.2 Allocation des Ressources

- **Objectif**: Optimiser la distribution des ressources selon les priorités
- **Fonctionnalités clés**:
  - Visualisation de la charge de travail
  - Comparaison besoins/capacités
  - Simulation de réallocation
- **Interactions**:
  - Glisser-déposer pour réaffecter des ressources
  - Ajustement des priorités avec feedback visuel
  - Génération de scénarios d'allocation

### 4.3 Communication aux Parties Prenantes

- **Objectif**: Présenter clairement les priorités aux décideurs
- **Fonctionnalités clés**:
  - Vues simplifiées pour présentation
  - Annotations et points d'attention
  - Historique d'évolution des priorités
- **Interactions**:
  - Création de snapshots pour présentation
  - Génération de rapports synthétiques
  - Partage de vues personnalisées

## 5. Exigences Techniques

### 5.1 Performance

- **Volume de données**: Support jusqu'à 1000 tâches
- **Temps de rendu**: < 2 secondes pour l'affichage initial
- **Réactivité**: Mise à jour < 500ms lors des interactions

### 5.2 Accessibilité

- **Daltonisme**: Palettes alternatives pour déficiences visuelles
- **Contraste**: Respect des ratios WCAG AA (4.5:1 minimum)
- **Texte alternatif**: Descriptions pour lecteurs d'écran
- **Navigation clavier**: Focus et interactions sans souris

### 5.3 Intégration

- **Export**: PNG, SVG, PDF, données CSV
- **Embedding**: Code pour intégration dans dashboards
- **API**: Endpoints pour mise à jour dynamique

## 6. Exemples et Maquettes

### 6.1 Exemple de Treemap

```plaintext
┌─────────────────────────────────────┐
│ Domaine A                           │
│ ┌───────────┐ ┌───────────────────┐ │
│ │           │ │ Catégorie A.2     │ │
│ │ Catégorie │ │ ┌───────┐┌──────┐ │ │
│ │    A.1    │ │ │ A.2.1 ││A.2.2 │ │ │
│ │           │ │ └───────┘└──────┘ │ │
│ └───────────┘ └───────────────────┘ │
└─────────────────────────────────────┘
┌───────────────┐ ┌───────────────────┐
│ Domaine B     │ │ Domaine C         │
│ ┌─────┐┌─────┐│ │ ┌─────────┐       │
│ │B.1  ││B.2  ││ │ │         │       │
│ └─────┘└─────┘│ │ │   C.1   │       │
│ ┌─────┐┌─────┐│ │ │         │       │
│ │B.3  ││B.4  ││ │ └─────────┘       │
│ └─────┘└─────┘│ │                   │
└───────────────┘ └───────────────────┘
```plaintext
### 6.2 Exemple d'Échelle de Couleurs

```plaintext
Priorité:  Basse   Moyenne   Haute   Critique
           [Vert]   [Jaune]  [Orange]  [Rouge]
           └─────────────────────────────────┘
```plaintext
### 6.3 Exemples d'Interactions

- Clic sur Domaine A: Zoom sur ce domaine avec détails des catégories
- Survol de la catégorie B.3: Affichage des statistiques détaillées
- Filtrage sur "Critique": Seules les zones rouges restent opaques
