package providers

import (
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

// Embed génère un embedding simulé pour un texte donné
func (p *MockEmbeddingProvider) Embed(text string) ([]float32, error) {
	// Vérifier d'abord le cache
	if embedding := p.checkCache(text); embedding != nil {
		return embedding, nil
	}

	// Simuler la latence de base
	time.Sleep(p.baseLatency)

	// Générer un embedding simulé
	embedding := generateMockEmbedding(text, 1536)

	// Mettre en cache le résultat
	p.cacheResult(text, embedding)

	// Mettre à jour les statistiques
	p.updateStats(p.baseLatency, 1, int64(len(text)))

	return embedding, nil
}

// EmbedBatch génère des embeddings simulés pour un batch de textes
func (p *MockEmbeddingProvider) EmbedBatch(texts []string) ([][]float32, error) {
	embeddings := make([][]float32, len(texts))
	var totalTokens int64

	// Latence de base pour le batch
	latency := p.baseLatency

	// Traitement séquentiel pour la simulation
	for i, text := range texts {
		// Vérifier le cache
		if embedding := p.checkCache(text); embedding != nil {
			embeddings[i] = embedding
			continue
		}

		// Ajouter la latence par élément
		latency += p.batchLatency

		// Générer l'embedding
		embeddings[i] = generateMockEmbedding(text, 1536)

		// Mettre en cache
		p.cacheResult(text, embeddings[i])

		totalTokens += int64(len(text))
	}

	// Simuler la latence totale du batch
	time.Sleep(latency)

	// Mettre à jour les statistiques
	p.updateStats(latency, int64(len(texts)), totalTokens)

	return embeddings, nil
}

// Méthodes utilitaires privées

func (p *MockEmbeddingProvider) checkCache(text string) []float32 {
	p.cacheLock.RLock()
	defer p.cacheLock.RUnlock()

	// Simuler le comportement du cache selon le taux configuré
	if embedding, exists := p.cache[text]; exists {
		// Même si l'embedding existe, on simule un miss selon le taux configuré
		if rand.Float32() <= p.cacheHitRate {
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

	p.cache[text] = embedding

	// Mettre à jour la taille approximative du cache
	p.statsLock.Lock()
	p.cacheSize = int64(len(p.cache)) * int64(len(embedding)*4) // 4 bytes par float32
	p.statsLock.Unlock()
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
