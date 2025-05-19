﻿<#
.SYNOPSIS
    Méthodes d'extension pour les collections.

.DESCRIPTION
    Ce script fournit des méthodes d'extension pour les opérations courantes sur les collections.
    Il permet d'effectuer des opérations comme Filter, Map, ForEach, etc. sur différents types de collections.

.NOTES
    Version: 1.0
    Auteur: EMAIL_SENDER_1 Team
    Date de création: 2025-05-20
#>

# Importer les types nécessaires
Add-Type -TypeDefinition @"
using System;
using System.Collections;
using System.Collections.Generic;
using System.Collections.Concurrent;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;

namespace UnifiedParallel.Collections
{
    /// <summary>
    /// Méthodes d'extension pour les collections
    /// </summary>
    public static class CollectionExtensions
    {
        /// <summary>
        /// Applique une fonction à chaque élément de la collection et retourne une nouvelle collection avec les résultats
        /// </summary>
        /// <typeparam name="TSource">Type des éléments de la collection source</typeparam>
        /// <typeparam name="TResult">Type des éléments de la collection résultante</typeparam>
        /// <param name="source">Collection source</param>
        /// <param name="selector">Fonction à appliquer à chaque élément</param>
        /// <returns>Nouvelle collection avec les résultats</returns>
        public static List<TResult> Map<TSource, TResult>(this IEnumerable<TSource> source, Func<TSource, TResult> selector)
        {
            if (source == null)
                throw new ArgumentNullException(nameof(source));
            if (selector == null)
                throw new ArgumentNullException(nameof(selector));

            return source.Select(selector).ToList();
        }

        /// <summary>
        /// Filtre les éléments de la collection selon un prédicat
        /// </summary>
        /// <typeparam name="T">Type des éléments de la collection</typeparam>
        /// <param name="source">Collection source</param>
        /// <param name="predicate">Prédicat pour filtrer les éléments</param>
        /// <returns>Nouvelle collection avec les éléments filtrés</returns>
        public static List<T> Filter<T>(this IEnumerable<T> source, Func<T, bool> predicate)
        {
            if (source == null)
                throw new ArgumentNullException(nameof(source));
            if (predicate == null)
                throw new ArgumentNullException(nameof(predicate));

            return source.Where(predicate).ToList();
        }

        /// <summary>
        /// Applique une action à chaque élément de la collection
        /// </summary>
        /// <typeparam name="T">Type des éléments de la collection</typeparam>
        /// <param name="source">Collection source</param>
        /// <param name="action">Action à appliquer à chaque élément</param>
        public static void ForEach<T>(this IEnumerable<T> source, Action<T> action)
        {
            if (source == null)
                throw new ArgumentNullException(nameof(source));
            if (action == null)
                throw new ArgumentNullException(nameof(action));

            foreach (var item in source)
                action(item);
        }

        /// <summary>
        /// Applique une action à chaque élément de la collection en parallèle
        /// </summary>
        /// <typeparam name="T">Type des éléments de la collection</typeparam>
        /// <param name="source">Collection source</param>
        /// <param name="action">Action à appliquer à chaque élément</param>
        /// <param name="maxDegreeOfParallelism">Nombre maximum de tâches parallèles</param>
        public static void ParallelForEach<T>(this IEnumerable<T> source, Action<T> action, int maxDegreeOfParallelism = -1)
        {
            if (source == null)
                throw new ArgumentNullException(nameof(source));
            if (action == null)
                throw new ArgumentNullException(nameof(action));

            var options = new ParallelOptions();
            if (maxDegreeOfParallelism > 0)
                options.MaxDegreeOfParallelism = maxDegreeOfParallelism;

            Parallel.ForEach(source, options, action);
        }

