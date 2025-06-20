# PROMPT ULTRA-GRANULARISÉ v2.0

**ACTION**: Remplacer la SÉLECTION ACTIVE de l'éditeur markdown VS Code par une granularisation niveau 8+

## INSTRUCTIONS DIRECTES

1. **LIS** la sélection active dans l'éditeur markdown
2. **DÉTECTE** automatiquement l'écosystème (Go/Node.js/Python/autre)
3. **APPLIQUE** la granularisation 8 niveaux ci-dessous
4. **REMPLACE** directement la sélection par le résultat

## STRUCTURE À APPLIQUER

Pour chaque tâche de la sélection, produis :

```markdown
### 🎯 [TITRE_TÂCHE_GRANULARISÉE]

**ÉCOSYSTÈME DÉTECTÉ**: [Go/Node.js/Python/autre]

**FICHIER CIBLE**: [chemin/fichier détecté]

**CONVENTIONS**: [PascalCase/camelCase/snake_case détectées]

#### 🏗️ NIVEAU 1: [ARCHITECTURE_PRINCIPALE]

- **Contexte**: [Architecture existante détectée]
- **Intégration**: [Points d'intégration identifiés]

##### 🔧 NIVEAU 2: [MODULE_FONCTIONNEL]

- **Responsabilité**: [Une responsabilité unique]
- **Interface**: [Interface à créer/utiliser]

###### ⚙️ NIVEAU 3: [COMPOSANT_TECHNIQUE]

- **Type**: [Struct/Class/Interface selon écosystème]
- **Localisation**: [fichier.ext:ligne_précise]

####### 📋 NIVEAU 4: [INTERFACE_CONTRAT]

```[langage_détecté]
// Code exact de l'interface selon conventions détectées
[signature_exacte_avec_types_et_méthodes]
```

######## 🛠️ NIVEAU 5: [MÉTHODE_FONCTION]

```[langage_détecté]
// Implémentation exacte selon patterns du projet
[code_complet_avec_gestion_erreurs]
```

######### 🎯 NIVEAU 6: [IMPLÉMENTATION_ATOMIQUE]

- **Action**: [Action précise indivisible]
- **Durée**: [5-15 min]
- **Commandes**:

  ```bash
  cd [chemin_détecté]
  [commande_build_spécifique_écosystème]
  [commande_test_spécifique]
  ```

########## 🔬 NIVEAU 7: [ÉTAPE_EXÉCUTION]

1. **Pré**: `[commande_validation]` → `[résultat_attendu]`
2. **Exec**: `[commande_implémentation]` → `[paramètres_exacts]`
3. **Post**: `[commande_vérification]` → `[critère_succès]`

########### ⚡ NIVEAU 8: [ACTION_INDIVISIBLE]

- **Instruction**: [Commande atomique non décomposable]
- **Validation**: `[test_automatique_spécifique]`
- **Rollback**: `[commande_restauration_exacte]`

### 📊 VALIDATION

- [ ] **Build**: `[commande_détectée]` → Success  
- [ ] **Tests**: `[commande_détectée]` → Pass
- [ ] **Lint**: `[commande_détectée]` → Clean

**Rollback**: `[commande_vcs_selon_écosystème]`

```markdown
<!-- Fin du template à appliquer -->
```

## CONSIGNES D'APPLICATION

1. **LIRE** la sélection active
2. **DÉTECTER** l'écosystème
3. **ANALYSER** l'architecture
4. **APPLIQUER** ce template
5. **REMPLACER** la sélection

Remplace chaque [placeholder] par des valeurs concrètes détectées.
