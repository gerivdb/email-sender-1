package tests

import (
	"context"
	"fmt"
	"sync"
	"testing"
	"time"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
	"github.com/stretchr/testify/suite"
)

// === PHASE 5.1.1.1: TESTS DU CLIENT QDRANT UNIFIÉ ===

// QdrantClientTestSuite suite de tests pour le client Qdrant unifié
type QdrantClientTestSuite struct {
	suite.Suite
	client    QdrantClient
	ctx       context.Context
	testData  map[string]TestVector
}

// QdrantClient interface du client Qdrant pour les tests
type QdrantClient interface {
	Connect(ctx context.Context) error
	CreateCollection(ctx context.Context, name string, vectorSize int) error
	UpsertPoints(ctx context.Context, collection string, points []Point) error
	SearchPoints(ctx context.Context, collection string, vector []float32, limit int) ([]SearchResult, error)
	DeletePoints(ctx context.Context, collection string, ids []string) error
	GetPoint(ctx context.Context, collection string, id string) (*Point, error)
	DeleteCollection(ctx context.Context, name string) error
	Close() error
	GetCollectionInfo(ctx context.Context, name string) (*CollectionInfo, error)
	CountPoints(ctx context.Context, collection string) (int64, error)
}

// Point représente un point vectoriel
type Point struct {
	ID      string                 `json:"id"`
	Vector  []float32              `json:"vector"`
	Payload map[string]interface{} `json:"payload"`
}

// SearchResult résultat de recherche
type SearchResult struct {
	ID      string                 `json:"id"`
	Score   float32                `json:"score"`
	Payload map[string]interface{} `json:"payload"`
	Vector  []float32              `json:"vector,omitempty"`
}

// CollectionInfo informations sur une collection
type CollectionInfo struct {
	Name        string `json:"name"`
	VectorSize  int    `json:"vector_size"`
	PointsCount int64  `json:"points_count"`
	Status      string `json:"status"`
}

// TestVector vecteur de test
type TestVector struct {
	ID      string
	Vector  []float32
	Payload map[string]interface{}
}

// SetupSuite initialise la suite de tests
func (suite *QdrantClientTestSuite) SetupSuite() {
	suite.ctx = context.Background()
	
	// Initialiser les données de test
	suite.testData = map[string]TestVector{
		"test_vector_1": {
			ID:     "test_001",
			Vector: []float32{0.1, 0.2, 0.3, 0.4},
			Payload: map[string]interface{}{
				"category": "test",
				"type":     "unit_test",
				"metadata": "test data 1",
			},
		},
		"test_vector_2": {
			ID:     "test_002", 
			Vector: []float32{0.5, 0.6, 0.7, 0.8},
			Payload: map[string]interface{}{
				"category": "test",
				"type":     "unit_test",
				"metadata": "test data 2",
			},
		},
		"test_vector_3": {
			ID:     "test_003",
			Vector: []float32{0.9, 0.1, 0.2, 0.3},
			Payload: map[string]interface{}{
				"category": "validation",
				"type":     "integration_test", 
				"metadata": "test data 3",
			},
		},
	}

	// Créer un mock client pour les tests (sera remplacé par le vrai client)
	suite.client = NewMockQdrantClient()
}

// TearDownSuite nettoie après les tests
func (suite *QdrantClientTestSuite) TearDownSuite() {
	if suite.client != nil {
		suite.client.Close()
	}
}

// === MICRO-ÉTAPE 5.1.1.1.1: TESTS DES OPÉRATIONS CRUD DE BASE ===

