# Plan d'implémentation : Assimilation des commits orphelins dans `dev` (sans PR)

- [x] **1. Préparation du champ de bataille**
    - [x] Synchroniser la branche `dev` : `git checkout dev && git pull`
    - [x] Créer une branche de travail dédiée : `git checkout -b assimilation-orphelins-legend`

- [x] **2. Invocation des artefacts orphelins (cherry-pick)**
    - [x] Pour chaque commit orphelin (08c2479e..., bfc51094..., dd25ceb0..., 237888fbf...) :
        - [x] Cherry-pick du commit : `git cherry-pick <commit>`
        - [x] Résolution des conflits (si besoin)
        - [x] Validation locale :
            - [x] Tests Go : `go test ./...`
            - [x] Analyse Codacy : `java -jar "C:/Program Files/CodacyCLI/codacy-analysis-cli-assembly.jar" analyze --directory . --output result-assimilation.json`
            - [x] Corriger tout problème détecté
            - [x] Tests d’intégration
            - [x] Vérification fonctionnelle (lancement local)

- [x] **3. Fusion et nettoyage**
    - [x] Vérification avant merge : `git checkout dev && git pull`
    - [x] Merger dans `dev` : `git merge assimilation-orphelins-legend`
    - [x] Gestion des erreurs (rollback si besoin)
    - [x] Suppression de la branche de travail et des branches orphelines

- [x] **4. Documentation et communication**
    - [x] Documenter l’opération (changelog ou fichier de suivi)
    - [x] Informer l’équipe

---

## Vérification des branches orphelines

Avant de cocher la suppression/assimilation des branches orphelines, exécuter :

```sh
git branch --merged dev
```
et
```sh
git branch -a | grep <nom_branche_orpheline>
```

Si les branches orphelines n’apparaissent plus ou sont bien fusionnées/supprimées, tu peux cocher les cases correspondantes.
