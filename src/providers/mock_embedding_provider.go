package providers

import (
	"context"
	"crypto/md5"
	"math"
	"math/rand"
	"sync"
	"time"
)

// MockEmbeddingProvider simule un fournisseur d'embeddings pour les tests
type MockEmbeddingProvider struct {
	// Cache des embeddings déjà calculés
	cache     map[string][]float32
	cacheLock sync.RWMutex

	// Configuration de la simulation
	baseLatency  time.Duration // Latence de base par requête
	batchLatency time.Duration // Latence additionnelle par élément dans un batch
	cacheHitRate float32       // Taux de succès du cache (0-1)
	maxCacheSize int64         // Taille maximale du cache en octets (0 = illimité)
	evictQueue   []string      // Queue FIFO pour l'éviction du cache

	// Configuration des embeddings
	dimensions int // Nombre de dimensions des embeddings
	batchSize  int // Taille maximum des batchs

	// Statistiques accumulées
	totalRequests int64
	cacheHits     int64
	totalLatency  time.Duration
	totalTokens   int64 // Nombre total de tokens traités
	totalBatches  int64 // Nombre total de batchs traités
	cacheSize     int64 // Taille approximative du cache en octets
	statsLock     sync.RWMutex
}

// NewMockEmbeddingProvider crée une nouvelle instance du provider simulé
func NewMockEmbeddingProvider(opts ...MockOption) *MockEmbeddingProvider {
	provider := &MockEmbeddingProvider{
		cache:        make(map[string][]float32),
		baseLatency:  100 * time.Millisecond, // Latence par défaut
		batchLatency: 10 * time.Millisecond,  // Latence additionnelle par élément
		cacheHitRate: 0.8,                    // 80% de succès du cache par défaut
		maxCacheSize: 100 * 1024 * 1024,      // 100MB par défaut
		evictQueue:   make([]string, 0),      // Queue d'éviction vide
		dimensions:   1536,                   // Dimensions par défaut (OpenAI)
		batchSize:    32,                     // Taille de batch par défaut
	}

	// Appliquer les options de configuration
	for _, opt := range opts {
		opt(provider)
	}

	return provider
}

// MockOption permet de configurer le provider simulé
type MockOption func(*MockEmbeddingProvider)

// WithBaseLatency configure la latence de base
func WithBaseLatency(d time.Duration) MockOption {
	return func(p *MockEmbeddingProvider) {
		p.baseLatency = d
	}
}

// WithBatchLatency configure la latence additionnelle par élément
func WithBatchLatency(d time.Duration) MockOption {
	return func(p *MockEmbeddingProvider) {
		p.batchLatency = d
	}
}

// WithCacheHitRate configure le taux de succès du cache
func WithCacheHitRate(rate float32) MockOption {
	return func(p *MockEmbeddingProvider) {
		p.cacheHitRate = rate
	}
}

// WithMaxCacheSize configure la taille maximale du cache en octets
func WithMaxCacheSize(size int64) MockOption {
	return func(p *MockEmbeddingProvider) {
		p.maxCacheSize = size
	}
}

// WithDimensions configure le nombre de dimensions des embeddings
func WithDimensions(dim int) MockOption {
	return func(p *MockEmbeddingProvider) {
		p.dimensions = dim
	}
}

// WithBatchSize configure la taille maximum des batchs
func WithBatchSize(size int) MockOption {
	return func(p *MockEmbeddingProvider) {
		p.batchSize = size
	}
}

// Méthodes de l'interface EmbeddingProvider

// GetEmbeddings génère des embeddings pour un batch de textes (interface EmbeddingProvider)
func (p *MockEmbeddingProvider) GetEmbeddings(ctx context.Context, texts []string) ([][]float32, error) {
	return p.EmbedBatch(texts)
}

// GetDimensions retourne le nombre de dimensions des embeddings
func (p *MockEmbeddingProvider) GetDimensions() int {
	return p.dimensions
}

// GetBatchSize retourne la taille maximum des batchs supportée
func (p *MockEmbeddingProvider) GetBatchSize() int {
	return p.batchSize
}

