# Prompt Ultra-Granularisé v2.0 - Spécification Exécutable Sans Improvisation

## 🔍 ANALYSE DES DIFFICULTÉS PHASE 1 FMOUA

**Basé sur l'analyse de l'implémentation Phase 1 FMOUA - Leçons Apprises**

### ❌ **DIFFICULTÉS IDENTIFIÉES DANS L'IMPLÉMENTATION ORIGINALE**

#### 1. **PROBLÈMES DE GRANULARITÉ INSUFFISANTE**

```yaml
difficultes_detectees:
  manque_precision:
    - "Tâches trop larges (ex: 'Configuration YAML fonctionnelle')"
    - "Absence de sous-étapes atomiques"
    - "Définitions ambigües des critères de validation"
    
  improvisation_excessive:
    - "Tests désactivés manuellement (DISABLED, SKIP)"
    - "Logique de contournement ad-hoc"
    - "Fixes temporaires non documentés"
    
  contexte_incomplet:
    - "Conventions de nommage non spécifiées"
    - "Architecture existante mal analysée"
    - "Dépendances inter-composants non mappées"
```

#### 2. **PROBLÈMES DE VALIDATION ET TESTS**

```yaml
problemes_tests_detectes:
  coverage_issues:
    - "Couverture 93.1% au lieu de 100% visé"
    - "Branches non testées dans config.go (lignes 46-48, 62-69, etc.)"
    - "Logique de fallback non couverte"
    
  test_complexity:
    - "Tests YAML sérialization complexes désactivés"
    - "Mock interfaces problématiques"
    - "Tests d'intégration incomplets"
    
  validation_gaps:
    - "Critères de succès flous"
    - "Rollback procedures non définies"
    - "Edge cases non anticipés"
```

#### 3. **PROBLÈMES D'INTÉGRATION ÉCOSYSTÈME**

```yaml
integration_problems:
  ecosystem_detection:
    - "Structure Go mal analysée initialement"
    - "Conventions de packages non respectées"
    - "Manager Hub integration complexe"
    
  dependency_management:
    - "Dépendances circulaires non anticipées"
    - "Import paths mal calculés"
    - "Version conflicts non gérés"
```

---

## 🎯 **PROMPT ULTRA-GRANULARISÉ V2.0 - SOLUTION OPTIMISÉE**

### **PRÉAMBULE OBLIGATOIRE - DÉTECTION CONTEXTUELLE AUTOMATIQUE**

```yaml
PHASE_PREPARATOIRE_OBLIGATOIRE:
  duree_estimee: "2-3 minutes d'analyse avant toute action"
  
  etape_1_detection_ecosystem:
    actions_atomiques:
      - nom: "Scanner structure de fichiers"
        commande: "find . -name '*.go' -o -name '*.mod' -o -name 'package.json' -o -name '*.py' | head -20"
        validation: "Au moins 3 types de fichiers détectés"
        
      - nom: "Identifier package manager principal"
        commande: "ls go.mod package.json requirements.txt Cargo.toml pom.xml 2>/dev/null | head -1"
        validation: "Un fichier de configuration trouvé"
        
      - nom: "Extraire conventions nommage"
        commande: "find . -name '*.go' -exec basename {} \\; | grep -E '(test|config|main)' | head -10"
        validation: "Patterns de nommage identifiés"

  etape_2_architecture_analysis:
    actions_atomiques:
      - nom: "Mapper structure packages/modules"
        commande: "find . -type d -name 'pkg' -o -name 'src' -o -name 'lib' | head -5"
        validation: "Architecture principale détectée"
        
      - nom: "Identifier patterns d'interface"
        commande: "grep -r 'interface.*{' . --include='*.go' | head -5"
        validation: "Interfaces existantes cataloguées"
        
      - nom: "Détecter points d'intégration"
        commande: "grep -r 'Manager\\|Hub\\|Service\\|Handler' . --include='*.go' | head -10"
        validation: "Points d'ancrage identifiés"

  etape_3_conventions_extraction:
    actions_atomiques:
      - nom: "Analyser historique git"
        commande: "git log --oneline --pretty=format:'%s' | head -10"
        validation: "Style de commits extrait"
        
      - nom: "Identifier patterns tests existants"
        commande: "find . -name '*_test.go' -exec basename {} \\; | head -5"
        validation: "Conventions tests détectées"
        
      - nom: "Extraire structure de documentation"
        commande: "find . -name '*.md' | head -10"
        validation: "Patterns documentation identifiés"
```

