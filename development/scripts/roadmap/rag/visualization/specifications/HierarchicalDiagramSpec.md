# Spécification du Diagramme Hiérarchique
*Version 1.0 - 2025-05-15*

## 1. Description Générale

Le diagramme hiérarchique (arborescence) est une représentation visuelle de la structure hiérarchique des tâches de la roadmap, montrant les relations parent-enfant entre les tâches. Il permet de visualiser l'organisation globale du projet et de naviguer facilement dans la hiérarchie des tâches.

## 2. Caractéristiques Clés

### 2.1 Représentation des Nœuds et Branches

#### 2.1.1 Structure des Nœuds
- **Forme**: Rectangles arrondis pour les nœuds
- **Dimensions**: 
  - Largeur: 200px par défaut (ajustable)
  - Hauteur: 80px par défaut (ajustable)
- **Contenu**:
  - Identifiant de la tâche (coin supérieur gauche)
  - Titre de la tâche (centré)
  - Indicateur de statut (coin supérieur droit)
  - Indicateur de progression (barre en bas du nœud)
  - Indicateur de priorité (bordure colorée ou icône)
- **États visuels**:
  - Normal: Opacité 100%
  - Sélectionné: Bordure épaisse, ombre portée
  - Survolé: Légère ombre portée, opacité légèrement augmentée
  - Filtré/Masqué: Opacité réduite (30%)

