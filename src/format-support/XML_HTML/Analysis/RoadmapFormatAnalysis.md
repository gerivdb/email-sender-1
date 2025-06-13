# Analyse de la conversion entre formats XML/HTML et format Roadmap

## 1. Analyse de la structure des formats

### 1.1 Structure du format Roadmap (Markdown)

Le format Roadmap utilise une structure Markdown hiérarchique avec les éléments suivants :

1. **Titres de section** : Utilisent la syntaxe `## N. Titre` pour définir les sections principales

2. **Métadonnées de section** : Informations comme la complexité, le temps estimé et la progression
3. **Phases** : Définies avec `- [ ] **Phase N: Titre**` (non cochées) ou `- [x] **Phase N: Titre**` (cochées)
4. **Tâches** : Définies avec `  - [ ] Titre` (non cochées) ou `  - [x] Titre` (cochées)
5. **Sous-tâches** : Définies avec `    - [ ] Titre` (non cochées) ou `    - [x] Titre` (cochées)
6. **Notes** : Définies avec `  > *Note: Texte*`
7. **Métadonnées de tâche** : Informations comme la date de début, ajoutées à la fin de la ligne de tâche

La structure hiérarchique est définie par l'indentation (2 espaces par niveau) et les cases à cocher indiquent l'état d'avancement.

### 1.2 Structure du format XML

Le format XML est un format de données hiérarchique qui utilise des balises pour définir des éléments et des attributs pour définir des propriétés. Une représentation XML de la roadmap pourrait être :

```xml
<roadmap title="Roadmap personnelle d'amelioration du projet">
  <overview>Ce document presente une feuille de route organisee par ordre de complexite croissante...</overview>
  <section id="0" title="Taches prioritaires (Analyse des erreurs et ameliorations critiques)">
    <metadata>
      <complexity>Elevee</complexity>
      <estimatedTime>7-10 jours</estimatedTime>
      <progress>100%</progress>
      <addedDate>07/04/2025</addedDate>
    </metadata>
    <phase id="1" title="Analyse et conception" completed="true">
      <task title="Analyser les besoins du projet" estimatedTime="1 jour" completed="true">
        <subtask title="Identifier les fonctionnalites essentielles" completed="true" />
        <subtask title="Definir les criteres de succes" completed="true" />
        <subtask title="Documenter les contraintes techniques" completed="true" />
      </task>
      <!-- Autres tâches... -->
    </phase>
    <!-- Autres phases... -->
  </section>
  <!-- Autres sections... -->
</roadmap>
```plaintext
### 1.3 Structure du format HTML

Le format HTML est également hiérarchique mais orienté vers l'affichage. Une représentation HTML de la roadmap pourrait être :

```html
<!DOCTYPE html>
<html>
<head>
  <title>Roadmap personnelle d'amelioration du projet</title>
  <style>
    .section { margin-bottom: 20px; }
    .phase { margin-left: 20px; }
    .task { margin-left: 40px; }
    .subtask { margin-left: 60px; }
    .completed { text-decoration: line-through; }
    .metadata { font-style: italic; color: #666; }

    .note { color: #888; font-style: italic; margin-left: 40px; }

  </style>
</head>
<body>
  <h1>Roadmap personnelle d'amelioration du projet</h1>
  
  <p>Ce document presente une feuille de route organisee par ordre de complexite croissante...</p>
  
  <div class="section">
    <h2>0. Taches prioritaires (Analyse des erreurs et ameliorations critiques)</h2>
    <div class="metadata">
      <p><strong>Complexite</strong>: Elevee</p>
      <p><strong>Temps estime</strong>: 7-10 jours</p>
      <p><strong>Progression</strong>: 100% - <em>Ajoute le 07/04/2025</em></p>
    </div>
    
    <div class="phase completed">
      <h3><input type="checkbox" checked disabled> Phase 1: Analyse et conception</h3>
      
      <div class="task completed">
        <p><input type="checkbox" checked disabled> Analyser les besoins du projet (1 jour)</p>
        
        <div class="subtask completed">
          <p><input type="checkbox" checked disabled> Identifier les fonctionnalites essentielles</p>
        </div>
        <!-- Autres sous-tâches... -->
      </div>
      <!-- Autres tâches... -->
    </div>
    <!-- Autres phases... -->
  </div>
  <!-- Autres sections... -->
</body>
</html>
```plaintext
## 2. Règles de conversion

### 2.1 Conversion de Markdown vers XML

