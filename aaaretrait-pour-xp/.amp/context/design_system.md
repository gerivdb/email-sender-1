# Système de design

Ce document décrit le système de design utilisé dans le projet, incluant les polices, les couleurs, les composants et les patterns d'interface.

## Principes de design

### Simplicité

- Interfaces épurées et intuitives
- Élimination des éléments non essentiels
- Focus sur les tâches principales de l'utilisateur

### Cohérence

- Expérience utilisateur uniforme à travers l'application
- Réutilisation des patterns d'interaction
- Terminologie cohérente

### Accessibilité

- Conformité WCAG 2.1 AA
- Support des lecteurs d'écran
- Contraste suffisant pour tous les textes

### Performance

- Temps de chargement rapides
- Animations fluides
- Optimisation pour différents appareils

## Typographie

### Polices principales

- **Titres** : Inter, sans-serif
  - H1: 32px/40px, 700
  - H2: 24px/32px, 700
  - H3: 20px/28px, 600
  - H4: 18px/24px, 600
  - H5: 16px/24px, 600
  - H6: 14px/20px, 600

- **Corps de texte** : Inter, sans-serif
  - Regular: 16px/24px, 400
  - Small: 14px/20px, 400
  - XSmall: 12px/16px, 400

- **Monospace** : JetBrains Mono, monospace
  - Pour le code et les données techniques

### Hiérarchie typographique

- Utiliser la taille, le poids et la couleur pour établir la hiérarchie
- Limiter à 3 niveaux de hiérarchie par écran
- Maintenir un espacement cohérent entre les éléments textuels

## Couleurs

### Palette primaire

- **Primaire** : #3366FF

  - Hover: #2952CC

  - Active: #1F3D99

  - Light: #D6E0FF

- **Secondaire** : #FF6633

  - Hover: #CC5229

  - Active: #993D1F

  - Light: #FFE0D6

### Palette neutre

- **Noir** : #000000

- **Gris foncé** : #333333

- **Gris moyen** : #666666

- **Gris clair** : #999999

- **Gris très clair** : #EEEEEE

- **Blanc** : #FFFFFF

### Couleurs sémantiques

- **Succès** : #00CC66

  - Light: #E6F9F1

- **Avertissement** : #FFCC00

  - Light: #FFF9E6

- **Erreur** : #FF3333

  - Light: #FFEBEB

- **Information** : #3399FF

  - Light: #EBF5FF

### Utilisation des couleurs

- Limiter l'utilisation des couleurs vives aux éléments interactifs et points d'attention
- Utiliser les variations de luminosité pour indiquer les états (hover, active, disabled)
- Maintenir un contraste suffisant pour l'accessibilité

## Layout et grille

### Grille de base

- **Colonnes** : 12 colonnes
- **Gouttière** : 24px
- **Marge** : 24px (desktop), 16px (tablette), 8px (mobile)

### Breakpoints

- **Mobile** : < 768px
- **Tablette** : 768px - 1023px
- **Desktop** : 1024px - 1439px
- **Large Desktop** : ≥ 1440px

### Espacement

- **4px** : Espacement minimal (entre éléments liés)
- **8px** : Espacement petit (entre éléments d'un groupe)
- **16px** : Espacement moyen (entre groupes d'éléments)
- **24px** : Espacement large (entre sections)
- **32px** : Espacement très large (entre blocs majeurs)
- **48px** : Espacement maximal (marges de page)

## Composants

### Composants de base

- **Boutons** : Primaire, Secondaire, Tertiaire, Danger
- **Champs de formulaire** : Text, Select, Checkbox, Radio, Toggle
- **Cartes** : Standard, Interactive, Statut
- **Tableaux** : Simple, Complexe, Données
- **Navigation** : Menu principal, Tabs, Breadcrumbs
- **Feedback** : Alertes, Toasts, Modals

### Patterns d'interaction

- **Formulaires** : Validation en temps réel, messages d'erreur contextuels
- **Listes** : Pagination, tri, filtrage
- **Tableaux de bord** : Widgets configurables, données en temps réel
- **Wizards** : Étapes séquentielles, progression visible

### États des composants

- **Default** : État initial
- **Hover** : Survol de la souris
- **Active/Pressed** : Clic/tap
- **Focus** : Focus clavier
- **Disabled** : Non disponible
- **Loading** : Chargement en cours
- **Error** : État d'erreur

## Iconographie

### Style d'icônes

- Style linéaire cohérent
- Épaisseur de trait uniforme (2px)
- Coins légèrement arrondis
- Tailles standardisées : 16px, 20px, 24px

### Utilisation

- Utiliser les icônes pour renforcer le sens, pas pour le remplacer
- Accompagner les icônes de texte quand elles représentent des actions
- Maintenir une bibliothèque d'icônes cohérente

## Animation et transitions

### Principes

- Animations subtiles et fonctionnelles
- Durées courtes (150-300ms)
- Courbes d'accélération naturelles

### Types d'animations

- **Transitions de page** : Fade, slide
- **Feedback** : Pulse, shake
- **États** : Fade, scale
- **Chargement** : Spinners, skeletons

## Ressources

### Bibliothèques

- Figma Design System
- Bibliothèque d'icônes
- Documentation des composants

### Outils

- Figma pour la conception
- Storybook pour la documentation des composants
- Chromatic pour les tests visuels