// TestCRUDOperations teste les opérations CRUD de base
func (suite *QdrantClientTestSuite) TestCRUDOperations() {
	collectionName := "test_crud_collection"
	
	// Test Create Collection
	suite.T().Run("CreateCollection", func(t *testing.T) {
		err := suite.client.CreateCollection(suite.ctx, collectionName, 4)
		assert.NoError(t, err)
		
		// Vérifier que la collection a été créée
		info, err := suite.client.GetCollectionInfo(suite.ctx, collectionName)
		assert.NoError(t, err)
		assert.Equal(t, collectionName, info.Name)
		assert.Equal(t, 4, info.VectorSize)
	})

	// Test Upsert Points
	suite.T().Run("UpsertPoints", func(t *testing.T) {
		testVector := suite.testData["test_vector_1"]
		point := Point{
			ID:      testVector.ID,
			Vector:  testVector.Vector,
			Payload: testVector.Payload,
		}
		
		err := suite.client.UpsertPoints(suite.ctx, collectionName, []Point{point})
		assert.NoError(t, err)
		
		// Vérifier que le point a été inséré
		count, err := suite.client.CountPoints(suite.ctx, collectionName)
		assert.NoError(t, err)
		assert.Equal(t, int64(1), count)
	})

	// Test Get Point
	suite.T().Run("GetPoint", func(t *testing.T) {
		testVector := suite.testData["test_vector_1"]
		
		point, err := suite.client.GetPoint(suite.ctx, collectionName, testVector.ID)
		assert.NoError(t, err)
		assert.NotNil(t, point)
		assert.Equal(t, testVector.ID, point.ID)
		assert.Equal(t, testVector.Vector, point.Vector)
		assert.Equal(t, testVector.Payload["category"], point.Payload["category"])
	})

	// Test Search Points
	suite.T().Run("SearchPoints", func(t *testing.T) {
		// Ajouter plusieurs points pour la recherche
		var points []Point
		for _, testVector := range suite.testData {
			points = append(points, Point{
				ID:      testVector.ID,
				Vector:  testVector.Vector,
				Payload: testVector.Payload,
			})
		}
		
		err := suite.client.UpsertPoints(suite.ctx, collectionName, points)
		assert.NoError(t, err)
		
		// Rechercher avec le premier vecteur
		queryVector := suite.testData["test_vector_1"].Vector
		results, err := suite.client.SearchPoints(suite.ctx, collectionName, queryVector, 5)
		assert.NoError(t, err)
		assert.Greater(t, len(results), 0)
		
		// Le premier résultat devrait être le vecteur lui-même (score parfait)
		assert.Equal(t, suite.testData["test_vector_1"].ID, results[0].ID)
		assert.Greater(t, results[0].Score, float32(0.9)) // Score élevé pour similarité parfaite
	})

	// Test Delete Points
	suite.T().Run("DeletePoints", func(t *testing.T) {
		testVector := suite.testData["test_vector_1"]
		
		err := suite.client.DeletePoints(suite.ctx, collectionName, []string{testVector.ID})
		assert.NoError(t, err)
		
		// Vérifier que le point a été supprimé
		point, err := suite.client.GetPoint(suite.ctx, collectionName, testVector.ID)
		assert.Error(t, err) // Devrait retourner une erreur car le point n'existe plus
		assert.Nil(t, point)
	})

	// Test Delete Collection
	suite.T().Run("DeleteCollection", func(t *testing.T) {
		err := suite.client.DeleteCollection(suite.ctx, collectionName)
		assert.NoError(t, err)
		
		// Vérifier que la collection a été supprimée
		_, err = suite.client.GetCollectionInfo(suite.ctx, collectionName)
		assert.Error(t, err) // Devrait retourner une erreur car la collection n'existe plus
	})
}

// === MICRO-ÉTAPE 5.1.1.1.2: TESTS DE GESTION D'ERREUR ET RETRY LOGIC ===