#### 2.1.2 Structure des Branches
- **Lignes**: Lignes droites ou courbes (Bézier) reliant les nœuds parents aux nœuds enfants
- **Épaisseur**: 1.5px par défaut
- **Couleur**: Gris neutre (#CCCCCC) par défaut
- **Style**: 
  - Ligne continue pour les relations normales
  - Ligne pointillée pour les relations spéciales (dépendances croisées)

#### 2.1.3 Organisation Spatiale
- **Orientation**: 
  - Verticale (top-down): Racine en haut, enfants vers le bas
  - Horizontale (left-right): Racine à gauche, enfants vers la droite
- **Espacement**:
  - Entre niveaux: 100px par défaut
  - Entre nœuds du même niveau: 40px par défaut
- **Alignement**: 
  - Centré par rapport au parent
  - Possibilité d'alignement à gauche/droite ou en haut/bas

### 2.2 Indicateurs Visuels de Statut et Priorité

#### 2.2.1 Indicateurs de Statut
- **Codage par couleur**:
  - À faire: Gris (#D3D3D3)
  - En cours: Bleu (#4A86E8)
  - Bloqué: Rouge (#E74C3C)
  - Terminé: Vert (#2ECC71)
- **Représentation**:
  - Couleur de fond du nœud (option 1)
  - Badge coloré dans le coin supérieur droit (option 2)
  - Bordure colorée (option 3)
- **Icônes** (optionnelles):
  - À faire: Cercle vide
  - En cours: Cercle à moitié rempli
  - Bloqué: Panneau d'avertissement
  - Terminé: Coche

#### 2.2.2 Indicateurs de Priorité
- **Codage par couleur**:
  - Basse: Vert clair (#A9DFBF)
  - Moyenne: Jaune (#F9E79F)
  - Haute: Orange (#F5B041)
  - Critique: Rouge (#E74C3C)
- **Représentation**:
  - Bande colorée verticale sur le côté gauche du nœud
  - Icône dans le coin supérieur gauche
  - Texte avec code couleur
- **Icônes** (optionnelles):
  - Basse: Flèche vers le bas
  - Moyenne: Tiret horizontal
  - Haute: Flèche vers le haut
  - Critique: Double flèche vers le haut ou étoile

#### 2.2.3 Indicateurs de Progression
- **Barre de progression**:
  - Position: Bas du nœud
  - Hauteur: 5px
  - Couleur: Dégradé basé sur le pourcentage (0% rouge → 100% vert)
- **Affichage numérique**:
  - Format: "XX%" dans le coin inférieur droit
  - Taille: Petite (10-12px)
  - Visibilité: Configurable (toujours visible ou au survol)

### 2.3 Règles de Pliage/Dépliage des Branches

#### 2.3.1 Contrôles de Pliage/Dépliage
- **Emplacement**: Coin inférieur du nœud parent
- **Apparence**:
  - Déplié: Icône "-" ou flèche vers le bas
  - Plié: Icône "+" ou flèche vers la droite
- **Comportement au clic**:
  - Simple clic: Plier/déplier le nœud immédiat
  - Double clic sur nœud: Plier/déplier récursivement

#### 2.3.2 États de Pliage
- **Complètement déplié**: Tous les descendants visibles
- **Partiellement déplié**: Certains sous-arbres pliés
- **Complètement plié**: Aucun descendant visible
- **Indicateur de contenu plié**: Badge indiquant le nombre de descendants masqués

#### 2.3.3 Règles d'Expansion Automatique
- **Niveau d'expansion par défaut**: 2 niveaux
- **Expansion intelligente**:
  - Expansion automatique des branches avec peu de nœuds
  - Pliage automatique des branches volumineuses
- **Persistance**: Mémorisation de l'état de pliage entre les sessions

## 3. Métadonnées à Afficher

### 3.1 Informations Essentielles par Nœud
- **Identifiant**: Format hiérarchique (ex: 1.2.3)
- **Titre**: Texte principal du nœud (tronqué si trop long)
- **Statut**: Représenté visuellement (couleur/icône)
- **Priorité**: Représentée visuellement (couleur/icône)
- **Progression**: Barre de progression et/ou pourcentage

### 3.2 Informations Contextuelles au Survol
- **Infobulle détaillée**:
  - Description complète (tronquée à 200 caractères)
  - Dates importantes (début, échéance, achèvement)
  - Liste des dépendances
  - Assignés/responsables
- **Aperçu des métriques**:
  - Nombre de sous-tâches
  - Progression globale de la branche
  - Temps estimé restant

### 3.3 Indicateurs de Progression
- **Par nœud**: Barre de progression individuelle
- **Agrégé par branche**:
  - Pourcentage moyen de progression des descendants
  - Représentation visuelle (dégradé de couleur ou opacité)
- **Indicateurs temporels**:
  - En avance: Bordure verte
  - Dans les temps: Bordure normale
  - En retard: Bordure rouge ou hachurée

## 4. Cas d'Utilisation Spécifiques

### 4.1 Vue d'Ensemble de la Structure du Projet
- **Objectif**: Comprendre l'organisation globale du projet
- **Fonctionnalités clés**:
  - Vue zoomée pour voir l'ensemble de la hiérarchie
  - Codage couleur par statut ou priorité
  - Filtrage par niveau hiérarchique
- **Interactions**:
  - Zoom in/out pour ajuster le niveau de détail
  - Pliage/dépliage pour gérer la complexité visuelle

### 4.2 Navigation Hiérarchique
- **Objectif**: Explorer et naviguer dans la structure des tâches
- **Fonctionnalités clés**:
  - Expansion/réduction des branches
  - Focus sur une branche spécifique
  - Fil d'Ariane montrant le chemin hiérarchique
- **Interactions**:
  - Clic pour sélectionner un nœud
  - Double-clic pour zoomer sur une branche
  - Navigation clavier (flèches, tab)

### 4.3 Analyse de Structure
- **Objectif**: Analyser les relations et la distribution des tâches
- **Fonctionnalités clés**:
  - Mise en évidence des branches critiques
  - Statistiques par niveau ou branche
  - Détection des déséquilibres structurels
- **Interactions**:
  - Filtrage par attributs (statut, priorité, assigné)
  - Tri des nœuds frères par divers critères
  - Comparaison de branches

## 5. Exigences Techniques

### 5.1 Performance
- **Nombre de nœuds**: Support jusqu'à 500 nœuds sans dégradation notable
- **Temps de rendu**: < 1 seconde pour l'affichage initial
- **Fluidité**: 60 FPS pour les animations et interactions

### 5.2 Compatibilité
- **Navigateurs**: Chrome, Firefox, Safari, Edge (dernières versions)
- **Appareils**: Desktop (prioritaire), tablette (supporté), mobile (basique)
- **Accessibilité**: Conforme WCAG 2.1 AA

### 5.3 Intégration
- **Export**: PNG, SVG, PDF
- **Embedding**: Code d'intégration pour autres applications
- **API**: Interface programmatique pour manipulation externe

## 6. Exemples et Maquettes

### 6.1 Exemple de Structure Simple
```
Root
├── Task 1
│   ├── Task 1.1
│   └── Task 1.2
└── Task 2
    ├── Task 2.1
    │   ├── Task 2.1.1
    │   └── Task 2.1.2
    └── Task 2.2
```

### 6.2 Représentation Visuelle
[Voir maquette jointe: hierarchical-diagram-mockup.png]

### 6.3 Exemples d'Interactions
- Clic sur "+" de Task 1: Déplier pour montrer Task 1.1 et Task 1.2
- Double-clic sur Task 2: Focus sur cette branche
- Survol de Task 2.1.1: Affichage de l'infobulle détaillée
