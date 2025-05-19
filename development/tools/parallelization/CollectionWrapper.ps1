﻿
<#
.SYNOPSIS
    Classe wrapper pour différents types de collections.

.DESCRIPTION
    Cette classe fournit une interface commune pour différents types de collections
    (ArrayList, List<T>, Array, ConcurrentBag<T>, etc.) et facilite les conversions
    entre ces différents types.

.NOTES
    Version: 1.0
    Auteur: EMAIL_SENDER_1 Team
    Date de création: 2025-05-20
#>

# Définir les types de collections supportés
Add-Type -TypeDefinition @"
using System;
using System.Collections;
using System.Collections.Generic;
using System.Collections.Concurrent;
using System.Linq;

namespace UnifiedParallel.Collections
{
    /// <summary>
    /// Types de collections supportés par CollectionWrapper
    /// </summary>
    public enum CollectionType
    {
        ArrayList,
        List,
        Array,
        ConcurrentBag,
        ConcurrentQueue,
        ConcurrentStack,
        ConcurrentDictionary,
        Queue,
        Stack,
        HashSet,
        Dictionary,
        Custom
    }

    /// <summary>
    /// Interface commune pour les wrappers de collections
    /// </summary>
    public interface ICollectionWrapper
    {
        /// <summary>
        /// Type de la collection encapsulée
        /// </summary>
        CollectionType Type { get; }

        /// <summary>
        /// Nombre d'éléments dans la collection
        /// </summary>
        int Count { get; }

        /// <summary>
        /// Indique si la collection est thread-safe
        /// </summary>
        bool IsThreadSafe { get; }

        /// <summary>
        /// Indique si la collection est en lecture seule
        /// </summary>
        bool IsReadOnly { get; }

        /// <summary>
        /// Obtient la collection sous-jacente
        /// </summary>
        object GetUnderlyingCollection();

        /// <summary>
        /// Convertit la collection en ArrayList
        /// </summary>
        ArrayList ToArrayList();

        /// <summary>
        /// Convertit la collection en tableau
        /// </summary>
        Array ToArray();

        /// <summary>
        /// Efface tous les éléments de la collection
        /// </summary>
        void Clear();
    }

    /// <summary>
    /// Wrapper générique pour les collections
    /// </summary>
    /// <typeparam name="T">Type des éléments de la collection</typeparam>
    public class CollectionWrapper<T> : ICollectionWrapper
    {
        private object _collection;
        private CollectionType _type;
        private bool _isThreadSafe;
        private bool _isReadOnly;

        /// <summary>
        /// Constructeur par défaut - crée une List<T> vide
        /// </summary>
        public CollectionWrapper()
        {
            _collection = new List<T>();
            _type = CollectionType.List;
            _isThreadSafe = false;
            _isReadOnly = false;
        }

        /// <summary>
        /// Constructeur avec capacité initiale - crée une List<T> avec la capacité spécifiée
        /// </summary>
        /// <param name="capacity">Capacité initiale de la collection</param>
        public CollectionWrapper(int capacity)
        {
            _collection = new List<T>(capacity);
            _type = CollectionType.List;
            _isThreadSafe = false;
            _isReadOnly = false;
        }

        /// <summary>
        /// Constructeur avec collection existante
        /// </summary>
        /// <param name="collection">Collection à encapsuler</param>
        public CollectionWrapper(object collection)
        {
            if (collection == null)
                throw new ArgumentNullException(nameof(collection));

            _collection = collection;
            DetermineCollectionType();
        }

        /// <summary>
        /// Constructeur avec type de collection spécifié
        /// </summary>
        /// <param name="collectionType">Type de collection à créer</param>
        /// <param name="capacity">Capacité initiale (optionnelle)</param>
        public CollectionWrapper(CollectionType collectionType, int capacity = 0)
        {
            _type = collectionType;
            _collection = CreateCollection(collectionType, capacity);
            DetermineThreadSafety();
            DetermineReadOnly();
        }

        /// <summary>
        /// Type de la collection encapsulée
        /// </summary>
        public CollectionType Type => _type;

        /// <summary>
        /// Nombre d'éléments dans la collection
        /// </summary>
        public int Count
        {
            get
            {
                switch (_type)
                {
                    case CollectionType.ArrayList:
                        return ((ArrayList)_collection).Count;
                    case CollectionType.List:
                        return ((List<T>)_collection).Count;
                    case CollectionType.Array:
                        return ((Array)_collection).Length;
                    case CollectionType.ConcurrentBag:
                        return ((ConcurrentBag<T>)_collection).Count;
                    case CollectionType.ConcurrentQueue:
                        return ((ConcurrentQueue<T>)_collection).Count;
                    case CollectionType.ConcurrentStack:
                        return ((ConcurrentStack<T>)_collection).Count;
                    case CollectionType.ConcurrentDictionary:
                        return ((ConcurrentDictionary<string, T>)_collection).Count;
                    case CollectionType.Queue:
                        return ((Queue<T>)_collection).Count;
                    case CollectionType.Stack:
                        return ((Stack<T>)_collection).Count;
                    case CollectionType.HashSet:
                        return ((HashSet<T>)_collection).Count;
                    case CollectionType.Dictionary:
                        return ((Dictionary<string, T>)_collection).Count;
                    case CollectionType.Custom:
                        if (_collection is ICollection collection)
                            return collection.Count;
                        if (_collection is ICollection<T> genericCollection)
                            return genericCollection.Count;
                        throw new InvalidOperationException("La collection personnalisée ne supporte pas le comptage d'éléments.");
                    default:
                        throw new NotSupportedException($"Type de collection non supporté: {_type}");
                }
            }
        }

