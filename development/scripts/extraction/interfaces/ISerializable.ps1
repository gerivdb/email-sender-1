using namespace System.Collections.Generic

<#
.SYNOPSIS
    Interface pour les objets sÃ©rialisables.
.DESCRIPTION
    DÃ©finit les mÃ©thodes requises pour qu'un objet puisse Ãªtre sÃ©rialisÃ© et dÃ©sÃ©rialisÃ©
    dans diffÃ©rents formats.
.NOTES
    Auteur: EMAIL_SENDER_1 Team
    Version: 1.0
    Date de crÃ©ation: 2025-05-15
#>

# Interface pour les objets sÃ©rialisables
class ISerializable {
    # MÃ©thode pour sÃ©rialiser l'objet en JSON
    [string] ToJson([int]$depth = 10) {
        throw "La mÃ©thode ToJson doit Ãªtre implÃ©mentÃ©e par les classes dÃ©rivÃ©es"
    }

    # MÃ©thode pour sÃ©rialiser l'objet en XML
    [string] ToXml() {
        throw "La mÃ©thode ToXml doit Ãªtre implÃ©mentÃ©e par les classes dÃ©rivÃ©es"
    }

    # MÃ©thode pour sÃ©rialiser l'objet en CSV
    [string] ToCsv() {
        throw "La mÃ©thode ToCsv doit Ãªtre implÃ©mentÃ©e par les classes dÃ©rivÃ©es"
    }

    # MÃ©thode pour sÃ©rialiser l'objet en YAML
    [string] ToYaml() {
        throw "La mÃ©thode ToYaml doit Ãªtre implÃ©mentÃ©e par les classes dÃ©rivÃ©es"
    }

    # MÃ©thode pour sÃ©rialiser l'objet en format personnalisÃ©
    [string] ToCustomFormat([string]$format) {
        throw "La mÃ©thode ToCustomFormat doit Ãªtre implÃ©mentÃ©e par les classes dÃ©rivÃ©es"
    }

    # MÃ©thode pour dÃ©sÃ©rialiser l'objet depuis JSON
    [void] FromJson([string]$json) {
        throw "La mÃ©thode FromJson doit Ãªtre implÃ©mentÃ©e par les classes dÃ©rivÃ©es"
    }

    # MÃ©thode pour dÃ©sÃ©rialiser l'objet depuis XML
    [void] FromXml([string]$xml) {
        throw "La mÃ©thode FromXml doit Ãªtre implÃ©mentÃ©e par les classes dÃ©rivÃ©es"
    }

    # MÃ©thode pour dÃ©sÃ©rialiser l'objet depuis CSV
    [void] FromCsv([string]$csv) {
        throw "La mÃ©thode FromCsv doit Ãªtre implÃ©mentÃ©e par les classes dÃ©rivÃ©es"
    }

    # MÃ©thode pour dÃ©sÃ©rialiser l'objet depuis YAML
    [void] FromYaml([string]$yaml) {
        throw "La mÃ©thode FromYaml doit Ãªtre implÃ©mentÃ©e par les classes dÃ©rivÃ©es"
    }

    # MÃ©thode pour dÃ©sÃ©rialiser l'objet depuis un format personnalisÃ©
    [void] FromCustomFormat([string]$data, [string]$format) {
        throw "La mÃ©thode FromCustomFormat doit Ãªtre implÃ©mentÃ©e par les classes dÃ©rivÃ©es"
    }

    # MÃ©thode pour sauvegarder l'objet dans un fichier
    [void] SaveToFile([string]$filePath, [string]$format = "Json") {
        throw "La mÃ©thode SaveToFile doit Ãªtre implÃ©mentÃ©e par les classes dÃ©rivÃ©es"
    }

    # MÃ©thode pour charger l'objet depuis un fichier
    [void] LoadFromFile([string]$filePath, [string]$format = "Json") {
        throw "La mÃ©thode LoadFromFile doit Ãªtre implÃ©mentÃ©e par les classes dÃ©rivÃ©es"
    }
}
