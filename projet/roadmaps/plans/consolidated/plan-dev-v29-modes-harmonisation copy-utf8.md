---
to: "plan-dev/plan-dev-v29-modes-harmonisation.md"
---
# Plan Dev: Modes Harmonisation (v29)

Date de crÃ©ation : 2025-05-21
Auteur : Ã€ complÃ©ter

## Introduction globale

Ce document prÃ©sente lâ€™ensemble des modes opÃ©rationnels harmonisÃ©s pour la gestion des workflows roadmap. Chaque mode est autonome, modulaire et conÃ§u pour Ãªtre combinÃ© avec les autres selon les besoins du projet. La logique modulaire permet dâ€™assembler les modes dans des sÃ©quences adaptÃ©es (exÂ : GRAN â†’ DEV-R â†’ TEST â†’ DEBUG â†’ REVIEW â†’ OPTI â†’ CHECK), tout en Ã©vitant toute redondance fonctionnelle.

### Liste des modes harmonisÃ©s

- ARCHI (Architecture)
- GRAN (Granularisation)
- DEV-R (DÃ©veloppement Roadmap)
- TEST (Tests automatisÃ©s)
- DEBUG (DÃ©bogage)
- CHECK (VÃ©rification dâ€™avancement)
- REVIEW (Revue qualitÃ©)
- OPTI (Optimisation)
- PREDIC (PrÃ©diction/Analyse)
- C-BREAK (RÃ©solution de cycles/dÃ©pendances)

Chaque fiche mode dÃ©tailleÂ : objectifs, commandes principales, fonctionnement, bonnes pratiques, intÃ©gration avec les autres modes, exemples dâ€™utilisation et snippet VS Code. Les points dâ€™entrÃ©e/sortie sont explicitÃ©s pour faciliter la combinaison et lâ€™automatisation.

## Objectif

Harmoniser, modulariser et rendre cohÃ©rents tous les modes opÃ©rationnels dÃ©crits dans `development/methodologies/modes`, afin de constituer une base unifiÃ©e, sans redondance, directement exploitable pour la gÃ©nÃ©ration de snippets et l'automatisation des workflows roadmap.

## Ã‰tapes principales

- [x] Recenser tous les fichiers de mode existants dans `development/methodologies/modes`
  - Fichiers trouvÃ©sÂ :
    - index.md
    - mode_archi.md
    - mode_c-break.md
    - mode_check_enhanced.md
    - mode_c_break.md
    - mode_debug.md
    - mode_dev_r.md
    - mode_gran.md
    - mode_opti.md
    - mode_predic.md
    - mode_review.md
    - mode_test.md
- [x] Identifier et supprimer les doublons (ex : C-BREAK)
  - Doublons dÃ©tectÃ©sÂ :
    - mode_c-break.md / mode_c_break.md (variante de nommage pour C-BREAK)
  - Action recommandÃ©eÂ : fusionner le contenu et ne conserver qu'un seul fichier pour le mode C-BREAK.
- [x] DÃ©finir une structure unifiÃ©e pour chaque mode
  - Structure proposÃ©e (voir section dÃ©diÃ©e ci-dessous)Â :
    - Titre, Description, Objectifs, Commandes principales, Fonctionnement, Bonnes pratiques, IntÃ©gration avec les autres modes, Exemples dâ€™utilisation, Snippet VS Code (optionnel)
  - Cette structure est dÃ©taillÃ©e dans la section Â«Â Structure unifiÃ©e pour chaque modeÂ Â» du plan.
- [x] RÃ©Ã©crire chaque fichier de mode selon cette structure
  - Chaque fichier de mode sera restructurÃ© selon la structure unifiÃ©e dÃ©finie ci-dessus (Titre, Description, Objectifs, Commandes principales, Fonctionnement, Bonnes pratiques, IntÃ©gration, Exemples, Snippet VS Code).
  - PrioritÃ©Â : traiter d'abord les modes principaux (ARCHI, GRAN, DEV-R, TEST, DEBUG, CHECK, REVIEW, OPTI, PREDIC, C-BREAK).
  - Les doublons (exÂ : C-BREAK) seront fusionnÃ©s lors de la rÃ©Ã©criture.
