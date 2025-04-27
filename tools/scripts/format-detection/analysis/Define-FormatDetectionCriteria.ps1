#Requires -Version 5.1
<#
.SYNOPSIS
    DÃ©finit et gÃ©nÃ¨re un fichier JSON de critÃ¨res de dÃ©tection pour divers formats de fichiers.

.DESCRIPTION
    Ce script Ã©tablit une structure de donnÃ©es dÃ©taillÃ©e pour les critÃ¨res de dÃ©tection
    de multiples formats de fichiers. Ces critÃ¨res incluent les extensions associÃ©es,
    les signatures binaires (magic numbers), les motifs de contenu (regex), les tests
    de structure spÃ©cifiques (ex: validation JSON/XML, structure ZIP Office) et une prioritÃ©
    de dÃ©tection. Le script gÃ©nÃ¨re ensuite un fichier JSON standardisÃ© qui sera utilisÃ©
    par des scripts d'analyse comme 'Analyze-FormatDetectionFailures.ps1'.

.PARAMETER OutputPath
    Le chemin complet oÃ¹ le fichier de configuration JSON ('FormatDetectionCriteria.json')
    sera enregistrÃ©. Par dÃ©faut, il est crÃ©Ã© dans le mÃªme rÃ©pertoire que le script.

.EXAMPLE
    .\Define-FormatDetectionCriteria.ps1
    # GÃ©nÃ¨re FormatDetectionCriteria.json dans le rÃ©pertoire courant.

.EXAMPLE
    .\Define-FormatDetectionCriteria.ps1 -OutputPath "C:\Configurations\Formats\DetectionRules.json"
    # GÃ©nÃ¨re le fichier de critÃ¨res Ã  un emplacement spÃ©cifique.

.NOTES
    Version: 1.1
    Auteur: Augment Agent (RÃ©visÃ© par IA)
    Date: 2025-04-12
    AmÃ©liorations v1.1:
    - Ajout de commentaires pour clarifier la structure et l'utilisation des champs.
    - Conversion explicite des patterns HEX en tableaux d'octets pour JSON.
    - Utilisation de `-Depth 10` pour ConvertTo-Json pour assurer la sÃ©rialisation complÃ¨te.
#>

[CmdletBinding(SupportsShouldProcess=$true)]
param(
    [Parameter(HelpMessage = "Chemin de sortie pour le fichier de critÃ¨res JSON.")]
    [string]$OutputPath = (Join-Path -Path $PSScriptRoot -ChildPath "FormatDetectionCriteria.json")
)

Write-Verbose "DÃ©finition des critÃ¨res de dÃ©tection pour les formats de fichiers."

