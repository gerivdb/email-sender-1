#Requires -Version 5.1
<#
.SYNOPSIS
    Module de filtrage pour les rapports d'analyse de pull requests.
.DESCRIPTION
    Fournit des fonctions pour filtrer et trier les résultats d'analyse
    de pull requests dans les rapports interactifs.
.NOTES
    Version: 1.0
    Auteur: Augment Agent
    Date: 2025-04-29
#>

# Fonction pour générer des contrôles de filtrage HTML
function Add-FilterControls {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [AllowEmptyCollection()]
        [object[]]$Issues,

        [Parameter()]
        [string]$ContainerId = "pr-filter-controls",

        [Parameter()]
        [string]$TargetTableId = "pr-issues-table",

        [Parameter()]
        [string[]]$FilterProperties = @("Type", "Severity", "Rule"),

        [Parameter()]
        [hashtable]$CustomLabels = @{}
    )

    # Vérifier si la collection est vide
    if ($null -eq $Issues -or $Issues.Count -eq 0) {
        $Issues = @()
    }

    # Extraire les valeurs uniques pour chaque propriété de filtrage
    $filterValues = @{}
    foreach ($property in $FilterProperties) {
        if ($Issues.Count -gt 0) {
            $values = $Issues | Select-Object -ExpandProperty $property -Unique | Sort-Object
            $filterValues[$property] = $values
        } else {
            $filterValues[$property] = @()
        }
    }

    # Générer le HTML pour les contrôles de filtrage
    $html = @"
<div id="$ContainerId" class="pr-filter-container">
    <div class="pr-filter-header">
        <h3>Filtres</h3>
        <button id="pr-reset-filters" class="pr-button">Réinitialiser</button>
    </div>
    <div class="pr-filter-controls">
"@

    foreach ($property in $FilterProperties) {
        $label = if ($CustomLabels.ContainsKey($property)) { $CustomLabels[$property] } else { $property }

        $html += @"
        <div class="pr-filter-group">
            <label class="pr-filter-label">$label</label>
            <select class="pr-filter-select" data-filter="$property">
                <option value="">Tous</option>
"@

        foreach ($value in $filterValues[$property]) {
            $html += @"
                <option value="$value">$value</option>
"@
        }

        $html += @"
            </select>
        </div>
"@
    }

    # Ajouter un champ de recherche
    $html += @"
        <div class="pr-filter-group">
            <label class="pr-filter-label">Recherche</label>
            <input type="text" id="pr-search-input" class="pr-search-input" placeholder="Rechercher...">
        </div>
    </div>
</div>

<script>
document.addEventListener('DOMContentLoaded', function() {
    const filterControls = document.querySelectorAll('#$ContainerId .pr-filter-select');
    const searchInput = document.getElementById('pr-search-input');
    const resetButton = document.getElementById('pr-reset-filters');
    const table = document.getElementById('$TargetTableId');

    if (!table) {
        console.error('Table cible non trouvée: $TargetTableId');
        return;
    }

    // Fonction pour appliquer les filtres
    function applyFilters() {
        const filters = {};
        filterControls.forEach(select => {
            if (select.value) {
                filters[select.dataset.filter] = select.value;
            }
        });

        const searchTerm = searchInput.value.toLowerCase();
        const rows = table.querySelectorAll('tbody tr');

        rows.forEach(row => {
            let visible = true;

            // Appliquer les filtres de sélection
            for (const [property, value] of Object.entries(filters)) {
                const cell = row.querySelector(`[data-${property.toLowerCase()}]`);
                if (cell && cell.dataset[property.toLowerCase()] !== value) {
                    visible = false;
                    break;
                }
            }

            // Appliquer le filtre de recherche
            if (visible && searchTerm) {
                visible = Array.from(row.cells).some(cell =>
                    cell.textContent.toLowerCase().includes(searchTerm)
                );
            }

            row.style.display = visible ? '' : 'none';
        });

        // Mettre à jour le compteur
        updateCounter();
    }

    // Fonction pour mettre à jour le compteur d'éléments visibles
    function updateCounter() {
        const visibleRows = table.querySelectorAll('tbody tr:not([style*="display: none"])').length;
        const totalRows = table.querySelectorAll('tbody tr').length;

        const counterElement = document.getElementById('pr-issues-counter');
        if (counterElement) {
            counterElement.textContent = `Affichage de ${visibleRows} sur ${totalRows} problèmes`;
        }
    }

    // Ajouter les écouteurs d'événements
    filterControls.forEach(select => {
        select.addEventListener('change', applyFilters);
    });

    searchInput.addEventListener('input', applyFilters);

    resetButton.addEventListener('click', function() {
        filterControls.forEach(select => {
            select.value = '';
        });
        searchInput.value = '';
        applyFilters();
    });

    // Initialiser le compteur
    updateCounter();
});
</script>

