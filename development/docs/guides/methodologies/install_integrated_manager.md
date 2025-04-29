# Guide d'installation du Gestionnaire Intégré

## Introduction

Le script `install-integrated-manager.ps1` est un outil essentiel pour installer et configurer le Gestionnaire Intégré dans votre projet. Ce guide détaille son fonctionnement, ses paramètres, et fournit des exemples d'utilisation pour vous aider à l'utiliser efficacement.

## Objectif

L'objectif principal du script `install-integrated-manager.ps1` est de faciliter l'installation et la configuration du Gestionnaire Intégré en :

- Copiant les fichiers nécessaires aux emplacements appropriés
- Créant les répertoires requis s'ils n'existent pas
- Établissant des liens symboliques pour un accès facile depuis différents emplacements
- Vérifiant que l'installation s'est déroulée correctement

## Prérequis

Avant d'utiliser le script d'installation, assurez-vous que :

1. PowerShell 5.1 ou supérieur est installé sur votre système
2. Vous disposez des droits d'administrateur si vous souhaitez créer des liens symboliques
3. Le script `integrated-manager.ps1` est disponible dans le même répertoire que le script d'installation

## Paramètres

Le script `install-integrated-manager.ps1` accepte les paramètres suivants :

| Paramètre | Type | Description | Obligatoire | Valeur par défaut |
|-----------|------|-------------|-------------|-------------------|
| ProjectRoot | string | Chemin vers la racine du projet où installer le Gestionnaire Intégré | Non | Répertoire courant (avec détection automatique du répertoire Git) |
| Force | switch | Indique si les fichiers existants doivent être écrasés | Non | $false |

### Détails des paramètres

#### ProjectRoot

Le paramètre `ProjectRoot` spécifie le répertoire racine du projet où le Gestionnaire Intégré sera installé. Si ce paramètre n'est pas fourni, le script tentera de détecter automatiquement la racine du projet en recherchant un répertoire `.git`.

**Comportement de détection automatique :**
1. Si `ProjectRoot` est défini comme "." (valeur par défaut), le script utilise le répertoire courant
2. Le script remonte ensuite dans l'arborescence des répertoires jusqu'à trouver un répertoire `.git`
3. Si aucun répertoire `.git` n'est trouvé, le répertoire courant est utilisé comme racine du projet

**Exemples de valeurs valides :**
- `"D:\MonProjet"`
- `"C:\Users\Utilisateur\Documents\Projets\MonProjet"`
- `"..\MonAutreProjet"`
- `"."` (répertoire courant)

**Contraintes :**
- Le répertoire spécifié doit exister
- Le chemin peut être absolu ou relatif

#### Force

Le paramètre `Force` est un commutateur (switch) qui indique si les fichiers existants doivent être écrasés lors de l'installation. Par défaut, le script ne remplace pas les fichiers existants et affiche un avertissement.

**Comportement :**
- Si `Force` est spécifié (`-Force`), tous les fichiers existants seront remplacés sans confirmation
- Si `Force` n'est pas spécifié, les fichiers existants ne seront pas modifiés et un avertissement sera affiché

**Cas d'utilisation :**
- Utilisez `-Force` lors d'une réinstallation ou d'une mise à jour du Gestionnaire Intégré
- Omettez `-Force` lors d'une première installation ou si vous souhaitez préserver les fichiers personnalisés

## Fonctionnement détaillé

Le script `install-integrated-manager.ps1` effectue les opérations suivantes :

### 1. Détermination du répertoire du projet

Le script détermine d'abord le répertoire racine du projet en utilisant le paramètre `ProjectRoot` ou en détectant automatiquement un répertoire Git.

```powershell
# Déterminer le chemin du projet
if ($ProjectRoot -eq ".") {
    $ProjectRoot = $PWD.Path
    
    # Remonter jusqu'à trouver le répertoire .git
    while (-not (Test-Path -Path (Join-Path -Path $ProjectRoot -ChildPath ".git") -PathType Container) -and 
           -not [string]::IsNullOrEmpty($ProjectRoot)) {
        $ProjectRoot = Split-Path -Path $ProjectRoot -Parent
    }
    
    if ([string]::IsNullOrEmpty($ProjectRoot) -or -not (Test-Path -Path (Join-Path -Path $ProjectRoot -ChildPath ".git") -PathType Container)) {
        $ProjectRoot = $PWD.Path
    }
}
```

### 2. Vérification des fichiers source

Le script vérifie ensuite que les fichiers source nécessaires existent :

