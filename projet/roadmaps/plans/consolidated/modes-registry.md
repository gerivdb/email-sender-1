# Registre centralisé des modes actifs

Ce fichier recense la structure des modes d’exécution et de configuration utilisés dans l’écosystème Roo Code et Kilo Code.

---

## 1. Modes standards Roo Code

| Nom           | Type     | Source      | Persona cible      | Objectif principal         | Complémentarités / Exclusivités | État d’activation |
|---------------|----------|-------------|--------------------|---------------------------|-------------------------------|-------------------|
| Architect     | Standard | Natif       | Architecte         | Planification technique   | Complémentarité Code/Ask      | Actif             |
| Code          | Standard | Natif       | Développeur        | Implémentation            | Exclusivité Debug             | Actif             |
| Ask           | Standard | Natif       | Utilisateur        | Recherche/Documentation   | Complémentarité Architect     | Actif             |
| Debug         | Standard | Natif       | Développeur        | Débogage                  | Exclusivité Code              | Actif             |
| Orchestrator  | Standard | Natif       | Chef de projet     | Coordination multi-tâches | Complémentarité Architect     | Actif             |

---

## 2. Modes custom Roo Code

| Nom                   | Type    | Source       | Persona cible         | Objectif principal           | Complémentarités / Exclusivités | État d’activation |
|-----------------------|---------|--------------|----------------------|------------------------------|-------------------------------|-------------------|
| Project Research      | Custom  | Marketplace  | Analyste             | Recherche projet             | Complémentarité Architect      | Inactif           |
| Documentation Writer  | Custom  | Marketplace  | Rédacteur technique  | Rédaction documentation      | Complémentarité Ask            | Inactif           |
| Mode Writer           | Custom  | Marketplace  | Développeur avancé   | Création de modes personnalisés | Exclusivité Code              | Inactif           |

---

## 3. Modes Kilo Code

> Aucun mode custom Kilo Code n’est défini pour l’instant.

| Nom      | Type     | Source | Persona cible | Objectif principal | Complémentarités / Exclusivités | État d’activation |
|----------|----------|--------|--------------|--------------------|-------------------------------|-------------------|
| KiloCode | Standard | Natif  | Utilisateur  | Exécution KiloCode | Exclusivité Roo Code           | Synchronisé       |
