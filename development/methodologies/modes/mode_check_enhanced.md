# Mode CHECK AmÃ©liorÃ©

## Description

Le mode CHECK amÃ©liorÃ© est une version avancÃ©e du [mode CHECK](mode_check.md) qui vÃ©rifie si les tÃ¢ches sÃ©lectionnÃ©es ont Ã©tÃ© implÃ©mentÃ©es Ã  100% et testÃ©es avec succÃ¨s Ã  100%, puis met Ã  jour automatiquement les cases Ã  cocher dans le document actif.

## AmÃ©liorations par rapport au mode CHECK standard

- **Encodage UTF-8 avec BOM** : Tous les fichiers sont enregistrÃ©s en UTF-8 avec BOM, ce qui garantit une meilleure compatibilitÃ© avec les caractÃ¨res accentuÃ©s.
- **PrÃ©servation des indentations** : Les indentations dans les documents sont correctement prÃ©servÃ©es lors de la mise Ã  jour des cases Ã  cocher.
- **Meilleure dÃ©tection des tÃ¢ches** : L'algorithme de dÃ©tection des tÃ¢ches a Ã©tÃ© amÃ©liorÃ© pour mieux identifier les tÃ¢ches dans le document actif.
- **PrÃ©servation du texte complet des tÃ¢ches** : Le texte complet des tÃ¢ches est prÃ©servÃ© lors de la mise Ã  jour des cases Ã  cocher.
- **Script wrapper simplifiÃ©** : Un script wrapper `check.ps1` est fourni pour faciliter l'utilisation du mode CHECK amÃ©liorÃ©.

## Utilisation

Le mode CHECK amÃ©liorÃ© est accessible via un script wrapper simplifiÃ© qui facilite son utilisation.

### Installation