// Embed génère un embedding simulé pour un texte donné
func (p *MockEmbeddingProvider) Embed(text string) ([]float32, error) {
	// Vérifier d'abord le cache
	if embedding := p.checkCache(text); embedding != nil {
		// Cache hit - retourner immédiatement sans latence artificielle
		p.updateStats(0, 1, int64(len(text)))
		return embedding, nil
	}

	// Simuler la latence de base plus une latence variable basée sur la taille du texte
	latency := p.baseLatency + time.Duration(len(text))*time.Microsecond
	time.Sleep(latency)

	// Générer un embedding simulé
	embedding := generateMockEmbedding(text, p.dimensions)

	// Mettre en cache le résultat
	p.cacheResult(text, embedding)

	// Mettre à jour les statistiques
	p.updateStats(latency, 1, int64(len(text)))

	return embedding, nil
}

// EmbedBatch génère des embeddings simulés pour un batch de textes
func (p *MockEmbeddingProvider) EmbedBatch(texts []string) ([][]float32, error) {
	embeddings := make([][]float32, len(texts))
	var totalTokens int64
	var totalLatency time.Duration

	// Traitement séquentiel pour la simulation
	for i, text := range texts {
		// Vérifier le cache - pas de latence pour les cache hits
		if embedding := p.checkCache(text); embedding != nil {
			embeddings[i] = embedding
			totalTokens += int64(len(text))
			continue
		}

		// Calculer la latence pour cet élément
		elementLatency := p.batchLatency // Latence de base par élément

		// Ajouter la latence de base pour le premier élément non-caché seulement
		if i == 0 {
			elementLatency += p.baseLatency
		}

		// Ajouter une latence variable basée sur la taille du texte
		elementLatency += time.Duration(len(text)) * time.Microsecond

		// Accumuler la latence totale pour les statistiques
		totalLatency += elementLatency
		totalTokens += int64(len(text))

		// Générer l'embedding
		embeddings[i] = generateMockEmbedding(text, p.dimensions)

		// Mettre en cache le résultat
		p.cacheResult(text, embeddings[i])

		// Simuler la latence pour cet élément
		time.Sleep(elementLatency)
	}

	// Mettre à jour les statistiques avec la latence totale accumulée
	p.updateStats(totalLatency, int64(len(texts)), totalTokens)

	return embeddings, nil
}

// Méthodes utilitaires privées

func (p *MockEmbeddingProvider) checkCache(text string) []float32 {
	p.cacheLock.RLock()
	defer p.cacheLock.RUnlock()

	// Vérifier si l'embedding existe dans le cache
	if embedding, exists := p.cache[text]; exists {
		// Si le taux de cache hit est à 1.0, toujours retourner le cache hit
		// Sinon, simuler des cache misses selon le taux configuré
		if p.cacheHitRate >= 1.0 || rand.Float32() <= p.cacheHitRate {
			p.statsLock.Lock()
			p.cacheHits++
			p.statsLock.Unlock()
			return embedding
		}
	}
	return nil
}

func (p *MockEmbeddingProvider) cacheResult(text string, embedding []float32) {
	p.cacheLock.Lock()
	defer p.cacheLock.Unlock()

	// Si l'élément existe déjà dans le cache, ne pas le ré-ajouter
	if _, exists := p.cache[text]; exists {
		return
	}

	// Calculer la taille du nouvel embedding
	newSize := int64(len(embedding) * 4) // 4 bytes par float32

	// Si le cache a une limite de taille et qu'elle serait dépassée
	if p.maxCacheSize > 0 {
		// Évincuer autant d'éléments que nécessaire pour faire de la place
		for p.cacheSize+newSize > p.maxCacheSize && len(p.evictQueue) > 0 {
			p.evictOldest()
		}
	}

	p.cache[text] = embedding
	p.evictQueue = append(p.evictQueue, text)

	// Mettre à jour la taille approximative du cache
	p.statsLock.Lock()
	p.cacheSize += newSize
	p.statsLock.Unlock()
}

func (p *MockEmbeddingProvider) evictOldest() {
	if len(p.evictQueue) == 0 {
		return
	}

	// Obtenir la clé du plus ancien élément dans le cache
	oldest := p.evictQueue[0]
	p.evictQueue = p.evictQueue[1:] // Mettre à jour la queue d'éviction

	// Si l'élément existe encore, le supprimer et mettre à jour la taille
	if oldEmbed, exists := p.cache[oldest]; exists {
		p.statsLock.Lock()
		p.cacheSize -= int64(len(oldEmbed) * 4) // 4 bytes par float32
		p.statsLock.Unlock()
		delete(p.cache, oldest)
	}
}

