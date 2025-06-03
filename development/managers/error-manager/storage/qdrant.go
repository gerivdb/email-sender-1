package errormanager

import (
	"context"
	"fmt"

	"github.com/qdrant/go-client/qdrant"
	"github.com/qdrant/go-client/qdrant/api"
)

var qdrantClient *qdrant.Client

// InitializeQdrant initializes the Qdrant client
func InitializeQdrant(endpoint string) error {
	config := &qdrant.Config{
		Host: endpoint,
	}
	var err error
	qdrantClient, err = qdrant.NewClient(config)
	if err != nil {
		return fmt.Errorf("failed to initialize Qdrant client: %w", err)
	}
	return nil
}

// StoreErrorVector stores an error vector in Qdrant
func StoreErrorVector(collection string, vector []float32, payload map[string]interface{}) error {
	if qdrantClient == nil {
		return fmt.Errorf("Qdrant client is not initialized")
	}

	points := []api.PointStruct{
		{
			Vector:  vector,
			Payload: payload,
		},
	}

	_, err := qdrantClient.Upsert(context.Background(), collection, points)
	if err != nil {
		return fmt.Errorf("failed to store error vector: %w", err)
	}

	return nil
}
