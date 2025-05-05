<#
.SYNOPSIS
    Module d'export de rapports au format PDF.
.DESCRIPTION
    Ce module fournit des fonctions pour exporter des rapports au format PDF
    en utilisant la bibliothÃƒÂ¨que DinkToPdf via HTML.
.NOTES
    Version: 1.0
    Auteur: Augment Agent
    Date de crÃƒÂ©ation: 2025-04-23
#>

# Importer le module d'export HTML
$HtmlExporterPath = Join-Path -Path $PSScriptRoot -ChildPath "html_exporter.ps1"
if (Test-Path -Path $HtmlExporterPath) {
    . $HtmlExporterPath
}
else {
    Write-Error "Module d'export HTML non trouvÃƒÂ©: $HtmlExporterPath"
    exit 1
}

# DÃƒÂ©finition des chemins par dÃƒÂ©faut
$script:DefaultWkhtmltopdfPath = "C:\Program Files\wkhtmltopdf\bin\wkhtmltopdf.exe"
$script:DefaultPdfOptionsPath = Join-Path -Path $PSScriptRoot -ChildPath "..\..\projet\config\reporting\pdf_options.json"

<#
.SYNOPSIS
    VÃƒÂ©rifie si wkhtmltopdf est installÃƒÂ©.
.DESCRIPTION
    Cette fonction vÃƒÂ©rifie si wkhtmltopdf est installÃƒÂ© et disponible
    pour la gÃƒÂ©nÃƒÂ©ration de PDF.
.PARAMETER WkhtmltopdfPath
    Chemin vers l'exÃƒÂ©cutable wkhtmltopdf.
.EXAMPLE
    $IsInstalled = Test-WkhtmltopdfInstallation
.OUTPUTS
    System.Boolean - True si wkhtmltopdf est installÃƒÂ©, False sinon.
#>
function Test-WkhtmltopdfInstallation {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$false)]
        [string]$WkhtmltopdfPath = $script:DefaultWkhtmltopdfPath
    )
    
    try {
        # VÃƒÂ©rifier si l'exÃƒÂ©cutable existe
        if (Test-Path -Path $WkhtmltopdfPath) {
            # VÃƒÂ©rifier si l'exÃƒÂ©cutable fonctionne
            $Version = & $WkhtmltopdfPath --version 2>&1
            
            if ($LASTEXITCODE -eq 0) {
                Write-Verbose "wkhtmltopdf est installÃƒÂ©: $Version"
                return $true
            }
            else {
                Write-Error "wkhtmltopdf existe mais ne fonctionne pas correctement: $Version"
                return $false
            }
        }
        else {
            Write-Error "wkhtmltopdf n'est pas installÃƒÂ©: $WkhtmltopdfPath"
            return $false
        }
    }
    catch {
        Write-Error "Erreur lors de la vÃƒÂ©rification de l'installation de wkhtmltopdf: $_"
        return $false
    }
}

<#
.SYNOPSIS
    Installe wkhtmltopdf si nÃƒÂ©cessaire.
.DESCRIPTION
    Cette fonction tÃƒÂ©lÃƒÂ©charge et installe wkhtmltopdf si nÃƒÂ©cessaire.
.PARAMETER InstallPath
    Chemin d'installation de wkhtmltopdf.
.EXAMPLE
    $Result = Install-Wkhtmltopdf
.OUTPUTS
    System.Boolean - True si l'installation a rÃƒÂ©ussi, False sinon.
