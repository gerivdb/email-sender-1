package _

import (
	"testing"

	"github.com/redis/go-redis/v9"
	"github.com/stretchr/testify/assert"
)

func TestRedisImport(t *testing.T) {
	// Test simple pour valider l'import Redis
	client := redis.NewClient(&redis.Options{
		Addr: "localhost:6379",
	})
	assert.NotNil(t, client)
}

func TestTestifyImport(t *testing.T) {
	// Test simple pour valider l'import Testify
	assert.True(t, true)
	assert.Equal(t, 1, 1)
}
