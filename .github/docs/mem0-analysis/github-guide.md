# Guide GitHub & Workflow — mem0-analysis

Ce guide décrit les bonnes pratiques d’intégration, de contribution et de CI/CD pour le module **mem0-analysis** dans l’écosystème Roo Managers.

---

## Gestion des sous-modules git

- **Initialisation complète** :

```bash
git clone --recurse-submodules <url-du-repo-principal>
```

- **Mise à jour des sous-modules** :

```bash
git submodule update --init --recursive
```

- **Bonnes pratiques** :
  - Toujours synchroniser les sous-modules avant de lancer les tests ou la CI.
  - Commiter explicitement toute mise à jour de sous-module :
    ```bash
    git add mem0-analysis
    git commit -m "Update mem0-analysis submodule"
    ```

---

## Workflow de contribution

1. **Créer une branche dédiée** pour chaque contribution.
2. **Vérifier la synchronisation** des sous-modules et des requirements.
3. **Lancer les tests unitaires** localement avant toute PR :
   ```bash
   pytest
   ```
4. **Respecter la structure documentaire** (README, requirements, installation…).
5. **Soumettre une Pull Request** claire, avec description des changements et checklist de validation.

---

## Intégration continue (CI/CD)

- **Fichiers CI** : `.github/workflows/ci.yml`
- **Badges** : Statut CI affiché dans le README principal.
- **Triggers** : 
  - Push sur `main` ou `dev`
  - PR sur `main` ou `dev`
- **Jobs** :
  - Installation des dépendances
  - Lint & format
  - Tests unitaires
  - Vérification des sous-modules

---

## Synchronisation avec le dépôt principal

- **Après chaque mise à jour de mem0-analysis** :
  - Mettre à jour le sous-module dans le dépôt principal.
  - Vérifier la compatibilité des requirements et de la documentation.
  - Relancer la CI globale.

---

## Points de vigilance

- **Dépendances** : Toute modification de `pyproject.toml` ou `requirements.txt` doit être documentée dans [`requirements.md`](requirements.md).
- **Credentials & secrets** : Ne jamais commiter de secrets. Utiliser `.env` localement et GitHub Secrets pour la CI.
- **Documentation** : Toute nouvelle fonctionnalité ou changement doit être documenté dans le dossier `.github/docs/mem0-analysis/`.

---

## Liens utiles

- [README mem0-analysis](README.md)
- [Guide d’installation](installation.md)
- [Liste des requirements](requirements.md)

---

## FAQ

- **Problème de sous-module non synchronisé ?**  
  Exécuter :  
  `git submodule update --init --recursive`

- **CI échouée sur les tests Python ?**  
  Vérifier la version de Python, la présence des credentials, et la synchronisation des sous-modules.