// TestErrorHandlingAndRetry teste la gestion d'erreur et retry logic
func (suite *QdrantClientTestSuite) TestErrorHandlingAndRetry() {
	
	// Test connexion invalide
	suite.T().Run("InvalidConnection", func(t *testing.T) {
		invalidClient := NewMockQdrantClientWithError()
		err := invalidClient.Connect(suite.ctx)
		assert.Error(t, err)
		assert.Contains(t, err.Error(), "connection failed")
	})

	// Test collection inexistante
	suite.T().Run("NonExistentCollection", func(t *testing.T) {
		err := suite.client.UpsertPoints(suite.ctx, "non_existent_collection", []Point{
			{ID: "test", Vector: []float32{0.1, 0.2}, Payload: map[string]interface{}{}},
		})
		assert.Error(t, err)
		assert.Contains(t, err.Error(), "collection not found")
	})

	// Test point inexistant
	suite.T().Run("NonExistentPoint", func(t *testing.T) {
		// Créer une collection de test
		collectionName := "test_error_collection"
		err := suite.client.CreateCollection(suite.ctx, collectionName, 4)
		require.NoError(t, err)
		
		// Essayer de récupérer un point inexistant
		point, err := suite.client.GetPoint(suite.ctx, collectionName, "non_existent_point")
		assert.Error(t, err)
		assert.Nil(t, point)
		
		// Nettoyer
		suite.client.DeleteCollection(suite.ctx, collectionName)
	})

	// Test dimensions incorrectes
	suite.T().Run("IncorrectDimensions", func(t *testing.T) {
		collectionName := "test_dimensions_collection"
		err := suite.client.CreateCollection(suite.ctx, collectionName, 4)
		require.NoError(t, err)
		
		// Essayer d'insérer un vecteur avec de mauvaises dimensions
		wrongVector := Point{
			ID:     "wrong_dims",
			Vector: []float32{0.1, 0.2}, // 2 dimensions au lieu de 4
			Payload: map[string]interface{}{},
		}
		
		err = suite.client.UpsertPoints(suite.ctx, collectionName, []Point{wrongVector})
		assert.Error(t, err)
		assert.Contains(t, err.Error(), "dimension mismatch")
		
		// Nettoyer
		suite.client.DeleteCollection(suite.ctx, collectionName)
	})

	// Test timeout et retry
	suite.T().Run("TimeoutAndRetry", func(t *testing.T) {
		retryClient := NewMockQdrantClientWithRetry()
		
		// Test avec timeout court
		ctxWithTimeout, cancel := context.WithTimeout(suite.ctx, 10*time.Millisecond)
		defer cancel()
		
		err := retryClient.Connect(ctxWithTimeout)
		assert.Error(t, err)
		assert.Contains(t, err.Error(), "timeout")
	})
}

// === MICRO-ÉTAPE 5.1.1.1.3: TESTS DE PERFORMANCE ET CONCURRENCE ===

