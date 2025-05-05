# Get-ExtractedInfoValidationErrors

## SYNOPSIS
Récupère les erreurs de validation d'un objet d'information extraite.

## SYNTAXE

```powershell
Get-ExtractedInfoValidationErrors
    -Info <Hashtable>
    [-CustomValidationRule <ScriptBlock>]
    [-Detailed]
    [<CommonParameters>]
```

## DESCRIPTION
La fonction `Get-ExtractedInfoValidationErrors` analyse un objet d'information extraite et retourne les erreurs de validation détectées. Cette fonction est similaire à `Test-ExtractedInfo`, mais au lieu de retourner un simple booléen, elle retourne la liste complète des erreurs de validation.

La fonction vérifie la présence des propriétés requises, les types de données, les valeurs autorisées et d'autres contraintes spécifiques au type d'information extraite. Elle prend également en compte les règles de validation globales enregistrées avec `Add-ExtractedInfoValidationRule`.

## PARAMÈTRES

### -Info
Spécifie l'objet d'information extraite à valider. Ce paramètre est obligatoire.

```yaml
Type: Hashtable
Required: True
```

### -CustomValidationRule
Spécifie un script block contenant une règle de validation personnalisée à appliquer en plus des règles standard. Le script block doit accepter un paramètre (l'objet d'information extraite) et retourner un tableau de chaînes d'erreur (vide si aucune erreur).

```yaml
Type: ScriptBlock
Required: False
```

### -Detailed
Indique si la fonction doit retourner un résultat détaillé contenant des informations sur la validation plutôt qu'un simple tableau d'erreurs.

```yaml
Type: SwitchParameter
Default: False
```

### <CommonParameters>
Cette fonction prend en charge les paramètres communs : Verbose, Debug, ErrorAction, ErrorVariable, WarningAction, WarningVariable, OutBuffer, PipelineVariable, et OutVariable.

## ENTRÉES
### System.Collections.Hashtable
Vous pouvez transmettre un objet d'information extraite via le pipeline.

## SORTIES
### System.String[] ou System.Collections.Hashtable
- Si le paramètre `-Detailed` n'est pas spécifié, la fonction retourne un tableau de chaînes contenant les erreurs de validation. Si l'objet est valide, un tableau vide est retourné.
- Si le paramètre `-Detailed` est spécifié, la fonction retourne une hashtable contenant des informations détaillées sur la validation, avec les propriétés suivantes :
  - **IsValid** : Booléen indiquant si l'objet est valide
  - **ObjectType** : Type de l'objet validé
  - **Errors** : Tableau des erreurs de validation détectées (vide si aucune erreur)

## NOTES
- Cette fonction ne modifie pas l'objet d'information extraite original.
- Les règles de validation standard vérifient :
  - La présence des propriétés requises (Id, Source, ExtractorName, etc.)
  - Les types de données des propriétés (chaînes, entiers, dates, etc.)
  - Les valeurs autorisées pour certaines propriétés (ProcessingState, ConfidenceScore, etc.)
  - Les contraintes spécifiques au type d'information extraite (Text pour TextExtractedInfo, Data pour StructuredDataExtractedInfo, etc.)
- Les règles de validation globales enregistrées avec `Add-ExtractedInfoValidationRule` sont également appliquées.
- Cette fonction est particulièrement utile pour le débogage et la correction d'objets d'information extraite invalides.
- Pour simplement vérifier si un objet est valide sans obtenir la liste des erreurs, utilisez la fonction `Test-ExtractedInfo`.

## EXEMPLES

### Exemple 1 : Récupérer les erreurs de validation d'un objet valide
```powershell
$info = New-ExtractedInfo -Source "document.pdf" -ExtractorName "PDFExtractor"
$errors = Get-ExtractedInfoValidationErrors -Info $info

if ($errors.Count -eq 0) {
    Write-Host "L'objet est valide, aucune erreur détectée."
}
else {
    Write-Host "L'objet est invalide, erreurs détectées :"
    foreach ($error in $errors) {
        Write-Host "- $error"
    }
}
```

Cet exemple récupère les erreurs de validation d'un objet d'information extraite valide et affiche un message approprié.

