# Plan d'implémentation : Assimilation des commits orphelins dans `dev` (sans PR)

1.  **Préparation du champ de bataille :**
    *   Synchroniser la branche `dev` : `git checkout dev && git pull`
    *   Créer une branche de travail dédiée : `git checkout -b assimilation-orphelins-legend`

2.  **Invocation des artefacts orphelins (cherry-pick) :**
    *   Pour chaque commit orphelin (08c2479e..., bfc51094..., dd25ceb0..., 237888fbf...) :
        *   a. Cherry-pick du commit : `git cherry-pick <commit>`
        *   b. Résolution des conflits (si la tempête gronde) :
            *   Utiliser VSCode pour résoudre les conflits.
            *   `git add <fichiers_concernés> && git cherry-pick --continue`
        *   c. Validation locale :
            *   Tests Go : `go test ./...`
            *   Analyse statique Codacy : `java -jar "C:/Program Files/CodacyCLI/codacy-analysis-cli-assembly.jar" analyze --directory . --output result-assimilation.json`
            *   Corriger tout problème détecté.
            *   **Vérification supplémentaire :** Exécuter les tests d'intégration pour valider l'ensemble.
            *   **Vérification supplémentaire :** Lancer l'application localement pour s'assurer que les changements n'ont pas introduit de régression fonctionnelle.

3.  **Fusion et nettoyage :**
    *   **Vérification avant le merge :**
        *   `git checkout dev && git pull` (pour s'assurer que la branche `dev` est à jour)
    *   **Merger directement dans `dev` :** `git merge assimilation-orphelins-legend`
    *   **Gestion des erreurs (rollback) :**
        *   Si le merge échoue (conflits) :
            *   Identifier le commit qui a causé le problème.
            *   Revenir à l'état précédent : `git reset --hard HEAD~1` (supprime le commit de merge)
            *   Résoudre les conflits manuellement et recommencer le merge.
    *   Supprimer la branche de travail et les branches orphelines si elles ne servent plus.

4.  **Documentation et communication :**
    *   Documenter l’opération dans le changelog ou un fichier de suivi :
        *   Commits cherry-pickés
        *   Conflits résolus et méthode de résolution
        *   Résultats des tests unitaires et d'intégration
        *   Résultats de l'analyse Codacy
    *   Informer l’équipe de la réussite de l’assimilation.