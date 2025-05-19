# Tests de Phase 1 (P1) pour les fonctions de clonage profond

# Définir les fonctions directement dans le test
function Invoke-DeepClone {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [object]$InputObject,
        
        [Parameter(Mandatory = $false)]
        [int]$Depth = 100
    )

    process {
        if ($null -eq $InputObject) {
            return $null
        }

        # Traitement spécial pour les dictionnaires
        if ($InputObject -is [System.Collections.IDictionary]) {
            $clone = @{}
            foreach ($key in $InputObject.Keys) {
                $clone[$key] = Invoke-DeepClone -InputObject $InputObject[$key] -Depth $Depth
            }
            return $clone
        }
        # Traitement spécial pour les tableaux
        elseif ($InputObject -is [array]) {
            $clone = @()
            foreach ($item in $InputObject) {
                $clone += Invoke-DeepClone -InputObject $item -Depth $Depth
            }
            return $clone
        }
        # Traitement spécial pour ArrayList
        elseif ($InputObject -is [System.Collections.ArrayList]) {
            $clone = New-Object System.Collections.ArrayList
            foreach ($item in $InputObject) {
                [void]$clone.Add((Invoke-DeepClone -InputObject $item -Depth $Depth))
            }
            return $clone
        }
        # Traitement spécial pour les objets PSObject
        elseif ($InputObject -is [PSObject] -or $InputObject -is [PSCustomObject]) {
            return Invoke-PSObjectDeepClone -InputObject $InputObject -Depth $Depth
        }
        # Pour les autres objets, utiliser JSON
        else {
            try {
                $json = ConvertTo-Json -InputObject $InputObject -Depth $Depth -Compress
                return ConvertFrom-Json -InputObject $json -Depth $Depth
            }
            catch {
                Write-Verbose "Erreur lors du clonage via JSON: $_"
                throw "Erreur lors du clonage profond: $_"
            }
        }
    }
}

function Invoke-PSObjectDeepClone {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [PSObject]$InputObject,
        
        [Parameter(Mandatory = $false)]
        [int]$Depth = 100
    )

    process {
        if ($null -eq $InputObject) {
            return $null
        }

        # Pour les objets PSObject, créer un nouvel objet et copier les propriétés
        $clone = [PSCustomObject]@{}
        
        # Obtenir toutes les propriétés de l'objet
        $properties = $InputObject.PSObject.Properties
        
        # Copier chaque propriété
        foreach ($property in $properties) {
            $propertyName = $property.Name
            $propertyValue = $property.Value
            
            # Cloner récursivement la valeur de la propriété
            $clonedValue = Invoke-DeepClone -InputObject $propertyValue -Depth $Depth
            
            # Ajouter la propriété au clone
            $clone | Add-Member -MemberType NoteProperty -Name $propertyName -Value $clonedValue
        }
        
        return $clone
    }
}

Describe "[P1] Tests basiques pour Invoke-DeepClone" {
    It "Devrait cloner un objet simple" {
        # Arrange
        $original = [PSCustomObject]@{
            Name = "Test"
            Value = 42
        }

        # Act
        $clone = Invoke-DeepClone -InputObject $original

        # Assert
        $clone | Should -Not -BeNullOrEmpty
        $clone.Name | Should -Be "Test"
        $clone.Value | Should -Be 42
    }

    It "Devrait créer une copie indépendante (deep clone)" {
        # Arrange
        $original = [PSCustomObject]@{
            Name = "Test"
            Value = 42
        }

        # Act
        $clone = Invoke-DeepClone -InputObject $original
        $clone.Name = "Modified"
        $clone.Value = 99

        # Assert
        $original.Name | Should -Be "Test"
        $original.Value | Should -Be 42
    }

    It "Devrait cloner un tableau simple" {
        # Arrange
        $original = @(1, 2, 3, 4, 5)

        # Act
        $clone = Invoke-DeepClone -InputObject $original

        # Assert
        $clone | Should -Not -BeNullOrEmpty
        $clone.Count | Should -Be 5
        $clone[0] | Should -Be 1
        $clone[4] | Should -Be 5
    }

    It "Devrait cloner un dictionnaire simple" {
        # Arrange
        $original = @{
            "Key1" = "Value1"
            "Key2" = "Value2"
        }

        # Act
        $clone = Invoke-DeepClone -InputObject $original

        # Assert
        $clone | Should -Not -BeNullOrEmpty
        $clone.Count | Should -Be 2
        $clone["Key1"] | Should -Be "Value1"
        $clone["Key2"] | Should -Be "Value2"
    }
}

Describe "[P1] Tests basiques pour Invoke-PSObjectDeepClone" {
    It "Devrait cloner un objet PSObject simple" {
        # Arrange
        $original = [PSCustomObject]@{
            Name = "Test"
            Value = 42
        }

        # Act
        $clone = Invoke-PSObjectDeepClone -InputObject $original

        # Assert
        $clone | Should -Not -BeNullOrEmpty
        $clone.Name | Should -Be "Test"
        $clone.Value | Should -Be 42
    }

    It "Devrait créer une copie indépendante (deep clone) d'un PSObject" {
        # Arrange
        $original = [PSCustomObject]@{
            Name = "Test"
            Value = 42
        }

        # Act
        $clone = Invoke-PSObjectDeepClone -InputObject $original
        $clone.Name = "Modified"
        $clone.Value = 99

        # Assert
        $original.Name | Should -Be "Test"
        $original.Value | Should -Be 42
    }

    It "Devrait cloner un PSObject avec des propriétés imbriquées" {
        # Arrange
        $original = [PSCustomObject]@{
            Name = "Parent"
            Child = [PSCustomObject]@{
                Name = "Child"
                Value = 42
            }
        }

        # Act
        $clone = Invoke-PSObjectDeepClone -InputObject $original

        # Assert
        $clone | Should -Not -BeNullOrEmpty
        $clone.Name | Should -Be "Parent"
        $clone.Child.Name | Should -Be "Child"
        $clone.Child.Value | Should -Be 42
    }
}
