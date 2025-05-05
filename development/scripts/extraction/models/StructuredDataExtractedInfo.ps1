using namespace System.Collections.Generic

<#
.SYNOPSIS
    Classe pour les informations structurÃ©es extraites.
.DESCRIPTION
    Ã‰tend la classe ValidatableExtractedInfo pour reprÃ©senter
    des informations structurÃ©es extraites avec des propriÃ©tÃ©s spÃ©cifiques.
.NOTES
    Auteur: EMAIL_SENDER_1 Team
    Version: 1.0
    Date de crÃ©ation: 2025-05-15
#>

# Importer les dÃ©pendances
. "$PSScriptRoot\ValidatableExtractedInfo.ps1"

class StructuredDataExtractedInfo : ValidatableExtractedInfo {
    # PropriÃ©tÃ©s spÃ©cifiques aux informations structurÃ©es
    [hashtable]$Data
    [string]$DataFormat
    [string]$Schema
    [string[]]$DataKeys
    [int]$DataItemCount
    [bool]$IsNested
    [int]$MaxDepth

    # Constructeur par dÃ©faut
    StructuredDataExtractedInfo() : base() {
        $this.InitializeStructuredData()
    }

    # Constructeur avec source
    StructuredDataExtractedInfo([string]$source) : base($source) {
        $this.InitializeStructuredData()
    }

    # Constructeur avec source et extracteur
    StructuredDataExtractedInfo([string]$source, [string]$extractorName) : base($source, $extractorName) {
        $this.InitializeStructuredData()
    }

    # Constructeur avec donnÃ©es
    StructuredDataExtractedInfo([string]$source, [string]$extractorName, [hashtable]$data) : base($source, $extractorName) {
        $this.InitializeStructuredData()
        $this.SetData($data)
    }

    # MÃ©thode d'initialisation des donnÃ©es structurÃ©es
    hidden [void] InitializeStructuredData() {
        $this.Data = @{}
        $this.DataFormat = "Hashtable"
        $this.Schema = ""
        $this.DataKeys = @()
        $this.DataItemCount = 0
        $this.IsNested = $false
        $this.MaxDepth = 0

        # Ajouter les rÃ¨gles de validation spÃ©cifiques aux donnÃ©es structurÃ©es
        $this.AddStructuredDataValidationRules()
    }

    # MÃ©thode pour ajouter les rÃ¨gles de validation spÃ©cifiques aux donnÃ©es structurÃ©es
    hidden [void] AddStructuredDataValidationRules() {
        # Validation des donnÃ©es
        $this.AddValidationRule("Data", {
                param($target, $value)
                return $null -ne $value
            }, "Les donnÃ©es ne peuvent pas Ãªtre null")

        # Validation du format de donnÃ©es
        $this.AddValidationRule("DataFormat", {
                param($target, $value)
                $validFormats = @("Hashtable", "PSObject", "Dictionary", "Array", "Json", "Xml", "Csv")
                return -not [string]::IsNullOrEmpty($value) -and $validFormats -contains $value
            }, "Le format de donnÃ©es doit Ãªtre l'un des suivants: Hashtable, PSObject, Dictionary, Array, Json, Xml, Csv")
    }

    # MÃ©thode pour dÃ©finir les donnÃ©es
    [void] SetData([hashtable]$data) {
        $this.Data = $data
        $this.AnalyzeData()
    }

    # MÃ©thode pour analyser les donnÃ©es
    [void] AnalyzeData() {
        if ($null -eq $this.Data) {
            $this.DataKeys = @()
            $this.DataItemCount = 0
            $this.IsNested = $false
            $this.MaxDepth = 0
            return
        }

        # Extraire les clÃ©s
        $this.DataKeys = $this.Data.Keys -as [string[]]
        $this.DataItemCount = $this.Data.Count

        # VÃ©rifier si les donnÃ©es sont imbriquÃ©es
        $this.IsNested = $false
        $this.MaxDepth = 1

        foreach ($key in $this.Data.Keys) {
            $value = $this.Data[$key]

            if ($value -is [hashtable] -or $value -is [System.Collections.IDictionary] -or
                $value -is [PSCustomObject] -or $value -is [array] -or $value -is [System.Collections.IList]) {
                $this.IsNested = $true
                $depth = $this.CalculateDepth($value, 1)
                if ($depth -gt $this.MaxDepth) {
                    $this.MaxDepth = $depth
                }
            }
        }
    }

