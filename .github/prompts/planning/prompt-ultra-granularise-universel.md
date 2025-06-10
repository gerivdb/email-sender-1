# Prompt Ultra-Granularisé - Spécification Exécutable Sans Improvisation

## 📋 CONTEXTE OPÉRATIONNEL

**CIBLE**: Granularisation exécutable niveau 6+ pour tâches atomiques
**PRINCIPE**: Zéro improvisation, zéro interprétation, exécution directe
**FOCUS**: Fenêtre d'éditeur markdown actif de VS Code

## 🎯 DIRECTIVES ABSOLUES D'EXÉCUTION

### 1. **FOCUS EXCLUSIF ÉDITEUR MARKDOWN**
```
ACTION: Remplacer UNIQUEMENT la sélection active dans l'éditeur VS Code
INTERDICTION: 
- ❌ Terminal (ignoré complètement)
- ❌ Autres fichiers non sélectionnés
- ❌ Suggestions générales
VALIDATION: Vérifier que l'action s'applique à l'éditeur principal markdown
```

### 2. **CONTRAINTES DE COHÉRENCE DOCUMENTAIRE**

#### A. **Identification Automatique des Fichiers de Référence**
```yaml
detection_automatique:
  patterns_recherche:
    - "**/README.md"
    - "**/SPECIFICATION*.md"
    - "**/IMPLEMENTATION*.md"
    - "**/ECOSYSTEM*.md"
    - "**/ARCHITECTURE*.md"
    - "**/*_COMPLETE.md"
    - "**/plan-dev-*.md"
    - "**/roadmap*.md"
    
validation_coherence:
  - "Analyser architecture existante avant ajout"
  - "Contrôler nommage selon conventions détectées"
  - "Valider intégration avec écosystème identifié"
  - "Respecter hiérarchie documentée"
```

#### B. **Standards Architecturaux DÉTECTÉS AUTOMATIQUEMENT**
```go
detection_principes:
  solid_indicators: ["interface", "struct", "dependency injection", "single responsibility"]
  kiss_indicators: ["simple", "clear", "readable", "minimal"]
  dry_indicators: ["reusable", "shared", "common", "base"]
  
application_automatique:
  S: "Une fonction = une responsabilité atomique"
  O: "Extension sans modification du core"
  L: "Interfaces compatibles ecosystem"
  I: "Interfaces spécialisées par domaine"
  D: "Injection via hub/manager détecté"
  
simplicity: "Fonctions < 50 lignes, méthodes explicites"
reusability: "Réutiliser composants existants détectés"
```### 3. **SPÉCIFICATION DE GRANULARISATION EXÉCUTABLE**

#### A. **Structure Hiérarchique OBLIGATOIRE**
```markdown
NIVEAU 1: 🏗️ ARCHITECTURE PRINCIPALE (Composant système)
└── NIVEAU 2: 🔧 SOUS-SYSTÈMES SPÉCIALISÉS (Modules fonctionnels)
    └── NIVEAU 3: ⚙️ MÉTHODES ET FONCTIONS (Implémentations)
        └── NIVEAU 4: 📋 TÂCHES ATOMIQUES (Actions concrètes)
            └── NIVEAU 5: 🔍 ÉLÉMENTS GRANULAIRES (Steps d'exécution)
                └── NIVEAU 6: 🎯 INSTRUCTIONS EXÉCUTABLES (Commandes directes)
                    └── NIVEAU 7: 🔬 MICRO-OPÉRATIONS (Actions unitaires)
                        └── NIVEAU 8: ⚡ ÉTAPES ATOMIQUES (Indivisibles)
```

