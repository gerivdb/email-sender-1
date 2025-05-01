#Requires -Version 5.1
<#
.SYNOPSIS
    Script de test gÃ©nÃ©rÃ© automatiquement (Small).
.DESCRIPTION
    Ce script a Ã©tÃ© gÃ©nÃ©rÃ© pour tester les performances des fonctions d'extraction AST.
    Taille: Small
    Fonctions: 5
    ParamÃ¨tres par fonction: 3
    Commandes par fonction: 10
    Variables par fonction: 5
    Profondeur d'imbrication: 2
.NOTES
    GÃ©nÃ©rÃ© le: 2025-05-01 18:33:02
#>

# Variables globales
$global:Variable1 = '1'
$global:Variable2 = '2'
$global:Variable3 = '3'
$global:Variable4 = '4'
$global:Variable5 = '5'

function Test-Function1 {
    [CmdletBinding()]
    param(        [Parameter(Mandatory = $true)]
        [int]$Parameter1,        [Parameter(Mandatory = $true)]
        [bool]$Parameter2,        [Parameter(Mandatory = $false)]
        [array]$Parameter3    )

    begin {
        Write-Verbose "DÃ©but de la fonction Test-Function1"        $local1 = $Parameter1 + '1'
        $local2 = $Parameter1 + '2'
        $local3 = $Parameter1 + '3'
        $local4 = $Parameter1 + '4'
        $local5 = $Parameter1 + '5'
    }

    process {
        # Traitement principal        if ($Parameter1 -eq 'Test1') {
            Write-Verbose "Condition 1 vraie"
        } else {
            Write-Verbose "Condition 1 fausse"
        }        foreach ($item in @(1, 2, 3)) {
            Write-Verbose "Traitement de l'Ã©lÃ©ment $item dans la boucle 2"
        }        try {
            Write-Verbose "Tentative d'opÃ©ration 3"
        } catch {
            Write-Error "Erreur dans l'opÃ©ration 3 : $_"
        }        if ($Parameter1 -eq 'Niveau1') {
        if ($Parameter1 -eq 'Niveau2') {
            Write-Verbose "Niveau le plus profond atteint"
        }        }        Write-Verbose "ExÃ©cution de la commande 5"
        if ($Parameter1 -eq 'Test6') {
            Write-Verbose "Condition 6 vraie"
        } else {
            Write-Verbose "Condition 6 fausse"
        }        foreach ($item in @(1, 2, 3)) {
            Write-Verbose "Traitement de l'Ã©lÃ©ment $item dans la boucle 7"
        }        try {
            Write-Verbose "Tentative d'opÃ©ration 8"
        } catch {
            Write-Error "Erreur dans l'opÃ©ration 8 : $_"
        }        if ($Parameter1 -eq 'Niveau1') {
        if ($Parameter1 -eq 'Niveau2') {
            Write-Verbose "Niveau le plus profond atteint"
        }        }        Write-Verbose "ExÃ©cution de la commande 10"
    }

    end {
        Write-Verbose "Fin de la fonction Test-Function1"
        return $Parameter1
    }
}
function Test-Function2 {
    [CmdletBinding()]
    param(        [Parameter(Mandatory = $true)]
        [int]$Parameter1,        [Parameter(Mandatory = $true)]
        [bool]$Parameter2,        [Parameter(Mandatory = $false)]
        [array]$Parameter3    )

    begin {
        Write-Verbose "DÃ©but de la fonction Test-Function2"        $local1 = $Parameter1 + '1'
        $local2 = $Parameter1 + '2'
        $local3 = $Parameter1 + '3'
        $local4 = $Parameter1 + '4'
        $local5 = $Parameter1 + '5'
    }

    process {
        # Traitement principal        if ($Parameter1 -eq 'Test1') {
            Write-Verbose "Condition 1 vraie"
        } else {
            Write-Verbose "Condition 1 fausse"
        }        foreach ($item in @(1, 2, 3)) {
            Write-Verbose "Traitement de l'Ã©lÃ©ment $item dans la boucle 2"
        }        try {
            Write-Verbose "Tentative d'opÃ©ration 3"
        } catch {
            Write-Error "Erreur dans l'opÃ©ration 3 : $_"
        }        if ($Parameter1 -eq 'Niveau1') {
        if ($Parameter1 -eq 'Niveau2') {
            Write-Verbose "Niveau le plus profond atteint"
        }        }        Write-Verbose "ExÃ©cution de la commande 5"
        if ($Parameter1 -eq 'Test6') {
            Write-Verbose "Condition 6 vraie"
        } else {
            Write-Verbose "Condition 6 fausse"
        }        foreach ($item in @(1, 2, 3)) {
            Write-Verbose "Traitement de l'Ã©lÃ©ment $item dans la boucle 7"
        }        try {
            Write-Verbose "Tentative d'opÃ©ration 8"
        } catch {
            Write-Error "Erreur dans l'opÃ©ration 8 : $_"
        }        if ($Parameter1 -eq 'Niveau1') {
        if ($Parameter1 -eq 'Niveau2') {
            Write-Verbose "Niveau le plus profond atteint"
        }        }        Write-Verbose "ExÃ©cution de la commande 10"
    }

    end {
        Write-Verbose "Fin de la fonction Test-Function2"
        return $Parameter1
    }
}
function Test-Function3 {
    [CmdletBinding()]
    param(        [Parameter(Mandatory = $true)]
        [int]$Parameter1,        [Parameter(Mandatory = $true)]
        [bool]$Parameter2,        [Parameter(Mandatory = $false)]
        [array]$Parameter3    )

    begin {
        Write-Verbose "DÃ©but de la fonction Test-Function3"        $local1 = $Parameter1 + '1'
        $local2 = $Parameter1 + '2'
        $local3 = $Parameter1 + '3'
        $local4 = $Parameter1 + '4'
        $local5 = $Parameter1 + '5'
    }

    process {
        # Traitement principal        if ($Parameter1 -eq 'Test1') {
            Write-Verbose "Condition 1 vraie"
        } else {
            Write-Verbose "Condition 1 fausse"
        }        foreach ($item in @(1, 2, 3)) {
            Write-Verbose "Traitement de l'Ã©lÃ©ment $item dans la boucle 2"
        }        try {
            Write-Verbose "Tentative d'opÃ©ration 3"
        } catch {
            Write-Error "Erreur dans l'opÃ©ration 3 : $_"
        }        if ($Parameter1 -eq 'Niveau1') {
        if ($Parameter1 -eq 'Niveau2') {
            Write-Verbose "Niveau le plus profond atteint"
        }        }        Write-Verbose "ExÃ©cution de la commande 5"
        if ($Parameter1 -eq 'Test6') {
            Write-Verbose "Condition 6 vraie"
        } else {
            Write-Verbose "Condition 6 fausse"
        }        foreach ($item in @(1, 2, 3)) {
            Write-Verbose "Traitement de l'Ã©lÃ©ment $item dans la boucle 7"
        }        try {
            Write-Verbose "Tentative d'opÃ©ration 8"
        } catch {
            Write-Error "Erreur dans l'opÃ©ration 8 : $_"
        }        if ($Parameter1 -eq 'Niveau1') {
        if ($Parameter1 -eq 'Niveau2') {
            Write-Verbose "Niveau le plus profond atteint"
        }        }        Write-Verbose "ExÃ©cution de la commande 10"
    }

    end {
        Write-Verbose "Fin de la fonction Test-Function3"
        return $Parameter1
    }
}
function Test-Function4 {
    [CmdletBinding()]
    param(        [Parameter(Mandatory = $true)]
        [int]$Parameter1,        [Parameter(Mandatory = $true)]
        [bool]$Parameter2,        [Parameter(Mandatory = $false)]
        [array]$Parameter3    )

    begin {
        Write-Verbose "DÃ©but de la fonction Test-Function4"        $local1 = $Parameter1 + '1'
        $local2 = $Parameter1 + '2'
        $local3 = $Parameter1 + '3'
        $local4 = $Parameter1 + '4'
        $local5 = $Parameter1 + '5'
    }

    process {
        # Traitement principal        if ($Parameter1 -eq 'Test1') {
            Write-Verbose "Condition 1 vraie"
        } else {
            Write-Verbose "Condition 1 fausse"
        }        foreach ($item in @(1, 2, 3)) {
            Write-Verbose "Traitement de l'Ã©lÃ©ment $item dans la boucle 2"
        }        try {
            Write-Verbose "Tentative d'opÃ©ration 3"
        } catch {
            Write-Error "Erreur dans l'opÃ©ration 3 : $_"
        }        if ($Parameter1 -eq 'Niveau1') {
        if ($Parameter1 -eq 'Niveau2') {
            Write-Verbose "Niveau le plus profond atteint"
        }        }        Write-Verbose "ExÃ©cution de la commande 5"
        if ($Parameter1 -eq 'Test6') {
            Write-Verbose "Condition 6 vraie"
        } else {
            Write-Verbose "Condition 6 fausse"
        }        foreach ($item in @(1, 2, 3)) {
            Write-Verbose "Traitement de l'Ã©lÃ©ment $item dans la boucle 7"
        }        try {
            Write-Verbose "Tentative d'opÃ©ration 8"
        } catch {
            Write-Error "Erreur dans l'opÃ©ration 8 : $_"
        }        if ($Parameter1 -eq 'Niveau1') {
        if ($Parameter1 -eq 'Niveau2') {
            Write-Verbose "Niveau le plus profond atteint"
        }        }        Write-Verbose "ExÃ©cution de la commande 10"
    }

    end {
        Write-Verbose "Fin de la fonction Test-Function4"
        return $Parameter1
    }
}
function Test-Function5 {
    [CmdletBinding()]
    param(        [Parameter(Mandatory = $true)]
        [int]$Parameter1,        [Parameter(Mandatory = $true)]
        [bool]$Parameter2,        [Parameter(Mandatory = $false)]
        [array]$Parameter3    )

    begin {
        Write-Verbose "DÃ©but de la fonction Test-Function5"        $local1 = $Parameter1 + '1'
        $local2 = $Parameter1 + '2'
        $local3 = $Parameter1 + '3'
        $local4 = $Parameter1 + '4'
        $local5 = $Parameter1 + '5'
    }

    process {
        # Traitement principal        if ($Parameter1 -eq 'Test1') {
            Write-Verbose "Condition 1 vraie"
        } else {
            Write-Verbose "Condition 1 fausse"
        }        foreach ($item in @(1, 2, 3)) {
            Write-Verbose "Traitement de l'Ã©lÃ©ment $item dans la boucle 2"
        }        try {
            Write-Verbose "Tentative d'opÃ©ration 3"
        } catch {
            Write-Error "Erreur dans l'opÃ©ration 3 : $_"
        }        if ($Parameter1 -eq 'Niveau1') {
        if ($Parameter1 -eq 'Niveau2') {
            Write-Verbose "Niveau le plus profond atteint"
        }        }        Write-Verbose "ExÃ©cution de la commande 5"
        if ($Parameter1 -eq 'Test6') {
            Write-Verbose "Condition 6 vraie"
        } else {
            Write-Verbose "Condition 6 fausse"
        }        foreach ($item in @(1, 2, 3)) {
            Write-Verbose "Traitement de l'Ã©lÃ©ment $item dans la boucle 7"
        }        try {
            Write-Verbose "Tentative d'opÃ©ration 8"
        } catch {
            Write-Error "Erreur dans l'opÃ©ration 8 : $_"
        }        if ($Parameter1 -eq 'Niveau1') {
        if ($Parameter1 -eq 'Niveau2') {
            Write-Verbose "Niveau le plus profond atteint"
        }        }        Write-Verbose "ExÃ©cution de la commande 10"
    }

    end {
        Write-Verbose "Fin de la fonction Test-Function5"
        return $Parameter1
    }
}
# Appels de fonctions
Test-Function1 -Parameter1 'TestValue1' -Parameter2 1
Test-Function2 -Parameter1 'TestValue2' -Parameter2 2
Test-Function3 -Parameter1 'TestValue3' -Parameter2 3
Test-Function4 -Parameter1 'TestValue4' -Parameter2 4
Test-Function5 -Parameter1 'TestValue5' -Parameter2 5

