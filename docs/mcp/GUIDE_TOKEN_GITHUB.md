# Guide ultra-simple pour configurer votre token GitHub

Ce guide vous explique comment configurer votre token GitHub en quelques étapes simples.

## Méthode 1 : Utiliser le script ultra-simple

1. Double-cliquez sur le fichier `scripts\setup\token-github.cmd`
2. Collez votre token GitHub lorsque demandé
3. Appuyez sur Entrée

C'est tout ! Votre token GitHub est maintenant configuré.

## Méthode 2 : Modifier directement le fichier .env

1. Ouvrez le fichier `.env` à la racine du projet avec Notepad
2. Remplacez la ligne `GITHUB_TOKEN=votre_token_github_ici` par `GITHUB_TOKEN=votre_vrai_token`
3. Enregistrez le fichier

## Méthode 3 : Utiliser le fichier .env.example

1. Copiez le fichier `.env.example` et renommez-le en `.env`
2. Ouvrez le fichier `.env` avec Notepad
3. Remplacez `VOTRE_TOKEN_GITHUB_ICI` par votre véritable token GitHub
4. Enregistrez le fichier

## Comment tester que votre token fonctionne

Pour vérifier que votre token GitHub est correctement configuré :

1. Ouvrez PowerShell
2. Exécutez la commande suivante :
   ```
   .\scripts\mcp\start-mcp-github.cmd
   ```
3. Si le serveur démarre sans erreur, votre token est correctement configuré

## Besoin d'aide ?

Si vous rencontrez des difficultés, n'hésitez pas à demander de l'aide.