        /// <summary>
        /// Convertit une collection en ArrayList thread-safe
        /// </summary>
        /// <typeparam name="T">Type des éléments de la collection</typeparam>
        /// <param name="source">Collection source</param>
        /// <returns>ArrayList thread-safe</returns>
        public static ArrayList ToThreadSafeArrayList<T>(this IEnumerable<T> source)
        {
            if (source == null)
                throw new ArgumentNullException(nameof(source));

            ArrayList result = ArrayList.Synchronized(new ArrayList());
            foreach (var item in source)
                result.Add(item);

            return result;
        }

        /// <summary>
        /// Convertit une collection en List<T> thread-safe
        /// </summary>
        /// <typeparam name="T">Type des éléments de la collection</typeparam>
        /// <param name="source">Collection source</param>
        /// <returns>List<T> thread-safe</returns>
        public static List<T> ToThreadSafeList<T>(this IEnumerable<T> source)
        {
            if (source == null)
                throw new ArgumentNullException(nameof(source));

            var result = new List<T>();
            var lockObj = new object();

            foreach (var item in source)
            {
                lock (lockObj)
                {
                    result.Add(item);
                }
            }

            return result;
        }

        /// <summary>
        /// Partitionne une collection en plusieurs sous-collections de taille spécifiée
        /// </summary>
        /// <typeparam name="T">Type des éléments de la collection</typeparam>
        /// <param name="source">Collection source</param>
        /// <param name="size">Taille de chaque partition</param>
        /// <returns>Collection de partitions</returns>
        public static IEnumerable<IEnumerable<T>> Partition<T>(this IEnumerable<T> source, int size)
        {
            if (source == null)
                throw new ArgumentNullException(nameof(source));
            if (size <= 0)
                throw new ArgumentOutOfRangeException(nameof(size), "La taille de la partition doit être supérieure à zéro.");

            var partition = new List<T>(size);
            foreach (var item in source)
            {
                partition.Add(item);
                if (partition.Count == size)
                {
                    yield return partition;
                    partition = new List<T>(size);
                }
            }

            if (partition.Count > 0)
                yield return partition;
        }

        /// <summary>
        /// Convertit une collection en ConcurrentBag<T>
        /// </summary>
        /// <typeparam name="T">Type des éléments de la collection</typeparam>
        /// <param name="source">Collection source</param>
        /// <returns>ConcurrentBag<T></returns>
        public static ConcurrentBag<T> ToConcurrentBag<T>(this IEnumerable<T> source)
        {
            if (source == null)
                throw new ArgumentNullException(nameof(source));

            return new ConcurrentBag<T>(source);
        }

        /// <summary>
        /// Convertit une collection en ConcurrentQueue<T>
        /// </summary>
        /// <typeparam name="T">Type des éléments de la collection</typeparam>
        /// <param name="source">Collection source</param>
        /// <returns>ConcurrentQueue<T></returns>
        public static ConcurrentQueue<T> ToConcurrentQueue<T>(this IEnumerable<T> source)
        {
            if (source == null)
                throw new ArgumentNullException(nameof(source));

            return new ConcurrentQueue<T>(source);
        }

        /// <summary>
        /// Convertit une collection en ConcurrentStack<T>
        /// </summary>
        /// <typeparam name="T">Type des éléments de la collection</typeparam>
        /// <param name="source">Collection source</param>
        /// <returns>ConcurrentStack<T></returns>
        public static ConcurrentStack<T> ToConcurrentStack<T>(this IEnumerable<T> source)
        {
            if (source == null)
                throw new ArgumentNullException(nameof(source));

            return new ConcurrentStack<T>(source);
        }

        /// <summary>
        /// Convertit une collection en BlockingCollection<T>
        /// </summary>
        /// <typeparam name="T">Type des éléments de la collection</typeparam>
        /// <param name="source">Collection source</param>
        /// <param name="boundedCapacity">Capacité maximale de la collection</param>
        /// <returns>BlockingCollection<T></returns>
        public static BlockingCollection<T> ToBlockingCollection<T>(this IEnumerable<T> source, int boundedCapacity = -1)
        {
            if (source == null)
                throw new ArgumentNullException(nameof(source));

            BlockingCollection<T> result;
            if (boundedCapacity > 0)
                result = new BlockingCollection<T>(new ConcurrentBag<T>(), boundedCapacity);
            else
                result = new BlockingCollection<T>(new ConcurrentBag<T>());

            foreach (var item in source)
                result.Add(item);

            result.CompleteAdding();
            return result;
        }
    }
}
"@

