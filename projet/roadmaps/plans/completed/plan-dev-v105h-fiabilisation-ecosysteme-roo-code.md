# Plan v105h – Fiabilisation de l’écosystème Roo Code

## Objectif

Garantir la robustesse, la traçabilité et l’auto-surveillance de l’écosystème Roo Code (.roo, managers, workflows, registry, prompts, etc.), en éliminant les bugs, les conflits, la redondance et les blocages pour les personas de l'extension VSIX Roo Code. Ce plan remplace les plans précédents en se concentrant sur la simplification, la clarification et l'automatisation.

---

## Sommaire

1.  **Simplification et Centralisation des Règles**
2.  **Amélioration et Intégration des Outils**
3.  **Clarification des Personas et des Workflows**
4.  **Mise en place de la Validation Sémantique**
5.  **Documentation et Formation**
6.  **Checklist de validation finale**

---

## 1. Simplification et Centralisation des Règles

-   **Actions :**
    -   Fusionner les règles redondantes des fichiers `rules-*.md` dans `rules.md`.
    -   Établir un mécanisme de surcharge (`override`) explicite et documenté pour les cas spécifiques.
    -   Supprimer les fichiers de règles devenus obsolètes après la fusion.
-   **Livrables :**
    -   Un fichier `rules.md` centralisé et allégé.
    -   Une documentation claire du mécanisme d'override.
    -   Une structure de règles simplifiée.

---

## 2. Amélioration et Intégration des Outils

-   **Actions :**
    -   Faire de `refs_sync.go` l'unique outil de gestion des références croisées, en supprimant les rapports manuels.
    -   Intégrer la sortie de `refs_sync.go` directement dans la documentation.
    -   Remplacer `auto-roadmap-runner.go` par un script shell (`.sh`) ou un `Makefile` plus simple et standard.
    -   Supprimer les fichiers de log et de rapport redondants (`crossrefs-gap-report.md`, `files-scan-log.md`, etc.).
-   **Livrables :**
    -   Un outil `refs_sync.go` amélioré et autonome.
    -   Un script de build/orchestration simplifié.
    -   Un dossier `.roo/tools` nettoyé.

---

## 3. Clarification des Personas et des Workflows

-   **Actions :**
    -   Définir et documenter clairement les personas de l'extension VSIX (développeur, architecte, testeur, etc.).
    -   Pour chaque persona, décrire les workflows typiques et les points de friction potentiels.
    -   Simplifier les workflows en se basant sur les retours des personas.
-   **Livrables :**
    -   Une documentation des personas et de leurs workflows.
    -   Des workflows simplifiés et documentés.

---

## 4. Mise en place de la Validation Sémantique

-   **Actions :**
    -   Développer un outil de validation sémantique des règles (`rules-validator.go`).
    -   Cet outil vérifiera la cohérence entre les règles, la détection de conflits et le respect des dépendances.
    -   Intégrer cet outil dans le processus de CI/CD pour une validation continue.
-   **Livrables :**
    -   Un outil `rules-validator.go` fonctionnel.
    -   Un processus de CI/CD qui valide sémantiquement les règles à chaque commit.

---

## 5. Documentation et Formation

-   **Actions :**
    -   Créer une documentation "Getting Started" pour les nouveaux contributeurs, expliquant l'écosystème simplifié.
    -   Mettre à jour toute la documentation pour refléter les changements.
-   **Livrables :**
    -   Un guide de démarrage rapide.
    -   Une documentation projet à jour.

---

## 6. Checklist de validation finale

-   [ ] Les règles sont centralisées et simplifiées.
-   [ ] Le mécanisme d'override est clair et documenté.
-   [ ] Les outils sont intégrés, simplifiés et ne sont plus redondants.
-   [ ] Les personas et leurs workflows sont définis et documentés.
-   [ ] La validation sémantique des règles est automatisée.
-   [ ] La documentation est à jour et un guide de démarrage rapide est disponible.

---

## Notes et recommandations

-   Ce plan est conçu pour être itératif. Chaque étape peut être mise en œuvre et validée indépendamment.
-   L'implication des utilisateurs finaux (les personas) est cruciale pour la réussite de ce plan.

---
