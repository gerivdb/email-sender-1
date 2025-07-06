# Étapes de résolution des conflits Git

Lorsque vous rencontrez des conflits de fusion (merge conflicts) dans Git, voici les étapes générales à suivre pour les résoudre :

1.  **Identifier les fichiers en conflit**
    *   Utilisez la commande `git status` dans votre terminal. Elle listera tous les fichiers qui ont des conflits non résolus. Ces fichiers seront généralement marqués comme "unmerged".

2.  **Ouvrir les fichiers en conflit**
    *   Ouvrez chacun des fichiers listés par `git status` dans votre éditeur de code (par exemple, VS Code).
    *   À l'intérieur de ces fichiers, vous verrez des marqueurs spéciaux qui délimitent les sections en conflit :
        ```
        <<<<<<< HEAD
        Contenu de votre branche actuelle (HEAD)
        =======
        Contenu de la branche que vous essayez de fusionner
        >>>>>>> nom-de-la-branche-a-fusionner
        ```
        *   `<<<<<<< HEAD` marque le début de la section de votre branche actuelle.
        *   `=======` sépare votre contenu de celui de la branche entrante.
        *   `>>>>>>> nom-de-la-branche-a-fusionner` marque la fin de la section de la branche entrante.

3.  **Résoudre les conflits**
    *   Pour chaque section en conflit, vous devez décider quelle version du code vous souhaitez conserver. Vous pouvez :
        *   Conserver votre version (`HEAD`).
        *   Conserver la version de la branche entrante.
        *   Combiner des parties des deux versions.
        *   Écrire un nouveau code qui intègre les deux changements.
    *   Après avoir pris votre décision, supprimez tous les marqueeurs de conflit (`<<<<<<<`, `=======`, `>>>>>>>`). Le fichier doit contenir uniquement le code final que vous souhaitez.

4.  **Ajouter les fichiers résolus à la zone de staging**
    *   Une fois que vous avez résolu tous les conflits dans un fichier et supprimé tous les marqueurs, vous devez informer Git que le fichier a été résolu.
    *   Utilisez la commande `git add <chemin/du/fichier_résolu>` pour chaque fichier que vous avez modifié.

5.  **Valider la fusion**
    *   Une fois que tous les fichiers en conflit ont été résolus et ajoutés à la zone de staging (`git add`), vous pouvez valider la fusion.
    *   Utilisez la commande `git commit`. Git ouvrira votre éditeur de texte par défaut (ou affichera un message dans le terminal) avec un message de commit pré-rempli. Ce message indique que c'est un commit de fusion. Vous pouvez l'accepter tel quel ou l'éditer pour ajouter plus de détails.
    *   Enregistrez et fermez l'éditeur (ou validez le message dans le terminal).

6.  **Pousser les modifications vers le dépôt distant**
    *   Après avoir validé la fusion localement, vous devez pousser ces changements vers le dépôt distant pour que les autres membres de l'équipe puissent voir la fusion résolue.
    *   Utilisez la commande `git push origin <nom_de_votre_branche_actuelle>` (par exemple, `git push origin dev` si vous êtes sur la branche `dev`).

N'hésitez pas à me demander si vous avez besoin d'aide pour une étape spécifique après avoir lu ces instructions.