        /// <summary>
        /// Indique si la collection est thread-safe
        /// </summary>
        public bool IsThreadSafe => _isThreadSafe;

        /// <summary>
        /// Indique si la collection est en lecture seule
        /// </summary>
        public bool IsReadOnly => _isReadOnly;

        /// <summary>
        /// Obtient la collection sous-jacente
        /// </summary>
        public object GetUnderlyingCollection()
        {
            return _collection;
        }

        /// <summary>
        /// Ajoute un élément à la collection
        /// </summary>
        /// <param name="item">Élément à ajouter</param>
        public void Add(T item)
        {
            if (_isReadOnly)
                throw new InvalidOperationException("La collection est en lecture seule.");

            switch (_type)
            {
                case CollectionType.ArrayList:
                    ((ArrayList)_collection).Add(item);
                    break;
                case CollectionType.List:
                    ((List<T>)_collection).Add(item);
                    break;
                case CollectionType.Array:
                    throw new InvalidOperationException("Impossible d'ajouter des éléments à un tableau fixe.");
                case CollectionType.ConcurrentBag:
                    ((ConcurrentBag<T>)_collection).Add(item);
                    break;
                case CollectionType.ConcurrentQueue:
                    ((ConcurrentQueue<T>)_collection).Enqueue(item);
                    break;
                case CollectionType.ConcurrentStack:
                    ((ConcurrentStack<T>)_collection).Push(item);
                    break;
                case CollectionType.Queue:
                    ((Queue<T>)_collection).Enqueue(item);
                    break;
                case CollectionType.Stack:
                    ((Stack<T>)_collection).Push(item);
                    break;
                case CollectionType.HashSet:
                    ((HashSet<T>)_collection).Add(item);
                    break;
                case CollectionType.Custom:
                    if (_collection is ICollection<T> genericCollection)
                    {
                        genericCollection.Add(item);
                        break;
                    }
                    throw new InvalidOperationException("La collection personnalisée ne supporte pas l'ajout d'éléments.");
                default:
                    throw new NotSupportedException($"Type de collection non supporté: {_type}");
            }
        }

        /// <summary>
        /// Ajoute une plage d'éléments à la collection
        /// </summary>
        /// <param name="items">Éléments à ajouter</param>
        public void AddRange(IEnumerable<T> items)
        {
            if (_isReadOnly)
                throw new InvalidOperationException("La collection est en lecture seule.");

            if (items == null)
                throw new ArgumentNullException(nameof(items));

            switch (_type)
            {
                case CollectionType.ArrayList:
                    ((ArrayList)_collection).AddRange(items.Cast<object>().ToArray());
                    break;
                case CollectionType.List:
                    ((List<T>)_collection).AddRange(items);
                    break;
                case CollectionType.Array:
                    throw new InvalidOperationException("Impossible d'ajouter des éléments à un tableau fixe.");
                case CollectionType.ConcurrentBag:
                    foreach (var item in items)
                        ((ConcurrentBag<T>)_collection).Add(item);
                    break;
                case CollectionType.ConcurrentQueue:
                    foreach (var item in items)
                        ((ConcurrentQueue<T>)_collection).Enqueue(item);
                    break;
                case CollectionType.ConcurrentStack:
                    foreach (var item in items)
                        ((ConcurrentStack<T>)_collection).Push(item);
                    break;
                case CollectionType.Queue:
                    foreach (var item in items)
                        ((Queue<T>)_collection).Enqueue(item);
                    break;
                case CollectionType.Stack:
                    foreach (var item in items)
                        ((Stack<T>)_collection).Push(item);
                    break;
                case CollectionType.HashSet:
                    ((HashSet<T>)_collection).UnionWith(items);
                    break;
                case CollectionType.Custom:
                    if (_collection is ICollection<T> genericCollection)
                    {
                        foreach (var item in items)
                            genericCollection.Add(item);
                        break;
                    }
                    throw new InvalidOperationException("La collection personnalisée ne supporte pas l'ajout d'éléments.");
                default:
                    throw new NotSupportedException($"Type de collection non supporté: {_type}");
            }
        }

