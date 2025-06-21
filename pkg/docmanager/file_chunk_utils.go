package docmanager

import (
	"bufio"
	"fmt"
	"os"
)

// ProcessFileByChunks lit un fichier texte par blocs de N lignes et appelle handler à chaque chunk.
func ProcessFileByChunks(path string, chunkSize int, handler func([]string) error) error {
	file, err := os.Open(path)
	if err != nil {
		return err
	}
	defer file.Close()

	scanner := bufio.NewScanner(file)
	var chunk []string
	for scanner.Scan() {
		chunk = append(chunk, scanner.Text())
		if len(chunk) >= chunkSize {
			if err := handler(chunk); err != nil {
				return err
			}
			chunk = chunk[:0]
		}
	}
	if len(chunk) > 0 {
		if err := handler(chunk); err != nil {
			return err
		}
	}
	return scanner.Err()
}
