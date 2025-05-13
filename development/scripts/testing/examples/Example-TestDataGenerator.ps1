#Requires -Version 5.1
<#
.SYNOPSIS
    Exemple d'utilisation des générateurs de données de test.
.DESCRIPTION
    Ce script montre comment utiliser les générateurs de données de test pour générer des données aléatoires.
.EXAMPLE
    .\Example-TestDataGenerator.ps1
.NOTES
    Version: 1.0.0
    Auteur: Augment Agent
    Date de création: 2025-05-15
#>

# Importer le module TestDataGenerator
$testDataGeneratorPath = Join-Path -Path (Split-Path -Parent $PSScriptRoot) -ChildPath "modules\TestDataGenerator\TestDataGenerator.psm1"
Import-Module $testDataGeneratorPath -Force

# Générer une chaîne aléatoire
$randomString = New-RandomString -Length 10
Write-Host "Chaîne aléatoire : $randomString" -ForegroundColor Cyan

# Générer une chaîne aléatoire avec un préfixe et un suffixe
$randomStringWithPrefixSuffix = New-RandomString -Length 8 -CharacterSet Alphabetic -Prefix "ID-" -Suffix "-2025"
Write-Host "Chaîne aléatoire avec préfixe et suffixe : $randomStringWithPrefixSuffix" -ForegroundColor Cyan

# Générer une chaîne aléatoire avec des caractères personnalisés
$randomStringWithCustomChars = New-RandomString -Length 5 -CustomCharacters "ABCDEF0123456789"
Write-Host "Chaîne aléatoire avec caractères personnalisés : $randomStringWithCustomChars" -ForegroundColor Cyan

# Générer une date aléatoire
$randomDate = New-RandomDate
Write-Host "Date aléatoire : $randomDate" -ForegroundColor Cyan

# Générer une date aléatoire dans une plage spécifique
$randomDateInRange = New-RandomDate -MinDate (Get-Date).AddYears(-5) -MaxDate (Get-Date).AddYears(1) -Format "dd/MM/yyyy" -AsString
Write-Host "Date aléatoire dans une plage spécifique : $randomDateInRange" -ForegroundColor Cyan

# Générer un nombre aléatoire
$randomNumber = New-RandomNumber -Min 1 -Max 100
Write-Host "Nombre aléatoire : $randomNumber" -ForegroundColor Cyan

# Générer un nombre décimal aléatoire
$randomDecimal = New-RandomNumber -Min 0 -Max 1 -Decimal -DecimalPlaces 4
Write-Host "Nombre décimal aléatoire : $randomDecimal" -ForegroundColor Cyan

# Générer une valeur booléenne aléatoire
$randomBoolean = New-RandomBoolean
Write-Host "Valeur booléenne aléatoire : $randomBoolean" -ForegroundColor Cyan

# Générer une valeur booléenne aléatoire avec une probabilité spécifique
$randomBooleanWithProbability = New-RandomBoolean -TrueProbability 0.8
Write-Host "Valeur booléenne aléatoire avec probabilité : $randomBooleanWithProbability" -ForegroundColor Cyan

# Générer un tableau aléatoire avec un générateur
$randomArrayWithGenerator = New-RandomArray -Count 5 -Generator { New-RandomString -Length 8 }
Write-Host "Tableau aléatoire avec générateur : $($randomArrayWithGenerator -join ', ')" -ForegroundColor Cyan

# Générer un tableau aléatoire à partir d'éléments existants
$randomArrayFromItems = New-RandomArray -Count 3 -Items @("Rouge", "Vert", "Bleu", "Jaune", "Noir") -AllowDuplicates:$false
Write-Host "Tableau aléatoire à partir d'éléments existants : $($randomArrayFromItems -join ', ')" -ForegroundColor Cyan

