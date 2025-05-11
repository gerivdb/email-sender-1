/**
 * hierarchical-diagram-data-sources.js
 * Module de gestion des sources de données pour les diagrammes hiérarchiques
 * Version: 1.0
 * Date: 2025-05-15
 */

/**
 * Classe DataSourceRegistry
 * Registre central pour les différentes sources de données
 */
class DataSourceRegistry {
    /**
     * Constructeur
     */
    constructor() {
        this.sources = new Map();
        this.defaultSource = null;
    }

    /**
     * Enregistre une source de données
     * @param {string} name - Nom unique de la source
     * @param {DataSource} source - Instance de la source de données
     * @param {boolean} setAsDefault - Définir comme source par défaut
     * @returns {DataSourceRegistry} - L'instance actuelle pour chaînage
     */
    register(name, source, setAsDefault = false) {
        if (!(source instanceof DataSource)) {
            throw new Error('La source doit être une instance de DataSource');
        }

        this.sources.set(name, source);

        if (setAsDefault || this.defaultSource === null) {
            this.defaultSource = name;
        }

        return this;
    }

    /**
     * Supprime une source de données
     * @param {string} name - Nom de la source à supprimer
     * @returns {boolean} - True si la suppression a réussi
     */
    unregister(name) {
        const result = this.sources.delete(name);

        // Si la source par défaut a été supprimée, en définir une nouvelle
        if (result && this.defaultSource === name) {
            this.defaultSource = this.sources.size > 0 ? 
                Array.from(this.sources.keys())[0] : null;
        }

        return result;
    }

    /**
     * Obtient une source de données par son nom
     * @param {string} name - Nom de la source (ou null pour la source par défaut)
     * @returns {DataSource} - La source de données ou null si non trouvée
     */
    getSource(name = null) {
        const sourceName = name || this.defaultSource;
        return sourceName ? this.sources.get(sourceName) || null : null;
    }

    /**
     * Définit la source par défaut
     * @param {string} name - Nom de la source à définir comme défaut
     * @returns {boolean} - True si la définition a réussi
     */
    setDefaultSource(name) {
        if (!this.sources.has(name)) {
            return false;
        }

        this.defaultSource = name;
        return true;
    }

    /**
     * Liste toutes les sources disponibles
     * @returns {Array} - Tableau d'objets {name, source, isDefault}
     */
    listSources() {
        return Array.from(this.sources.entries()).map(([name, source]) => ({
            name,
            source,
            isDefault: name === this.defaultSource
        }));
    }

    /**
     * Charge des données depuis une source
     * @param {string} sourceName - Nom de la source (ou null pour la source par défaut)
     * @param {Object} params - Paramètres de chargement
     * @returns {Promise} - Promise résolue avec les données
     */
    loadData(sourceName = null, params = {}) {
        const source = this.getSource(sourceName);

        if (!source) {
            return Promise.reject(new Error(`Source de données non trouvée: ${sourceName || 'default'}`));
        }

        return source.loadData(params);
    }
}

/**
 * Classe DataSource
 * Classe de base abstraite pour les sources de données
 */
class DataSource {
    /**
     * Constructeur
     * @param {Object} options - Options de configuration
     */
    constructor(options = {}) {
        this.options = options;
        
        if (new.target === DataSource) {
            throw new Error('DataSource est une classe abstraite et ne peut pas être instanciée directement');
        }
    }

    /**
     * Charge les données
     * @param {Object} params - Paramètres de chargement
     * @returns {Promise} - Promise résolue avec les données
     */
    loadData(params = {}) {
        throw new Error('La méthode loadData doit être implémentée par les classes dérivées');
    }

    /**
     * Sauvegarde les données
     * @param {Object} data - Données à sauvegarder
     * @param {Object} params - Paramètres de sauvegarde
     * @returns {Promise} - Promise résolue après la sauvegarde
     */
    saveData(data, params = {}) {
        throw new Error('La méthode saveData doit être implémentée par les classes dérivées');
    }
}

/**
 * Classe ApiDataSource
 * Source de données utilisant une API REST
 */
class ApiDataSource extends DataSource {
    /**
     * Constructeur
     * @param {Object} options - Options de configuration
     * @param {string} options.baseUrl - URL de base de l'API
     * @param {string} options.endpoint - Point d'entrée de l'API
     * @param {Object} options.headers - En-têtes HTTP par défaut
     * @param {number} options.timeout - Timeout en ms
     * @param {Function} options.authProvider - Fonction fournissant les informations d'authentification
     */
    constructor(options = {}) {
        super(Object.assign({
            baseUrl: '',
            endpoint: '',
            headers: {
                'Accept': 'application/json',
                'Content-Type': 'application/json'
            },
            timeout: 30000,
            authProvider: null
        }, options));
    }