<style>
.pr-filter-container {
    margin: 20px 0;
    padding: 15px;
    background-color: #f8f9fa;
    border: 1px solid #ddd;
    border-radius: 5px;
}
.pr-filter-header {
    display: flex;
    justify-content: space-between;
    align-items: center;
    margin-bottom: 15px;
}
.pr-filter-header h3 {
    margin: 0;
    color: #333;
}
.pr-filter-controls {
    display: flex;
    flex-wrap: wrap;
    gap: 15px;
}
.pr-filter-group {
    display: flex;
    flex-direction: column;
    min-width: 150px;
}
.pr-filter-label {
    font-size: 14px;
    color: #555;
    margin-bottom: 5px;
}
.pr-filter-select, .pr-search-input {
    padding: 8px;
    border: 1px solid #ddd;
    border-radius: 4px;
    font-size: 14px;
}
.pr-button {
    padding: 8px 15px;
    background-color: #f0f0f0;
    border: 1px solid #ddd;
    border-radius: 4px;
    cursor: pointer;
    font-size: 14px;
    color: #333;
}
.pr-button:hover {
    background-color: #e0e0e0;
}
</style>
"@

    return $html
}

# Fonction pour ajouter des capacités de tri à une table HTML
function Add-SortingCapabilities {
    [CmdletBinding()]
    param(
        [Parameter()]
        [string]$TableId = "pr-issues-table",

        [Parameter()]
        [string[]]$SortableColumns = @("Type", "Severity", "Line", "Rule"),

        [Parameter()]
        [string]$DefaultSortColumn = "Severity",

        [Parameter()]
        [string]$DefaultSortDirection = "desc"
    )

    # Générer le JavaScript pour le tri
    $html = @"
<script>
document.addEventListener('DOMContentLoaded', function() {
    const table = document.getElementById('$TableId');

    if (!table) {
        console.error('Table non trouvée: $TableId');
        return;
    }

    // Ajouter des attributs de tri aux en-têtes de colonnes
    const headers = table.querySelectorAll('thead th');
    const sortableColumns = $($SortableColumns | ConvertTo-Json -Compress);

    headers.forEach(header => {
        const columnName = header.textContent.trim();
        if (sortableColumns.includes(columnName)) {
            header.classList.add('pr-sortable');
            header.dataset.sort = columnName.toLowerCase();
            header.dataset.direction = 'none';

            // Ajouter l'indicateur de tri
            const sortIndicator = document.createElement('span');
            sortIndicator.className = 'pr-sort-indicator';
            header.appendChild(sortIndicator);

            // Ajouter l'écouteur d'événements
            header.addEventListener('click', () => sortTable(header));
        }
    });

    // Fonction pour trier la table
    function sortTable(header) {
        const column = header.dataset.sort;
        let direction = header.dataset.direction;

        // Réinitialiser tous les en-têtes
        headers.forEach(h => {
            if (h !== header) {
                h.dataset.direction = 'none';
                h.classList.remove('pr-sort-asc', 'pr-sort-desc');
            }
        });

        // Changer la direction
        if (direction === 'none' || direction === 'desc') {
            direction = 'asc';
        } else {
            direction = 'desc';
        }

        header.dataset.direction = direction;
        header.classList.remove('pr-sort-asc', 'pr-sort-desc');
        header.classList.add(`pr-sort-\${direction}`);

        // Trier les lignes
        const tbody = table.querySelector('tbody');
        const rows = Array.from(tbody.querySelectorAll('tr'));

        rows.sort((a, b) => {
            const aValue = a.querySelector(`[data-\${column}]`)?.dataset[column] || a.cells[Array.from(headers).indexOf(header)].textContent;
            const bValue = b.querySelector(`[data-\${column}]`)?.dataset[column] || b.cells[Array.from(headers).indexOf(header)].textContent;

            // Déterminer le type de données
            if (!isNaN(aValue) && !isNaN(bValue)) {
                // Tri numérique
                return direction === 'asc'
                    ? parseFloat(aValue) - parseFloat(bValue)
                    : parseFloat(bValue) - parseFloat(aValue);
            } else {
                // Tri alphabétique
                return direction === 'asc'
                    ? aValue.localeCompare(bValue)
                    : bValue.localeCompare(aValue);
            }
        });

        // Réorganiser les lignes
        rows.forEach(row => tbody.appendChild(row));
    }

    // Trier par défaut
    const defaultHeader = Array.from(headers).find(h => h.textContent.trim() === '$DefaultSortColumn');
    if (defaultHeader) {
        defaultHeader.dataset.direction = '$DefaultSortDirection' === 'asc' ? 'desc' : 'asc'; // Inversé car le clic va le changer
        sortTable(defaultHeader);
    }
});
</script>

<style>
.pr-sortable {
    cursor: pointer;
    position: relative;
    padding-right: 20px;
}
.pr-sort-indicator {
    position: absolute;
    right: 5px;
    top: 50%;
    transform: translateY(-50%);
}
.pr-sort-indicator::before {
    content: '⇕';
    color: #ccc;
}
.pr-sort-asc .pr-sort-indicator::before {
    content: '↑';
    color: #333;
}
.pr-sort-desc .pr-sort-indicator::before {
    content: '↓';
    color: #333;
}
</style>
"@

    return $html
}