# Générer un objet aléatoire
$randomObject = New-RandomObject -Properties @{
    Id      = { New-RandomNumber -Min 1 -Max 1000 }
    Name    = { New-RandomString -Length 8 }
    Created = { New-RandomDate }
    Active  = { New-RandomBoolean }
}
Write-Host "Objet aléatoire :" -ForegroundColor Cyan
$randomObject | Format-List

# Générer plusieurs objets aléatoires
$randomObjects = New-RandomObject -Properties @{
    Id    = { New-RandomNumber -Min 1 -Max 1000 }
    Name  = { New-RandomString -Length 8 }
    Score = { New-RandomNumber -Min 0 -Max 100 -Decimal -DecimalPlaces 2 }
} -Count 3
Write-Host "Objets aléatoires :" -ForegroundColor Cyan
$randomObjects | Format-Table

# Générer un utilisateur aléatoire
$randomUser = New-RandomUsers
Write-Host "Utilisateur aléatoire :" -ForegroundColor Cyan
$randomUser | Format-List

# Générer plusieurs utilisateurs aléatoires avec des informations supplémentaires
$randomUsers = New-RandomUsers -Count 3 -IncludeAddress -IncludePhone -IncludeCompany -Locale "fr-FR"
Write-Host "Utilisateurs aléatoires avec informations supplémentaires :" -ForegroundColor Cyan
$randomUsers | ForEach-Object {
    Write-Host "- $($_.FirstName) $($_.LastName) ($($_.Email))" -ForegroundColor Yellow
    Write-Host "  Adresse : $($_.Address.Number) $($_.Address.Street), $($_.Address.ZipCode) $($_.Address.City), $($_.Address.Country)" -ForegroundColor Gray
    Write-Host "  Téléphone : Mobile: $($_.Phone.Mobile), Fixe: $($_.Phone.Home)" -ForegroundColor Gray
    Write-Host "  Entreprise : $($_.Company.Name) - $($_.Company.JobTitle) ($($_.Company.Department))" -ForegroundColor Gray
    Write-Host ""
}

# Générer des données pour un test de base de données
$users = New-RandomUsers -Count 5 -IncludeAddress
$orders = New-RandomObject -Properties @{
    OrderId     = { "ORD-" + (New-RandomString -Length 8 -CharacterSet Alphanumeric) }
    UserId      = { $users[(New-RandomNumber -Min 0 -Max 4)].Id }
    OrderDate   = { New-RandomDate -MinDate (Get-Date).AddMonths(-6) -MaxDate (Get-Date) }
    TotalAmount = { New-RandomNumber -Min 10 -Max 1000 -Decimal -DecimalPlaces 2 }
    Status      = { New-RandomArray -Count 1 -Items @("Pending", "Processing", "Shipped", "Delivered", "Cancelled") }
} -Count 10

Write-Host "Données de test pour une base de données :" -ForegroundColor Cyan
Write-Host "Utilisateurs :" -ForegroundColor Yellow
$users | Format-Table Id, FirstName, LastName, Email
Write-Host "Commandes :" -ForegroundColor Yellow
$orders | Format-Table OrderId, UserId, OrderDate, TotalAmount, Status

# Générer des données pour un test d'API
$apiResponse = New-RandomObject -Properties @{
    status = { "success" }
    code   = { 200 }
    data   = {
        New-RandomObject -Properties @{
            users  = { $users }
            orders = { $orders }
            stats  = {
                New-RandomObject -Properties @{
                    totalUsers         = { $users.Count }
                    totalOrders        = { $orders.Count }
                    averageOrderAmount = { [math]::Round(($orders | Measure-Object -Property TotalAmount -Average).Average, 2) }
                    lastUpdate         = { Get-Date -Format "yyyy-MM-dd HH:mm:ss" }
                }
            }
        }
    }
}

Write-Host "Données de test pour une API :" -ForegroundColor Cyan
$apiResponse | ConvertTo-Json -Depth 5

Write-Host "Test terminé avec succès." -ForegroundColor Green
