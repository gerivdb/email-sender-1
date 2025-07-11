package main

import (
	"os"
	"testing"

	"github.com/stretchr/testify/assert"
)

func TestScanFile(t *testing.T) {
	content := []byte("logger.info('test')")
	sources, err := scanFile("test.go", content)
	assert.NoError(t, err)
	assert.Len(t, sources, 1)
	assert.Equal(t, sources[0].Type, "logger")
}

func TestGenerateMarkdown(t *testing.T) {
	sources := []ObservabilitySource{
		{
			Path:    "test.go",
			Type:    "logger",
			Content: "logger.info('test')",
		},
	}
	filename := "test.md"
	err := generateMarkdown(filename, sources)
	assert.NoError(t, err)
	defer os.Remove(filename)

	// Vérifier si le fichier a été créé
	_, err = os.Stat(filename)
	assert.NoError(t, err)

	// Vérifier le contenu du fichier (optionnel)
	// content, err := os.ReadFile(filename)
	// assert.NoError(t, err)
	// assert.Contains(t, string(content), "logger.info('test')")
}

func TestGenerateJSON(t *testing.T) {
	sources := []ObservabilitySource{
		{
			Path:    "test.go",
			Type:    "logger",
			Content: "logger.info('test')",
		},
	}
	filename := "test.json"
	err := generateJSON(filename, sources)
	assert.NoError(t, err)
	defer os.Remove(filename)

	// Vérifier si le fichier a été créé
	_, err = os.Stat(filename)
	assert.NoError(t, err)

	// Vérifier le contenu du fichier (optionnel)
	// content, err := os.ReadFile(filename)
	// assert.NoError(t, err)
	// assert.Contains(t, string(content), "logger.info('test')")
}
