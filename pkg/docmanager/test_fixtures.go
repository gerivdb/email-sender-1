package docmanager

import (
	"io/ioutil"
	"os"
)

type Document struct {
	Title   string
	Content string
}

type DocumentConflict struct {
	DocA *Document
	DocB *Document
}

func CreateTestDocument(title, content string) *Document {
	return &Document{Title: title, Content: content}
}

func CreateTestConflict(docA, docB *Document) *DocumentConflict {
	return &DocumentConflict{DocA: docA, DocB: docB}
}

func CreateTempTestFiles(count int) ([]string, func()) {
	files := make([]string, count)
	dirs := make([]string, count)
	for i := 0; i < count; i++ {
		dir, _ := ioutil.TempDir("", "testfile_")
		file := dir + "/file.txt"
		_ = ioutil.WriteFile(file, []byte("test content"), 0644)
		files[i] = file
		dirs[i] = dir
	}
	cleanup := func() {
		for _, dir := range dirs {
			_ = os.RemoveAll(dir)
		}
	}
	return files, cleanup
}