#>
function Install-Wkhtmltopdf {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$false)]
        [string]$InstallPath = "C:\Program Files\wkhtmltopdf"
    )
    
    try {
        # VÃƒÂ©rifier si wkhtmltopdf est dÃƒÂ©jÃƒÂ  installÃƒÂ©
        if (Test-WkhtmltopdfInstallation) {
            Write-Verbose "wkhtmltopdf est dÃƒÂ©jÃƒÂ  installÃƒÂ©"
            return $true
        }
        
        # CrÃƒÂ©er un rÃƒÂ©pertoire temporaire
        $TempDir = [System.IO.Path]::GetTempPath() + [System.Guid]::NewGuid().ToString()
        New-Item -Path $TempDir -ItemType Directory -Force | Out-Null
        
        # URL de tÃƒÂ©lÃƒÂ©chargement
        $DownloadUrl = "https://github.com/wkhtmltopdf/packaging/releases/download/0.12.6-1/wkhtmltox-0.12.6-1.msvc2015-win64.exe"
        $InstallerPath = Join-Path -Path $TempDir -ChildPath "wkhtmltopdf-installer.exe"
        
        # TÃƒÂ©lÃƒÂ©charger l'installateur
        Write-Verbose "TÃƒÂ©lÃƒÂ©chargement de wkhtmltopdf depuis $DownloadUrl"
        Invoke-WebRequest -Uri $DownloadUrl -OutFile $InstallerPath
        
        # Installer wkhtmltopdf
        Write-Verbose "Installation de wkhtmltopdf"
        Start-Process -FilePath $InstallerPath -ArgumentList "/S", "/D=$InstallPath" -Wait
        
        # VÃƒÂ©rifier si l'installation a rÃƒÂ©ussi
        if (Test-WkhtmltopdfInstallation) {
            Write-Verbose "wkhtmltopdf a ÃƒÂ©tÃƒÂ© installÃƒÂ© avec succÃƒÂ¨s"
            return $true
        }
        else {
            Write-Error "L'installation de wkhtmltopdf a ÃƒÂ©chouÃƒÂ©"
            return $false
        }
    }
    catch {
        Write-Error "Erreur lors de l'installation de wkhtmltopdf: $_"
        return $false
    }
    finally {
        # Nettoyer le rÃƒÂ©pertoire temporaire
        if (Test-Path -Path $TempDir) {
            Remove-Item -Path $TempDir -Recurse -Force
        }
    }
}

<#
.SYNOPSIS
    Charge les options PDF depuis un fichier JSON.
.DESCRIPTION
    Cette fonction charge les options PDF depuis un fichier JSON
    pour la gÃƒÂ©nÃƒÂ©ration de PDF.
.PARAMETER OptionsPath
    Chemin vers le fichier JSON contenant les options PDF.
.EXAMPLE
    $Options = Get-PdfOptions -OptionsPath "projet/config/reporting/pdf_options.json"
.OUTPUTS
    System.Object - Les options PDF chargÃƒÂ©es.
#>
function Get-PdfOptions {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$false)]
        [string]$OptionsPath = $script:DefaultPdfOptionsPath
    )
    
    try {
        # VÃƒÂ©rifier si le fichier existe
        if (Test-Path -Path $OptionsPath) {
            # Charger le fichier JSON
            $OptionsJson = Get-Content -Path $OptionsPath -Raw -Encoding UTF8
            $Options = ConvertFrom-Json -InputObject $OptionsJson -ErrorAction Stop
            
            Write-Verbose "Options PDF chargÃƒÂ©es avec succÃƒÂ¨s"
            return $Options
        }
        else {
            # Utiliser des options par dÃƒÂ©faut
            Write-Verbose "Fichier d'options PDF non trouvÃƒÂ©, utilisation des options par dÃƒÂ©faut"
            
            $DefaultOptions = @{
                global = @{
                    margin_top = "20mm"
                    margin_bottom = "20mm"
                    margin_left = "20mm"
                    margin_right = "20mm"
                    page_size = "A4"
                    orientation = "Portrait"
                    dpi = 300
                    image_quality = 100
                    enable_javascript = $true
                    javascript_delay = 1000
                }
                toc = @{
                    enable = $true
                    header_text = "Table des matiÃƒÂ¨res"
                    level_indentation = 10
                    disable_dotted_lines = $false
                    disable_links = $false
                }
                outline = @{
                    enable = $true
                    depth = 3
                }
                header = @{
                    enable = $true
                    html = "<div style='text-align: right; font-size: 10px; color: #777;'>Page [page] sur [topage]</div>"
                    spacing = "5mm"
                }
                footer = @{
                    enable = $true
                    html = "<div style='text-align: center; font-size: 10px; color: #777;'>Rapport gÃƒÂ©nÃƒÂ©rÃƒÂ© le [date] ÃƒÂ  [time]</div>"
                    spacing = "5mm"
                }
            }
            
            return $DefaultOptions
        }
    }
    catch {
        Write-Error "Erreur lors du chargement des options PDF: $_"
        
        # Utiliser des options par dÃƒÂ©faut en cas d'erreur
        $DefaultOptions = @{
            global = @{
                margin_top = "20mm"
                margin_bottom = "20mm"
                margin_left = "20mm"
                margin_right = "20mm"
                page_size = "A4"
                orientation = "Portrait"
            }
        }
        
        return $DefaultOptions
    }
}

<#
.SYNOPSIS
    Convertit les options PDF en arguments pour wkhtmltopdf.
.DESCRIPTION
    Cette fonction convertit les options PDF en arguments
    pour la ligne de commande wkhtmltopdf.
.PARAMETER Options
    Options PDF ÃƒÂ  convertir.