### **MODÈLE DE TÂCHE ATOMIQUE NIVEAU 8 - ULTRA-DÉTAILLÉ**

```yaml
TEMPLATE_TACHE_ATOMIQUE_NIVEAU_8:
  structure_obligatoire:
    titre: "[PACKAGE/COMPOSANT] Action précise sur élément spécifique"
    duree_max: "15 minutes par tâche atomique"
    
  contexte_pre_calcule:
    ecosystem_type: 
      detection: "Automatique via scanner préparatoire"
      valeurs_possibles: ["go_modules", "npm_project", "python_pip", "rust_cargo", "java_maven"]
      validation: "Vérifié via existence fichiers config"
      
    architecture_pattern:
      detection: "Analyse structure répertoires"
      valeurs_possibles: ["mvc", "hexagonal", "clean_arch", "microservices", "monolith"]
      validation: "Confirmé via organisation packages"
      
    naming_convention:
      detection: "Extraction patterns fichiers existants"
      exemples: ["snake_case", "camelCase", "PascalCase", "kebab-case"]
      validation: "Cohérence >80% dans codebase"

  entrees_specifications_completes:
    fichiers_input:
      - chemin_absolu: "Calculé automatiquement selon convention détectée"
        format_attendu: "Déterminé par extension + analyse contenu"
        schema_validation: "JSON Schema ou struct Go extraits du code"
        prerequis_existence: "Vérification automatique avant exécution"
        fallback_creation: "Procédure si fichier manquant"
        
    donnees_input:
      - type_structure: "Extrait des définitions existantes dans codebase"
        source_origine: "Fonction/Méthode détectée via grep patterns"
        format_serialization: "JSON/YAML/TOML selon convention projet"
        contraintes_validation: "Rules extraites du code de validation existant"
        valeurs_par_defaut: "Déterminées via analyse config par défaut"

  sorties_specifications_atomiques:
    fichiers_output:
      - chemin_calcule: "Selon arborescence convention + naming pattern"
        format_coherent: "Maintien cohérence avec ecosystem détecté"
        permissions_system: "Selon OS détecté (Windows/Unix)"
        backup_strategy: "Git commit automatique avant modification"
        
    donnees_output:
      - type_retour: "Compatible avec interfaces détectées"
        integration_points: "Hooks identifiés dans architecture"
        validation_schema: "Tests automatiques générés"
        metrics_collection: "Selon système de monitoring détecté"

  methode_execution_step_by_step:
    outils_verification:
      - nom: "Détection toolchain"
        commandes: ["go version", "npm --version", "python --version", "git --version"]
        versions_minimales: "Extraites de go.mod/package.json/requirements.txt"
        fallback_installation: "Scripts d'installation automatique si manquant"
        
    sequence_commandes_atomiques:
      - ordre: 1
        action: "Vérification pré-conditions"
        commande_exacte: "cd [répertoire_détecté] && [build_command_détecté] --dry-run"
        validation_succes: "Exit code 0 + output parsing"
        rollback_echec: "Restauration état git précédent"
        timeout_max: "30 secondes"
        
      - ordre: 2
        action: "Exécution principale"
        commande_exacte: "[action_specifique] [parametres_calcules]"
        validation_succes: "Vérification output + fichiers créés + tests"
        rollback_echec: "Séquence rollback spécifique"
        timeout_max: "120 secondes"
        
      - ordre: 3
        action: "Validation post-execution"
        commande_exacte: "[test_command_détecté] [target_specifique]"
        validation_succes: "Tous tests passent + coverage maintenue"
        rollback_echec: "Reset complet + rapport d'erreur"
        timeout_max: "60 secondes"

  validation_completion_exhaustive:
    criteres_succes_measurables:
      - nom: "Build sans erreurs"
        commande_verification: "[build_command] ./... 2>&1 | grep -i error | wc -l"
        seuil_acceptation: "0 erreurs"
        
      - nom: "Tests conformes"
        commande_verification: "[test_command] -v ./... | grep -E 'PASS|FAIL'"
        seuil_acceptation: "100% PASS, 0% FAIL"
        
      - nom: "Coverage maintenue"
        commande_verification: "[coverage_command] | tail -1 | grep -oE '[0-9]+\\.[0-9]+%'"
        seuil_acceptation: ">= [coverage_target]%"
        
      - nom: "Intégration validée"
        commande_verification: "[integration_test_command] [integration_target]"
        seuil_acceptation: "API compatibility maintained"

    metriques_qualite_automatiques:
      - complexite_cyclomatique: "Selon langage détecté (gocyclo, complexity, etc.)"
      - lines_of_code: "Cloc ou équivalent selon ecosystem"
      - duplication_rate: "Outils de détection duplication appropriés"
      - security_scan: "Gosec, npm audit, bandit selon stack"

  estimation_effort_data_driven:
    duree_min_calculee: "Basée sur LOC à modifier + complexité détectée"
    duree_max_realiste: "Historique project + buffer erreurs"
    complexite_determinee:
      algorithme: "LOC + Dependencies + Test_Coverage + Integration_Points"
      classification: "TRIVIAL|SIMPLE|MODERATE|COMPLEX|CRITICAL"
      
    dependances_mappees:
      directes: "Extraites automatiquement des imports/includes"
      indirectes: "Analyse transitive des dépendances"
      conflits_potentiels: "Détection versions incompatibles"
      ordre_resolution: "Tri topologique des dépendances"
```