# Fonction pour créer une vue personnalisée
function New-CustomReportView {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Name,

        [Parameter(Mandatory = $true)]
        [hashtable]$Filters,

        [Parameter()]
        [string]$Description = "",

        [Parameter()]
        [string]$Icon = "filter",

        [Parameter()]
        [string]$TargetTableId = "pr-issues-table"
    )

    # Générer un ID unique pour la vue
    $viewId = "view-$($Name.ToLower() -replace '[^a-z0-9]', '-')"

    # Convertir les filtres en JSON pour le JavaScript
    $filtersJson = $Filters | ConvertTo-Json -Compress

    # Générer le HTML pour la vue personnalisée
    $html = @"
<div class="pr-custom-view" id="$viewId" data-filters='$filtersJson'>
    <div class="pr-view-icon">
        <i class="fas fa-$Icon"></i>
    </div>
    <div class="pr-view-content">
        <h4 class="pr-view-name">$Name</h4>
        <p class="pr-view-description">$Description</p>
    </div>
</div>

<script>
document.addEventListener('DOMContentLoaded', function() {
    const view = document.getElementById('$viewId');

    if (!view) {
        console.error('Vue personnalisée non trouvée: $viewId');
        return;
    }

    view.addEventListener('click', function() {
        const filters = JSON.parse(this.dataset.filters);
        const table = document.getElementById('$TargetTableId');

        if (!table) {
            console.error('Table cible non trouvée: $TargetTableId');
            return;
        }

        // Réinitialiser les filtres actuels
        const filterSelects = document.querySelectorAll('.pr-filter-select');
        const searchInput = document.getElementById('pr-search-input');

        filterSelects.forEach(select => {
            select.value = '';
        });

        if (searchInput) {
            searchInput.value = '';
        }

        // Appliquer les nouveaux filtres
        for (const [property, value] of Object.entries(filters)) {
            const select = document.querySelector(`.pr-filter-select[data-filter="\${property}"]`);
            if (select) {
                select.value = value;
            }
        }

        // Déclencher l'événement de changement pour appliquer les filtres
        filterSelects[0]?.dispatchEvent(new Event('change'));

        // Mettre en évidence la vue active
        document.querySelectorAll('.pr-custom-view').forEach(v => {
            v.classList.remove('pr-view-active');
        });
        this.classList.add('pr-view-active');
    });
});
</script>

