# Add-ExtractedInfoValidationRule

## SYNOPSIS
Ajoute une règle de validation personnalisée pour les objets d'information extraite.

## SYNTAXE

```powershell
Add-ExtractedInfoValidationRule
    -Name <String>
    -Rule <ScriptBlock>
    [-Description <String>]
    [-TargetType <String>]
    [-Force]
    [<CommonParameters>]
```

## DESCRIPTION
La fonction `Add-ExtractedInfoValidationRule` permet d'ajouter une règle de validation personnalisée qui sera appliquée automatiquement lors de la validation des objets d'information extraite avec les fonctions `Test-ExtractedInfo` et `Get-ExtractedInfoValidationErrors`.

Les règles de validation personnalisées permettent d'étendre le système de validation intégré avec des vérifications spécifiques à vos besoins, comme des contraintes métier, des formats particuliers, ou des relations entre propriétés.

## PARAMÈTRES

### -Name
Spécifie le nom unique de la règle de validation. Ce paramètre est obligatoire.

```yaml
Type: String
Required: True
```

### -Rule
Spécifie le script block contenant la logique de validation. Le script block doit accepter un paramètre (l'objet d'information extraite) et retourner un tableau de chaînes d'erreur (vide si aucune erreur). Ce paramètre est obligatoire.

```yaml
Type: ScriptBlock
Required: True
```

### -Description
Spécifie une description de la règle de validation.

```yaml
Type: String
Required: False
```

### -TargetType
Spécifie le type d'objet d'information extraite auquel cette règle s'applique. Si ce paramètre n'est pas spécifié, la règle s'applique à tous les types. Les valeurs valides sont : "ExtractedInfo", "TextExtractedInfo", "StructuredDataExtractedInfo", "MediaExtractedInfo".

```yaml
Type: String
Required: False
```

### -Force
Indique si une règle existante avec le même nom doit être remplacée. Si ce paramètre n'est pas spécifié et qu'une règle avec le même nom existe déjà, la fonction génère une erreur.

```yaml
Type: SwitchParameter
Default: False
```

### <CommonParameters>
Cette fonction prend en charge les paramètres communs : Verbose, Debug, ErrorAction, ErrorVariable, WarningAction, WarningVariable, OutBuffer, PipelineVariable, et OutVariable.

## ENTRÉES
Aucune. Cette fonction ne prend pas d'entrée depuis le pipeline.

## SORTIES
### System.Boolean
Retourne $true si la règle a été ajoutée avec succès, ou $false en cas d'échec.

## NOTES
- Les règles de validation ajoutées avec cette fonction sont stockées en mémoire et sont disponibles jusqu'à la fin de la session PowerShell ou jusqu'à ce qu'elles soient supprimées avec `Remove-ExtractedInfoValidationRule`.
- Pour appliquer une règle de validation de manière ponctuelle sans l'ajouter de façon permanente, utilisez le paramètre `-CustomValidationRule` des fonctions `Test-ExtractedInfo` et `Get-ExtractedInfoValidationErrors`.
- Les règles de validation sont appliquées dans l'ordre suivant :
  1. Règles de validation standard intégrées
  2. Règles de validation globales ajoutées avec cette fonction
  3. Règles de validation personnalisées spécifiées avec le paramètre `-CustomValidationRule`
- Si plusieurs règles détectent des erreurs, toutes les erreurs sont combinées dans le résultat de validation.
- Pour obtenir la liste des règles de validation actuellement enregistrées, utilisez la fonction `Get-ExtractedInfoValidationRules`.

## EXEMPLES

### Exemple 1 : Ajouter une règle de validation simple
```powershell
# Définir une règle de validation qui vérifie que le score de confiance est d'au moins 50
$minConfidenceRule = {
    param($Info)
    
    $errors = @()
    
    if ($Info.ConfidenceScore -lt 50) {
        $errors += "Le score de confiance doit être d'au moins 50 (actuellement : $($Info.ConfidenceScore))"
    }
    
    return $errors
}

# Ajouter la règle
$result = Add-ExtractedInfoValidationRule -Name "MinConfidenceRule" -Rule $minConfidenceRule -Description "Vérifie que le score de confiance est d'au moins 50"

if ($result) {
    Write-Host "La règle de validation a été ajoutée avec succès."
}

# Tester la règle
$info = New-ExtractedInfo -Source "test.txt" -ConfidenceScore 30
$validationResult = Test-ExtractedInfo -Info $info -Detailed

if (-not $validationResult.IsValid) {
    Write-Host "Erreurs de validation :"
    foreach ($error in $validationResult.Errors) {
        Write-Host "- $error"
    }
}
```

