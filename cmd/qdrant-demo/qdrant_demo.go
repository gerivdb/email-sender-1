<<<<<<< HEAD:cmd/qdrant-demo/qdrant_demo.go
package qdrant_demo

import (
	"fmt"
	"log"
	"os"

	"email_sender/src/qdrant"
)

func main() {
	// Load environment variables if .env.qdrant exists
	if _, err := os.Stat(".env.qdrant"); err == nil {
		log.Println("Using .env.qdrant configuration")
		// In a real application, you would load the .env file here
	}

	// Create Qdrant client with automatic mode detection
	client, err := qdrant.NewAutoClient()
	if err != nil {
		log.Fatalf("Failed to create Qdrant client: %v", err)
	}
	defer client.Close()

	// Check what mode we're using
	stats := client.GetStats()
	mode := stats["mode"].(string)
	fmt.Printf("✅ Qdrant client created in %s mode\n", mode)

	// Test health check
	if err := client.HealthCheck(); err != nil {
		log.Fatalf("Health check failed: %v", err)
	}
	fmt.Println("✅ Health check passed")

	// Create a test collection
	collectionName := "test_emails"
	vectorSize := 384	// Typical embedding size

	err = client.CreateCollection(collectionName, vectorSize)
	if err != nil {
		log.Fatalf("Failed to create collection: %v", err)
	}
	fmt.Printf("✅ Collection '%s' created\n", collectionName)

	// Add some test points
	points := []qdrant.Point{
		{
			ID:	"email_1",
			Vector:	generateRandomVector(vectorSize),
			Payload: map[string]interface{}{
				"subject":	"Welcome to our service",
				"sender":	"welcome@company.com",
				"type":		"welcome",
			},
		},
		{
			ID:	"email_2",
			Vector:	generateRandomVector(vectorSize),
			Payload: map[string]interface{}{
				"subject":	"Your order confirmation",
				"sender":	"orders@company.com",
				"type":		"order",
			},
		},
	}

	err = client.UpsertPoints(collectionName, points)
	if err != nil {
		log.Fatalf("Failed to upsert points: %v", err)
	}
	fmt.Printf("✅ Added %d points to collection\n", len(points))

	// Perform a search
	searchRequest := qdrant.SearchRequest{
		Vector:		generateRandomVector(vectorSize),
		Limit:		5,
		WithPayload:	true,
	}

	results, err := client.Search(collectionName, searchRequest)
	if err != nil {
		log.Fatalf("Search failed: %v", err)
	}
	fmt.Printf("✅ Search returned %d results\n", len(results))

	// Display results
	for i, result := range results {
		fmt.Printf("  Result %d: ID=%v, Score=%.4f\n", i+1, result.ID, result.Score)
		if subject, ok := result.Payload["subject"].(string); ok {
			fmt.Printf("    Subject: %s\n", subject)
		}
	}

	// Get collection info
	info, err := client.GetCollectionInfo(collectionName)
	if err != nil {
		log.Fatalf("Failed to get collection info: %v", err)
	}
	fmt.Printf("✅ Collection info: %d points, vector size %d\n", info.PointsCount, info.VectorSize)

	// Clean up
	err = client.DeleteCollection(collectionName)
	if err != nil {
		log.Printf("⚠️  Failed to delete collection: %v", err)
	} else {
		fmt.Printf("✅ Collection '%s' deleted\n", collectionName)
	}

	// Final stats
	finalStats := client.GetStats()
	fmt.Println("\n📊 Final Statistics:")
	for key, value := range finalStats {
		fmt.Printf("  %s: %v\n", key, value)
	}
}

// generateRandomVector creates a random normalized vector for testing
func generateRandomVector(size int) []float32 {
	vector := make([]float32, size)
	var magnitude float32

	// Generate random values
	for i := 0; i < size; i++ {
		vector[i] = float32(1.0 - 2.0*float64(i%1000)/1000.0)	// Simple deterministic pattern
		magnitude += vector[i] * vector[i]
	}

	// Normalize
	magnitude = float32(1.0)	// Simplified normalization for demo
	for i := 0; i < size; i++ {
		vector[i] /= magnitude
	}

	return vector
}
=======
package main

