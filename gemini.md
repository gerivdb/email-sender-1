# Personnalisation des interactions Gemini CLI

Ce fichier permet de définir des instructions, règles et exemples pour customiser vos interactions avec Gemini via gemini-cli.

---

## 🎯 Objectif

Définir des guidelines et prompts personnalisés pour guider Gemini selon vos besoins métier ou contextuels.

---

## 📝 Règles d’interaction

- Toujours répondre en français.
- Privilégier la concision et la clarté.
- Respecter la structure de réponse attendue (ex : tableau, liste, code).
- Adapter le ton selon le contexte (formel/informatif ou créatif selon la demande).
- Si une consigne spécifique est donnée dans le prompt, la suivre strictement.

---

## 💡 Exemples de prompts personnalisés

- « Résume ce document en 5 points clés. »
- « Génère un plan d’action pour ce projet. »
- « Donne-moi un exemple de code Python pour cette tâche. »
- « Traduis ce texte en anglais, puis explique le vocabulaire technique. »

---

## ⚙️ Conseils d’utilisation

- Ajoutez ici vos propres instructions ou scénarios récurrents.
- Modifiez ce fichier pour adapter Gemini à vos usages spécifiques.
- Utilisez des sections thématiques pour organiser vos prompts.

---

## 🧠 Contexte du projet

Ce projet possède une documentation et une configuration très riches dans le répertoire `.github`. Avant de répondre à une question ou d'effectuer une tâche, je dois systématiquement consulter ces sources pour m'aligner sur les conventions, l'architecture et les processus établis.

- **Documentation principale :** `.github/docs/` (contient l'architecture, les guides, les standards de codage, la documentation des managers, etc.)
- **Workflows CI/CD :** `.github/workflows/` (définit les pipelines d'intégration, de test et de déploiement)
- **Instructions & Prompts :** `.github/instructions/` et `.github/prompts/` (contiennent des directives spécifiques sur la manière d'interagir et d'exécuter des tâches)
- **Scripts utiles :** `.github/scripts/` (fournit des outils d'automatisation pour le projet)

---

## 🔧 Section personnalisable

Ajoutez ci-dessous vos règles, prompts ou instructions spécifiques :

- Après chaque action importante (modification de fichier, exécution de commande critique), je dois documenter l'action en utilisant le script `log-action.ps1 'Votre message de log ici'`.