# Fonctions d'aide pour utiliser les méthodes d'extension
function Invoke-CollectionMap {
    <#
    .SYNOPSIS
        Applique une fonction à chaque élément d'une collection et retourne une nouvelle collection avec les résultats.

    .DESCRIPTION
        Cette fonction applique une fonction à chaque élément d'une collection et retourne une nouvelle collection avec les résultats.
        Elle utilise la méthode d'extension Map<TSource, TResult> de la classe CollectionExtensions.

    .PARAMETER Collection
        Collection source.

    .PARAMETER ScriptBlock
        Script à appliquer à chaque élément.

    .PARAMETER OutputType
        Type des éléments de la collection résultante. Par défaut, le même type que la collection source.

    .EXAMPLE
        $numbers = @(1, 2, 3, 4, 5)
        $squares = Invoke-CollectionMap -Collection $numbers -ScriptBlock { param($x) $x * $x }
        Applique la fonction de carré à chaque élément de la collection et retourne une nouvelle collection avec les résultats.

    .OUTPUTS
        System.Collections.Generic.List`1
    #>
    [CmdletBinding()]
    [OutputType([System.Collections.Generic.List`1])]
    param(
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true)]
        [object]$Collection,

        [Parameter(Mandatory = $true, Position = 1)]
        [scriptblock]$ScriptBlock,

        [Parameter(Mandatory = $false)]
        [type]$OutputType
    )

    begin {
        $items = @()
    }

    process {
        if ($Collection -is [System.Collections.IEnumerable] -and $Collection -isnot [string]) {
            foreach ($item in $Collection) {
                $items += $item
            }
        } else {
            $items += $Collection
        }
    }

    end {
        # Déterminer le type d'entrée
        $inputType = [object]
        if ($items.Count -gt 0 -and $null -ne $items[0]) {
            $inputType = $items[0].GetType()
        }

        # Déterminer le type de sortie
        if ($null -eq $OutputType) {
            # Exécuter le script sur le premier élément pour déterminer le type de sortie
            if ($items.Count -gt 0) {
                $result = & $ScriptBlock $items[0]
                if ($null -ne $result) {
                    $OutputType = $result.GetType()
                } else {
                    $OutputType = [object]
                }
            } else {
                $OutputType = [object]
            }
        }

        # Créer un délégué Func<TSource, TResult> à partir du scriptblock
        $delegateType = [System.Func``2].MakeGenericType($inputType, $OutputType)
        $delegate = $ScriptBlock.GetDelegate($delegateType)

        # Créer une liste générique du type d'entrée
        $listType = [System.Collections.Generic.List``1].MakeGenericType($inputType)
        $list = [Activator]::CreateInstance($listType)
        foreach ($item in $items) {
            $list.Add($item)
        }

        # Appeler la méthode d'extension Map
        $mapMethod = [UnifiedParallel.Collections.CollectionExtensions].GetMethod("Map").MakeGenericMethod($inputType, $OutputType)
        return $mapMethod.Invoke($null, @($list, $delegate))
    }
}