    /**
     * Construit l'URL complète
     * @param {Object} params - Paramètres de requête
     * @returns {string} - URL complète
     * @private
     */
    _buildUrl(params = {}) {
        let url = this.options.baseUrl;
        
        if (this.options.endpoint) {
            url += (url.endsWith('/') ? '' : '/') + this.options.endpoint;
        }

        // Ajouter les paramètres de requête
        const queryParams = new URLSearchParams();
        
        for (const [key, value] of Object.entries(params)) {
            if (Array.isArray(value)) {
                value.forEach(v => queryParams.append(`${key}[]`, v));
            } else if (value !== null && value !== undefined) {
                queryParams.append(key, value);
            }
        }

        const queryString = queryParams.toString();
        if (queryString) {
            url += (url.includes('?') ? '&' : '?') + queryString;
        }

        return url;
    }

    /**
     * Obtient les en-têtes HTTP
     * @returns {Object} - En-têtes HTTP
     * @private
     */
    async _getHeaders() {
        let headers = { ...this.options.headers };

        // Ajouter les informations d'authentification si disponibles
        if (typeof this.options.authProvider === 'function') {
            const authInfo = await this.options.authProvider();
            
            if (authInfo) {
                headers = { ...headers, ...authInfo };
            }
        }

        return headers;
    }

    /**
     * Charge les données depuis l'API
     * @param {Object} params - Paramètres de requête
     * @returns {Promise} - Promise résolue avec les données
     */
    async loadData(params = {}) {
        const url = this._buildUrl(params);
        const headers = await this._getHeaders();
        
        const controller = new AbortController();
        const timeoutId = setTimeout(() => controller.abort(), this.options.timeout);

        try {
            const response = await fetch(url, {
                method: 'GET',
                headers,
                signal: controller.signal
            });

            if (!response.ok) {
                throw new Error(`Erreur HTTP: ${response.status} ${response.statusText}`);
            }

            return await response.json();
        } catch (error) {
            if (error.name === 'AbortError') {
                throw new Error(`Timeout de la requête après ${this.options.timeout}ms`);
            }
            throw error;
        } finally {
            clearTimeout(timeoutId);
        }
    }

    /**
     * Sauvegarde les données via l'API
     * @param {Object} data - Données à sauvegarder
     * @param {Object} params - Paramètres de sauvegarde
     * @returns {Promise} - Promise résolue avec la réponse
     */
    async saveData(data, params = {}) {
        const url = this._buildUrl(params);
        const headers = await this._getHeaders();
        
        const controller = new AbortController();
        const timeoutId = setTimeout(() => controller.abort(), this.options.timeout);

        try {
            const response = await fetch(url, {
                method: 'POST',
                headers,
                body: JSON.stringify(data),
                signal: controller.signal
            });

            if (!response.ok) {
                throw new Error(`Erreur HTTP: ${response.status} ${response.statusText}`);
            }

            return await response.json();
        } catch (error) {
            if (error.name === 'AbortError') {
                throw new Error(`Timeout de la requête après ${this.options.timeout}ms`);
            }
            throw error;
        } finally {
            clearTimeout(timeoutId);
        }
    }
}

/**
 * Classe FileDataSource
 * Source de données utilisant des fichiers locaux
 */
class FileDataSource extends DataSource {
    /**
     * Constructeur
     * @param {Object} options - Options de configuration
     * @param {string} options.basePath - Chemin de base pour les fichiers
     * @param {string} options.defaultFile - Nom de fichier par défaut
     * @param {boolean} options.useCache - Utiliser le cache pour les fichiers
     * @param {number} options.cacheExpiration - Durée d'expiration du cache en ms
     */
    constructor(options = {}) {
        super(Object.assign({
            basePath: 'data/',
            defaultFile: 'hierarchical-data.json',
            useCache: true,
            cacheExpiration: 60000 // 1 minute
        }, options));

        this.cache = new Map();
    }

    /**
     * Construit le chemin complet du fichier
     * @param {string} filename - Nom du fichier (ou null pour le fichier par défaut)
     * @returns {string} - Chemin complet
     * @private
     */
    _buildPath(filename = null) {
        const file = filename || this.options.defaultFile;
        let path = this.options.basePath;
        
        if (!path.endsWith('/')) {
            path += '/';
        }
        
        return path + file;
    }

    /**
     * Vérifie si une entrée du cache est valide
     * @param {string} key - Clé de cache
     * @returns {boolean} - True si l'entrée est valide
     * @private
     */
    _isCacheValid(key) {
        if (!this.options.useCache || !this.cache.has(key)) {
            return false;
        }

        const cacheEntry = this.cache.get(key);
        const now = Date.now();
        
        return now - cacheEntry.timestamp < this.options.cacheExpiration;
    }

