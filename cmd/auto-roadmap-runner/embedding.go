// cmd/auto-roadmap-runner/embedding.go
package main

import (
	"encoding/json"
	"math/rand"
	"os"
	"time"
)

func GenerateEmbeddings() error {
	data, err := os.ReadFile("projet/roadmaps/plans/consolidated/roadmaps.json")
	if err != nil {
		return err
	}
	var roadmaps []Roadmap
	if err := json.Unmarshal(data, &roadmaps); err != nil {
		return err
	}
	rand.Seed(time.Now().UnixNano())
	for i := range roadmaps {
		vec := make([]float64, 128)
		for j := range vec {
			vec[j] = rand.Float64()
		}
		roadmaps[i].Embeddings = vec
	}
	out, marshalErr := json.MarshalIndent(roadmaps, "", "  ")
	if marshalErr != nil {
		return marshalErr
	}
	return os.WriteFile("projet/roadmaps/plans/consolidated/roadmaps.json", out, 0o644)
}