```powershell
# Chemins des fichiers source
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$integratedManagerScript = Join-Path -Path $scriptPath -ChildPath "integrated-manager.ps1"
$integratedManagerDoc = Join-Path -Path $ProjectRoot -ChildPath "development\docs\guides\methodologies\integrated_manager.md"
$unifiedConfigJson = Join-Path -Path $ProjectRoot -ChildPath "development\config\unified-config.json"

# Vérifier que les fichiers source existent
if (-not (Test-Path -Path $integratedManagerScript)) {
    Write-Error "Le script du gestionnaire intégré est introuvable : $integratedManagerScript"
    exit 1
}
```

### 3. Création des répertoires nécessaires

Le script crée ensuite les répertoires nécessaires s'ils n'existent pas :

```powershell
# Créer les répertoires nécessaires
$directories = @(
    "development\config",
    "development\docs\guides\methodologies",
    "tools\scripts",
    "scripts"
)

foreach ($directory in $directories) {
    $dirPath = Join-Path -Path $ProjectRoot -ChildPath $directory
    if (-not (Test-Path -Path $dirPath -PathType Container)) {
        Write-Host "Création du répertoire : $dirPath" -ForegroundColor Green
        New-Item -Path $dirPath -ItemType Directory -Force | Out-Null
    }
}
```

### 4. Copie des fichiers

Le script copie ensuite les fichiers nécessaires aux emplacements appropriés :

```powershell
# Copier les fichiers
$filesToCopy = @{
    $integratedManagerScript = Join-Path -Path $ProjectRoot -ChildPath "development\\managers\\integrated-manager\\scripts\\integrated-manager\.ps1"
    $integratedManagerDoc = Join-Path -Path $ProjectRoot -ChildPath "development\docs\guides\methodologies\integrated_manager.md"
    $unifiedConfigJson = Join-Path -Path $ProjectRoot -ChildPath "development\config\unified-config.json"
}

foreach ($source in $filesToCopy.Keys) {
    $destination = $filesToCopy[$source]
    
    if (Test-Path -Path $source) {
        if ((Test-Path -Path $destination) -and -not $Force) {
            Write-Warning "Le fichier existe déjà et ne sera pas écrasé : $destination"
        } else {
            Write-Host "Copie du fichier : $source -> $destination" -ForegroundColor Green
            Copy-Item -Path $source -Destination $destination -Force
        }
    } else {
        Write-Warning "Le fichier source est introuvable : $source"
    }
}
```

### 5. Création des liens symboliques

Le script crée des liens symboliques pour faciliter l'accès au Gestionnaire Intégré depuis différents emplacements :

```powershell
# Créer les liens symboliques
foreach ($link in $linkPaths.Keys) {
    $linkPath = Join-Path -Path $ProjectRoot -ChildPath $link
    $targetPath = $linkPaths[$link]
    
    if ((Test-Path -Path $linkPath) -and -not $Force) {
        Write-Warning "Le lien existe déjà et ne sera pas écrasé : $linkPath"
    } else {
        if (Test-Path -Path $linkPath) {
            Remove-Item -Path $linkPath -Force
        }
        
        try {
            # Créer un lien symbolique si possible
            if ($PSVersionTable.PSVersion.Major -ge 5) {
                Write-Host "Création du lien symbolique : $linkPath -> $targetPath" -ForegroundColor Green
                New-Item -Path $linkPath -ItemType SymbolicLink -Target $targetPath -Force | Out-Null
            } else {
                # Sinon, créer un fichier de redirection
                Write-Host "Création du fichier de redirection : $linkPath -> $targetPath" -ForegroundColor Green
                @"
# Ce fichier est une redirection vers le script du gestionnaire intégré
# Le script réel se trouve à l'emplacement : $targetPath

# Rediriger vers le script réel
& "$targetPath" @args
"@ | Set-Content -Path $linkPath -Encoding UTF8
            }
        } catch {
            Write-Warning "Impossible de créer le lien symbolique : $linkPath -> $targetPath"
            Write-Warning "Erreur : $_"
            
            # Créer un fichier de redirection en cas d'échec
            Write-Host "Création du fichier de redirection : $linkPath -> $targetPath" -ForegroundColor Green
            @"
# Ce fichier est une redirection vers le script du gestionnaire intégré
# Le script réel se trouve à l'emplacement : $targetPath

# Rediriger vers le script réel
& "$targetPath" @args
"@ | Set-Content -Path $linkPath -Encoding UTF8
        }
    }
}
```

### 6. Création d'un raccourci dans le dossier principal

Le script crée également un raccourci dans le dossier principal pour un accès facile :