1. **Titres de section** : Convertir en éléments `<section>` avec attributs `id` et `title`
2. **Métadonnées de section** : Convertir en éléments `<metadata>` avec sous-éléments pour chaque type de métadonnée
3. **Phases** : Convertir en éléments `<phase>` avec attributs `id`, `title` et `completed`
4. **Tâches** : Convertir en éléments `<task>` avec attributs `title`, `estimatedTime` et `completed`
5. **Sous-tâches** : Convertir en éléments `<subtask>` avec attributs `title` et `completed`
6. **Notes** : Convertir en éléments `<note>` avec le texte comme contenu
7. **Métadonnées de tâche** : Extraire et convertir en attributs de l'élément `<task>`

### 2.2 Conversion de Markdown vers HTML

1. **Titres de section** : Convertir en éléments `<h2>` dans des `<div class="section">`
2. **Métadonnées de section** : Convertir en paragraphes `<p>` dans des `<div class="metadata">`
3. **Phases** : Convertir en éléments `<h3>` avec cases à cocher dans des `<div class="phase">`
4. **Tâches** : Convertir en paragraphes `<p>` avec cases à cocher dans des `<div class="task">`
5. **Sous-tâches** : Convertir en paragraphes `<p>` avec cases à cocher dans des `<div class="subtask">`
6. **Notes** : Convertir en paragraphes `<p>` dans des `<div class="note">`
7. **Métadonnées de tâche** : Intégrer dans le texte du paragraphe de la tâche

### 2.3 Conversion de XML vers Markdown

1. **Éléments `<section>`** : Convertir en titres de section `## N. Titre`

2. **Éléments `<metadata>`** : Convertir en lignes de métadonnées de section
3. **Éléments `<phase>`** : Convertir en lignes de phase avec cases à cocher
4. **Éléments `<task>`** : Convertir en lignes de tâche avec cases à cocher
5. **Éléments `<subtask>`** : Convertir en lignes de sous-tâche avec cases à cocher
6. **Éléments `<note>`** : Convertir en lignes de note
7. **Attributs de tâche** : Convertir en métadonnées de tâche à la fin de la ligne

### 2.4 Conversion de HTML vers Markdown

1. **Éléments `<div class="section">`** : Extraire le titre et convertir en titres de section
2. **Éléments `<div class="metadata">`** : Extraire les métadonnées et convertir en lignes de métadonnées
3. **Éléments `<div class="phase">`** : Extraire le titre et l'état et convertir en lignes de phase
4. **Éléments `<div class="task">`** : Extraire le titre, l'état et les métadonnées et convertir en lignes de tâche
5. **Éléments `<div class="subtask">`** : Extraire le titre et l'état et convertir en lignes de sous-tâche
6. **Éléments `<div class="note">`** : Extraire le texte et convertir en lignes de note

## 3. Algorithmes de conversion

### 3.1 Algorithme de conversion de Markdown vers XML

1. **Parsing du Markdown** :
   - Utiliser une expression régulière pour identifier les sections, phases, tâches et sous-tâches
   - Extraire les métadonnées et les notes
   - Construire une structure de données hiérarchique

2. **Génération du XML** :
   - Créer un document XML avec un élément racine `<roadmap>`
   - Pour chaque section, créer un élément `<section>` avec les attributs appropriés
   - Pour chaque phase, créer un élément `<phase>` avec les attributs appropriés
   - Pour chaque tâche, créer un élément `<task>` avec les attributs appropriés
   - Pour chaque sous-tâche, créer un élément `<subtask>` avec les attributs appropriés
   - Pour chaque note, créer un élément `<note>` avec le texte comme contenu

### 3.2 Algorithme de conversion de Markdown vers HTML

1. **Parsing du Markdown** :
   - Utiliser une expression régulière pour identifier les sections, phases, tâches et sous-tâches
   - Extraire les métadonnées et les notes
   - Construire une structure de données hiérarchique

2. **Génération du HTML** :
   - Créer un document HTML avec un en-tête et un corps
   - Ajouter des styles CSS pour la mise en forme
   - Pour chaque section, créer un `<div class="section">` avec un titre `<h2>`
   - Pour chaque phase, créer un `<div class="phase">` avec un titre `<h3>` et une case à cocher
   - Pour chaque tâche, créer un `<div class="task">` avec un paragraphe `<p>` et une case à cocher
   - Pour chaque sous-tâche, créer un `<div class="subtask">` avec un paragraphe `<p>` et une case à cocher
   - Pour chaque note, créer un `<div class="note">` avec un paragraphe `<p>`

### 3.3 Algorithme de conversion de XML vers Markdown

1. **Parsing du XML** :
   - Charger le document XML
   - Parcourir les éléments `<section>`, `<phase>`, `<task>`, `<subtask>` et `<note>`
   - Extraire les attributs et le contenu

2. **Génération du Markdown** :
   - Pour chaque élément `<section>`, générer un titre de section
   - Pour chaque élément `<metadata>`, générer des lignes de métadonnées
   - Pour chaque élément `<phase>`, générer une ligne de phase avec une case à cocher
   - Pour chaque élément `<task>`, générer une ligne de tâche avec une case à cocher
   - Pour chaque élément `<subtask>`, générer une ligne de sous-tâche avec une case à cocher
   - Pour chaque élément `<note>`, générer une ligne de note

