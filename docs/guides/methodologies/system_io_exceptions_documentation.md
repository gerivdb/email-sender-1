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
