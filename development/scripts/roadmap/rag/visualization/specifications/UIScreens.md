# Spécification des Écrans d'Interface Utilisateur
*Version 1.0 - 2025-05-15*

## 1. Introduction

Ce document définit les spécifications pour les écrans d'interface utilisateur du système de visualisation Roadmap RAG. Il décrit la structure, les composants et les interactions pour chaque écran principal, ainsi que les règles de navigation et d'organisation de l'information.

## 2. Dashboard de Visualisation

### 2.1 Structure Générale

#### 2.1.1 Layout
```
┌─────────────────────────────────────────────────────────────┐
│ [Logo] Roadmap Visualization Dashboard           [User Menu] │ <- Header
├─────────┬───────────────────────────────────────┬───────────┤
│         │                                       │           │
│         │                                       │           │
│ Selector│           Main Visualization          │  Details  │
│  Panel  │                 Area                  │   Panel   │
│         │                                       │           │
│         │                                       │           │
├─────────┴───────────────────────────────────────┴───────────┤
│ [Status Bar]     [Timeline Controls]     [View Options]     │ <- Footer
└─────────────────────────────────────────────────────────────┘
```

#### 2.1.2 Dimensions et Proportions
- **Largeur totale**: 100% (responsive)
- **Hauteur totale**: 100vh (plein écran)
- **Header**: 60px de hauteur
- **Footer**: 40px de hauteur
- **Selector Panel**: 20% de la largeur (min: 250px, max: 350px)
- **Details Panel**: 25% de la largeur (min: 300px, max: 400px)
- **Main Area**: Reste de l'espace disponible