Cet exemple ajoute une règle de validation qui vérifie que le score de confiance est d'au moins 50, puis teste la règle sur un objet d'information extraite.

### Exemple 2 : Ajouter une règle de validation spécifique à un type
```powershell
# Définir une règle de validation pour les objets de type TextExtractedInfo
$textLengthRule = {
    param($Info)
    
    $errors = @()
    
    if ($Info.Text.Length -lt 10) {
        $errors += "Le texte doit contenir au moins 10 caractères (actuellement : $($Info.Text.Length))"
    }
    
    return $errors
}

# Ajouter la règle pour le type TextExtractedInfo uniquement
$result = Add-ExtractedInfoValidationRule -Name "TextLengthRule" -Rule $textLengthRule -TargetType "TextExtractedInfo" -Description "Vérifie que le texte contient au moins 10 caractères"

if ($result) {
    Write-Host "La règle de validation a été ajoutée avec succès."
}

# Tester la règle sur un objet TextExtractedInfo
$textInfo = New-TextExtractedInfo -Source "text.txt" -Text "Court"
$textValidationResult = Test-ExtractedInfo -Info $textInfo -Detailed

if (-not $textValidationResult.IsValid) {
    Write-Host "Erreurs de validation pour l'objet texte :"
    foreach ($error in $textValidationResult.Errors) {
        Write-Host "- $error"
    }
}

# Tester la règle sur un objet ExtractedInfo (la règle ne devrait pas s'appliquer)
$basicInfo = New-ExtractedInfo -Source "basic.txt"
$basicValidationResult = Test-ExtractedInfo -Info $basicInfo -Detailed

if ($basicValidationResult.IsValid) {
    Write-Host "L'objet de base est valide (la règle TextLengthRule ne s'applique pas)."
}
```

Cet exemple ajoute une règle de validation spécifique aux objets de type TextExtractedInfo qui vérifie que le texte contient au moins 10 caractères, puis teste la règle sur différents types d'objets.

### Exemple 3 : Ajouter une règle de validation complexe
```powershell
# Définir une règle de validation complexe qui vérifie plusieurs conditions
$complexRule = {
    param($Info)
    
    $errors = @()
    
    # Vérifier que la source est une URL valide pour les extracteurs web
    if ($Info.ExtractorName -like "*Web*" -and -not ($Info.Source -match "^https?://")) {
        $errors += "La source doit être une URL valide pour les extracteurs web (actuellement : $($Info.Source))"
    }
    
    # Vérifier que le score de confiance est cohérent avec l'état de traitement
    if ($Info.ProcessingState -eq "Validated" -and $Info.ConfidenceScore -lt 80) {
        $errors += "Le score de confiance doit être d'au moins 80 pour les objets validés (actuellement : $($Info.ConfidenceScore))"
    }
    
    # Vérifier que les métadonnées contiennent certaines informations pour les objets validés
    if ($Info.ProcessingState -eq "Validated") {
        if (-not $Info.Metadata.ContainsKey("ValidatedBy")) {
            $errors += "Les métadonnées doivent contenir la clé 'ValidatedBy' pour les objets validés"
        }
        if (-not $Info.Metadata.ContainsKey("ValidationDate")) {
            $errors += "Les métadonnées doivent contenir la clé 'ValidationDate' pour les objets validés"
        }
    }
    
    return $errors
}

# Ajouter la règle
$result = Add-ExtractedInfoValidationRule -Name "BusinessRules" -Rule $complexRule -Description "Règles métier pour la validation des objets"

if ($result) {
    Write-Host "La règle de validation complexe a été ajoutée avec succès."
}

# Tester la règle sur différents objets
$webInfo = New-ExtractedInfo -Source "example.com" -ExtractorName "WebExtractor"
$validatedInfo = New-ExtractedInfo -Source "document.pdf" -ProcessingState "Validated" -ConfidenceScore 75

# Valider les objets
$webValidationResult = Test-ExtractedInfo -Info $webInfo -Detailed
$validatedValidationResult = Test-ExtractedInfo -Info $validatedInfo -Detailed

# Afficher les résultats
Write-Host "Validation de l'objet web :"
if (-not $webValidationResult.IsValid) {
    foreach ($error in $webValidationResult.Errors) {
        Write-Host "- $error"
    }
}

Write-Host "`nValidation de l'objet validé :"
if (-not $validatedValidationResult.IsValid) {
    foreach ($error in $validatedValidationResult.Errors) {
        Write-Host "- $error"
    }
}
```

Cet exemple ajoute une règle de validation complexe qui vérifie plusieurs conditions métier, puis teste la règle sur différents objets.

### Exemple 4 : Remplacer une règle existante
```powershell
# Définir une première version de la règle
$initialRule = {
    param($Info)
    
    $errors = @()
    
    if ($Info.Source -notlike "*.txt") {
        $errors += "La source doit être un fichier texte (*.txt)"
    }
    
    return $errors
}

