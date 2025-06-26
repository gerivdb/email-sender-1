# Gemini CLI – Documentation des commandes

Gemini CLI est un outil en ligne de commande qui permet d’interagir avec l’IA Gemini de Google directement depuis votre terminal. Cette documentation recense les commandes principales et leur usage, basée sur la documentation officielle.

---

## Commandes Slash (`/`)

- `/bug` : Signaler un bug concernant Gemini CLI.
- `/chat save <tag>` : Sauvegarder l’historique de conversation sous un tag.
- `/chat resume <tag>` : Reprendre une conversation sauvegardée.
- `/chat list` : Lister les tags de conversation sauvegardés.
- `/clear` : Effacer l’écran du terminal (Ctrl+L).
- `/compress` : Remplacer le contexte du chat par un résumé.
- `/editor` : Ouvrir un dialogue pour choisir un éditeur supporté.
- `/help` ou `/?` : Afficher l’aide générale.
- `/mcp` : Lister les serveurs MCP configurés et leurs outils.
  - `/mcp desc` : Afficher les descriptions détaillées des serveurs/outils MCP.
  - `/mcp nodesc` : Masquer les descriptions, n’afficher que les noms.
  - `/mcp schema` : Afficher le schéma JSON complet des paramètres d’outils.
- `/memory add <texte>` : Ajouter du contexte mémoire à l’IA.
- `/memory show` : Afficher le contexte mémoire chargé.
- `/memory refresh` : Recharger la mémoire à partir des fichiers GEMINI.md.
- `/restore [tool_call_id]` : Restaurer les fichiers du projet à l’état précédent un outil.
- `/stats` : Afficher les statistiques de session (tokens, durée, etc.).
- `/theme` : Changer le thème visuel de Gemini CLI.
- `/auth` : Changer la méthode d’authentification.
- `/about` : Afficher les infos de version.
- `/tools` : Lister les outils disponibles dans Gemini CLI.
  - `/tools desc` : Afficher les descriptions détaillées des outils.
  - `/tools nodesc` : Masquer les descriptions, n’afficher que les noms.
- `/quit` ou `/exit` : Quitter Gemini CLI.

---

## Commandes At (`@`)

- `@<chemin_fichier_ou_dossier>` : Injecter le contenu d’un fichier ou dossier dans le prompt.
  - Exemples :
    - `@README.md Explique ce fichier.`
    - `@src/ Résume le code de ce dossier.`
- `@` (seul) : Le prompt est envoyé tel quel à Gemini (utile pour parler du symbole @).

**Détails :**
- Les fichiers/dossiers sont lus et leur contenu est inséré dans la requête.
- Les fichiers ignorés par git sont exclus par défaut.
- Les fichiers binaires ou très volumineux peuvent être ignorés ou tronqués.

---

## Commandes Shell (`!`)

- `!<commande_shell>` : Exécuter une commande shell directement depuis Gemini CLI.
  - Exemples :
    - `!ls -la`
    - `!git status`
- `!` (seul) : Bascule en mode shell (toutes les entrées suivantes sont interprétées comme des commandes shell jusqu’à sortie du mode shell).

**Attention :** Les commandes shell exécutées via Gemini CLI ont les mêmes droits que dans votre terminal natif.

---

## Sandbox Gemini CLI

La sandbox permet d’exécuter des commandes et scripts dans un environnement isolé pour plus de sécurité et de contrôle.

- Pour activer ou utiliser la sandbox, consultez la documentation officielle : [Sandbox Gemini CLI](https://github.com/google-gemini/gemini-cli/blob/main/docs/sandbox.md)
- La sandbox protège votre système en limitant les accès et en isolant les processus lancés via Gemini CLI.
- Reportez-vous à la documentation pour les options d’activation, de configuration et les limitations éventuelles.

---

## Ressources complémentaires
- [Documentation officielle Gemini CLI](https://github.com/google-gemini/gemini-cli/tree/main/docs/cli)
- [Liste complète des commandes (commands.md)](https://github.com/google-gemini/gemini-cli/blob/main/docs/cli/commands.md)
- [Configuration avancée](https://github.com/google-gemini/gemini-cli/blob/main/docs/cli/configuration.md)
- [Sandbox Gemini CLI](https://github.com/google-gemini/gemini-cli/blob/main/docs/sandbox.md)

---

*Document généré automatiquement à partir de la documentation officielle Gemini CLI.*