### **NIVEAU 8 - GRANULARISATION EXTRÊME POUR ÉVITER L'IMPROVISATION**

```yaml
NIVEAU_8_MICRO_OPERATIONS:
  exemple_concret_config_yaml:
    L8_1_analyser_structure_config_existante:
      - action: "Scanner fichiers *.yaml dans projet"
        commande: "find . -name '*.yaml' -o -name '*.yml' | head -10"
        output_attendu: "Liste fichiers configuration"
        validation: "Au moins 1 fichier trouvé"
        
    L8_2_identifier_schema_configuration:
      - action: "Extraire structure types Go pour config"
        commande: "grep -A 20 'type.*Config struct' pkg/*/types/*.go"
        output_attendu: "Définitions struct configuration"
        validation: "Structures types identifiées"
        
    L8_3_definir_structure_fmoua_config:
      - action: "Créer type FMOUAConfig avec champs obligatoires"
        fichier_cible: "pkg/fmoua/types/config.go"
        contenu_template: |
          type FMOUAConfig struct {
              Performance types.PerformanceConfig `yaml:"performance"`
              AIConfig    types.AIConfig         `yaml:"ai_config"`
              // ... autres champs selon analyse
          }
        validation: "Compilation sans erreur"
        
    L8_4_implementer_validation_config:
      - action: "Ajouter fonction ValidateFMOUAConfig"
        fichier_cible: "pkg/fmoua/core/config.go"
        signature_exacte: "func ValidateFMOUAConfig(config *FMOUAConfig) error"
        logique_validation: "Vérifier champs requis + contraintes métier"
        tests_associes: "TestValidateFMOUAConfig avec cas d'erreur"
        
    L8_5_implementer_chargement_yaml:
      - action: "Fonction LoadFMOUAConfig avec gestion erreurs"
        dependances_requises: ["gopkg.in/yaml.v3", "github.com/spf13/viper"]
        gestion_erreurs: "File not found, parse error, validation error"
        fallback_strategy: "Configuration par défaut si échec"
        
    L8_6_creer_tests_coverage_complet:
      - action: "Tests pour tous les chemins de code"
        fichier_test: "pkg/fmoua/core/config_test.go"
        cas_test_obligatoires:
          - "TestLoadFMOUAConfig_Success"
          - "TestLoadFMOUAConfig_FileNotFound"
          - "TestLoadFMOUAConfig_InvalidYAML"
          - "TestLoadFMOUAConfig_ValidationError"
          - "TestValidateFMOUAConfig_AllScenarios"
        coverage_target: "100% des lignes de code"
```

### **DIRECTIVES ANTI-IMPROVISATION ABSOLUES**