    /**
     * Charge les données depuis un fichier
     * @param {Object} params - Paramètres de chargement
     * @param {string} params.filename - Nom du fichier (optionnel)
     * @param {boolean} params.bypassCache - Ignorer le cache (optionnel)
     * @returns {Promise} - Promise résolue avec les données
     */
    async loadData(params = {}) {
        const filename = params.filename || this.options.defaultFile;
        const filePath = this._buildPath(filename);
        const cacheKey = filePath;

        // Vérifier le cache
        if (!params.bypassCache && this._isCacheValid(cacheKey)) {
            return this.cache.get(cacheKey).data;
        }

        try {
            const response = await fetch(filePath);
            
            if (!response.ok) {
                throw new Error(`Erreur lors du chargement du fichier: ${response.status} ${response.statusText}`);
            }
            
            const data = await response.json();
            
            // Mettre en cache
            if (this.options.useCache) {
                this.cache.set(cacheKey, {
                    data,
                    timestamp: Date.now()
                });
            }
            
            return data;
        } catch (error) {
            throw new Error(`Erreur lors du chargement du fichier ${filePath}: ${error.message}`);
        }
    }

    /**
     * Sauvegarde les données dans un fichier (non implémenté côté client)
     * @param {Object} data - Données à sauvegarder
     * @param {Object} params - Paramètres de sauvegarde
     * @returns {Promise} - Promise rejetée avec une erreur
     */
    saveData(data, params = {}) {
        return Promise.reject(new Error('La sauvegarde de fichiers n\'est pas prise en charge côté client'));
    }

    /**
     * Vide le cache
     * @param {string} key - Clé spécifique à vider (ou null pour tout vider)
     */
    clearCache(key = null) {
        if (key) {
            this.cache.delete(key);
        } else {
            this.cache.clear();
        }
    }
}

/**
 * Classe LocalStorageDataSource
 * Source de données utilisant le localStorage du navigateur
 */
class LocalStorageDataSource extends DataSource {
    /**
     * Constructeur
     * @param {Object} options - Options de configuration
     * @param {string} options.keyPrefix - Préfixe pour les clés de stockage
     * @param {string} options.defaultKey - Clé par défaut
     */
    constructor(options = {}) {
        super(Object.assign({
            keyPrefix: 'hierarchical_diagram_',
            defaultKey: 'data'
        }, options));
    }

    /**
     * Construit la clé complète
     * @param {string} key - Clé (ou null pour la clé par défaut)
     * @returns {string} - Clé complète
     * @private
     */
    _buildKey(key = null) {
        return this.options.keyPrefix + (key || this.options.defaultKey);
    }

    /**
     * Charge les données depuis le localStorage
     * @param {Object} params - Paramètres de chargement
     * @param {string} params.key - Clé de stockage (optionnel)
     * @returns {Promise} - Promise résolue avec les données
     */
    loadData(params = {}) {
        return new Promise((resolve, reject) => {
            try {
                const key = this._buildKey(params.key);
                const data = localStorage.getItem(key);
                
                if (!data) {
                    reject(new Error(`Aucune donnée trouvée pour la clé: ${key}`));
                    return;
                }
                
                resolve(JSON.parse(data));
            } catch (error) {
                reject(new Error(`Erreur lors du chargement depuis localStorage: ${error.message}`));
            }
        });
    }

    /**
     * Sauvegarde les données dans le localStorage
     * @param {Object} data - Données à sauvegarder
     * @param {Object} params - Paramètres de sauvegarde
     * @param {string} params.key - Clé de stockage (optionnel)
     * @returns {Promise} - Promise résolue après la sauvegarde
     */
    saveData(data, params = {}) {
        return new Promise((resolve, reject) => {
            try {
                const key = this._buildKey(params.key);
                const jsonData = JSON.stringify(data);
                
                localStorage.setItem(key, jsonData);
                resolve({ success: true, key });
            } catch (error) {
                reject(new Error(`Erreur lors de la sauvegarde dans localStorage: ${error.message}`));
            }
        });
    }

    /**
     * Supprime des données du localStorage
     * @param {Object} params - Paramètres
     * @param {string} params.key - Clé de stockage (optionnel)
     * @returns {Promise} - Promise résolue après la suppression
     */
    removeData(params = {}) {
        return new Promise((resolve) => {
            const key = this._buildKey(params.key);
            localStorage.removeItem(key);
            resolve({ success: true, key });
        });
    }

    /**
     * Liste toutes les clés disponibles
     * @returns {Promise} - Promise résolue avec la liste des clés
     */
    listKeys() {
        return new Promise((resolve) => {
            const keys = [];
            const prefix = this.options.keyPrefix;
            
            for (let i = 0; i < localStorage.length; i++) {
                const key = localStorage.key(i);
                
                if (key.startsWith(prefix)) {
                    keys.push(key.substring(prefix.length));
                }
            }
            
            resolve(keys);
        });
    }
}

// Exporter les classes pour utilisation dans d'autres modules
if (typeof module !== 'undefined' && module.exports) {
    module.exports = {
        DataSourceRegistry,
        DataSource,
        ApiDataSource,
        FileDataSource,
        LocalStorageDataSource
    };
}
