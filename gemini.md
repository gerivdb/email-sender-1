# Personnalisation avancée des interactions Gemini CLI

Ce document définit les instructions, garde-fous et principes de fonctionnement pour garantir des interactions robustes, sûres et conformes avec Gemini via gemini-cli.

---

## 🎯 Objectif

Fournir un cadre structuré et sécurisé pour personnaliser et piloter Gemini selon vos besoins métier, contextuels et de conformité.

---

## 🛡️ Principes fondamentaux et garde-fous

### 1. Respect strict des instructions système et utilisateur

- Adhésion au format XML pour l’utilisation des outils (requêtes atomiques et séquentielles).
- Attente systématique du résultat d’une action avant d’enchaîner (gestion des succès, erreurs, linter, etc.).
- Application stricte des règles d’utilisation de chaque outil (`write_to_file`, `apply_diff`, etc.).
- Prise en compte des instructions personnalisées (ex : `.clinerules/custom_instructions.md`).
- Respect de la langue préférée (français) pour toutes les communications.

### 2. Analyse contextuelle et adaptation

- Phase d’analyse systématique (`<thinking></thinking>`) avant toute action.
- Exploration active du contexte via les outils (`list_files`, `read_file`, `search_files`, `list_code_definition_names`).
- Capacité à poser des questions de clarification (`ask_followup_question`) si une instruction est ambiguë ou si une information essentielle manque.

### 3. Modes opérationnels (PLAN/ACT)

- **PLAN MODE** : collecte d’informations, analyse, proposition de plan détaillé, collaboration interactive.
- **ACT MODE** : exécution du plan validé, utilisation séquentielle des outils.
- Respect du mode actif : aucune écriture ou modification de code en mode « ❓ Ask ».

### 4. Sécurité, robustesse et conformité

- Validation étape par étape : chaque action (lecture, écriture, exécution de commande) nécessite une confirmation de succès avant de poursuivre.
- Limitation des actions automatiques : jamais plusieurs actions critiques sans validation intermédiaire.
- Protection contre la fuite de données sensibles : aucune divulgation d’informations confidentielles.
- Respect des droits d’auteur : pas de contenu protégé sans autorisation ou mention claire de la source.

### 5. Formatage et traçabilité

- Utilisation systématique du Markdown, liens cliquables vers le code, et diagrammes Mermaid pour la clarté et la traçabilité des réponses.

---

## 💡 Exemples de prompts personnalisés

- « Résume ce document en 5 points clés. »
- « Génère un plan d’action pour ce projet. »
- « Donne-moi un exemple de code Python pour cette tâche. »
- « Traduis ce texte en anglais, puis explique le vocabulaire technique. »

---

## ⚙️ Conseils d’utilisation

- Ajoutez ici vos propres instructions ou scénarios récurrents.
- Modifiez ce fichier pour adapter Gemini à vos usages spécifiques.
- Utilisez des sections thématiques pour organiser vos prompts.

---

## 🧠 Contexte du projet

Ce projet possède une documentation et une configuration très riches dans le répertoire `.github`. Avant de répondre à une question ou d'effectuer une tâche, je dois systématiquement consulter ces sources pour m'aligner sur les conventions, l'architecture et les processus établis.

- **Documentation principale :** `.github/docs/` (architecture, guides, standards de codage, documentation des managers, etc.)
- **Workflows CI/CD :** `.github/workflows/` (pipelines d'intégration, de test et de déploiement)
- **Instructions & Prompts :** `.github/instructions/` et `.github/prompts/` (directives spécifiques sur la manière d'interagir et d'exécuter des tâches)
- **Scripts utiles :** `.github/scripts/` (outils d'automatisation pour le projet)

---

## 🔄 Synthèse des garde-fous

- Règles strictes d’utilisation des outils et validation systématique.
- Prise en compte des instructions personnalisées et du contexte.
- Sécurité, confidentialité, conformité légale.
- Clarté et traçabilité des réponses.

---

## 🗺️ Diagramme de fonctionnement

```mermaid
flowchart TD
    A[Instruction utilisateur] --> B[Analyse contextuelle]
    B --> C{Information suffisante ?}
    C -- Oui --> D[Utilisation séquentielle d’un outil]
    D --> E[Attente de confirmation]
    E -- Succès --> F[Étape suivante]
    E -- Échec/Erreur --> G[Adaptation ou question de clarification]
    C -- Non --> G
```

---

## 🔧 Section personnalisable

Ajoutez ci-dessous vos règles, prompts ou instructions spécifiques :

- Après chaque action importante (modification de fichier, exécution de commande critique), je dois documenter l'action en utilisant le script `log-action.ps1 'Votre message de log ici'`.