- [x] VÃ©rifier la cohÃ©rence globale (pas de redondance, pas dâ€™incohÃ©rence)
  - Chaque mode a Ã©tÃ© restructurÃ© selon la structure unifiÃ©e, les doublons ont Ã©tÃ© fusionnÃ©s.
  - VÃ©rification effectuÃ©eÂ : pas de redondance fonctionnelle, chaque mode est autonome et les interactions sont rÃ©fÃ©rencÃ©es.
  - Les points dâ€™entrÃ©e/sortie et les combinaisons typiques sont explicitÃ©s dans chaque fiche mode.
- [x] Ajouter une introduction globale listant tous les modes et expliquant la logique modulaire/combinatoire
  - Introduction ajoutÃ©e en tÃªte de documentÂ :

## Structure unifiÃ©e pour chaque mode

```markdown
# Mode <NOM>

## Description

RÃ©sumÃ© du mode, son objectif principal et son rÃ´le dans le workflow.

## Objectifs

- Liste des objectifs spÃ©cifiques du mode.

## Commandes principales

- <COMMANDE> : Description courte
- ...

## Fonctionnement

- Ã‰tapes clÃ©s du mode (sÃ©quentiel, dÃ©clencheurs, automatisations, etc.)

## Bonnes pratiques

- Conseils dâ€™utilisation, piÃ¨ges Ã  Ã©viter, standards Ã  respecter.

## IntÃ©gration avec les autres modes

- Comment ce mode sâ€™articule avec les autres (ex : TEST sâ€™active aprÃ¨s DEV-R, DEBUG aprÃ¨s TEST, etc.)
- Exemples de combinaisons typiques.

## Exemples dâ€™utilisation

```powershell
# Exemple dâ€™appel du mode en CLI ou via snippet

Invoke-AugmentMode -Mode "<NOM>" -FilePath "<roadmap>" -TaskIdentifier "<id>"
```plaintext
## Snippet VS Code (optionnel)

```json
{
  "Mode <NOM>": {
    "prefix": "<prefix>",
    "body": [
      // contenu du snippet
    ],
    "description": "InsÃ¨re le template du mode <NOM>."
  }
}
```plaintext
```plaintext
## Modes Ã  harmoniser (liste indicative)

- ARCHI (Architecture)
- GRAN (Granularisation)
- DEV-R (DÃ©veloppement Roadmap)
- TEST (Tests automatisÃ©s)
- DEBUG (DÃ©bogage)
- CHECK (VÃ©rification dâ€™avancement)
- REVIEW (Revue qualitÃ©)
- OPTI (Optimisation)
- PREDIC (PrÃ©diction/Analyse)
- C-BREAK (RÃ©solution de cycles/dÃ©pendances)
- (Optionnel : GIT, UI, DB, SECURE, META...)

## Principes dâ€™intÃ©gration et de combinaison

- Chaque mode est autonome mais expose clairement ses points dâ€™entrÃ©e/sortie pour Ãªtre combinÃ© avec dâ€™autres.
- Pas de redondance : chaque fonctionnalitÃ© nâ€™est dÃ©crite que dans un seul mode, les interactions sont rÃ©fÃ©rencÃ©es.
- Workflows recommandÃ©s (exemples) :
  - GRAN â†’ DEV-R â†’ TEST â†’ DEBUG â†’ REVIEW â†’ OPTI â†’ CHECK
  - ARCHI â†’ C-BREAK â†’ DEV-R â†’ TEST â†’ DEBUG â†’ REVIEW
- Exemples de combinaisons sont donnÃ©s dans chaque fiche mode.
- PrÃ©paration Ã  la gÃ©nÃ©ration de snippets : chaque fiche peut Ãªtre copiÃ©e telle quelle dans un fichier de snippets VS Code.

## DÃ©tails

- Utiliser la structure imbriquÃ©e ci-dessus pour dÃ©tailler chaque niveau, jusquâ€™Ã  10 niveaux si nÃ©cessaire.
- Sâ€™assurer que lâ€™ensemble couvre tous les besoins de dÃ©veloppement, debug, test, review, optimisation, etc.

# Ã‰tapes suivantes pour lâ€™harmonisation des modes (v29)

- [ ] Mettre Ã  jour la documentation associÃ©e Ã  chaque mode harmonisÃ©
  - [ ] VÃ©rifier que chaque fiche mode est bien rÃ©fÃ©rencÃ©e dans la documentation globale.
    - [x] mode_archi.md
    - [x] mode_gran.md
    - [x] mode_dev_r.md
    - [x] mode_test.md
    - [x] mode_debug.md
    - [x] mode_check_enhanced.md
    - [ ] mode_review.md
    - [ ] mode_opti.md
    - [ ] mode_predic.md
    - [x] mode_c-break.md
    - [ ] index.md
  - [x] Ajouter des liens croisÃ©s entre modes pour faciliter la navigation.