### 3.4 Algorithme de conversion de HTML vers Markdown

1. **Parsing du HTML** :
   - Charger le document HTML
   - Parcourir les éléments avec les classes "section", "phase", "task", "subtask" et "note"
   - Extraire le texte, l'état des cases à cocher et les métadonnées

2. **Génération du Markdown** :
   - Pour chaque élément avec la classe "section", générer un titre de section
   - Pour chaque élément avec la classe "metadata", générer des lignes de métadonnées
   - Pour chaque élément avec la classe "phase", générer une ligne de phase avec une case à cocher
   - Pour chaque élément avec la classe "task", générer une ligne de tâche avec une case à cocher
   - Pour chaque élément avec la classe "subtask", générer une ligne de sous-tâche avec une case à cocher
   - Pour chaque élément avec la classe "note", générer une ligne de note

## 4. Considérations techniques

### 4.1 Préservation de la structure

- Maintenir la hiérarchie des éléments lors de la conversion
- Préserver l'indentation et les niveaux de profondeur
- Conserver les relations parent-enfant entre les éléments

### 4.2 Gestion des caractères spéciaux

- Échapper les caractères spéciaux dans le Markdown (*, _, #, etc.)

- Encoder correctement les caractères spéciaux en XML et HTML
- Gérer les accents et les caractères non-ASCII

### 4.3 Validation des données

- Vérifier la validité du Markdown avant la conversion
- Valider le XML généré contre un schéma XSD
- Valider le HTML généré contre les standards W3C

### 4.4 Performance

- Optimiser les expressions régulières pour le parsing du Markdown
- Utiliser des techniques de streaming pour les fichiers volumineux
- Minimiser l'utilisation de la mémoire lors des conversions

## 5. Exemples de conversion

### 5.1 Exemple de conversion Markdown vers XML

**Markdown :**
```markdown
## 1. Section de test

**Complexite**: Moyenne
**Temps estime**: 3-5 jours
**Progression**: 50%

- [ ] **Phase 1: Test**
  - [x] Tâche 1 (1 jour) - *Démarrée le 01/01/2025*
    - [x] Sous-tâche 1
    - [ ] Sous-tâche 2
  - [ ] Tâche 2 (2 jours)
  > *Note: Ceci est une note*
```plaintext
**XML :**
```xml
<section id="1" title="Section de test">
  <metadata>
    <complexity>Moyenne</complexity>
    <estimatedTime>3-5 jours</estimatedTime>
    <progress>50%</progress>
  </metadata>
  <phase id="1" title="Test" completed="false">
    <task title="Tâche 1" estimatedTime="1 jour" completed="true" startDate="01/01/2025">
      <subtask title="Sous-tâche 1" completed="true" />
      <subtask title="Sous-tâche 2" completed="false" />
    </task>
    <task title="Tâche 2" estimatedTime="2 jours" completed="false" />
    <note>Ceci est une note</note>
  </phase>
</section>
```plaintext
### 5.2 Exemple de conversion Markdown vers HTML

**Markdown :**
```markdown
## 1. Section de test

**Complexite**: Moyenne
**Temps estime**: 3-5 jours
**Progression**: 50%

- [ ] **Phase 1: Test**
  - [x] Tâche 1 (1 jour) - *Démarrée le 01/01/2025*
    - [x] Sous-tâche 1
    - [ ] Sous-tâche 2
  - [ ] Tâche 2 (2 jours)
  > *Note: Ceci est une note*
```plaintext
**HTML :**
```html
<div class="section">
  <h2>1. Section de test</h2>
  <div class="metadata">
    <p><strong>Complexite</strong>: Moyenne</p>
    <p><strong>Temps estime</strong>: 3-5 jours</p>
    <p><strong>Progression</strong>: 50%</p>
  </div>
  
  <div class="phase">
    <h3><input type="checkbox" disabled> Phase 1: Test</h3>
    
    <div class="task completed">
      <p><input type="checkbox" checked disabled> Tâche 1 (1 jour) - <em>Démarrée le 01/01/2025</em></p>
      
      <div class="subtask completed">
        <p><input type="checkbox" checked disabled> Sous-tâche 1</p>
      </div>
      
      <div class="subtask">
        <p><input type="checkbox" disabled> Sous-tâche 2</p>
      </div>
    </div>
    
    <div class="task">
      <p><input type="checkbox" disabled> Tâche 2 (2 jours)</p>
    </div>
    
    <div class="note">
      <p><em>Note: Ceci est une note</em></p>
    </div>
  </div>
</div>
```plaintext