#### B. **Modèle de Tâche Atomique UNIVERSELLE**
```yaml
tache_atomique:
  titre: "[COMPOSANT] Action précise sur élément spécifique"
  
  contexte_detection:
    ecosystem_type: "Détecté automatiquement (ex: managers, services, modules)"
    technology_stack: "Identifié via extensions fichiers et imports"
    architecture_pattern: "Analysé via structure projet"
    naming_convention: "Extrait des fichiers existants"
  
  entrees_requises:
    fichiers_input:
      - chemin: "Chemin relatif détecté/calculé"
        format: "Format déterminé par extension"
        validation: "Vérifier existence et conformité détectée"
    donnees_input:
      - type: "Type/Structure identifiée dans codebase"
        source: "Méthode/Fonction source détectée"
        validation: "Contraintes extraites du code existant"
    
  sorties_produites:
    fichiers_output:
      - chemin: "Chemin calculé selon convention détectée"
        format: "Format cohérent avec ecosystem"
        validation: "Tests appropriés selon stack technology"
    donnees_output:
      - type: "Type cohérent avec architecture existante"
        destination: "Point d'intégration identifié"
        validation: "Schema/Interface compatibility check"    
  prerequis_verification:
    - existence_structure: "Vérifier structure projet attendue"
    - compilation_actuelle: "Build command détecté réussit"
    - tests_existants: "Test command détecté pass"
    - coherence_ecosystem: "Aucun conflit avec composants détectés"
    
  methode_execution:
    outils_requis:
      - "Outils détectés dans projet (package.json, go.mod, etc.)"
      - "IDE/Éditeur configuré pour stack détectée"
      - "Système de contrôle version détecté"
    commandes_exactes:
      - "cd [répertoire_détecté]"
      - "[build_command_détecté]"
      - "[test_command_détecté]"
      - "[validation_command_approprié]"
    scripts_disponibles:
      - nom: "Scripts détectés dans projet"
        parametres: "Paramètres extraits de documentation/usage"
    
  validation_completion:
    criteres_reussite:
      - "Build sans erreurs selon toolchain détectée"
      - "Tests conformes aux standards projet"
      - "Intégration validée avec architecture existante"
      - "Documentation mise à jour selon patterns détectés"
    rollback_echec:
      - "Commandes de rollback appropriées au VCS détecté"
      - "Restauration selon stratégie backup identifiée"
      
  estimation_effort:
    duree_min: "Calculée selon complexité détectée"
    duree_max: "Basée sur patterns similaires dans projet"
    complexite: "ATOMIQUE|COMPOSEE|COMPLEXE (déterminée automatiquement)"
    dependances: "Extraites de l'analyse de dépendances"
```

### 4. **DÉTECTION AUTOMATIQUE CONVENTIONS ET ÉVITEMENT REDONDANCE**

#### A. **Extraction Automatique Conventions**
```bash
# Détection automatique des patterns
detection_commands:
  - "find . -name '*.go' -o -name '*.js' -o -name '*.py' -o -name '*.java' | head -20"
  - "grep -r 'interface.*{' . | head -10"
  - "find . -name 'package.json' -o -name 'go.mod' -o -name 'requirements.txt'"
  - "git log --oneline | head -20"

extraction_patterns:
  - "Analyser nommage fichiers existants pour conventions"
  - "Extraire patterns interface/classe/structure"
  - "Identifier architecture (MVC, microservices, monolith)"
  - "Détecter standards équipe via commits/code"
```#### B. **Vérification Anti-Redondance UNIVERSELLE**
```bash
verification_universelle:
  - "find . -name '*[nouveau_composant]*' -type f"
  - "grep -r '[nouveau_nom]' . --include='*.[extension_détectée]'"
  - "git log --grep='[nouveau_composant]' --oneline"
  
validation_rules:
  - "Aucun doublon détecté dans arborescence"
  - "Aucune collision namespace/module"
  - "Respect conventions nommage extraites"
  - "Cohérence avec architecture identifiée"
```

### 5. **INTÉGRATION ÉCOSYSTÈME DÉTECTÉE AUTOMATIQUEMENT**

#### A. **Mapping Automatique Dépendances**
```yaml
detection_dependances:
  package_managers:
    - package.json: "npm/yarn ecosystem"
    - go.mod: "Go modules ecosystem"
    - requirements.txt: "Python ecosystem"
    - Cargo.toml: "Rust ecosystem"
    - pom.xml: "Maven ecosystem"
    
  architecture_detection:
    managers_pattern: "*/managers/*" 
    services_pattern: "*/services/*"
    components_pattern: "*/components/*"
    modules_pattern: "*/modules/*"
    
integration_points:
  - "Interfaces détectées dans codebase"
  - "Patterns d'injection de dépendances identifiés"
  - "Points d'extension existants"
  - "Hubs/Coordinateurs centraux"
```

### 6. **OUTILS ET SCRIPTS DÉTECTION AUTOMATIQUE**