# Ajouter la règle initiale
Add-ExtractedInfoValidationRule -Name "SourceRule" -Rule $initialRule | Out-Null

# Définir une version améliorée de la règle
$improvedRule = {
    param($Info)
    
    $errors = @()
    
    # Règle plus flexible : accepte les fichiers texte et les fichiers markdown
    if ($Info.Source -notlike "*.txt" -and $Info.Source -notlike "*.md") {
        $errors += "La source doit être un fichier texte (*.txt) ou un fichier markdown (*.md)"
    }
    
    return $errors
}

# Tenter de remplacer la règle sans le paramètre Force
try {
    Add-ExtractedInfoValidationRule -Name "SourceRule" -Rule $improvedRule -ErrorAction Stop
    Write-Host "La règle a été remplacée (cela ne devrait pas se produire)."
}
catch {
    Write-Host "Erreur attendue : $($_.Exception.Message)"
    
    # Remplacer la règle avec le paramètre Force
    $result = Add-ExtractedInfoValidationRule -Name "SourceRule" -Rule $improvedRule -Force
    
    if ($result) {
        Write-Host "La règle a été remplacée avec succès en utilisant le paramètre Force."
    }
}

# Tester la règle mise à jour
$txtInfo = New-ExtractedInfo -Source "document.txt"
$mdInfo = New-ExtractedInfo -Source "document.md"
$docInfo = New-ExtractedInfo -Source "document.docx"

$txtValid = Test-ExtractedInfo -Info $txtInfo
$mdValid = Test-ExtractedInfo -Info $mdInfo
$docValid = Test-ExtractedInfo -Info $docInfo

Write-Host "Fichier texte valide : $txtValid"
Write-Host "Fichier markdown valide : $mdValid"
Write-Host "Fichier docx valide : $docValid"
```

Cet exemple montre comment remplacer une règle de validation existante en utilisant le paramètre `-Force`.

### Exemple 5 : Ajouter plusieurs règles de validation
```powershell
# Définir plusieurs règles de validation
$rules = @{
    "MinConfidenceRule" = @{
        Rule = {
            param($Info)
            $errors = @()
            if ($Info.ConfidenceScore -lt 50) {
                $errors += "Le score de confiance doit être d'au moins 50"
            }
            return $errors
        }
        Description = "Vérifie que le score de confiance est d'au moins 50"
        TargetType = $null # S'applique à tous les types
    }
    
    "TextLengthRule" = @{
        Rule = {
            param($Info)
            $errors = @()
            if ($Info.Text.Length -lt 10) {
                $errors += "Le texte doit contenir au moins 10 caractères"
            }
            return $errors
        }
        Description = "Vérifie que le texte contient au moins 10 caractères"
        TargetType = "TextExtractedInfo"
    }
    
    "StructuredDataRule" = @{
        Rule = {
            param($Info)
            $errors = @()
            if (-not $Info.Data -or $Info.Data.Count -eq 0) {
                $errors += "Les données structurées ne doivent pas être vides"
            }
            return $errors
        }
        Description = "Vérifie que les données structurées ne sont pas vides"
        TargetType = "StructuredDataExtractedInfo"
    }
}

# Ajouter toutes les règles
foreach ($ruleName in $rules.Keys) {
    $ruleInfo = $rules[$ruleName]
    
    $params = @{
        Name = $ruleName
        Rule = $ruleInfo.Rule
        Description = $ruleInfo.Description
        Force = $true # Remplacer si la règle existe déjà
    }
    
    if ($ruleInfo.TargetType) {
        $params.TargetType = $ruleInfo.TargetType
    }
    
    $result = Add-ExtractedInfoValidationRule @params
    
    if ($result) {
        Write-Host "Règle '$ruleName' ajoutée avec succès."
    }
    else {
        Write-Host "Échec de l'ajout de la règle '$ruleName'."
    }
}