#### 2.1.3 Comportement Responsive
- **Desktop** (≥1024px): Layout complet comme ci-dessus
- **Tablette** (768px-1023px): 
  - Panels rétractables (icônes d'expansion)
  - Main Area prioritaire
- **Mobile** (<768px): 
  - Layout vertical (panels en accordéon)
  - Navigation par onglets entre les sections

### 2.2 Sélecteur de Visualisation

#### 2.2.1 Composants
- **Sélecteur de Type**:
  - Onglets ou boutons radio pour chaque type
  - Icône + libellé pour chaque option
  - Indication visuelle du type actif
- **Filtres Rapides**:
  - Statut (multiselect avec code couleur)
  - Priorité (multiselect avec code couleur)
  - Période (sélecteur de plage de dates)
- **Recherche**:
  - Champ de recherche textuelle
  - Suggestions automatiques
  - Historique des recherches récentes
- **Vues Enregistrées**:
  - Liste des configurations sauvegardées
  - Option de sauvegarde de la vue actuelle
  - Gestion (renommer, supprimer)

#### 2.2.2 Interactions
- **Changement de Type**: Transition animée vers nouvelle visualisation
- **Application de Filtres**: Mise à jour immédiate ou différée (bouton "Appliquer")
- **Recherche**: Mise en évidence des résultats dans la visualisation
- **Chargement de Vue**: Restauration complète de la configuration

#### 2.2.3 États et Feedback
- **Chargement**: Indicateur de progression
- **Filtres Actifs**: Badges ou indicateurs visuels
- **Résultats Vides**: Message explicatif et suggestions
- **Erreurs**: Notifications non intrusives avec options de correction

### 2.3 Zone Principale de Visualisation

#### 2.3.1 Composants
- **Conteneur de Visualisation**:
  - Zone de rendu principale
  - Contrôles de zoom/pan superposés
  - Indicateur d'échelle/niveau
- **Légende**:
  - Codes couleur et symboles
  - Position: bas ou côté droit
  - Rétractable/extensible
- **Minimap** (optionnelle):
  - Vue d'ensemble réduite
  - Cadre de visualisation actuelle
  - Position: coin inférieur droit

#### 2.3.2 Interactions
- **Navigation**:
  - Zoom: Molette/pincement ou boutons +/-
  - Pan: Glisser-déposer ou flèches directionnelles
  - Focus: Double-clic sur élément
- **Sélection**:
  - Clic simple: Sélection unique
  - Ctrl+clic: Sélection multiple
  - Lasso/rectangle: Sélection par zone
- **Contextuel**:
  - Clic droit: Menu contextuel
  - Survol: Tooltip informatif
  - Glisser-déposer: Réorganisation (si applicable)

#### 2.3.3 Modes d'Affichage
- **Standard**: Visualisation complète
- **Focus**: Zoom sur élément sélectionné
- **Comparaison**: Vue côte à côte (avant/après)
- **Présentation**: Mode épuré pour partage/export

### 2.4 Panneau de Détails

#### 2.4.1 Composants
- **En-tête**:
  - Titre de l'élément sélectionné
  - Identifiant
  - Boutons d'action rapide
- **Informations Principales**:
  - Statut avec indicateur visuel
  - Priorité avec indicateur visuel
  - Dates clés (début, fin, mise à jour)
  - Progression (barre + pourcentage)
- **Onglets de Détails**:
  - Général: Informations de base
  - Relations: Dépendances et liens
  - Historique: Modifications récentes
  - Notes: Commentaires et annotations
- **Actions**:
  - Boutons d'édition (si autorisé)
  - Options d'export
  - Liens vers systèmes externes

#### 2.4.2 États
- **Aucune Sélection**: Message d'invite + statistiques globales
- **Sélection Unique**: Détails complets de l'élément
- **Sélection Multiple**: Résumé comparatif + actions groupées
- **Mode Édition**: Formulaires et contrôles d'édition

#### 2.4.3 Comportement
- **Mise à Jour**: Automatique à la sélection
- **Persistance**: Maintien des informations lors du défilement
- **Redimensionnement**: Ajustable par l'utilisateur (drag)
- **Masquage**: Option de réduction complète

## 3. Vue Détaillée

### 3.1 Structure Générale

#### 3.1.1 Layout
```
┌─────────────────────────────────────────────────────────────┐
│ [Back] Detailed View: [Title]                    [Actions]  │ <- Header
├─────────────────────────────────────────────────┬───────────┤
│                                                 │           │
│                                                 │           │
│                                                 │           │
│             Full-Screen Visualization           │  Details  │
│                                                 │   Panel   │
│                                                 │  (Fixed)  │
│                                                 │           │
├─────────────────────────────────────────────────┴───────────┤
│ [Advanced Controls]                             [Export]    │ <- Footer
└─────────────────────────────────────────────────────────────┘
```

#### 3.1.2 Caractéristiques Spécifiques
- **Visualisation Agrandie**: Occupe 75-80% de l'écran
- **Panneau de Détails**: Fixe, non rétractable
- **Contrôles Avancés**: Plus d'options que dans le dashboard
- **Navigation**: Bouton retour vers dashboard
- **Mode Immersif**: Option plein écran sans panels

### 3.2 Visualisation Plein Écran

#### 3.2.1 Améliorations par Type
- **Diagramme Hiérarchique**:
  - Niveaux de détail supplémentaires
  - Annotations visibles
  - Minimap permanente
- **Diagramme de Gantt**:
  - Échelle temporelle ajustable
  - Affichage des ressources
  - Chemin critique visible
- **Graphe de Dépendances**:
  - Filtres de profondeur
  - Regroupements dynamiques
  - Statistiques de centralité
- **Carte de Chaleur**:
  - Seuils ajustables
  - Superposition de métriques
  - Comparaison temporelle

#### 3.2.2 Contrôles Spécifiques
- **Barre d'Outils Contextuelle**:
  - Apparaît près de la sélection
  - Options spécifiques au type
  - Disparaît après inactivité
- **Contrôles de Filtrage Avancé**:
  - Expressions complexes
  - Sauvegarde de filtres
  - Visualisation de l'impact
- **Options d'Affichage**:
  - Densité d'information
  - Style visuel (standard, présentation, impression)
  - Annotations et marqueurs

### 3.3 Panneau Latéral de Détails

#### 3.3.1 Contenu Enrichi
- **Informations Complètes**:
  - Tous les champs disponibles
  - Métriques calculées
  - Indicateurs de tendance
- **Visualisations Secondaires**:
  - Mini-graphiques contextuels
  - Indicateurs de performance
  - Comparaisons historiques
- **Documentation**:
  - Notes détaillées
  - Pièces jointes
  - Références externes

#### 3.3.2 Actions Avancées
- **Édition Directe**:
  - Modification des propriétés
  - Ajout/suppression de relations
  - Commentaires et annotations
- **Analyse**:
  - Calcul d'impact
  - Simulation de modifications
  - Détection de problèmes
- **Collaboration**:
  - Partage de vue spécifique
  - Assignation de tâches
  - Historique des modifications

## 4. Mode Comparaison

### 4.1 Structure Générale

#### 4.1.1 Layout
```
┌─────────────────────────────────────────────────────────────┐
│ [Back] Comparison Mode                          [Options]   │ <- Header
├─────────────────────────┬─────────────────────┬─────────────┤
│                         │                     │             │
│                         │                     │             │
│     Visualization A     │    Visualization B  │  Comparison │
│                         │                     │   Summary   │
│                         │                     │             │
│                         │                     │             │
├─────────────────────────┴─────────────────────┴─────────────┤
│ [Sync Controls]  [Difference Highlighting]    [Export]      │ <- Footer
└─────────────────────────────────────────────────────────────┘
```

#### 4.1.2 Modes de Comparaison
- **Côte à Côte**: Deux visualisations parallèles
- **Superposition**: Éléments des deux vues combinés
- **Avant/Après**: Transition entre deux états
- **Différentiel**: Affichage uniquement des différences

### 4.2 Contrôles Synchronisés

#### 4.2.1 Options de Synchronisation
- **Navigation**: Zoom/pan synchronisé ou indépendant
- **Sélection**: Mise en évidence croisée
- **Filtres**: Application simultanée ou séparée
- **Période**: Alignement temporel

#### 4.2.2 Sélecteurs de Version
- **Points de Comparaison**:
  - Versions historiques
  - Scénarios alternatifs
  - Prévisions vs réalité
- **Mécanisme de Sélection**:
  - Liste déroulante de versions
  - Calendrier pour dates spécifiques
  - Curseur temporel

### 4.3 Indicateurs de Différences

#### 4.3.1 Mise en Évidence Visuelle
- **Ajouts**: Vert ou bordure verte
- **Suppressions**: Rouge ou bordure rouge
- **Modifications**: Orange ou bordure orange
- **Inchangés**: Gris ou transparence réduite

#### 4.3.2 Résumé des Différences
- **Statistiques Globales**:
  - Nombre d'éléments modifiés
  - Pourcentage de changement
  - Impact sur métriques clés
- **Catégorisation**:
  - Par type de changement
  - Par domaine/composant
  - Par importance
- **Tendances**:
  - Direction du changement
  - Vitesse d'évolution
  - Prédictions basées sur historique

## 5. Contrôles de Filtrage et Navigation

### 5.1 Contrôles de Filtrage

#### 5.1.1 Types de Filtres
- **Attributs**:
  - Statut (multiselect)
  - Priorité (multiselect)
  - Assigné (autocomplete)
  - Tags (chips)
- **Temporels**:
  - Période (date range picker)
  - Durée (slider)
  - Échéance (before/after)
- **Structurels**:
  - Niveau hiérarchique (dropdown)
  - Relations (has dependency, is blocked)
  - Groupes (appartenance)

#### 5.1.2 Interface de Filtrage
- **Filtres Rapides**:
  - Préréglages communs
  - Derniers filtres utilisés
  - Suggestions contextuelles
- **Filtres Avancés**:
  - Constructeur d'expressions
  - Opérateurs logiques (ET, OU, NON)
  - Conditions complexes
- **Gestion des Filtres**:
  - Sauvegarde de configurations
  - Partage de filtres
  - Import/export

#### 5.1.3 Feedback de Filtrage
- **Indicateurs Actifs**:
  - Badges sur filtres appliqués
  - Résumé textuel des conditions
  - Option de désactivation rapide
- **Résultats**:
  - Compteur d'éléments filtrés
  - Pourcentage du total
  - Alerte si résultat vide

### 5.2 Contrôles de Navigation

#### 5.2.1 Navigation Spatiale
- **Zoom**:
  - Boutons +/- avec niveau actuel
  - Slider de niveau de zoom
  - Préréglages (fit all, fit selection)
- **Pan**:
  - Contrôles directionnels
  - Mode main (hand tool)
  - Retour à la position initiale
- **Focus**:
  - Zoom sur sélection
  - Centrage automatique
  - Breadcrumbs hiérarchiques

#### 5.2.2 Navigation Temporelle
- **Timeline**:
  - Slider avec marqueurs d'événements
  - Boutons avant/arrière
  - Lecture automatique (animation)
- **Périodes**:
  - Sélecteur de granularité (jour, semaine, mois)
  - Raccourcis (aujourd'hui, ce mois, trimestre)
  - Comparaison de périodes

#### 5.2.3 Raccourcis et Gestes
- **Clavier**:
  - Flèches: déplacement
  - +/-: zoom
  - Espace: sélection
  - Échap: annuler/retour
- **Souris**:
  - Molette: zoom
  - Clic-droit: menu contextuel
  - Double-clic: focus
  - Shift+sélection: multi-sélection
- **Tactile**:
  - Pincement: zoom
  - Balayage: déplacement
  - Tap: sélection
  - Double-tap: focus

### 5.3 Contrôles de Personnalisation

#### 5.3.1 Options Visuelles
- **Thèmes**:
  - Clair/sombre
  - Impression
  - Présentation
  - Personnalisé
- **Densité**:
  - Compacte
  - Standard
  - Confortable
- **Mise en Évidence**:
  - Par statut
  - Par priorité
  - Par progression
  - Par assignation

#### 5.3.2 Préférences Utilisateur
- **Comportement**:
  - Auto-refresh (on/off + intervalle)
  - Animations (on/off + vitesse)
  - Tooltips (on/off + délai)
- **Affichage**:
  - Champs visibles
  - Ordre de tri par défaut
  - Niveau de détail initial
- **Notifications**:
  - Alertes de changements
  - Rappels d'échéances
  - Mentions et assignations

#### 5.3.3 Sauvegarde de Configuration
- **Profils**:
  - Création de profils nommés
  - Changement rapide entre profils
  - Profil par défaut
- **Partage**:
  - Export de configuration
  - Partage par lien
  - Application à d'autres utilisateurs
- **Réinitialisation**:
  - Retour aux paramètres par défaut
  - Réinitialisation partielle
  - Historique des configurations