#### A. **Scripts Disponibles Détectés**
```yaml
detection_scripts:
  npm_scripts: "package.json scripts section"
  make_targets: "Makefile targets"
  shell_scripts: "*.sh files in project"
  powershell_scripts: "*.ps1 files in project"
  custom_tools: "tools/, scripts/, bin/ directories"
  
utilisation_automatique:
  - "Intégrer dans pipeline de tâches"
  - "Respecter conventions d'usage détectées"
  - "Maintenir compatibilité avec toolchain"
```### 7. **VALIDATION ET MÉTRIQUES UNIVERSELLES**

#### A. **Critères Validation ADAPTÉS AU PROJET**
```yaml
validation_adaptative:
  build_system:
    go: "go build -v ./..."
    node: "npm run build"
    python: "python -m build"
    rust: "cargo build"
    java: "mvn compile"
    
  test_system:
    go: "go test -v -race -cover ./..."
    node: "npm test"
    python: "pytest"
    rust: "cargo test"
    java: "mvn test"
    
  quality_checks:
    - "Linting selon outils projet (eslint, golangci-lint, etc.)"
    - "Coverage selon standards projet"
    - "Performance selon benchmarks existants"
```

#### B. **Métriques Contextuelles**
```yaml
metriques_adaptees:
  complexity_metrics:
    - "Métrique appropriée au langage détecté"
    - "Standards équipe extraits du code"
    - "Benchmarks historiques du projet"
    
  integration_metrics:
    - "Compatibilité avec architecture détectée"
    - "Respect patterns existants"
    - "Non-régression fonctionnalités"
```

## 🎯 ACTION DEMANDÉE

**INSTRUCTION EXÉCUTABLE UNIVERSELLE**:
```
1. ANALYSER le contexte de l'éditeur actif :
   - Détecter le type d'écosystème/projet
   - Identifier les conventions et patterns
   - Extraire l'architecture et les dépendances
   
2. APPLIQUER la granularisation ultra-détaillée :
   - Atteindre NIVEAU 8 de granularité avec tâches atomiques
   - Spécifier entrées/sorties complètes pour chaque tâche
   - Intégrer avec écosystème détecté automatiquement
   - Générer outils d'assistance contextuels
   
3. PRODUIRE un plan d'exécution où :
   - Chaque tâche est exécutable sans questionnement
   - Aucune zone d'improvisation n'existe
   - Toutes les dépendances sont explicites
   - La validation est automatisable

RÉSULTAT ATTENDU: Plan d'exécution ultra-granularisé adapté 
automatiquement à l'écosystème détecté, avec zéro ambiguïté.
```### 📋 TEMPLATE D'APPLICATION

Pour utiliser ce prompt sur n'importe quelle sélection :

1. **Sélectionner** le contenu dans l'éditeur markdown VS Code
2. **Appliquer** ce prompt
3. **Laisser** la détection automatique analyser le contexte
4. **Obtenir** une granularisation adaptée à l'écosystème spécifique

**Format de sortie** : Markdown structuré avec hiérarchie ultra-détaillée, checkboxes, métriques, et instructions exécutables spécifiques au contexte détecté.

---

## 🔧 EXEMPLES D'USAGE CONTEXTUELS

### Pour Écosystème Go
```yaml
detection_automatique:
  - go.mod présent
  - Structure packages Go
  - Interfaces Go patterns
  - Tests *_test.go

application_specifique:
  - Conventions nommage Go (PascalCase public, camelCase private)
  - Patterns interface satisfaction
  - Gestion erreurs Go idiomatique
  - Tests unitaires et benchmarks
```

### Pour Écosystème Node.js
```yaml
detection_automatique:
  - package.json présent
  - Structure modules npm
  - CommonJS/ES modules
  - Tests jest/mocha

application_specifique:
  - Conventions nommage npm (kebab-case packages)
  - Patterns async/await
  - Gestion erreurs Promise-based
  - Tests unitaires et intégration
```

### Pour Écosystème Python
```yaml
detection_automatique:
  - requirements.txt ou pyproject.toml
  - Structure packages Python
  - Imports Python patterns
  - Tests pytest

application_specifique:
  - PEP 8 naming conventions
  - Type hints et annotations
  - Gestion exceptions Python
  - Tests unitaires et doctests
```

## 📚 MÉTADONNÉES DOCUMENT

- **Version**: 1.0.0
- **Date création**: 2025-01-13
- **Auteur**: Framework de Planification FMOUA
- **Usage**: Prompt universel pour granularisation ultra-détaillée
- **Compatibilité**: Tous écosystèmes de développement
- **Maintenance**: Auto-adaptable selon détection contexte