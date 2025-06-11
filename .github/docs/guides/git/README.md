# Documentation Git pour le projet EMAIL_SENDER_1

Ce dossier contient la documentation relative à l'utilisation et à la configuration de Git dans le cadre du projet EMAIL_SENDER_1.

## Guides disponibles

- [**Recommandations de configuration Git**](./git-config-recommendations.md) - Configurations Git recommandées pour le projet
- [**Résoudre les problèmes de pagination dans les terminaux**](./terminal-pagination.md) - Guide pour résoudre les problèmes de pagination Git dans les environnements d'Agent VS Code

## Configuration automatique

Pour configurer automatiquement Git selon les recommandations du projet, exécutez le script suivant :

```powershell
# Dans le répertoire racine du projet
.\.github\scripts\git-configure.ps1
```

## Problème résolu récemment

Un problème a été identifié avec la commande `git branch` qui semblait ne pas se terminer correctement dans l'environnement d'Agent VS Code. Ce problème était dû au mode de pagination interactif de Git qui n'est pas pleinement compatible avec les terminaux simulés.

**Solution appliquée :** Désactivation de la pagination Git via `git config --global core.pager ''`

Pour plus de détails sur ce problème et d'autres solutions possibles, consultez [le guide sur la pagination Git](./terminal-pagination.md).

## Ressources supplémentaires

- [Documentation officielle Git](https://git-scm.com/docs)
- [Pro Git Book](https://git-scm.com/book/en/v2)

## Contribuer à cette documentation

Si vous souhaitez améliorer cette documentation ou ajouter de nouveaux guides Git, n'hésitez pas à créer une pull request avec vos modifications.

---

Dernière mise à jour : 11 juin 2025