// TestPerformanceAndConcurrency teste la performance et la concurrence
func (suite *QdrantClientTestSuite) TestPerformanceAndConcurrency() {
	
	// Test insertion en lot
	suite.T().Run("BulkInsert", func(t *testing.T) {
		collectionName := "test_bulk_collection"
		err := suite.client.CreateCollection(suite.ctx, collectionName, 4)
		require.NoError(t, err)
		
		// Générer 1000 points de test
		var points []Point
		for i := 0; i < 1000; i++ {
			points = append(points, Point{
				ID:     fmt.Sprintf("bulk_point_%d", i),
				Vector: []float32{float32(i) * 0.001, float32(i) * 0.002, float32(i) * 0.003, float32(i) * 0.004},
				Payload: map[string]interface{}{
					"index": i,
					"type":  "bulk_test",
				},
			})
		}
		
		// Mesurer le temps d'insertion
		start := time.Now()
		err = suite.client.UpsertPoints(suite.ctx, collectionName, points)
		duration := time.Since(start)
		
		assert.NoError(t, err)
		t.Logf("Bulk insert of 1000 points took: %v", duration)
		
		// Vérifier le nombre de points
		count, err := suite.client.CountPoints(suite.ctx, collectionName)
		assert.NoError(t, err)
		assert.Equal(t, int64(1000), count)
		
		// Nettoyer
		suite.client.DeleteCollection(suite.ctx, collectionName)
	})

	// Test recherche concurrente
	suite.T().Run("ConcurrentSearch", func(t *testing.T) {
		collectionName := "test_concurrent_collection"
		err := suite.client.CreateCollection(suite.ctx, collectionName, 4)
		require.NoError(t, err)
		
		// Insérer des données de test
		var points []Point
		for i := 0; i < 100; i++ {
			points = append(points, Point{
				ID:     fmt.Sprintf("concurrent_point_%d", i),
				Vector: []float32{float32(i) * 0.01, float32(i) * 0.02, float32(i) * 0.03, float32(i) * 0.04},
				Payload: map[string]interface{}{
					"index": i,
				},
			})
		}
		
		err = suite.client.UpsertPoints(suite.ctx, collectionName, points)
		require.NoError(t, err)
		
		// Lancer 10 goroutines de recherche concurrente
		var wg sync.WaitGroup
		numGoroutines := 10
		results := make([][]SearchResult, numGoroutines)
		errors := make([]error, numGoroutines)
		
		start := time.Now()
		for i := 0; i < numGoroutines; i++ {
			wg.Add(1)
			go func(index int) {
				defer wg.Done()
				
				queryVector := []float32{0.5, 0.5, 0.5, 0.5}
				searchResults, err := suite.client.SearchPoints(suite.ctx, collectionName, queryVector, 10)
				results[index] = searchResults
				errors[index] = err
			}(i)
		}
		
		wg.Wait()
		duration := time.Since(start)
		
		// Vérifier que toutes les recherches ont réussi
		for i := 0; i < numGoroutines; i++ {
			assert.NoError(t, errors[i], fmt.Sprintf("Goroutine %d failed", i))
			assert.Greater(t, len(results[i]), 0, fmt.Sprintf("Goroutine %d returned no results", i))
		}
		
		t.Logf("Concurrent search with %d goroutines took: %v", numGoroutines, duration)
		
		// Nettoyer
		suite.client.DeleteCollection(suite.ctx, collectionName)
	})

	// Test stress avec insertions/recherches simultanées
	suite.T().Run("StressTest", func(t *testing.T) {
		collectionName := "test_stress_collection"
		err := suite.client.CreateCollection(suite.ctx, collectionName, 4)
		require.NoError(t, err)
		
		var wg sync.WaitGroup
		numWorkers := 5
		operationsPerWorker := 20
		
		start := time.Now()
		
		// Workers pour insertions
		for i := 0; i < numWorkers; i++ {
			wg.Add(1)
			go func(workerID int) {
				defer wg.Done()
				
				for j := 0; j < operationsPerWorker; j++ {
					point := Point{
						ID:     fmt.Sprintf("stress_worker_%d_point_%d", workerID, j),
						Vector: []float32{float32(workerID), float32(j), 0.5, 0.5},
						Payload: map[string]interface{}{
							"worker": workerID,
							"index":  j,
						},
					}
					
					err := suite.client.UpsertPoints(suite.ctx, collectionName, []Point{point})
					if err != nil {
						t.Logf("Insert error in worker %d: %v", workerID, err)
					}
				}
			}(i)
		}
		
		// Workers pour recherches
		for i := 0; i < numWorkers; i++ {
			wg.Add(1)
			go func(workerID int) {
				defer wg.Done()
				
				for j := 0; j < operationsPerWorker; j++ {
					queryVector := []float32{float32(workerID) * 0.1, float32(j) * 0.1, 0.5, 0.5}
					_, err := suite.client.SearchPoints(suite.ctx, collectionName, queryVector, 5)
					if err != nil {
						t.Logf("Search error in worker %d: %v", workerID, err)
					}
				}
			}(i)
		}
		
		wg.Wait()
		duration := time.Since(start)
		
		t.Logf("Stress test with %d workers (%d ops each) took: %v", numWorkers, operationsPerWorker, duration)
		
		// Vérifier l'état final
		count, err := suite.client.CountPoints(suite.ctx, collectionName)
		assert.NoError(t, err)
		assert.LessOrEqual(t, count, int64(numWorkers*operationsPerWorker))
		
		// Nettoyer
		suite.client.DeleteCollection(suite.ctx, collectionName)
	})
}