# Afficher les règles ajoutées
$registeredRules = Get-ExtractedInfoValidationRules -Detailed
Write-Host "`nRègles de validation enregistrées :"
foreach ($ruleName in $registeredRules.Keys) {
    $ruleInfo = $registeredRules[$ruleName]
    $targetType = if ($ruleInfo.TargetType) { $ruleInfo.TargetType } else { "Tous les types" }
    
    Write-Host "- $ruleName : $($ruleInfo.Description) (Cible : $targetType)"
}
```

Cet exemple ajoute plusieurs règles de validation avec différentes cibles et descriptions, puis affiche la liste des règles enregistrées.

### Exemple 6 : Utiliser des règles de validation pour implémenter des contraintes métier
```powershell
# Définir une règle de validation pour les contraintes métier
$businessRule = {
    param($Info)
    
    $errors = @()
    
    # Règle 1 : Les documents confidentiels doivent avoir une source spécifique
    if ($Info.Metadata.ContainsKey("Confidential") -and $Info.Metadata.Confidential -eq $true) {
        if (-not ($Info.Source -like "secure://*")) {
            $errors += "Les documents confidentiels doivent avoir une source commençant par 'secure://'"
        }
        
        # Règle 2 : Les documents confidentiels doivent avoir un score de confiance élevé
        if ($Info.ConfidenceScore -lt 90) {
            $errors += "Les documents confidentiels doivent avoir un score de confiance d'au moins 90"
        }
    }
    
    # Règle 3 : Les documents en état d'erreur doivent avoir une raison d'erreur
    if ($Info.ProcessingState -eq "Error" -and (-not $Info.Metadata.ContainsKey("ErrorReason"))) {
        $errors += "Les documents en état d'erreur doivent avoir une métadonnée 'ErrorReason'"
    }
    
    return $errors
}

# Ajouter la règle
$result = Add-ExtractedInfoValidationRule -Name "BusinessConstraints" -Rule $businessRule -Description "Contraintes métier pour les documents"

if ($result) {
    Write-Host "La règle de contraintes métier a été ajoutée avec succès."
}

# Tester la règle sur différents objets
$confidentialInfo = New-ExtractedInfo -Source "regular://document.pdf" -ConfidenceScore 85
$confidentialInfo = Add-ExtractedInfoMetadata -Info $confidentialInfo -Key "Confidential" -Value $true

$errorInfo = New-ExtractedInfo -Source "document.txt" -ProcessingState "Error"

# Valider les objets
$confidentialValidation = Test-ExtractedInfo -Info $confidentialInfo -Detailed
$errorValidation = Test-ExtractedInfo -Info $errorInfo -Detailed

# Afficher les résultats
Write-Host "Validation du document confidentiel :"
if (-not $confidentialValidation.IsValid) {
    foreach ($error in $confidentialValidation.Errors) {
        Write-Host "- $error"
    }
}

Write-Host "`nValidation du document en erreur :"
if (-not $errorValidation.IsValid) {
    foreach ($error in $errorValidation.Errors) {
        Write-Host "- $error"
    }
}

# Corriger les objets
$correctedConfidential = Copy-ExtractedInfo -Info $confidentialInfo
$correctedConfidential.Source = "secure://document.pdf"
$correctedConfidential.ConfidenceScore = 95

$correctedError = Copy-ExtractedInfo -Info $errorInfo
$correctedError = Add-ExtractedInfoMetadata -Info $correctedError -Key "ErrorReason" -Value "Fichier corrompu"

# Valider les objets corrigés
$correctedConfidentialValid = Test-ExtractedInfo -Info $correctedConfidential
$correctedErrorValid = Test-ExtractedInfo -Info $correctedError

Write-Host "`nDocument confidentiel corrigé valide : $correctedConfidentialValid"
Write-Host "Document en erreur corrigé valide : $correctedErrorValid"
```

Cet exemple utilise des règles de validation pour implémenter des contraintes métier complexes, puis montre comment corriger les objets pour qu'ils respectent ces contraintes.

### Exemple 7 : Utiliser des règles de validation pour la validation de collections
```powershell
# Définir une règle de validation pour les objets dans une collection
$collectionItemRule = {
    param($Info)
    
    $errors = @()
    
    # Règle : Tous les objets d'une même collection doivent avoir le même extracteur
    if ($Info.Metadata.ContainsKey("CollectionName") -and -not $Info.Metadata.ContainsKey("ExtractorOverride")) {
        $expectedExtractor = "$($Info.Metadata.CollectionName)Extractor"
        
        if ($Info.ExtractorName -ne $expectedExtractor) {
            $errors += "L'extracteur doit être '$expectedExtractor' pour les objets de la collection '$($Info.Metadata.CollectionName)'"
        }
    }
    
    return $errors
}