    # MÃ©thode pour calculer la profondeur d'un objet imbriquÃ©
    hidden [int] CalculateDepth($object, [int]$currentDepth) {
        if ($null -eq $object) {
            return $currentDepth
        }

        $maxChildDepth = $currentDepth

        if ($object -is [hashtable] -or $object -is [System.Collections.IDictionary]) {
            foreach ($key in $object.Keys) {
                $childDepth = $this.CalculateDepth($object[$key], $currentDepth + 1)
                if ($childDepth -gt $maxChildDepth) {
                    $maxChildDepth = $childDepth
                }
            }
        } elseif ($object -is [PSCustomObject]) {
            foreach ($property in $object.PSObject.Properties) {
                $childDepth = $this.CalculateDepth($property.Value, $currentDepth + 1)
                if ($childDepth -gt $maxChildDepth) {
                    $maxChildDepth = $childDepth
                }
            }
        } elseif ($object -is [array] -or $object -is [System.Collections.IList]) {
            foreach ($item in $object) {
                $childDepth = $this.CalculateDepth($item, $currentDepth + 1)
                if ($childDepth -gt $maxChildDepth) {
                    $maxChildDepth = $childDepth
                }
            }
        }

        return $maxChildDepth
    }

    # MÃ©thode pour dÃ©finir le schÃ©ma
    [void] SetSchema([string]$schema) {
        $this.Schema = $schema
    }

    # MÃ©thode pour gÃ©nÃ©rer un schÃ©ma simple (implÃ©mentation simplifiÃ©e)
    [string] GenerateSchema() {
        if ($null -eq $this.Data -or $this.Data.Count -eq 0) {
            return ""
        }

        # ImplÃ©mentation simplifiÃ©e: gÃ©nÃ©rer un schÃ©ma JSON basique
        $schemaObj = @{
            type       = "object"
            properties = @{}
            required   = @()
        }

        foreach ($key in $this.Data.Keys) {
            $value = $this.Data[$key]
            $type = $this.GetJsonSchemaType($value)

            $schemaObj.properties[$key] = @{
                type = $type
            }

            # Ajouter Ã  la liste des propriÃ©tÃ©s requises si la valeur n'est pas null
            if ($null -ne $value) {
                $schemaObj.required += $key
            }
        }

        $schemaJson = ConvertTo-Json -InputObject $schemaObj -Depth 10
        $this.Schema = $schemaJson
        return $schemaJson
    }

    # MÃ©thode pour dÃ©terminer le type JSON Schema d'une valeur
    hidden [string] GetJsonSchemaType($value) {
        if ($null -eq $value) {
            return "null"
        }

        switch ($value.GetType().Name) {
            "String" { return "string" }
            "Int32" { return "integer" }
            "Int64" { return "integer" }
            "Double" { return "number" }
            "Boolean" { return "boolean" }
            "DateTime" { return "string" }
            "Hashtable" { return "object" }
            "PSCustomObject" { return "object" }
            "Object[]" { return "array" }
            default {
                if ($value -is [array]) {
                    return "array"
                }
                return "string"
            }
        }
        # Cette ligne ne devrait jamais Ãªtre atteinte, mais elle est nÃ©cessaire pour Ã©viter l'erreur de compilation
        return "string"
    }

    # MÃ©thode pour obtenir une valeur par clÃ©
    [object] GetValue([string]$key) {
        if ($this.Data.ContainsKey($key)) {
            return $this.Data[$key]
        }
        return $null
    }