        /// <summary>
        /// Efface tous les éléments de la collection
        /// </summary>
        public void Clear()
        {
            if (_isReadOnly)
                throw new InvalidOperationException("La collection est en lecture seule.");

            switch (_type)
            {
                case CollectionType.ArrayList:
                    ((ArrayList)_collection).Clear();
                    break;
                case CollectionType.List:
                    ((List<T>)_collection).Clear();
                    break;
                case CollectionType.Array:
                    Array.Clear((Array)_collection, 0, ((Array)_collection).Length);
                    break;
                case CollectionType.ConcurrentBag:
                    while (((ConcurrentBag<T>)_collection).TryTake(out _)) { }
                    break;
                case CollectionType.ConcurrentQueue:
                    while (((ConcurrentQueue<T>)_collection).TryDequeue(out _)) { }
                    break;
                case CollectionType.ConcurrentStack:
                    while (((ConcurrentStack<T>)_collection).TryPop(out _)) { }
                    break;
                case CollectionType.ConcurrentDictionary:
                    ((ConcurrentDictionary<string, T>)_collection).Clear();
                    break;
                case CollectionType.Queue:
                    ((Queue<T>)_collection).Clear();
                    break;
                case CollectionType.Stack:
                    ((Stack<T>)_collection).Clear();
                    break;
                case CollectionType.HashSet:
                    ((HashSet<T>)_collection).Clear();
                    break;
                case CollectionType.Dictionary:
                    ((Dictionary<string, T>)_collection).Clear();
                    break;
                case CollectionType.Custom:
                    if (_collection is ICollection collection)
                    {
                        if (collection is IList list)
                        {
                            list.Clear();
                            break;
                        }
                    }
                    throw new InvalidOperationException("La collection personnalisée ne supporte pas l'effacement d'éléments.");
                default:
                    throw new NotSupportedException($"Type de collection non supporté: {_type}");
            }
        }

        /// <summary>
        /// Convertit la collection en ArrayList
        /// </summary>
        public ArrayList ToArrayList()
        {
            ArrayList result = new ArrayList();

            switch (_type)
            {
                case CollectionType.ArrayList:
                    return (ArrayList)_collection;
                case CollectionType.List:
                    result.AddRange(((List<T>)_collection).ToArray());
                    break;
                case CollectionType.Array:
                    result.AddRange((Array)_collection);
                    break;
                case CollectionType.ConcurrentBag:
                    foreach (var item in ((ConcurrentBag<T>)_collection))
                        result.Add(item);
                    break;
                case CollectionType.ConcurrentQueue:
                    foreach (var item in ((ConcurrentQueue<T>)_collection))
                        result.Add(item);
                    break;
                case CollectionType.ConcurrentStack:
                    foreach (var item in ((ConcurrentStack<T>)_collection))
                        result.Add(item);
                    break;
                case CollectionType.ConcurrentDictionary:
                    foreach (var item in ((ConcurrentDictionary<string, T>)_collection))
                        result.Add(item.Value);
                    break;
                case CollectionType.Queue:
                    foreach (var item in ((Queue<T>)_collection))
                        result.Add(item);
                    break;
                case CollectionType.Stack:
                    foreach (var item in ((Stack<T>)_collection))
                        result.Add(item);
                    break;
                case CollectionType.HashSet:
                    foreach (var item in ((HashSet<T>)_collection))
                        result.Add(item);
                    break;
                case CollectionType.Dictionary:
                    foreach (var item in ((Dictionary<string, T>)_collection))
                        result.Add(item.Value);
                    break;
                case CollectionType.Custom:
                    if (_collection is IEnumerable enumerable)
                    {
                        foreach (var item in enumerable)
                            result.Add(item);
                        break;
                    }
                    throw new InvalidOperationException("La collection personnalisée ne peut pas être convertie en ArrayList.");
                default:
                    throw new NotSupportedException($"Type de collection non supporté: {_type}");
            }

            return result;
        }

        /// <summary>
        /// Convertit la collection en tableau
        /// </summary>
        public Array ToArray()
        {
            switch (_type)
            {
                case CollectionType.ArrayList:
                    return ((ArrayList)_collection).ToArray(typeof(T));
                case CollectionType.List:
                    return ((List<T>)_collection).ToArray();
                case CollectionType.Array:
                    return (Array)_collection;
                case CollectionType.ConcurrentBag:
                    return ((ConcurrentBag<T>)_collection).ToArray();
                case CollectionType.ConcurrentQueue:
                    return ((ConcurrentQueue<T>)_collection).ToArray();
                case CollectionType.ConcurrentStack:
                    return ((ConcurrentStack<T>)_collection).ToArray();
                case CollectionType.ConcurrentDictionary:
                    return ((ConcurrentDictionary<string, T>)_collection).Values.ToArray();
                case CollectionType.Queue:
                    return ((Queue<T>)_collection).ToArray();
                case CollectionType.Stack:
                    return ((Stack<T>)_collection).ToArray();
                case CollectionType.HashSet:
                    return ((HashSet<T>)_collection).ToArray();
                case CollectionType.Dictionary:
                    return ((Dictionary<string, T>)_collection).Values.ToArray();
                case CollectionType.Custom:
                    if (_collection is IEnumerable<T> genericEnumerable)
                        return genericEnumerable.ToArray();
                    if (_collection is IEnumerable enumerable)
                        return enumerable.Cast<T>().ToArray();
                    throw new InvalidOperationException("La collection personnalisée ne peut pas être convertie en tableau.");
                default:
                    throw new NotSupportedException($"Type de collection non supporté: {_type}");
            }
        }