function Invoke-CollectionFilter {
    <#
    .SYNOPSIS
        Filtre les éléments d'une collection selon un prédicat.

    .DESCRIPTION
        Cette fonction filtre les éléments d'une collection selon un prédicat et retourne une nouvelle collection avec les éléments filtrés.
        Elle utilise la méthode d'extension Filter<T> de la classe CollectionExtensions.

    .PARAMETER Collection
        Collection source.

    .PARAMETER ScriptBlock
        Prédicat pour filtrer les éléments.

    .EXAMPLE
        $numbers = @(1, 2, 3, 4, 5)
        $evens = Invoke-CollectionFilter -Collection $numbers -ScriptBlock { param($x) $x % 2 -eq 0 }
        Filtre les nombres pairs de la collection.

    .OUTPUTS
        System.Collections.Generic.List`1
    #>
    [CmdletBinding()]
    [OutputType([System.Collections.Generic.List`1])]
    param(
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true)]
        [object]$Collection,

        [Parameter(Mandatory = $true, Position = 1)]
        [scriptblock]$ScriptBlock
    )

    begin {
        $items = @()
    }

    process {
        if ($Collection -is [System.Collections.IEnumerable] -and $Collection -isnot [string]) {
            foreach ($item in $Collection) {
                $items += $item
            }
        } else {
            $items += $Collection
        }
    }

    end {
        # Déterminer le type d'entrée
        $inputType = [object]
        if ($items.Count -gt 0 -and $null -ne $items[0]) {
            $inputType = $items[0].GetType()
        }

        # Créer un délégué Func<T, bool> à partir du scriptblock
        $delegateType = [System.Func``2].MakeGenericType($inputType, [bool])
        $delegate = $ScriptBlock.GetDelegate($delegateType)

        # Créer une liste générique du type d'entrée
        $listType = [System.Collections.Generic.List``1].MakeGenericType($inputType)
        $list = [Activator]::CreateInstance($listType)
        foreach ($item in $items) {
            $list.Add($item)
        }

        # Appeler la méthode d'extension Filter
        $filterMethod = [UnifiedParallel.Collections.CollectionExtensions].GetMethod("Filter").MakeGenericMethod($inputType)
        return $filterMethod.Invoke($null, @($list, $delegate))
    }
}

function Invoke-CollectionForEach {
    <#
    .SYNOPSIS
        Applique une action à chaque élément d'une collection.

    .DESCRIPTION
        Cette fonction applique une action à chaque élément d'une collection.
        Elle utilise la méthode d'extension ForEach<T> de la classe CollectionExtensions.

    .PARAMETER Collection
        Collection source.

    .PARAMETER ScriptBlock
        Action à appliquer à chaque élément.

    .EXAMPLE
        $numbers = @(1, 2, 3, 4, 5)
        Invoke-CollectionForEach -Collection $numbers -ScriptBlock { param($x) Write-Host $x }
        Affiche chaque élément de la collection.

    .OUTPUTS
        None
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true)]
        [object]$Collection,

        [Parameter(Mandatory = $true, Position = 1)]
        [scriptblock]$ScriptBlock
    )

    begin {
        $items = @()
    }

    process {
        if ($Collection -is [System.Collections.IEnumerable] -and $Collection -isnot [string]) {
            foreach ($item in $Collection) {
                $items += $item
            }
        } else {
            $items += $Collection
        }
    }

    end {
        # Déterminer le type d'entrée
        $inputType = [object]
        if ($items.Count -gt 0 -and $null -ne $items[0]) {
            $inputType = $items[0].GetType()
        }

        # Créer un délégué Action<T> à partir du scriptblock
        $delegateType = [System.Action``1].MakeGenericType($inputType)
        $delegate = $ScriptBlock.GetDelegate($delegateType)

        # Créer une liste générique du type d'entrée
        $listType = [System.Collections.Generic.List``1].MakeGenericType($inputType)
        $list = [Activator]::CreateInstance($listType)
        foreach ($item in $items) {
            $list.Add($item)
        }

        # Appeler la méthode d'extension ForEach
        $forEachMethod = [UnifiedParallel.Collections.CollectionExtensions].GetMethod("ForEach").MakeGenericMethod($inputType)
        $forEachMethod.Invoke($null, @($list, $delegate))
    }
}