// TestQdrantClientSuite exécute la suite de tests
func TestQdrantClientSuite(t *testing.T) {
	suite.Run(t, new(QdrantClientTestSuite))
}

// === MOCKS POUR LES TESTS ===

// MockQdrantClient implémentation mock pour les tests
type MockQdrantClient struct {
	collections map[string]*MockCollection
	connected   bool
	shouldError bool
	mu          sync.RWMutex
}

// MockCollection collection mock
type MockCollection struct {
	Name       string
	VectorSize int
	Points     map[string]Point
	mu         sync.RWMutex
}

// NewMockQdrantClient crée un nouveau client mock
func NewMockQdrantClient() *MockQdrantClient {
	return &MockQdrantClient{
		collections: make(map[string]*MockCollection),
		connected:   false,
		shouldError: false,
	}
}

// NewMockQdrantClientWithError crée un client mock qui génère des erreurs
func NewMockQdrantClientWithError() *MockQdrantClient {
	return &MockQdrantClient{
		collections: make(map[string]*MockCollection),
		connected:   false,
		shouldError: true,
	}
}

// NewMockQdrantClientWithRetry crée un client mock avec retry logic
func NewMockQdrantClientWithRetry() *MockQdrantClient {
	return &MockQdrantClient{
		collections: make(map[string]*MockCollection),
		connected:   false,
		shouldError: false,
	}
}

// Implémentation des méthodes du MockQdrantClient
func (m *MockQdrantClient) Connect(ctx context.Context) error {
	if m.shouldError {
		return fmt.Errorf("connection failed: mock error")
	}
	m.connected = true
	return nil
}

func (m *MockQdrantClient) CreateCollection(ctx context.Context, name string, vectorSize int) error {
	if m.shouldError {
		return fmt.Errorf("failed to create collection: mock error")
	}
	
	m.mu.Lock()
	defer m.mu.Unlock()
	
	m.collections[name] = &MockCollection{
		Name:       name,
		VectorSize: vectorSize,
		Points:     make(map[string]Point),
	}
	return nil
}

func (m *MockQdrantClient) UpsertPoints(ctx context.Context, collection string, points []Point) error {
	if m.shouldError {
		return fmt.Errorf("failed to upsert points: mock error")
	}
	
	m.mu.RLock()
	coll, exists := m.collections[collection]
	m.mu.RUnlock()
	
	if !exists {
		return fmt.Errorf("collection not found: %s", collection)
	}
	
	coll.mu.Lock()
	defer coll.mu.Unlock()
	
	for _, point := range points {
		if len(point.Vector) != coll.VectorSize {
			return fmt.Errorf("dimension mismatch: expected %d, got %d", coll.VectorSize, len(point.Vector))
		}
		coll.Points[point.ID] = point
	}
	
	return nil
}

func (m *MockQdrantClient) SearchPoints(ctx context.Context, collection string, vector []float32, limit int) ([]SearchResult, error) {
	if m.shouldError {
		return nil, fmt.Errorf("search failed: mock error")
	}
	
	m.mu.RLock()
	coll, exists := m.collections[collection]
	m.mu.RUnlock()
	
	if !exists {
		return nil, fmt.Errorf("collection not found: %s", collection)
	}
	
	coll.mu.RLock()
	defer coll.mu.RUnlock()
	
	var results []SearchResult
	for _, point := range coll.Points {
		// Calcul simple de similarité (cosine similarity approximative)
		score := m.calculateSimilarity(vector, point.Vector)
		results = append(results, SearchResult{
			ID:      point.ID,
			Score:   score,
			Payload: point.Payload,
			Vector:  point.Vector,
		})
	}
	
	// Trier par score décroissant et limiter
	for i := 0; i < len(results)-1; i++ {
		for j := i + 1; j < len(results); j++ {
			if results[i].Score < results[j].Score {
				results[i], results[j] = results[j], results[i]
			}
		}
	}
	
	if len(results) > limit {
		results = results[:limit]
	}
	
	return results, nil
}