        /// <summary>
        /// Convertit la collection en List<T>
        /// </summary>
        public List<T> ToList()
        {
            switch (_type)
            {
                case CollectionType.ArrayList:
                    return ((ArrayList)_collection).Cast<T>().ToList();
                case CollectionType.List:
                    return new List<T>((List<T>)_collection);
                case CollectionType.Array:
                    return ((Array)_collection).Cast<T>().ToList();
                case CollectionType.ConcurrentBag:
                    return ((ConcurrentBag<T>)_collection).ToList();
                case CollectionType.ConcurrentQueue:
                    return ((ConcurrentQueue<T>)_collection).ToList();
                case CollectionType.ConcurrentStack:
                    return ((ConcurrentStack<T>)_collection).ToList();
                case CollectionType.ConcurrentDictionary:
                    return ((ConcurrentDictionary<string, T>)_collection).Values.ToList();
                case CollectionType.Queue:
                    return ((Queue<T>)_collection).ToList();
                case CollectionType.Stack:
                    return ((Stack<T>)_collection).ToList();
                case CollectionType.HashSet:
                    return ((HashSet<T>)_collection).ToList();
                case CollectionType.Dictionary:
                    return ((Dictionary<string, T>)_collection).Values.ToList();
                case CollectionType.Custom:
                    if (_collection is IEnumerable<T> genericEnumerable)
                        return genericEnumerable.ToList();
                    if (_collection is IEnumerable enumerable)
                        return enumerable.Cast<T>().ToList();
                    throw new InvalidOperationException("La collection personnalisée ne peut pas être convertie en List<T>.");
                default:
                    throw new NotSupportedException($"Type de collection non supporté: {_type}");
            }
        }

        /// <summary>
        /// Convertit la collection en ConcurrentBag<T>
        /// </summary>
        public ConcurrentBag<T> ToConcurrentBag()
        {
            ConcurrentBag<T> result = new ConcurrentBag<T>();

            switch (_type)
            {
                case CollectionType.ArrayList:
                    foreach (var item in ((ArrayList)_collection))
                        result.Add((T)item);
                    break;
                case CollectionType.List:
                    foreach (var item in ((List<T>)_collection))
                        result.Add(item);
                    break;
                case CollectionType.Array:
                    foreach (var item in ((Array)_collection))
                        result.Add((T)item);
                    break;
                case CollectionType.ConcurrentBag:
                    return new ConcurrentBag<T>(((ConcurrentBag<T>)_collection));
                case CollectionType.ConcurrentQueue:
                    foreach (var item in ((ConcurrentQueue<T>)_collection))
                        result.Add(item);
                    break;
                case CollectionType.ConcurrentStack:
                    foreach (var item in ((ConcurrentStack<T>)_collection))
                        result.Add(item);
                    break;
                case CollectionType.ConcurrentDictionary:
                    foreach (var item in ((ConcurrentDictionary<string, T>)_collection))
                        result.Add(item.Value);
                    break;
                case CollectionType.Queue:
                    foreach (var item in ((Queue<T>)_collection))
                        result.Add(item);
                    break;
                case CollectionType.Stack:
                    foreach (var item in ((Stack<T>)_collection))
                        result.Add(item);
                    break;
                case CollectionType.HashSet:
                    foreach (var item in ((HashSet<T>)_collection))
                        result.Add(item);
                    break;
                case CollectionType.Dictionary:
                    foreach (var item in ((Dictionary<string, T>)_collection))
                        result.Add(item.Value);
                    break;
                case CollectionType.Custom:
                    if (_collection is IEnumerable<T> genericEnumerable)
                    {
                        foreach (var item in genericEnumerable)
                            result.Add(item);
                        break;
                    }
                    if (_collection is IEnumerable enumerable)
                    {
                        foreach (var item in enumerable)
                            result.Add((T)item);
                        break;
                    }
                    throw new InvalidOperationException("La collection personnalisée ne peut pas être convertie en ConcurrentBag<T>.");
                default:
                    throw new NotSupportedException($"Type de collection non supporté: {_type}");
            }

            return result;
        }