function Invoke-CollectionParallelForEach {
    <#
    .SYNOPSIS
        Applique une action à chaque élément d'une collection en parallèle.

    .DESCRIPTION
        Cette fonction applique une action à chaque élément d'une collection en parallèle.
        Elle utilise la méthode d'extension ParallelForEach<T> de la classe CollectionExtensions.

    .PARAMETER Collection
        Collection source.

    .PARAMETER ScriptBlock
        Action à appliquer à chaque élément.

    .PARAMETER MaxDegreeOfParallelism
        Nombre maximum de tâches parallèles. Par défaut, utilise tous les processeurs disponibles.

    .EXAMPLE
        $numbers = @(1, 2, 3, 4, 5)
        Invoke-CollectionParallelForEach -Collection $numbers -ScriptBlock { param($x) Write-Host $x }
        Affiche chaque élément de la collection en parallèle.

    .OUTPUTS
        None
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true)]
        [object]$Collection,

        [Parameter(Mandatory = $true, Position = 1)]
        [scriptblock]$ScriptBlock,

        [Parameter(Mandatory = $false)]
        [int]$MaxDegreeOfParallelism = -1
    )

    begin {
        $items = @()
    }

    process {
        if ($Collection -is [System.Collections.IEnumerable] -and $Collection -isnot [string]) {
            foreach ($item in $Collection) {
                $items += $item
            }
        } else {
            $items += $Collection
        }
    }

    end {
        # Déterminer le type d'entrée
        $inputType = [object]
        if ($items.Count -gt 0 -and $null -ne $items[0]) {
            $inputType = $items[0].GetType()
        }

        # Créer un délégué Action<T> à partir du scriptblock
        $delegateType = [System.Action``1].MakeGenericType($inputType)
        $delegate = $ScriptBlock.GetDelegate($delegateType)

        # Créer une liste générique du type d'entrée
        $listType = [System.Collections.Generic.List``1].MakeGenericType($inputType)
        $list = [Activator]::CreateInstance($listType)
        foreach ($item in $items) {
            $list.Add($item)
        }

        # Appeler la méthode d'extension ParallelForEach
        $parallelForEachMethod = [UnifiedParallel.Collections.CollectionExtensions].GetMethod("ParallelForEach").MakeGenericMethod($inputType)
        $parallelForEachMethod.Invoke($null, @($list, $delegate, $MaxDegreeOfParallelism))
    }
}

function Invoke-CollectionPartition {
    <#
    .SYNOPSIS
        Partitionne une collection en plusieurs sous-collections de taille spécifiée.

    .DESCRIPTION
        Cette fonction partitionne une collection en plusieurs sous-collections de taille spécifiée.
        Elle utilise la méthode d'extension Partition<T> de la classe CollectionExtensions.

    .PARAMETER Collection
        Collection source.

    .PARAMETER Size
        Taille de chaque partition.

    .EXAMPLE
        $numbers = @(1, 2, 3, 4, 5, 6, 7, 8, 9, 10)
        $partitions = Invoke-CollectionPartition -Collection $numbers -Size 3
        Partitionne la collection en sous-collections de taille 3.

    .OUTPUTS
        System.Collections.Generic.IEnumerable`1
    #>
    [CmdletBinding()]
    [OutputType([System.Collections.Generic.IEnumerable`1])]
    param(
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true)]
        [object]$Collection,

        [Parameter(Mandatory = $true, Position = 1)]
        [int]$Size
    )

    begin {
        $items = @()
    }

    process {
        if ($Collection -is [System.Collections.IEnumerable] -and $Collection -isnot [string]) {
            foreach ($item in $Collection) {
                $items += $item
            }
        } else {
            $items += $Collection
        }
    }

    end {
        # Déterminer le type d'entrée
        $inputType = [object]
        if ($items.Count -gt 0 -and $null -ne $items[0]) {
            $inputType = $items[0].GetType()
        }

        # Créer une liste générique du type d'entrée
        $listType = [System.Collections.Generic.List``1].MakeGenericType($inputType)
        $list = [Activator]::CreateInstance($listType)
        foreach ($item in $items) {
            $list.Add($item)
        }

        # Appeler la méthode d'extension Partition
        $partitionMethod = [UnifiedParallel.Collections.CollectionExtensions].GetMethod("Partition").MakeGenericMethod($inputType)
        return $partitionMethod.Invoke($null, @($list, $Size))
    }
}

