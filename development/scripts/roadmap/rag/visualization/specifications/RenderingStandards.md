# Standards de Rendu pour les Visualisations
*Version 1.0 - 2025-05-15*

## 1. Introduction

Ce document définit les standards de rendu pour les visualisations graphiques du système Roadmap RAG. Il établit les règles concernant la palette de couleurs, la typographie, l'accessibilité et le responsive design pour assurer une expérience utilisateur cohérente et professionnelle.

## 2. Palette de Couleurs

### 2.1 Couleurs Primaires

#### 2.1.1 Couleurs de Base
- **Primaire**: #4A86E8 (Bleu)
  - Clair: #7FACEF
  - Foncé: #2A66C8
- **Secondaire**: #6C8EAD (Bleu-gris)
  - Clair: #8EABC5
  - Foncé: #4A7195
- **Tertiaire**: #2C4A52 (Bleu-vert foncé)
  - Clair: #4E6C74
  - Foncé: #1A2C30

#### 2.1.2 Couleurs Neutres
- **Fond principal**: #FFFFFF (Blanc)
- **Fond secondaire**: #F5F7FA (Gris très clair)
- **Fond tertiaire**: #E9EEF2 (Gris clair)
- **Texte principal**: #333333 (Gris très foncé)
- **Texte secondaire**: #666666 (Gris foncé)
- **Texte tertiaire**: #999999 (Gris moyen)
- **Bordures**: #DDDDDD (Gris clair)
- **Séparateurs**: #EEEEEE (Gris très clair)

#### 2.1.3 Couleurs d'Accentuation
- **Accent 1**: #2ECC71 (Vert)
- **Accent 2**: #F5B041 (Orange)
- **Accent 3**: #E74C3C (Rouge)
- **Accent 4**: #9B59B6 (Violet)
- **Accent 5**: #1ABC9C (Turquoise)

### 2.2 Couleurs Fonctionnelles

#### 2.2.1 Couleurs de Statut
- **À faire**: #D3D3D3 (Gris)
  - Texte: #666666
  - Icône: ◯ (cercle vide)
- **En cours**: #4A86E8 (Bleu)
  - Texte: #FFFFFF
  - Icône: ◑ (cercle à moitié rempli)
- **Bloqué**: #E74C3C (Rouge)
  - Texte: #FFFFFF
  - Icône: ⚠ (avertissement)
- **Terminé**: #2ECC71 (Vert)
  - Texte: #FFFFFF
  - Icône: ✓ (coche)

#### 2.2.2 Couleurs de Priorité
- **Basse**: #A9DFBF (Vert clair)
  - Texte: #2E7D32
  - Icône: ↓ (flèche bas)
- **Moyenne**: #F9E79F (Jaune)
  - Texte: #F57F17
  - Icône: − (tiret)
- **Haute**: #F5B041 (Orange)
  - Texte: #E65100
  - Icône: ↑ (flèche haut)
- **Critique**: #E74C3C (Rouge)
  - Texte: #FFFFFF
  - Icône: ⚡ (éclair)

#### 2.2.3 Couleurs d'Alerte
- **Information**: #3498DB (Bleu clair)
  - Fond: #EBF5FB
  - Bordure: #AED6F1
- **Succès**: #2ECC71 (Vert)
  - Fond: #E9F7EF
  - Bordure: #A9DFBF
- **Avertissement**: #F39C12 (Orange)
  - Fond: #FEF5E7
  - Bordure: #FAD7A0
- **Erreur**: #E74C3C (Rouge)
  - Fond: #FDEDEC
  - Bordure: #F5B7B1

### 2.3 Règles d'Utilisation des Couleurs

#### 2.3.1 Principes Généraux
- **Cohérence**: Utiliser les mêmes couleurs pour les mêmes significations
- **Hiérarchie**: Utiliser la couleur pour guider l'attention
- **Parcimonie**: Limiter le nombre de couleurs dans une même vue
- **Contraste**: Assurer la lisibilité du texte sur les fonds colorés

#### 2.3.2 Combinaisons Recommandées
- **Visualisations de données**:
  - Séquentielle: Dégradé d'une même teinte
  - Divergente: Du rouge au vert en passant par le jaune
  - Catégorielle: Utiliser les couleurs d'accentuation
- **Interface utilisateur**:
  - Fond clair avec texte foncé
  - Éléments interactifs en couleur primaire
  - Alertes et notifications en couleurs fonctionnelles