- [x] GÃ©nÃ©rer automatiquement les snippets VS Code Ã  partir des fiches modes
  - [x] Extraire la section Â«Â Snippet VS CodeÂ Â» de chaque fiche mode.
  - [x] GÃ©nÃ©rer un fichier de snippets global.
- [x] Mettre en place des tests dâ€™intÃ©gritÃ© pour les modes
  - [x] VÃ©rifier la prÃ©sence de toutes les sections obligatoires dans chaque fiche mode.
  - [x] DÃ©tecter les incohÃ©rences ou oublis (exÂ : absence dâ€™exemple, de bonnes pratiques, etc.).
- [x] IntÃ©grer les modes harmonisÃ©s dans les workflows dâ€™automatisation
  - [x] Adapter les scripts ou outils existants pour exploiter la nouvelle structure des modes (extraction automatique des snippets opÃ©rationnelle via `misc/extract_vscode_snippets.py`).
  - [x] Documenter les points dâ€™intÃ©gration (exÂ : gÃ©nÃ©ration de roadmap, automatisation de tÃ¢ches, extraction de snippets utilisable dans CI/CD ou autres outils).
- [x] Organiser une revue collective pour valider lâ€™harmonisation
  - [x] Faire relire les fiches modes par plusieurs membres de lâ€™Ã©quipe (DEV-R, ARCHI, GRAN, TEST, DEBUG, CHECK, REVIEW, OPTI, PREDIC, C-BREAK).
  - [x] Recueillir les retours et ajuster si besoin.
- [x] Recueillir toutes les informations sur le "Mode Manager" qui d'aprÃ¨s son nom semble justement chargÃ© de gÃ©rer les modes.
  - [x] Identifier les fonctionnalitÃ©s et les interactions avec les autres modes.
  - [x] Documenter son fonctionnement et son intÃ©gration dans le workflow global.

> **SynthÃ¨se sur le Mode Manager**
>
> **FonctionnalitÃ©s principales :**
> - Gestion centralisÃ©e de tous les modes opÃ©rationnels (ARCHI, GRAN, DEV-R, TEST, DEBUG, CHECK, REVIEW, OPTI, PREDIC, C-BREAK) via une interface unifiÃ©e.
> - ParamÃ©trage dynamique (Mode, FilePath, TaskIdentifier, ConfigPath, Force, Chainâ€¦)
> - ChaÃ®nage de modes : exÃ©cution sÃ©quentielle automatisÃ©e (ex : GRAN, DEV-R, CHECK)
> - Affichage de la liste des modes, documentation, exemples dâ€™utilisation
> - Chargement de la configuration JSON pour scripts et paramÃ¨tres
> - Extensible : ajout de nouveaux modes/scripts via la configuration
>
> **Interactions avec les autres modes :**
> - Lance les scripts de chaque mode (ex : gran-mode.ps1, dev-r-mode.ps1â€¦)
> - Transmet les paramÃ¨tres nÃ©cessaires Ã  chaque mode
> - GÃ¨re les enchaÃ®nements multi-modes (workflows)
> - Centralise lâ€™orchestration, les modes restent autonomes
>
> **IntÃ©gration dans le workflow global :**
> - Point dâ€™entrÃ©e unique pour automatiser les workflows roadmap, granularisation, dÃ©veloppement, tests, etc.
> - Utilisation typiqueÂ :
>   ```powershell
>   .\development\managers\mode-manager\scripts\mode-manager.ps1 -Mode DEV-R -FilePath "projet/roadmaps/roadmap.md" -TaskIdentifier "1.2.3"
>   ```
>   ou pour une chaÃ®neÂ :
>   ```powershell
>   .\development\managers\mode-manager\scripts\mode-manager.ps1 -Chain "GRAN,DEV-R,CHECK" -FilePath "projet/roadmaps/roadmap.md" -TaskIdentifier "1.2.3"
>   ```
> - Configuration dans `projet/config/managers/mode-manager/mode-manager.config.json`
> - Toute Ã©volution se fait via la configuration ou lâ€™ajout de scripts

