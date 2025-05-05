using namespace System.Collections.Generic

<#
.SYNOPSIS
    Interface pour les objets validables.
.DESCRIPTION
    DÃ©finit les mÃ©thodes requises pour qu'un objet puisse Ãªtre validÃ©
    selon diffÃ©rentes rÃ¨gles et contraintes.
.NOTES
    Auteur: EMAIL_SENDER_1 Team
    Version: 1.0
    Date de crÃ©ation: 2025-05-15
#>

# Interface pour les objets validables
class IValidatable {
    # MÃ©thode pour valider l'objet
    [bool] Validate() {
        throw "La mÃ©thode Validate doit Ãªtre implÃ©mentÃ©e par les classes dÃ©rivÃ©es"
    }

    # MÃ©thode pour valider l'objet avec des rÃ¨gles personnalisÃ©es
    [bool] ValidateWithRules([hashtable]$rules) {
        throw "La mÃ©thode ValidateWithRules doit Ãªtre implÃ©mentÃ©e par les classes dÃ©rivÃ©es"
    }

    # MÃ©thode pour obtenir les erreurs de validation
    [string[]] GetValidationErrors() {
        throw "La mÃ©thode GetValidationErrors doit Ãªtre implÃ©mentÃ©e par les classes dÃ©rivÃ©es"
    }

    # MÃ©thode pour vÃ©rifier si une propriÃ©tÃ© spÃ©cifique est valide
    [bool] IsPropertyValid([string]$propertyName) {
        throw "La mÃ©thode IsPropertyValid doit Ãªtre implÃ©mentÃ©e par les classes dÃ©rivÃ©es"
    }

    # MÃ©thode pour obtenir les erreurs de validation pour une propriÃ©tÃ© spÃ©cifique
    [string[]] GetPropertyValidationErrors([string]$propertyName) {
        throw "La mÃ©thode GetPropertyValidationErrors doit Ãªtre implÃ©mentÃ©e par les classes dÃ©rivÃ©es"
    }

    # MÃ©thode pour ajouter une rÃ¨gle de validation
    [void] AddValidationRule([string]$propertyName, [scriptblock]$rule, [string]$errorMessage) {
        throw "La mÃ©thode AddValidationRule doit Ãªtre implÃ©mentÃ©e par les classes dÃ©rivÃ©es"
    }

    # MÃ©thode pour supprimer une rÃ¨gle de validation
    [void] RemoveValidationRule([string]$propertyName, [int]$ruleIndex) {
        throw "La mÃ©thode RemoveValidationRule doit Ãªtre implÃ©mentÃ©e par les classes dÃ©rivÃ©es"
    }

    # MÃ©thode pour effacer toutes les rÃ¨gles de validation
    [void] ClearValidationRules() {
        throw "La mÃ©thode ClearValidationRules doit Ãªtre implÃ©mentÃ©e par les classes dÃ©rivÃ©es"
    }
}
