# Documentation CLI : Génération automatique AGENTS.md

## Script principal

Le script à utiliser pour générer ou mettre à jour la documentation détaillée des managers Go est :

```
go run ./tools/cmd/generate_manager_io_doc/main.go --dry-run
```

- **--dry-run** : Génère la documentation dans `dryrun_agents_doc.md` sans modifier `AGENTS.md`.
- Sans ce flag, le script sauvegarde automatiquement `AGENTS.md` dans `AGENTS.md.bak` avant toute modification réelle.

**Conseil** :

- Exécutez toujours la commande depuis la racine du projet.
- Vérifiez le fichier `dryrun_agents_doc.md` avant d’appliquer une modification réelle.

---

*Ce dossier ne contient qu’un seul script CLI principal. Si vous avez plusieurs `main.go` dans le projet, vérifiez bien le chemin avant d’exécuter !*
