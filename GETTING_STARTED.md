# Guide de Démarrage Rapide pour les Contributeurs

Bienvenue dans l'écosystème Roo Code ! Ce guide vous aidera à faire vos premiers pas en tant que contributeur.

## 1. Comprendre l'Écosystème

L'écosystème Roo Code est conçu pour être modulaire et extensible. Il est composé de :

- **Règles** : Un ensemble de fichiers `.md` dans le dossier `.roo/rules` qui définissent les standards et les bonnes pratiques du projet.
- **Outils** : Des scripts et des programmes dans le dossier `.roo/tools` qui permettent de valider, de synchroniser et de maintenir l'écosystème.
- **Personas** : Des descriptions des différents types d'utilisateurs dans le fichier `.roo/personas.md`.
- **Workflows** : Des descriptions des processus clés dans `.roo/rules/workflows-matrix.md`.

## 2. Votre Première Contribution

Pour contribuer à l'écosystème, vous devez suivre les étapes suivantes :

1. **Modifier ou créer un fichier de règles** : Identifiez le fichier de règles que vous souhaitez modifier ou créer dans le dossier `.roo/rules`.
2. **Lancer le script de validation** : Une fois vos modifications terminées, lancez le script `run_all.sh` à partir du dossier `.roo/tools` pour valider vos changements :
   ```bash
   cd .roo/tools
   ./run_all.sh
   ```
3. **Corriger les erreurs** : Si le script détecte des erreurs, corrigez-les et relancez le script jusqu'à ce que la validation réussisse.
4. **Soumettre vos modifications** : Une fois la validation réussie, vous pouvez soumettre vos modifications en toute confiance.

## 3. Aller plus loin

Pour en savoir plus sur l'écosystème Roo Code, vous pouvez consulter les documents suivants :

- [`.roo/rules/rules.md`](./.roo/rules/rules.md) : Les principes transverses de l'écosystème.
- [`.roo/personas.md`](./.roo/personas.md) : Les personas de l'extension VSIX.
- [`.roo/rules/workflows-matrix.md`](./.roo/rules/workflows-matrix.md) : Les workflows principaux.

N'hésitez pas à poser des questions si vous rencontrez des difficultés. Votre contribution est la bienvenue !
