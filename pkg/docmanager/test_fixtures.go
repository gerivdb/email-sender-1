package docmanager

import (
	"io/ioutil"
	"os"
	"time"
)

// CreateTestDocument crée un document de test avec des valeurs déterministes
func CreateTestDocument(id, path string, content string, version int) *Document {
	return &Document{
		ID:       id,
		Path:     path,
		Content:  []byte(content),
		Metadata: map[string]interface{}{"test": true},
		Version:  version,
	}
}

// CreateTestConflict crée un conflit de document de test
func CreateTestConflict(local, remote *Document) *DocumentConflict {
	return &DocumentConflict{
		ID:           "conflict-001",
		Type:         ContentConflict,
		LocalDoc:     local,
		RemoteDoc:    remote,
		ConflictedAt: time.Date(2020, 1, 1, 0, 0, 0, 0, time.UTC),
		Context:      map[string]interface{}{"test": true},
	}
}

// CreateTempTestFiles crée des fichiers temporaires pour les tests et retourne un cleanup
func CreateTempTestFiles(count int) ([]string, func()) {
	files := make([]string, count)
	for i := 0; i < count; i++ {
		f, err := ioutil.TempFile("", "testfile-*.txt")
		if err != nil {
			panic(err)
		}
		if _, err := f.Write([]byte("test content")); err != nil {
			panic(err)
		}
		f.Close()
		files[i] = f.Name()
	}
	cleanup := func() {
		for _, f := range files {
			os.Remove(f)
		}
	}
	return files, cleanup
}