Le mode CHECK amÃ©liorÃ© est installÃ© automatiquement avec les autres modes opÃ©rationnels. Le script wrapper `check.ps1` est placÃ© dans le rÃ©pertoire `tools\scripts\`.

### Syntaxe de base

```powershell
.\development\tools\scripts\check.ps1 [-FilePath <chemin_roadmap>] [-TaskIdentifier <id_tÃ¢che>] [-ActiveDocumentPath <chemin_document>] [-Force]
```

### VÃ©rification simple (mode simulation)

Pour vÃ©rifier si les tÃ¢ches sÃ©lectionnÃ©es ont Ã©tÃ© implÃ©mentÃ©es Ã  100% et testÃ©es avec succÃ¨s Ã  100% sans appliquer les modifications :

```powershell
.\development\tools\scripts\check.ps1 -FilePath "projet/documentation/roadmap/roadmap.md" -TaskIdentifier "1.2.3"
```

### Mise Ã  jour automatique des cases Ã  cocher

Pour mettre Ã  jour automatiquement les cases Ã  cocher dans le document actif :

```powershell
.\development\tools\scripts\check.ps1 -FilePath "projet/documentation/roadmap/roadmap.md" -TaskIdentifier "1.2.3" -Force
```

### SpÃ©cification du document actif

Si le document actif ne peut pas Ãªtre dÃ©tectÃ© automatiquement, vous pouvez le spÃ©cifier manuellement :

```powershell
.\development\tools\scripts\check.ps1 -FilePath "projet/documentation/roadmap/roadmap.md" -TaskIdentifier "1.2.3" -ActiveDocumentPath "projet/documentation/roadmap/roadmap.md" -Force
```

### Mode simulation et mode force

Par dÃ©faut, le mode CHECK amÃ©liorÃ© fonctionne en mode simulation (`-Force` non spÃ©cifiÃ©) :
- Il affiche les modifications qui seraient apportÃ©es sans les appliquer
- Il indique le nombre de cases Ã  cocher qui seraient mises Ã  jour

Pour appliquer rÃ©ellement les modifications, utilisez le paramÃ¨tre `-Force` :
```powershell
.\development\tools\scripts\check.ps1 -FilePath "projet/documentation/roadmap/roadmap.md" -TaskIdentifier "1.2.3" -Force
```

### ParamÃ¨tres complets

- **FilePath** : Chemin vers le fichier de roadmap Ã  vÃ©rifier (par dÃ©faut : "projet/roadmaps/plans/plan-modes-stepup.md")
- **TaskIdentifier** : Identifiant de la tÃ¢che Ã  vÃ©rifier (par exemple, "1.2.3")
- **ActiveDocumentPath** : Chemin vers le document actif Ã  mettre Ã  jour
- **Force** : Applique les modifications sans confirmation

## Fonctionnement interne

Le mode CHECK amÃ©liorÃ© fonctionne en plusieurs Ã©tapes :

1. **Analyse de la roadmap** : Le script analyse le fichier de roadmap pour identifier les tÃ¢ches et leur structure.
2. **VÃ©rification de l'implÃ©mentation** : Pour chaque tÃ¢che, le script vÃ©rifie si l'implÃ©mentation est complÃ¨te (100%).
3. **VÃ©rification des tests** : Pour chaque tÃ¢che, le script vÃ©rifie si les tests sont complets et rÃ©ussis (100%).
4. **DÃ©tection du document actif** : Le script tente de dÃ©tecter automatiquement le document actif.
5. **Mise Ã  jour des cases Ã  cocher** : Si les conditions sont remplies, le script met Ã  jour les cases Ã  cocher dans le document actif.

### Composants principaux

Le mode CHECK amÃ©liorÃ© utilise les fonctions suivantes :

1. `Invoke-RoadmapCheck` : VÃ©rifie si les tÃ¢ches sÃ©lectionnÃ©es ont Ã©tÃ© implÃ©mentÃ©es Ã  100% et testÃ©es avec succÃ¨s Ã  100%.
2. `Update-RoadmapTaskStatus` : Met Ã  jour le statut des tÃ¢ches dans la roadmap.
3. `Update-ActiveDocumentCheckboxes-Enhanced` : Met Ã  jour les cases Ã  cocher dans le document actif avec support UTF-8 avec BOM.

### DÃ©tection du document actif

Le mode CHECK amÃ©liorÃ© tente de dÃ©tecter automatiquement le document actif en utilisant les mÃ©thodes suivantes :

1. VÃ©rification de la variable d'environnement `VSCODE_ACTIVE_DOCUMENT`.
2. Recherche des fichiers Markdown rÃ©cemment modifiÃ©s (dans les 30 derniÃ¨res minutes).

Si aucun document actif ne peut Ãªtre dÃ©tectÃ© automatiquement, vous pouvez le spÃ©cifier manuellement avec le paramÃ¨tre `-ActiveDocumentPath`.

## IntÃ©gration avec les autres modes

Le mode CHECK amÃ©liorÃ© s'intÃ¨gre parfaitement avec les autres modes opÃ©rationnels :

- **Mode DEV-R** : Permet de vÃ©rifier automatiquement les tÃ¢ches implÃ©mentÃ©es pendant le dÃ©veloppement.
- **Mode GRAN** : ComplÃ©mentaire au mode CHECK pour la granularisation des tÃ¢ches.
- **Mode TEST** : Fournit les rÃ©sultats de tests utilisÃ©s par le mode CHECK.

## RÃ©solution des problÃ¨mes

### ProblÃ¨mes d'encodage

Si vous rencontrez des problÃ¨mes d'encodage (caractÃ¨res accentuÃ©s mal affichÃ©s), assurez-vous que tous les fichiers sont enregistrÃ©s en UTF-8 avec BOM. Le mode CHECK amÃ©liorÃ© tente de corriger automatiquement l'encodage, mais certains cas particuliers peuvent nÃ©cessiter une intervention manuelle.

### ProblÃ¨mes de dÃ©tection du document actif

Si le document actif ne peut pas Ãªtre dÃ©tectÃ© automatiquement, utilisez le paramÃ¨tre `-ActiveDocumentPath` pour le spÃ©cifier manuellement. Cela peut se produire si vous n'utilisez pas VS Code ou si le document n'a pas Ã©tÃ© modifiÃ© rÃ©cemment.

### ProblÃ¨mes de mise Ã  jour des cases Ã  cocher

Si les cases Ã  cocher ne sont pas mises Ã  jour correctement, vÃ©rifiez les points suivants :
- Les tÃ¢ches ont bien Ã©tÃ© implÃ©mentÃ©es Ã  100% et testÃ©es avec succÃ¨s Ã  100%
- Le format des tÃ¢ches dans votre roadmap correspond au format attendu
- Vous avez utilisÃ© le paramÃ¨tre `-Force` pour appliquer les modifications