```yaml
INTERDICTIONS_STRICTES:
  zero_improvisation:
    - "❌ INTERDIT: Désactiver tests sans justification documentée"
    - "❌ INTERDIT: Ajouter TODO/FIXME sans issue trackée"
    - "❌ INTERDIT: Modifier sans tests de régression"
    - "❌ INTERDIT: Hardcoder valeurs sans configuration"
    
  validation_obligatoire:
    - "✅ OBLIGATOIRE: Chaque fonction a ses tests unitaires"
    - "✅ OBLIGATOIRE: Chaque modification a rollback procedure"
    - "✅ OBLIGATOIRE: Chaque intégration a validation automatique"
    - "✅ OBLIGATOIRE: Chaque commit passe CI/CD pipeline"
    
  documentation_exigee:
    - "📚 REQUIRED: GoDoc pour toutes les fonctions publiques"
    - "📚 REQUIRED: README.md mis à jour pour nouvelles features"
    - "📚 REQUIRED: CHANGELOG.md pour tous les changements"
    - "📚 REQUIRED: Architecture Decision Records (ADR) pour choix techniques"
```

### **SCRIPTS D'ASSISTANCE CONTEXTUELS AUTOMATIQUES**

```bash
# Génération automatique de scripts d'assistance
#!/bin/bash
# Auto-généré basé sur la détection d'écosystème

ECOSYSTEM_TYPE="[DETECTED_TYPE]"
PROJECT_ROOT="[DETECTED_ROOT]"
PACKAGE_MANAGER="[DETECTED_PM]"

# Script de validation pour l'écosystème détecté
validate_implementation() {
    echo "🔍 Validation pour écosystème: $ECOSYSTEM_TYPE"
    
    case $ECOSYSTEM_TYPE in
        "go_modules")
            go build ./...
            go test -v -race -cover ./...
            go mod tidy
            golangci-lint run
            ;;
        "npm_project")
            npm ci
            npm run build
            npm test
            npm run lint
            ;;
        "python_pip")
            pip install -r requirements.txt
            python -m pytest
            python -m black --check .
            python -m flake8
            ;;
    esac
}

# Script de rollback automatique
rollback_changes() {
    echo "🔄 Rollback automatique..."
    git stash
    git reset --hard HEAD~1
    echo "✅ Rollback effectué"
}

# Script de génération de rapport
generate_implementation_report() {
    echo "📊 Génération rapport d'implémentation..."
    echo "Écosystème: $ECOSYSTEM_TYPE" > implementation_report.md
    echo "Timestamp: $(date)" >> implementation_report.md
    # ... rapport détaillé basé sur métriques collectées
}
```

### **EXEMPLE D'APPLICATION ULTRA-GRANULARISÉE**

Pour appliquer ce prompt sur une sélection de roadmap markdown :

1. **ANALYSER** (2-3 minutes obligatoires)
   - Scanner l'écosystème projet
   - Identifier conventions et patterns
   - Mapper architecture et dépendances

2. **DÉCOMPOSER** la sélection en tâches niveau 8
   - Chaque action = max 15 minutes
   - Validation automatique à chaque étape
   - Rollback procédure définie

3. **EXÉCUTER** avec zéro improvisation
   - Scripts générés automatiquement
   - Métriques collectées en temps réel
   - Validation continue

4. **VALIDER** de manière exhaustive
   - Tous critères mesurables vérifiés
   - Coverage maintenue
   - Intégration confirmée

**RÉSULTAT ATTENDU**: Plan d'exécution où chaque étape de 15 minutes maximum est exécutable sans questionnement, avec validation automatique et rollback procedure.

---

## 📚 MÉTADONNÉES

- **Version**: 2.0.0 (Amélioré basé sur retour Phase 1 FMOUA)
- **Analyse basée sur**: Implémentation Phase 1 FMOUA avec 93.1% coverage
- **Difficultés identifiées**: Tests désactivés, improvisation excessive, granularité insuffisante
- **Améliorations**: Niveau 8 granularité, détection automatique, validation exhaustive
- **Compatibilité**: Tous écosystèmes avec détection automatique
- **Maintenance**: Auto-adaptable + apprentissage des échecs précédents
