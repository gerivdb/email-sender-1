// core/scanmodules/scanmodules_test.go
package scanmodules

import (
	"os"
	"testing"
)

// TestMain est une fonction spéciale qui s'exécute avant tous les tests du package.
// Elle permet de configurer l'environnement de test et de nettoyer après l'exécution des tests.
func TestMain(m *testing.M) {
	// Créer un répertoire temporaire pour les fichiers de sortie
	tempDir, err := os.MkdirTemp("", "test_scanmodules")
	if err != nil {
		panic(err)
	}
	defer os.RemoveAll(tempDir) // Nettoyer après les tests

	// Changer le répertoire de travail pour le répertoire temporaire
	originalDir, err := os.Getwd()
	if err != nil {
		panic(err)
	}
	err = os.Chdir(tempDir)
	if err != nil {
		panic(err)
	}
	defer os.Chdir(originalDir) // Revenir au répertoire d'origine après les tests

	// Exécuter les tests
	exitCode := m.Run()

	os.Exit(exitCode)
}

func TestRunScanModules(t *testing.T) {
	// Exécuter la fonction RunScanModules
	err := RunScanModules()
	if err != nil {
		t.Fatalf("RunScanModules a retourné une erreur: %v", err)
	}

	// Vérifier que les fichiers de sortie existent
	files := []string{"arborescence.txt", "modules.txt", "modules.json"}
	for _, file := range files {
		_, err := os.Stat(file)
		if os.IsNotExist(err) {
			t.Errorf("Le fichier %s n'a pas été créé", file)
		}
	}
}
