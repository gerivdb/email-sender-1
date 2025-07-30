# Règles de documentation Roo-Code

Ce fichier est subordonné à [.roo/rules/rules.md](rules.md).  
Il détaille les bonnes pratiques, modèles et conventions spécifiques à la rédaction documentaire du projet Roo-Code.

---

## 1. Principes généraux

- Respecter la structure logique : titres, sous-titres, sommaire, navigation claire.
- Privilégier la concision, la clarté et l’accessibilité.
- Utiliser le Markdown comme format principal.
- Centraliser les modèles dans `.github/docs/templates/` si possible.

---

## 2. Modèles recommandés

- **README.md** :  
  - Présentation du projet, objectifs, installation, usage, contribution, licence.
- **API Documentation** :  
  - Structure par endpoints, paramètres, exemples de requêtes/réponses, codes d’erreur.
- **Guides utilisateur** :  
  - Étapes séquentielles, captures d’écran, FAQ, glossaire.

---

## 3. Conventions de style

- Utiliser des listes à puces pour les étapes ou options.
- Mettre en avant les sections importantes avec des encadrés ou des emojis.
- Ajouter des liens cliquables vers la documentation centrale ou les fichiers de référence.
- Documenter systématiquement les cas limites et scénarios d’erreur.

---

## 4. Overrides et modes spécifiques

- Si un mode Roo-Code nécessite une documentation particulière (ex : mode debug, mode code), ajouter une section dédiée et référencer le prompt système concerné.
- Les prompts système doivent indiquer explicitement les adaptations ou exceptions à ces règles.

---

## 5. Maintenance

- Mettre à jour ce fichier à chaque évolution des standards ou des besoins documentaires.
- Ajouter les nouveaux modèles ou guides dans `.github/docs/templates/` et référencer ici.

---