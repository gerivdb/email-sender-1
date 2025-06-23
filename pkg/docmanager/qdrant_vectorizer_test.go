// SPDX-License-Identifier: MIT
// Test QDrant Vectorizer Implementation
package docmanager

import (
	"testing"

	"github.com/stretchr/testify/assert"
)

func TestQDrantVectorizer_MockIntegration(t *testing.T) {
	client := NewMockQDrantClient()
	vectorizer := QDrantVectorizer{
		client:         client,
		collectionName: "test-collection",
		vectorSize:     3,
		connected:      true,
	}

	// 1. Création de collection
	err := client.CreateCollection("test-collection", 3)
	assert.NoError(t, err)
	info, err := client.GetCollectionInfo("test-collection")
	assert.NoError(t, err)
	assert.Equal(t, "test-collection", info.Name)
	assert.Equal(t, 3, info.VectorSize)

	// 2. Indexation d'un document
	point := QDrantPoint{
		ID:      "doc1",
		Vector:  []float64{0.1, 0.2, 0.3},
		Payload: map[string]interface{}{"title": "Test Doc"},
	}
	err = client.UpsertPoints("test-collection", []QDrantPoint{point})
	assert.NoError(t, err)

	// 3. Recherche sémantique simulée
	searchResp, err := client.SearchPoints("test-collection", []float64{0.1, 0.2, 0.3}, 1, nil)
	assert.NoError(t, err)
	assert.Len(t, searchResp.Result, 1)
	assert.Equal(t, "doc1", searchResp.Result[0].ID)

	// 4. Gestion d'erreur (collection inconnue)
	_, err = client.GetCollectionInfo("unknown")
	assert.Error(t, err)

	// 5. Vérification de la configuration/connexion
	health, err := client.GetHealth()
	assert.NoError(t, err)
	assert.Equal(t, "ok", health.Status)
}
