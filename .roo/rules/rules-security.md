# Règles de sécurité documentaire Roo-Code

Ce fichier est subordonné à [.roo/rules/rules.md](rules.md).  
Il détaille les principes, conventions et bonnes pratiques pour la sécurité documentaire et applicative dans le projet Roo-Code.

---

## 1. Gestion des accès

- Définir des rôles et permissions clairs pour chaque manager/agent.
- Utiliser des clés API ou tokens pour les accès externes.
- Valider systématiquement les clés et permissions avant toute opération critique.

---

## 2. Gestion des secrets

- Centraliser les secrets dans un coffre sécurisé (SecurityManager).
- Ne jamais stocker de secrets en clair dans le code ou la documentation.
- Documenter la procédure de rotation et de révocation des secrets.

---

## 3. Audit et détection de vulnérabilités

- Intégrer des outils d’audit et de scan dans les workflows de maintenance.
- Documenter les incidents et les réponses dans `.github/docs/incidents/`.
- Mettre à jour la documentation à chaque évolution des politiques de sécurité.

---