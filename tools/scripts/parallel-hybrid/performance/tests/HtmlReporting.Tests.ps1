Describe "Fonctions de génération de rapports HTML" {
    Context "Génération de graphiques" {
        BeforeAll {
            # Fonction pour générer un graphique Chart.js
            function New-ChartJsGraph {
                param (
                    [string]$ChartId,
                    [string]$ChartType,
                    [string]$Title,
                    [string]$Labels,
                    [string]$DataSets,
                    [int]$Width = 800,
                    [int]$Height = 400
                )

                $chartHtml = @"
<div class="chart-container" style="position: relative; width: ${Width}px; height: ${Height}px; margin: 20px auto;">
    <canvas id="$ChartId"></canvas>
</div>
<script>
    var ctx = document.getElementById('$ChartId').getContext('2d');
    var $ChartId = new Chart(ctx, {
        type: '$ChartType',
        data: {
            labels: $Labels,
            datasets: $DataSets
        },
        options: {
            responsive: true,
            title: {
                display: true,
                text: '$Title'
            }
        }
    });
</script>
"@
                return $chartHtml
            }

            # Données de test
            $testLabels = '["Test1", "Test2", "Test3"]'
            $testDataSets = @"
[{
    label: 'Temps d\'exécution (s)',
    data: [5.2, 4.5, 4.8],
    backgroundColor: 'rgba(54, 162, 235, 0.2)',
    borderColor: 'rgba(54, 162, 235, 1)',
    borderWidth: 1
}]
"@
        }

        It "Génère correctement un graphique Chart.js" {
            # Générer un graphique
            $chartHtml = New-ChartJsGraph -ChartId "testChart" -ChartType "bar" -Title "Test Chart" -Labels $testLabels -DataSets $testDataSets

            # Vérifier que le HTML contient les éléments attendus
            $chartHtml | Should -Match "canvas id=`"testChart`""
            $chartHtml | Should -Match "type: 'bar'"
            $chartHtml | Should -Match "text: 'Test Chart'"
            $chartHtml | Should -Match $testLabels
            $chartHtml | Should -Match "Temps d\\'exécution \(s\)"
        }
    }

    Context "Génération de tableaux HTML" {
        BeforeAll {
            # Fonction pour générer un tableau HTML
            function New-HtmlTable {
                param (
                    [array]$Data,
                    [string]$TableId,
                    [string[]]$Columns,
                    [string[]]$Headers,
                    [hashtable]$Formatters = @{},
                    [string]$CssClass = "data-table"
                )

                $tableHtml = "<table id='$TableId' class='$CssClass'>`n"
                $tableHtml += "  <thead>`n    <tr>`n"

                # Ajouter les en-têtes
                foreach ($header in $Headers) {
                    $tableHtml += "      <th>$header</th>`n"
                }
                $tableHtml += "    </tr>`n  </thead>`n  <tbody>`n"

                # Ajouter les lignes de données
                foreach ($row in $Data) {
                    $tableHtml += "    <tr>`n"
                    foreach ($col in $Columns) {
                        $value = $row.$col

                        # Appliquer le formattage si défini
                        if ($Formatters.ContainsKey($col)) {
                            $format = $Formatters[$col]
                            $value = $value.ToString($format)
                        }

                        $tableHtml += "      <td>$value</td>`n"
                    }
                    $tableHtml += "    </tr>`n"
                }

                $tableHtml += "  </tbody>`n</table>"
                return $tableHtml
            }

            # Données de test
            $testData = @(
                [PSCustomObject]@{
                    BatchSize = 10
                    ExecutionTime = 5.2
                    SuccessRate = 100
                },
                [PSCustomObject]@{
                    BatchSize = 20
                    ExecutionTime = 4.5
                    SuccessRate = 100
                },
                [PSCustomObject]@{
                    BatchSize = 50
                    ExecutionTime = 3.8
                    SuccessRate = 80
                }
            )
        }

        It "Génère correctement un tableau HTML" {
            # Générer un tableau
            $tableHtml = New-HtmlTable -Data $testData -TableId "testTable" -Columns @("BatchSize", "ExecutionTime", "SuccessRate") -Headers @("Taille du lot", "Temps d'exécution (s)", "Taux de succès (%)") -Formatters @{ExecutionTime = "F2"; SuccessRate = "F1"}

            # Vérifier que le HTML contient les éléments attendus
            $tableHtml | Should -Match "table id='testTable'"
            $tableHtml | Should -Match "<th>Taille du lot</th>"
            $tableHtml | Should -Match "<th>Temps d'exécution \(s\)</th>"
            $tableHtml | Should -Match "<th>Taux de succès \(%\)</th>"
            $tableHtml | Should -Match "<td>10</td>"
            $tableHtml | Should -Match "<td>5.20</td>"
            $tableHtml | Should -Match "<td>100.0</td>"
        }
    }

    Context "Génération de rapports complets" {
        BeforeAll {
            # Fonction pour générer un rapport HTML complet
            function New-HtmlReport {
                param (
                    [string]$Title,
                    [string]$Content,
                    [string]$CssStyles = "",
                    [string]$JsScripts = ""
                )

                $htmlReport = @"
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>$Title</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        h1 { color: #2c3e50; }
        .container { max-width: 1200px; margin: 0 auto; }
        $CssStyles
    </style>
    <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
</head>
<body>
    <div class="container">
        <h1>$Title</h1>
        $Content
    </div>
    <script>
        $JsScripts
    </script>
</body>
</html>
"@
                return $htmlReport
            }
        }

        It "Génère correctement un rapport HTML complet" {
            # Générer un rapport
            $reportContent = "<p>Ceci est un rapport de test.</p>"
            $customCss = ".test { color: red; }"
            $customJs = "console.log('Test');"

            $reportHtml = New-HtmlReport -Title "Rapport de test" -Content $reportContent -CssStyles $customCss -JsScripts $customJs

            # Vérifier que le HTML contient les éléments attendus
            $reportHtml | Should -Match "<title>Rapport de test</title>"
            $reportHtml | Should -Match "<h1>Rapport de test</h1>"
            $reportHtml | Should -Match "<p>Ceci est un rapport de test.</p>"
            $reportHtml | Should -Match "\.test \{ color: red; \}"
            $reportHtml | Should -Match "console\.log\('Test'\);"
            $reportHtml | Should -Match "<script src=`"https://cdn\.jsdelivr\.net/npm/chart\.js`"></script>"
        }
    }
}