#### Rapport dâ€™avancement DEV-R (21/05/2025)

**Responsable** : DEV-R  
**PÃ©rimÃ¨tre** : Analyse du contexte dans lâ€™utilisation des modes et du Mode Manager

**SynthÃ¨se des actions rÃ©alisÃ©esÂ :**
- Recensement des principaux types de contexte impactant lâ€™usage des modesÂ :
    - Type de projet (mono-module, multi-module, legacy, greenfieldâ€¦)
    - Workflow cible (agile, cycle en V, CI/CD, prototypage rapideâ€¦)
    - Historique des actions (tÃ¢ches dÃ©jÃ  rÃ©alisÃ©es, modes dÃ©jÃ  enchaÃ®nÃ©s, erreurs prÃ©cÃ©dentesâ€¦)
    - PrÃ©fÃ©rences utilisateur (affichage, raccourcis, modes favorisâ€¦)
    - Environnement technique (OS, Ã©diteur, outils disponibles, configuration spÃ©cifiqueâ€¦)
- Collecte initiale des besoins utilisateurs via interviews flash et analyse des tickets internesÂ :
    - Cas dâ€™usage oÃ¹ le contexte accÃ©lÃ¨re la sÃ©lection ou lâ€™enchaÃ®nement des modes
    - ExemplesÂ : prÃ©-remplissage des paramÃ¨tres, suggestions de modes selon lâ€™historique, adaptation des snippets
- Premiers constats sur lâ€™impact du contexteÂ :
    - AutomatisationÂ : le contexte permet de chaÃ®ner automatiquement les modes adaptÃ©s au projet courant
    - GÃ©nÃ©ration de snippetsÂ : adaptation dynamique des snippets selon le type de tÃ¢che ou de projet
    - NavigationÂ : filtrage des modes ou commandes selon le contexte dÃ©tectÃ©
    - Prise de dÃ©cisionÂ : recommandations de modes ou dâ€™actions selon lâ€™historique et les prÃ©fÃ©rences

**Prochaines Ã©tapesÂ :**
- Approfondir la collecte des besoins utilisateurs (questionnaire, ateliers)
- Formaliser les cas dâ€™usage oÃ¹ le contexte est dÃ©terminant
- Prototyper des adaptations contextuelles dans le Mode Manager (exÂ : suggestions dynamiques, prÃ©-remplissage)
- Ã‰valuer lâ€™impact sur la productivitÃ© et la satisfaction utilisateur
- Prioriser les axes dâ€™amÃ©lioration (ergonomie, automatisation, personnalisation)

**RemarquesÂ :**
- Lâ€™intÃ©gration du contexte dans les outils et modes est un levier majeur dâ€™optimisation des workflows.
- Une documentation dÃ©diÃ©e sera proposÃ©e pour formaliser les bonnes pratiques de gestion du contexte.

