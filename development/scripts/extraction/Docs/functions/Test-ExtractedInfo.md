# Test-ExtractedInfo

## SYNOPSIS
Vérifie si un objet d'information extraite est valide selon les règles de validation définies.

## SYNTAXE

```powershell
Test-ExtractedInfo
    -Info <Hashtable>
    [-CustomValidationRule <ScriptBlock>]
    [-Detailed]
    [<CommonParameters>]
```

## DESCRIPTION
La fonction `Test-ExtractedInfo` vérifie si un objet d'information extraite est valide selon un ensemble de règles de validation. Ces règles comprennent la vérification des propriétés requises, des types de données, des valeurs autorisées et d'autres contraintes spécifiques au type d'information extraite.

La fonction prend en charge l'ajout de règles de validation personnalisées et peut fournir des résultats détaillés sur les problèmes de validation détectés.

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
Indique si la fonction doit retourner un résultat détaillé contenant des informations sur les erreurs de validation plutôt qu'un simple booléen.

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
### System.Boolean ou System.Collections.Hashtable
- Si le paramètre `-Detailed` n'est pas spécifié, la fonction retourne un booléen indiquant si l'objet est valide.
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
- Pour obtenir la liste détaillée des erreurs de validation sans utiliser le paramètre `-Detailed`, utilisez la fonction `Get-ExtractedInfoValidationErrors`.

## EXEMPLES

### Exemple 1 : Valider un objet d'information extraite simple
```powershell
$info = New-ExtractedInfo -Source "document.pdf" -ExtractorName "PDFExtractor"
$isValid = Test-ExtractedInfo -Info $info
Write-Host "L'objet est valide : $isValid"
```

Cet exemple vérifie si un objet d'information extraite simple est valide.

### Exemple 2 : Valider un objet d'information extraite avec résultat détaillé
```powershell
# Créer un objet d'information extraite avec une propriété invalide
$invalidInfo = New-ExtractedInfo -Source "document.pdf" -ExtractorName "PDFExtractor"
$invalidInfo.ConfidenceScore = 150 # Invalide : doit être entre 0 et 100

# Valider l'objet avec résultat détaillé
$validationResult = Test-ExtractedInfo -Info $invalidInfo -Detailed

# Afficher les résultats
Write-Host "L'objet est valide : $($validationResult.IsValid)"
if (-not $validationResult.IsValid) {
    Write-Host "Erreurs de validation :"
    foreach ($error in $validationResult.Errors) {
        Write-Host "- $error"
    }
}
```

Cet exemple valide un objet d'information extraite avec une propriété invalide et affiche les erreurs de validation détaillées.

### Exemple 3 : Valider un objet d'information extraite avec une règle personnalisée
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
    
    return $errors
}

# Valider l'objet avec la règle personnalisée
$validationResult = Test-ExtractedInfo -Info $info -CustomValidationRule $customRule -Detailed

# Afficher les résultats
Write-Host "L'objet est valide : $($validationResult.IsValid)"
if (-not $validationResult.IsValid) {
    Write-Host "Erreurs de validation :"
    foreach ($error in $validationResult.Errors) {
        Write-Host "- $error"
    }
}
```

Cet exemple valide un objet d'information extraite de type texte avec une règle personnalisée qui vérifie la longueur du texte.

### Exemple 4 : Valider différents types d'objets d'information extraite
```powershell
# Créer différents types d'objets d'information extraite
$basicInfo = New-ExtractedInfo -Source "basic.txt"
$textInfo = New-TextExtractedInfo -Source "text.txt" -Text "Exemple de texte"
$structuredInfo = New-StructuredDataExtractedInfo -Source "data.json" -Data @{ Name = "Test" }
$mediaInfo = New-MediaExtractedInfo -Source "image.jpg" -MediaPath "C:\Images\image.jpg" -MediaType "Image"

# Fonction pour valider et afficher les résultats
function Test-AndReport {
    param($Info, $Description)
    
    $result = Test-ExtractedInfo -Info $Info -Detailed
    
    Write-Host "Validation de $Description :"
    Write-Host "- Type : $($Info._Type)"
    Write-Host "- Valide : $($result.IsValid)"
    
    if (-not $result.IsValid) {
        Write-Host "- Erreurs :"
        foreach ($error in $result.Errors) {
            Write-Host "  * $error"
        }
    }
    
    Write-Host ""
}

