package graphgen

import (
	"os"
	"path/filepath"
	"testing"
)

func TestGenerateGraphData(t *testing.T) {
	// Cas 1 : Aucune source (devrait générer un graphe vide ou par défaut)
	data, err := GenerateGraphData([]string{})
	if err != nil {
		t.Errorf("GenerateGraphData a échoué pour des sources vides : %v", err)
	}
	if data == nil {
		t.Error("GenerateGraphData a retourné des données nil pour des sources vides")
	}
	// Vérifier la présence des clés attendues
	if _, ok := data["nodes"]; !ok {
		t.Error("La clé 'nodes' est manquante dans les données du graphe.")
	}
	if _, ok := data["edges"]; !ok {
		t.Error("La clé 'edges' est manquante dans les données du graphe.")
	}

	// Cas 2 : Avec des sources simulées
	sources := []string{"source1.go", "source2.ts"}
	data, err = GenerateGraphData(sources)
	if err != nil {
		t.Errorf("GenerateGraphData a échoué pour des sources simulées : %v", err)
	}
	if data == nil {
		t.Error("GenerateGraphData a retourné des données nil pour des sources simulées")
	}
	if metadata, ok := data["metadata"].(map[string]string); ok {
		if metadata["sources"] != "[source1.go source2.ts]" {
			t.Errorf("Les sources dans les métadonnées ne correspondent pas. Attendu : '[source1.go source2.ts]', Obtenu : '%s'", metadata["sources"])
		}
	} else {
		t.Error("Les métadonnées sont manquantes ou ne sont pas du bon type.")
	}
}

func TestExportGraphScan(t *testing.T) {
	tempDir := t.TempDir()
	outputPath := filepath.Join(tempDir, "graphgen-scan.json")
	testData := map[string]interface{}{
		"nodes": []map[string]string{{"id": "testNode"}},
		"edges": []map[string]string{},
	}

	err := ExportGraphScan(outputPath, testData)
	if err != nil {
		t.Errorf("ExportGraphScan a échoué : %v", err)
	}

	// Vérifier si le fichier a été créé
	_, err = os.Stat(outputPath)
	if os.IsNotExist(err) {
		t.Errorf("Le fichier de sortie n'a pas été créé : %v", err)
	}

	// Lire le contenu et vérifier qu'il est valide JSON (simple vérification pour le moment)
	content, err := os.ReadFile(outputPath)
	if err != nil {
		t.Errorf("Erreur lors de la lecture du fichier de sortie : %v", err)
	}
	if len(content) == 0 {
		t.Error("Le fichier de sortie est vide")
	}
	// Une vérification plus robuste impliquerait un unmarshalling JSON
}