# Ajouter la règle
Add-ExtractedInfoValidationRule -Name "CollectionConsistencyRule" -Rule $collectionItemRule -Description "Règle de cohérence pour les collections" -Force | Out-Null

# Créer une collection
$collection = New-ExtractedInfoCollection -Name "TestCollection"

# Créer des objets avec des métadonnées de collection
$info1 = New-ExtractedInfo -Source "doc1.txt" -ExtractorName "TestCollectionExtractor"
$info1 = Add-ExtractedInfoMetadata -Info $info1 -Key "CollectionName" -Value "TestCollection"

$info2 = New-ExtractedInfo -Source "doc2.txt" -ExtractorName "TestCollectionExtractor"
$info2 = Add-ExtractedInfoMetadata -Info $info2 -Key "CollectionName" -Value "TestCollection"

$info3 = New-ExtractedInfo -Source "doc3.txt" -ExtractorName "DifferentExtractor"
$info3 = Add-ExtractedInfoMetadata -Info $info3 -Key "CollectionName" -Value "TestCollection"

# Ajouter les objets à la collection
$collection = Add-ExtractedInfoToCollection -Collection $collection -InfoList @($info1, $info2)

# Valider la collection
$collectionValid = Test-ExtractedInfoCollection -Collection $collection -IncludeItemErrors -Detailed

# Afficher les résultats
Write-Host "Validation de la collection :"
Write-Host "- Collection valide : $($collectionValid.IsValid)"

if ($collectionValid.ItemErrors -and $collectionValid.ItemErrors.Count -gt 0) {
    Write-Host "- Erreurs d'éléments :"
    foreach ($itemError in $collectionValid.ItemErrors) {
        Write-Host "  * Élément à l'index $($itemError.ItemIndex) :"
        foreach ($error in $itemError.Errors) {
            Write-Host "    - $error"
        }
    }
}

# Tenter d'ajouter l'objet invalide
try {
    # Valider d'abord l'objet
    $info3Valid = Test-ExtractedInfo -Info $info3
    
    if (-not $info3Valid) {
        $errors = Get-ExtractedInfoValidationErrors -Info $info3
        Write-Host "`nL'objet info3 est invalide :"
        foreach ($error in $errors) {
            Write-Host "- $error"
        }
        
        # Corriger l'objet
        $correctedInfo3 = Copy-ExtractedInfo -Info $info3 -ExtractorName "TestCollectionExtractor"
        
        # Vérifier que l'objet corrigé est valide
        $correctedInfo3Valid = Test-ExtractedInfo -Info $correctedInfo3
        Write-Host "`nL'objet corrigé est valide : $correctedInfo3Valid"
        
        # Ajouter l'objet corrigé à la collection
        $collection = Add-ExtractedInfoToCollection -Collection $collection -Info $correctedInfo3
        Write-Host "L'objet corrigé a été ajouté à la collection."
    }
    else {
        # Ajouter l'objet à la collection
        $collection = Add-ExtractedInfoToCollection -Collection $collection -Info $info3
        Write-Host "L'objet a été ajouté à la collection (cela ne devrait pas se produire)."
    }
}
catch {
    Write-Host "Erreur lors de l'ajout de l'objet à la collection : $($_.Exception.Message)"
}
```

Cet exemple utilise des règles de validation pour assurer la cohérence des objets dans une collection, puis montre comment corriger un objet invalide avant de l'ajouter à la collection.

## LIENS CONNEXES
- [Get-ExtractedInfoValidationRules](Get-ExtractedInfoValidationRules.md)
- [Remove-ExtractedInfoValidationRule](Remove-ExtractedInfoValidationRule.md)
- [Clear-ExtractedInfoValidationRules](Clear-ExtractedInfoValidationRules.md)
- [Test-ExtractedInfo](Test-ExtractedInfo.md)
- [Get-ExtractedInfoValidationErrors](Get-ExtractedInfoValidationErrors.md)