#### 2.3.3 Accessibilité des Couleurs
- **Daltonisme**:
  - Éviter les combinaisons rouge/vert sans différence de luminosité
  - Utiliser des motifs en plus des couleurs
  - Proposer des palettes alternatives
- **Contraste**:
  - Texte sur fond: Ratio minimum 4.5:1
  - Grands textes: Ratio minimum 3:1
  - Éléments d'interface: Ratio minimum 3:1

## 3. Typographie

### 3.1 Familles de Polices

#### 3.1.1 Police Principale
- **Famille**: Roboto
- **Alternatives**: Segoe UI, Helvetica Neue, Arial, sans-serif
- **Utilisation**: Corps de texte, étiquettes, menus
- **Styles disponibles**: Light (300), Regular (400), Medium (500), Bold (700)

#### 3.1.2 Police d'En-têtes
- **Famille**: Roboto Condensed
- **Alternatives**: Arial Narrow, sans-serif
- **Utilisation**: Titres, sous-titres, en-têtes
- **Styles disponibles**: Regular (400), Bold (700)

#### 3.1.3 Police Monospace
- **Famille**: Roboto Mono
- **Alternatives**: Consolas, Courier New, monospace
- **Utilisation**: Code, identifiants, données techniques
- **Styles disponibles**: Regular (400), Medium (500)

### 3.2 Échelle Typographique

#### 3.2.1 Tailles de Base
- **Corps de texte**: 14px (1rem)
- **Petit texte**: 12px (0.857rem)
- **Très petit texte**: 10px (0.714rem)
- **Grand texte**: 16px (1.143rem)
- **Très grand texte**: 18px (1.286rem)

#### 3.2.2 Hiérarchie des Titres
- **H1**: 24px (1.714rem), Bold
- **H2**: 20px (1.429rem), Bold
- **H3**: 18px (1.286rem), Medium
- **H4**: 16px (1.143rem), Medium
- **H5**: 14px (1rem), Bold
- **H6**: 14px (1rem), Medium

#### 3.2.3 Éléments Spécifiques
- **Labels**: 12px, Medium
- **Boutons**: 14px, Medium
- **Tooltips**: 12px, Regular
- **Badges**: 10px, Bold
- **Légendes**: 12px, Regular
- **Navigation**: 14px, Medium

### 3.3 Règles Typographiques

#### 3.3.1 Espacement
- **Interligne (line-height)**:
  - Corps de texte: 1.5
  - Titres: 1.2
  - Texte condensé: 1.3
- **Espacement des lettres (letter-spacing)**:
  - Normal: 0
  - Titres: -0.01em
  - Texte en capitales: 0.05em
- **Espacement des paragraphes**:
  - Marge supérieure: 0.5em
  - Marge inférieure: 1em

#### 3.3.2 Alignement
- **Texte principal**: Aligné à gauche
- **Titres**: Alignés à gauche
- **Données numériques**: Alignées à droite
- **Étiquettes dans visualisations**:
  - Horizontales: Centrées
  - Verticales: Alignées à gauche

#### 3.3.3 Troncature et Débordement
- **Texte long**:
  - Ellipsis (...) après 2 lignes maximum
  - Tooltip avec texte complet au survol
- **Identifiants longs**:
  - Troncature au milieu (début...fin)
  - Pas de césure des mots

## 4. Accessibilité

### 4.1 Contraste et Lisibilité

#### 4.1.1 Ratios de Contraste
- **Texte normal**: Minimum 4.5:1
- **Grand texte (18px+)**: Minimum 3:1
- **Texte sur éléments graphiques**: Minimum 3:1
- **Éléments d'interface**: Minimum 3:1 avec adjacents

#### 4.1.2 Techniques d'Amélioration
- **Ombres portées**: Légère ombre pour texte sur fond variable
- **Contours**: Fin contour pour améliorer la lisibilité
- **Fonds semi-transparents**: Derrière le texte sur images
- **Taille de texte minimale**: 12px (sauf mentions légales: 10px)

#### 4.1.3 Modes d'Affichage Alternatifs
- **Mode sombre**: Inversion intelligente des contrastes
- **Mode fort contraste**: Augmentation des différences
- **Mode daltonisme**: Palettes adaptées aux différents types
- **Mode texte**: Alternative non graphique

### 4.2 Navigation et Interaction

#### 4.2.1 Navigation au Clavier
- **Focus visible**: Indication claire de l'élément actif
- **Ordre logique**: Tabulation suivant la structure visuelle
- **Raccourcis clavier**: Pour actions fréquentes
- **Skip links**: Pour sauter aux sections principales

