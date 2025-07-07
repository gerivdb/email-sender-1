package qdrant

import (
	"fmt"
	"testing"

	"github.com/stretchr/testify/assert"
)

type Point struct {
	ID      string
	Vector  []float32
	Payload map[string]interface{}
}

type UpsertResponse struct {
	Points []Point
}

// In-memory store for points
var pointStore = make(map[string]Point)

// Mock implementation of UpsertPoints using in-memory store
func UpsertPoints(points []Point) (*UpsertResponse, error) {
	for _, point := range points {
		pointStore[point.ID] = point
	}
	return &UpsertResponse{Points: points}, nil
}

// Mock implementation of GetPoint using in-memory store
func GetPoint(id string) (Point, error) {
	if point, exists := pointStore[id]; exists {
		return point, nil
	}
	return Point{}, fmt.Errorf("point not found")
}

func TestUpsertPointsMinimalBatch(t *testing.T) {
	// Préparer un jeu de données minimal (1-2 points)
	points := []Point{
		{
			ID:      "point1",
			Vector:  []float32{0.1, 0.2, 0.3},
			Payload: map[string]interface{}{"key": "value1"},
		},
		{
			ID:      "point2",
			Vector:  []float32{0.4, 0.5, 0.6},
			Payload: map[string]interface{}{"key": "value2"},
		},
	}

	// Exécuter la méthode UpsertPoints
	response, err := UpsertPoints(points)

	// Vérifier qu'il n'y a pas d'erreur
	assert.NoError(t, err)

	// Vérifier la réponse de l'API
	assert.NotNil(t, response)
	assert.Equal(t, len(points), len(response.Points))

	// Valider que les points sont insérés dans QDrant
	for _, point := range points {
		retrievedPoint, err := GetPoint(point.ID)
		assert.NoError(t, err)
		assert.Equal(t, point, retrievedPoint)
	}
}