.EXAMPLE
    $Args = ConvertTo-WkhtmltopdfArguments -Options $Options
.OUTPUTS
    System.String[] - Les arguments pour wkhtmltopdf.
#>
function ConvertTo-WkhtmltopdfArguments {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [object]$Options
    )
    
    try {
        $Arguments = @()
        
        # Options globales
        if ($Options.PSObject.Properties.Name -contains "global") {
            $Global = $Options.global
            
            if ($Global.PSObject.Properties.Name -contains "margin_top") {
                $Arguments += "--margin-top"
                $Arguments += $Global.margin_top
            }
            
            if ($Global.PSObject.Properties.Name -contains "margin_bottom") {
                $Arguments += "--margin-bottom"
                $Arguments += $Global.margin_bottom
            }
            
            if ($Global.PSObject.Properties.Name -contains "margin_left") {
                $Arguments += "--margin-left"
                $Arguments += $Global.margin_left
            }
            
            if ($Global.PSObject.Properties.Name -contains "margin_right") {
                $Arguments += "--margin-right"
                $Arguments += $Global.margin_right
            }
            
            if ($Global.PSObject.Properties.Name -contains "page_size") {
                $Arguments += "--page-size"
                $Arguments += $Global.page_size
            }
            
            if ($Global.PSObject.Properties.Name -contains "orientation") {
                $Arguments += "--orientation"
                $Arguments += $Global.orientation
            }
            
            if ($Global.PSObject.Properties.Name -contains "dpi") {
                $Arguments += "--dpi"
                $Arguments += $Global.dpi
            }
            
            if ($Global.PSObject.Properties.Name -contains "image_quality") {
                $Arguments += "--image-quality"
                $Arguments += $Global.image_quality
            }
            
            if ($Global.PSObject.Properties.Name -contains "enable_javascript" -and $Global.enable_javascript) {
                $Arguments += "--enable-javascript"
            }
            
            if ($Global.PSObject.Properties.Name -contains "javascript_delay") {
                $Arguments += "--javascript-delay"
                $Arguments += $Global.javascript_delay
            }
        }
        
        # Options de table des matiÃƒÂ¨res
        if ($Options.PSObject.Properties.Name -contains "toc" -and $Options.toc.enable) {
            $Arguments += "toc"
            
            if ($Options.toc.PSObject.Properties.Name -contains "header_text") {
                $Arguments += "--toc-header-text"
                $Arguments += "`"$($Options.toc.header_text)`""
            }
            
            if ($Options.toc.PSObject.Properties.Name -contains "level_indentation") {
                $Arguments += "--toc-level-indentation"
                $Arguments += $Options.toc.level_indentation
            }
            
            if ($Options.toc.PSObject.Properties.Name -contains "disable_dotted_lines" -and $Options.toc.disable_dotted_lines) {
                $Arguments += "--toc-no-dots"
            }
            
            if ($Options.toc.PSObject.Properties.Name -contains "disable_links" -and $Options.toc.disable_links) {
                $Arguments += "--toc-disable-links"
            }
        }
        
        # Options d'outline
        if ($Options.PSObject.Properties.Name -contains "outline" -and $Options.outline.enable) {
            $Arguments += "--outline"
            
            if ($Options.outline.PSObject.Properties.Name -contains "depth") {
                $Arguments += "--outline-depth"
                $Arguments += $Options.outline.depth
            }
        }
        
        # Options d'en-tÃƒÂªte
        if ($Options.PSObject.Properties.Name -contains "header" -and $Options.header.enable) {
            if ($Options.header.PSObject.Properties.Name -contains "html") {
                $HeaderHtmlPath = [System.IO.Path]::GetTempFileName() + ".html"
                $Options.header.html | Out-File -FilePath $HeaderHtmlPath -Encoding UTF8
                
                $Arguments += "--header-html"
                $Arguments += $HeaderHtmlPath
            }
            
            if ($Options.header.PSObject.Properties.Name -contains "spacing") {
                $Arguments += "--header-spacing"
                $Arguments += $Options.header.spacing
            }
        }
        
        # Options de pied de page
        if ($Options.PSObject.Properties.Name -contains "footer" -and $Options.footer.enable) {
            if ($Options.footer.PSObject.Properties.Name -contains "html") {
                $FooterHtmlPath = [System.IO.Path]::GetTempFileName() + ".html"
                $Options.footer.html | Out-File -FilePath $FooterHtmlPath -Encoding UTF8
                
                $Arguments += "--footer-html"
                $Arguments += $FooterHtmlPath
            }
            
            if ($Options.footer.PSObject.Properties.Name -contains "spacing") {
                $Arguments += "--footer-spacing"
                $Arguments += $Options.footer.spacing
            }
        }
        
        return $Arguments
    }
    catch {
        Write-Error "Erreur lors de la conversion des options PDF: $_"
        return @()
    }
}

<#
.SYNOPSIS
    Exporte un rapport au format PDF.
.DESCRIPTION
    Cette fonction exporte un rapport au format PDF
    en utilisant wkhtmltopdf.
.PARAMETER ReportData
    DonnÃƒÂ©es du rapport ÃƒÂ  exporter.
.PARAMETER OutputPath
    Chemin oÃƒÂ¹ le fichier PDF sera sauvegardÃƒÂ©.
.PARAMETER OptionsPath
    Chemin vers le fichier JSON contenant les options PDF.
.PARAMETER WkhtmltopdfPath
    Chemin vers l'exÃƒÂ©cutable wkhtmltopdf.
.EXAMPLE
    $Result = Export-ReportToPdf -ReportData $ReportData -OutputPath "output/reports/report.pdf"
.OUTPUTS
    System.Boolean - True si l'export a rÃƒÂ©ussi, False sinon.
#>
function Export-ReportToPdf {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [object]$ReportData,
        
        [Parameter(Mandatory=$true)]
        [string]$OutputPath,
        
        [Parameter(Mandatory=$false)]
        [string]$OptionsPath = $script:DefaultPdfOptionsPath,
        
        [Parameter(Mandatory=$false)]
        [string]$WkhtmltopdfPath = $script:DefaultWkhtmltopdfPath
    )
    
    try {
        # VÃƒÂ©rifier si wkhtmltopdf est installÃƒÂ©
        if (-not (Test-WkhtmltopdfInstallation -WkhtmltopdfPath $WkhtmltopdfPath)) {
            # Tenter d'installer wkhtmltopdf
            $Installed = Install-Wkhtmltopdf
            
            if (-not $Installed) {
                Write-Error "Impossible d'installer wkhtmltopdf"
                return $false
            }
        }
        
        # CrÃƒÂ©er un fichier HTML temporaire
        $TempHtmlPath = [System.IO.Path]::GetTempFileName() + ".html"
        
        # Exporter le rapport en HTML
        $HtmlExported = Export-ReportToHtml -ReportData $ReportData -OutputPath $TempHtmlPath
        
        if (-not $HtmlExported) {
            Write-Error "Ãƒâ€°chec de l'export du rapport en HTML"
            return $false
        }
        
        # Charger les options PDF
        $Options = Get-PdfOptions -OptionsPath $OptionsPath
        
        # Convertir les options en arguments
        $Arguments = ConvertTo-WkhtmltopdfArguments -Options $Options
        
        # Ajouter les chemins de fichiers aux arguments
        $Arguments += $TempHtmlPath
        $Arguments += $OutputPath
        
        # CrÃƒÂ©er le rÃƒÂ©pertoire de sortie s'il n'existe pas
        $OutputDir = Split-Path -Parent $OutputPath
        if (-not (Test-Path -Path $OutputDir)) {
            New-Item -Path $OutputDir -ItemType Directory -Force | Out-Null
        }
        
        # ExÃƒÂ©cuter wkhtmltopdf
        Write-Verbose "GÃƒÂ©nÃƒÂ©ration du PDF avec wkhtmltopdf"
        $Process = Start-Process -FilePath $WkhtmltopdfPath -ArgumentList $Arguments -Wait -PassThru -NoNewWindow
        
        # VÃƒÂ©rifier si la gÃƒÂ©nÃƒÂ©ration a rÃƒÂ©ussi
        if ($Process.ExitCode -eq 0) {
            Write-Verbose "PDF gÃƒÂ©nÃƒÂ©rÃƒÂ© avec succÃƒÂ¨s: $OutputPath"
            return $true
        }
        else {
            Write-Error "Ãƒâ€°chec de la gÃƒÂ©nÃƒÂ©ration du PDF: code de sortie $($Process.ExitCode)"
            return $false
        }
    }
    catch {
        Write-Error "Erreur lors de l'export du rapport en PDF: $_"
        return $false
    }
    finally {
        # Nettoyer les fichiers temporaires
        if (Test-Path -Path $TempHtmlPath) {
            Remove-Item -Path $TempHtmlPath -Force
        }
    }
}

# Exporter les fonctions
Export-ModuleMember -Function Export-ReportToPdf, Test-WkhtmltopdfInstallation, Install-Wkhtmltopdf
