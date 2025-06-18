package main

import (
	"testing"

	"github.com/qdrant/go-client/qdrant"
	"github.com/stretchr/testify/assert"
)

func TestQdrantImport(t *testing.T) {
	// Test simple pour valider l'import Qdrant
	config := &qdrant.Config{
		Host: "localhost",
		Port: 6334,
	}
	assert.NotNil(t, config)
	assert.Equal(t, "localhost", config.Host)
}
