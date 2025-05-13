#Requires -Version 5.1
<#
.SYNOPSIS
    Crée des données de test.
.DESCRIPTION
    Crée des données de test pour les tests unitaires, avec différents types de données.
.PARAMETER Type
    Type de données à générer (String, Number, DateTime, Boolean, Array, Object, Json, Xml, Csv).
.PARAMETER Count
    Nombre d'éléments à générer pour les types Array.
.PARAMETER Properties
    Propriétés à inclure pour les types Object.
.PARAMETER Min
    Valeur minimale pour les types Number.
.PARAMETER Max
    Valeur maximale pour les types Number.
.PARAMETER Length
    Longueur pour les types String.
.PARAMETER Format
    Format pour les types DateTime.
.PARAMETER CustomGenerator
    Fonction personnalisée pour générer des données.
.EXAMPLE
    New-TestData -Type String -Length 10
.EXAMPLE
    New-TestData -Type Number -Min 1 -Max 100
.EXAMPLE
    New-TestData -Type Array -Count 5 -CustomGenerator { param($i) "Item$i" }
.NOTES
    Cette fonction est utile pour générer des données de test pour les tests unitaires.
#>
function New-TestData {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet("String", "Number", "DateTime", "Boolean", "Array", "Object", "Json", "Xml", "Csv")]
        [string]$Type,

        [Parameter(Mandatory = $false)]
        [int]$Count = 1,

        [Parameter(Mandatory = $false)]
        [hashtable]$Properties,

        [Parameter(Mandatory = $false)]
        [int]$Min = 0,

        [Parameter(Mandatory = $false)]
        [int]$Max = 100,

        [Parameter(Mandatory = $false)]
        [int]$Length = 10,

        [Parameter(Mandatory = $false)]
        [string]$Format = "yyyy-MM-dd",

        [Parameter(Mandatory = $false)]
        [scriptblock]$CustomGenerator
    )

    switch ($Type) {
        "String" {
            if ($CustomGenerator) {
                return & $CustomGenerator
            }
            else {
                $chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789"
                $result = ""
                $random = New-Object System.Random
                for ($i = 0; $i -lt $Length; $i++) {
                    $result += $chars[$random.Next(0, $chars.Length)]
                }
                return $result
            }
        }
        "Number" {
            if ($CustomGenerator) {
                return & $CustomGenerator
            }
            else {
                $random = New-Object System.Random
                return $random.Next($Min, $Max + 1)
            }
        }
        "DateTime" {
            if ($CustomGenerator) {
                return & $CustomGenerator
            }
            else {
                $random = New-Object System.Random
                $days = $random.Next(0, 365)
                $date = (Get-Date).AddDays(-$days)
                if ($Format) {
                    return $date.ToString($Format)
                }
                else {
                    return $date
                }
            }
        }
        "Boolean" {
            if ($CustomGenerator) {
                return & $CustomGenerator
            }
            else {
                $random = New-Object System.Random
                return $random.Next(0, 2) -eq 1
            }
        }
        "Array" {
            $result = @()
            for ($i = 0; $i -lt $Count; $i++) {
                if ($CustomGenerator) {
                    $result += & $CustomGenerator $i
                }
                else {
                    $result += "Item$i"
                }
            }
            return $result
        }
        "Object" {
            if ($CustomGenerator) {
                return & $CustomGenerator
            }
            else {
                if (-not $Properties) {
                    $Properties = @{
                        Id = { New-TestData -Type Number -Min 1 -Max 1000 }
                        Name = { New-TestData -Type String -Length 8 }
                        Created = { New-TestData -Type DateTime }
                        Active = { New-TestData -Type Boolean }
                    }
                }

                $result = [PSCustomObject]@{}
                foreach ($key in $Properties.Keys) {
                    $valueGenerator = $Properties[$key]
                    $value = & $valueGenerator
                    $result | Add-Member -MemberType NoteProperty -Name $key -Value $value
                }
                return $result
            }
        }
        "Json" {
            if ($CustomGenerator) {
                $data = & $CustomGenerator
            }
            else {
                $data = New-TestData -Type Object -Properties $Properties
            }
            return $data | ConvertTo-Json -Depth 10
        }
        "Xml" {
            if ($CustomGenerator) {
                return & $CustomGenerator
            }
            else {
                $xmlTemplate = @"
<?xml version="1.0" encoding="UTF-8"?>
<root>
    <item id="1">
        <name>Item 1</name>
        <value>Value 1</value>
    </item>
    <item id="2">
        <name>Item 2</name>
        <value>Value 2</value>
    </item>
</root>
"@
                return $xmlTemplate
            }
        }
        "Csv" {
            if ($CustomGenerator) {
                return & $CustomGenerator
            }
            else {
                $csvTemplate = @"
Id,Name,Value
1,Item 1,Value 1
2,Item 2,Value 2
3,Item 3,Value 3
"@
                return $csvTemplate
            }
        }
    }
}