        /// <summary>
        /// Détermine le type de la collection encapsulée
        /// </summary>
        private void DetermineCollectionType()
        {
            if (_collection is ArrayList)
            {
                _type = CollectionType.ArrayList;
                _isThreadSafe = false;
                _isReadOnly = false;
            }
            else if (_collection is List<T>)
            {
                _type = CollectionType.List;
                _isThreadSafe = false;
                _isReadOnly = false;
            }
            else if (_collection is Array)
            {
                _type = CollectionType.Array;
                _isThreadSafe = false;
                _isReadOnly = ((Array)_collection).IsReadOnly;
            }
            else if (_collection is ConcurrentBag<T>)
            {
                _type = CollectionType.ConcurrentBag;
                _isThreadSafe = true;
                _isReadOnly = false;
            }
            else if (_collection is ConcurrentQueue<T>)
            {
                _type = CollectionType.ConcurrentQueue;
                _isThreadSafe = true;
                _isReadOnly = false;
            }
            else if (_collection is ConcurrentStack<T>)
            {
                _type = CollectionType.ConcurrentStack;
                _isThreadSafe = true;
                _isReadOnly = false;
            }
            else if (_collection is ConcurrentDictionary<string, T>)
            {
                _type = CollectionType.ConcurrentDictionary;
                _isThreadSafe = true;
                _isReadOnly = false;
            }
            else if (_collection is Queue<T>)
            {
                _type = CollectionType.Queue;
                _isThreadSafe = false;
                _isReadOnly = false;
            }
            else if (_collection is Stack<T>)
            {
                _type = CollectionType.Stack;
                _isThreadSafe = false;
                _isReadOnly = false;
            }
            else if (_collection is HashSet<T>)
            {
                _type = CollectionType.HashSet;
                _isThreadSafe = false;
                _isReadOnly = false;
            }
            else if (_collection is Dictionary<string, T>)
            {
                _type = CollectionType.Dictionary;
                _isThreadSafe = false;
                _isReadOnly = false;
            }
            else
            {
                _type = CollectionType.Custom;
                DetermineThreadSafety();
                DetermineReadOnly();
            }
        }

        /// <summary>
        /// Détermine si la collection est thread-safe
        /// </summary>
        private void DetermineThreadSafety()
        {
            // Les collections du namespace System.Collections.Concurrent sont thread-safe
            _isThreadSafe = _collection.GetType().Namespace == "System.Collections.Concurrent";
        }

        /// <summary>
        /// Détermine si la collection est en lecture seule
        /// </summary>
        private void DetermineReadOnly()
        {
            if (_collection is System.Collections.Generic.ICollection<T> genericCollection)
                _isReadOnly = genericCollection.IsReadOnly;
            else if (_collection is System.Collections.ObjectModel.ReadOnlyCollection<T>)
                _isReadOnly = true;
            else
                _isReadOnly = false;
        }

        /// <summary>
        /// Crée une collection du type spécifié
        /// </summary>
        /// <param name="collectionType">Type de collection à créer</param>
        /// <param name="capacity">Capacité initiale (optionnelle)</param>
        /// <returns>La collection créée</returns>
        private object CreateCollection(CollectionType collectionType, int capacity)
        {
            switch (collectionType)
            {
                case CollectionType.ArrayList:
                    return capacity > 0 ? new ArrayList(capacity) : new ArrayList();
                case CollectionType.List:
                    return capacity > 0 ? new List<T>(capacity) : new List<T>();
                case CollectionType.Array:
                    return capacity > 0 ? new T[capacity] : new T[0];
                case CollectionType.ConcurrentBag:
                    return new ConcurrentBag<T>();
                case CollectionType.ConcurrentQueue:
                    return new ConcurrentQueue<T>();
                case CollectionType.ConcurrentStack:
                    return new ConcurrentStack<T>();
                case CollectionType.ConcurrentDictionary:
                    return new ConcurrentDictionary<string, T>();
                case CollectionType.Queue:
                    return capacity > 0 ? new Queue<T>(capacity) : new Queue<T>();
                case CollectionType.Stack:
                    return capacity > 0 ? new Stack<T>(capacity) : new Stack<T>();
                case CollectionType.HashSet:
                    return capacity > 0 ? new HashSet<T>(capacity) : new HashSet<T>();
                case CollectionType.Dictionary:
                    return capacity > 0 ? new Dictionary<string, T>(capacity) : new Dictionary<string, T>();
                default:
                    throw new NotSupportedException($"Type de collection non supporté: {collectionType}");
            }
        }
    }
}
"@

