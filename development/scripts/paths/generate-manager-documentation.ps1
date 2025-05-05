# GÃ©nÃ¨re la documentation pour tous les gestionnaires

# DÃ©finir les chemins
$projectRoot = "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1"
$managersRoot = Join-Path -Path $projectRoot -ChildPath "development\managers"
$docsRoot = Join-Path -Path $projectRoot -ChildPath "development\docs\guides\methodologies"
$templatePath = Join-Path -Path $docsRoot -ChildPath "manager_documentation_template.md"
$configRoot = Join-Path -Path $projectRoot -ChildPath "projet\config\managers"

# VÃ©rifier que le modÃ¨le de documentation existe
if (-not (Test-Path -Path $templatePath -PathType Leaf)) {
    Write-Error "Le modÃ¨le de documentation est introuvable : $templatePath"
    exit 1
}

# Lire le contenu du modÃ¨le
$templateContent = Get-Content -Path $templatePath -Raw

# Obtenir la liste des gestionnaires
$managers = Get-ChildItem -Path $managersRoot -Directory | Where-Object { $_.Name -like "*-manager" }

# GÃ©nÃ©rer la documentation pour chaque gestionnaire
foreach ($manager in $managers) {
    $managerName = $manager.Name
    $managerDisplayName = ($managerName -replace "-manager", " Manager")
    $firstChar = $managerDisplayName.Substring(0, 1).ToUpper()
    $restOfString = $managerDisplayName.Substring(1)
    $managerDisplayName = $firstChar + $restOfString
    $managerScriptName = $managerName

    # VÃ©rifier si le script principal du gestionnaire existe
    $managerScriptPath = Join-Path -Path $manager.FullName -ChildPath "scripts\$managerScriptName.ps1"
    if (-not (Test-Path -Path $managerScriptPath -PathType Leaf)) {
        Write-Warning "Le script principal du gestionnaire est introuvable : $managerScriptPath"
        continue
    }

    # DÃ©finir le chemin du fichier de documentation
    $docFileName = $managerName -replace "-", "_"
    $docPath = Join-Path -Path $docsRoot -ChildPath "$docFileName.md"

    # CrÃ©er le contenu de la documentation
    $docContent = $templateContent

    # Remplacer les placeholders
    $docContent = $docContent -replace '\[NOM_DU_GESTIONNAIRE\]', $managerDisplayName
    $docContent = $docContent -replace '\[nom-du-gestionnaire\]', $managerName
    $docContent = $docContent -replace '\[DESCRIPTION_COURTE\]', "gÃ¨re les fonctionnalitÃ©s liÃ©es Ã  $($managerDisplayName.ToLower())"
    $docContent = $docContent -replace '\[OBJECTIF_PRINCIPAL\]', "fournir des fonctionnalitÃ©s liÃ©es Ã  $($managerDisplayName.ToLower())"

    # Remplacer les fonctionnalitÃ©s
    $functionalitiesReplacement = "- Gestion des fonctionnalitÃ©s liÃ©es Ã  $($managerDisplayName.ToLower())`n"
    $functionalitiesReplacement += "- Configuration et personnalisation du gestionnaire`n"
    $functionalitiesReplacement += "- IntÃ©gration avec d'autres gestionnaires`n"
    $functionalitiesReplacement += "- Journalisation et surveillance des activitÃ©s"

    $docContent = $docContent -replace '- \[FONCTIONNALITÃ‰_1\]\s*- \[FONCTIONNALITÃ‰_2\]\s*- \[FONCTIONNALITÃ‰_3\]\s*- \[FONCTIONNALITÃ‰_4\]', $functionalitiesReplacement

    # Remplacer les prÃ©requis
    $docContent = $docContent -replace '1\. \[PRÃ‰REQUIS_1\]\s*2\. \[PRÃ‰REQUIS_2\]\s*3\. \[PRÃ‰REQUIS_3\]', "1. PowerShell 5.1 ou supÃ©rieur est installÃ© sur votre systÃ¨me`n2. Le gestionnaire intÃ©grÃ© est installÃ©`n3. Les droits d'accÃ¨s appropriÃ©s sont configurÃ©s"

    # Remplacer les Ã©tapes d'installation manuelle
    $docContent = $docContent -replace '1\. \[Ã‰TAPE_1\]\s*2\. \[Ã‰TAPE_2\]\s*3\. \[Ã‰TAPE_3\]', "1. Copiez les fichiers du gestionnaire dans le rÃ©pertoire appropriÃ©`n2. CrÃ©ez le fichier de configuration dans le rÃ©pertoire appropriÃ©`n3. VÃ©rifiez que le gestionnaire fonctionne correctement"

    # Remplacer les commandes
    $commandsReplacement = "#### Commande 1 : Help`n`n"
    $commandsReplacement += "```powershell`n"
    $commandsReplacement += ".\development\managers\$managerName\scripts\$managerScriptName.ps1 -Help`n"
    $commandsReplacement += "```\n\n"
    $commandsReplacement += "**Description :** Affiche l'aide du gestionnaire`n`n"
    $commandsReplacement += "**Exemple :**`n"
    $commandsReplacement += "```powershell`n"
    $commandsReplacement += ".\development\managers\$managerName\scripts\$managerScriptName.ps1 -Help`n"
    $commandsReplacement += "```\n\n"

    $commandsReplacement += "#### Commande 2 : Version`n`n"
    $commandsReplacement += "```powershell`n"
    $commandsReplacement += ".\development\managers\$managerName\scripts\$managerScriptName.ps1 -Version`n"
    $commandsReplacement += "```\n\n"
    $commandsReplacement += "**Description :** Affiche la version du gestionnaire`n`n"
    $commandsReplacement += "**Exemple :**`n"
    $commandsReplacement += "```powershell`n"
    $commandsReplacement += ".\development\managers\$managerName\scripts\$managerScriptName.ps1 -Version`n"
    $commandsReplacement += "```\n\n"

    # Remplacer les sections de commandes
    $docContent = $docContent -replace '#### Commande 1 : \[NOM_COMMANDE_1\].*?#### Commande 2 : \[NOM_COMMANDE_2\].*?```powershell.*?```', $commandsReplacement

    # Remplacer les exemples
    $examplesReplacement = "#### Exemple 1 : Utilisation basique`n`n"
    $examplesReplacement += "```powershell`n"
    $examplesReplacement += "# Utilisation basique du gestionnaire`n"
    $examplesReplacement += ".\development\managers\$managerName\scripts\$managerScriptName.ps1 -Help`n"
    $examplesReplacement += "```\n\n"

    $examplesReplacement += "#### Exemple 2 : Affichage de la version`n`n"
    $examplesReplacement += "```powershell`n"
    $examplesReplacement += "# Afficher la version du gestionnaire`n"
    $examplesReplacement += ".\development\managers\$managerName\scripts\$managerScriptName.ps1 -Version`n"
    $examplesReplacement += "```\n\n"

    # Remplacer les sections d'exemples
    $docContent = $docContent -replace '#### Exemple 1 : \[TITRE_EXEMPLE_1\].*?#### Exemple 2 : \[TITRE_EXEMPLE_2\].*?```powershell.*?```', $examplesReplacement

    # Remplacer les problÃ¨mes courants
    $problemsReplacement = "#### ProblÃ¨me 1 : Le gestionnaire ne dÃ©marre pas`n`n"
    $problemsReplacement += "**SymptÃ´mes :**`n"
    $problemsReplacement += "- Le gestionnaire ne rÃ©pond pas`n"
    $problemsReplacement += "- Des erreurs s'affichent dans la console`n`n"
    $problemsReplacement += "**Causes possibles :**`n"
    $problemsReplacement += "- Le fichier de configuration est manquant ou corrompu`n"
    $problemsReplacement += "- Les dÃ©pendances ne sont pas installÃ©es`n`n"
    $problemsReplacement += "**Solutions :**`n"
    $problemsReplacement += "1. VÃ©rifiez que le fichier de configuration existe et est valide`n"
    $problemsReplacement += "2. Installez les dÃ©pendances manquantes`n"
    $problemsReplacement += "3. VÃ©rifiez les journaux pour plus d'informations`n`n"

    $problemsReplacement += "#### ProblÃ¨me 2 : Erreurs de permission`n`n"
    $problemsReplacement += "**SymptÃ´mes :**`n"
    $problemsReplacement += "- Des erreurs d'accÃ¨s refusÃ© s'affichent`n"
    $problemsReplacement += "- Le gestionnaire ne peut pas accÃ©der aux fichiers`n`n"
    $problemsReplacement += "**Causes possibles :**`n"
    $problemsReplacement += "- Permissions insuffisantes`n"
    $problemsReplacement += "- Fichiers verrouillÃ©s par un autre processus`n`n"
    $problemsReplacement += "**Solutions :**`n"
    $problemsReplacement += "1. ExÃ©cutez PowerShell en tant qu'administrateur`n"
    $problemsReplacement += "2. VÃ©rifiez que les fichiers ne sont pas utilisÃ©s par un autre processus`n"
    $problemsReplacement += "3. Configurez les permissions appropriÃ©es sur les fichiers et rÃ©pertoires`n`n"

    # Remplacer les sections de problÃ¨mes
    $docContent = $docContent -replace '#### ProblÃ¨me 1 : \[TITRE_PROBLÃˆME_1\].*?#### ProblÃ¨me 2 : \[TITRE_PROBLÃˆME_2\].*?(?=##)', $problemsReplacement

    # Remplacer les recommandations
    $docContent = $docContent -replace '1\. \[RECOMMANDATION_1\]\s*2\. \[RECOMMANDATION_2\]\s*3\. \[RECOMMANDATION_3\]', "1. Utilisez le gestionnaire intÃ©grÃ© pour accÃ©der Ã  ce gestionnaire lorsque c'est possible`n2. Configurez correctement le fichier de configuration avant d'utiliser le gestionnaire`n3. Consultez les journaux en cas de problÃ¨me"

    # Remplacer les recommandations de sÃ©curitÃ©
    $docContent = $docContent -replace '1\. \[RECOMMANDATION_SÃ‰CURITÃ‰_1\]\s*2\. \[RECOMMANDATION_SÃ‰CURITÃ‰_2\]\s*3\. \[RECOMMANDATION_SÃ‰CURITÃ‰_3\]', "1. N'exÃ©cutez pas le gestionnaire avec des privilÃ¨ges administrateur sauf si nÃ©cessaire`n2. ProtÃ©gez l'accÃ¨s aux fichiers de configuration`n3. Utilisez des mots de passe forts pour les services associÃ©s"

    # Remplacer les rÃ©fÃ©rences
    $docContent = $docContent -replace '- \[RÃ‰FÃ‰RENCE_1\]\s*- \[RÃ‰FÃ‰RENCE_2\]\s*- \[RÃ‰FÃ‰RENCE_3\]', "- [Documentation du gestionnaire intÃ©grÃ©](integrated_manager.md)`n- [Documentation du gestionnaire de modes](mode_manager.md)`n- [Guide des bonnes pratiques](../best-practices/powershell_best_practices.md)"

    # Remplacer l'historique des versions
    $today = Get-Date -Format "yyyy-MM-dd"
    $docContent = $docContent -replace '\| 1\.0\.0 \| YYYY-MM-DD \| Version initiale \|\s*\| 1\.1\.0 \| YYYY-MM-DD \| \[DESCRIPTION_CHANGEMENTS\] \|\s*\| 1\.2\.0 \| YYYY-MM-DD \| \[DESCRIPTION_CHANGEMENTS\] \|', "| 1.0.0 | $today | Version initiale |"

    # Ã‰crire le fichier de documentation
    try {
        # Utiliser UTF-8 avec BOM pour assurer la compatibilitÃ© avec les caractÃ¨res spÃ©ciaux
        $utf8WithBom = New-Object System.Text.UTF8Encoding $true
        [System.IO.File]::WriteAllText($docPath, $docContent, $utf8WithBom)
        Write-Host "Documentation gÃ©nÃ©rÃ©e pour $managerDisplayName : $docPath" -ForegroundColor Green
    } catch {
        Write-Error "Erreur lors de l'Ã©criture du fichier de documentation : $docPath"
        Write-Error "Erreur : $_"
    }
}

Write-Host "GÃ©nÃ©ration de la documentation terminÃ©e." -ForegroundColor Green
