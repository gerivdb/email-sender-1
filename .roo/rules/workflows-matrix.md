# Workflows Principaux de l'Extension Roo Code

Ce document présente les workflows principaux de l'extension Roo Code, en se concentrant sur les besoins des [personas](./personas.md).

---

## 1. Workflow de Développement (pour le Développeur)

Ce workflow décrit comment un développeur utilise l'extension pour intégrer les standards du projet.

```mermaid
graph TD
    A[Ouvrir un fichier] --> B{L'extension analyse le code};
    B --> C[Le code est conforme];
    B --> D[Le code n'est pas conforme];
    D --> E{L'extension propose des corrections};
    E --> F[Appliquer les corrections];
    F --> C;
```

**Points de friction potentiels :**

*   Les suggestions de correction ne sont pas claires.
*   L'analyse est trop lente.

---

## 2. Workflow de Contribution (pour le Contributeur)

Ce workflow décrit comment un contributeur modifie ou ajoute une règle.

```mermaid
graph TD
    A[Modifier un fichier de règles] --> B{Lancer le script de validation};
    B --> C[Validation réussie];
    B --> D[Validation échouée];
    D --> E{Corriger les erreurs};
    E --> B;
    C --> F[Soumettre la modification];
```

**Points de friction potentiels :**

*   Le script de validation est complexe à utiliser.
*   Les erreurs de validation sont difficiles à comprendre.

---

## 3. Workflow d'Architecture (pour l'Architecte)

Ce workflow décrit comment un architecte supervise et fait évoluer l'écosystème.

```mermaid
graph TD
    A[Consulter le dashboard de l'écosystème] --> B{Identifier une anomalie ou une amélioration};
    B --> C[Créer une nouvelle règle ou modifier une règle existante];
    C --> D{Valider l'impact de la modification};
    D --> E[Déployer la modification];
```

**Points de friction potentiels :**

*   Le dashboard n'est pas fiable ou est incomplet.
*   Il est difficile d'évaluer l'impact d'une modification sur l'ensemble de l'écosystème.