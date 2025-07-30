# Règles de sécurité documentaire Roo-Code

Ce fichier est subordonné à [.roo/rules/rules.md](rules.md).  
Il détaille les principes, conventions et bonnes pratiques pour la sécurité documentaire et applicative dans le projet Roo-Code.

---

## 1. Principes généraux

- Centraliser la gestion des accès, secrets et audits via SecurityManager.
- Chiffrer systématiquement les données sensibles (voir SecurityManager, StorageManager).
- Documenter les politiques d’accès et de gestion des secrets.
- Mettre en place des audits réguliers et des scans de vulnérabilité.

---

## 2. Gestion des accès

- Définir des rôles et permissions clairs pour chaque manager/agent.
- Utiliser des clés API ou tokens pour les accès externes.
- Valider systématiquement les clés et permissions avant toute opération critique.

---

## 3. Gestion des secrets

- Centraliser les secrets dans un coffre sécurisé (SecurityManager).
- Ne jamais stocker de secrets en clair dans le code ou la documentation.
- Documenter la procédure de rotation et de révocation des secrets.

---

## 4. Audit et détection de vulnérabilités

- Intégrer des outils d’audit et de scan dans les workflows de maintenance.
- Documenter les incidents et les réponses dans `.github/docs/incidents/`.
- Mettre à jour la documentation à chaque évolution des politiques de sécurité.

---

## 5. Overrides et modes spécifiques

- Si un mode Roo-Code nécessite des règles de sécurité particulières (ex : mode maintenance, mode debug), ajouter une section dédiée et référencer le prompt système concerné.
- Les prompts système doivent indiquer explicitement les adaptations ou exceptions à ces règles.

---

## 6. Maintenance

- Mettre à jour ce fichier à chaque évolution des pratiques ou des outils de sécurité.
- Documenter les nouveaux outils ou politiques dans la documentation centrale.

---