<style>
.pr-custom-view {
    display: flex;
    align-items: center;
    padding: 10px 15px;
    background-color: #f8f9fa;
    border: 1px solid #ddd;
    border-radius: 5px;
    margin-bottom: 10px;
    cursor: pointer;
    transition: background-color 0.2s;
}
.pr-custom-view:hover {
    background-color: #e9ecef;
}
.pr-view-active {
    background-color: #e2e6ea;
    border-color: #ced4da;
}
.pr-view-icon {
    margin-right: 15px;
    font-size: 20px;
    color: #6c757d;
}
.pr-view-content {
    flex-grow: 1;
}
.pr-view-name {
    margin: 0 0 5px 0;
    font-size: 16px;
    color: #495057;
}
.pr-view-description {
    margin: 0;
    font-size: 14px;
    color: #6c757d;
}
</style>
"@

    return $html
}

# Fonction pour créer un rapport avec recherche avancée
function New-SearchableReport {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [AllowEmptyCollection()]
        [object[]]$Issues,

        [Parameter()]
        [string]$Title = "Rapport d'analyse",

        [Parameter()]
        [string]$Description = "",

        [Parameter()]
        [string]$TableId = "pr-issues-table",

        [Parameter()]
        [string[]]$SearchableProperties = @("FilePath", "Message", "Rule", "Type", "Severity")
    )

    # Vérifier si la collection est vide
    if ($null -eq $Issues -or $Issues.Count -eq 0) {
        $Issues = @()
    }

    # Générer le HTML pour le rapport avec recherche
    $html = @"
<div class="pr-searchable-report">
    <div class="pr-report-header">
        <h2>$Title</h2>
        <p>$Description</p>
    </div>

    <div class="pr-search-container">
        <input type="text" id="pr-advanced-search" class="pr-advanced-search" placeholder="Recherche avancée (ex: severity:error type:syntax)">
        <button id="pr-search-help" class="pr-button pr-help-button">?</button>
    </div>

    <div id="pr-search-help-content" class="pr-search-help-content" style="display: none;">
        <h4>Aide à la recherche</h4>
        <p>Vous pouvez utiliser les filtres suivants dans votre recherche :</p>
        <ul>
"@

    foreach ($property in $SearchableProperties) {
        $html += @"
            <li><strong>$($property.ToLower()):</strong> Filtrer par $property (ex: $($property.ToLower()):valeur)</li>
"@
    }

    $html += @"
        </ul>
        <p>Vous pouvez combiner plusieurs filtres : <code>severity:error type:syntax file:script.ps1</code></p>
        <p>Les termes sans préfixe seront recherchés dans tous les champs.</p>
    </div>

    <div class="pr-results-info">
        <span id="pr-issues-counter">Affichage de ${$Issues.Count} problèmes</span>
    </div>

    <table id="$TableId" class="pr-issues-table">
        <thead>
            <tr>
                <th>Type</th>
                <th>Severity</th>
                <th>FilePath</th>
                <th>Line</th>
                <th>Message</th>
                <th>Rule</th>
            </tr>
        </thead>
        <tbody>
"@

    foreach ($issue in $Issues) {
        $html += @"
            <tr data-type="$($issue.Type)" data-severity="$($issue.Severity)" data-rule="$($issue.Rule)">
                <td>$($issue.Type)</td>
                <td>$($issue.Severity)</td>
                <td>$($issue.FilePath)</td>
                <td>$($issue.Line)</td>
                <td>$($issue.Message)</td>
                <td>$($issue.Rule)</td>
            </tr>
"@
    }

    $html += @"
        </tbody>
    </table>
</div>

