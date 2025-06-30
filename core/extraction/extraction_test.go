package extraction

import (
	"os"
	"path/filepath"
	"testing"
)

func TestExtractAndParseData(t *testing.T) {
	// Créer un fichier temporaire pour le test
	tempDir := t.TempDir()
	tempFile := filepath.Join(tempDir, "test_source.txt")
	err := os.WriteFile(tempFile, []byte("test content"), 0644)
	if err != nil {
		t.Fatalf("Erreur lors de la création du fichier temporaire : %v", err)
	}

	// Cas 1 : Chemin source valide
	data, err := ExtractAndParseData(tempFile)
	if err != nil {
		t.Errorf("ExtractAndParseData a échoué pour un chemin valide : %v", err)
	}
	if data == nil {
		t.Error("ExtractAndParseData a retourné des données nil pour un chemin valide")
	}
	if data["status"] != "success" {
		t.Errorf("Statut attendu 'success', obtenu '%v'", data["status"])
	}

	// Cas 2 : Chemin source inexistant
	_, err = ExtractAndParseData("chemin/inexistant/fichier.txt")
	if err == nil {
		t.Error("ExtractAndParseData devrait échouer pour un chemin inexistant, mais a réussi")
	}
}

func TestGenerateExtractionParsingScan(t *testing.T) {
	tempDir := t.TempDir()
	outputPath := filepath.Join(tempDir, "extraction-parsing-scan.json")
	testData := map[string]interface{}{
		"key": "value",
	}

	err := GenerateExtractionParsingScan(outputPath, testData)
	if err != nil {
		t.Errorf("GenerateExtractionParsingScan a échoué : %v", err)
	}

	// Vérifier si le fichier a été créé
	_, err = os.Stat(outputPath)
	if os.IsNotExist(err) {
		t.Errorf("Le fichier de sortie n'a pas été créé : %v", err)
	}

	// Lire le contenu et vérifier qu'il n'est pas vide (une vérification plus approfondie nécessiterait un parsing JSON)
	content, err := os.ReadFile(outputPath)
	if err != nil {
		t.Errorf("Erreur lors de la lecture du fichier de sortie : %v", err)
	}
	if len(content) == 0 {
		t.Error("Le fichier de sortie est vide")
	}
}
