# Mode ARCHI

## Description

Le mode ARCHI (Architecture) est un mode opérationnel dédié à la conception, la documentation et la validation de l’architecture du système, pour garantir qualité, maintenabilité et évolutivité.

## Objectifs

- Concevoir l’architecture logicielle, système, données et intégration.
- Documenter et modéliser l’architecture.
- Analyser les dépendances et détecter les points critiques.
- Valider l’architecture selon des règles définies.

## Commandes principales

- archi analyze : Analyse l’architecture existante.
- archi diagram : Génère un diagramme d’architecture.
- archi validate : Valide l’architecture selon des règles spécifiques.

## Fonctionnement

- Analyse le code source et la configuration pour extraire la structure du système.
- Génère des diagrammes et rapports d’architecture.
- Valide la conformité de l’architecture aux standards et règles du projet.
- Propose des améliorations ou des refontes si nécessaire.

## Bonnes pratiques

- Toujours documenter les choix d’architecture.
- Mettre à jour la documentation à chaque évolution majeure.
- Utiliser des outils de modélisation adaptés.
- Vérifier la cohérence entre architecture prévue et implémentée.

## Intégration avec les autres modes

Le mode ARCHI s’intègre naturellement avec :
- **DEV-R** : Pour concevoir l’architecture avant le développement ([voir mode_dev_r.md](mode_dev_r.md))
- **REVIEW** : Pour valider l’architecture implémentée ([voir mode_review.md](mode_review.md))
- **C-BREAK** : Pour détecter et résoudre les dépendances circulaires ([voir mode_c-break.md](mode_c-break.md))

Exemple de workflow typique : ARCHI → DEV-R → REVIEW → C-BREAK

## Exemples d’utilisation

```powershell
# Analyser l’architecture existante

archi analyze -SourcePath "src" -OutputPath "projet/architecture"

# Générer un diagramme d’architecture

archi diagram -SourcePath "src" -OutputPath "projet/architecture"

# Valider l’architecture

archi validate -SourcePath "src" -RulesPath "projet/config/architecture-rules.json"
```plaintext
## Snippet VS Code (optionnel)

```json
{
  "Mode ARCHI": {
    "prefix": "archi",
    "body": [
      "# Mode ARCHI",

      "",
      "## Description",

      "Le mode ARCHI (Architecture) est un mode opérationnel dédié à la conception, la documentation et la validation de l’architecture du système.",
      "",
      "## Fonctionnement",

      "- Analyse l’architecture existante",
      "- Génère des diagrammes",
      "- Valide la conformité aux règles du projet"
    ],
    "description": "Insère le template du mode ARCHI pour la gestion d’architecture."
  }
}
```plaintext