    # MÃ©thode pour dÃ©finir une valeur
    [void] SetValue([string]$key, [object]$value) {
        $this.Data[$key] = $value
        $this.AnalyzeData()
    }

    # MÃ©thode pour supprimer une clÃ©
    [bool] RemoveKey([string]$key) {
        if ($this.Data.ContainsKey($key)) {
            $this.Data.Remove($key)
            $this.AnalyzeData()
            return $true
        }
        return $false
    }

    # MÃ©thode pour vÃ©rifier si une clÃ© existe
    [bool] ContainsKey([string]$key) {
        return $this.Data.ContainsKey($key)
    }

    # MÃ©thode pour fusionner avec d'autres donnÃ©es
    [void] MergeWith([hashtable]$otherData) {
        foreach ($key in $otherData.Keys) {
            $this.Data[$key] = $otherData[$key]
        }
        $this.AnalyzeData()
    }

    # Surcharge de la mÃ©thode GetSummary
    [string] GetSummary() {
        $baseInfo = ([ValidatableExtractedInfo]$this).GetSummary()
        return "$baseInfo, DonnÃ©es: $($this.DataItemCount) Ã©lÃ©ments, Profondeur max: $($this.MaxDepth)"
    }

    # Surcharge de la mÃ©thode Clone pour retourner un StructuredDataExtractedInfo
    [StructuredDataExtractedInfo] Clone() {
        $clone = [StructuredDataExtractedInfo]::new()

        # Cloner les propriÃ©tÃ©s de base
        $clone.Id = $this.Id
        $clone.Source = $this.Source
        $clone.ExtractedAt = $this.ExtractedAt
        $clone.ExtractorName = $this.ExtractorName
        $clone.ProcessingState = $this.ProcessingState
        $clone.ConfidenceScore = $this.ConfidenceScore
        $clone.IsValid = $this.IsValid

        # Cloner les mÃ©tadonnÃ©es
        foreach ($key in $this.Metadata.Keys) {
            $clone.Metadata[$key] = $this.Metadata[$key]
        }

        # Cloner les rÃ¨gles de validation
        foreach ($propertyName in $this.ValidationRules.Keys) {
            $rules = $this.ValidationRules[$propertyName]

            foreach ($rule in $rules) {
                $clonedRule = $rule.Clone()

                if (-not $clone.ValidationRules.ContainsKey($propertyName)) {
                    $clone.ValidationRules[$propertyName] = [List[ValidationRule]]::new()
                }

                $clone.ValidationRules[$propertyName].Add($clonedRule)
            }
        }

        # Cloner les propriÃ©tÃ©s spÃ©cifiques
        $clone.DataFormat = $this.DataFormat
        $clone.Schema = $this.Schema
        $clone.DataKeys = $this.DataKeys.Clone()
        $clone.DataItemCount = $this.DataItemCount
        $clone.IsNested = $this.IsNested
        $clone.MaxDepth = $this.MaxDepth

        # Cloner les donnÃ©es (copie profonde)
        $clone.Data = $this.CloneHashtable($this.Data)

        return $clone
    }

    # MÃ©thode pour cloner un hashtable (copie profonde)
    hidden [hashtable] CloneHashtable([hashtable]$original) {
        $clone = @{}

        foreach ($key in $original.Keys) {
            $value = $original[$key]

            if ($value -is [hashtable]) {
                $clone[$key] = $this.CloneHashtable($value)
            } elseif ($value -is [array]) {
                $clone[$key] = $this.CloneArray($value)
            } else {
                $clone[$key] = $value
            }
        }

        return $clone
    }

    # MÃ©thode pour cloner un tableau (copie profonde)
    hidden [array] CloneArray([array]$original) {
        $clone = @()

        foreach ($item in $original) {
            if ($item -is [hashtable]) {
                $clone += $this.CloneHashtable($item)
            } elseif ($item -is [array]) {
                $clone += $this.CloneArray($item)
            } else {
                $clone += $item
            }
        }

        return $clone
    }
}