#### 4.2.2 Alternatives aux Interactions Complexes
- **Hover/survol**: Alternative par focus ou clic
- **Drag-and-drop**: Alternative par menus ou boutons
- **Pinch-zoom**: Alternative par boutons +/-
- **Gestes multi-touch**: Alternatives à un doigt

#### 4.2.3 Feedback et Assistance
- **Messages d'erreur**: Clairs et avec solutions
- **Tooltips**: Informations contextuelles
- **Indicateurs d'état**: Visuels et textuels
- **Aide contextuelle**: Disponible à chaque étape

### 4.3 Compatibilité avec les Technologies d'Assistance

#### 4.3.1 Structure Sémantique
- **Balisage ARIA**: Rôles, états et propriétés
- **Landmarks**: Régions principales identifiées
- **Hiérarchie de titres**: Structure logique
- **Listes et tableaux**: Balisage approprié

#### 4.3.2 Textes Alternatifs
- **Images**: Descriptions concises et pertinentes
- **Graphiques**: Résumés et tendances principales
- **Icônes**: Signification et fonction
- **Visualisations complexes**: Descriptions textuelles équivalentes

#### 4.3.3 Annonces Dynamiques
- **Mises à jour de contenu**: Notifications aux lecteurs d'écran
- **Résultats de filtrage**: Annonce du nombre de résultats
- **Progression**: Indication vocale de l'avancement
- **Erreurs**: Annonce immédiate des problèmes

## 5. Responsive Design

### 5.1 Grille et Mise en Page

#### 5.1.1 Système de Grille
- **Base**: Grille à 12 colonnes
- **Gouttières**: 16px (desktop), 8px (mobile)
- **Marges extérieures**: 
  - Desktop: 24px
  - Tablette: 16px
  - Mobile: 8px
- **Points de rupture**:
  - Mobile: < 768px
  - Tablette: 768px - 1023px
  - Desktop: 1024px - 1439px
  - Large: ≥ 1440px

#### 5.1.2 Comportements Adaptatifs
- **Réorganisation**: Colonnes en lignes sur petit écran
- **Simplification**: Réduction des éléments non essentiels
- **Priorisation**: Contenu important d'abord
- **Densité**: Espacement réduit sur petit écran

#### 5.1.3 Conteneurs et Limites
- **Largeur maximale**: 1440px
- **Largeur minimale**: 320px
- **Hauteur maximale**: 80vh pour les visualisations
- **Débordement**: Scroll vertical privilégié

### 5.2 Adaptation des Visualisations

#### 5.2.1 Stratégies de Redimensionnement
- **Mise à l'échelle proportionnelle**: Préservation des ratios
- **Réorganisation**: Changement de layout
- **Simplification**: Réduction des détails
- **Pagination**: Division en plusieurs vues

#### 5.2.2 Modifications Spécifiques par Type
- **Diagramme hiérarchique**:
  - Mobile: Vue verticale uniquement, niveaux réduits
  - Tablette: Expansion limitée, focus sur branches principales
- **Diagramme de Gantt**:
  - Mobile: Vue mensuelle uniquement, détails au tap
  - Tablette: Vue hebdomadaire, scroll horizontal
- **Graphe de dépendances**:
  - Mobile: Vue simplifiée, focus sur nœuds critiques
  - Tablette: Densité réduite, regroupement augmenté
- **Carte de chaleur**:
  - Mobile: Cellules plus grandes, moins de niveaux
  - Tablette: Légende réduite, focus sur hotspots

#### 5.2.3 Contrôles Adaptés
- **Desktop**: Interactions souris précises
- **Tablette**: Zones tactiles agrandies (min 44px)
- **Mobile**: 
  - Boutons principaux: min 48px
  - Espacement entre éléments: min 8px
  - Menus simplifiés et empilés

### 5.3 Performance Mobile

#### 5.3.1 Optimisations Graphiques
- **Résolution adaptative**: Simplification à faible DPI
- **Animations réduites**: Option de désactivation
- **Rendu progressif**: Éléments principaux d'abord
- **Mise en cache**: Vues précalculées pour petits écrans

#### 5.3.2 Gestion des Ressources
- **Chargement différé**: Données non visibles
- **Pagination**: Limites de données par vue
- **Compression**: Images et assets optimisés
- **Mise en cache locale**: Données fréquemment utilisées

#### 5.3.3 Considérations Spéciales
- **Mode hors ligne**: Fonctionnalités de base disponibles
- **Interruptions**: Reprise après veille/changement d'app
- **Batterie**: Réduction des calculs intensifs
- **Données mobiles**: Option basse consommation
