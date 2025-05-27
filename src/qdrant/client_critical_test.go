package qdrant_test

import (
    "testing"
    "time"
)

// 🎯 TDD Inversé - Tests critiques AVANT implémentation
// ROI: +24h (test guide l'implémentation + bugs détectés tôt)

// Vector represents an embedding vector for Email Sender
type Vector struct {
    ID       string                 `json:"id"`
    Vector   []float32             `json:"vector"`
    Payload  map[string]interface{} `json:"payload"`
}

// Test critique #1: Migration gRPC→HTTP DOIT fonctionner
func TestQdrantHTTPClient_MustWork(t *testing.T) {
    t.Log("🎯 Test critique: Migration HTTP doit fonctionner")
    
    // Ce test guide l'implémentation
    client := NewHTTPClient("http://localhost:6333")
    
    // Cas d'usage réel Email Sender: vectorisation d'emails
    emailVector := generateEmailVector("test@venue.com")
    vectors := []Vector{emailVector}
    
    err := client.UpsertPoints("email_contacts", vectors)
    if err != nil {
        t.Fatalf("❌ Migration gRPC→HTTP échouée: %v", err)
    }
    
    t.Log("✅ Migration HTTP validée")
}

// Test critique #2: Performance batch DOIT être acceptable
func TestQdrantHTTPClient_BatchPerformance(t *testing.T) {
    t.Log("🎯 Test critique: Performance batch")
    
    client := NewHTTPClient("http://localhost:6333")
    
    // Simulation batch de 100 contacts (cas réel)
    vectors := make([]Vector, 100)
    for i := 0; i < 100; i++ {
        vectors[i] = generateEmailVector(fmt.Sprintf("contact%d@venue.com", i))
    }
    
    start := time.Now()
    err := client.UpsertPointsBatch("email_contacts", vectors)
    duration := time.Since(start)
    
    if err != nil {
        t.Fatalf("❌ Batch upsert échoué: %v", err)
    }
    
    // Performance requirement: <2 secondes pour 100 contacts
    if duration > 2*time.Second {
        t.Fatalf("❌ Performance inacceptable: %v (max: 2s)", duration)
    }
    
    t.Logf("✅ Batch performance: %v pour 100 contacts", duration)
}

// Test critique #3: Recherche vectorielle DOIT retourner résultats pertinents
func TestQdrantHTTPClient_VectorSearch(t *testing.T) {
    t.Log("🎯 Test critique: Recherche vectorielle")
    
    client := NewHTTPClient("http://localhost:6333")
    
    // Index some test vectors
    testVectors := []Vector{
        generateEmailVector("jazz@venue.com"),
        generateEmailVector("rock@venue.com"),
        generateEmailVector("classical@venue.com"),
    }
    
    err := client.UpsertPoints("email_contacts", testVectors)
    if err != nil {
        t.Fatalf("❌ Setup test data échoué: %v", err)
    }
    
    // Search for similar vectors
    queryVector := generateEmailVector("jazz@venue.com")
    results, err := client.SearchSimilar("email_contacts", queryVector.Vector, 5)
    
    if err != nil {
        t.Fatalf("❌ Recherche vectorielle échouée: %v", err)
    }
    
    if len(results) == 0 {
        t.Fatalf("❌ Aucun résultat trouvé")
    }
    
    // Le premier résultat doit être très similaire (score > 0.9)
    if results[0].Score < 0.9 {
        t.Fatalf("❌ Score trop faible: %f (attendu > 0.9)", results[0].Score)
    }
    
    t.Logf("✅ Recherche vectorielle: %d résultats, meilleur score: %f", 
           len(results), results[0].Score)
}

// Helper: génère un vecteur simulé pour email
func generateEmailVector(email string) Vector {
    // Simulation: vecteur basé sur hash de l'email
    vector := make([]float32, 384) // Dimension standard
    
    // Simple hash-based vector generation for testing
    hash := simpleHash(email)
    for i := 0; i < 384; i++ {
        vector[i] = float32((hash + i) % 1000) / 1000.0
    }
    
    return Vector{
        ID:     email,
        Vector: vector,
        Payload: map[string]interface{}{
            "email":      email,
            "type":       "contact",
            "created_at": time.Now().Unix(),
        },
    }
}

func simpleHash(s string) int {
    h := 0
    for _, c := range s {
        h = 31*h + int(c)
    }
    return h
}