- [ ] Planifier la maintenance, lâ€™harmonisation et lâ€™Ã©volution des modes, du Mode Manager et de la documentation associÃ©e
  - [ ] Suivi, maintenance et Ã©volution des modes et du Mode Manager
    - [x] Mettre en place une veille technique rÃ©guliÃ¨re (analyse des besoins dâ€™harmonisation, retours dâ€™expÃ©rience, nouvelles pratiques) pour chaque mode et pour le Mode Manager.  
      - [Lien vers la veille technique](veille_technique.md) â€” [En cours]
    - [x] VÃ©rifier automatiquement lâ€™utilisation du template lors des modifications (script/CI/CD).
        - Utiliser le script `misc/check_template_usage.py` pour contrÃ´ler la conformitÃ© des fichiers modifiÃ©s avec le template.
        - IntÃ©grer ce script dans le pipeline CI/CD pour chaque PR ou commit touchant un mode ou le Mode Manager (alerte en cas dâ€™Ã©cart).
        - En cas dâ€™Ã©volution de la structure, proposer la modification du template via une PR dÃ©diÃ©e, puis faire valider la nouvelle structure par lâ€™Ã©quipe avant adoption.
    - [x] Ajouter un exemple ou snippet pour chaque nouvelle fonctionnalitÃ© ou point dâ€™intÃ©gration (voir exemples ci-dessous).
        - Exemple de snippet VS Code pour CHECKÂ :
            ```json
            {
              "Mode CHECK AmÃ©liorÃ©": {
                "prefix": "mode-check-ameliore",
                "body": [
                  "# Mode CHECK AmÃ©liorÃ©",

                  "",
                  "## Description",

                  "Le mode CHECK amÃ©liorÃ© vÃ©rifie lâ€™implÃ©mentation et les tests des tÃ¢ches, puis met Ã  jour les cases Ã  cocher.",
                  "",
                  "## Objectifs",

                  "- VÃ©rifier lâ€™implÃ©mentation complÃ¨te des tÃ¢ches.",
                  "- Sâ€™assurer que les tests sont rÃ©ussis Ã  100%.",
                  "- Mettre Ã  jour automatiquement les cases Ã  cocher.",
                  "",
                  "## Commandes principales",

                  "- check.ps1 -FilePath <chemin_roadmap> -TaskIdentifier <id_tÃ¢che>",
                  "- check.ps1 -FilePath <chemin_roadmap> -TaskIdentifier <id_tÃ¢che> -Force",
                  "- check.ps1 -FilePath <chemin_roadmap> -TaskIdentifier <id_tÃ¢che> -ActiveDocumentPath <chemin_document>",
                  "",
                  "## Fonctionnement",

                  "- Analyse la roadmap, vÃ©rifie lâ€™implÃ©mentation et les tests, met Ã  jour les cases Ã  cocher.",
                  "",
                  "## Bonnes pratiques",

                  "- ExÃ©cuter aprÃ¨s chaque Ã©tape de dÃ©veloppement/test.",
                  "- VÃ©rifier lâ€™encodage des fichiers.",
                  "- Utiliser -Force aprÃ¨s validation.",
                  "",
                  "## IntÃ©gration avec les autres modes",

                  "- DEV-R, GRAN, TEST, REVIEW, OPTI, C-BREAK.",
                  "",
                  "## Exemples dâ€™utilisation",

                  "# VÃ©rification simple",

                  ".\\development\\tools\\scripts\\check.ps1 -FilePath \"projet/documentation/roadmap/roadmap.md\" -TaskIdentifier \"1.2.3\"",
                  "# Mise Ã  jour automatique",

                  ".\\development\\tools\\scripts\\check.ps1 -FilePath \"projet/documentation/roadmap/roadmap.md\" -TaskIdentifier \"1.2.3\" -Force"
                ],
                "description": "InsÃ¨re le template du mode CHECK AmÃ©liorÃ©."
              },
              "Check sÃ©lection (mode CHECK)": {
                "prefix": "check",
                "body": [
                  "# VÃ©rification des lignes sÃ©lectionnÃ©es (mode CHECK)",

                  "${1:check.ps1} -FilePath ${2:projet/documentation/roadmap/roadmap.md} -Selection ${TM_SELECTED_TEXT}"
                ],
                "description": "Lance la vÃ©rification CHECK sur les lignes sÃ©lectionnÃ©es dans l'Ã©diteur."
              }
            }
            ```
        - Documenter chaque snippet ajoutÃ© dans la fiche mode concernÃ©e et dans la documentation globale.
            - [ ] Utiliser un template standardisÃ© pour chaque modification (exÂ : Hygen, modÃ¨le markdown).
                - [x] Toujours partir du template situÃ© dans `development/templates/hygen/mode` ou du modÃ¨le markdown de rÃ©fÃ©rence.
                    - Ouvrir le template, copier la structure, et lâ€™utiliser pour toute nouvelle fiche ou modification majeure dâ€™un mode ou du Mode Manager.
                    - VÃ©rifier que toutes les sections obligatoires sont prÃ©sentes et adaptÃ©es au contexte du mode ou du Mode Manager.
                - [x] VÃ©rifier automatiquement lâ€™utilisation du template lors des modifications (script/CI/CD).
                    - Utiliser le script `misc/check_template_usage.py` pour contrÃ´ler la conformitÃ© des fichiers modifiÃ©s avec le template.
                    - IntÃ©grer ce script dans le pipeline CI/CD pour chaque PR ou commit touchant un mode ou le Mode Manager (alerte en cas dâ€™Ã©cart).
                    - En cas dâ€™Ã©volution de la structure, proposer la modification du template via une PR dÃ©diÃ©e, puis faire valider la nouvelle structure par lâ€™Ã©quipe avant adoption.
                - [ ] Ajouter un exemple ou snippet pour chaque nouvelle fonctionnalitÃ© ou point dâ€™intÃ©gration (voir exemples ci-dessous).
                    - Exemple de snippet VS Code pour CHECKÂ :
                        ```json
                        {
                          "Mode CHECK AmÃ©liorÃ©": {
                            "prefix": "mode-check-ameliore",
                            "body": [
                              "# Mode CHECK AmÃ©liorÃ©",

                              "",
                              "## Description",

                              "Le mode CHECK amÃ©liorÃ© vÃ©rifie lâ€™implÃ©mentation et les tests des tÃ¢ches, puis met Ã  jour les cases Ã  cocher.",
                              "",
                              "## Objectifs",

                              "- VÃ©rifier lâ€™implÃ©mentation complÃ¨te des tÃ¢ches.",
                              "- Sâ€™assurer que les tests sont rÃ©ussis Ã  100%.",
                              "- Mettre Ã  jour automatiquement les cases Ã  cocher.",
                              "",
                              "## Commandes principales",

                              "- check.ps1 -FilePath <chemin_roadmap> -TaskIdentifier <id_tÃ¢che>",
                              "- check.ps1 -FilePath <chemin_roadmap> -TaskIdentifier <id_tÃ¢che> -Force",
                              "- check.ps1 -FilePath <chemin_roadmap> -TaskIdentifier <id_tÃ¢che> -ActiveDocumentPath <chemin_document>",
                              "",
                              "## Fonctionnement",

                              "- Analyse la roadmap, vÃ©rifie lâ€™implÃ©mentation et les tests, met Ã  jour les cases Ã  cocher.",
                              "",
                              "## Bonnes pratiques",

                              "- ExÃ©cuter aprÃ¨s chaque Ã©tape de dÃ©veloppement/test.",
                              "- VÃ©rifier lâ€™encodage des fichiers.",
                              "- Utiliser -Force aprÃ¨s validation.",
                              "",
                              "## IntÃ©gration avec les autres modes",

                              "- DEV-R, GRAN, TEST, REVIEW, OPTI, C-BREAK.",
                              "",
                              "## Exemples dâ€™utilisation",

                              "# VÃ©rification simple",

                              ".\\development\\tools\\scripts\\check.ps1 -FilePath \"projet/documentation/roadmap/roadmap.md\" -TaskIdentifier \"1.2.3\"",
                              "# Mise Ã  jour automatique",

                              ".\\development\\tools\\scripts\\check.ps1 -FilePath \"projet/documentation/roadmap/roadmap.md\" -TaskIdentifier \"1.2.3\" -Force"
                            ],
                            "description": "InsÃ¨re le template du mode CHECK AmÃ©liorÃ©."
                          },
                          "Check sÃ©lection (mode CHECK)": {
                            "prefix": "check",
                            "body": [
                              "# VÃ©rification des lignes sÃ©lectionnÃ©es (mode CHECK)",

                              "${1:check.ps1} -FilePath ${2:projet/documentation/roadmap/roadmap.md} -Selection ${TM_SELECTED_TEXT}"
                            ],
                            "description": "Lance la vÃ©rification CHECK sur les lignes sÃ©lectionnÃ©es dans l'Ã©diteur."
                          }
                        }
                        ```
                    - Documenter chaque snippet ajoutÃ© dans la fiche mode concernÃ©e et dans la documentation globale.
            - [ ] Ajouter un exemple ou snippet pour chaque nouvelle fonctionnalitÃ© ou point dâ€™intÃ©gration.
            - [ ] VÃ©rifier automatiquement la prÃ©sence et la complÃ©tude des sections obligatoires (script/CI/CD).
            - [ ] IntÃ©grer une checklist de PR pour garantir la mise Ã  jour documentaire Ã  chaque Ã©volution.
        - [ ] Tenir un changelog dÃ©taillÃ© pour chaque mode et pour le Mode Manager (date, auteur, description, impact, lien vers la modification).
            - [ ] CrÃ©er/maintenir un fichier CHANGELOG.md par mode et pour le Mode Manager.
            - [ ] Ajouter automatiquement une entrÃ©e Ã  chaque PR ou commit modifiant un mode (hook script/CI/CD).
            - [ ] VÃ©rifier la cohÃ©rence et la complÃ©tude du changelog lors des revues (script/CI/CD).
        - [ ] Archiver les anciennes versions si nÃ©cessaire (pour traÃ§abilitÃ©, retour arriÃ¨re et auditabilitÃ©).
            - [ ] DÃ©placer les versions obsolÃ¨tes dans un dossier dâ€™archive dÃ©diÃ© (exÂ : /archives/modes/<mode>/).
            - [ ] Automatiser la sauvegarde et la restauration via script ou pipeline CI/CD.
            - [ ] Documenter la procÃ©dure dâ€™archivage et de restauration (README dans le dossier dâ€™archive).
    - [ ] Processus de validation et dâ€™automatisation
        - [ ] Proposer les Ã©volutions via une fiche de modification standardisÃ©e (template).
        - [ ] Valider les changements en revue collective (relecture, tests, validation croisÃ©e).
        - [ ] ImplÃ©menter les changements dans les fichiers de modes, le Mode Manager et la documentation.
        - [ ] Mettre Ã  jour les snippets VS Code et les scripts dâ€™automatisation si besoin.
        - [ ] Automatiser la dÃ©tection des Ã©carts, la gÃ©nÃ©ration de documentation et lâ€™extraction des snippets (tests dâ€™intÃ©gritÃ©, scripts de vÃ©rification, CI/CD).