# Structure principale des critÃ¨res
# Chaque clÃ© est le nom normalisÃ© du format (MAJUSCULES).
$formatCriteria = @{
    # --- FORMATS TEXTE ---
    "TEXT" = @{
        Category = "TEXT" # Type gÃ©nÃ©ral (TEXT, BINARY)
        Extensions = @(".txt", ".log", ".md", ".text", ".inf", ".ini", ".out") # Extensions courantes (minuscules)
        Signatures = @() # Signatures binaires (magic numbers)
        ContentPatterns = @{
            Regex = @() # Motifs Regex Ã  rechercher dans le contenu
            BinaryTest = @{
                MaxBinaryRatio = 0.15 # % max de caractÃ¨res non-texte (0-31 sauf CR, LF, TAB) ou NULL (0) tolÃ©rÃ©
                ControlCharsAllowed = @(9, 10, 13) # TAB, LF, CR sont autorisÃ©s dans les fichiers texte
            }
        }
        StructureTests = @{
            # Tests spÃ©cifiques Ã  la structure (ex: validation XML/JSON)
            LineBreaks = $true # Doit contenir des sauts de ligne typiques
        }
        Priority = 1 # PrioritÃ© de dÃ©tection (plus Ã©levÃ© = plus prioritaire)
    }
    "CSV" = @{
        Category = "TEXT"
        Extensions = @(".csv")
        Signatures = @()
        ContentPatterns = @{
            Regex = @(
                # Au moins 3 colonnes sÃ©parÃ©es par des virgules sur plusieurs lignes
                '(?m)^([^,]*,){2,}[^,\r\n]*$'
                # Ou au moins une ligne avec sÃ©parateur virgule
                 #'.*?,.*' # Trop gÃ©nÃ©rique, peut causer des faux positifs
            )
            BinaryTest = @{ MaxBinaryRatio = 0.05; ControlCharsAllowed = @(9, 10, 13) }
        }
        StructureTests = @{
            ConsistentDelimiter = "," # VÃ©rifier si la virgule est un dÃ©limiteur cohÃ©rent
            # ConsistentFieldCount = $true # Optionnel: VÃ©rifier si le nombre de champs est constant
        }
        Priority = 4 # Plus Ã©levÃ© que TEXT simple
    }
    "TSV" = @{
        Category = "TEXT"
        Extensions = @(".tsv", ".tab")
        Signatures = @()
        ContentPatterns = @{
            Regex = @(
                '(?m)^([^\t]*\t){2,}[^\t\r\n]*$' # Au moins 3 colonnes sÃ©parÃ©es par TAB
            )
            BinaryTest = @{ MaxBinaryRatio = 0.05; ControlCharsAllowed = @(9, 10, 13) }
        }
        StructureTests = @{ ConsistentDelimiter = "`t" }
        Priority = 4
    }
    "XML" = @{
        Category = "TEXT"
        Extensions = @(".xml", ".xsd", ".xsl", ".xslt", ".svg", ".config", ".csproj", ".vbproj", ".nuspec", ".plist")
        Signatures = @(
            @{ Offset = 0; Pattern = [byte[]](0xEF, 0xBB, 0xBF, 0x3C, 0x3F, 0x78, 0x6D, 0x6C); Type = "HEX" } # UTF8 BOM + <?xml
            @{ Offset = 0; Pattern = [byte[]](0x3C, 0x3F, 0x78, 0x6D, 0x6C); Type = "HEX" } # <?xml
        )
        ContentPatterns = @{
            Regex = @(
                '(?i)^\s*<\?xml\s+version=', # DÃ©claration XML (insensible Ã  la casse)
                '(?s)<([a-zA-Z0-9:]+)\b[^>]*>.*?</\1>' # PrÃ©sence de balises ouvrantes/fermantes correspondantes
            )
            BinaryTest = @{ MaxBinaryRatio = 0.05; ControlCharsAllowed = @(9, 10, 13) }
        }
        StructureTests = @{
            WellFormed = $true # Indique que le script d'analyse DEVRAIT tenter de valider la syntaxe XML
        }
        Priority = 6 # Assez spÃ©cifique
    }
    "HTML" = @{
        Category = "TEXT"
        Extensions = @(".html", ".htm", ".xhtml")
        Signatures = @(
             @{ Offset = 0; Pattern = "<!DOCTYPE html"; Type = "ASCII" } # Sensible Ã  la casse souvent
        )
        ContentPatterns = @{
            Regex = @(
                '(?i)^\s*<!DOCTYPE\s+html', # Doctype HTML5 (insensible Ã  la casse)
                '(?is)<html\b.*>.*</html>', # Balise <html> ... </html>
                '(?is)<head\b.*>.*</head>.*<body\b.*>.*</body>' # Structure head/body typique
            )
            BinaryTest = @{ MaxBinaryRatio = 0.05; ControlCharsAllowed = @(9, 10, 13) }
        }
        StructureTests = @{
            RequiredTags = @("html", "head", "body") # Indique que l'analyseur DEVRAIT chercher ces balises
        }
        Priority = 5 # LÃ©gÃ¨rement moins spÃ©cifique que XML pur
    }
    "JSON" = @{
        Category = "TEXT"
        Extensions = @(".json", ".jsonl", ".geojson", ".webmanifest")
        Signatures = @()
        ContentPatterns = @{
            Regex = @(
                '(?s)^\s*\{.*\}\s*$', # Commence par { et finit par } (objet)
                '(?s)^\s*\[.*\]\s*$', # Commence par [ et finit par ] (tableau)
                '"[^"\\]*(?:\\.[^"\\]*)*"\s*:' # PrÃ©sence de clÃ©s JSON (chaÃ®nes entre guillemets suivies de :)
            )
            BinaryTest = @{ MaxBinaryRatio = 0.05; ControlCharsAllowed = @(9, 10, 13) }
        }
        StructureTests = @{
            ValidJson = $true # Indique que l'analyseur DEVRAIT tenter de valider la syntaxe JSON
        }
        Priority = 6
    }
    "POWERSHELL" = @{
        Category = "TEXT"
        Extensions = @(".ps1", ".psm1", ".psd1")
        Signatures = @()
        ContentPatterns = @{
            Regex = @(
                '(?im)^\s*(param\s*\(|function\s+\w|class\s+\w|workflow\s+\w)', # DÃ©clarations PS
                '\$\w+\s*=', # Assignation de variable
                '(\b(Write|Get|Set|New|Add|Remove|Invoke|Test|Register|Unregister)-\w+)\b', # Cmdlets courantes
                '#requires\s+-version' # Directive Requires
            )
            BinaryTest = @{ MaxBinaryRatio = 0.05; ControlCharsAllowed = @(9, 10, 13) }
        }
        StructureTests = @{
            # ValidSyntax = $true # Trop complexe Ã  implÃ©menter nativement en PS5.1 pour l'analyse
        }
        Priority = 7 # TrÃ¨s spÃ©cifique
    }
    # Ajouter BATCH, PYTHON, JAVASCRIPT sur le mÃªme modÃ¨le que POWERSHELL...
    "PYTHON" = @{
        Category = "TEXT"; Extensions = @(".py", ".pyw"); Signatures = @();
        ContentPatterns = @{ Regex = @('(?m)^\s*def\s+\w+\s*\(', '(?m)^\s*class\s+\w+\s*:', '(?m)^\s*import\s+\w+', '(?m)^\s*from\s+\w+\s+import'); BinaryTest = @{ MaxBinaryRatio = 0.05; ControlCharsAllowed = @(9, 10, 13) }; };
        StructureTests = @{ Indentation = $true }; Priority = 7;
    }
    "JAVASCRIPT" = @{
        Category = "TEXT"; Extensions = @(".js", ".jsx", ".mjs", ".cjs"); Signatures = @();
        ContentPatterns = @{ Regex = @('(?i)\bfunction\s+\w+\s*\(', '\b(var|let|const)\s+\w+\s*=', '\bclass\s+\w+\s*{', '\bimport\s+.*\s+from\s+'); BinaryTest = @{ MaxBinaryRatio = 0.05; ControlCharsAllowed = @(9, 10, 13) }; };
        StructureTests = @{}; Priority = 7;
    }
     "BATCH" = @{
        Category = "TEXT"; Extensions = @(".bat", ".cmd"); Signatures = @();
        ContentPatterns = @{ Regex = @('(?im)^\s*@echo off', '(?im)^\s*set\s+\w+=', '(?im)^\s*goto\s+\w+', '(?im)^\s*if\s+.*\s+goto\s+'); BinaryTest = @{ MaxBinaryRatio = 0.05; ControlCharsAllowed = @(9, 10, 13) }; };
        StructureTests = @{}; Priority = 5;
    }

    # --- FORMATS BINAIRES ---
    "JPEG" = @{
        Category = "BINARY"; Extensions = @(".jpg", ".jpeg", ".jpe", ".jif", ".jfif");
        Signatures = @( @{ Offset = 0; Pattern = [byte[]](0xFF, 0xD8, 0xFF); Type = "HEX" } ); # Signature standard
        ContentPatterns = @{ BinaryTest = @{ IsBinary = $true } }; StructureTests = @{}; Priority = 8;
    }
    "PNG" = @{
        Category = "BINARY"; Extensions = @(".png");
        Signatures = @( @{ Offset = 0; Pattern = [byte[]](0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A); Type = "HEX" } );
        ContentPatterns = @{ BinaryTest = @{ IsBinary = $true } }; StructureTests = @{}; Priority = 8;
    }
    "GIF" = @{
        Category = "BINARY"; Extensions = @(".gif");
        Signatures = @(
            @{ Offset = 0; Pattern = "GIF87a"; Type = "ASCII" },
            @{ Offset = 0; Pattern = "GIF89a"; Type = "ASCII" }
        );
        ContentPatterns = @{ BinaryTest = @{ IsBinary = $true } }; StructureTests = @{}; Priority = 8;
    }
    "BMP" = @{
        Category = "BINARY"; Extensions = @(".bmp", ".dib");
        Signatures = @( @{ Offset = 0; Pattern = [byte[]](0x42, 0x4D); Type = "HEX" } ); # "BM"
        ContentPatterns = @{ BinaryTest = @{ IsBinary = $true } }; StructureTests = @{}; Priority = 8;
    }
    "TIFF" = @{
        Category = "BINARY"; Extensions = @(".tif", ".tiff");
        Signatures = @(
            @{ Offset = 0; Pattern = [byte[]](0x49, 0x49, 0x2A, 0x00); Type = "HEX" }, # Little-endian
            @{ Offset = 0; Pattern = [byte[]](0x4D, 0x4D, 0x00, 0x2A); Type = "HEX" }  # Big-endian
        );
        ContentPatterns = @{ BinaryTest = @{ IsBinary = $true } }; StructureTests = @{}; Priority = 8;
    }
    "PDF" = @{
        Category = "BINARY"; Extensions = @(".pdf");
        Signatures = @( @{ Offset = 0; Pattern = "%PDF-"; Type = "ASCII" } );
        ContentPatterns = @{ BinaryTest = @{ IsBinary = $true } }; StructureTests = @{}; Priority = 9; # TrÃ¨s fiable
    }
    "ZIP" = @{
        Category = "BINARY"; Extensions = @(".zip", ".jar", ".war", ".ear", ".kmz");
        Signatures = @(
            @{ Offset = 0; Pattern = [byte[]](0x50, 0x4B, 0x03, 0x04); Type = "HEX" }, # Standard PKZip
            @{ Offset = 0; Pattern = [byte[]](0x50, 0x4B, 0x05, 0x06); Type = "HEX" }, # Empty archive
            @{ Offset = 0; Pattern = [byte[]](0x50, 0x4B, 0x07, 0x08); Type = "HEX" }  # Spanned archive
        );
        ContentPatterns = @{ BinaryTest = @{ IsBinary = $true } };
        StructureTests = @{ ZipStructure = $true }; # Indique qu'on DEVRAIT pouvoir lister le contenu
        Priority = 6; # PrioritÃ© moyenne, car utilisÃ© par d'autres formats (Office)
    }
     # Formats Office basÃ©s sur ZIP (OOXML) - Ils ont la mÃªme signature ZIP mais des extensions diffÃ©rentes
    "WORD" = @{
        Category = "BINARY"; Extensions = @(".docx", ".docm", ".dotx", ".dotm");
        Signatures = @( @{ Offset = 0; Pattern = [byte[]](0x50, 0x4B, 0x03, 0x04); Type = "HEX" } ); # Signature ZIP
        ContentPatterns = @{ BinaryTest = @{ IsBinary = $true } };
        StructureTests = @{
            ZipStructure = $true;
            # L'analyseur doit chercher ce fichier spÃ©cifique DANS le ZIP pour confirmer
            DocxContentTypes = @{ Path = "word/document.xml"; Required = $true }
        };
        Priority = 7; # Plus prioritaire que ZIP gÃ©nÃ©rique si l'extension correspond ET la structure est vÃ©rifiÃ©e
    }
     "EXCEL" = @{
        Category = "BINARY"; Extensions = @(".xlsx", ".xlsm", ".xltx", ".xltm", ".xlsb"); # xlsb est binaire mais peut avoir sig zip
        Signatures = @( @{ Offset = 0; Pattern = [byte[]](0x50, 0x4B, 0x03, 0x04); Type = "HEX" } ); # Signature ZIP
        ContentPatterns = @{ BinaryTest = @{ IsBinary = $true } };
        StructureTests = @{
            ZipStructure = $true;
            XlsxContentTypes = @{ Path = "xl/workbook.xml"; Required = $true }
        };
        Priority = 7;
    }
    "POWERPOINT" = @{
        Category = "BINARY"; Extensions = @(".pptx", ".pptm", ".potx", ".potm", ".ppsx", ".ppsm");
        Signatures = @( @{ Offset = 0; Pattern = [byte[]](0x50, 0x4B, 0x03, 0x04); Type = "HEX" } ); # Signature ZIP
        ContentPatterns = @{ BinaryTest = @{ IsBinary = $true } };
        StructureTests = @{
            ZipStructure = $true;
            PptxContentTypes = @{ Path = "ppt/presentation.xml"; Required = $true }
        };
        Priority = 7;
    }
    # Anciens formats Office (OLE Compound File)
    "WORD_LEGACY" = @{
        Category = "BINARY"; Extensions = @(".doc", ".dot");
        Signatures = @( @{ Offset = 0; Pattern = [byte[]](0xD0, 0xCF, 0x11, 0xE0, 0xA1, 0xB1, 0x1A, 0xE1); Type = "HEX" } );
        ContentPatterns = @{ BinaryTest = @{ IsBinary = $true } }; StructureTests = @{}; Priority = 7;
    }
     "EXCEL_LEGACY" = @{
        Category = "BINARY"; Extensions = @(".xls", ".xlt");
        Signatures = @( @{ Offset = 0; Pattern = [byte[]](0xD0, 0xCF, 0x11, 0xE0, 0xA1, 0xB1, 0x1A, 0xE1); Type = "HEX" } );
        ContentPatterns = @{ BinaryTest = @{ IsBinary = $true } }; StructureTests = @{}; Priority = 7;
    }
    "POWERPOINT_LEGACY" = @{
        Category = "BINARY"; Extensions = @(".ppt", ".pot", ".pps");
        Signatures = @( @{ Offset = 0; Pattern = [byte[]](0xD0, 0xCF, 0x11, 0xE0, 0xA1, 0xB1, 0x1A, 0xE1); Type = "HEX" } );
        ContentPatterns = @{ BinaryTest = @{ IsBinary = $true } }; StructureTests = @{}; Priority = 7;
    }
     "INSTALLER_MSI" = @{ # Aussi OLE
        Category = "BINARY"; Extensions = @(".msi", ".msp", ".mst");
        Signatures = @( @{ Offset = 0; Pattern = [byte[]](0xD0, 0xCF, 0x11, 0xE0, 0xA1, 0xB1, 0x1A, 0xE1); Type = "HEX" } );
        ContentPatterns = @{ BinaryTest = @{ IsBinary = $true } }; StructureTests = @{}; Priority = 9;
    }
     # Autres archives
    "RAR" = @{
        Category = "BINARY"; Extensions = @(".rar");
        Signatures = @(
            @{ Offset = 0; Pattern = [byte[]](0x52, 0x61, 0x72, 0x21, 0x1A, 0x07, 0x00); Type = "HEX" }, # RAR v1.5+
            @{ Offset = 0; Pattern = [byte[]](0x52, 0x61, 0x72, 0x21, 0x1A, 0x07, 0x01, 0x00); Type = "HEX" }  # RAR v5+
        );
        ContentPatterns = @{ BinaryTest = @{ IsBinary = $true } }; StructureTests = @{}; Priority = 6;
    }
    "7Z" = @{
        Category = "BINARY"; Extensions = @(".7z");
        Signatures = @( @{ Offset = 0; Pattern = [byte[]](0x37, 0x7A, 0xBC, 0xAF, 0x27, 0x1C); Type = "HEX" } );
        ContentPatterns = @{ BinaryTest = @{ IsBinary = $true } }; StructureTests = @{}; Priority = 6;
    }
    # ExÃ©cutables
    "EXECUTABLE_PE" = @{ # Windows PE (Portable Executable)
        Category = "BINARY"; Extensions = @(".exe", ".dll", ".sys", ".ocx", ".cpl", ".drv", ".scr");
        Signatures = @( @{ Offset = 0; Pattern = [byte[]](0x4D, 0x5A); Type = "HEX" } ); # "MZ" header
        ContentPatterns = @{ BinaryTest = @{ IsBinary = $true } };
        StructureTests = @{ PEHeader = $true }; # Indique qu'on DEVRAIT vÃ©rifier la prÃ©sence de l'en-tÃªte PE plus loin
        Priority = 10; # TrÃ¨s haute prioritÃ©
    }
    # Format Binaire gÃ©nÃ©rique (Fallback)
    "BINARY" = @{
        Category = "BINARY"
        Extensions = @(".bin", ".dat", ".data", ".img", ".iso", ".dump") # Extensions trÃ¨s gÃ©nÃ©riques
        Signatures = @() # Aucune signature spÃ©cifique
        ContentPatterns = @{
            BinaryTest = @{ IsBinary = $true } # Le test binaire doit Ã©chouer pour TEXT
        }
        StructureTests = @{}
        Priority = 0 # PrioritÃ© la plus basse, utilisÃ© si rien d'autre ne correspond
    }
     # Format Inconnu (Fallback ultime)
    "UNKNOWN" = @{
        Category = "UNKNOWN"; Extensions = @(); Signatures = @(); ContentPatterns = @{}; StructureTests = @{}; Priority = -1;
    }
}

