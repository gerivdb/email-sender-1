# Guideline pour l'utilisation d'Augment dans VS Code

## 1. Limites des entrées (inputs)

**Contrainte actuelle** : Augment a une limite d'environ 8 000 à 10 000 caractères pour le paramètre `str_replace_entries`, due à la sérialisation des données entre le frontend et le backend.

**Solutions de contournement** :

- **Diviser manuellement les modifications** :
  - Séparez les gros changements en plusieurs appels (ex. : une fonction ou section par appel).
  - Exemple : Éditez fonction1 dans un premier appel, puis fonction2 dans un second.

- **Utiliser une approche par insertion** :
  - Préférez insérer du nouveau code plutôt que remplacer de gros blocs si possible.

- **Créer des nouveaux fichiers avec save-file** :
  - Pour les fichiers entièrement nouveaux, utilisez la commande `save-file`, qui a moins de restrictions que `str_replace_entries`.

> **Note** : Aucun mécanisme automatique de division des entrées volumineuses n'existe actuellement, mais une amélioration est prévue dans une future mise à jour.

## 2. Gestion des fichiers

**Comportement** : Augment ne modifie pas directement les fichiers existants comme Cline ; il crée de nouveaux fichiers ou nécessite des remplacements explicites.

**Recommandations** :
- Pour modifier un fichier existant, spécifiez clairement la région à remplacer via `str_replace_entries`.
- Vérifiez les erreurs comme `Cannot read file` ou `No replacement was performed` si le texte cible (`oldStr`) ne correspond pas exactement au contenu du fichier.

**Exemple d'erreur courante** :
```
No replacement was performed, oldStr did not appear verbatim in tools\path-utils\Path-Manager.psm1.
```
**Correction** : Ajustez `oldStr` pour qu'il corresponde précisément au contenu existant (voir la diff fournie dans l'erreur).

## 3. Gestion de l'encodage (spécifique aux fichiers PowerShell)

**Problèmes potentiels** : Les caractères accentués peuvent poser problème si l'encodage n'est pas correct (ex. : `OpÃ©ration` au lieu de `Opération`).

**Solutions** :

- **Enregistrer les fichiers en UTF-8 avec BOM** :
  - Dans VS Code, utilisez `File > Save with Encoding > UTF-8 with BOM` pour les scripts PowerShell (.ps1, .psm1).

- **Ajouter une ligne au début des scripts PowerShell** :
  ```powershell
  [Console]::OutputEncoding = [System.Text.Encoding]::UTF8
  ```

- **Configurer le terminal PowerShell** :
  - Avant d'exécuter des scripts, tapez dans le terminal :
  ```powershell
  chcp 65001
  ```

**Impact** : Un mauvais encodage peut affecter la lecture des entrées par Augment ou l'affichage des sorties, mais les modifications de fichiers sont généralement bien gérées en UTF-8.

## 4. Configuration recommandée dans VS Code

Ajoutez ces paramètres dans `settings.json` (accessible via `Ctrl+Shift+P > Preferences: Open Settings (JSON)`) pour optimiser Augment :

- **Gestion des fichiers volumineux** :
```json
"files.maxMemoryForLargeFilesMB": 4096
```

- **Affichage des résultats dans le terminal** :
```json
"terminal.integrated.scrollback": 10000
```

- **Encodage du terminal** :
```json
"terminal.integrated.env.windows": {
  "LC_ALL": "fr_FR.UTF-8"
}
```
(Adaptez `windows` à `linux` ou `osx` selon votre système.)

- **Performance générale** :
```json
"terminal.integrated.gpuAcceleration": "on"
```

## 5. Résolution des erreurs courantes

- **Erreur** : `Cannot read file: votre_fichier.ps1` :
  - Vérifiez que le chemin du fichier est correct et accessible dans le projet.

- **Erreur** : `No replacement was performed` :
  - Consultez la diff fournie (ex. : `# Commentaire à remplacer` vs. `Nom du fichier : Path-Manager.psm1`) et ajustez `oldStr` pour correspondre au contenu exact.
  - **Action** : Relancez la commande après correction.

## 6. Ressources et support

- **Documentation officielle** : Consultez https://docs.augmentcode.com/ (URL à confirmer).
- **Signaler un problème** :
  - Utilisez le bouton de feedback dans l'interface d'Augment.
  - Contactez support@augmentcode.com (adresse à confirmer).
  - Ouvrez un ticket sur le GitHub d'Augment si disponible.
- **Communauté** : Rejoignez le Discord ou Slack d'Augment pour des astuces supplémentaires.
- **Exemples** : Explorez la section "Exemples" de la documentation.

## 7. Évolutions futures

La limitation des entrées volumineuses est connue et en cours de résolution.

Une mise à jour dans les prochains mois devrait :
- Augmenter la taille maximale des inputs.
- Ajouter un mécanisme automatique pour diviser les grosses entrées.

## Conseils pratiques

- **Testez avec des petits inputs d'abord** : Avant de travailler sur un gros fichier, validez votre flux avec un extrait de 10 lignes.
- **Sauvegardez vos fichiers** : Utilisez un système de contrôle de version (comme Git) pour éviter les pertes de données en cas d'erreur.
- **Comparez manuellement si nécessaire** : Si Augment ne fournit pas de vue split, utilisez la fonctionnalité de diff de VS Code (clic droit > "Compare with...").

Cette guideline devrait vous permettre de travailler efficacement avec Augment tout en attendant les améliorations promises.
