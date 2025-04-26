# Documentation des exceptions du namespace System.IO

## Introduction

Le namespace `System.IO` contient les exceptions liées aux opérations d'entrée/sortie dans le framework .NET. Ces exceptions sont essentielles pour gérer les erreurs qui peuvent survenir lors de la manipulation de fichiers, de répertoires et de flux de données. Comprendre ces exceptions, leurs cas d'utilisation et leurs caractéristiques est crucial pour développer des applications robustes qui interagissent avec le système de fichiers.

Cette documentation présente en détail les exceptions principales du namespace `System.IO`, leurs hiérarchies, leurs cas d'utilisation typiques, et fournit des exemples concrets en PowerShell pour illustrer leur comportement.

## IOException et ses caractéristiques

### Vue d'ensemble

`IOException` est l'exception de base pour toutes les erreurs d'entrée/sortie dans le framework .NET. Elle est levée lorsqu'une opération d'entrée/sortie échoue, comme la lecture ou l'écriture dans un fichier, l'accès à un périphérique, ou toute autre opération impliquant des ressources externes.

### Hiérarchie

```
System.Exception
└── System.SystemException
    └── System.IO.IOException
        ├── System.IO.FileNotFoundException
        ├── System.IO.DirectoryNotFoundException
        ├── System.IO.PathTooLongException
        ├── System.IO.DriveNotFoundException
        ├── System.IO.EndOfStreamException
        ├── System.IO.FileLoadException
        ├── System.IO.InternalBufferOverflowException
        └── System.IO.PipeException
```

### Description

`IOException` est une exception générique qui indique qu'une erreur s'est produite lors d'une opération d'entrée/sortie. Elle peut être causée par diverses raisons, telles que des problèmes de périphérique, des erreurs de réseau, des problèmes de permissions, ou des erreurs de système de fichiers.

### Propriétés spécifiques

| Propriété | Type | Description |
|-----------|------|-------------|
| HResult | int | Code d'erreur numérique qui peut fournir des informations supplémentaires sur l'erreur |

### Constructeurs principaux

```csharp
IOException()
IOException(string message)
IOException(string message, Exception innerException)
IOException(string message, int hresult)
IOException(string message, int hresult, Exception innerException)
```

### Cas d'utilisation typiques

1. **Erreurs de lecture/écriture de fichier** : Problèmes lors de la lecture ou de l'écriture dans un fichier.

2. **Problèmes d'accès au périphérique** : Erreurs lors de l'accès à un périphérique de stockage.

3. **Erreurs de réseau** : Problèmes lors de la lecture ou de l'écriture sur un réseau.

4. **Fichier verrouillé** : Tentative d'accès à un fichier qui est déjà utilisé par un autre processus.

5. **Espace disque insuffisant** : Tentative d'écriture sur un disque qui n'a pas assez d'espace libre.

### Exemples en PowerShell

```powershell
# Exemple 1: Erreur de lecture de fichier
function Read-FileWithIOExceptionHandling {
    param (
        [string]$FilePath
    )

    try {
        $fileStream = [System.IO.FileStream]::new($FilePath, [System.IO.FileMode]::Open)
        $reader = [System.IO.StreamReader]::new($fileStream)
        $content = $reader.ReadToEnd()
        $reader.Close()
        $fileStream.Close()
        return $content
    } catch [System.IO.IOException] {
        Write-Host "Erreur d'E/S lors de la lecture du fichier: $($_.Exception.Message)"
        return $null
    } finally {
        if ($reader -ne $null) { $reader.Dispose() }
        if ($fileStream -ne $null) { $fileStream.Dispose() }
    }
}

# Tentative de lecture d'un fichier qui est peut-être verrouillé ou inaccessible
Read-FileWithIOExceptionHandling -FilePath "C:\Windows\System32\drivers\etc\hosts"

# Exemple 2: Erreur d'écriture de fichier
function Write-FileWithIOExceptionHandling {
    param (
        [string]$FilePath,
        [string]$Content
    )

    try {
        $fileStream = [System.IO.FileStream]::new($FilePath, [System.IO.FileMode]::Create)
        $writer = [System.IO.StreamWriter]::new($fileStream)
        $writer.Write($Content)
        $writer.Flush()
        $writer.Close()
        $fileStream.Close()
        return $true
    } catch [System.IO.IOException] {
        Write-Host "Erreur d'E/S lors de l'écriture dans le fichier: $($_.Exception.Message)"
        return $false
    } finally {
        if ($writer -ne $null) { $writer.Dispose() }
        if ($fileStream -ne $null) { $fileStream.Dispose() }
    }
}

# Tentative d'écriture dans un fichier qui est peut-être en lecture seule ou inaccessible
Write-FileWithIOExceptionHandling -FilePath "C:\Windows\System32\test.txt" -Content "Test"

# Exemple 3: Fichier verrouillé par un autre processus
function Demonstrate-LockedFileIOException {
    param (
        [string]$FilePath
    )

    try {
        # Créer un fichier et le garder ouvert
        $fileStream1 = [System.IO.FileStream]::new($FilePath, [System.IO.FileMode]::Create, [System.IO.FileAccess]::ReadWrite, [System.IO.FileShare]::None)
        Write-Host "Fichier créé et verrouillé: $FilePath"

        # Tenter d'ouvrir le même fichier dans un autre flux
        Write-Host "Tentative d'ouverture du fichier verrouillé..."
        $fileStream2 = [System.IO.FileStream]::new($FilePath, [System.IO.FileMode]::Open)

        # Cette ligne ne sera jamais exécutée
        Write-Host "Fichier ouvert avec succès (cela ne devrait pas se produire)"
        $fileStream2.Close()
    } catch [System.IO.IOException] {
        Write-Host "IOException capturée: $($_.Exception.Message)"
        Write-Host "HResult: $($_.Exception.HResult)"
    } finally {
        if ($fileStream1 -ne $null) {
            $fileStream1.Close()
            Write-Host "Premier flux fermé, le fichier est maintenant déverrouillé"
        }
    }
}

$tempFile = [System.IO.Path]::GetTempFileName()
Demonstrate-LockedFileIOException -FilePath $tempFile
Remove-Item -Path $tempFile -Force -ErrorAction SilentlyContinue

# Exemple 4: Espace disque insuffisant (simulation)
function Simulate-DiskFullIOException {
    param (
        [string]$Message = "There is not enough space on the disk."
    )

    # Simuler une IOException avec un message d'espace disque insuffisant
    $exception = [System.IO.IOException]::new($Message, -2147024784)  # 0x80070070 (ERROR_DISK_FULL)

    try {
        throw $exception
    } catch [System.IO.IOException] {
        Write-Host "IOException capturée: $($_.Exception.Message)"
        Write-Host "HResult: $($_.Exception.HResult)"

        # Vérifier si c'est une erreur de disque plein
        if ($_.Exception.HResult -eq -2147024784) {
            Write-Host "Erreur spécifique: Espace disque insuffisant"
        }
    }
}

Simulate-DiskFullIOException

# Exemple 5: Utilisation de la classe File avec gestion des IOException
function Copy-FileWithIOExceptionHandling {
    param (
        [string]$SourcePath,
        [string]$DestinationPath
    )

    try {
        [System.IO.File]::Copy($SourcePath, $DestinationPath, $true)
        Write-Host "Fichier copié avec succès de $SourcePath vers $DestinationPath"
        return $true
    } catch [System.IO.FileNotFoundException] {
        # Gestion spécifique pour FileNotFoundException
        Write-Host "Le fichier source n'existe pas: $SourcePath"
        return $false
    } catch [System.IO.IOException] {
        # Gestion générique pour les autres IOException
        Write-Host "Erreur d'E/S lors de la copie du fichier: $($_.Exception.Message)"
        return $false
    }
}

# Créer un fichier temporaire pour le test
$sourceFile = [System.IO.Path]::GetTempFileName()
$destinationFile = [System.IO.Path]::Combine([System.IO.Path]::GetTempPath(), "copied_file.tmp")

# Écrire du contenu dans le fichier source
[System.IO.File]::WriteAllText($sourceFile, "Contenu de test")

# Copier le fichier
Copy-FileWithIOExceptionHandling -SourcePath $sourceFile -DestinationPath $destinationFile

# Nettoyer
Remove-Item -Path $sourceFile -Force -ErrorAction SilentlyContinue
Remove-Item -Path $destinationFile -Force -ErrorAction SilentlyContinue
```

### Codes HResult courants pour IOException

Les codes HResult peuvent fournir des informations plus précises sur la nature de l'erreur d'E/S. Voici quelques codes courants :

| Code HResult | Valeur hexadécimale | Description |
|--------------|---------------------|-------------|
| -2147024784 | 0x80070070 | ERROR_DISK_FULL - Le disque est plein |
| -2147024864 | 0x80070020 | ERROR_SHARING_VIOLATION - Le fichier est utilisé par un autre processus |
| -2147024891 | 0x80070005 | ERROR_ACCESS_DENIED - Accès refusé |
| -2147024893 | 0x80070003 | ERROR_PATH_NOT_FOUND - Le chemin spécifié est introuvable |
| -2147024894 | 0x80070002 | ERROR_FILE_NOT_FOUND - Le fichier spécifié est introuvable |

### Prévention des IOException

Voici plusieurs techniques pour éviter les `IOException` :

#### 1. Utilisation de blocs try-catch-finally

```powershell
function Process-FileWithProperCleanup {
    param (
        [string]$FilePath
    )

    $fileStream = $null

    try {
        $fileStream = [System.IO.FileStream]::new($FilePath, [System.IO.FileMode]::Open)
        # Traitement du fichier...
        return $true
    } catch [System.IO.IOException] {
        Write-Host "Erreur d'E/S: $($_.Exception.Message)"
        return $false
    } finally {
        # Toujours fermer et disposer des ressources, même en cas d'erreur
        if ($fileStream -ne $null) {
            $fileStream.Dispose()
        }
    }
}
```

#### 2. Utilisation de l'instruction using (en C#) ou de son équivalent en PowerShell

```powershell
function Process-FileWithUsing {
    param (
        [string]$FilePath
    )

    try {
        # En PowerShell 7+, vous pouvez utiliser le mot-clé 'using'
        # Pour PowerShell 5.1, nous simulons le comportement
        $fileStream = [System.IO.FileStream]::new($FilePath, [System.IO.FileMode]::Open)
        try {
            # Traitement du fichier...
            return $true
        } finally {
            $fileStream.Dispose()
        }
    } catch [System.IO.IOException] {
        Write-Host "Erreur d'E/S: $($_.Exception.Message)"
        return $false
    }
}
```

#### 3. Vérification préalable des conditions

```powershell
function Write-FileWithPreCheck {
    param (
        [string]$FilePath,
        [string]$Content
    )

    # Vérifier si le répertoire existe
    $directory = [System.IO.Path]::GetDirectoryName($FilePath)
    if (-not [System.IO.Directory]::Exists($directory)) {
        Write-Host "Le répertoire n'existe pas: $directory"
        return $false
    }

    # Vérifier si le fichier est en lecture seule
    if ([System.IO.File]::Exists($FilePath)) {
        $fileInfo = [System.IO.FileInfo]::new($FilePath)
        if ($fileInfo.IsReadOnly) {
            Write-Host "Le fichier est en lecture seule: $FilePath"
            return $false
        }
    }

    # Vérifier l'espace disque disponible
    $driveInfo = [System.IO.DriveInfo]::new([System.IO.Path]::GetPathRoot($FilePath))
    if ($driveInfo.AvailableFreeSpace -lt $Content.Length) {
        Write-Host "Espace disque insuffisant sur $($driveInfo.Name)"
        return $false
    }

    # Maintenant, tenter d'écrire dans le fichier
    try {
        [System.IO.File]::WriteAllText($FilePath, $Content)
        return $true
    } catch [System.IO.IOException] {
        Write-Host "Erreur d'E/S malgré les vérifications: $($_.Exception.Message)"
        return $false
    }
}
```

#### 4. Utilisation de FileShare pour éviter les conflits

```powershell
function Open-FileWithSharing {
    param (
        [string]$FilePath
    )

    try {
        # Ouvrir le fichier avec FileShare.ReadWrite pour permettre à d'autres processus de l'utiliser
        $fileStream = [System.IO.FileStream]::new($FilePath, [System.IO.FileMode]::Open, [System.IO.FileAccess]::Read, [System.IO.FileShare]::ReadWrite)

        # Traitement du fichier...
        $fileStream.Close()
        return $true
    } catch [System.IO.IOException] {
        Write-Host "Erreur d'E/S malgré le partage: $($_.Exception.Message)"
        return $false
    }
}
```

#### 5. Implémentation de mécanismes de retry

```powershell
function Read-FileWithRetry {
    param (
        [string]$FilePath,
        [int]$MaxRetries = 3,
        [int]$RetryDelayMs = 1000
    )

    $retryCount = 0

    while ($retryCount -lt $MaxRetries) {
        try {
            $content = [System.IO.File]::ReadAllText($FilePath)
            return $content
        } catch [System.IO.IOException] {
            $retryCount++
            Write-Host "Tentative $retryCount/$MaxRetries a échoué: $($_.Exception.Message)"

            if ($retryCount -ge $MaxRetries) {
                Write-Host "Nombre maximum de tentatives atteint. Abandon."
                return $null
            }

            # Attendre avant de réessayer
            Start-Sleep -Milliseconds $RetryDelayMs
        }
    }
}
```

### Débogage des IOException

Lorsque vous rencontrez une `IOException`, voici quelques étapes pour la déboguer efficacement :

1. **Examiner le message d'exception** : Le message peut contenir des informations utiles sur la cause de l'erreur.

2. **Vérifier le code HResult** : Le code HResult peut fournir des informations plus précises sur la nature de l'erreur.

3. **Vérifier les permissions** : Assurez-vous que l'application a les permissions nécessaires pour accéder au fichier ou au répertoire.

4. **Vérifier si le fichier est verrouillé** : Utilisez des outils comme Process Explorer pour voir si le fichier est utilisé par un autre processus.

5. **Vérifier l'espace disque** : Assurez-vous qu'il y a suffisamment d'espace disque disponible.

```powershell
function Debug-IOException {
    param (
        [string]$FilePath,
        [string]$Operation = "Read"  # "Read" ou "Write"
    )

    Write-Host "Débogage d'opération d'E/S sur le fichier: $FilePath"

    # Vérifier si le fichier existe
    if (-not [System.IO.File]::Exists($FilePath)) {
        Write-Host "Le fichier n'existe pas"
        return
    }

    # Obtenir les informations sur le fichier
    $fileInfo = [System.IO.FileInfo]::new($FilePath)
    Write-Host "Taille du fichier: $($fileInfo.Length) octets"
    Write-Host "Dernière modification: $($fileInfo.LastWriteTime)"
    Write-Host "Attributs: $($fileInfo.Attributes)"

    # Vérifier si le fichier est en lecture seule
    if ($fileInfo.IsReadOnly) {
        Write-Host "ATTENTION: Le fichier est en lecture seule"
    }

    # Vérifier l'espace disque
    $driveInfo = [System.IO.DriveInfo]::new($fileInfo.Directory.Root.FullName)
    Write-Host "Espace disque disponible: $($driveInfo.AvailableFreeSpace) octets"

    # Tenter l'opération avec capture détaillée de l'exception
    try {
        if ($Operation -eq "Read") {
            $fileStream = [System.IO.FileStream]::new($FilePath, [System.IO.FileMode]::Open, [System.IO.FileAccess]::Read)
        } else {
            $fileStream = [System.IO.FileStream]::new($FilePath, [System.IO.FileMode]::Open, [System.IO.FileAccess]::Write)
        }

        Write-Host "Opération réussie"
        $fileStream.Close()
    } catch [System.IO.IOException] {
        Write-Host "IOException capturée:"
        Write-Host "  Message: $($_.Exception.Message)"
        Write-Host "  HResult: $($_.Exception.HResult) (0x$($_.Exception.HResult.ToString('X8')))"

        # Interpréter le code HResult
        switch ($_.Exception.HResult) {
            -2147024784 { Write-Host "  Interprétation: Espace disque insuffisant" }
            -2147024864 { Write-Host "  Interprétation: Le fichier est utilisé par un autre processus" }
            -2147024891 { Write-Host "  Interprétation: Accès refusé" }
            -2147024893 { Write-Host "  Interprétation: Chemin introuvable" }
            -2147024894 { Write-Host "  Interprétation: Fichier introuvable" }
            default { Write-Host "  Interprétation: Code d'erreur non reconnu" }
        }
    }
}

# Exemple d'utilisation
$tempFile = [System.IO.Path]::GetTempFileName()
Debug-IOException -FilePath $tempFile -Operation "Write"
Remove-Item -Path $tempFile -Force -ErrorAction SilentlyContinue
```

