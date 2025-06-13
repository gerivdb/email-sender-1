# Spécification du Diagramme de Gantt Simplifié

*Version 1.0 - 2025-05-15*

## 1. Description Générale

Le diagramme de Gantt simplifié est une représentation temporelle des tâches de la roadmap, montrant leur durée prévue, dates de début et de fin, ainsi que les dépendances temporelles. Il permet de visualiser la planification du projet dans le temps et de suivre l'avancement par rapport au calendrier prévu.

## 2. Caractéristiques Clés

### 2.1 Représentation de l'Axe Temporel

#### 2.1.1 Structure de l'Axe

- **Orientation**: Horizontale, de gauche à droite
- **Unités de temps**:
  - Jours (vue détaillée)
  - Semaines (vue intermédiaire)
  - Mois (vue globale)
  - Trimestres (vue très globale)
- **Graduation**:
  - Graduations principales: Mois/Semaines selon le zoom
  - Graduations secondaires: Jours/Semaines selon le zoom
- **Étiquettes**:
  - Format date: "JJ/MM" ou "MM/AAAA" selon le zoom
  - Jours de la semaine: Abréviation à 2 lettres (Lu, Ma, Me...)
  - Mois: Nom complet ou abrégé à 3 lettres

#### 2.1.2 Repères Temporels

- **Aujourd'hui**: Ligne verticale rouge
- **Jalons**: Diamants ou triangles à des dates clés
- **Périodes spéciales**:
  - Week-ends: Fond grisé léger
  - Jours fériés: Fond hachuré léger
  - Périodes de congés: Fond coloré spécifique

#### 2.1.3 Navigation Temporelle

- **Zoom**: 
  - Niveaux prédéfinis (jour, semaine, mois, trimestre)
  - Zoom continu via molette ou pincement
