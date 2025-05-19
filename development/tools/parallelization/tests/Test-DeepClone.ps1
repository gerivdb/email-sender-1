# Importer le script à tester
$scriptPath = Join-Path -Path $PSScriptRoot -ChildPath "..\DeepCloneExtensions.ps1"
. $scriptPath

# Définir une classe sérialisable pour les tests
Add-Type -TypeDefinition @"
using System;
using System.Collections.Generic;

namespace UnifiedParallel.Tests
{
    [Serializable]
    public class TestPerson
    {
        public string Name { get; set; }
        public int Age { get; set; }
        public List<string> Hobbies { get; set; }
        public TestAddress Address { get; set; }

        public TestPerson()
        {
            Hobbies = new List<string>();
        }
    }

    [Serializable]
    public class TestAddress
    {
        public string Street { get; set; }
        public string City { get; set; }
        public string Country { get; set; }
    }

    // Classe non sérialisable pour tester les erreurs
    public class NonSerializableClass
    {
        public string Data { get; set; }
    }
}
"@

Write-Host "Test 1: Clonage d'un objet simple" -ForegroundColor Cyan
$original = [PSCustomObject]@{
    Name = "Test"
    Value = 42
}

$clone = Invoke-DeepClone -InputObject $original
Write-Host "Original: $($original | ConvertTo-Json)"
Write-Host "Clone: $($clone | ConvertTo-Json)"

# Modifier le clone
$clone.Name = "Modified"
Write-Host "Après modification du clone:"
Write-Host "Original: $($original | ConvertTo-Json)"
Write-Host "Clone: $($clone | ConvertTo-Json)"

Write-Host "`nTest 2: Clonage d'un objet complexe" -ForegroundColor Cyan
$person = New-Object UnifiedParallel.Tests.TestPerson
$person.Name = "John Doe"
$person.Age = 30
$person.Hobbies.Add("Reading")
$person.Hobbies.Add("Hiking")

$address = New-Object UnifiedParallel.Tests.TestAddress
$address.Street = "123 Main St"
$address.City = "Anytown"
$address.Country = "USA"

$person.Address = $address

$clone = Invoke-DeepClone -InputObject $person
Write-Host "Original: Name=$($person.Name), Age=$($person.Age), Hobbies=$($person.Hobbies.Count), Address=$($person.Address.Street)"
Write-Host "Clone: Name=$($clone.Name), Age=$($clone.Age), Hobbies=$($clone.Hobbies.Count), Address=$($clone.Address.Street)"

# Modifier le clone
$clone.Name = "Jane Doe"
$clone.Address.Street = "456 Oak Ave"
$clone.Hobbies.Add("Swimming")

Write-Host "Après modification du clone:"
Write-Host "Original: Name=$($person.Name), Age=$($person.Age), Hobbies=$($person.Hobbies.Count), Address=$($person.Address.Street)"
Write-Host "Clone: Name=$($clone.Name), Age=$($clone.Age), Hobbies=$($clone.Hobbies.Count), Address=$($clone.Address.Street)"

Write-Host "`nTest 3: Gestion des erreurs" -ForegroundColor Cyan
try {
    $nonSerializable = New-Object UnifiedParallel.Tests.NonSerializableClass
    $nonSerializable.Data = "Test"
    $clone = Invoke-DeepClone -InputObject $nonSerializable
    Write-Host "Erreur: Le test aurait dû échouer pour un type non sérialisable" -ForegroundColor Red
}
catch {
    Write-Host "Exception correctement levée pour un type non sérialisable: $_" -ForegroundColor Green
}

Write-Host "`nTest 4: Compatibilité avec le pipeline" -ForegroundColor Cyan
$original = [PSCustomObject]@{
    Name = "Test"
    Value = 42
}

$clone = $original | Invoke-DeepClone
Write-Host "Original: $($original | ConvertTo-Json)"
Write-Host "Clone: $($clone | ConvertTo-Json)"

# Modifier le clone
$clone.Name = "Modified"
Write-Host "Après modification du clone:"
Write-Host "Original: $($original | ConvertTo-Json)"
Write-Host "Clone: $($clone | ConvertTo-Json)"

Write-Host "`nTous les tests sont terminés." -ForegroundColor Green