### Bonnes pratiques pour gérer les IOException

1. **Toujours fermer les ressources** : Utilisez des blocs `try-finally` ou l'équivalent de `using` pour vous assurer que les ressources sont correctement fermées.

2. **Gérer les exceptions spécifiques** : Capturez les exceptions dérivées de `IOException` avant de capturer `IOException` elle-même.

3. **Implémenter des mécanismes de retry** : Pour les opérations qui peuvent échouer temporairement, implémentez une logique de retry.

4. **Vérifier les conditions préalables** : Vérifiez les conditions qui pourraient causer une `IOException` avant de tenter l'opération.

5. **Utiliser les modes de partage appropriés** : Utilisez les modes de partage appropriés pour éviter les conflits d'accès aux fichiers.

6. **Journaliser les détails de l'exception** : Journalisez le message et le code HResult pour faciliter le débogage.

7. **Nettoyer les ressources temporaires** : Assurez-vous de nettoyer les fichiers temporaires, même en cas d'erreur.

### Résumé

`IOException` est l'exception de base pour toutes les erreurs d'entrée/sortie dans le framework .NET. Elle est levée lorsqu'une opération d'entrée/sortie échoue, comme la lecture ou l'écriture dans un fichier, l'accès à un périphérique, ou toute autre opération impliquant des ressources externes.

En comprenant les caractéristiques de `IOException`, ses codes HResult courants, et en appliquant les bonnes pratiques pour la prévention et le débogage, vous pouvez développer des applications plus robustes qui gèrent efficacement les erreurs d'entrée/sortie.

## FileNotFoundException et ses détails

### Vue d'ensemble

`FileNotFoundException` est une exception qui est levée lorsqu'une tentative d'accès à un fichier échoue parce que le fichier n'existe pas. Cette exception est une sous-classe de `IOException` et est spécifiquement utilisée pour signaler l'absence d'un fichier requis.

### Hiérarchie

```
System.Exception
└── System.SystemException
    └── System.IO.IOException
        └── System.IO.FileNotFoundException
            └── System.IO.FileLoadException
```

### Description

`FileNotFoundException` est levée lorsqu'une méthode qui nécessite l'accès à un fichier ne peut pas trouver le fichier à l'emplacement spécifié. Cette exception est couramment rencontrée lors de l'ouverture, de la lecture ou de la copie de fichiers qui n'existent pas.

### Propriétés spécifiques