```powershell
# Créer un raccourci dans le dossier principal
$shortcutPath = Join-Path -Path $ProjectRoot -ChildPath "integrated-manager.ps1"
if ((Test-Path -Path $shortcutPath) -and -not $Force) {
    Write-Warning "Le raccourci existe déjà et ne sera pas écrasé : $shortcutPath"
} else {
    Write-Host "Création du raccourci : $shortcutPath" -ForegroundColor Green
    @"
# Ce fichier est un raccourci vers le script du gestionnaire intégré
# Le script réel se trouve à l'emplacement : development\\managers\\integrated-manager\\scripts\\integrated-manager\.ps1

# Rediriger vers le script réel
& "development\\managers\\integrated-manager\\scripts\\integrated-manager\.ps1" @args
"@ | Set-Content -Path $shortcutPath -Encoding UTF8
}
```

### 7. Vérification de l'installation

Enfin, le script vérifie que tous les fichiers ont été correctement installés :

```powershell
# Vérifier que les fichiers ont été correctement installés
$filesToCheck = @(
    "development\\managers\\integrated-manager\\scripts\\integrated-manager\.ps1",
    "development\docs\guides\methodologies\integrated_manager.md",
    "development\config\unified-config.json",
    "tools\scripts\integrated-manager.ps1",
    "scripts\integrated-manager.ps1",
    "integrated-manager.ps1"
)

$allFilesExist = $true
foreach ($file in $filesToCheck) {
    $filePath = Join-Path -Path $ProjectRoot -ChildPath $file
    if (-not (Test-Path -Path $filePath)) {
        Write-Warning "Le fichier n'a pas été correctement installé : $filePath"
        $allFilesExist = $false
    }
}

if ($allFilesExist) {
    Write-Host "Le gestionnaire intégré a été installé avec succès !" -ForegroundColor Green
    Write-Host "Pour l'utiliser, exécutez :" -ForegroundColor Cyan
    Write-Host "  - Depuis le dossier principal : .\integrated-manager.ps1" -ForegroundColor Cyan
    Write-Host "  - Depuis n'importe quel dossier : .\scripts\integrated-manager.ps1" -ForegroundColor Cyan
    Write-Host "  - Depuis n'importe quel dossier : .\tools\scripts\integrated-manager.ps1" -ForegroundColor Cyan
} else {
    Write-Warning "Le gestionnaire intégré n'a pas été correctement installé."
}
```

## Exemples d'utilisation

### Installation simple

Pour installer le Gestionnaire Intégré dans le répertoire courant :

```powershell
.\install-integrated-manager.ps1
```

### Installation dans un répertoire spécifique

Pour installer le Gestionnaire Intégré dans un répertoire spécifique :

```powershell
.\install-integrated-manager.ps1 -ProjectRoot "D:\MonProjet"
```

### Réinstallation avec écrasement des fichiers existants

Pour réinstaller le Gestionnaire Intégré en écrasant les fichiers existants :

```powershell
.\install-integrated-manager.ps1 -Force
```

### Installation complète dans un répertoire spécifique avec écrasement

Pour installer le Gestionnaire Intégré dans un répertoire spécifique en écrasant les fichiers existants :

```powershell
.\install-integrated-manager.ps1 -ProjectRoot "D:\MonProjet" -Force
```

## Cas d'erreur et résolution

### Le script du gestionnaire intégré est introuvable

**Erreur :**
```
Le script du gestionnaire intégré est introuvable : C:\Chemin\vers\integrated-manager.ps1
```

**Cause :** Le script `integrated-manager.ps1` n'est pas présent dans le même répertoire que le script d'installation.

**Solution :**
1. Vérifiez que le script `integrated-manager.ps1` est présent dans le même répertoire que `install-integrated-manager.ps1`
2. Si ce n'est pas le cas, copiez-le dans le même répertoire ou spécifiez le chemin correct

### Le répertoire du projet n'existe pas

**Erreur :**
```
Le répertoire du projet n'existe pas : D:\CheminInexistant
```

**Cause :** Le répertoire spécifié par le paramètre `ProjectRoot` n'existe pas.

**Solution :**
1. Vérifiez que le chemin spécifié existe
2. Créez le répertoire avant d'exécuter le script
3. Utilisez un chemin valide

### Impossible de créer le lien symbolique

**Erreur :**
```
Impossible de créer le lien symbolique : D:\MonProjet\tools\scripts\integrated-manager.ps1 -> C:\Chemin\vers\integrated-manager.ps1
Erreur : Accès refusé
```

**Cause :** Vous n'avez pas les droits d'administrateur nécessaires pour créer des liens symboliques.