---

### Ã‰valuation, harmonisation et Ã©volution des templates et modes

- [ ] Ã‰valuer et harmoniser le template Hygen pour les modes
  - [ ] Comparer la structure du template Hygen (`development/templates/hygen/mode`) avec la diversitÃ© rÃ©elle des modes existants (`development/methodologies/modes`), en excluant `index.md`.
    - [ ] Lister toutes les sections prÃ©sentes dans le template Hygen.
    - [ ] Lister toutes les sections prÃ©sentes dans chaque mode existant.
    - [ ] Identifier les diffÃ©rences de structure, de syntaxe, dâ€™intitulÃ© ou dâ€™ordre des sections.
  - [ ] Identifier les Ã©carts de structure, de syntaxe ou de sections manquantes/optionnelles.
    - [ ] RepÃ©rer les sections obligatoires absentes dans certains modes.
    - [ ] RepÃ©rer les sections optionnelles ou spÃ©cifiques Ã  certains modes.
    - [ ] Noter les incohÃ©rences de nommage ou de format.
  - [ ] Proposer les adaptations nÃ©cessaires pour que le template couvre tous les cas dâ€™usage des modes actuels et futurs.
    - [ ] DÃ©finir une structure cible exhaustive et flexible.
    - [ ] Ajouter des exemples pour chaque section du template.
    - [ ] PrÃ©voir des champs optionnels et des instructions pour lâ€™adaptation Ã  de nouveaux modes.

