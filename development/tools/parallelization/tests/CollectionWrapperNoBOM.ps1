# Version sans BOM du fichier CollectionWrapper.ps1

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
        /// Convertit la collection en ArrayList avec préservation des types
        /// </summary>
        /// <returns>ArrayList contenant les éléments de la collection avec leurs types préservés</returns>
        public ArrayList ToArrayList()
        {
            // Optimisation pour les grandes collections
            int capacity = Count > 0 ? Count : 16;
            ArrayList result = new ArrayList(capacity);

            switch (_type)
            {
                case CollectionType.ArrayList:
                    // Retourner directement l'ArrayList si c'est déjà une ArrayList
                    return (ArrayList)_collection;
                case CollectionType.List:
                    // Optimisation pour les grandes collections
                    if (Count > 1000)
                    {
                        // Utiliser AddRange avec ToArray pour les grandes collections
                        result.AddRange(((List<T>)_collection).ToArray());
                    }
                    else
                    {
                        // Ajouter les éléments un par un pour préserver les types
                        foreach (var item in ((List<T>)_collection))
                            result.Add(item);
                    }
                    break;
                case CollectionType.Array:
                    // Optimisation pour les grandes collections
                    if (((Array)_collection).Length > 1000)
                    {
                        // Utiliser AddRange pour les grandes collections
                        result.AddRange((Array)_collection);
                    }
                    else
                    {
                        // Ajouter les éléments un par un pour préserver les types
                        foreach (var item in ((Array)_collection))
                            result.Add(item);
                    }
                    break;
                case CollectionType.ConcurrentBag:
                    // Ajouter les éléments un par un pour préserver les types
                    foreach (var item in ((ConcurrentBag<T>)_collection))
                        result.Add(item);
                    break;
                case CollectionType.ConcurrentQueue:
                    // Ajouter les éléments un par un pour préserver les types
                    foreach (var item in ((ConcurrentQueue<T>)_collection))
                        result.Add(item);
                    break;
                case CollectionType.ConcurrentStack:
                    // Ajouter les éléments un par un pour préserver les types
                    foreach (var item in ((ConcurrentStack<T>)_collection))
                        result.Add(item);
                    break;
                case CollectionType.ConcurrentDictionary:
                    // Ajouter les éléments un par un pour préserver les types
                    foreach (var item in ((ConcurrentDictionary<string, T>)_collection))
                        result.Add(item.Value);
                    break;
                case CollectionType.Queue:
                    // Ajouter les éléments un par un pour préserver les types
                    foreach (var item in ((Queue<T>)_collection))
                        result.Add(item);
                    break;
                case CollectionType.Stack:
                    // Ajouter les éléments un par un pour préserver les types
                    foreach (var item in ((Stack<T>)_collection))
                        result.Add(item);
                    break;
                case CollectionType.HashSet:
                    // Ajouter les éléments un par un pour préserver les types
                    foreach (var item in ((HashSet<T>)_collection))
                        result.Add(item);
                    break;
                case CollectionType.Dictionary:
                    // Ajouter les éléments un par un pour préserver les types
                    foreach (var item in ((Dictionary<string, T>)_collection))
                        result.Add(item.Value);
                    break;
                case CollectionType.Custom:
                    if (_collection is IEnumerable<T> genericEnumerable)
                    {
                        // Ajouter les éléments un par un pour préserver les types
                        foreach (var item in genericEnumerable)
                            result.Add(item);
                        break;
                    }
                    if (_collection is IEnumerable enumerable)
                    {
                        // Ajouter les éléments un par un pour préserver les types
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