### Exemple 2 : Récupérer les erreurs de validation d'un objet invalide
```powershell
# Créer un objet d'information extraite avec plusieurs problèmes
$invalidInfo = @{
    _Type = "TextExtractedInfo"
    Id = [guid]::NewGuid().ToString()
    # Source manquante
    ExtractorName = "TextExtractor"
    ExtractionDate = Get-Date
    LastModifiedDate = Get-Date
    ProcessingState = "InvalidState" # État invalide
    ConfidenceScore = 150 # Score invalide (doit être entre 0 et 100)
    Metadata = @{}
    # Text manquant (requis pour TextExtractedInfo)
    Language = "en"
}

# Récupérer les erreurs de validation
$errors = Get-ExtractedInfoValidationErrors -Info $invalidInfo

# Afficher les erreurs
Write-Host "Nombre d'erreurs détectées : $($errors.Count)"
foreach ($error in $errors) {
    Write-Host "- $error"
}
```

Cet exemple récupère les erreurs de validation d'un objet d'information extraite invalide avec plusieurs problèmes et les affiche.

### Exemple 3 : Récupérer un résultat de validation détaillé
```powershell
# Créer un objet d'information extraite avec un problème
$info = New-StructuredDataExtractedInfo -Source "data.json" -Data @{ Name = "Test" }
$info.ConfidenceScore = 110 # Invalide : doit être entre 0 et 100

# Récupérer un résultat de validation détaillé
$validationResult = Get-ExtractedInfoValidationErrors -Info $info -Detailed

# Afficher les résultats
Write-Host "Type d'objet : $($validationResult.ObjectType)"
Write-Host "Valide : $($validationResult.IsValid)"
Write-Host "Nombre d'erreurs : $($validationResult.Errors.Count)"

if (-not $validationResult.IsValid) {
    Write-Host "Erreurs de validation :"
    foreach ($error in $validationResult.Errors) {
        Write-Host "- $error"
    }
}
```

Cet exemple récupère un résultat de validation détaillé pour un objet d'information extraite avec un score de confiance invalide.

### Exemple 4 : Utiliser une règle de validation personnalisée
```powershell
# Créer un objet d'information extraite
$info = New-TextExtractedInfo -Source "article.html" -Text "Ceci est un exemple de texte." -Language "fr"

# Définir une règle de validation personnalisée
$customRule = {
    param($Info)
    
    $errors = @()
    
    # Règle : Le texte doit contenir au moins 50 caractères
    if ($Info._Type -eq "TextExtractedInfo" -and $Info.Text.Length -lt 50) {
        $errors += "Le texte doit contenir au moins 50 caractères (actuellement : $($Info.Text.Length))"
    }
    
    # Règle : La langue doit être "en" pour les articles
    if ($Info._Type -eq "TextExtractedInfo" -and $Info.Source -like "*article*" -and $Info.Language -ne "en") {
        $errors += "La langue doit être 'en' pour les articles (actuellement : $($Info.Language))"
    }
    
    return $errors
}

# Récupérer les erreurs de validation avec la règle personnalisée
$errors = Get-ExtractedInfoValidationErrors -Info $info -CustomValidationRule $customRule

# Afficher les erreurs
if ($errors.Count -eq 0) {
    Write-Host "L'objet est valide selon les règles standard et personnalisées."
}
else {
    Write-Host "L'objet est invalide, erreurs détectées :"
    foreach ($error in $errors) {
        Write-Host "- $error"
    }
}
```

Cet exemple utilise une règle de validation personnalisée qui vérifie la longueur du texte et la langue pour les articles.

### Exemple 5 : Valider différents types d'objets d'information extraite
```powershell
# Créer différents types d'objets d'information extraite avec des problèmes
$basicInfo = New-ExtractedInfo -Source "basic.txt"
$basicInfo.ProcessingState = "Unknown" # État invalide

$textInfo = New-TextExtractedInfo -Source "text.txt" -Text ""
# Texte vide (techniquement valide mais potentiellement problématique)

$structuredInfo = @{
    _Type = "StructuredDataExtractedInfo"
    Id = [guid]::NewGuid().ToString()
    Source = "data.json"
    ExtractorName = "JsonExtractor"
    ExtractionDate = Get-Date
    LastModifiedDate = Get-Date
    ProcessingState = "Raw"
    ConfidenceScore = 75
    Metadata = @{}
    # Data manquante (requise pour StructuredDataExtractedInfo)
    DataFormat = "JSON"
}

$mediaInfo = New-MediaExtractedInfo -Source "image.jpg" -MediaPath "C:\Images\image.jpg" -MediaType "InvalidType"
# Type de média invalide

# Fonction pour valider et afficher les résultats
function Get-ValidationReport {
    param($Info, $Description)
    
    $errors = Get-ExtractedInfoValidationErrors -Info $Info
    
    Write-Host "Validation de $Description :"
    Write-Host "- Type : $($Info._Type)"
    
    if ($errors.Count -eq 0) {
        Write-Host "- Valide : Oui"
    }
    else {
        Write-Host "- Valide : Non"
        Write-Host "- Erreurs :"
        foreach ($error in $errors) {
            Write-Host "  * $error"
        }
    }
    
    Write-Host ""
}

# Valider chaque type d'objet
Get-ValidationReport -Info $basicInfo -Description "l'objet de base"
Get-ValidationReport -Info $textInfo -Description "l'objet texte"
Get-ValidationReport -Info $structuredInfo -Description "l'objet données structurées"
Get-ValidationReport -Info $mediaInfo -Description "l'objet média"
```

