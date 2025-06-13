# Mode TEST

## Description

Le mode TEST est un mode opérationnel dédié à la création, l’exécution et la validation des tests pour garantir la qualité, la robustesse et la conformité du code.

## Objectifs

- Garantir le bon fonctionnement du code et la conformité aux exigences.
- Automatiser la création et l’exécution des tests unitaires, d’intégration et de performance.
- Analyser la couverture de code et générer des rapports de test.

## Commandes principales

- test generate : Génère les tests pour un script ou une fonctionnalité.
- test run : Exécute tous les tests associés à un composant ou une tâche.
- test coverage : Analyse la couverture de code.

## Fonctionnement

- Génère automatiquement les tests à partir du code ou de la roadmap.
- Exécute les tests et collecte les résultats.
- Analyse la couverture et détecte les régressions.
- Génère des rapports détaillés pour chaque exécution.

## Bonnes pratiques

- Écrire des tests pour chaque fonctionnalité nouvelle ou modifiée.
- Automatiser l’exécution des tests à chaque commit ou livraison.
- Analyser les rapports pour corriger rapidement les erreurs.
- Maintenir une couverture de code élevée et pertinente.

## Intégration avec les autres modes

Le mode TEST s’intègre naturellement avec :
- **DEV-R** : Pour tester les fonctionnalités implémentées ([voir mode_dev_r.md](mode_dev_r.md))
- **DEBUG** : Pour identifier et corriger les problèmes détectés par les tests ([voir mode_debug.md](mode_debug.md))
- **CHECK** : Pour vérifier que tous les tests passent avant de valider une tâche ([voir mode_check_enhanced.md](mode_check_enhanced.md))

Exemple de workflow typique : DEV-R → TEST → DEBUG → CHECK

## Exemples d’utilisation

```powershell
# Générer et exécuter les tests pour un script

Invoke-AugmentMode -Mode "TEST" -FilePath "projet/roadmap.md" -TaskIdentifier "1.2.3" -GenerateTests -RunTests

# Analyser la couverture de code

Invoke-AugmentMode -Mode "TEST" -FilePath "projet/roadmap.md" -AnalyzeCoverage
```plaintext
## Snippet VS Code (optionnel)

```json
{
  "Mode TEST": {
    "prefix": "testmode",
    "body": [
      "# Mode TEST",

      "",
      "## Description",

      "Le mode TEST est un mode opérationnel dédié à la création, l’exécution et la validation des tests.",
      "",
      "## Fonctionnement",

      "- Génère et exécute les tests automatiquement",
      "- Analyse la couverture de code",
      "- Génère des rapports de test"
    ],
    "description": "Insère le template du mode TEST pour la gestion des tests."
  }
}{
  "Mode TEST": {
    "prefix": "testmode",
    "body": [
      "# Mode TEST",

      "",
      "## Description",

      "Le mode TEST est un mode opérationnel dédié à la création, l’exécution et la validation des tests.",
      "",
      "## Fonctionnement",

      "- Génère et exécute les tests automatiquement",
      "- Analyse la couverture de code",
      "- Génère des rapports de test"
    ],
    "description": "Insère le template du mode TEST pour la gestion des tests."
  }
}
```plaintext