| Propriété | Type | Description |
|-----------|------|-------------|
| FileName | string | Nom du fichier qui n'a pas pu être trouvé |
| FusionLog | string | Informations de journalisation supplémentaires (principalement utilisées pour le chargement d'assemblies) |

### Constructeurs principaux

```csharp
FileNotFoundException()
FileNotFoundException(string message)
FileNotFoundException(string message, Exception innerException)
FileNotFoundException(string message, string fileName)
FileNotFoundException(string message, string fileName, Exception innerException)
```

### Cas d'utilisation typiques

1. **Fichier d'entrée manquant** : Tentative de lecture d'un fichier qui n'existe pas.

2. **Chemin incorrect** : Spécification d'un chemin incorrect pour un fichier.

3. **Fichier supprimé** : Tentative d'accès à un fichier qui a été supprimé.

4. **Fichier déplacé** : Tentative d'accès à un fichier qui a été déplacé.

5. **Problèmes de casse** : Sur les systèmes sensibles à la casse, spécification d'un nom de fichier avec une casse incorrecte.

### Exemples en PowerShell

```powershell
# Exemple 1: Lecture d'un fichier inexistant
function Read-NonExistentFile {
    param (
        [string]$FilePath
    )

    try {
        $content = [System.IO.File]::ReadAllText($FilePath)
        return $content
    } catch [System.IO.FileNotFoundException] {
        Write-Host "Erreur: Le fichier '$FilePath' n'existe pas"
        Write-Host "Détails: $($_.Exception.Message)"
        Write-Host "Nom du fichier: $($_.Exception.FileName)"
        return $null
    }
}

Read-NonExistentFile -FilePath "C:\fichier_inexistant.txt"

# Sortie:
# Erreur: Le fichier 'C:\fichier_inexistant.txt' n'existe pas
# Détails: Could not find file 'C:\fichier_inexistant.txt'.
# Nom du fichier: C:\fichier_inexistant.txt

# Exemple 2: Ouverture d'un fichier avec un chemin incorrect
function Open-FileWithIncorrectPath {
    param (
        [string]$FilePath
    )

    try {
        $fileStream = [System.IO.FileStream]::new($FilePath, [System.IO.FileMode]::Open)
        $reader = [System.IO.StreamReader]::new($fileStream)
        $content = $reader.ReadToEnd()
        $reader.Close()
        $fileStream.Close()
        return $content
    } catch [System.IO.FileNotFoundException] {
        return "FileNotFound: $($_.Exception.FileName)"
    } catch [System.IO.DirectoryNotFoundException] {
        return "DirectoryNotFound: $FilePath"
    } catch {
        return "Autre erreur: $($_.Exception.GetType().FullName)"
    } finally {
        if ($reader -ne $null) { $reader.Dispose() }
        if ($fileStream -ne $null) { $fileStream.Dispose() }
    }
}

Open-FileWithIncorrectPath -FilePath "C:\Dossier_Inexistant\fichier.txt"

# Sortie:
# DirectoryNotFound: C:\Dossier_Inexistant\fichier.txt

# Exemple 3: Vérification de l'existence d'un fichier avant de l'ouvrir
function Open-FileWithCheck {
    param (
        [string]$FilePath
    )

    if (-not [System.IO.File]::Exists($FilePath)) {
        Write-Host "Le fichier '$FilePath' n'existe pas"
        return $null
    }

    try {
        $content = [System.IO.File]::ReadAllText($FilePath)
        return $content
    } catch {
        Write-Host "Erreur lors de la lecture du fichier: $($_.Exception.Message)"
        return $null
    }
}

# Créer un fichier temporaire pour le test
$tempFile = [System.IO.Path]::GetTempFileName()
[System.IO.File]::WriteAllText($tempFile, "Contenu de test")

# Tester avec un fichier existant
Open-FileWithCheck -FilePath $tempFile

# Tester avec un fichier inexistant
Open-FileWithCheck -FilePath "C:\fichier_inexistant.txt"

# Nettoyer
Remove-Item -Path $tempFile -Force -ErrorAction SilentlyContinue

# Sortie:
# Contenu de test
# Le fichier 'C:\fichier_inexistant.txt' n'existe pas

# Exemple 4: Création d'un fichier s'il n'existe pas
function Get-OrCreateFile {
    param (
        [string]$FilePath,
        [string]$DefaultContent = ""
    )

    try {
        return [System.IO.File]::ReadAllText($FilePath)
    } catch [System.IO.FileNotFoundException] {
        Write-Host "Le fichier '$FilePath' n'existe pas. Création du fichier..."
        [System.IO.File]::WriteAllText($FilePath, $DefaultContent)
        return $DefaultContent
    } catch {
        Write-Host "Erreur inattendue: $($_.Exception.Message)"
        return $null
    }
}

$tempPath = [System.IO.Path]::Combine([System.IO.Path]::GetTempPath(), "test_file.txt")

# Supprimer le fichier s'il existe déjà
if ([System.IO.File]::Exists($tempPath)) {
    Remove-Item -Path $tempPath -Force
}

# Première appel - le fichier n'existe pas
$content1 = Get-OrCreateFile -FilePath $tempPath -DefaultContent "Contenu par défaut"

# Deuxième appel - le fichier existe maintenant
$content2 = Get-OrCreateFile -FilePath $tempPath

# Nettoyer
Remove-Item -Path $tempPath -Force -ErrorAction SilentlyContinue

# Sortie:
# Le fichier '...\test_file.txt' n'existe pas. Création du fichier...
# Contenu par défaut
# Contenu par défaut

# Exemple 5: Gestion des erreurs de chargement d'assembly
function Load-Assembly {
    param (
        [string]$AssemblyPath
    )

    try {
        $assembly = [System.Reflection.Assembly]::LoadFrom($AssemblyPath)
        return "Assembly chargé: $($assembly.FullName)"
    } catch [System.IO.FileNotFoundException] {
        Write-Host "Erreur: L'assembly '$($_.Exception.FileName)' n'a pas pu être trouvé"

        if (-not [string]::IsNullOrEmpty($_.Exception.FusionLog)) {
            Write-Host "Journal de fusion: $($_.Exception.FusionLog)"
        }

        return $null
    } catch {
        Write-Host "Erreur inattendue: $($_.Exception.Message)"
        return $null
    }
}

Load-Assembly -AssemblyPath "C:\assembly_inexistant.dll"

# Sortie:
# Erreur: L'assembly 'C:\assembly_inexistant.dll' n'a pas pu être trouvé
```

### Différence entre FileNotFoundException et DirectoryNotFoundException

Il est important de comprendre la différence entre `FileNotFoundException` et `DirectoryNotFoundException` :

- **FileNotFoundException** : Levée lorsque le fichier spécifié n'existe pas, mais le répertoire parent existe.

- **DirectoryNotFoundException** : Levée lorsque le répertoire parent du fichier spécifié n'existe pas.

```powershell
function Demonstrate-FileVsDirectoryNotFound {
    param (
        [string]$Path,
        [switch]$IsDirectory
    )

    try {
        if ($IsDirectory) {
            # Tenter d'accéder à un répertoire
            [System.IO.Directory]::GetFiles($Path)
        } else {
            # Tenter d'accéder à un fichier
            [System.IO.File]::ReadAllText($Path)
        }
        return "Succès (ne devrait pas se produire)"
    } catch [System.IO.FileNotFoundException] {
        return "FileNotFoundException: Le fichier n'existe pas, mais le répertoire parent existe"
    } catch [System.IO.DirectoryNotFoundException] {
        return "DirectoryNotFoundException: Le répertoire parent n'existe pas"
    } catch {
        return "Autre exception: $($_.Exception.GetType().FullName)"
    }
}

# Créer un répertoire temporaire pour le test
$tempDir = [System.IO.Path]::Combine([System.IO.Path]::GetTempPath(), "test_dir")
[System.IO.Directory]::CreateDirectory($tempDir)

# Cas 1: Fichier inexistant dans un répertoire existant
$nonExistentFile = [System.IO.Path]::Combine($tempDir, "fichier_inexistant.txt")
Demonstrate-FileVsDirectoryNotFound -Path $nonExistentFile

# Cas 2: Fichier dans un répertoire inexistant
$nonExistentDir = [System.IO.Path]::Combine([System.IO.Path]::GetTempPath(), "dossier_inexistant")
$fileInNonExistentDir = [System.IO.Path]::Combine($nonExistentDir, "fichier.txt")
Demonstrate-FileVsDirectoryNotFound -Path $fileInNonExistentDir

# Cas 3: Répertoire inexistant
Demonstrate-FileVsDirectoryNotFound -Path $nonExistentDir -IsDirectory

# Nettoyer
Remove-Item -Path $tempDir -Recurse -Force -ErrorAction SilentlyContinue

# Sortie:
# FileNotFoundException: Le fichier n'existe pas, mais le répertoire parent existe
# DirectoryNotFoundException: Le répertoire parent n'existe pas
# DirectoryNotFoundException: Le répertoire parent n'existe pas
```

### Prévention des FileNotFoundException

Voici plusieurs techniques pour éviter les `FileNotFoundException` :

#### 1. Vérification préalable de l'existence du fichier

```powershell
function Read-FileIfExists {
    param (
        [string]$FilePath
    )

    if (-not [System.IO.File]::Exists($FilePath)) {
        Write-Host "Le fichier '$FilePath' n'existe pas"
        return $null
    }

    return [System.IO.File]::ReadAllText($FilePath)
}
```

#### 2. Création du fichier s'il n'existe pas

```powershell
function Ensure-FileExists {
    param (
        [string]$FilePath,
        [string]$DefaultContent = ""
    )

    if (-not [System.IO.File]::Exists($FilePath)) {
        # Vérifier si le répertoire parent existe
        $directory = [System.IO.Path]::GetDirectoryName($FilePath)
        if (-not [System.IO.Directory]::Exists($directory)) {
            [System.IO.Directory]::CreateDirectory($directory)
        }

        # Créer le fichier avec le contenu par défaut
        [System.IO.File]::WriteAllText($FilePath, $DefaultContent)
    }

    return [System.IO.File]::ReadAllText($FilePath)
}
```

#### 3. Utilisation de chemins absolus

```powershell
function Get-AbsolutePath {
    param (
        [string]$RelativePath
    )

    # Convertir le chemin relatif en chemin absolu
    $absolutePath = [System.IO.Path]::GetFullPath($RelativePath)

    Write-Host "Chemin relatif: $RelativePath"
    Write-Host "Chemin absolu: $absolutePath"

    return $absolutePath
}
```

#### 4. Recherche de fichiers dans plusieurs emplacements

```powershell
function Find-FileInMultipleLocations {
    param (
        [string]$FileName,
        [string[]]$SearchPaths
    )

    foreach ($path in $SearchPaths) {
        $filePath = [System.IO.Path]::Combine($path, $FileName)
        if ([System.IO.File]::Exists($filePath)) {
            Write-Host "Fichier trouvé: $filePath"
            return $filePath
        }
    }

    Write-Host "Fichier '$FileName' non trouvé dans les chemins de recherche"
    return $null
}
```

#### 5. Gestion des problèmes de casse sur les systèmes sensibles à la casse

```powershell
function Find-FileIgnoreCase {
    param (
        [string]$Directory,
        [string]$FileName
    )

    if (-not [System.IO.Directory]::Exists($Directory)) {
        Write-Host "Le répertoire '$Directory' n'existe pas"
        return $null
    }

    # Obtenir tous les fichiers dans le répertoire
    $files = [System.IO.Directory]::GetFiles($Directory)

    # Rechercher le fichier sans tenir compte de la casse
    foreach ($file in $files) {
        $currentFileName = [System.IO.Path]::GetFileName($file)
        if ($currentFileName -ieq $FileName) {  # -ieq pour une comparaison insensible à la casse
            Write-Host "Fichier trouvé (casse différente): $file"
            return $file
        }
    }

    Write-Host "Fichier '$FileName' non trouvé dans le répertoire '$Directory'"
    return $null
}
```

### Débogage des FileNotFoundException

Lorsque vous rencontrez une `FileNotFoundException`, voici quelques étapes pour la déboguer efficacement :

1. **Vérifier le chemin complet** : Assurez-vous que le chemin complet du fichier est correct.

2. **Vérifier les permissions** : Assurez-vous que l'application a les permissions nécessaires pour accéder au fichier.

3. **Vérifier la casse** : Sur les systèmes sensibles à la casse, vérifiez que la casse du nom de fichier est correcte.

4. **Vérifier le répertoire parent** : Assurez-vous que le répertoire parent existe.

5. **Utiliser des outils de débogage** : Utilisez des outils comme Process Monitor pour suivre les tentatives d'accès aux fichiers.

```powershell
function Debug-FileNotFoundException {
    param (
        [string]$FilePath
    )

    Write-Host "Débogage de FileNotFoundException pour le fichier: $FilePath"

    # Vérifier si le chemin est absolu ou relatif
    $isAbsolute = [System.IO.Path]::IsPathRooted($FilePath)
    Write-Host "Chemin absolu: $isAbsolute"

    if (-not $isAbsolute) {
        $absolutePath = [System.IO.Path]::GetFullPath($FilePath)
        Write-Host "Chemin absolu résolu: $absolutePath"
        $FilePath = $absolutePath
    }

    # Vérifier si le fichier existe
    $fileExists = [System.IO.File]::Exists($FilePath)
    Write-Host "Le fichier existe: $fileExists"

    if (-not $fileExists) {
        # Vérifier si le répertoire parent existe
        $directory = [System.IO.Path]::GetDirectoryName($FilePath)
        $directoryExists = [System.IO.Directory]::Exists($directory)
        Write-Host "Répertoire parent: $directory"
        Write-Host "Le répertoire parent existe: $directoryExists"

        if ($directoryExists) {
            # Lister les fichiers dans le répertoire
            Write-Host "Fichiers dans le répertoire:"
            $files = [System.IO.Directory]::GetFiles($directory)
            foreach ($file in $files) {
                Write-Host "  $file"
            }

            # Vérifier si un fichier avec un nom similaire existe (problème de casse)
            $fileName = [System.IO.Path]::GetFileName($FilePath)
            foreach ($file in $files) {
                $currentFileName = [System.IO.Path]::GetFileName($file)
                if ($currentFileName -ieq $fileName) {
                    Write-Host "Fichier trouvé avec une casse différente: $file"
                    break
                }
            }
        } else {
            Write-Host "Le problème est que le répertoire parent n'existe pas (DirectoryNotFoundException)"
        }
    }
}

# Exemple d'utilisation
Debug-FileNotFoundException -FilePath "C:\Windows\System32\notepad.exe"  # Devrait exister
Debug-FileNotFoundException -FilePath "C:\Windows\System32\notepad.EXE"  # Test de casse
Debug-FileNotFoundException -FilePath "C:\Windows\System32\fichier_inexistant.txt"  # Ne devrait pas exister
Debug-FileNotFoundException -FilePath "C:\Dossier_Inexistant\fichier.txt"  # Répertoire inexistant
```

### Bonnes pratiques pour gérer les FileNotFoundException

1. **Vérifier l'existence du fichier** : Utilisez `File.Exists()` pour vérifier si un fichier existe avant de tenter de l'ouvrir.

2. **Utiliser des chemins absolus** : Utilisez des chemins absolus plutôt que des chemins relatifs pour éviter les ambiguïtés.

3. **Créer les répertoires manquants** : Créez les répertoires manquants avant de créer un fichier.

4. **Gérer les problèmes de casse** : Sur les systèmes sensibles à la casse, faites attention à la casse des noms de fichiers.

5. **Fournir des messages d'erreur clairs** : Lorsqu'une `FileNotFoundException` est capturée, fournissez des messages d'erreur clairs qui incluent le chemin complet du fichier.

6. **Implémenter des mécanismes de recherche** : Si un fichier peut être à plusieurs endroits, implémentez un mécanisme de recherche.

7. **Journaliser les détails de l'exception** : Journalisez le message et le nom du fichier pour faciliter le débogage.

### Résumé

`FileNotFoundException` est une exception qui est levée lorsqu'une tentative d'accès à un fichier échoue parce que le fichier n'existe pas. Cette exception est une sous-classe de `IOException` et est spécifiquement utilisée pour signaler l'absence d'un fichier requis.

En comprenant les détails de `FileNotFoundException`, ses cas d'utilisation typiques, et en appliquant les bonnes pratiques pour la prévention et le débogage, vous pouvez développer des applications plus robustes qui gèrent efficacement les erreurs liées à l'absence de fichiers.

## DirectoryNotFoundException et ses contextes

### Vue d'ensemble

`DirectoryNotFoundException` est une exception qui est levée lorsqu'une partie d'un chemin de fichier ou de répertoire n'existe pas. Cette exception est une sous-classe de `IOException` et est spécifiquement utilisée pour signaler l'absence d'un répertoire requis dans un chemin.

### Hiérarchie

```
System.Exception
└── System.SystemException
    └── System.IO.IOException
        └── System.IO.DirectoryNotFoundException
```

### Description

`DirectoryNotFoundException` est levée lorsqu'une méthode qui nécessite l'accès à un répertoire ne peut pas trouver le répertoire à l'emplacement spécifié. Cette exception est couramment rencontrée lors de l'accès à des fichiers ou des répertoires dont le chemin parent n'existe pas.

### Propriétés spécifiques

`DirectoryNotFoundException` n'ajoute pas de propriétés spécifiques à celles héritées de `IOException`.

### Constructeurs principaux

```csharp
DirectoryNotFoundException()
DirectoryNotFoundException(string message)
DirectoryNotFoundException(string message, Exception innerException)
```

### Contextes courants

1. **Répertoire parent inexistant** : Tentative d'accès à un fichier dont le répertoire parent n'existe pas.

2. **Chemin de répertoire incorrect** : Spécification d'un chemin incorrect pour un répertoire.

3. **Répertoire supprimé** : Tentative d'accès à un répertoire qui a été supprimé.

4. **Lecteur ou partage réseau inexistant** : Tentative d'accès à un répertoire sur un lecteur ou un partage réseau qui n'existe pas ou n'est pas accessible.

5. **Problèmes de permissions** : Tentative d'accès à un répertoire pour lequel l'utilisateur n'a pas les permissions nécessaires (bien que cela puisse également générer `UnauthorizedAccessException`).

### Exemples en PowerShell

```powershell
# Exemple 1: Accès à un fichier dans un répertoire inexistant
function Access-FileInNonExistentDirectory {
    param (
        [string]$FilePath
    )

    try {
        $content = [System.IO.File]::ReadAllText($FilePath)
        return $content
    } catch [System.IO.DirectoryNotFoundException] {
        Write-Host "Erreur: Le répertoire parent du fichier '$FilePath' n'existe pas"
        Write-Host "Détails: $($_.Exception.Message)"
        return $null
    } catch [System.IO.FileNotFoundException] {
        Write-Host "Erreur: Le fichier '$FilePath' n'existe pas, mais le répertoire parent existe"
        return $null
    } catch {
        Write-Host "Autre erreur: $($_.Exception.GetType().FullName)"
        return $null
    }
}

Access-FileInNonExistentDirectory -FilePath "C:\Dossier_Inexistant\fichier.txt"

# Sortie:
# Erreur: Le répertoire parent du fichier 'C:\Dossier_Inexistant\fichier.txt' n'existe pas
# Détails: Could not find a part of the path 'C:\Dossier_Inexistant\fichier.txt'.

# Exemple 2: Création d'un répertoire s'il n'existe pas
function Create-DirectoryIfNotExists {
    param (
        [string]$DirectoryPath
    )

    try {
        # Tenter d'obtenir les informations sur le répertoire
        $dirInfo = [System.IO.DirectoryInfo]::new($DirectoryPath)
        $files = $dirInfo.GetFiles()
        Write-Host "Le répertoire '$DirectoryPath' existe déjà et contient $($files.Count) fichiers"
        return $true
    } catch [System.IO.DirectoryNotFoundException] {
        Write-Host "Le répertoire '$DirectoryPath' n'existe pas. Création du répertoire..."
        try {
            [System.IO.Directory]::CreateDirectory($DirectoryPath) | Out-Null
            Write-Host "Répertoire créé avec succès"
            return $true
        } catch {
            Write-Host "Erreur lors de la création du répertoire: $($_.Exception.Message)"
            return $false
        }
    } catch {
        Write-Host "Autre erreur: $($_.Exception.Message)"
        return $false
    }
}

# Test avec un répertoire inexistant
$tempDir = [System.IO.Path]::Combine([System.IO.Path]::GetTempPath(), "test_dir_" + [Guid]::NewGuid().ToString())
Create-DirectoryIfNotExists -DirectoryPath $tempDir

# Test avec un répertoire existant
Create-DirectoryIfNotExists -DirectoryPath $tempDir

# Nettoyer
Remove-Item -Path $tempDir -Recurse -Force -ErrorAction SilentlyContinue

# Sortie:
# Le répertoire '...\test_dir_...' n'existe pas. Création du répertoire...
# Répertoire créé avec succès
# Le répertoire '...\test_dir_...' existe déjà et contient 0 fichiers

# Exemple 3: Accès à un lecteur ou partage réseau inexistant
function Access-NonExistentDrive {
    param (
        [string]$DrivePath
    )

    try {
        $files = [System.IO.Directory]::GetFiles($DrivePath)
        Write-Host "Le lecteur '$DrivePath' existe et contient $($files.Count) fichiers"
        return $files
    } catch [System.IO.DirectoryNotFoundException] {
        Write-Host "Erreur: Le lecteur ou répertoire '$DrivePath' n'existe pas"
        Write-Host "Détails: $($_.Exception.Message)"
        return $null
    } catch {
        Write-Host "Autre erreur: $($_.Exception.GetType().FullName) - $($_.Exception.Message)"
        return $null
    }
}

# Test avec un lecteur inexistant (ajustez la lettre de lecteur selon votre système)
Access-NonExistentDrive -DrivePath "Z:\Documents"

# Sortie:
# Erreur: Le lecteur ou répertoire 'Z:\Documents' n'existe pas
# Détails: Could not find a part of the path 'Z:\Documents'.

# Exemple 4: Vérification récursive de l'existence des répertoires parents
function Verify-DirectoryPath {
    param (
        [string]$Path
    )

    $result = @{
        Exists = $false
        MissingParts = @()
        FullPath = [System.IO.Path]::GetFullPath($Path)
    }

    # Vérifier si le chemin existe déjà
    if ([System.IO.Directory]::Exists($Path)) {
        $result.Exists = $true
        return $result
    }

    # Décomposer le chemin et vérifier chaque partie
    $parts = $result.FullPath.Split([System.IO.Path]::DirectorySeparatorChar)
    $currentPath = ""

    # Construire le chemin progressivement et vérifier chaque partie
    for ($i = 0; $i -lt $parts.Length; $i++) {
        $part = $parts[$i]

        # Ignorer les parties vides (comme après le séparateur de lecteur)
        if ([string]::IsNullOrEmpty($part)) {
            continue
        }

        # Ajouter le séparateur de lecteur pour le premier élément sous Windows
        if ($i -eq 0 -and $part.EndsWith(":")) {
            $currentPath = $part + [System.IO.Path]::DirectorySeparatorChar
        } else {
            # Pour les autres parties, ajouter le séparateur et la partie
            if (-not [string]::IsNullOrEmpty($currentPath)) {
                $currentPath = [System.IO.Path]::Combine($currentPath, $part)
            } else {
                $currentPath = $part
            }
        }

        # Vérifier si cette partie du chemin existe
        if (-not [System.IO.Directory]::Exists($currentPath)) {
            $result.MissingParts += $currentPath
        }
    }

    return $result
}

# Test avec un chemin à plusieurs niveaux
$deepPath = [System.IO.Path]::Combine([System.IO.Path]::GetTempPath(), "level1", "level2", "level3")
$verificationResult = Verify-DirectoryPath -Path $deepPath

Write-Host "Chemin complet: $($verificationResult.FullPath)"
Write-Host "Existe: $($verificationResult.Exists)"
Write-Host "Parties manquantes:"
foreach ($part in $verificationResult.MissingParts) {
    Write-Host "  - $part"
}

# Sortie:
# Chemin complet: ...\Temp\level1\level2\level3
# Existe: False
# Parties manquantes:
#   - ...\Temp\level1
#   - ...\Temp\level1\level2
#   - ...\Temp\level1\level2\level3

# Exemple 5: Création récursive de répertoires
function Create-DirectoryRecursively {
    param (
        [string]$Path
    )

    try {
        # CreateDirectory crée automatiquement tous les répertoires parents nécessaires
        $dirInfo = [System.IO.Directory]::CreateDirectory($Path)
        Write-Host "Répertoire '$Path' créé avec succès"
        return $dirInfo
    } catch {
        Write-Host "Erreur lors de la création du répertoire: $($_.Exception.Message)"
        return $null
    }
}

# Test avec un chemin à plusieurs niveaux
$deepPath = [System.IO.Path]::Combine([System.IO.Path]::GetTempPath(), "level1", "level2", "level3")
Create-DirectoryRecursively -Path $deepPath

# Vérifier que tous les répertoires ont été créés
$level1 = [System.IO.Path]::Combine([System.IO.Path]::GetTempPath(), "level1")
$level2 = [System.IO.Path]::Combine($level1, "level2")
$level3 = [System.IO.Path]::Combine($level2, "level3")

Write-Host "level1 existe: $([System.IO.Directory]::Exists($level1))"
Write-Host "level2 existe: $([System.IO.Directory]::Exists($level2))"
Write-Host "level3 existe: $([System.IO.Directory]::Exists($level3))"

# Nettoyer
Remove-Item -Path $level1 -Recurse -Force -ErrorAction SilentlyContinue

# Sortie:
# Répertoire '...\Temp\level1\level2\level3' créé avec succès
# level1 existe: True
# level2 existe: True
# level3 existe: True
```

### Différence entre DirectoryNotFoundException et FileNotFoundException

Comme nous l'avons vu dans la section sur `FileNotFoundException`, il est important de comprendre la différence entre ces deux exceptions :

- **DirectoryNotFoundException** : Levée lorsqu'une partie du chemin (généralement un répertoire parent) n'existe pas.

- **FileNotFoundException** : Levée lorsque le fichier spécifié n'existe pas, mais le répertoire parent existe.

Cette distinction est importante pour déterminer la cause exacte de l'erreur et pour implémenter la solution appropriée.

### Prévention des DirectoryNotFoundException

Voici plusieurs techniques pour éviter les `DirectoryNotFoundException` :

#### 1. Vérification préalable de l'existence du répertoire

```powershell
function Ensure-DirectoryExists {
    param (
        [string]$DirectoryPath
    )

    if (-not [System.IO.Directory]::Exists($DirectoryPath)) {
        Write-Host "Le répertoire '$DirectoryPath' n'existe pas"
        return $false
    }

    return $true
}
```

#### 2. Création du répertoire s'il n'existe pas

```powershell
function Create-DirectoryIfNotExists {
    param (
        [string]$DirectoryPath
    )

    if (-not [System.IO.Directory]::Exists($DirectoryPath)) {
        try {
            [System.IO.Directory]::CreateDirectory($DirectoryPath) | Out-Null
            Write-Host "Répertoire '$DirectoryPath' créé avec succès"
        } catch {
            Write-Host "Erreur lors de la création du répertoire: $($_.Exception.Message)"
            return $false
        }
    }

    return $true
}
```

#### 3. Utilisation de chemins absolus

```powershell
function Get-AbsoluteDirectoryPath {
    param (
        [string]$RelativePath
    )

    # Convertir le chemin relatif en chemin absolu
    $absolutePath = [System.IO.Path]::GetFullPath($RelativePath)

    Write-Host "Chemin relatif: $RelativePath"
    Write-Host "Chemin absolu: $absolutePath"

    return $absolutePath
}
```

#### 4. Vérification de la disponibilité des lecteurs et partages réseau

```powershell
function Check-DriveAvailability {
    param (
        [string]$DrivePath
    )

    # Extraire la lettre de lecteur ou le nom de partage réseau
    $root = [System.IO.Path]::GetPathRoot($DrivePath)

    if ([string]::IsNullOrEmpty($root)) {
        Write-Host "Chemin invalide: $DrivePath"
        return $false
    }

    # Vérifier si le lecteur ou le partage réseau existe
    if (-not [System.IO.Directory]::Exists($root)) {
        Write-Host "Le lecteur ou partage réseau '$root' n'existe pas ou n'est pas accessible"
        return $false
    }

    Write-Host "Le lecteur ou partage réseau '$root' est disponible"
    return $true
}
```

#### 5. Utilisation de méthodes qui créent automatiquement les répertoires parents

```powershell
function Write-FileWithDirectoryCreation {
    param (
        [string]$FilePath,
        [string]$Content
    )

    try {
        # Extraire le répertoire parent
        $directory = [System.IO.Path]::GetDirectoryName($FilePath)

        # Créer le répertoire parent s'il n'existe pas
        if (-not [string]::IsNullOrEmpty($directory) -and -not [System.IO.Directory]::Exists($directory)) {
            [System.IO.Directory]::CreateDirectory($directory) | Out-Null
            Write-Host "Répertoire '$directory' créé avec succès"
        }

        # Écrire le fichier
        [System.IO.File]::WriteAllText($FilePath, $Content)
        Write-Host "Fichier '$FilePath' écrit avec succès"

        return $true
    } catch {
        Write-Host "Erreur: $($_.Exception.Message)"
        return $false
    }
}
```

### Débogage des DirectoryNotFoundException

Lorsque vous rencontrez une `DirectoryNotFoundException`, voici quelques étapes pour la déboguer efficacement :

1. **Vérifier le chemin complet** : Assurez-vous que le chemin complet est correct et bien formé.

2. **Vérifier les répertoires parents** : Vérifiez que tous les répertoires parents existent.

3. **Vérifier les permissions** : Assurez-vous que l'application a les permissions nécessaires pour accéder au répertoire.

4. **Vérifier les lecteurs et partages réseau** : Si le chemin inclut un lecteur ou un partage réseau, vérifiez qu'il est disponible et accessible.

5. **Utiliser des outils de débogage** : Utilisez des outils comme Process Monitor pour suivre les tentatives d'accès aux répertoires.

```powershell
function Debug-DirectoryNotFoundException {
    param (
        [string]$Path
    )

    Write-Host "Débogage de DirectoryNotFoundException pour le chemin: $Path"

    # Vérifier si le chemin est absolu ou relatif
    $isAbsolute = [System.IO.Path]::IsPathRooted($Path)
    Write-Host "Chemin absolu: $isAbsolute"

    if (-not $isAbsolute) {
        $absolutePath = [System.IO.Path]::GetFullPath($Path)
        Write-Host "Chemin absolu résolu: $absolutePath"
        $Path = $absolutePath
    }

    # Vérifier si le chemin existe
    $pathExists = [System.IO.Directory]::Exists($Path)
    Write-Host "Le chemin existe: $pathExists"

    if (-not $pathExists) {
        # Décomposer le chemin et vérifier chaque partie
        $parts = $Path.Split([System.IO.Path]::DirectorySeparatorChar)
        $currentPath = ""

        Write-Host "Analyse des parties du chemin:"

        for ($i = 0; $i -lt $parts.Length; $i++) {
            $part = $parts[$i]

            # Ignorer les parties vides
            if ([string]::IsNullOrEmpty($part)) {
                continue
            }

            # Construire le chemin progressivement
            if ($i -eq 0 -and $part.EndsWith(":")) {
                $currentPath = $part + [System.IO.Path]::DirectorySeparatorChar
            } else {
                if (-not [string]::IsNullOrEmpty($currentPath)) {
                    $currentPath = [System.IO.Path]::Combine($currentPath, $part)
                } else {
                    $currentPath = $part
                }
            }

            # Vérifier si cette partie du chemin existe
            $exists = [System.IO.Directory]::Exists($currentPath)
            Write-Host "  $currentPath - Existe: $exists"

            if (-not $exists) {
                Write-Host "  => Première partie manquante du chemin"
                break
            }
        }

        # Vérifier si le lecteur ou partage réseau existe
        $root = [System.IO.Path]::GetPathRoot($Path)
        $rootExists = [System.IO.Directory]::Exists($root)
        Write-Host "Racine du chemin: $root - Existe: $rootExists"

        if (-not $rootExists) {
            Write-Host "Le problème est que le lecteur ou partage réseau n'existe pas ou n'est pas accessible"
        }
    }
}

# Exemple d'utilisation
Debug-DirectoryNotFoundException -Path "C:\Windows\System32"  # Devrait exister
Debug-DirectoryNotFoundException -Path "C:\Dossier_Inexistant"  # Ne devrait pas exister
Debug-DirectoryNotFoundException -Path "Z:\Documents"  # Lecteur inexistant
```

### Bonnes pratiques pour gérer les DirectoryNotFoundException

1. **Vérifier l'existence du répertoire** : Utilisez `Directory.Exists()` pour vérifier si un répertoire existe avant de tenter d'y accéder.

2. **Créer les répertoires manquants** : Utilisez `Directory.CreateDirectory()` pour créer les répertoires manquants avant d'y accéder.

3. **Utiliser des chemins absolus** : Utilisez des chemins absolus plutôt que des chemins relatifs pour éviter les ambiguïtés.

4. **Vérifier la disponibilité des lecteurs et partages réseau** : Vérifiez que les lecteurs et partages réseau sont disponibles avant d'y accéder.

5. **Fournir des messages d'erreur clairs** : Lorsqu'une `DirectoryNotFoundException` est capturée, fournissez des messages d'erreur clairs qui incluent le chemin complet.

6. **Implémenter des mécanismes de récupération** : Implémentez des mécanismes pour récupérer après une `DirectoryNotFoundException`, comme la création automatique des répertoires manquants.

7. **Journaliser les détails de l'exception** : Journalisez le message et le chemin complet pour faciliter le débogage.

### Résumé

`DirectoryNotFoundException` est une exception qui est levée lorsqu'une partie d'un chemin de fichier ou de répertoire n'existe pas. Cette exception est une sous-classe de `IOException` et est spécifiquement utilisée pour signaler l'absence d'un répertoire requis dans un chemin.

En comprenant les contextes dans lesquels `DirectoryNotFoundException` peut être levée, et en appliquant les bonnes pratiques pour la prévention et le débogage, vous pouvez développer des applications plus robustes qui gèrent efficacement les erreurs liées à l'absence de répertoires.

## PathTooLongException et ses limites

### Vue d'ensemble

`PathTooLongException` est une exception qui est levée lorsqu'un chemin de fichier ou de répertoire dépasse la longueur maximale autorisée par le système d'exploitation. Cette exception est une sous-classe de `IOException` et est spécifiquement utilisée pour signaler des problèmes liés à la longueur des chemins.

### Hiérarchie

```
System.Exception
└── System.SystemException
    └── System.IO.IOException
        └── System.IO.PathTooLongException
```

### Description

`PathTooLongException` est levée lorsqu'une opération sur un fichier ou un répertoire implique un chemin dont la longueur dépasse les limites du système d'exploitation. Cette exception est couramment rencontrée lors de la manipulation de fichiers dans des répertoires profondément imbriqués ou avec des noms très longs.

### Propriétés spécifiques

`PathTooLongException` n'ajoute pas de propriétés spécifiques à celles héritées de `IOException`.

### Constructeurs principaux

```csharp
PathTooLongException()
PathTooLongException(string message)
PathTooLongException(string message, Exception innerException)
```

### Limites de longueur des chemins

Les limites de longueur des chemins varient selon le système d'exploitation et la méthode d'accès utilisée :

#### Windows

- **Limite standard** : 260 caractères (MAX_PATH) pour les chemins complets, incluant la lettre de lecteur, les séparateurs et le caractère nul de fin.
- **Limite étendue** : Jusqu'à environ 32 767 caractères avec le préfixe `\\?\` (nécessite un support spécifique dans le code).
- **Limite par composant** : 255 caractères pour chaque composant du chemin (nom de fichier ou de répertoire).

#### Unix/Linux

- **Limite standard** : Généralement 4096 caractères (PATH_MAX) pour les chemins complets.
- **Limite par composant** : 255 caractères (NAME_MAX) pour chaque composant du chemin.

#### .NET

- Suit généralement les limites du système d'exploitation sous-jacent.
- Certaines méthodes .NET peuvent avoir leurs propres limites ou comportements spécifiques.

### Exemples en PowerShell

```powershell
# Exemple 1: Création d'un chemin trop long
function Create-LongPath {
    param (
        [int]$Length = 300
    )

    # Créer un chemin de base dans le répertoire temporaire
    $basePath = [System.IO.Path]::GetTempPath()

    # Calculer la longueur nécessaire pour le nom de fichier
    $baseLength = $basePath.Length
    $fileNameLength = $Length - $baseLength - 1  # -1 pour le séparateur

    # Créer un nom de fichier de la longueur requise
    $fileName = "A" * $fileNameLength + ".txt"

    # Construire le chemin complet
    $longPath = [System.IO.Path]::Combine($basePath, $fileName)

    Write-Host "Longueur du chemin de base: $baseLength caractères"
    Write-Host "Longueur du nom de fichier: $fileNameLength caractères"
    Write-Host "Longueur totale du chemin: $($longPath.Length) caractères"

    return $longPath
}

# Créer un chemin qui dépasse la limite standard de Windows (260 caractères)
$longPath = Create-LongPath -Length 300

# Exemple 2: Tentative d'accès à un fichier avec un chemin trop long
function Access-LongPath {
    param (
        [string]$FilePath
    )

    try {
        # Tenter de créer le fichier
        [System.IO.File]::WriteAllText($FilePath, "Test content")
        Write-Host "Fichier créé avec succès: $FilePath"
        return $true
    } catch [System.IO.PathTooLongException] {
        Write-Host "Erreur: Le chemin est trop long"
        Write-Host "Détails: $($_.Exception.Message)"
        Write-Host "Longueur du chemin: $($FilePath.Length) caractères"
        return $false
    } catch {
        Write-Host "Autre erreur: $($_.Exception.GetType().FullName)"
        Write-Host "Message: $($_.Exception.Message)"
        return $false
    }
}

# Tenter d'accéder à un fichier avec un chemin trop long
Access-LongPath -FilePath $longPath

# Sortie:
# Longueur du chemin de base: 9 caractères
# Longueur du nom de fichier: 290 caractères
# Longueur totale du chemin: 300 caractères
# Erreur: Le chemin est trop long
# Détails: The specified path, file name, or both are too long. The fully qualified file name must be less than 260 characters, and the directory name must be less than 248 characters.
# Longueur du chemin: 300 caractères

# Exemple 3: Utilisation du préfixe \\?\ pour contourner la limite standard sous Windows
function Access-LongPathWithPrefix {
    param (
        [string]$FilePath
    )

    try {
        # Ajouter le préfixe \\?\ pour contourner la limite standard
        $prefixedPath = "\\?\" + $FilePath

        # Tenter de créer le fichier avec le chemin préfixé
        # Note: Cela peut ne pas fonctionner dans toutes les versions de PowerShell
        # car certaines méthodes .NET ne supportent pas les chemins étendus
        [System.IO.File]::WriteAllText($prefixedPath, "Test content")
        Write-Host "Fichier créé avec succès avec le préfixe \\?\: $prefixedPath"
        return $true
    } catch [System.IO.PathTooLongException] {
        Write-Host "Erreur: Le chemin est toujours trop long même avec le préfixe \\?\"
        Write-Host "Détails: $($_.Exception.Message)"
        return $false
    } catch {
        Write-Host "Autre erreur: $($_.Exception.GetType().FullName)"
        Write-Host "Message: $($_.Exception.Message)"
        return $false
    }
}

# Tenter d'accéder à un fichier avec un chemin trop long en utilisant le préfixe \\?\
Access-LongPathWithPrefix -FilePath $longPath

# Exemple 4: Création de répertoires profondément imbriqués
function Create-DeepNestedDirectories {
    param (
        [int]$Depth = 50,
        [string]$BasePath = $null
    )

    if ($null -eq $BasePath) {
        $BasePath = [System.IO.Path]::Combine([System.IO.Path]::GetTempPath(), "DeepTest")
    }

    try {
        # Créer le répertoire de base
        if (-not [System.IO.Directory]::Exists($BasePath)) {
            [System.IO.Directory]::CreateDirectory($BasePath) | Out-Null
        }

        $currentPath = $BasePath

        # Créer des répertoires imbriqués
        for ($i = 1; $i -le $Depth; $i++) {
            $currentPath = [System.IO.Path]::Combine($currentPath, "Level$i")

            try {
                [System.IO.Directory]::CreateDirectory($currentPath) | Out-Null
                Write-Host "Répertoire créé: $currentPath"
                Write-Host "Longueur du chemin: $($currentPath.Length) caractères"
            } catch [System.IO.PathTooLongException] {
                Write-Host "Erreur à la profondeur $i: Le chemin est trop long"
                Write-Host "Longueur du chemin: $($currentPath.Length) caractères"
                return $currentPath
            } catch {
                Write-Host "Autre erreur à la profondeur $i: $($_.Exception.GetType().FullName)"
                Write-Host "Message: $($_.Exception.Message)"
                return $currentPath
            }
        }

        return $currentPath
    } finally {
        # Nettoyer (suppression du répertoire de base)
        if ([System.IO.Directory]::Exists($BasePath)) {
            try {
                [System.IO.Directory]::Delete($BasePath, $true)
            } catch {
                Write-Host "Erreur lors du nettoyage: $($_.Exception.Message)"
            }
        }
    }
}

# Créer des répertoires profondément imbriqués jusqu'à atteindre la limite
Create-DeepNestedDirectories -Depth 50

# Exemple 5: Raccourcissement d'un chemin trop long
function Shorten-Path {
    param (
        [string]$LongPath,
        [int]$MaxLength = 259
    )

    # Si le chemin est déjà assez court, le retourner tel quel
    if ($LongPath.Length -le $MaxLength) {
        return $LongPath
    }

    # Décomposer le chemin
    $directory = [System.IO.Path]::GetDirectoryName($LongPath)
    $fileName = [System.IO.Path]::GetFileName($LongPath)
    $extension = [System.IO.Path]::GetExtension($LongPath)
    $fileNameWithoutExt = [System.IO.Path]::GetFileNameWithoutExtension($LongPath)

    # Calculer la longueur maximale pour le nom de fichier
    $maxFileNameLength = $MaxLength - $directory.Length - $extension.Length - 1  # -1 pour le séparateur

    # Si le nom de fichier est trop long, le tronquer
    if ($fileNameWithoutExt.Length > $maxFileNameLength) {
        $shortenedFileName = $fileNameWithoutExt.Substring(0, $maxFileNameLength) + $extension
        $shortenedPath = [System.IO.Path]::Combine($directory, $shortenedFileName)

        Write-Host "Chemin original: $LongPath"
        Write-Host "Longueur originale: $($LongPath.Length) caractères"
        Write-Host "Chemin raccourci: $shortenedPath"
        Write-Host "Longueur raccourcie: $($shortenedPath.Length) caractères"

        return $shortenedPath
    }

    # Si le problème n'est pas le nom de fichier, utiliser une approche différente
    Write-Host "Le nom de fichier n'est pas le problème, le répertoire est trop profond"
    return $LongPath
}

# Raccourcir un chemin trop long
$shortenedPath = Shorten-Path -LongPath $longPath -MaxLength 259
```

### Prévention des PathTooLongException

Voici plusieurs techniques pour éviter les `PathTooLongException` :

#### 1. Vérification préalable de la longueur du chemin

```powershell
function Validate-PathLength {
    param (
        [string]$Path,
        [int]$MaxLength = 259
    )

    if ($Path.Length > $MaxLength) {
        Write-Host "Avertissement: Le chemin dépasse la longueur maximale recommandée"
        Write-Host "Longueur du chemin: $($Path.Length) caractères"
        Write-Host "Longueur maximale recommandée: $MaxLength caractères"
        return $false
    }

    return $true
}
```

#### 2. Utilisation de chemins relatifs courts

```powershell
function Use-RelativePath {
    param (
        [string]$BasePath,
        [string]$TargetPath
    )

    # Obtenir le chemin relatif
    $relativePath = [System.IO.Path]::GetRelativePath($BasePath, $TargetPath)

    Write-Host "Chemin absolu: $TargetPath"
    Write-Host "Longueur absolue: $($TargetPath.Length) caractères"
    Write-Host "Chemin relatif à partir de $BasePath: $relativePath"
    Write-Host "Longueur relative: $($relativePath.Length) caractères"

    return $relativePath
}
```

#### 3. Utilisation de chemins courts (8.3) sous Windows

```powershell
function Get-ShortPath {
    param (
        [string]$LongPath
    )

    # Cette fonction nécessite Windows et utilise la commande cmd.exe
    if (-not $IsWindows -and -not $env:OS.Contains("Windows")) {
        Write-Host "Cette fonction n'est disponible que sous Windows"
        return $LongPath
    }

    try {
        $shortPath = (New-Object -ComObject Scripting.FileSystemObject).GetFile($LongPath).ShortPath

        Write-Host "Chemin long: $LongPath"
        Write-Host "Longueur: $($LongPath.Length) caractères"
        Write-Host "Chemin court (8.3): $shortPath"
        Write-Host "Longueur: $($shortPath.Length) caractères"

        return $shortPath
    } catch {
        Write-Host "Erreur lors de l'obtention du chemin court: $($_.Exception.Message)"
        return $LongPath
    }
}
```

#### 4. Utilisation du préfixe \\?\ sous Windows

```powershell
function Use-ExtendedLengthPath {
    param (
        [string]$Path
    )

    # Vérifier si le chemin est déjà préfixé
    if ($Path.StartsWith("\\?\")) {
        return $Path
    }

    # Convertir en chemin absolu si ce n'est pas déjà le cas
    if (-not [System.IO.Path]::IsPathRooted($Path)) {
        $Path = [System.IO.Path]::GetFullPath($Path)
    }

    # Ajouter le préfixe
    $extendedPath = "\\?\" + $Path

    Write-Host "Chemin original: $Path"
    Write-Host "Chemin étendu: $extendedPath"

    return $extendedPath
}
```

#### 5. Utilisation de mappages de lecteurs ou de jonctions

```powershell
function Create-DriveMapping {
    param (
        [string]$LongPath,
        [string]$DriveLetter = "Z"
    )

    # Cette fonction nécessite Windows et des privilèges administratifs
    if (-not $IsWindows -and -not $env:OS.Contains("Windows")) {
        Write-Host "Cette fonction n'est disponible que sous Windows"
        return $LongPath
    }

    try {
        # Supprimer le mapping existant s'il existe
        $existingMapping = Get-PSDrive -Name $DriveLetter -ErrorAction SilentlyContinue
        if ($existingMapping) {
            Remove-PSDrive -Name $DriveLetter -Force
        }

        # Créer un nouveau mapping
        New-PSDrive -Name $DriveLetter -PSProvider FileSystem -Root $LongPath -Scope Global

        $shortPath = $DriveLetter + ":\"

        Write-Host "Chemin long: $LongPath"
        Write-Host "Longueur: $($LongPath.Length) caractères"
        Write-Host "Mapping créé: $shortPath"
        Write-Host "Longueur: $($shortPath.Length) caractères"

        return $shortPath
    } catch {
        Write-Host "Erreur lors de la création du mapping: $($_.Exception.Message)"
        return $LongPath
    }
}
```

### Débogage des PathTooLongException

Lorsque vous rencontrez une `PathTooLongException`, voici quelques étapes pour la déboguer efficacement :

1. **Identifier la longueur du chemin** : Déterminez la longueur exacte du chemin qui pose problème.

2. **Vérifier les limites du système** : Assurez-vous de connaître les limites exactes de votre système d'exploitation et de votre environnement .NET.

3. **Analyser la structure du chemin** : Identifiez les parties du chemin qui contribuent le plus à sa longueur.

4. **Tester des alternatives** : Essayez différentes approches pour contourner la limite, comme l'utilisation de chemins relatifs ou de préfixes spéciaux.

5. **Vérifier la compatibilité des API** : Certaines API .NET peuvent avoir des comportements différents face aux chemins longs.

```powershell
function Debug-PathTooLongException {
    param (
        [string]$Path
    )

    Write-Host "Débogage de PathTooLongException pour le chemin: $Path"
    Write-Host "Longueur totale du chemin: $($Path.Length) caractères"

    # Décomposer le chemin
    $directory = [System.IO.Path]::GetDirectoryName($Path)
    $fileName = [System.IO.Path]::GetFileName($Path)
    $extension = [System.IO.Path]::GetExtension($Path)
    $fileNameWithoutExt = [System.IO.Path]::GetFileNameWithoutExtension($Path)

    Write-Host "Répertoire: $directory"
    Write-Host "Longueur du répertoire: $($directory.Length) caractères"
    Write-Host "Nom de fichier: $fileName"
    Write-Host "Longueur du nom de fichier: $($fileName.Length) caractères"
    Write-Host "Extension: $extension"
    Write-Host "Nom de fichier sans extension: $fileNameWithoutExt"

    # Analyser la profondeur du chemin
    $parts = $Path.Split([System.IO.Path]::DirectorySeparatorChar)
    Write-Host "Nombre de composants dans le chemin: $($parts.Length)"

    # Afficher les composants les plus longs
    $longComponents = $parts | Where-Object { $_.Length -gt 20 } | Sort-Object -Property Length -Descending
    if ($longComponents.Count -gt 0) {
        Write-Host "Composants les plus longs:"
        foreach ($component in $longComponents) {
            Write-Host "  - $component ($($component.Length) caractères)"
        }
    }

    # Vérifier si le préfixe \\?\ pourrait aider
    if (-not $Path.StartsWith("\\?\") -and $Path.Length -gt 259 -and $Path.Length -lt 32767) {
        Write-Host "Suggestion: Essayez d'utiliser le préfixe \\?\ pour contourner la limite standard"
    }

    # Vérifier si un chemin relatif pourrait aider
    $currentDirectory = (Get-Location).Path
    $relativePath = [System.IO.Path]::GetRelativePath($currentDirectory, $Path)
    if ($relativePath.Length < $Path.Length) {
        Write-Host "Suggestion: Utilisez un chemin relatif à partir du répertoire courant"
        Write-Host "Chemin relatif: $relativePath"
        Write-Host "Longueur: $($relativePath.Length) caractères"
    }
}

# Exemple d'utilisation
Debug-PathTooLongException -Path $longPath
```

### Bonnes pratiques pour gérer les PathTooLongException

1. **Conception préventive** : Concevez votre structure de répertoires pour éviter les chemins trop longs.

2. **Validation préalable** : Vérifiez la longueur des chemins avant de tenter des opérations sur les fichiers.

3. **Utilisation de chemins relatifs** : Utilisez des chemins relatifs plutôt que des chemins absolus lorsque c'est possible.

4. **Raccourcissement des noms** : Utilisez des noms de fichiers et de répertoires courts et significatifs.

5. **Utilisation de techniques spécifiques à la plateforme** : Utilisez des techniques comme le préfixe `\\?\` sous Windows lorsque c'est nécessaire.

6. **Mappages de lecteurs** : Utilisez des mappages de lecteurs ou des jonctions pour raccourcir les chemins d'accès.

7. **Gestion des erreurs** : Implémentez une gestion appropriée des erreurs pour les cas où une `PathTooLongException` est inévitable.

### Résumé

`PathTooLongException` est une exception qui est levée lorsqu'un chemin de fichier ou de répertoire dépasse la longueur maximale autorisée par le système d'exploitation. Cette exception est une sous-classe de `IOException` et est spécifiquement utilisée pour signaler des problèmes liés à la longueur des chemins.

En comprenant les limites de longueur des chemins sur différentes plateformes et en appliquant les bonnes pratiques pour la prévention et le débogage, vous pouvez développer des applications plus robustes qui gèrent efficacement les erreurs liées aux chemins trop longs.

## UnauthorizedAccessException et ses permissions

### Vue d'ensemble

`UnauthorizedAccessException` est une exception qui est levée lorsqu'une opération n'est pas autorisée par le système d'exploitation, généralement en raison de restrictions de permissions. Cette exception peut être levée lors de tentatives d'accès à des fichiers, des répertoires, des registres ou d'autres ressources protégées sans les autorisations nécessaires.

### Hiérarchie

```
System.Exception
└── System.SystemException
    └── System.UnauthorizedAccessException
```

Contrairement aux exceptions précédentes, `UnauthorizedAccessException` n'est pas une sous-classe de `IOException`, mais plutôt une sous-classe directe de `SystemException`. Cela reflète le fait que les problèmes d'accès non autorisé peuvent survenir dans divers contextes, pas seulement dans les opérations d'entrée/sortie.

### Description

`UnauthorizedAccessException` est levée dans plusieurs contextes liés aux permissions et aux droits d'accès :

1. **Opérations sur les fichiers et répertoires** : Tentatives de lecture, d'écriture, de création ou de suppression de fichiers ou de répertoires sans les permissions nécessaires.

2. **Accès au registre** : Tentatives d'accès ou de modification des clés de registre sans les permissions appropriées.

3. **Opérations réseau** : Tentatives d'accès à des ressources réseau sans les autorisations requises.

4. **Opérations de sécurité** : Tentatives d'exécution d'opérations nécessitant des privilèges élevés.

### Propriétés spécifiques

`UnauthorizedAccessException` n'ajoute pas de propriétés spécifiques à celles héritées de `Exception`, mais elle fournit des informations détaillées dans sa propriété `Message`. Voici les propriétés héritées les plus pertinentes pour le diagnostic des problèmes d'accès non autorisé :

| Propriété | Type | Description |
|-----------|------|-------------|
| Message | string | Message décrivant l'erreur, incluant souvent le chemin d'accès et le type d'opération qui a échoué |
| StackTrace | string | Trace de la pile d'appels au moment où l'exception a été levée |
| Source | string | Nom de l'application ou de l'objet qui a causé l'erreur |
| HResult | int | Code d'erreur numérique associé à l'exception (généralement 0x80070005 pour les erreurs d'accès) |
| InnerException | Exception | Exception interne qui a causé l'exception actuelle (si applicable) |

### Codes HResult courants

Le code HResult pour `UnauthorizedAccessException` est généralement `0x80070005`, qui correspond à `E_ACCESSDENIED` (Accès refusé) dans les codes d'erreur Windows.

### Constructeurs principaux

```csharp
UnauthorizedAccessException()
// Initialise une nouvelle instance avec un message par défaut

UnauthorizedAccessException(string message)
// Initialise une nouvelle instance avec un message d'erreur spécifié

UnauthorizedAccessException(string message, Exception innerException)
// Initialise une nouvelle instance avec un message d'erreur spécifié et une référence à l'exception interne
```

### Différence avec SecurityException

Il est important de distinguer `UnauthorizedAccessException` de `SecurityException` :

- **UnauthorizedAccessException** : Levée par le système d'exploitation lorsqu'une opération n'est pas autorisée en raison des permissions du système de fichiers ou d'autres restrictions d'accès au niveau du système d'exploitation.

- **SecurityException** : Levée par le Common Language Runtime (CLR) lorsqu'une opération n'est pas autorisée en raison des restrictions de la politique de sécurité .NET, comme les restrictions de Code Access Security (CAS).

### Scénarios courants d'accès non autorisé

#### 1. Accès aux fichiers et répertoires

Les scénarios les plus courants impliquent des opérations sur les fichiers et les répertoires :

- **Lecture d'un fichier protégé** : Tentative de lecture d'un fichier pour lequel l'utilisateur n'a pas de permissions de lecture.

```powershell
try {
    $content = [System.IO.File]::ReadAllText("C:\Windows\System32\config\SAM")
    Write-Host "Contenu lu avec succès"
} catch [System.UnauthorizedAccessException] {
    Write-Host "Accès non autorisé : Vous n'avez pas les permissions pour lire ce fichier"
}
```

- **Écriture dans un fichier en lecture seule** : Tentative de modification d'un fichier en lecture seule ou pour lequel l'utilisateur n'a pas de permissions d'écriture.

```powershell
try {
    [System.IO.File]::WriteAllText("C:\Windows\System32\drivers\etc\hosts", "127.0.0.1 localhost")
    Write-Host "Fichier modifié avec succès"
} catch [System.UnauthorizedAccessException] {
    Write-Host "Accès non autorisé : Vous n'avez pas les permissions pour modifier ce fichier"
}
```

- **Suppression d'un fichier verrouillé** : Tentative de suppression d'un fichier qui est en cours d'utilisation par un autre processus ou pour lequel l'utilisateur n'a pas de permissions de suppression.

```powershell
try {
    [System.IO.File]::Delete("C:\Windows\System32\ntoskrnl.exe")
    Write-Host "Fichier supprimé avec succès"
} catch [System.UnauthorizedAccessException] {
    Write-Host "Accès non autorisé : Vous n'avez pas les permissions pour supprimer ce fichier"
} catch [System.IO.IOException] {
    Write-Host "Le fichier est en cours d'utilisation par un autre processus"
}
```

- **Accès à un répertoire restreint** : Tentative d'accès à un répertoire pour lequel l'utilisateur n'a pas de permissions d'accès.

```powershell
try {
    $files = [System.IO.Directory]::GetFiles("C:\Windows\System32\config")
    Write-Host "Nombre de fichiers : $($files.Count)"
} catch [System.UnauthorizedAccessException] {
    Write-Host "Accès non autorisé : Vous n'avez pas les permissions pour accéder à ce répertoire"
}
```

- **Création d'un fichier dans un répertoire protégé** : Tentative de création d'un fichier dans un répertoire pour lequel l'utilisateur n'a pas de permissions d'écriture.

```powershell
try {
    [System.IO.File]::WriteAllText("C:\Windows\System32\test.txt", "Test")
    Write-Host "Fichier créé avec succès"
} catch [System.UnauthorizedAccessException] {
    Write-Host "Accès non autorisé : Vous n'avez pas les permissions pour créer un fichier dans ce répertoire"
}
```

#### 2. Accès au registre

Les opérations sur le registre Windows peuvent également générer des `UnauthorizedAccessException` :

- **Lecture d'une clé de registre protégée** : Tentative de lecture d'une clé de registre pour laquelle l'utilisateur n'a pas de permissions de lecture.

```powershell
try {
    $key = [Microsoft.Win32.Registry]::LocalMachine.OpenSubKey("SAM")
    if ($key -ne $null) {
        $valueNames = $key.GetValueNames()
        Write-Host "Valeurs : $valueNames"
        $key.Close()
    }
} catch [System.UnauthorizedAccessException] {
    Write-Host "Accès non autorisé : Vous n'avez pas les permissions pour lire cette clé de registre"
}
```

- **Écriture dans une clé de registre protégée** : Tentative de modification d'une clé de registre pour laquelle l'utilisateur n'a pas de permissions d'écriture.

```powershell
try {
    $key = [Microsoft.Win32.Registry]::LocalMachine.OpenSubKey("SOFTWARE\Microsoft\Windows NT\CurrentVersion", $true)
    if ($key -ne $null) {
        $key.SetValue("TestValue", "TestData")
        $key.Close()
        Write-Host "Valeur de registre créée avec succès"
    }
} catch [System.UnauthorizedAccessException] {
    Write-Host "Accès non autorisé : Vous n'avez pas les permissions pour modifier cette clé de registre"
}
```

#### 3. Opérations réseau

Les opérations réseau peuvent également générer des `UnauthorizedAccessException` :

- **Accès à un partage réseau protégé** : Tentative d'accès à un partage réseau pour lequel l'utilisateur n'a pas de permissions d'accès.

```powershell
try {
    $files = [System.IO.Directory]::GetFiles("\\Server\ProtectedShare")
    Write-Host "Nombre de fichiers : $($files.Count)"
} catch [System.UnauthorizedAccessException] {
    Write-Host "Accès non autorisé : Vous n'avez pas les permissions pour accéder à ce partage réseau"
} catch [System.IO.IOException] {
    Write-Host "Erreur d'E/S lors de l'accès au partage réseau"
}
```

- **Liaison à un port réseau réservé** : Tentative de liaison à un port réseau inférieur à 1024 sans privilèges administratifs.

```powershell
try {
    $listener = New-Object System.Net.Sockets.TcpListener([System.Net.IPAddress]::Any, 80)
    $listener.Start()
    Write-Host "Écoute sur le port 80"
    # ... autres opérations ...
    $listener.Stop()
} catch [System.Net.Sockets.SocketException] {
    # Sur Windows, cela génère généralement une SocketException plutôt qu'une UnauthorizedAccessException
    Write-Host "Accès non autorisé : Vous n'avez pas les permissions pour écouter sur le port 80"
}
```

#### 4. Opérations de sécurité

Les opérations liées à la sécurité peuvent également générer des `UnauthorizedAccessException` :

- **Accès à des informations d'identification protégées** : Tentative d'accès à des informations d'identification ou à des secrets protégés.

```powershell
try {
    # Tentative d'accès à des informations d'identification protégées
    $credential = [System.Security.Cryptography.ProtectedData]::Unprotect($protectedData, $null, [System.Security.Cryptography.DataProtectionScope]::LocalMachine)
    Write-Host "Informations d'identification déchiffrées avec succès"
} catch [System.UnauthorizedAccessException] {
    Write-Host "Accès non autorisé : Vous n'avez pas les permissions pour déchiffrer ces données"
} catch [System.Security.Cryptography.CryptographicException] {
    Write-Host "Erreur de déchiffrement"
}
```

- **Modification des paramètres de sécurité** : Tentative de modification des paramètres de sécurité du système sans privilèges administratifs.

```powershell
try {
    # Tentative de modification des paramètres de sécurité
    $securityPolicy = [System.Security.SecurityManager]::GetStandardSandbox($null)
    # ... opérations de modification ...
    Write-Host "Paramètres de sécurité modifiés avec succès"
} catch [System.UnauthorizedAccessException] {
    Write-Host "Accès non autorisé : Vous n'avez pas les permissions pour modifier les paramètres de sécurité"
} catch [System.Security.SecurityException] {
    Write-Host "Violation de la politique de sécurité"
}
```

### Types de permissions et leurs implications

Les `UnauthorizedAccessException` sont souvent liées à des problèmes de permissions. Comprendre les différents types de permissions est essentiel pour diagnostiquer et résoudre ces problèmes.

#### Permissions du système de fichiers Windows

Dans Windows, les permissions du système de fichiers sont gérées par les listes de contrôle d'accès (ACL) et peuvent être visualisées et modifiées via l'interface graphique ou via PowerShell.

##### Permissions de base

| Permission | Description | Opérations typiques | Exception si refusée |
|------------|-------------|---------------------|----------------------|
| **Lecture** | Permet de lire le contenu d'un fichier ou de lister le contenu d'un répertoire | `Get-Content`, `Get-ChildItem`, `[System.IO.File]::ReadAllText()` | `UnauthorizedAccessException` lors de la lecture |
| **Écriture** | Permet de modifier le contenu d'un fichier ou de créer des fichiers dans un répertoire | `Set-Content`, `New-Item`, `[System.IO.File]::WriteAllText()` | `UnauthorizedAccessException` lors de l'écriture |
| **Exécution** | Permet d'exécuter un fichier ou d'accéder à un répertoire | `Invoke-Expression`, `Start-Process` | `UnauthorizedAccessException` lors de l'exécution |
| **Suppression** | Permet de supprimer un fichier ou un répertoire | `Remove-Item`, `[System.IO.File]::Delete()` | `UnauthorizedAccessException` lors de la suppression |
| **Modification** | Combine les permissions de lecture, d'écriture et d'exécution | Diverses opérations | `UnauthorizedAccessException` selon l'opération |
| **Contrôle total** | Permet toutes les opérations, y compris la modification des permissions | Toutes les opérations | Rarement une `UnauthorizedAccessException` |

##### Permissions spéciales

| Permission | Description | Opérations typiques | Exception si refusée |
|------------|-------------|---------------------|----------------------|
| **Traverse Folder / Execute File** | Permet de traverser des répertoires ou d'exécuter des fichiers | Navigation dans les répertoires, exécution de fichiers | `UnauthorizedAccessException` lors de la navigation ou de l'exécution |
| **List Folder / Read Data** | Permet de lister le contenu d'un répertoire ou de lire les données d'un fichier | Listage de répertoires, lecture de fichiers | `UnauthorizedAccessException` lors du listage ou de la lecture |
| **Read Attributes** | Permet de lire les attributs d'un fichier ou d'un répertoire | Lecture des attributs | `UnauthorizedAccessException` lors de la lecture des attributs |
| **Read Extended Attributes** | Permet de lire les attributs étendus d'un fichier ou d'un répertoire | Lecture des attributs étendus | `UnauthorizedAccessException` lors de la lecture des attributs étendus |
| **Create Files / Write Data** | Permet de créer des fichiers dans un répertoire ou d'écrire des données dans un fichier | Création de fichiers, écriture de données | `UnauthorizedAccessException` lors de la création ou de l'écriture |
| **Create Folders / Append Data** | Permet de créer des sous-répertoires ou d'ajouter des données à un fichier | Création de répertoires, ajout de données | `UnauthorizedAccessException` lors de la création ou de l'ajout |
| **Write Attributes** | Permet de modifier les attributs d'un fichier ou d'un répertoire | Modification des attributs | `UnauthorizedAccessException` lors de la modification des attributs |
| **Write Extended Attributes** | Permet de modifier les attributs étendus d'un fichier ou d'un répertoire | Modification des attributs étendus | `UnauthorizedAccessException` lors de la modification des attributs étendus |
| **Delete Subfolders and Files** | Permet de supprimer des sous-répertoires et des fichiers | Suppression récursive | `UnauthorizedAccessException` lors de la suppression |
| **Delete** | Permet de supprimer un fichier ou un répertoire | Suppression | `UnauthorizedAccessException` lors de la suppression |
| **Read Permissions** | Permet de lire les permissions d'un fichier ou d'un répertoire | Lecture des permissions | `UnauthorizedAccessException` lors de la lecture des permissions |
| **Change Permissions** | Permet de modifier les permissions d'un fichier ou d'un répertoire | Modification des permissions | `UnauthorizedAccessException` lors de la modification des permissions |
| **Take Ownership** | Permet de prendre possession d'un fichier ou d'un répertoire | Prise de possession | `UnauthorizedAccessException` lors de la prise de possession |

#### Vérification et modification des permissions avec PowerShell

PowerShell offre plusieurs cmdlets pour vérifier et modifier les permissions :

```powershell
# Vérifier les permissions d'un fichier
function Get-FilePermissions {
    param (
        [string]$Path
    )

    try {
        $acl = Get-Acl -Path $Path
        Write-Host "Propriétaire : $($acl.Owner)"
        Write-Host "Accès :"

        foreach ($access in $acl.Access) {
            Write-Host "  - Identité : $($access.IdentityReference)"
            Write-Host "    Type : $($access.AccessControlType)"
            Write-Host "    Droits : $($access.FileSystemRights)"
            Write-Host "    Hérité : $($access.IsInherited)"
            Write-Host ""
        }
    } catch [System.UnauthorizedAccessException] {
        Write-Host "Accès non autorisé : Vous n'avez pas les permissions pour lire les permissions de ce fichier"
    } catch {
        Write-Host "Erreur : $($_.Exception.Message)"
    }
}

# Ajouter une permission à un fichier
function Add-FilePermission {
    param (
        [string]$Path,
        [string]$Identity,
        [System.Security.AccessControl.FileSystemRights]$Rights,
        [System.Security.AccessControl.AccessControlType]$AccessType = "Allow"
    )

    try {
        $acl = Get-Acl -Path $Path
        $rule = New-Object System.Security.AccessControl.FileSystemAccessRule($Identity, $Rights, $AccessType)
        $acl.AddAccessRule($rule)
        Set-Acl -Path $Path -AclObject $acl
        Write-Host "Permission ajoutée avec succès"
    } catch [System.UnauthorizedAccessException] {
        Write-Host "Accès non autorisé : Vous n'avez pas les permissions pour modifier les permissions de ce fichier"
    } catch {
        Write-Host "Erreur : $($_.Exception.Message)"
    }
}

# Supprimer une permission d'un fichier
function Remove-FilePermission {
    param (
        [string]$Path,
        [string]$Identity,
        [System.Security.AccessControl.FileSystemRights]$Rights,
        [System.Security.AccessControl.AccessControlType]$AccessType = "Allow"
    )

    try {
        $acl = Get-Acl -Path $Path
        $rule = New-Object System.Security.AccessControl.FileSystemAccessRule($Identity, $Rights, $AccessType)
        $acl.RemoveAccessRule($rule)
        Set-Acl -Path $Path -AclObject $acl
        Write-Host "Permission supprimée avec succès"
    } catch [System.UnauthorizedAccessException] {
        Write-Host "Accès non autorisé : Vous n'avez pas les permissions pour modifier les permissions de ce fichier"
    } catch {
        Write-Host "Erreur : $($_.Exception.Message)"
    }
}

# Exemple d'utilisation
$filePath = "C:\Temp\test.txt"
if (-not (Test-Path -Path $filePath)) {
    Set-Content -Path $filePath -Value "Test content"
}

# Vérifier les permissions actuelles
Get-FilePermissions -Path $filePath

# Ajouter une permission de lecture pour tous les utilisateurs
Add-FilePermission -Path $filePath -Identity "Everyone" -Rights "Read"

# Vérifier les permissions après modification
Get-FilePermissions -Path $filePath

# Supprimer la permission de lecture pour tous les utilisateurs
Remove-FilePermission -Path $filePath -Identity "Everyone" -Rights "Read"

# Vérifier les permissions après suppression
Get-FilePermissions -Path $filePath
```

#### Permissions du registre Windows

Les permissions du registre Windows sont similaires à celles du système de fichiers, mais s'appliquent aux clés de registre :

| Permission | Description | Opérations typiques | Exception si refusée |
|------------|-------------|---------------------|----------------------|
| **Lecture** | Permet de lire les valeurs d'une clé de registre | `Get-ItemProperty`, `[Microsoft.Win32.Registry]::GetValue()` | `UnauthorizedAccessException` lors de la lecture |
| **Écriture** | Permet de modifier les valeurs d'une clé de registre | `Set-ItemProperty`, `[Microsoft.Win32.Registry]::SetValue()` | `UnauthorizedAccessException` lors de l'écriture |
| **Création de sous-clés** | Permet de créer des sous-clés | `New-Item`, `[Microsoft.Win32.Registry]::CreateSubKey()` | `UnauthorizedAccessException` lors de la création |
| **Énumération de sous-clés** | Permet de lister les sous-clés | `Get-ChildItem`, `[Microsoft.Win32.Registry]::GetSubKeyNames()` | `UnauthorizedAccessException` lors de l'énumération |
| **Notification** | Permet de recevoir des notifications de changement | Surveillance des changements | `UnauthorizedAccessException` lors de la configuration de la surveillance |
| **Contrôle total** | Permet toutes les opérations | Toutes les opérations | Rarement une `UnauthorizedAccessException` |

#### Permissions réseau

Les permissions réseau dépendent du type de ressource réseau :

| Type de ressource | Permissions courantes | Opérations typiques | Exception si refusée |
|-------------------|----------------------|---------------------|----------------------|
| **Partages réseau** | Lecture, Écriture, Modification, Contrôle total | Accès aux fichiers et répertoires partagés | `UnauthorizedAccessException` lors de l'accès |
| **Ports réseau** | Liaison, Écoute, Connexion | Création de serveurs, connexion à des services | `SocketException` (généralement) lors de la liaison ou de la connexion |
| **Services réseau** | Démarrage, Arrêt, Modification | Gestion des services | `UnauthorizedAccessException` lors de la gestion |

#### Permissions de sécurité

Les permissions de sécurité concernent les opérations liées à la sécurité du système :

| Type d'opération | Permissions requises | Opérations typiques | Exception si refusée |
|------------------|---------------------|---------------------|----------------------|
| **Gestion des utilisateurs** | Administrateur local ou de domaine | Création, modification, suppression d'utilisateurs | `UnauthorizedAccessException` lors de la gestion |
| **Gestion des certificats** | Administrateur ou permissions spécifiques | Installation, suppression de certificats | `UnauthorizedAccessException` lors de la gestion |
| **Accès aux données protégées** | Propriétaire des données ou permissions spécifiques | Déchiffrement, accès aux secrets | `UnauthorizedAccessException` lors de l'accès |
| **Modification des politiques de sécurité** | Administrateur | Modification des politiques | `UnauthorizedAccessException` lors de la modification |

### Exemples PowerShell pour illustrer les problèmes d'accès

Voici des exemples PowerShell plus complets pour illustrer les problèmes d'accès et la gestion des `UnauthorizedAccessException` :

#### Exemple 1 : Création d'un fichier de test et manipulation des permissions

```powershell
function Test-FilePermissions {
    param (
        [string]$TestDirectory = "$env:TEMP\PermissionTest"
    )

    # Créer un répertoire de test
    if (-not (Test-Path -Path $TestDirectory)) {
        New-Item -Path $TestDirectory -ItemType Directory | Out-Null
        Write-Host "Répertoire de test créé : $TestDirectory" -ForegroundColor Green
    }

    # Créer un fichier de test
    $testFile = Join-Path -Path $TestDirectory -ChildPath "test_file.txt"
    Set-Content -Path $testFile -Value "Contenu de test" -Force
    Write-Host "Fichier de test créé : $testFile" -ForegroundColor Green

    # Obtenir l'utilisateur actuel
    $currentUser = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
    Write-Host "Utilisateur actuel : $currentUser" -ForegroundColor Yellow

    # Afficher les permissions initiales
    Write-Host "`nPermissions initiales :" -ForegroundColor Yellow
    $acl = Get-Acl -Path $testFile
    foreach ($access in $acl.Access) {
        Write-Host "  - $($access.IdentityReference) : $($access.FileSystemRights)" -ForegroundColor Gray
    }

    # Retirer toutes les permissions pour l'utilisateur actuel
    Write-Host "`nRetrait des permissions pour l'utilisateur actuel..." -ForegroundColor Yellow
    $acl = Get-Acl -Path $testFile
    $accessRulesToRemove = $acl.Access | Where-Object { $_.IdentityReference.Value -eq $currentUser }
    foreach ($rule in $accessRulesToRemove) {
        $acl.RemoveAccessRule($rule) | Out-Null
    }
    Set-Acl -Path $testFile -AclObject $acl

    # Tenter de lire le fichier sans permissions
    Write-Host "`nTentative de lecture du fichier sans permissions :" -ForegroundColor Yellow
    try {
        $content = Get-Content -Path $testFile -ErrorAction Stop
        Write-Host "Contenu lu avec succès : $content" -ForegroundColor Green
    } catch [System.UnauthorizedAccessException] {
        Write-Host "Erreur d'accès non autorisé : $($_.Exception.Message)" -ForegroundColor Red
        Write-Host "Type d'exception : $($_.Exception.GetType().FullName)" -ForegroundColor Red
    } catch {
        Write-Host "Autre erreur : $($_.Exception.Message)" -ForegroundColor Red
    }

    # Restaurer les permissions
    Write-Host "`nRestauration des permissions..." -ForegroundColor Yellow
    $acl = Get-Acl -Path $TestDirectory
    Set-Acl -Path $testFile -AclObject $acl

    # Tenter de lire le fichier avec les permissions restaurées
    Write-Host "`nTentative de lecture du fichier avec permissions restaurées :" -ForegroundColor Yellow
    try {
        $content = Get-Content -Path $testFile -ErrorAction Stop
        Write-Host "Contenu lu avec succès : $content" -ForegroundColor Green
    } catch {
        Write-Host "Erreur : $($_.Exception.Message)" -ForegroundColor Red
    }

    # Nettoyage
    Write-Host "`nNettoyage..." -ForegroundColor Yellow
    Remove-Item -Path $TestDirectory -Recurse -Force -ErrorAction SilentlyContinue
    if (-not (Test-Path -Path $TestDirectory)) {
        Write-Host "Répertoire de test supprimé" -ForegroundColor Green
    } else {
        Write-Host "Impossible de supprimer le répertoire de test" -ForegroundColor Red
    }
}

# Exécuter le test
Test-FilePermissions
```

#### Exemple 2 : Tentative d'accès à des fichiers système protégés

```powershell
function Test-SystemFileAccess {
    # Liste de fichiers système protégés
    $protectedFiles = @(
        "$env:windir\System32\config\SAM",
        "$env:windir\System32\config\SECURITY",
        "$env:windir\System32\config\SOFTWARE",
        "$env:windir\System32\config\SYSTEM",
        "$env:windir\System32\ntoskrnl.exe"
    )

    foreach ($file in $protectedFiles) {
        Write-Host "`nTest d'accès au fichier : $file" -ForegroundColor Yellow

        # Vérifier si le fichier existe
        if (-not (Test-Path -Path $file)) {
            Write-Host "Le fichier n'existe pas" -ForegroundColor Red
            continue
        }

        # Tenter de lire le fichier
        Write-Host "Tentative de lecture..." -ForegroundColor Yellow
        try {
            $content = Get-Content -Path $file -TotalCount 1 -ErrorAction Stop
            Write-Host "Lecture réussie (inattendu)" -ForegroundColor Green
        } catch [System.UnauthorizedAccessException] {
            Write-Host "Erreur d'accès non autorisé : $($_.Exception.Message)" -ForegroundColor Red

            # Afficher les détails de l'exception
            Write-Host "  - Type d'exception : $($_.Exception.GetType().FullName)" -ForegroundColor Gray
            Write-Host "  - Message : $($_.Exception.Message)" -ForegroundColor Gray
            Write-Host "  - HResult : 0x$($_.Exception.HResult.ToString("X8"))" -ForegroundColor Gray

            # Afficher les permissions actuelles
            try {
                $acl = Get-Acl -Path $file -ErrorAction Stop
                Write-Host "  - Propriétaire : $($acl.Owner)" -ForegroundColor Gray
                Write-Host "  - Groupe : $($acl.Group)" -ForegroundColor Gray
                Write-Host "  - Accès :" -ForegroundColor Gray
                foreach ($access in $acl.Access) {
                    Write-Host "    * $($access.IdentityReference) : $($access.FileSystemRights)" -ForegroundColor Gray
                }
            } catch {
                Write-Host "  - Impossible de lire les permissions : $($_.Exception.Message)" -ForegroundColor Gray
            }
        } catch {
            Write-Host "Autre erreur : $($_.Exception.Message)" -ForegroundColor Red
        }

        # Tenter de modifier le fichier
        Write-Host "Tentative d'écriture..." -ForegroundColor Yellow
        try {
            Set-Content -Path $file -Value "Test" -ErrorAction Stop
            Write-Host "Écriture réussie (inattendu)" -ForegroundColor Green
        } catch [System.UnauthorizedAccessException] {
            Write-Host "Erreur d'accès non autorisé : $($_.Exception.Message)" -ForegroundColor Red
        } catch {
            Write-Host "Autre erreur : $($_.Exception.Message)" -ForegroundColor Red
        }
    }
}

# Exécuter le test
Test-SystemFileAccess
```

#### Exemple 3 : Tentative d'accès au registre protégé

```powershell
function Test-RegistryAccess {
    # Liste de clés de registre protégées
    $protectedKeys = @(
        "HKLM:\SAM",
        "HKLM:\SECURITY",
        "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon",
        "HKLM:\SYSTEM\CurrentControlSet\Control\Lsa"
    )

    foreach ($key in $protectedKeys) {
        Write-Host "`nTest d'accès à la clé de registre : $key" -ForegroundColor Yellow

        # Vérifier si la clé existe
        if (-not (Test-Path -Path $key)) {
            Write-Host "La clé n'existe pas" -ForegroundColor Red
            continue
        }

        # Tenter de lire la clé
        Write-Host "Tentative de lecture..." -ForegroundColor Yellow
        try {
            $values = Get-ItemProperty -Path $key -ErrorAction Stop
            Write-Host "Lecture réussie" -ForegroundColor Green
            Write-Host "Nombre de valeurs : $($values.PSObject.Properties.Count)" -ForegroundColor Gray
        } catch [System.UnauthorizedAccessException] {
            Write-Host "Erreur d'accès non autorisé : $($_.Exception.Message)" -ForegroundColor Red
        } catch {
            Write-Host "Autre erreur : $($_.Exception.Message)" -ForegroundColor Red
        }

        # Tenter de créer une nouvelle valeur
        Write-Host "Tentative d'écriture..." -ForegroundColor Yellow
        try {
            Set-ItemProperty -Path $key -Name "TestValue" -Value "Test" -ErrorAction Stop
            Write-Host "Écriture réussie" -ForegroundColor Green

            # Supprimer la valeur de test si elle a été créée
            Remove-ItemProperty -Path $key -Name "TestValue" -ErrorAction SilentlyContinue
        } catch [System.UnauthorizedAccessException] {
            Write-Host "Erreur d'accès non autorisé : $($_.Exception.Message)" -ForegroundColor Red
        } catch {
            Write-Host "Autre erreur : $($_.Exception.Message)" -ForegroundColor Red
        }
    }
}

# Exécuter le test
Test-RegistryAccess
```

#### Exemple 4 : Élévation de privilèges et contournement des restrictions d'accès

```powershell
function Test-PrivilegeElevation {
    # Vérifier si le script s'exécute avec des privilèges administratifs
    $isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

    Write-Host "Exécution avec privilèges administratifs : $isAdmin" -ForegroundColor Yellow

    # Fichier de test dans un emplacement protégé
    $protectedFile = "$env:windir\System32\test_admin.txt"

    # Tenter d'accéder au fichier sans élévation
    Write-Host "`nTentative d'accès sans élévation :" -ForegroundColor Yellow
    try {
        Set-Content -Path $protectedFile -Value "Test" -ErrorAction Stop
        Write-Host "Écriture réussie" -ForegroundColor Green

        # Nettoyer
        Remove-Item -Path $protectedFile -ErrorAction SilentlyContinue
    } catch [System.UnauthorizedAccessException] {
        Write-Host "Erreur d'accès non autorisé : $($_.Exception.Message)" -ForegroundColor Red
    } catch {
        Write-Host "Autre erreur : $($_.Exception.Message)" -ForegroundColor Red
    }

    # Si nous ne sommes pas administrateur, suggérer une élévation
    if (-not $isAdmin) {
        Write-Host "`nPour contourner cette restriction, vous pouvez exécuter PowerShell en tant qu'administrateur :" -ForegroundColor Yellow
        Write-Host "Start-Process PowerShell -Verb RunAs" -ForegroundColor Gray
    } else {
        Write-Host "`nVous êtes déjà administrateur, vous devriez pouvoir accéder à la plupart des fichiers système" -ForegroundColor Green
    }

    # Démontrer l'utilisation de l'impersonation (nécessite des privilèges élevés)
    Write-Host "`nDémonstration d'impersonation (nécessite des privilèges élevés) :" -ForegroundColor Yellow
    try {
        Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;
using System.Security.Principal;

public class Impersonation {
    [DllImport("advapi32.dll", SetLastError = true)]
    public static extern bool LogonUser(string lpszUsername, string lpszDomain, string lpszPassword,
        int dwLogonType, int dwLogonProvider, ref IntPtr phToken);

    [DllImport("kernel32.dll", SetLastError = true)]
    public static extern bool CloseHandle(IntPtr hObject);
}
"@

        Write-Host "Type d'impersonation ajouté avec succès" -ForegroundColor Green
        Write-Host "Cette fonctionnalité permettrait d'exécuter du code sous l'identité d'un autre utilisateur" -ForegroundColor Gray
    } catch {
        Write-Host "Erreur lors de l'ajout du type d'impersonation : $($_.Exception.Message)" -ForegroundColor Red
    }
}

# Exécuter le test
Test-PrivilegeElevation
```

#### Exemple 5 : Utilisation de l'API Windows pour obtenir des informations détaillées sur les erreurs d'accès

```powershell
function Get-DetailedAccessError {
    param (
        [string]$Path
    )

    # Ajouter les types nécessaires
    Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;
using System.Text;

public class NativeMethods {
    [DllImport("kernel32.dll", SetLastError = true, CharSet = CharSet.Auto)]
    public static extern uint GetLastError();

    [DllImport("kernel32.dll", SetLastError = true, CharSet = CharSet.Auto)]
    public static extern uint FormatMessage(
        uint dwFlags,
        IntPtr lpSource,
        uint dwMessageId,
        uint dwLanguageId,
        StringBuilder lpBuffer,
        uint nSize,
        IntPtr Arguments
    );

    public const uint FORMAT_MESSAGE_FROM_SYSTEM = 0x00001000;
    public const uint FORMAT_MESSAGE_IGNORE_INSERTS = 0x00000200;
}
"@

    try {
        # Tenter d'accéder au fichier
        $content = [System.IO.File]::ReadAllText($Path)
        Write-Host "Accès réussi au fichier : $Path" -ForegroundColor Green
        return $true
    } catch [System.UnauthorizedAccessException] {
        Write-Host "Erreur d'accès non autorisé au fichier : $Path" -ForegroundColor Red

        # Obtenir le code d'erreur Windows
        $errorCode = [System.Runtime.InteropServices.Marshal]::GetHRForException($_.Exception)
        Write-Host "Code d'erreur HRESULT : 0x$($errorCode.ToString("X8"))" -ForegroundColor Gray

        # Obtenir le message d'erreur Windows détaillé
        $errorCode = [NativeMethods]::GetLastError()
        if ($errorCode -ne 0) {
            $buffer = New-Object System.Text.StringBuilder 1024
            $flags = [NativeMethods]::FORMAT_MESSAGE_FROM_SYSTEM -bor [NativeMethods]::FORMAT_MESSAGE_IGNORE_INSERTS
            $result = [NativeMethods]::FormatMessage($flags, [IntPtr]::Zero, $errorCode, 0, $buffer, $buffer.Capacity, [IntPtr]::Zero)

            if ($result -ne 0) {
                Write-Host "Message d'erreur Windows : $($buffer.ToString().Trim())" -ForegroundColor Gray
            }
        }

        # Afficher les détails de l'exception
        Write-Host "Type d'exception : $($_.Exception.GetType().FullName)" -ForegroundColor Gray
        Write-Host "Message : $($_.Exception.Message)" -ForegroundColor Gray
        if ($_.Exception.InnerException) {
            Write-Host "Exception interne : $($_.Exception.InnerException.Message)" -ForegroundColor Gray
        }

        return $false
    } catch {
        Write-Host "Autre erreur lors de l'accès au fichier : $Path" -ForegroundColor Red
        Write-Host "Type d'exception : $($_.Exception.GetType().FullName)" -ForegroundColor Gray
        Write-Host "Message : $($_.Exception.Message)" -ForegroundColor Gray

        return $false
    }
}

# Tester avec un fichier protégé
Get-DetailedAccessError -Path "$env:windir\System32\config\SAM"
```

### Techniques de prévention des UnauthorizedAccessException

Pour éviter les `UnauthorizedAccessException`, vous pouvez mettre en œuvre plusieurs techniques préventives :

#### 1. Vérification préalable des permissions

Avant d'effectuer une opération qui pourrait générer une `UnauthorizedAccessException`, vérifiez si vous avez les permissions nécessaires :

```powershell
function Test-FileAccess {
    param (
        [string]$Path,
        [System.Security.AccessControl.FileSystemRights]$Rights = [System.Security.AccessControl.FileSystemRights]::Read
    )

    try {
        # Vérifier si le fichier existe
        if (-not (Test-Path -Path $Path)) {
            return @{
                HasAccess = $false
                Reason = "FileNotFound"
                Message = "Le fichier n'existe pas"
            }
        }

        # Obtenir l'utilisateur actuel
        $currentUser = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name

        # Obtenir les ACL du fichier
        $acl = Get-Acl -Path $Path

        # Vérifier si l'utilisateur a les droits demandés
        $hasAccess = $false
        foreach ($access in $acl.Access) {
            if ($access.IdentityReference.Value -eq $currentUser -or
                $access.IdentityReference.Value -eq "Everyone" -or
                $access.IdentityReference.Value -eq "BUILTIN\Users") {

                if (($access.FileSystemRights -band $Rights) -eq $Rights) {
                    $hasAccess = $true
                    break
                }
            }
        }

        if ($hasAccess) {
            return @{
                HasAccess = $true
                Reason = "PermissionGranted"
                Message = "L'utilisateur a les permissions nécessaires"
            }
        } else {
            return @{
                HasAccess = $false
                Reason = "PermissionDenied"
                Message = "L'utilisateur n'a pas les permissions nécessaires"
            }
        }
    } catch {
        return @{
            HasAccess = $false
            Reason = "Error"
            Message = $_.Exception.Message
        }
    }
}

# Exemple d'utilisation
$filePath = "C:\Windows\System32\drivers\etc\hosts"
$readAccess = Test-FileAccess -Path $filePath -Rights ([System.Security.AccessControl.FileSystemRights]::Read)
$writeAccess = Test-FileAccess -Path $filePath -Rights ([System.Security.AccessControl.FileSystemRights]::Write)

Write-Host "Accès en lecture : $($readAccess.HasAccess) - $($readAccess.Message)"
Write-Host "Accès en écriture : $($writeAccess.HasAccess) - $($writeAccess.Message)"
```

#### 2. Utilisation de blocs try-catch spécifiques

Utilisez des blocs try-catch spécifiques pour gérer les `UnauthorizedAccessException` de manière appropriée :

```powershell
function Safe-FileOperation {
    param (
        [string]$Path,
        [string]$Operation = "Read", # Read, Write, Delete
        [string]$Content = $null
    )

    try {
        switch ($Operation) {
            "Read" {
                $result = Get-Content -Path $Path -ErrorAction Stop
                return @{
                    Success = $true
                    Result = $result
                    Message = "Lecture réussie"
                }
            }
            "Write" {
                if ($null -eq $Content) {
                    return @{
                        Success = $false
                        Result = $null
                        Message = "Contenu non spécifié pour l'écriture"
                    }
                }
                Set-Content -Path $Path -Value $Content -ErrorAction Stop
                return @{
                    Success = $true
                    Result = $null
                    Message = "Écriture réussie"
                }
            }
            "Delete" {
                Remove-Item -Path $Path -ErrorAction Stop
                return @{
                    Success = $true
                    Result = $null
                    Message = "Suppression réussie"
                }
            }
            default {
                return @{
                    Success = $false
                    Result = $null
                    Message = "Opération non reconnue"
                }
            }
        }
    } catch [System.UnauthorizedAccessException] {
        return @{
            Success = $false
            Result = $null
            Message = "Accès non autorisé : $($_.Exception.Message)"
            Exception = $_
        }
    } catch [System.IO.FileNotFoundException] {
        return @{
            Success = $false
            Result = $null
            Message = "Fichier non trouvé : $($_.Exception.Message)"
            Exception = $_
        }
    } catch {
        return @{
            Success = $false
            Result = $null
            Message = "Erreur : $($_.Exception.Message)"
            Exception = $_
        }
    }
}

# Exemple d'utilisation
$result = Safe-FileOperation -Path "C:\Windows\System32\drivers\etc\hosts" -Operation "Read"
if ($result.Success) {
    Write-Host "Opération réussie : $($result.Message)"
    # Traiter $result.Result
} else {
    Write-Host "Échec de l'opération : $($result.Message)"
    # Gérer l'erreur
}
```

#### 3. Élévation de privilèges contrôlée

Pour les opérations nécessitant des privilèges élevés, utilisez une élévation de privilèges contrôlée :

```powershell
function Invoke-ElevatedOperation {
    param (
        [scriptblock]$ScriptBlock,
        [switch]$NoExit
    )

    # Vérifier si nous sommes déjà en mode administrateur
    $isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

    if ($isAdmin) {
        # Exécuter directement le script block
        Write-Host "Exécution avec privilèges administratifs existants" -ForegroundColor Green
        return & $ScriptBlock
    } else {
        # Préparer le script à exécuter
        $scriptPath = [System.IO.Path]::GetTempFileName() + ".ps1"
        $ScriptBlock.ToString() | Out-File -FilePath $scriptPath -Encoding UTF8

        Write-Host "Élévation des privilèges requise. Lancement d'un nouveau processus PowerShell..." -ForegroundColor Yellow

        # Construire les arguments
        $arguments = "-File `"$scriptPath`""
        if ($NoExit) {
            $arguments = "-NoExit " + $arguments
        }

        # Lancer PowerShell en tant qu'administrateur
        try {
            $process = Start-Process PowerShell -ArgumentList $arguments -Verb RunAs -PassThru -Wait

            # Nettoyer
            Remove-Item -Path $scriptPath -Force -ErrorAction SilentlyContinue

            return @{
                Success = $true
                ExitCode = $process.ExitCode
                Message = "Opération élevée terminée avec le code de sortie $($process.ExitCode)"
            }
        } catch {
            # Nettoyer
            Remove-Item -Path $scriptPath -Force -ErrorAction SilentlyContinue

            return @{
                Success = $false
                ExitCode = -1
                Message = "Échec de l'élévation : $($_.Exception.Message)"
            }
        }
    }
}

# Exemple d'utilisation
$result = Invoke-ElevatedOperation -ScriptBlock {
    # Code nécessitant des privilèges administratifs
    Set-Content -Path "C:\Windows\System32\test_admin.txt" -Value "Test administrateur"
    return "Opération administrative réussie"
}

Write-Host "Résultat : $($result | ConvertTo-Json)"
```

#### 4. Utilisation de chemins alternatifs

Pour les fichiers système protégés, utilisez des chemins alternatifs ou des copies temporaires :

```powershell
function Edit-ProtectedFile {
    param (
        [string]$ProtectedPath,
        [scriptblock]$EditOperation
    )

    # Créer un répertoire temporaire
    $tempDir = Join-Path -Path ([System.IO.Path]::GetTempPath()) -ChildPath ([System.Guid]::NewGuid().ToString())
    New-Item -Path $tempDir -ItemType Directory -Force | Out-Null

    try {
        # Obtenir le nom du fichier
        $fileName = [System.IO.Path]::GetFileName($ProtectedPath)
        $tempPath = Join-Path -Path $tempDir -ChildPath $fileName

        # Vérifier si le fichier protégé existe
        if (-not (Test-Path -Path $ProtectedPath)) {
            return @{
                Success = $false
                Message = "Le fichier protégé n'existe pas"
            }
        }

        # Copier le fichier protégé vers le répertoire temporaire
        try {
            Copy-Item -Path $ProtectedPath -Destination $tempPath -ErrorAction Stop
        } catch [System.UnauthorizedAccessException] {
            return @{
                Success = $false
                Message = "Accès non autorisé lors de la copie du fichier protégé"
            }
        } catch {
            return @{
                Success = $false
                Message = "Erreur lors de la copie du fichier protégé : $($_.Exception.Message)"
            }
        }

        # Appliquer l'opération d'édition sur la copie temporaire
        try {
            & $EditOperation $tempPath
        } catch {
            return @{
                Success = $false
                Message = "Erreur lors de l'édition du fichier temporaire : $($_.Exception.Message)"
            }
        }

        # Remplacer le fichier protégé par la copie modifiée (nécessite des privilèges élevés)
        $replaceResult = Invoke-ElevatedOperation -ScriptBlock {
            param($Source, $Destination)

            try {
                Copy-Item -Path $Source -Destination $Destination -Force -ErrorAction Stop
                return @{
                    Success = $true
                    Message = "Fichier protégé mis à jour avec succès"
                }
            } catch {
                return @{
                    Success = $false
                    Message = "Erreur lors du remplacement du fichier protégé : $($_.Exception.Message)"
                }
            }
        } -ArgumentList $tempPath, $ProtectedPath

        return $replaceResult
    } finally {
        # Nettoyer
        Remove-Item -Path $tempDir -Recurse -Force -ErrorAction SilentlyContinue
    }
}

# Exemple d'utilisation
$result = Edit-ProtectedFile -ProtectedPath "C:\Windows\System32\drivers\etc\hosts" -EditOperation {
    param($TempPath)

    # Lire le contenu actuel
    $content = Get-Content -Path $TempPath

    # Ajouter une ligne
    $content += "# Ligne ajoutée par Edit-ProtectedFile"

    # Écrire le contenu modifié
    Set-Content -Path $TempPath -Value $content
}

Write-Host "Résultat : $($result.Message)"
```

#### 5. Utilisation de l'impersonation

Pour les opérations nécessitant des permissions spécifiques, utilisez l'impersonation pour exécuter le code sous une autre identité :

```powershell
function Invoke-AsUser {
    param (
        [string]$Username,
        [securestring]$Password,
        [string]$Domain = ".",
        [scriptblock]$ScriptBlock
    )

    Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;
using System.Security.Principal;

public class Impersonation : IDisposable {
    private IntPtr _token;
    private WindowsImpersonationContext _context;

    [DllImport("advapi32.dll", SetLastError = true)]
    public static extern bool LogonUser(string lpszUsername, string lpszDomain, string lpszPassword,
        int dwLogonType, int dwLogonProvider, ref IntPtr phToken);

    [DllImport("kernel32.dll", SetLastError = true)]
    public static extern bool CloseHandle(IntPtr hObject);

    public Impersonation(string username, string domain, string password) {
        _token = IntPtr.Zero;

        bool logonSuccess = LogonUser(
            username,
            domain,
            password,
            9, // LOGON32_LOGON_NEW_CREDENTIALS
            3, // LOGON32_PROVIDER_WINNT50
            ref _token);

        if (!logonSuccess) {
            int error = Marshal.GetLastWin32Error();
            throw new System.ComponentModel.Win32Exception(error);
        }

        WindowsIdentity identity = new WindowsIdentity(_token);
        _context = identity.Impersonate();
    }

    public void Dispose() {
        if (_context != null) {
            _context.Dispose();
            _context = null;
        }

        if (_token != IntPtr.Zero) {
            CloseHandle(_token);
            _token = IntPtr.Zero;
        }
    }
}
"@

    try {
        # Convertir le mot de passe sécurisé en chaîne
        $BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($Password)
        $PlainPassword = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)

        # Créer l'objet d'impersonation
        $impersonation = New-Object Impersonation -ArgumentList $Username, $Domain, $PlainPassword

        try {
            # Exécuter le script block sous l'identité de l'utilisateur spécifié
            Write-Host "Exécution sous l'identité de $Domain\$Username" -ForegroundColor Yellow
            $result = & $ScriptBlock
            return @{
                Success = $true
                Result = $result
                Message = "Opération réussie sous l'identité de $Domain\$Username"
            }
        } finally {
            # Libérer l'impersonation
            $impersonation.Dispose()
        }
    } catch {
        return @{
            Success = $false
            Result = $null
            Message = "Erreur d'impersonation : $($_.Exception.Message)"
        }
    } finally {
        # Nettoyer le mot de passe en mémoire
        if ($BSTR -ne [IntPtr]::Zero) {
            [System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($BSTR)
        }
    }
}

# Exemple d'utilisation (nécessite des informations d'identification valides)
$securePassword = ConvertTo-SecureString "MotDePasse" -AsPlainText -Force
$result = Invoke-AsUser -Username "UtilisateurAvecPermissions" -Password $securePassword -ScriptBlock {
    # Code à exécuter sous l'identité de l'utilisateur spécifié
    Get-Content -Path "\\Server\PartageProtégé\fichier.txt"
}

if ($result.Success) {
    Write-Host "Opération réussie : $($result.Message)"
    # Traiter $result.Result
} else {
    Write-Host "Échec de l'opération : $($result.Message)"
}
```

#### 6. Utilisation de services Windows

Pour les opérations nécessitant des privilèges élevés de manière permanente, utilisez un service Windows :

```powershell
function Register-PrivilegedService {
    param (
        [string]$ServiceName = "PrivilegedOperationService",
        [string]$DisplayName = "Service pour opérations privilégiées",
        [string]$Description = "Service permettant d'exécuter des opérations nécessitant des privilèges élevés",
        [string]$BinaryPath
    )

    # Vérifier si nous sommes en mode administrateur
    $isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

    if (-not $isAdmin) {
        return @{
            Success = $false
            Message = "Cette opération nécessite des privilèges administratifs"
        }
    }

    # Vérifier si le service existe déjà
    $service = Get-Service -Name $ServiceName -ErrorAction SilentlyContinue

    if ($service) {
        return @{
            Success = $false
            Message = "Le service '$ServiceName' existe déjà"
        }
    }

    # Créer le service
    try {
        $service = New-Service -Name $ServiceName -DisplayName $DisplayName -Description $Description -BinaryPathName $BinaryPath -StartupType Manual

        return @{
            Success = $true
            Service = $service
            Message = "Service '$ServiceName' créé avec succès"
        }
    } catch {
        return @{
            Success = $false
            Message = "Erreur lors de la création du service : $($_.Exception.Message)"
        }
    }
}

# Exemple d'utilisation (nécessite un exécutable de service valide)
$servicePath = "C:\Path\To\PrivilegedService.exe"
$result = Register-PrivilegedService -BinaryPath $servicePath

if ($result.Success) {
    Write-Host "Service créé avec succès : $($result.Message)"
} else {
    Write-Host "Échec de la création du service : $($result.Message)"
}
```

#### 7. Utilisation de tâches planifiées

Pour les opérations nécessitant des privilèges élevés de manière ponctuelle, utilisez une tâche planifiée :

```powershell
function Invoke-AsScheduledTask {
    param (
        [string]$TaskName = "PrivilegedOperation",
        [scriptblock]$ScriptBlock,
        [switch]$DeleteTaskWhenDone = $true
    )

    # Créer un fichier temporaire pour le script
    $scriptPath = [System.IO.Path]::GetTempFileName() + ".ps1"
    $outputPath = [System.IO.Path]::GetTempFileName() + ".txt"

    try {
        # Écrire le script dans le fichier temporaire
        $scriptContent = @"
`$ErrorActionPreference = 'Stop'
try {
    `$result = {
$($ScriptBlock.ToString())
    }
    `$resultJson = ConvertTo-Json -InputObject `$result -Depth 10 -Compress
    Set-Content -Path "$outputPath" -Value `$resultJson -Encoding UTF8
    exit 0
} catch {
    `$errorJson = ConvertTo-Json -InputObject @{
        Error = `$_.Exception.Message
        Type = `$_.Exception.GetType().FullName
        StackTrace = `$_.ScriptStackTrace
    } -Depth 10 -Compress
    Set-Content -Path "$outputPath" -Value `$errorJson -Encoding UTF8
    exit 1
}
"@
        Set-Content -Path $scriptPath -Value $scriptContent -Encoding UTF8

        # Créer une action pour exécuter PowerShell avec le script
        $action = New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument "-ExecutionPolicy Bypass -File `"$scriptPath`""

        # Créer un déclencheur pour exécuter la tâche immédiatement
        $trigger = New-ScheduledTaskTrigger -Once -At (Get-Date)

        # Créer un principal pour exécuter la tâche avec les privilèges les plus élevés
        $principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest

        # Créer la tâche
        $task = New-ScheduledTask -Action $action -Trigger $trigger -Principal $principal

        # Enregistrer la tâche
        Register-ScheduledTask -TaskName $TaskName -InputObject $task | Out-Null

        # Démarrer la tâche
        Start-ScheduledTask -TaskName $TaskName

        # Attendre que la tâche soit terminée
        $timeout = 60 # secondes
        $elapsed = 0
        $interval = 1 # secondes

        do {
            Start-Sleep -Seconds $interval
            $elapsed += $interval
            $taskInfo = Get-ScheduledTaskInfo -TaskName $TaskName
        } while ($taskInfo.LastTaskResult -eq 267009 -and $elapsed -lt $timeout) # 267009 = tâche en cours d'exécution

        # Lire le résultat
        if (Test-Path -Path $outputPath) {
            $resultJson = Get-Content -Path $outputPath -Raw
            try {
                $result = ConvertFrom-Json -InputObject $resultJson

                if ($result.Error) {
                    return @{
                        Success = $false
                        Message = "Erreur lors de l'exécution de la tâche : $($result.Error)"
                        Error = $result
                    }
                } else {
                    return @{
                        Success = $true
                        Result = $result
                        Message = "Tâche exécutée avec succès"
                    }
                }
            } catch {
                return @{
                    Success = $false
                    Message = "Erreur lors de la lecture du résultat : $($_.Exception.Message)"
                }
            }
        } else {
            return @{
                Success = $false
                Message = "Aucun résultat n'a été généré par la tâche"
            }
        }
    } catch {
        return @{
            Success = $false
            Message = "Erreur lors de l'exécution de la tâche planifiée : $($_.Exception.Message)"
        }
    } finally {
        # Nettoyer
        if ($DeleteTaskWhenDone) {
            Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false -ErrorAction SilentlyContinue
        }

        Remove-Item -Path $scriptPath -Force -ErrorAction SilentlyContinue
        Remove-Item -Path $outputPath -Force -ErrorAction SilentlyContinue
    }
}

# Exemple d'utilisation
$result = Invoke-AsScheduledTask -ScriptBlock {
    # Code nécessitant des privilèges SYSTEM
    Set-Content -Path "C:\Windows\System32\drivers\etc\hosts" -Value "127.0.0.1 localhost"
    return "Fichier hosts modifié avec succès"
}

if ($result.Success) {
    Write-Host "Opération réussie : $($result.Message)"
    Write-Host "Résultat : $($result.Result)"
} else {
    Write-Host "Échec de l'opération : $($result.Message)"
}
```