# Valider chaque type d'objet
Test-AndReport -Info $basicInfo -Description "l'objet de base"
Test-AndReport -Info $textInfo -Description "l'objet texte"
Test-AndReport -Info $structuredInfo -Description "l'objet données structurées"
Test-AndReport -Info $mediaInfo -Description "l'objet média"
```

Cet exemple valide différents types d'objets d'information extraite et affiche les résultats pour chacun.

### Exemple 5 : Valider un objet d'information extraite avec des propriétés manquantes
```powershell
# Créer un objet d'information extraite incomplet
$incompleteInfo = @{
    _Type = "TextExtractedInfo"
    Id = [guid]::NewGuid().ToString()
    # Source manquante
    ExtractorName = "TextExtractor"
    ExtractionDate = Get-Date
    LastModifiedDate = Get-Date
    ProcessingState = "Raw"
    ConfidenceScore = 75
    Metadata = @{}
    # Text manquant (requis pour TextExtractedInfo)
    Language = "en"
}

# Valider l'objet
$validationResult = Test-ExtractedInfo -Info $incompleteInfo -Detailed

# Afficher les résultats
Write-Host "L'objet est valide : $($validationResult.IsValid)"
Write-Host "Type d'objet : $($validationResult.ObjectType)"
Write-Host "Nombre d'erreurs : $($validationResult.Errors.Count)"

if (-not $validationResult.IsValid) {
    Write-Host "Erreurs de validation :"
    foreach ($error in $validationResult.Errors) {
        Write-Host "- $error"
    }
}
```

Cet exemple valide un objet d'information extraite incomplet avec des propriétés requises manquantes.

### Exemple 6 : Utiliser Test-ExtractedInfo avec le pipeline
```powershell
# Créer plusieurs objets d'information extraite
$infos = @(
    (New-ExtractedInfo -Source "source1"),
    (New-ExtractedInfo -Source "source2" -ProcessingState "InvalidState"), # État invalide
    (New-TextExtractedInfo -Source "source3" -Text "Texte")
)

# Valider tous les objets via le pipeline
$validationResults = $infos | Test-ExtractedInfo -Detailed

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

Cet exemple utilise le pipeline pour valider plusieurs objets d'information extraite et affiche les résultats pour chacun.

### Exemple 7 : Valider un objet avec des règles de validation globales
```powershell
# Ajouter une règle de validation globale
$globalRule = {
    param($Info)
    
    $errors = @()
    
    # Règle : La source doit commencer par "http" pour les objets extraits du web
    if ($Info.Source -notlike "http*" -and $Info.ExtractorName -eq "WebExtractor") {
        $errors += "La source doit commencer par 'http' pour les objets extraits du web"
    }
    
    return $errors
}

Add-ExtractedInfoValidationRule -Name "WebSourceRule" -Rule $globalRule

# Créer des objets à valider
$validInfo = New-ExtractedInfo -Source "https://example.com" -ExtractorName "WebExtractor"
$invalidInfo = New-ExtractedInfo -Source "example.com" -ExtractorName "WebExtractor"

# Valider les objets
$validResult = Test-ExtractedInfo -Info $validInfo -Detailed
$invalidResult = Test-ExtractedInfo -Info $invalidInfo -Detailed

# Afficher les résultats
Write-Host "Objet valide :"
Write-Host "- Source : $($validInfo.Source)"
Write-Host "- Valide : $($validResult.IsValid)"

Write-Host "`nObjet invalide :"
Write-Host "- Source : $($invalidInfo.Source)"
Write-Host "- Valide : $($invalidResult.IsValid)"
if (-not $invalidResult.IsValid) {
    Write-Host "- Erreurs :"
    foreach ($error in $invalidResult.Errors) {
        Write-Host "  * $error"
    }
}

# Supprimer la règle de validation globale
Remove-ExtractedInfoValidationRule -Name "WebSourceRule"
```

Cet exemple ajoute une règle de validation globale qui vérifie que la source commence par "http" pour les objets extraits du web, puis valide deux objets avec cette règle.

## LIENS CONNEXES
- [Get-ExtractedInfoValidationErrors](Get-ExtractedInfoValidationErrors.md)
- [Add-ExtractedInfoValidationRule](Add-ExtractedInfoValidationRule.md)
- [Remove-ExtractedInfoValidationRule](Remove-ExtractedInfoValidationRule.md)
- [Test-ExtractedInfoCollection](Test-ExtractedInfoCollection.md)
- [New-ExtractedInfo](New-ExtractedInfo.md)