# Fonctions d'aide pour utiliser CollectionWrapper
function New-CollectionWrapper {
    <#
    .SYNOPSIS
        Crée un nouveau wrapper de collection.

    .DESCRIPTION
        Cette fonction crée un nouveau wrapper de collection qui encapsule différents types de collections
        et fournit une interface commune pour les manipuler.

    .PARAMETER CollectionType
        Type de collection à créer. Valeurs possibles : ArrayList, List, Array, ConcurrentBag,
        ConcurrentQueue, ConcurrentStack, ConcurrentDictionary, Queue, Stack, HashSet, Dictionary, Custom.

    .PARAMETER Collection
        Collection existante à encapsuler. Si spécifié, le paramètre CollectionType est ignoré.

    .PARAMETER Capacity
        Capacité initiale de la collection. Applicable uniquement pour certains types de collections.

    .PARAMETER ElementType
        Type des éléments de la collection. Par défaut, object.

    .EXAMPLE
        $wrapper = New-CollectionWrapper -CollectionType List
        Crée un wrapper pour une nouvelle List<object>.

    .EXAMPLE
        $wrapper = New-CollectionWrapper -CollectionType ConcurrentBag -ElementType ([string])
        Crée un wrapper pour une nouvelle ConcurrentBag<string>.

    .EXAMPLE
        $list = [System.Collections.Generic.List[int]]::new()
        $wrapper = New-CollectionWrapper -Collection $list
        Crée un wrapper pour une List<int> existante.

    .OUTPUTS
        UnifiedParallel.Collections.CollectionWrapper`1
    #>
    [CmdletBinding()]
    [OutputType([object])]
    param(
        [Parameter(Mandatory = $false, Position = 0)]
        [ValidateSet("ArrayList", "List", "Array", "ConcurrentBag", "ConcurrentQueue", "ConcurrentStack",
            "ConcurrentDictionary", "Queue", "Stack", "HashSet", "Dictionary", "Custom")]
        [string]$CollectionType = "List",

        [Parameter(Mandatory = $false, Position = 1)]
        [object]$Collection,

        [Parameter(Mandatory = $false)]
        [int]$Capacity = 0,

        [Parameter(Mandatory = $false)]
        [type]$ElementType = [object]
    )

    # Si une collection est spécifiée, l'encapsuler directement
    if ($null -ne $Collection) {
        $wrapperType = [Type]::GetType("UnifiedParallel.Collections.CollectionWrapper``1").MakeGenericType($ElementType)
        return [Activator]::CreateInstance($wrapperType, @($Collection))
    }

    # Sinon, créer une nouvelle collection du type spécifié
    $enumType = [UnifiedParallel.Collections.CollectionType]
    $collectionTypeEnum = [Enum]::Parse($enumType, $CollectionType)

    $wrapperType = [Type]::GetType("UnifiedParallel.Collections.CollectionWrapper``1").MakeGenericType($ElementType)
    return [Activator]::CreateInstance($wrapperType, @($collectionTypeEnum, $Capacity))
}

function ConvertTo-ArrayList {
    <#
    .SYNOPSIS
        Convertit une collection en ArrayList.

    .DESCRIPTION
        Cette fonction convertit une collection en System.Collections.ArrayList.
        Elle accepte différents types de collections en entrée et effectue la conversion appropriée.

    .PARAMETER Collection
        Collection à convertir en ArrayList.

    .PARAMETER UseWrapper
        Indique si la conversion doit utiliser CollectionWrapper pour optimiser les performances.
        Par défaut, la valeur est $true.

    .EXAMPLE
        $list = [System.Collections.Generic.List[int]]::new()
        $list.Add(1)
        $list.Add(2)
        $arrayList = ConvertTo-ArrayList -Collection $list
        Convertit une List<int> en ArrayList.

    .OUTPUTS
        System.Collections.ArrayList
    #>
    [CmdletBinding()]
    [OutputType([System.Collections.ArrayList])]
    param(
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true)]
        [object]$Collection,

        [Parameter(Mandatory = $false)]
        [switch]$UseWrapper = $true
    )

    process {
        if ($null -eq $Collection) {
            return (New-Object System.Collections.ArrayList)
        }

        if ($UseWrapper) {
            # Déterminer le type d'élément
            $elementType = [object]
            if ($Collection -is [System.Collections.Generic.IEnumerable`1]) {
                $genericType = $Collection.GetType().GetGenericArguments()[0]
                if ($null -ne $genericType) {
                    $elementType = $genericType
                }
            }

            # Utiliser CollectionWrapper pour la conversion
            $wrapper = New-CollectionWrapper -Collection $Collection -ElementType $elementType
            return $wrapper.ToArrayList()
        } else {
            # Conversion manuelle
            $result = New-Object System.Collections.ArrayList

            # Traiter différents types de collections
            if ($Collection -is [System.Collections.ArrayList]) {
                return $Collection
            } elseif ($Collection -is [System.Collections.IEnumerable]) {
                foreach ($item in $Collection) {
                    [void]$result.Add($item)
                }
            } else {
                [void]$result.Add($Collection)
            }

            return $result
        }
    }
}