<script>
document.addEventListener('DOMContentLoaded', function() {
    const searchInput = document.getElementById('pr-advanced-search');
    const table = document.getElementById('$TableId');
    const helpButton = document.getElementById('pr-search-help');
    const helpContent = document.getElementById('pr-search-help-content');

    if (!table || !searchInput) {
        console.error('Éléments requis non trouvés');
        return;
    }

    // Fonction pour analyser la requête de recherche
    function parseSearchQuery(query) {
        const filters = {};
        const terms = [];

        // Extraire les filtres spécifiques (property:value)
        const filterRegex = /(\w+):([^\s]+|"[^"]*")/g;
        let match;

        while ((match = filterRegex.exec(query)) !== null) {
            const property = match[1].toLowerCase();
            let value = match[2];

            // Supprimer les guillemets si présents
            if (value.startsWith('"') && value.endsWith('"')) {
                value = value.substring(1, value.length - 1);
            }

            filters[property] = value.toLowerCase();

            // Remplacer le filtre par un espace dans la requête
            query = query.replace(match[0], ' ');
        }

        // Les termes restants sont des termes de recherche généraux
        query.split(/\s+/).forEach(term => {
            if (term.trim()) {
                terms.push(term.toLowerCase());
            }
        });

        return { filters, terms };
    }

    // Fonction pour appliquer la recherche
    function applySearch() {
        const query = searchInput.value;
        const { filters, terms } = parseSearchQuery(query);
        const rows = table.querySelectorAll('tbody tr');
        const searchableProperties = $($SearchableProperties | ConvertTo-Json -Compress);

        rows.forEach(row => {
            let visible = true;

            // Appliquer les filtres spécifiques
            for (const [property, value] of Object.entries(filters)) {
                if (searchableProperties.includes(property.charAt(0).toUpperCase() + property.slice(1))) {
                    const cell = row.querySelector(`[data-\${property}]`) ||
                                 row.cells[Array.from(row.parentNode.parentNode.querySelector('thead tr').cells)
                                    .findIndex(cell => cell.textContent.toLowerCase() === property)];

                    if (cell) {
                        const cellValue = (cell.dataset[property] || cell.textContent).toLowerCase();
                        if (!cellValue.includes(value)) {
                            visible = false;
                            break;
                        }
                    } else {
                        // Si la propriété n'est pas trouvée, on considère que le filtre n'est pas satisfait
                        visible = false;
                        break;
                    }
                } else {
                    // Propriété non reconnue, ignorer ce filtre
                    console.warn(`Propriété de recherche non reconnue: \${property}`);
                }
            }

            // Appliquer les termes généraux
            if (visible && terms.length > 0) {
                const rowText = Array.from(row.cells).map(cell => cell.textContent.toLowerCase()).join(' ');
                visible = terms.every(term => rowText.includes(term));
            }

            row.style.display = visible ? '' : 'none';
        });

        // Mettre à jour le compteur
        updateCounter();
    }

    // Fonction pour mettre à jour le compteur
    function updateCounter() {
        const visibleRows = table.querySelectorAll('tbody tr:not([style*="display: none"])').length;
        const totalRows = table.querySelectorAll('tbody tr').length;

        const counterElement = document.getElementById('pr-issues-counter');
        if (counterElement) {
            counterElement.textContent = `Affichage de \${visibleRows} sur \${totalRows} problèmes`;
        }
    }

    // Ajouter les écouteurs d'événements
    searchInput.addEventListener('input', applySearch);

    helpButton.addEventListener('click', function() {
        helpContent.style.display = helpContent.style.display === 'none' ? 'block' : 'none';
    });

    // Initialiser le compteur
    updateCounter();
});
</script>

<style>
.pr-searchable-report {
    font-family: Arial, sans-serif;
    margin: 20px 0;
}
.pr-report-header {
    margin-bottom: 20px;
}
.pr-report-header h2 {
    margin: 0 0 10px 0;
    color: #333;
}
.pr-search-container {
    display: flex;
    margin-bottom: 15px;
}
.pr-advanced-search {
    flex-grow: 1;
    padding: 10px;
    border: 1px solid #ddd;
    border-radius: 4px;
    font-size: 16px;
}
.pr-help-button {
    margin-left: 10px;
    width: 40px;
    height: 40px;
    border-radius: 50%;
    background-color: #f0f0f0;
    border: 1px solid #ddd;
    font-size: 18px;
    font-weight: bold;
    cursor: pointer;
}
.pr-search-help-content {
    margin-bottom: 15px;
    padding: 15px;
    background-color: #f8f9fa;
    border: 1px solid #ddd;
    border-radius: 4px;
}
.pr-results-info {
    margin-bottom: 10px;
    font-size: 14px;
    color: #666;
}
.pr-issues-table {
    width: 100%;
    border-collapse: collapse;
    margin-bottom: 20px;
}
.pr-issues-table th, .pr-issues-table td {
    padding: 10px;
    text-align: left;
    border-bottom: 1px solid #ddd;
}
.pr-issues-table th {
    background-color: #f8f9fa;
    font-weight: bold;
    color: #333;
}
.pr-issues-table tr:hover {
    background-color: #f5f5f5;
}
</style>
"@

    return $html
}

# Exporter les fonctions
Export-ModuleMember -Function Add-FilterControls, Add-SortingCapabilities, New-CustomReportView, New-SearchableReport