import (
	"fmt"
	"log"
	"os"

	"github.com/gerivdb/email-sender-1/src/qdrant"
)

func main() {
	// Load environment variables if .env.qdrant exists
	if _, err := os.Stat(".env.qdrant"); err == nil {
		log.Println("Using .env.qdrant configuration")
		// In a real application, you would load the .env file here
	}

	// Create Qdrant client with automatic mode detection
	client, err := qdrant.NewAutoClient()
	if err != nil {
		log.Fatalf("Failed to create Qdrant client: %v", err)
	}
	defer client.Close()

	// Check what mode we're using
	stats := client.GetStats()
	mode := stats["mode"].(string)
	fmt.Printf("✅ Qdrant client created in %s mode\n", mode)

	// Test health check
	if err := client.HealthCheck(); err != nil {
		log.Fatalf("Health check failed: %v", err)
	}
	fmt.Println("✅ Health check passed")

	// Create a test collection
	collectionName := "test_emails"
	vectorSize := 384 // Typical embedding size

	err = client.CreateCollection(collectionName, vectorSize)
	if err != nil {
		log.Fatalf("Failed to create collection: %v", err)
	}
	fmt.Printf("✅ Collection '%s' created\n", collectionName)

	// Add some test points
	points := []qdrant.Point{
		{
			ID:     "email_1",
			Vector: generateRandomVector(vectorSize),
			Payload: map[string]interface{}{
				"subject": "Welcome to our service",
				"sender":  "welcome@company.com",
				"type":    "welcome",
			},
		},
		{
			ID:     "email_2",
			Vector: generateRandomVector(vectorSize),
			Payload: map[string]interface{}{
				"subject": "Your order confirmation",
				"sender":  "orders@company.com",
				"type":    "order",
			},
		},
	}

	err = client.UpsertPoints(collectionName, points)
	if err != nil {
		log.Fatalf("Failed to upsert points: %v", err)
	}
	fmt.Printf("✅ Added %d points to collection\n", len(points))

	// Perform a search
	searchRequest := qdrant.SearchRequest{
		Vector:      generateRandomVector(vectorSize),
		Limit:       5,
		WithPayload: true,
	}

	results, err := client.Search(collectionName, searchRequest)
	if err != nil {
		log.Fatalf("Search failed: %v", err)
	}
	fmt.Printf("✅ Search returned %d results\n", len(results))

	// Display results
	for i, result := range results {
		fmt.Printf("  Result %d: ID=%v, Score=%.4f\n", i+1, result.ID, result.Score)
		if subject, ok := result.Payload["subject"].(string); ok {
			fmt.Printf("    Subject: %s\n", subject)
		}
	}

	// Get collection info
	info, err := client.GetCollectionInfo(collectionName)
	if err != nil {
		log.Fatalf("Failed to get collection info: %v", err)
	}
	fmt.Printf("✅ Collection info: %d points, vector size %d\n", info.PointsCount, info.VectorSize)

	// Clean up
	err = client.DeleteCollection(collectionName)
	if err != nil {
		log.Printf("⚠️  Failed to delete collection: %v", err)
	} else {
		fmt.Printf("✅ Collection '%s' deleted\n", collectionName)
	}

	// Final stats
	finalStats := client.GetStats()
	fmt.Println("\n📊 Final Statistics:")
	for key, value := range finalStats {
		fmt.Printf("  %s: %v\n", key, value)
	}
}

// generateRandomVector creates a random normalized vector for testing
func generateRandomVector(size int) []float32 {
	vector := make([]float32, size)
	var magnitude float32

	// Generate random values
	for i := 0; i < size; i++ {
		vector[i] = float32(1.0 - 2.0*float64(i%1000)/1000.0) // Simple deterministic pattern
		magnitude += vector[i] * vector[i]
	}

	// Normalize
	magnitude = float32(1.0) // Simplified normalization for demo
	for i := 0; i < size; i++ {
		vector[i] /= magnitude
	}

	return vector
}
>>>>>>> migration/gateway-manager-v77:cmd/qdrant-demo/main.go