func (p *MockEmbeddingProvider) updateStats(latency time.Duration, batchSize, tokens int64) {
	p.statsLock.Lock()
	defer p.statsLock.Unlock()

	p.totalRequests += batchSize // Increment by batch size since each item is a request
	p.totalBatches++             // Increment by 1 since this is one batch operation
	p.totalLatency += latency
	p.totalTokens += tokens
}

// Génère un vecteur d'embedding simulé de manière déterministe
func generateMockEmbedding(text string, dim int) []float32 {
	// Calculer le hash MD5 du texte
	hash := md5.Sum([]byte(text))

	// Convertir les bytes en float32 entre -1 et 1
	embedding := make([]float32, dim)
	for i := range embedding {
		// Utiliser le hash pour générer des valeurs déterministes
		byteIndex := i % len(hash)
		value := float32(hash[byteIndex])/255.0*2.0 - 1.0

		// Ajouter une variation basée sur la position
		position := float32(i) / float32(dim)
		value = value*0.8 + position*0.2 // Mélanger avec la position pour plus de variété

		// Normaliser pour rester entre -1 et 1
		embedding[i] = float32(math.Tanh(float64(value)))
	}

	return normalizeVector(embedding)
}

// Normalise un vecteur pour avoir une norme de 1
func normalizeVector(v []float32) []float32 {
	var norm float32
	for _, x := range v {
		norm += x * x
	}
	norm = float32(math.Sqrt(float64(norm)))

	if norm == 0 {
		return v // Éviter la division par zéro
	}

	normalized := make([]float32, len(v))
	for i, x := range v {
		normalized[i] = x / norm
	}
	return normalized
}

// Stats contient les statistiques d'utilisation du provider
type Stats struct {
	TotalRequests int64
	TotalBatches  int64
	CacheHits     int64
	TotalTokens   int64
	CacheSize     int64         // Taille approximative en octets
	AvgLatency    time.Duration // Latence moyenne par requête
	HitRate       float32       // Taux de succès du cache effectif
}

// GetStats retourne le nombre total de requêtes, le nombre de cache hits et la latence moyenne
func (p *MockEmbeddingProvider) GetStats() (int64, int64, time.Duration) {
	p.statsLock.RLock()
	defer p.statsLock.RUnlock()

	var avgLatency time.Duration
	if p.totalRequests > 0 {
		avgLatency = p.totalLatency / time.Duration(p.totalRequests)
	}

	return p.totalRequests, p.cacheHits, avgLatency
}

// MD5Hash calcule le hash MD5 d'un texte donné et retourne le résultat sous forme de tableau de float32
func MD5Hash(text string) []float32 {
	hash := md5.Sum([]byte(text))

	// Convertir le hash en tableau de float32
	result := make([]float32, len(hash))
	for i := range hash {
		result[i] = float32(hash[i]) / math.MaxUint8 // Normaliser entre 0 et 1
	}
	return result
}

// SetMaxCacheSize met à jour la taille maximale du cache et évince si nécessaire
func (p *MockEmbeddingProvider) SetMaxCacheSize(size int64) {
	p.cacheLock.Lock()
	defer p.cacheLock.Unlock()

	p.maxCacheSize = size

	// Si le cache actuel dépasse la nouvelle limite, évincuer des éléments
	if size > 0 {
		for p.cacheSize > size && len(p.evictQueue) > 0 {
			p.evictOldest()
		}
	}
}

// GetCacheContents retourne le contenu actuel du cache (pour debug)
func (p *MockEmbeddingProvider) GetCacheContents() []string {
	p.cacheLock.RLock()
	defer p.cacheLock.RUnlock()

	keys := make([]string, 0, len(p.cache))
	for key := range p.cache {
		keys = append(keys, key)
	}
	return keys
}

// GetCacheSize retourne la taille actuelle du cache
func (p *MockEmbeddingProvider) GetCacheSize() int64 {
	p.statsLock.RLock()
	defer p.statsLock.RUnlock()
	return p.cacheSize
}