**Solution :**
1. Exécutez PowerShell en tant qu'administrateur
2. Utilisez une version de PowerShell qui prend en charge les liens symboliques (5.1 ou supérieur)
3. Le script créera automatiquement un fichier de redirection en cas d'échec de création du lien symbolique

### Le fichier existe déjà et ne sera pas écrasé

**Avertissement :**
```
Le fichier existe déjà et ne sera pas écrasé : D:\MonProjet\development\config\unified-config.json
```

**Cause :** Le fichier existe déjà et le paramètre `-Force` n'a pas été spécifié.

**Solution :**
1. Utilisez le paramètre `-Force` pour écraser les fichiers existants
2. Supprimez manuellement les fichiers existants avant d'exécuter le script
3. Sauvegardez les fichiers existants avant de les écraser

## Bonnes pratiques

### Quand utiliser le paramètre -Force

- Utilisez `-Force` lors d'une réinstallation ou d'une mise à jour du Gestionnaire Intégré
- Utilisez `-Force` si vous êtes sûr de vouloir écraser les fichiers existants
- N'utilisez pas `-Force` si vous avez personnalisé les fichiers et que vous souhaitez les conserver

### Sauvegarde avant installation

Il est recommandé de sauvegarder les fichiers existants avant d'installer ou de réinstaller le Gestionnaire Intégré, surtout si vous utilisez le paramètre `-Force`. Vous pouvez le faire manuellement ou avec un script de sauvegarde.

```powershell
# Exemple de sauvegarde avant installation
$backupFolder = "backup_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
New-Item -Path $backupFolder -ItemType Directory -Force | Out-Null
Copy-Item -Path "development\config\unified-config.json" -Destination $backupFolder -Force -ErrorAction SilentlyContinue
Copy-Item -Path "development\docs\guides\methodologies\integrated_manager.md" -Destination $backupFolder -Force -ErrorAction SilentlyContinue
Copy-Item -Path "integrated-manager.ps1" -Destination $backupFolder -Force -ErrorAction SilentlyContinue

# Installer le Gestionnaire Intégré
.\install-integrated-manager.ps1 -Force
```

### Vérification après installation

Après l'installation, vérifiez que le Gestionnaire Intégré fonctionne correctement en exécutant une commande simple :

```powershell
# Vérifier que le Gestionnaire Intégré fonctionne correctement
.\integrated-manager.ps1 -ListModes
```

Si cette commande affiche la liste des modes disponibles, l'installation a réussi.

## Intégration avec d'autres scripts

Le script `install-integrated-manager.ps1` peut être intégré à d'autres scripts pour automatiser l'installation du Gestionnaire Intégré dans le cadre d'un processus plus large.

### Exemple d'intégration dans un script d'installation global

```powershell
# Script d'installation global
param (
    [string]$ProjectRoot = ".",
    [switch]$Force
)

# Installer le Gestionnaire Intégré
Write-Host "Installation du Gestionnaire Intégré..." -ForegroundColor Cyan
& ".\scripts\install-integrated-manager.ps1" -ProjectRoot $ProjectRoot -Force:$Force

# Installer d'autres composants
Write-Host "Installation d'autres composants..." -ForegroundColor Cyan
# ...

Write-Host "Installation terminée." -ForegroundColor Green
```

### Exemple d'intégration dans un workflow CI/CD

```powershell
# Script de déploiement CI/CD
param (
    [string]$DeploymentPath,
    [switch]$Force = $true
)

# Cloner le dépôt
git clone https://github.com/mon-organisation/mon-projet.git $DeploymentPath

# Installer le Gestionnaire Intégré
Write-Host "Installation du Gestionnaire Intégré..." -ForegroundColor Cyan
& "$DeploymentPath\scripts\install-integrated-manager.ps1" -ProjectRoot $DeploymentPath -Force:$Force

# Configurer l'environnement
Write-Host "Configuration de l'environnement..." -ForegroundColor Cyan
# ...

Write-Host "Déploiement terminé." -ForegroundColor Green
```

## Conclusion

Le script `install-integrated-manager.ps1` est un outil essentiel pour installer et configurer le Gestionnaire Intégré dans votre projet. Il automatise la création des répertoires nécessaires, la copie des fichiers et la création des liens symboliques, ce qui facilite l'accès au Gestionnaire Intégré depuis différents emplacements.

En suivant les instructions de ce guide et en utilisant les exemples fournis, vous pourrez installer et configurer le Gestionnaire Intégré rapidement et efficacement, ce qui vous permettra de profiter pleinement de ses fonctionnalités pour gérer vos modes opérationnels et vos roadmaps.