- [ ] Harmoniser la structure de tous les modes
  - [ ] DÃ©finir une structure cible unique, inspirÃ©e du niveau de dÃ©tail de `mode_dev_r.md`.
    - [ ] Analyser la structure de `mode_dev_r.md` (niveau de dÃ©tail, clartÃ©, complÃ©tude).
    - [ ] Formaliser cette structure comme rÃ©fÃ©rence pour tous les modes.
  - [ ] Adapter chaque fiche mode existante pour respecter cette structure (titre, description, objectifs, commandes, fonctionnement, bonnes pratiques, intÃ©gration, exemples, snippet VS Code, etc.).
    - [ ] Lister les modes Ã  adapter.
    - [ ] Pour chaque mode, identifier les sections Ã  complÃ©ter, corriger ou rÃ©organiser.
    - [ ] Appliquer la structure cible Ã  chaque fiche mode.
  - [ ] Sâ€™assurer que chaque mode est suffisamment prÃ©cis, complet et cohÃ©rent pour Ãªtre exploitÃ© par le Mode Manager et les outils dâ€™automatisation.
    - [ ] VÃ©rifier la prÃ©sence de tous les champs obligatoires.
    - [ ] VÃ©rifier la clartÃ© des exemples et des snippets.
    - [ ] Valider la cohÃ©rence dâ€™ensemble (terminologie, format, liens croisÃ©s).