Cet exemple valide différents types d'objets d'information extraite avec des problèmes et affiche les erreurs pour chacun.

### Exemple 6 : Utiliser Get-ExtractedInfoValidationErrors avec le pipeline
```powershell
# Créer plusieurs objets d'information extraite
$infos = @(
    (New-ExtractedInfo -Source "source1"),
    (New-ExtractedInfo -Source "source2" -ProcessingState "InvalidState"), # État invalide
    (New-TextExtractedInfo -Source "source3" -Text "Texte")
)

# Récupérer les erreurs de validation pour tous les objets via le pipeline
$validationResults = $infos | Get-ExtractedInfoValidationErrors -Detailed

# Afficher les résultats
for ($i = 0; $i -lt $infos.Count; $i++) {
    $info = $infos[$i]
    $result = $validationResults[$i]
    
    Write-Host "Objet $($i+1) (Source: $($info.Source), Type: $($info._Type)):"
    Write-Host "- Valide : $($result.IsValid)"
    
    if (-not $result.IsValid) {
        Write-Host "- Erreurs :"
        foreach ($error in $result.Errors) {
            Write-Host "  * $error"
        }
    }
    
    Write-Host ""
}
```

Cet exemple utilise le pipeline pour récupérer les erreurs de validation de plusieurs objets d'information extraite et affiche les résultats pour chacun.

### Exemple 7 : Corriger un objet d'information extraite en fonction des erreurs de validation
```powershell
# Créer un objet d'information extraite avec plusieurs problèmes
$invalidInfo = @{
    _Type = "TextExtractedInfo"
    Id = [guid]::NewGuid().ToString()
    # Source manquante
    ExtractorName = "TextExtractor"
    ExtractionDate = Get-Date
    LastModifiedDate = Get-Date
    ProcessingState = "InvalidState" # État invalide
    ConfidenceScore = 150 # Score invalide (doit être entre 0 et 100)
    Metadata = @{}
    # Text manquant (requis pour TextExtractedInfo)
    Language = "en"
}

# Récupérer les erreurs de validation
$errors = Get-ExtractedInfoValidationErrors -Info $invalidInfo

# Afficher les erreurs initiales
Write-Host "Erreurs initiales :"
foreach ($error in $errors) {
    Write-Host "- $error"
}

# Corriger l'objet en fonction des erreurs
$correctedInfo = $invalidInfo.Clone()

foreach ($error in $errors) {
    if ($error -match "Missing required property: Source") {
        $correctedInfo.Source = "corrected.txt"
    }
    elseif ($error -match "Missing required property: Text") {
        $correctedInfo.Text = "Texte corrigé"
    }
    elseif ($error -match "Invalid ProcessingState value") {
        $correctedInfo.ProcessingState = "Raw"
    }
    elseif ($error -match "ConfidenceScore must be between 0 and 100") {
        $correctedInfo.ConfidenceScore = 75
    }
}

# Vérifier si l'objet corrigé est valide
$remainingErrors = Get-ExtractedInfoValidationErrors -Info $correctedInfo

Write-Host "`nAprès correction :"
if ($remainingErrors.Count -eq 0) {
    Write-Host "L'objet est maintenant valide."
}
else {
    Write-Host "L'objet est toujours invalide, erreurs restantes :"
    foreach ($error in $remainingErrors) {
        Write-Host "- $error"
    }
}
```

Cet exemple montre comment corriger un objet d'information extraite en fonction des erreurs de validation détectées.

## LIENS CONNEXES
- [Test-ExtractedInfo](Test-ExtractedInfo.md)
- [Add-ExtractedInfoValidationRule](Add-ExtractedInfoValidationRule.md)
- [Remove-ExtractedInfoValidationRule](Remove-ExtractedInfoValidationRule.md)
- [Get-ExtractedInfoCollectionValidationErrors](Get-ExtractedInfoCollectionValidationErrors.md)
- [New-ExtractedInfo](New-ExtractedInfo.md)
