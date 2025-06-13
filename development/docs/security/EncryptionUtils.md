# Module d'utilitaires de chiffrement (EncryptionUtils)

Ce document décrit le module d'utilitaires de chiffrement (`EncryptionUtils.ps1`) qui permet de sécuriser les données sensibles en utilisant des algorithmes de chiffrement robustes.

## Table des matières

1. [Introduction](#introduction)

2. [Fonctions disponibles](#fonctions-disponibles)

3. [Algorithmes de chiffrement](#algorithmes-de-chiffrement)

4. [Exemples d'utilisation](#exemples-dutilisation)

5. [Bonnes pratiques de sécurité](#bonnes-pratiques-de-sécurité)

6. [Intégration avec d'autres modules](#intégration-avec-dautres-modules)

7. [Considérations de performance](#considérations-de-performance)

## Introduction

Le module d'utilitaires de chiffrement fournit des fonctions pour chiffrer et déchiffrer des données, ainsi que pour sécuriser les fichiers contenant des informations sensibles. Il utilise des algorithmes de chiffrement robustes comme AES-256 et des techniques de dérivation de clé sécurisées comme PBKDF2.

Le module offre plusieurs fonctionnalités :
- Génération de clés de chiffrement à partir de mots de passe
- Chiffrement et déchiffrement de chaînes de caractères
- Chiffrement et déchiffrement de fichiers
- Calcul de hachages de fichiers
- Signature et vérification de fichiers

## Fonctions disponibles

### New-EncryptionKey

```powershell
New-EncryptionKey [-Password <SecureString>] [-Salt <string>] [-KeySize <int>] [-Iterations <int>] [-HashAlgorithm <string>] [-OutputFile <string>]
```plaintext
Cette fonction génère une clé de chiffrement à partir d'un mot de passe ou de manière aléatoire.

#### Paramètres

- **Password** : Mot de passe à utiliser pour générer la clé (SecureString).
- **Salt** : Sel à utiliser pour la dérivation de la clé (par défaut : "EMAIL_SENDER_1_Salt").
- **KeySize** : Taille de la clé en bits (par défaut : 256).
- **Iterations** : Nombre d'itérations pour la dérivation de la clé (par défaut : 10000).
- **HashAlgorithm** : Algorithme de hachage à utiliser (par défaut : "SHA256").
- **OutputFile** : Fichier dans lequel enregistrer la clé (optionnel).

#### Exemple

```powershell
# Générer une clé à partir d'un mot de passe

$password = ConvertTo-SecureString -String "MonMotDePasse" -AsPlainText -Force
$key = New-EncryptionKey -Password $password

# Générer une clé aléatoire

$randomKey = New-EncryptionKey
```plaintext
### Protect-String

```powershell
Protect-String -InputString <string> -EncryptionKey <object> [-BlockSize <int>]
```plaintext
Cette fonction chiffre une chaîne de caractères.

#### Paramètres

- **InputString** : Chaîne de caractères à chiffrer.
- **EncryptionKey** : Clé de chiffrement à utiliser.
- **BlockSize** : Taille de bloc en bits (par défaut : 128).

#### Exemple

```powershell
# Chiffrer une chaîne

$encryptedString = Protect-String -InputString "Données sensibles" -EncryptionKey $key
```plaintext
### Unprotect-String

```powershell
Unprotect-String -EncryptedString <string> -EncryptionKey <object> [-BlockSize <int>]
```plaintext
Cette fonction déchiffre une chaîne de caractères.

#### Paramètres

- **EncryptedString** : Chaîne de caractères chiffrée.
- **EncryptionKey** : Clé de chiffrement à utiliser.
- **BlockSize** : Taille de bloc en bits (par défaut : 128).

#### Exemple

```powershell
# Déchiffrer une chaîne

$decryptedString = Unprotect-String -EncryptedString $encryptedString -EncryptionKey $key
```plaintext
### Protect-File

```powershell
Protect-File -InputFile <string> -OutputFile <string> -EncryptionKey <object> [-BlockSize <int>] [-BufferSize <int>]
```plaintext
Cette fonction chiffre un fichier.

#### Paramètres

- **InputFile** : Chemin du fichier à chiffrer.
- **OutputFile** : Chemin du fichier chiffré.
- **EncryptionKey** : Clé de chiffrement à utiliser.
- **BlockSize** : Taille de bloc en bits (par défaut : 128).
- **BufferSize** : Taille du tampon en octets (par défaut : 4096).

#### Exemple

```powershell
# Chiffrer un fichier

$result = Protect-File -InputFile "C:\Data\secret.txt" -OutputFile "C:\Data\secret.enc" -EncryptionKey $key
```plaintext
### Unprotect-File

```powershell
Unprotect-File -InputFile <string> -OutputFile <string> -EncryptionKey <object> [-BlockSize <int>] [-BufferSize <int>]
```plaintext
Cette fonction déchiffre un fichier.

#### Paramètres

- **InputFile** : Chemin du fichier chiffré.
- **OutputFile** : Chemin du fichier déchiffré.
- **EncryptionKey** : Clé de chiffrement à utiliser.
- **BlockSize** : Taille de bloc en bits (par défaut : 128).
- **BufferSize** : Taille du tampon en octets (par défaut : 4096).

#### Exemple

```powershell
# Déchiffrer un fichier

$result = Unprotect-File -InputFile "C:\Data\secret.enc" -OutputFile "C:\Data\secret_decrypted.txt" -EncryptionKey $key
```plaintext
### Get-FileHash

```powershell
Get-FileHash -FilePath <string> [-Algorithm <string>] [-BufferSize <int>]
```plaintext
Cette fonction calcule le hachage d'un fichier.

#### Paramètres

- **FilePath** : Chemin du fichier.
- **Algorithm** : Algorithme de hachage à utiliser (MD5, SHA1, SHA256, SHA384, SHA512) (par défaut : SHA256).
- **BufferSize** : Taille du tampon en octets (par défaut : 4096).

#### Exemple

```powershell
# Calculer le hachage d'un fichier

$hash = Get-FileHash -FilePath "C:\Data\file.txt" -Algorithm "SHA256"
```plaintext
### New-FileSignature

```powershell
New-FileSignature -FilePath <string> -EncryptionKey <object> [-SignatureFile <string>] [-Algorithm <string>]
```plaintext
Cette fonction signe un fichier.

#### Paramètres

- **FilePath** : Chemin du fichier à signer.
- **EncryptionKey** : Clé de chiffrement à utiliser.
- **SignatureFile** : Chemin du fichier de signature (optionnel).
- **Algorithm** : Algorithme de hachage à utiliser (par défaut : SHA256).

#### Exemple

```powershell
# Signer un fichier

$signature = New-FileSignature -FilePath "C:\Data\file.txt" -EncryptionKey $key -SignatureFile "C:\Data\file.txt.sig"
```plaintext
### Test-FileSignature

```powershell
Test-FileSignature -FilePath <string> -EncryptionKey <object> -Signature <string> | -SignatureFile <string>
```plaintext
Cette fonction vérifie la signature d'un fichier.

#### Paramètres

- **FilePath** : Chemin du fichier à vérifier.
- **EncryptionKey** : Clé de chiffrement à utiliser.
- **Signature** : Signature du fichier.
- **SignatureFile** : Chemin du fichier de signature.

#### Exemple

```powershell
# Vérifier la signature d'un fichier

$result = Test-FileSignature -FilePath "C:\Data\file.txt" -EncryptionKey $key -SignatureFile "C:\Data\file.txt.sig"
```plaintext
## Algorithmes de chiffrement

Le module utilise les algorithmes de chiffrement suivants :

### AES (Advanced Encryption Standard)

AES est un algorithme de chiffrement symétrique largement utilisé et considéré comme sûr. Le module utilise AES-256 (256 bits) par défaut, qui offre un niveau de sécurité très élevé.

### PBKDF2 (Password-Based Key Derivation Function 2)

PBKDF2 est une fonction de dérivation de clé qui permet de générer une clé de chiffrement à partir d'un mot de passe. Elle utilise un sel et un grand nombre d'itérations pour rendre les attaques par force brute plus difficiles.

### Algorithmes de hachage

Le module prend en charge plusieurs algorithmes de hachage pour le calcul des hachages de fichiers et la signature :
- MD5 (non recommandé pour des applications de sécurité)
- SHA1 (non recommandé pour des applications de sécurité)
- SHA256 (recommandé)
- SHA384
- SHA512

## Exemples d'utilisation

### Chiffrement et déchiffrement de chaînes de caractères

```powershell
# Importer le module

. ".\modules\EncryptionUtils.ps1"

# Générer une clé de chiffrement

$password = ConvertTo-SecureString -String "MonMotDePasse" -AsPlainText -Force
$key = New-EncryptionKey -Password $password

# Chiffrer une chaîne

$sensitiveData = "Numéro de carte de crédit: 1234-5678-9012-3456"
$encryptedData = Protect-String -InputString $sensitiveData -EncryptionKey $key

Write-Host "Données chiffrées: $encryptedData"

# Déchiffrer la chaîne

$decryptedData = Unprotect-String -EncryptedString $encryptedData -EncryptionKey $key

Write-Host "Données déchiffrées: $decryptedData"
```plaintext
### Chiffrement et déchiffrement de fichiers

```powershell
# Importer le module

. ".\modules\EncryptionUtils.ps1"

# Générer une clé de chiffrement

$password = ConvertTo-SecureString -String "MonMotDePasse" -AsPlainText -Force
$key = New-EncryptionKey -Password $password

# Chiffrer un fichier

$inputFile = "C:\Data\confidential.docx"
$encryptedFile = "C:\Data\confidential.enc"
$result = Protect-File -InputFile $inputFile -OutputFile $encryptedFile -EncryptionKey $key

if ($result) {
    Write-Host "Fichier chiffré avec succès: $encryptedFile"
    
    # Déchiffrer le fichier

    $decryptedFile = "C:\Data\confidential_decrypted.docx"
    $result = Unprotect-File -InputFile $encryptedFile -OutputFile $decryptedFile -EncryptionKey $key
    
    if ($result) {
        Write-Host "Fichier déchiffré avec succès: $decryptedFile"
    }
}
```plaintext
### Signature et vérification de fichiers

```powershell
# Importer le module

. ".\modules\EncryptionUtils.ps1"

# Générer une clé de chiffrement

$key = New-EncryptionKey

# Signer un fichier

$filePath = "C:\Data\important.pdf"
$signatureFile = "C:\Data\important.pdf.sig"
$signature = New-FileSignature -FilePath $filePath -EncryptionKey $key -SignatureFile $signatureFile

Write-Host "Fichier signé: $signatureFile"

# Vérifier la signature

$result = Test-FileSignature -FilePath $filePath -EncryptionKey $key -SignatureFile $signatureFile

if ($result.IsValid) {
    Write-Host "La signature est valide."
    Write-Host "Horodatage de la signature: $($result.SignatureTimestamp)"
} else {
    Write-Host "La signature n'est pas valide!"
    Write-Host "Hachage attendu: $($result.ExpectedHash)"
    Write-Host "Hachage actuel: $($result.CurrentHash)"
}
```plaintext
### Stockage sécurisé de clés

```powershell
# Importer le module

. ".\modules\EncryptionUtils.ps1"

# Générer une clé de chiffrement

$password = ConvertTo-SecureString -String "MotDePasseMaitre" -AsPlainText -Force
$key = New-EncryptionKey -Password $password -OutputFile "C:\Keys\master.key"

Write-Host "Clé enregistrée dans: C:\Keys\master.key"

# Chiffrer une autre clé

$anotherPassword = ConvertTo-SecureString -String "AutreMotDePasse" -AsPlainText -Force
$anotherKey = New-EncryptionKey -Password $anotherPassword

# Convertir la clé en JSON

$keyJson = $anotherKey | ConvertTo-Json

# Chiffrer la clé

$encryptedKey = Protect-String -InputString $keyJson -EncryptionKey $key

# Enregistrer la clé chiffrée

$encryptedKey | Set-Content -Path "C:\Keys\encrypted.key" -Encoding UTF8

Write-Host "Clé chiffrée enregistrée dans: C:\Keys\encrypted.key"
```plaintext
## Bonnes pratiques de sécurité

Pour utiliser le module d'utilitaires de chiffrement de manière sécurisée, suivez ces bonnes pratiques :

1. **Utilisez des mots de passe forts** : Les mots de passe utilisés pour générer des clés de chiffrement doivent être longs, complexes et uniques.

2. **Protégez les clés de chiffrement** : Les clés de chiffrement sont sensibles et doivent être protégées. Ne les stockez pas en clair dans des fichiers ou des bases de données.

3. **Utilisez SecureString pour les mots de passe** : Utilisez toujours SecureString pour manipuler les mots de passe afin d'éviter qu'ils ne soient exposés en mémoire.

4. **Utilisez AES-256** : AES-256 est considéré comme sûr et offre un bon niveau de sécurité.

5. **Utilisez un grand nombre d'itérations pour PBKDF2** : Un grand nombre d'itérations (au moins 10000) rend les attaques par force brute plus difficiles.

6. **Utilisez SHA-256 ou supérieur pour les hachages** : MD5 et SHA-1 sont considérés comme faibles et ne doivent pas être utilisés pour des applications de sécurité.

7. **Vérifiez toujours les signatures** : Lorsque vous utilisez des signatures, vérifiez-les toujours avant d'utiliser les fichiers correspondants.

8. **Nettoyez les données sensibles de la mémoire** : Après avoir utilisé des données sensibles, assurez-vous de les effacer de la mémoire.

9. **Sauvegardez les clés de chiffrement** : Si vous perdez une clé de chiffrement, vous ne pourrez pas déchiffrer les données. Assurez-vous de sauvegarder les clés de manière sécurisée.

10. **Utilisez des vecteurs d'initialisation (IV) uniques** : Le module génère automatiquement des IV uniques, mais assurez-vous de ne jamais réutiliser un IV avec la même clé.

## Intégration avec d'autres modules

Le module d'utilitaires de chiffrement peut être intégré avec d'autres modules pour ajouter des fonctionnalités de chiffrement. Voici quelques exemples d'intégration :

### Intégration avec UnifiedFileProcessor

```powershell
# Importer les modules

. ".\modules\EncryptionUtils.ps1"
. ".\modules\UnifiedFileProcessor.ps1"

# Initialiser le module UnifiedFileProcessor

Initialize-UnifiedFileProcessor

# Générer une clé de chiffrement

$password = ConvertTo-SecureString -String "MonMotDePasse" -AsPlainText -Force
$key = New-EncryptionKey -Password $password

# Traiter et chiffrer un fichier

$inputFile = "C:\Data\input.csv"
$processedFile = "C:\Data\processed.json"
$encryptedFile = "C:\Data\processed.enc"

# Traiter le fichier

$result = Invoke-SecureFileProcessing -InputFile $inputFile -OutputFile $processedFile -InputFormat "CSV" -OutputFormat "JSON"

if ($result) {
    # Chiffrer le fichier traité

    $encryptResult = Protect-SecureFile -InputFile $processedFile -OutputFile $encryptedFile -EncryptionKey $key -CreateSignature
    
    if ($encryptResult) {
        Write-Host "Fichier traité et chiffré avec succès: $encryptedFile"
        Write-Host "Signature: $($encryptResult.SignatureFile)"
    }
}
```plaintext
### Intégration avec des fonctions personnalisées

```powershell
# Importer le module

. ".\modules\EncryptionUtils.ps1"

# Fonction pour enregistrer des données sensibles de manière sécurisée

function Save-SensitiveData {
    param(
        [Parameter(Mandatory = $true)]
        [object]$Data,
        
        [Parameter(Mandatory = $true)]
        [string]$OutputFile,
        
        [Parameter(Mandatory = $true)]
        [System.Security.SecureString]$Password
    )
    
    # Générer une clé de chiffrement

    $key = New-EncryptionKey -Password $Password
    
    # Convertir les données en JSON

    $jsonData = $Data | ConvertTo-Json -Depth 10
    
    # Chiffrer les données

    $encryptedData = Protect-String -InputString $jsonData -EncryptionKey $key
    
    # Enregistrer les données chiffrées

    $encryptedData | Set-Content -Path $OutputFile -Encoding UTF8
    
    return $true
}

# Fonction pour charger des données sensibles

function Load-SensitiveData {
    param(
        [Parameter(Mandatory = $true)]
        [string]$InputFile,
        
        [Parameter(Mandatory = $true)]
        [System.Security.SecureString]$Password
    )
    
    # Vérifier que le fichier existe

    if (-not (Test-Path -Path $InputFile)) {
        Write-Error "Le fichier n'existe pas: $InputFile"
        return $null
    }
    
    # Générer une clé de chiffrement

    $key = New-EncryptionKey -Password $Password
    
    # Lire les données chiffrées

    $encryptedData = Get-Content -Path $InputFile -Raw
    
    # Déchiffrer les données

    $jsonData = Unprotect-String -EncryptedString $encryptedData -EncryptionKey $key
    
    if ([string]::IsNullOrEmpty($jsonData)) {
        Write-Error "Impossible de déchiffrer les données. Mot de passe incorrect?"
        return $null
    }
    
    # Convertir les données JSON en objet

    $data = $jsonData | ConvertFrom-Json
    
    return $data
}

# Utilisation

$sensitiveData = @{
    Username = "admin"
    Password = "P@ssw0rd"
    ApiKey = "1234567890abcdef"
    ServerUrl = "https://api.example.com"
}

$password = ConvertTo-SecureString -String "MotDePasseSecurise" -AsPlainText -Force

# Enregistrer les données

Save-SensitiveData -Data $sensitiveData -OutputFile "C:\Data\config.enc" -Password $password

# Charger les données

$loadedData = Load-SensitiveData -InputFile "C:\Data\config.enc" -Password $password

# Afficher les données

$loadedData
```plaintext
## Considérations de performance

Le chiffrement et le déchiffrement sont des opérations coûteuses en termes de CPU. Voici quelques considérations de performance à prendre en compte lors de l'utilisation du module :

1. **Taille des fichiers** : Le chiffrement et le déchiffrement de fichiers volumineux peuvent prendre beaucoup de temps. Envisagez de diviser les fichiers volumineux en morceaux plus petits.

2. **Nombre d'itérations PBKDF2** : Un grand nombre d'itérations rend les attaques par force brute plus difficiles, mais ralentit également la génération de clés. Trouvez un équilibre entre sécurité et performance.

3. **Taille du tampon** : La taille du tampon utilisée pour le chiffrement et le déchiffrement de fichiers peut affecter les performances. Une taille de tampon plus grande peut améliorer les performances, mais consomme plus de mémoire.

4. **Algorithme de hachage** : SHA-256 offre un bon équilibre entre sécurité et performance. SHA-512 est plus sécurisé mais plus lent.

5. **Mise en cache des clés** : Si vous utilisez fréquemment les mêmes clés, envisagez de les mettre en cache pour éviter de les recalculer à chaque fois.

6. **Parallélisation** : Le module ne prend pas en charge la parallélisation, mais vous pouvez implémenter votre propre parallélisation pour traiter plusieurs fichiers simultanément.

7. **Compression** : Envisagez de compresser les données avant de les chiffrer pour réduire la taille des données et améliorer les performances.

Pour les opérations critiques en termes de performance, envisagez d'utiliser des bibliothèques natives ou des outils spécialisés comme OpenSSL ou GPG.