- [ ] AmÃ©liorer et gÃ©nÃ©raliser le template Hygen
  - [ ] IntÃ©grer toutes les sections obligatoires et optionnelles dans le template.
    - [ ] Ajouter des commentaires ou instructions pour chaque section.
    - [ ] PrÃ©voir des blocs conditionnels pour les sections optionnelles.
  - [ ] Permettre la crÃ©ation de nouveaux modes Ã  partir du template, avec un niveau de prÃ©cision et de complÃ©tude homogÃ¨ne.
    - [ ] Tester la gÃ©nÃ©ration dâ€™un nouveau mode avec le template.
    - [ ] Ajuster le template selon les retours dâ€™expÃ©rience.
  - [ ] PrÃ©voir la possibilitÃ© de reformater automatiquement les modes existants pour les aligner sur le template (script de migration ou commande Hygen dÃ©diÃ©e).
    - [ ] DÃ©velopper un script ou une commande pour migrer les modes existants.
    - [ ] Tester la migration sur plusieurs modes.
    - [ ] Documenter le processus de migration.

---

### Extension des capacitÃ©s du Mode Manager

- [ ] RÃ©flÃ©chir Ã  lâ€™Ã©tendue fonctionnelle du Mode Manager
  - [ ] Lister les fonctionnalitÃ©s actuelles et envisagÃ©es
    - [ ] Recenser les fonctions existantes (harmonisation, gestion, crÃ©ation, modification, suppression, documentation, versioning, orchestration, etc.)
    - [ ] Identifier les besoins futurs (intÃ©gration avancÃ©e, reporting, analyse, etc.)
    - [ ] Prioriser les fonctionnalitÃ©s Ã  dÃ©velopper
  - [ ] DÃ©finir les interactions entre le Mode Manager, les modes, les templates et les outils dâ€™automatisation
    - [ ] Cartographier les flux dâ€™information entre le Mode Manager et chaque mode
    - [ ] DÃ©crire les points dâ€™intÃ©gration avec les templates (crÃ©ation, mise Ã  jour, migration)
    - [ ] Lister les outils dâ€™automatisation concernÃ©s (scripts, CI/CD, snippets, etc.)
    - [ ] Formaliser les API, interfaces ou points dâ€™entrÃ©e nÃ©cessaires
  - [ ] Proposer un plan dâ€™Ã©volution pour faire du Mode Manager un vÃ©ritable assistant central de gestion des modes
    - [ ] DÃ©finir les Ã©tapes dâ€™Ã©volution (MVP, version avancÃ©e, extensions)
    - [ ] SpÃ©cifier les besoins en CLI, API, UI, intÃ©gration CI/CD
    - [ ] PrÃ©voir des modules ou extensions pour lâ€™harmonisation, la migration, la gestion du contexte
    - [ ] Documenter la feuille de route et les jalons de dÃ©veloppement

---

### Prise en compte du contexte et expÃ©rience utilisateur

- [ ] Optimiser la gestion du contexte dans les prompts, modes et outils
  - [ ] Analyser lâ€™importance du contexte dans lâ€™utilisation des modes et du Mode Manager
    - [ ] Identifier les types de contexte pertinents (type de projet, workflow, historique, prÃ©fÃ©rences, environnement technique)
    - [ ] Recueillir les besoins utilisateurs et les cas dâ€™usage oÃ¹ le contexte influence la productivitÃ©
    - [ ] Ã‰valuer lâ€™impact du contexte sur lâ€™automatisation, la gÃ©nÃ©ration de snippets, la navigation et la prise de dÃ©cision
    - [ ] Prioriser les axes dâ€™amÃ©lioration liÃ©s au contexte
  - [ ] AmÃ©liorer les prompts, la documentation et les interfaces pour mieux exploiter le contexte et guider lâ€™utilisateur
    - [ ] Adapter dynamiquement les prompts selon le contexte dÃ©tectÃ©
    - [ ] Ajouter des exemples contextuels dans la documentation
    - [ ] Proposer des suggestions ou complÃ©tions intelligentes selon le contexte
    - [ ] Tester lâ€™ergonomie et la clartÃ© des interfaces enrichies par le contexte
  - [ ] Ã‰tudier la possibilitÃ© dâ€™introduire un systÃ¨me de gestion de contexte partagÃ© ou persistant entre les outils
    - [ ] DÃ©finir les besoins de persistance et de partage du contexte (fichier, base, variables globales)
    - [ ] Prototyper un mÃ©canisme de gestion de contexte partagÃ© (exÂ : fichier de contexte, API, service)
    - [ ] IntÃ©grer ce systÃ¨me dans les outils principaux (modes, Mode Manager, scripts)
    - [ ] Documenter les usages, les limites et les bonnes pratiques pour la gestion du contexte



