package main

import (
	"os"
	"testing"
)

func TestRoadmapsIndexGeneration(t *testing.T) {
	_ = os.Remove("roadmaps_index.md")
	main()
	if _, err := os.Stat("roadmaps_index.md"); os.IsNotExist(err) {
		t.Fatalf("roadmaps_index.md n'a pas été généré")
	}
	_ = os.Remove("roadmaps_index.md")
}