- **Déplacement**:
  - Glisser-déposer horizontal
  - Boutons "précédent/suivant" pour périodes
  - Sélecteur de période rapide (aujourd'hui, semaine, mois)

### 2.2 Visualisation des Barres de Tâches

#### 2.2.1 Apparence des Barres

- **Forme**: Rectangles arrondis
- **Dimensions**:
  - Hauteur: 30px par défaut (configurable)
  - Largeur: Proportionnelle à la durée
- **Couleurs**:
  - Par statut: Même code couleur que le diagramme hiérarchique
  - Par catégorie: Palette de couleurs distinctes
  - Par priorité: Dégradé du vert (basse) au rouge (critique)
- **Bordures**:
  - Standard: 1px solide, légèrement plus foncé que le fond
  - Sélectionné: 2px solide, couleur de mise en évidence

#### 2.2.2 Contenu des Barres

- **Texte principal**: Titre de la tâche (tronqué si nécessaire)
- **Identifiant**: Code de la tâche (optionnel, petit)
- **Indicateurs**:
  - Progression: Barre interne ou dégradé
  - Retard: Hachures rouges ou bordure rouge
  - Priorité: Icône ou bande verticale

#### 2.2.3 États des Barres

- **Normal**: Opacité 100%
- **Sélectionné**: Bordure épaisse, légère ombre
- **Survolé**: Légère ombre, opacité augmentée
- **Filtré/Masqué**: Opacité réduite (30%)
- **Terminé**: Hachures diagonales ou motif spécifique

### 2.3 Représentation des Dépendances

#### 2.3.1 Types de Dépendances

- **Fin-Début** (standard): La tâche B commence après la fin de la tâche A
- **Début-Début**: La tâche B commence après le début de la tâche A
- **Fin-Fin**: La tâche B finit après la fin de la tâche A
- **Début-Fin**: La tâche B finit après le début de la tâche A

#### 2.3.2 Apparence des Liens

- **Lignes**: 
  - Style: Flèches courbes ou lignes brisées
  - Épaisseur: 1.5px par défaut
  - Couleur: Gris neutre (#888888) par défaut

- **Marqueurs**:
  - Flèche à l'extrémité de destination
  - Points de contrôle aux coudes (pour manipulation)
- **États**:
  - Normal: Ligne continue
  - Critique: Ligne rouge ou plus épaisse
  - Survolé: Mise en évidence (épaisseur augmentée)
  - Problématique: Ligne pointillée rouge

#### 2.3.3 Interaction avec les Dépendances

- **Création**: Glisser-déposer entre barres
- **Modification**: Points de contrôle déplaçables
- **Suppression**: Clic droit ou bouton dédié
- **Mise en évidence**: Survol pour afficher le chemin complet

## 3. Métadonnées à Afficher

### 3.1 Informations Essentielles par Tâche

- **Identifiant**: Code hiérarchique (ex: 1.2.3)
- **Titre**: Nom de la tâche
- **Dates**:
  - Début prévu
  - Fin prévue
  - Début réel (si commencé)
  - Fin réelle (si terminé)
- **Durée**: En jours ouvrés
- **Statut**: Représenté visuellement (couleur/motif)

### 3.2 Indicateurs de Progression

- **Pourcentage d'avancement**:
  - Représentation visuelle: Portion remplie de la barre
  - Valeur numérique: Affichée dans ou à côté de la barre
- **Comparaison prévu/réel**:
  - Barre supérieure: Planning prévu
  - Barre inférieure: Avancement réel
- **Jalons intermédiaires**:
  - Points ou lignes verticales sur la barre
  - Couleur indiquant le statut (atteint/non atteint)

### 3.3 Informations de Retard/Avance

- **Indicateur visuel**:
  - En avance: Bordure ou hachures vertes
  - Dans les temps: Normal
  - En retard: Bordure ou hachures rouges
- **Quantification**:
  - Nombre de jours d'avance/retard
  - Pourcentage par rapport à la durée totale
- **Projection**:
  - Date de fin projetée basée sur l'avancement actuel
  - Différence avec la date de fin prévue

## 4. Cas d'Utilisation Spécifiques

### 4.1 Planification Temporelle du Projet

- **Objectif**: Visualiser et ajuster le planning du projet
- **Fonctionnalités clés**:
  - Vue d'ensemble de toutes les tâches dans le temps
  - Ajustement des dates par glisser-déposer
  - Création/modification des dépendances
- **Interactions**:
  - Déplacement des barres pour modifier les dates
  - Redimensionnement pour modifier les durées
  - Création de liens de dépendance

### 4.2 Suivi de l'Avancement par Rapport au Calendrier

- **Objectif**: Évaluer l'état d'avancement du projet
- **Fonctionnalités clés**:
  - Comparaison prévu/réel
  - Mise en évidence des retards
  - Filtrage par statut ou période
- **Interactions**:
  - Mise à jour du pourcentage d'avancement
  - Marquage des jalons comme atteints
  - Génération de rapports d'avancement

### 4.3 Analyse de Chemin Critique

- **Objectif**: Identifier et gérer les tâches critiques
- **Fonctionnalités clés**:
  - Mise en évidence du chemin critique
  - Calcul des marges (flottement)
  - Simulation de modifications de planning
- **Interactions**:
  - Sélection d'une tâche pour voir son impact
  - Ajustement des ressources ou durées
  - Visualisation des scénarios alternatifs

## 5. Exigences Techniques

### 5.1 Performance

- **Nombre de tâches**: Support jusqu'à 200 tâches sans dégradation
- **Temps de rendu**: < 1.5 secondes pour l'affichage initial
- **Fluidité**: Réactivité immédiate lors des interactions

### 5.2 Compatibilité

- **Navigateurs**: Chrome, Firefox, Safari, Edge (dernières versions)
- **Appareils**: Desktop (optimal), tablette (supporté)
- **Impression**: Mise en page optimisée pour l'impression

### 5.3 Intégration

- **Export**: PNG, PDF, Excel/CSV (données)
- **Import**: MS Project, formats iCalendar
- **API**: Endpoints pour mise à jour programmatique

## 6. Exemples et Maquettes

### 6.1 Exemple de Structure Temporelle

```plaintext
Mai 2025                 Juin 2025                Juillet 2025
|---------------------|---------------------|---------------------|
Task 1 [==============]
Task 2      [=========]
Task 3                 [=======]
Task 4                       [===============]
Task 5                                [=======]
```plaintext
### 6.2 Représentation des Dépendances

```plaintext
Task 1 [==============]
                     \
Task 2                [=========]
                                \
Task 3                           [=======]
        \
         \
Task 4    [===============]
                          \
Task 5                     [=======]
```plaintext
### 6.3 Exemples d'Interactions

- Glisser Task 3 vers la droite: Ajuste sa date de début et impacte Task 5
- Clic sur Task 4: Affiche ses détails et met en évidence ses dépendances
- Ajustement de la progression de Task 2 à 75%: Met à jour la barre interne
