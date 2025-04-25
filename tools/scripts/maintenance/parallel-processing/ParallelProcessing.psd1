#
# Manifeste de Module pour 'ParallelProcessing'
#
# Généré par : [Votre Nom ou Nom d'Équipe]
# Date de génération : [Date Actuelle, ex: 2024-05-21]
#
# Ce fichier définit les métadonnées et la configuration du module PowerShell.
# Remplissez les sections marquées [À METTRE À JOUR] avec vos informations spécifiques.
#

@{

    # --- Identification et Versioning ---

    # Module principal (fichier .psm1) ou module binaire (.dll) associé à ce manifeste.
    RootModule = 'ParallelProcessing.psm1'

    # Version sémantique (Majeur.Mineur.Patch) de ce module. Incrémentez selon les règles SemVer.
    ModuleVersion = '1.0.0' # Version initiale, ou mettez à jour si nécessaire

    # Identifiant unique global (GUID) pour ce module.
    # Générez un NOUVEAU GUID avec `New-Guid` si vous créez ou copiez ce module. Ne réutilisez pas ce GUID exact.
    GUID = '8f7b1c9a-5b4a-4e3d-8c7d-9e1f2b3a4c5d' # [À METTRE À JOUR] Générez un nouveau GUID !

    # --- Auteur et Informations Légales ---

    # Auteur(s) de ce module.
    Author = '[Votre Nom ou Nom d''Équipe]' # [À METTRE À JOUR]

    # Entreprise ou organisation (si applicable).
    CompanyName = '[Votre Entreprise ou Organisation]' # [À METTRE À JOUR] (Optionnel)

    # Déclaration de copyright. Mettez à jour l'année et le détenteur.
    Copyright = '(c) 2024 [Votre Nom ou Entreprise]. Tous droits réservés.' # [À METTRE À JOUR]

    # --- Description et Compatibilité ---

    # Description courte et claire des fonctionnalités fournies par ce module.
    Description = 'Fournit des fonctions PowerShell pour exécuter des traitements parallèles hautes performances en utilisant des Runspace Pools optimisés. Conçu pour être robuste et efficace, particulièrement pour PowerShell 5.1+.'

    # Éditions de PowerShell supportées. 'Desktop' (Windows PowerShell) et 'Core' (PowerShell 6+).
    # Étant donné que les Runspace Pools fonctionnent sur les deux, c'est une bonne valeur par défaut.
    CompatiblePSEditions = @('Desktop', 'Core')

    # Version minimale requise du moteur PowerShell. 5.1 est une base solide pour ce type de module.
    PowerShellVersion = '5.1'

    # Version minimale requise de Microsoft .NET Framework (pour l'édition 'Desktop' uniquement).
    # PowerShell 5.1 requiert techniquement .NET 4.5.2 ou plus récent. 4.5.2 est une valeur sûre.
    DotNetFrameworkVersion = '4.5.2'

    # Version minimale requise du Common Language Runtime (CLR) (pour l'édition 'Desktop' uniquement).
    CLRVersion = '4.0' # Correspond à .NET Framework 4.x

    # --- Dépendances (Généralement vides pour les modules de script simples) ---

    # Modules qui doivent être importés AVANT celui-ci.
    # RequiredModules = @()

    # Assemblies (.dll) qui doivent être chargés AVANT celui-ci.
    # RequiredAssemblies = @()

    # Fichiers de script (.ps1) à exécuter dans la portée de l'appelant AVANT l'importation. À utiliser avec prudence.
    # ScriptsToProcess = @()

    # Fichiers de types (.ps1xml) à charger lors de l'importation.
    # TypesToProcess = @()

    # Fichiers de formatage (.ps1xml) à charger lors de l'importation.
    # FormatsToProcess = @()

    # Modules à importer comme modules imbriqués.
    # NestedModules = @()

    # --- Exports (TRÈS IMPORTANT pour la performance et l'isolation) ---

    # Liste explicite des fonctions à exporter. N'utilisez PAS de jokers (*).
    # Exportez SEULEMENT les fonctions destinées à l'utilisateur final.
    FunctionsToExport = @(
        'Invoke-OptimizedParallel'
        # Ajoutez ici d'autres fonctions *publiques* si nécessaire.
        # 'Invoke-ParallelScriptAnalysis', # Exemple si elle devient publique
        # 'Invoke-ParallelScriptCorrection' # Exemple si elle devient publique
    )

    # Liste des cmdlets à exporter (vide pour un module de script).
    CmdletsToExport = @()

    # Liste des variables à exporter. **NE PAS utiliser '*'**. Exportez uniquement si absolument nécessaire.
    # La meilleure pratique est de ne rien exporter.
    VariablesToExport = @()

    # Liste des alias à exporter. La meilleure pratique est de ne rien exporter.
    AliasesToExport = @()

    # Ressources DSC à exporter (si applicable).
    # DscResourcesToExport = @()

    # --- Fichiers et Données Privées ---

    # Liste de tous les modules inclus dans ce package (pour les modules complexes).
    # ModuleList = @()

    # Liste de tous les fichiers inclus dans ce package (peut aider au packaging).
    # FileList = @()

    # Données privées passées au module. Contient souvent des métadonnées PSData pour les galeries.
    PrivateData = @{

        PSData = @{

            # Mots-clés pour la découverte du module (ex: PowerShell Gallery).
            Tags = @('Parallel', 'Concurrency', 'Threading', 'Runspace', 'Performance', 'Optimization', 'PowerShell5.1', 'Core')

            # URL vers la licence du module (ex: lien vers le fichier LICENSE sur GitHub).
            LicenseUri = 'https://[URL_VERS_VOTRE_LICENCE]' # [À METTRE À JOUR] (Ex: MIT, Apache 2.0)

            # URL vers le site principal du projet (ex: dépôt GitHub/GitLab).
            ProjectUri = 'https://[URL_VERS_VOTRE_PROJET]' # [À METTRE À JOUR]

            # URL vers une icône pour le module (affichée dans certaines galeries/outils).
            IconUri = 'https://[URL_VERS_VOTRE_ICONE]' # [À METTRE À JOUR] (Optionnel)

            # Notes de version pour cette version spécifique du module.
            ReleaseNotes = @'
Version 1.0.0 (2024-05-21):
- Version initiale du module.
- Introduction de la fonction Invoke-OptimizedParallel pour l'exécution parallèle basée sur Runspace Pools.
- Optimisé pour PowerShell 5.1 et supérieur.
- Gestion robuste des erreurs et sortie détaillée par élément.
'@ # [À METTRE À JOUR] pour chaque nouvelle version

        } # Fin de PSData

        # Vous pouvez ajouter ici d'autres données privées si votre module en a besoin.
        # Par exemple, des configurations internes par défaut.

    } # Fin de PrivateData

    # --- Aide et Préfixe ---

    # URI vers un fichier HelpInfo XML pour l'aide actualisable (Updatable Help).
    # HelpInfoURI = ''

    # Préfixe par défaut pour les commandes exportées (généralement non défini).
    # DefaultCommandPrefix = ''

}