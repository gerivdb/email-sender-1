package integration

import (
	"testing"

	"github.com/stretchr/testify/assert"
)

// TestFinalPush_100Coverage - Viser les dernières lignes non couvertes
func TestFinalPush_100Coverage(t *testing.T) {
	t.Run("JSONWebhookTransformer_GetContentType", func(t *testing.T) {
		transformer := NewJSONWebhookTransformer()

		// Test GetContentType - appel direct
		contentType := transformer.GetContentType()
		assert.Equal(t, "application/json", contentType)

		// Test multiple fois pour s'assurer que c'est toujours constant
		contentType2 := transformer.GetContentType()
		assert.Equal(t, contentType, contentType2)
	})

	t.Run("HMACAuthenticator_GetHeaders_FullCoverage", func(t *testing.T) {
		auth := NewHMACWebhookAuthenticator()

		// Test GetHeaders avec payload et secret
		headers := auth.GetHeaders([]byte("test payload"), "secret123")
		assert.NotNil(t, headers)
		assert.Contains(t, headers, "X-Webhook-Signature")
		assert.Contains(t, headers, "X-Webhook-Timestamp")

		// Test avec payload vide
		headers2 := auth.GetHeaders([]byte(""), "secret123")
		assert.NotNil(t, headers2)
		assert.Contains(t, headers2, "X-Webhook-Signature")

		// Test avec différents secrets
		headers3 := auth.GetHeaders([]byte("test"), "different-secret")
		assert.NotNil(t, headers3)
		assert.NotEqual(t, headers["X-Webhook-Signature"], headers3["X-Webhook-Signature"])
	})
}