function ConvertTo-List {
    <#
    .SYNOPSIS
        Convertit une collection en List<T>.

    .DESCRIPTION
        Cette fonction convertit une collection en System.Collections.Generic.List<T>.
        Elle accepte différents types de collections en entrée et effectue la conversion appropriée.

    .PARAMETER Collection
        Collection à convertir en List<T>.

    .PARAMETER ElementType
        Type des éléments de la liste. Si non spécifié, le type est déterminé automatiquement.

    .PARAMETER UseWrapper
        Indique si la conversion doit utiliser CollectionWrapper pour optimiser les performances.
        Par défaut, la valeur est $true.

    .EXAMPLE
        $arrayList = New-Object System.Collections.ArrayList
        $arrayList.Add(1)
        $arrayList.Add(2)
        $list = ConvertTo-List -Collection $arrayList -ElementType ([int])
        Convertit un ArrayList en List<int>.

    .OUTPUTS
        System.Collections.Generic.List`1
    #>
    [CmdletBinding()]
    [OutputType([System.Collections.Generic.IList])]
    param(
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true)]
        [object]$Collection,

        [Parameter(Mandatory = $false)]
        [type]$ElementType,

        [Parameter(Mandatory = $false)]
        [switch]$UseWrapper = $true
    )

    process {
        if ($null -eq $Collection) {
            if ($null -eq $ElementType) {
                $ElementType = [object]
            }
            $listType = [System.Collections.Generic.List`1].MakeGenericType($ElementType)
            return [Activator]::CreateInstance($listType)
        }

        # Déterminer le type d'élément si non spécifié
        if ($null -eq $ElementType) {
            if ($Collection -is [System.Collections.Generic.IEnumerable`1]) {
                $ElementType = $Collection.GetType().GetGenericArguments()[0]
            } else {
                $ElementType = [object]
            }
        }

        if ($UseWrapper) {
            # Utiliser CollectionWrapper pour la conversion
            $wrapper = New-CollectionWrapper -Collection $Collection -ElementType $ElementType
            return $wrapper.ToList()
        } else {
            # Conversion manuelle
            $listType = [System.Collections.Generic.List`1].MakeGenericType($ElementType)
            $result = [Activator]::CreateInstance($listType)

            # Traiter différents types de collections
            if ($Collection -is [System.Collections.Generic.List`1]) {
                $collectionElementType = $Collection.GetType().GetGenericArguments()[0]
                if ($collectionElementType -eq $ElementType) {
                    return $Collection
                }
            }

            if ($Collection -is [System.Collections.IEnumerable]) {
                foreach ($item in $Collection) {
                    $result.Add($item)
                }
            } else {
                $result.Add($Collection)
            }

            return $result
        }
    }
}

function ConvertTo-ConcurrentBag {
    <#
    .SYNOPSIS
        Convertit une collection en ConcurrentBag<T>.

    .DESCRIPTION
        Cette fonction convertit une collection en System.Collections.Concurrent.ConcurrentBag<T>.
        Elle accepte différents types de collections en entrée et effectue la conversion appropriée.

    .PARAMETER Collection
        Collection à convertir en ConcurrentBag<T>.

    .PARAMETER ElementType
        Type des éléments du sac. Si non spécifié, le type est déterminé automatiquement.

    .PARAMETER UseWrapper
        Indique si la conversion doit utiliser CollectionWrapper pour optimiser les performances.
        Par défaut, la valeur est $true.

    .EXAMPLE
        $list = [System.Collections.Generic.List[string]]::new()
        $list.Add("Item1")
        $list.Add("Item2")
        $bag = ConvertTo-ConcurrentBag -Collection $list
        Convertit une List<string> en ConcurrentBag<string>.

    .OUTPUTS
        System.Collections.Concurrent.ConcurrentBag`1
    #>
    [CmdletBinding()]
    [OutputType([System.Collections.Concurrent.ConcurrentBag`1])]
    param(
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true)]
        [object]$Collection,

        [Parameter(Mandatory = $false)]
        [type]$ElementType,

        [Parameter(Mandatory = $false)]
        [switch]$UseWrapper = $true
    )

    process {
        if ($null -eq $Collection) {
            if ($null -eq $ElementType) {
                $ElementType = [object]
            }
            $bagType = [System.Collections.Concurrent.ConcurrentBag`1].MakeGenericType($ElementType)
            return [Activator]::CreateInstance($bagType)
        }

        # Déterminer le type d'élément si non spécifié
        if ($null -eq $ElementType) {
            if ($Collection -is [System.Collections.Generic.IEnumerable`1]) {
                $ElementType = $Collection.GetType().GetGenericArguments()[0]
            } else {
                $ElementType = [object]
            }
        }

        if ($UseWrapper) {
            # Utiliser CollectionWrapper pour la conversion
            $wrapper = New-CollectionWrapper -Collection $Collection -ElementType $ElementType
            return $wrapper.ToConcurrentBag()
        } else {
            # Conversion manuelle
            $bagType = [System.Collections.Concurrent.ConcurrentBag`1].MakeGenericType($ElementType)

            # Traiter différents types de collections
            if ($Collection -is [System.Collections.Concurrent.ConcurrentBag`1]) {
                $collectionElementType = $Collection.GetType().GetGenericArguments()[0]
                if ($collectionElementType -eq $ElementType) {
                    return $Collection
                }
                $result = [Activator]::CreateInstance($bagType, @($Collection))
                return $result
            }

            $result = [Activator]::CreateInstance($bagType)

            if ($Collection -is [System.Collections.IEnumerable]) {
                foreach ($item in $Collection) {
                    $result.Add($item)
                }
            } else {
                $result.Add($Collection)
            }

            return $result
        }
    }
}

function Test-CollectionType {
    <#
    .SYNOPSIS
        Détermine le type d'une collection.

    .DESCRIPTION
        Cette fonction détermine le type d'une collection et retourne des informations sur celle-ci.

    .PARAMETER Collection
        Collection à analyser.

    .EXAMPLE
        $list = [System.Collections.Generic.List[int]]::new()
        Test-CollectionType -Collection $list
        Retourne des informations sur le type de la collection.

    .OUTPUTS
        PSCustomObject
    #>
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true)]
        [object]$Collection
    )

    process {
        if ($null -eq $Collection) {
            return [PSCustomObject]@{
                Type         = "Null"
                ElementType  = $null
                IsGeneric    = $false
                IsThreadSafe = $false
                IsReadOnly   = $false
                Count        = 0
                IsEmpty      = $true
            }
        }

        $type = $Collection.GetType()
        $typeName = $type.Name
        $fullTypeName = $type.FullName
        $isGeneric = $type.IsGenericType
        $elementType = $null
        $isThreadSafe = $false
        $isReadOnly = $false
        $count = 0
        $isEmpty = $true

        # Déterminer le type d'élément pour les collections génériques
        if ($isGeneric) {
            $elementType = $type.GetGenericArguments()[0]
        }

        # Déterminer si la collection est thread-safe
        $isThreadSafe = $type.Namespace -eq "System.Collections.Concurrent"

        # Déterminer si la collection est en lecture seule
        if ($Collection -is [System.Collections.ICollection]) {
            $isReadOnly = $Collection.IsReadOnly
        } elseif ($Collection -is [System.Collections.Generic.ICollection`1]) {
            $isReadOnly = $Collection.IsReadOnly
        }

        # Déterminer le nombre d'éléments
        if ($Collection -is [System.Collections.ICollection]) {
            $count = $Collection.Count
            $isEmpty = $count -eq 0
        } elseif ($Collection -is [System.Collections.Generic.ICollection`1]) {
            $count = $Collection.Count
            $isEmpty = $count -eq 0
        } elseif ($Collection -is [System.Array]) {
            $count = $Collection.Length
            $isEmpty = $count -eq 0
        }

        # Déterminer le type de collection
        $collectionType = "Unknown"
        if ($Collection -is [System.Collections.ArrayList]) {
            $collectionType = "ArrayList"
        } elseif ($Collection -is [System.Collections.Generic.List`1]) {
            $collectionType = "List"
        } elseif ($Collection -is [System.Array]) {
            $collectionType = "Array"
        } elseif ($Collection -is [System.Collections.Concurrent.ConcurrentBag`1]) {
            $collectionType = "ConcurrentBag"
        } elseif ($Collection -is [System.Collections.Concurrent.ConcurrentQueue`1]) {
            $collectionType = "ConcurrentQueue"
        } elseif ($Collection -is [System.Collections.Concurrent.ConcurrentStack`1]) {
            $collectionType = "ConcurrentStack"
        } elseif ($Collection -is [System.Collections.Concurrent.ConcurrentDictionary`2]) {
            $collectionType = "ConcurrentDictionary"
        } elseif ($Collection -is [System.Collections.Generic.Queue`1]) {
            $collectionType = "Queue"
        } elseif ($Collection -is [System.Collections.Generic.Stack`1]) {
            $collectionType = "Stack"
        } elseif ($Collection -is [System.Collections.Generic.HashSet`1]) {
            $collectionType = "HashSet"
        } elseif ($Collection -is [System.Collections.Generic.Dictionary`2]) {
            $collectionType = "Dictionary"
        } elseif ($Collection -is [System.Collections.IEnumerable]) {
            $collectionType = "IEnumerable"
        }

        return [PSCustomObject]@{
            Type         = $collectionType
            TypeName     = $typeName
            FullTypeName = $fullTypeName
            ElementType  = $elementType
            IsGeneric    = $isGeneric
            IsThreadSafe = $isThreadSafe
            IsReadOnly   = $isReadOnly
            Count        = $count
            IsEmpty      = $isEmpty
        }
    }
}