function ConvertTo-ThreadSafeCollection {
    <#
    .SYNOPSIS
        Convertit une collection en collection thread-safe.

    .DESCRIPTION
        Cette fonction convertit une collection en collection thread-safe.
        Elle utilise les méthodes d'extension de la classe CollectionExtensions.

    .PARAMETER Collection
        Collection source.

    .PARAMETER Type
        Type de collection thread-safe à créer. Valeurs possibles : ArrayList, List, ConcurrentBag, ConcurrentQueue, ConcurrentStack, BlockingCollection.

    .PARAMETER BoundedCapacity
        Capacité maximale de la collection. Applicable uniquement pour BlockingCollection.

    .EXAMPLE
        $numbers = @(1, 2, 3, 4, 5)
        $threadSafeList = ConvertTo-ThreadSafeCollection -Collection $numbers -Type List
        Convertit la collection en List<T> thread-safe.

    .OUTPUTS
        Object
    #>
    [CmdletBinding()]
    [OutputType([object])]
    param(
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true)]
        [object]$Collection,

        [Parameter(Mandatory = $true, Position = 1)]
        [ValidateSet("ArrayList", "List", "ConcurrentBag", "ConcurrentQueue", "ConcurrentStack", "BlockingCollection")]
        [string]$Type,

        [Parameter(Mandatory = $false)]
        [int]$BoundedCapacity = -1
    )

    begin {
        $items = @()
    }

    process {
        if ($Collection -is [System.Collections.IEnumerable] -and $Collection -isnot [string]) {
            foreach ($item in $Collection) {
                $items += $item
            }
        } else {
            $items += $Collection
        }
    }

    end {
        # Déterminer le type d'entrée
        $inputType = [object]
        if ($items.Count -gt 0 -and $null -ne $items[0]) {
            $inputType = $items[0].GetType()
        }

        # Créer une liste générique du type d'entrée
        $listType = [System.Collections.Generic.List``1].MakeGenericType($inputType)
        $list = [Activator]::CreateInstance($listType)
        foreach ($item in $items) {
            $list.Add($item)
        }

        # Convertir en collection thread-safe
        switch ($Type) {
            "ArrayList" {
                $method = [UnifiedParallel.Collections.CollectionExtensions].GetMethod("ToThreadSafeArrayList").MakeGenericMethod($inputType)
                return $method.Invoke($null, @($list))
            }
            "List" {
                $method = [UnifiedParallel.Collections.CollectionExtensions].GetMethod("ToThreadSafeList").MakeGenericMethod($inputType)
                return $method.Invoke($null, @($list))
            }
            "ConcurrentBag" {
                $method = [UnifiedParallel.Collections.CollectionExtensions].GetMethod("ToConcurrentBag").MakeGenericMethod($inputType)
                return $method.Invoke($null, @($list))
            }
            "ConcurrentQueue" {
                $method = [UnifiedParallel.Collections.CollectionExtensions].GetMethod("ToConcurrentQueue").MakeGenericMethod($inputType)
                return $method.Invoke($null, @($list))
            }
            "ConcurrentStack" {
                $method = [UnifiedParallel.Collections.CollectionExtensions].GetMethod("ToConcurrentStack").MakeGenericMethod($inputType)
                return $method.Invoke($null, @($list))
            }
            "BlockingCollection" {
                $method = [UnifiedParallel.Collections.CollectionExtensions].GetMethod("ToBlockingCollection").MakeGenericMethod($inputType)
                return $method.Invoke($null, @($list, $BoundedCapacity))
            }
        }
    }
}