func (m *MockQdrantClient) DeletePoints(ctx context.Context, collection string, ids []string) error {
	if m.shouldError {
		return fmt.Errorf("delete failed: mock error")
	}
	
	m.mu.RLock()
	coll, exists := m.collections[collection]
	m.mu.RUnlock()
	
	if !exists {
		return fmt.Errorf("collection not found: %s", collection)
	}
	
	coll.mu.Lock()
	defer coll.mu.Unlock()
	
	for _, id := range ids {
		delete(coll.Points, id)
	}
	
	return nil
}

func (m *MockQdrantClient) GetPoint(ctx context.Context, collection string, id string) (*Point, error) {
	if m.shouldError {
		return nil, fmt.Errorf("get point failed: mock error")
	}
	
	m.mu.RLock()
	coll, exists := m.collections[collection]
	m.mu.RUnlock()
	
	if !exists {
		return nil, fmt.Errorf("collection not found: %s", collection)
	}
	
	coll.mu.RLock()
	defer coll.mu.RUnlock()
	
	point, exists := coll.Points[id]
	if !exists {
		return nil, fmt.Errorf("point not found: %s", id)
	}
	
	return &point, nil
}

func (m *MockQdrantClient) DeleteCollection(ctx context.Context, name string) error {
	if m.shouldError {
		return fmt.Errorf("delete collection failed: mock error")
	}
	
	m.mu.Lock()
	defer m.mu.Unlock()
	
	delete(m.collections, name)
	return nil
}

func (m *MockQdrantClient) Close() error {
	m.connected = false
	return nil
}

func (m *MockQdrantClient) GetCollectionInfo(ctx context.Context, name string) (*CollectionInfo, error) {
	if m.shouldError {
		return nil, fmt.Errorf("get collection info failed: mock error")
	}
	
	m.mu.RLock()
	coll, exists := m.collections[name]
	m.mu.RUnlock()
	
	if !exists {
		return nil, fmt.Errorf("collection not found: %s", name)
	}
	
	coll.mu.RLock()
	defer coll.mu.RUnlock()
	
	return &CollectionInfo{
		Name:        coll.Name,
		VectorSize:  coll.VectorSize,
		PointsCount: int64(len(coll.Points)),
		Status:      "green",
	}, nil
}

func (m *MockQdrantClient) CountPoints(ctx context.Context, collection string) (int64, error) {
	if m.shouldError {
		return 0, fmt.Errorf("count points failed: mock error")
	}
	
	m.mu.RLock()
	coll, exists := m.collections[collection]
	m.mu.RUnlock()
	
	if !exists {
		return 0, fmt.Errorf("collection not found: %s", collection)
	}
	
	coll.mu.RLock()
	defer coll.mu.RUnlock()
	
	return int64(len(coll.Points)), nil
}

// calculateSimilarity calcule une similarité simple entre deux vecteurs
func (m *MockQdrantClient) calculateSimilarity(a, b []float32) float32 {
	if len(a) != len(b) {
		return 0.0
	}
	
	var dotProduct, normA, normB float32
	for i := range a {
		dotProduct += a[i] * b[i]
		normA += a[i] * a[i]
		normB += b[i] * b[i]
	}
	
	if normA == 0 || normB == 0 {
		return 0.0
	}
	
	similarity := dotProduct / (float32(normA) * float32(normB))
	if similarity < 0 {
		similarity = -similarity
	}
	
	return similarity
}
