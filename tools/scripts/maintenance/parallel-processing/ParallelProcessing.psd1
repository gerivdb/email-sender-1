#
# Manifeste de Module pour 'ParallelProcessing'
#
# GÃ©nÃ©rÃ© par : [Votre Nom ou Nom d'Ã‰quipe]
# Date de gÃ©nÃ©ration : [Date Actuelle, ex: 2024-05-21]
#
# Ce fichier dÃ©finit les mÃ©tadonnÃ©es et la configuration du module PowerShell.
# Remplissez les sections marquÃ©es [Ã€ METTRE Ã€ JOUR] avec vos informations spÃ©cifiques.
#

@{

    # --- Identification et Versioning ---

    # Module principal (fichier .psm1) ou module binaire (.dll) associÃ© Ã  ce manifeste.
    RootModule = 'ParallelProcessing.psm1'

    # Version sÃ©mantique (Majeur.Mineur.Patch) de ce module. IncrÃ©mentez selon les rÃ¨gles SemVer.
    ModuleVersion = '1.0.0' # Version initiale, ou mettez Ã  jour si nÃ©cessaire

    # Identifiant unique global (GUID) pour ce module.
    # GÃ©nÃ©rez un NOUVEAU GUID avec `New-Guid` si vous crÃ©ez ou copiez ce module. Ne rÃ©utilisez pas ce GUID exact.
    GUID = '8f7b1c9a-5b4a-4e3d-8c7d-9e1f2b3a4c5d' # [Ã€ METTRE Ã€ JOUR] GÃ©nÃ©rez un nouveau GUID !

    # --- Auteur et Informations LÃ©gales ---

    # Auteur(s) de ce module.
    Author = '[Votre Nom ou Nom d''Ã‰quipe]' # [Ã€ METTRE Ã€ JOUR]

    # Entreprise ou organisation (si applicable).
    CompanyName = '[Votre Entreprise ou Organisation]' # [Ã€ METTRE Ã€ JOUR] (Optionnel)

    # DÃ©claration de copyright. Mettez Ã  jour l'annÃ©e et le dÃ©tenteur.
    Copyright = '(c) 2024 [Votre Nom ou Entreprise]. Tous droits rÃ©servÃ©s.' # [Ã€ METTRE Ã€ JOUR]

    # --- Description et CompatibilitÃ© ---

    # Description courte et claire des fonctionnalitÃ©s fournies par ce module.
    Description = 'Fournit des fonctions PowerShell pour exÃ©cuter des traitements parallÃ¨les hautes performances en utilisant des Runspace Pools optimisÃ©s. ConÃ§u pour Ãªtre robuste et efficace, particuliÃ¨rement pour PowerShell 5.1+.'

    # Ã‰ditions de PowerShell supportÃ©es. 'Desktop' (Windows PowerShell) et 'Core' (PowerShell 6+).
    # Ã‰tant donnÃ© que les Runspace Pools fonctionnent sur les deux, c'est une bonne valeur par dÃ©faut.
    CompatiblePSEditions = @('Desktop', 'Core')

    # Version minimale requise du moteur PowerShell. 5.1 est une base solide pour ce type de module.
    PowerShellVersion = '5.1'

    # Version minimale requise de Microsoft .NET Framework (pour l'Ã©dition 'Desktop' uniquement).
    # PowerShell 5.1 requiert techniquement .NET 4.5.2 ou plus rÃ©cent. 4.5.2 est une valeur sÃ»re.
    DotNetFrameworkVersion = '4.5.2'

    # Version minimale requise du Common Language Runtime (CLR) (pour l'Ã©dition 'Desktop' uniquement).
    CLRVersion = '4.0' # Correspond Ã  .NET Framework 4.x

    # --- DÃ©pendances (GÃ©nÃ©ralement vides pour les modules de script simples) ---

    # Modules qui doivent Ãªtre importÃ©s AVANT celui-ci.
    # RequiredModules = @()

    # Assemblies (.dll) qui doivent Ãªtre chargÃ©s AVANT celui-ci.
    # RequiredAssemblies = @()

    # Fichiers de script (.ps1) Ã  exÃ©cuter dans la portÃ©e de l'appelant AVANT l'importation. Ã€ utiliser avec prudence.
    # ScriptsToProcess = @()

    # Fichiers de types (.ps1xml) Ã  charger lors de l'importation.
    # TypesToProcess = @()

    # Fichiers de formatage (.ps1xml) Ã  charger lors de l'importation.
    # FormatsToProcess = @()

    # Modules Ã  importer comme modules imbriquÃ©s.
    # NestedModules = @()

    # --- Exports (TRÃˆS IMPORTANT pour la performance et l'isolation) ---

    # Liste explicite des fonctions Ã  exporter. N'utilisez PAS de jokers (*).
    # Exportez SEULEMENT les fonctions destinÃ©es Ã  l'utilisateur final.
    FunctionsToExport = @(
        'Invoke-OptimizedParallel'
        # Ajoutez ici d'autres fonctions *publiques* si nÃ©cessaire.
        # 'Invoke-ParallelScriptAnalysis', # Exemple si elle devient publique
        # 'Invoke-ParallelScriptCorrection' # Exemple si elle devient publique
    )

    # Liste des cmdlets Ã  exporter (vide pour un module de script).
    CmdletsToExport = @()

    # Liste des variables Ã  exporter. **NE PAS utiliser '*'**. Exportez uniquement si absolument nÃ©cessaire.
    # La meilleure pratique est de ne rien exporter.
    VariablesToExport = @()

    # Liste des alias Ã  exporter. La meilleure pratique est de ne rien exporter.
    AliasesToExport = @()

    # Ressources DSC Ã  exporter (si applicable).
    # DscResourcesToExport = @()

    # --- Fichiers et DonnÃ©es PrivÃ©es ---

    # Liste de tous les modules inclus dans ce package (pour les modules complexes).
    # ModuleList = @()

    # Liste de tous les fichiers inclus dans ce package (peut aider au packaging).
    # FileList = @()

    # DonnÃ©es privÃ©es passÃ©es au module. Contient souvent des mÃ©tadonnÃ©es PSData pour les galeries.
    PrivateData = @{

        PSData = @{

            # Mots-clÃ©s pour la dÃ©couverte du module (ex: PowerShell Gallery).
            Tags = @('Parallel', 'Concurrency', 'Threading', 'Runspace', 'Performance', 'Optimization', 'PowerShell5.1', 'Core')

            # URL vers la licence du module (ex: lien vers le fichier LICENSE sur GitHub).
            LicenseUri = 'https://[URL_VERS_VOTRE_LICENCE]' # [Ã€ METTRE Ã€ JOUR] (Ex: MIT, Apache 2.0)

            # URL vers le site principal du projet (ex: dÃ©pÃ´t GitHub/GitLab).
            ProjectUri = 'https://[URL_VERS_VOTRE_PROJET]' # [Ã€ METTRE Ã€ JOUR]

            # URL vers une icÃ´ne pour le module (affichÃ©e dans certaines galeries/outils).
            IconUri = 'https://[URL_VERS_VOTRE_ICONE]' # [Ã€ METTRE Ã€ JOUR] (Optionnel)

            # Notes de version pour cette version spÃ©cifique du module.
            ReleaseNotes = @'
Version 1.0.0 (2024-05-21):
- Version initiale du module.
- Introduction de la fonction Invoke-OptimizedParallel pour l'exÃ©cution parallÃ¨le basÃ©e sur Runspace Pools.
- OptimisÃ© pour PowerShell 5.1 et supÃ©rieur.
- Gestion robuste des erreurs et sortie dÃ©taillÃ©e par Ã©lÃ©ment.
'@ # [Ã€ METTRE Ã€ JOUR] pour chaque nouvelle version

        } # Fin de PSData

        # Vous pouvez ajouter ici d'autres donnÃ©es privÃ©es si votre module en a besoin.
        # Par exemple, des configurations internes par dÃ©faut.

    } # Fin de PrivateData

    # --- Aide et PrÃ©fixe ---

    # URI vers un fichier HelpInfo XML pour l'aide actualisable (Updatable Help).
    # HelpInfoURI = ''

    # PrÃ©fixe par dÃ©faut pour les commandes exportÃ©es (gÃ©nÃ©ralement non dÃ©fini).
    # DefaultCommandPrefix = ''

}