# Génère la documentation pour tous les gestionnaires

# Définir les chemins
$projectRoot = "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1"
$managersRoot = Join-Path -Path $projectRoot -ChildPath "development\managers"
$docsRoot = Join-Path -Path $projectRoot -ChildPath "development\docs\guides\methodologies"
$templatePath = Join-Path -Path $docsRoot -ChildPath "manager_documentation_template.md"
$configRoot = Join-Path -Path $projectRoot -ChildPath "projet\config\managers"

# Vérifier que le modèle de documentation existe
if (-not (Test-Path -Path $templatePath -PathType Leaf)) {
    Write-Error "Le modèle de documentation est introuvable : $templatePath"
    exit 1
}

# Lire le contenu du modèle
$templateContent = Get-Content -Path $templatePath -Raw

# Obtenir la liste des gestionnaires
$managers = Get-ChildItem -Path $managersRoot -Directory | Where-Object { $_.Name -like "*-manager" }

# Générer la documentation pour chaque gestionnaire
foreach ($manager in $managers) {
    $managerName = $manager.Name
    $managerDisplayName = ($managerName -replace "-manager", " Manager")
    $firstChar = $managerDisplayName.Substring(0, 1).ToUpper()
    $restOfString = $managerDisplayName.Substring(1)
    $managerDisplayName = $firstChar + $restOfString
    $managerScriptName = $managerName

    # Vérifier si le script principal du gestionnaire existe
    $managerScriptPath = Join-Path -Path $manager.FullName -ChildPath "scripts\$managerScriptName.ps1"
    if (-not (Test-Path -Path $managerScriptPath -PathType Leaf)) {
        Write-Warning "Le script principal du gestionnaire est introuvable : $managerScriptPath"
        continue
    }

    # Définir le chemin du fichier de documentation
    $docFileName = $managerName -replace "-", "_"
    $docPath = Join-Path -Path $docsRoot -ChildPath "$docFileName.md"

    # Créer le contenu de la documentation
    $docContent = $templateContent

    # Remplacer les placeholders
    $docContent = $docContent -replace '\[NOM_DU_GESTIONNAIRE\]', $managerDisplayName
    $docContent = $docContent -replace '\[nom-du-gestionnaire\]', $managerName
    $docContent = $docContent -replace '\[DESCRIPTION_COURTE\]', "gère les fonctionnalités liées à $($managerDisplayName.ToLower())"
    $docContent = $docContent -replace '\[OBJECTIF_PRINCIPAL\]', "fournir des fonctionnalités liées à $($managerDisplayName.ToLower())"

    # Remplacer les fonctionnalités
    $functionalitiesReplacement = "- Gestion des fonctionnalités liées à $($managerDisplayName.ToLower())`n"
    $functionalitiesReplacement += "- Configuration et personnalisation du gestionnaire`n"
    $functionalitiesReplacement += "- Intégration avec d'autres gestionnaires`n"
    $functionalitiesReplacement += "- Journalisation et surveillance des activités"

    $docContent = $docContent -replace '- \[FONCTIONNALITÉ_1\]\s*- \[FONCTIONNALITÉ_2\]\s*- \[FONCTIONNALITÉ_3\]\s*- \[FONCTIONNALITÉ_4\]', $functionalitiesReplacement

    # Remplacer les prérequis
    $docContent = $docContent -replace '1\. \[PRÉREQUIS_1\]\s*2\. \[PRÉREQUIS_2\]\s*3\. \[PRÉREQUIS_3\]', "1. PowerShell 5.1 ou supérieur est installé sur votre système`n2. Le gestionnaire intégré est installé`n3. Les droits d'accès appropriés sont configurés"

    # Remplacer les étapes d'installation manuelle
    $docContent = $docContent -replace '1\. \[ÉTAPE_1\]\s*2\. \[ÉTAPE_2\]\s*3\. \[ÉTAPE_3\]', "1. Copiez les fichiers du gestionnaire dans le répertoire approprié`n2. Créez le fichier de configuration dans le répertoire approprié`n3. Vérifiez que le gestionnaire fonctionne correctement"

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

    # Remplacer les problèmes courants
    $problemsReplacement = "#### Problème 1 : Le gestionnaire ne démarre pas`n`n"
    $problemsReplacement += "**Symptômes :**`n"
    $problemsReplacement += "- Le gestionnaire ne répond pas`n"
    $problemsReplacement += "- Des erreurs s'affichent dans la console`n`n"
    $problemsReplacement += "**Causes possibles :**`n"
    $problemsReplacement += "- Le fichier de configuration est manquant ou corrompu`n"
    $problemsReplacement += "- Les dépendances ne sont pas installées`n`n"
    $problemsReplacement += "**Solutions :**`n"
    $problemsReplacement += "1. Vérifiez que le fichier de configuration existe et est valide`n"
    $problemsReplacement += "2. Installez les dépendances manquantes`n"
    $problemsReplacement += "3. Vérifiez les journaux pour plus d'informations`n`n"

    $problemsReplacement += "#### Problème 2 : Erreurs de permission`n`n"
    $problemsReplacement += "**Symptômes :**`n"
    $problemsReplacement += "- Des erreurs d'accès refusé s'affichent`n"
    $problemsReplacement += "- Le gestionnaire ne peut pas accéder aux fichiers`n`n"
    $problemsReplacement += "**Causes possibles :**`n"
    $problemsReplacement += "- Permissions insuffisantes`n"
    $problemsReplacement += "- Fichiers verrouillés par un autre processus`n`n"
    $problemsReplacement += "**Solutions :**`n"
    $problemsReplacement += "1. Exécutez PowerShell en tant qu'administrateur`n"
    $problemsReplacement += "2. Vérifiez que les fichiers ne sont pas utilisés par un autre processus`n"
    $problemsReplacement += "3. Configurez les permissions appropriées sur les fichiers et répertoires`n`n"

    # Remplacer les sections de problèmes
    $docContent = $docContent -replace '#### Problème 1 : \[TITRE_PROBLÈME_1\].*?#### Problème 2 : \[TITRE_PROBLÈME_2\].*?(?=##)', $problemsReplacement

    # Remplacer les recommandations
    $docContent = $docContent -replace '1\. \[RECOMMANDATION_1\]\s*2\. \[RECOMMANDATION_2\]\s*3\. \[RECOMMANDATION_3\]', "1. Utilisez le gestionnaire intégré pour accéder à ce gestionnaire lorsque c'est possible`n2. Configurez correctement le fichier de configuration avant d'utiliser le gestionnaire`n3. Consultez les journaux en cas de problème"

    # Remplacer les recommandations de sécurité
    $docContent = $docContent -replace '1\. \[RECOMMANDATION_SÉCURITÉ_1\]\s*2\. \[RECOMMANDATION_SÉCURITÉ_2\]\s*3\. \[RECOMMANDATION_SÉCURITÉ_3\]', "1. N'exécutez pas le gestionnaire avec des privilèges administrateur sauf si nécessaire`n2. Protégez l'accès aux fichiers de configuration`n3. Utilisez des mots de passe forts pour les services associés"

    # Remplacer les références
    $docContent = $docContent -replace '- \[RÉFÉRENCE_1\]\s*- \[RÉFÉRENCE_2\]\s*- \[RÉFÉRENCE_3\]', "- [Documentation du gestionnaire intégré](integrated_manager.md)`n- [Documentation du gestionnaire de modes](mode_manager.md)`n- [Guide des bonnes pratiques](../best-practices/powershell_best_practices.md)"

    # Remplacer l'historique des versions
    $today = Get-Date -Format "yyyy-MM-dd"
    $docContent = $docContent -replace '\| 1\.0\.0 \| YYYY-MM-DD \| Version initiale \|\s*\| 1\.1\.0 \| YYYY-MM-DD \| \[DESCRIPTION_CHANGEMENTS\] \|\s*\| 1\.2\.0 \| YYYY-MM-DD \| \[DESCRIPTION_CHANGEMENTS\] \|', "| 1.0.0 | $today | Version initiale |"

    # Écrire le fichier de documentation
    try {
        # Utiliser UTF-8 avec BOM pour assurer la compatibilité avec les caractères spéciaux
        $utf8WithBom = New-Object System.Text.UTF8Encoding $true
        [System.IO.File]::WriteAllText($docPath, $docContent, $utf8WithBom)
        Write-Host "Documentation générée pour $managerDisplayName : $docPath" -ForegroundColor Green
    } catch {
        Write-Error "Erreur lors de l'écriture du fichier de documentation : $docPath"
        Write-Error "Erreur : $_"
    }
}

Write-Host "Génération de la documentation terminée." -ForegroundColor Green
