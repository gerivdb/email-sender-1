#Requires -Version 5.1
<#
.SYNOPSIS
    Exemple d'utilisation des helpers de test.
.DESCRIPTION
    Ce script montre comment utiliser les helpers de test pour vérifier différents types de contenu.
.EXAMPLE
    .\Example-TestHelpers.ps1
.NOTES
    Version: 1.0.0
    Auteur: Augment Agent
    Date de création: 2025-05-15
#>

# Importer les modules nécessaires
$testFrameworkPath = Join-Path -Path (Split-Path -Parent $PSScriptRoot) -ChildPath "modules\TestFramework\TestFramework.psm1"
$testHelpersPath = Join-Path -Path (Split-Path -Parent $PSScriptRoot) -ChildPath "modules\TestHelpers\TestHelpers.psm1"
Import-Module $testFrameworkPath -Force
Import-Module $testHelpersPath -Force

# Créer un environnement de test
$env = New-TestEnvironment -TestName "HelpersTest" -Files @{
    "test.txt"  = "Contenu de test"
    "test.json" = '{"name":"Test","value":123,"items":["Item1","Item2","Item3"]}'
    "test.xml"  = @"
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
    "test.csv"  = @"
Id,Name,Value
1,Item 1,Value 1
2,Item 2,Value 2
3,Item 3,Value 3
"@
}

# Tester le contenu d'un fichier texte
$textPath = Join-Path -Path $env.Path -ChildPath "test.txt"
$textResult = Test-FileContent -Path $textPath -ExpectedContent "Contenu de test"
Write-Host "Test du contenu du fichier texte : $textResult" -ForegroundColor $(if ($textResult) { "Green" } else { "Red" })

$textContainsResult = Test-FileContent -Path $textPath -ExpectedContent "Contenu" -Contains
Write-Host "Test du contenu partiel du fichier texte : $textContainsResult" -ForegroundColor $(if ($textContainsResult) { "Green" } else { "Red" })

# Tester le contenu d'un fichier JSON
$jsonPath = Join-Path -Path $env.Path -ChildPath "test.json"
$jsonResult = Test-JsonContent -Path $jsonPath -ExpectedStructure @{
    name  = "Test"
    value = 123
    items = @("Item1", "Item2", "Item3")
}
Write-Host "Test du contenu du fichier JSON : $jsonResult" -ForegroundColor $(if ($jsonResult) { "Green" } else { "Red" })

$jsonPartialResult = Test-JsonContent -Path $jsonPath -ExpectedStructure @{
    name  = "Test"
    value = 123
}
Write-Host "Test du contenu partiel du fichier JSON : $jsonPartialResult" -ForegroundColor $(if ($jsonPartialResult) { "Green" } else { "Red" })

# Tester le contenu d'un fichier XML
$xmlPath = Join-Path -Path $env.Path -ChildPath "test.xml"
$xmlResult = Test-XmlContent -Path $xmlPath -XPath "/root/item[@id='1']/name" -ExpectedValue "Item 1"
Write-Host "Test du contenu du fichier XML : $xmlResult" -ForegroundColor $(if ($xmlResult) { "Green" } else { "Red" })

$xmlCountResult = Test-XmlContent -Path $xmlPath -XPath "//item" -ExpectedCount 2
Write-Host "Test du nombre d'éléments dans le fichier XML : $xmlCountResult" -ForegroundColor $(if ($xmlCountResult) { "Green" } else { "Red" })

# Tester le contenu d'un fichier CSV
$csvPath = Join-Path -Path $env.Path -ChildPath "test.csv"
$csvHeadersResult = Test-CsvContent -Path $csvPath -ExpectedHeaders "Id", "Name", "Value"
Write-Host "Test des en-têtes du fichier CSV : $csvHeadersResult" -ForegroundColor $(if ($csvHeadersResult) { "Green" } else { "Red" })

$csvRowCountResult = Test-CsvContent -Path $csvPath -ExpectedRowCount 3
Write-Host "Test du nombre de lignes dans le fichier CSV : $csvRowCountResult" -ForegroundColor $(if ($csvRowCountResult) { "Green" } else { "Red" })

$csvValuesResult = Test-CsvContent -Path $csvPath -RowFilter { $_.Id -eq 1 } -ExpectedValues @{
    Name  = "Item 1"
    Value = "Value 1"
}
Write-Host "Test des valeurs dans le fichier CSV : $csvValuesResult" -ForegroundColor $(if ($csvValuesResult) { "Green" } else { "Red" })

# Mocker une API pour les tests
New-TestMock -CommandName "Invoke-WebRequest" -ParameterFilter { $Uri -eq "https://api.example.com/data" } -MockScript {
    return [PSCustomObject]@{
        StatusCode = 200
        Content    = '{"status":"ok","data":{"id":1,"name":"Test"}}'
    }
}

# Tester une réponse d'API
$apiResult = Test-ApiResponse -Uri "https://api.example.com/data" -Method GET -ExpectedStatusCode 200 -ContentType json -ExpectedContent @{
    status = "ok"
    data   = @{
        id   = 1
        name = "Test"
    }
}
Write-Host "Test de la réponse de l'API : $apiResult" -ForegroundColor $(if ($apiResult) { "Green" } else { "Red" })

# Mocker une requête de base de données pour les tests
New-TestMock -CommandName "System.Data.SqlClient.SqlConnection" -MockScript {
    return [PSCustomObject]@{
        ConnectionString = $null
        Open             = { }
        Close            = { }
        CreateCommand    = {
            return [PSCustomObject]@{
                CommandText = $null
                Parameters  = [PSCustomObject]@{
                    AddWithValue = { param($name, $value) }
                }
            }
        }
    }
}

New-TestMock -CommandName "System.Data.SqlClient.SqlDataAdapter" -MockScript {
    return [PSCustomObject]@{
        Fill = {
            param($dataset)
            $table = New-Object System.Data.DataTable
            $table.Columns.Add("Id", [int])
            $table.Columns.Add("Name", [string])
            $table.Columns.Add("Email", [string])

            $row = $table.NewRow()
            $row["Id"] = 1
            $row["Name"] = "Test"
            $row["Email"] = "test@example.com"
            $table.Rows.Add($row)

            $dataset.Tables.Add($table)
        }
    }
}

# Tester une requête de base de données
$dbResult = Test-DatabaseQuery -ConnectionString "Server=localhost;Database=test;Integrated Security=True" -Query "SELECT * FROM Users" -ExpectedRowCount 1 -ExpectedValues @{
    Name  = "Test"
    Email = "test@example.com"
}
Write-Host "Test de la requête de base de données : $dbResult" -ForegroundColor $(if ($dbResult) { "Green" } else { "Red" })

# Nettoyer l'environnement
$env.Cleanup()

Write-Host "Test terminé avec succès." -ForegroundColor Green