# Valider la structure (optionnel mais recommandÃ©)
# TODO: Ajouter une fonction qui vÃ©rifie que chaque entrÃ©e a au moins Category, Extensions, Priority etc.

# Enregistrer les critÃ¨res au format JSON
Write-Verbose "Enregistrement des critÃ¨res dans $OutputPath..."
if ($PSCmdlet.ShouldProcess($OutputPath, "GÃ©nÃ©rer le fichier de critÃ¨res JSON")) {
    try {
        # Utiliser Depth 10 pour Ãªtre sÃ»r que toutes les structures imbriquÃ©es sont sÃ©rialisÃ©es
        $formatCriteria | ConvertTo-Json -Depth 10 | Out-File -FilePath $OutputPath -Encoding utf8 -Force -ErrorAction Stop
        Write-Host "CritÃ¨res de dÃ©tection de format enregistrÃ©s avec succÃ¨s dans : $OutputPath" -ForegroundColor Green
    } catch {
        Write-Error "Impossible d'enregistrer les critÃ¨res dans '$OutputPath': $($_.Exception.Message)"
        exit 1 # ArrÃªter si l'Ã©criture Ã©choue
    }
}

# Afficher un rÃ©sumÃ©
$totalFormats = $formatCriteria.Keys.Count
$textFormats = ($formatCriteria.Values | Where-Object { $_.Category -eq "TEXT" }).Count
$binaryFormats = ($formatCriteria.Values | Where-Object { $_.Category -eq "BINARY" }).Count
$unknownFormats = ($formatCriteria.Values | Where-Object { $_.Category -notin @("TEXT", "BINARY") }).Count

Write-Host "`n--- RÃ©sumÃ© des CritÃ¨res DÃ©finis ---" -ForegroundColor Cyan
Write-Host " Nombre total de formats      : $totalFormats" -ForegroundColor White
Write-Host " Formats Texte              : $textFormats" -ForegroundColor White
Write-Host " Formats Binaires           : $binaryFormats" -ForegroundColor White
Write-Host " Autres (Unknown/CatÃ©gorie) : $unknownFormats" -ForegroundColor White

# Afficher les formats par prioritÃ© dÃ©croissante (Top 10)
Write-Host "`n Top 10 des Formats par PrioritÃ© :" -ForegroundColor Cyan
$formatsByPriority = $formatCriteria.GetEnumerator() | Sort-Object { $_.Value.Priority } -Descending | Select-Object -First 10
$rank = 1
foreach ($format in $formatsByPriority) {
    Write-Host (" {0,3}. {1,-20} (PrioritÃ©: {2})" -f $rank, $format.Key, $format.Value.Priority) -ForegroundColor White
    $rank++
}
Write-Host "--- Fin de la dÃ©finition des critÃ¨res ---" -ForegroundColor Cyan