package common

import (
	"bufio"
	"bytes"
	"encoding/hex"
	"fmt"
	"io"
	"os"
	"unicode/utf8"
)

// ReadFileRange lit un fichier par plage de lignes spécifiée.
// startLine et endLine sont inclusifs et basés sur 1.
func ReadFileRange(path string, startLine, endLine int) ([]string, error) {
	if startLine <= 0 || startLine > endLine {
		return nil, fmt.Errorf("plage de lignes invalide: startLine=%d, endLine=%d", startLine, endLine)
	}

	file, err := os.Open(path)
	if err != nil {
		return nil, fmt.Errorf("impossible d'ouvrir le fichier %s: %w", path, err)
	}
	defer file.Close()

	var lines []string
	scanner := bufio.NewScanner(file)
	currentLine := 1

	for scanner.Scan() {
		if currentLine >= startLine && currentLine <= endLine {
			lines = append(lines, scanner.Text())
		}
		if currentLine > endLine {
			break
		}
		currentLine++
	}

	if err := scanner.Err(); err != nil {
		return nil, fmt.Errorf("erreur lors de la lecture du fichier %s: %w", path, err)
	}

	return lines, nil
}

// IsBinaryFile détermine si un fichier est binaire en vérifiant la présence de caractères non-UTF-8.
func IsBinaryFile(path string) (bool, error) {
	file, err := os.Open(path)
	if err != nil {
		return false, fmt.Errorf("impossible d'ouvrir le fichier %s: %w", path, err)
	}
	defer file.Close()

	// Lire un échantillon du fichier (par exemple, les 1024 premiers octets)
	buffer := make([]byte, 1024)
	n, err := file.Read(buffer)
	if err != nil && err != io.EOF {
		return false, fmt.Errorf("erreur lors de la lecture de l'échantillon du fichier %s: %w", path, err)
	}

	// Vérifier si l'échantillon contient des octets non-UTF-8
	// Si plus de 30% des octets ne sont pas des caractères UTF-8 valides, on considère que c'est binaire.
	// Le seuil de 30% est arbitraire et peut être ajusté.
	nonUTF8Count := 0
	for i := 0; i < n; {
		r, size := utf8.DecodeRune(buffer[i:])
		if r == utf8.RuneError { // Caractère UTF-8 invalide
			nonUTF8Count++
		}
		i += size
	}

	return float64(nonUTF8Count)/float64(n) > 0.3, nil
}

// PreviewHex lit une section d'un fichier et la renvoie en format hexadécimal.
func PreviewHex(path string, offset, length int) ([]byte, error) {
	file, err := os.Open(path)
	if err != nil {
		return nil, fmt.Errorf("impossible d'ouvrir le fichier %s: %w", path, err)
	}
	defer file.Close()

	_, err = file.Seek(int64(offset), io.SeekStart)
	if err != nil {
		return nil, fmt.Errorf("impossible de se positionner à l'offset %d dans le fichier %s: %w", offset, path, err)
	}

	buffer := make([]byte, length)
	n, err := file.Read(buffer)
	if err != nil && err != io.EOF {
		return nil, fmt.Errorf("erreur lors de la lecture de la plage du fichier %s: %w", path, err)
	}

	// Convertir les octets lus en représentation hexadécimale
	hexOutput := make([]byte, hex.EncodedLen(n))
	hex.Encode(hexOutput, buffer[:n])

	return hexOutput, nil
}

// Fonction utilitaire pour la navigation par bloc (à implémenter dans cmd/read_file_navigator.go)
// Cette fonction est un placeholder pour montrer l'intégration
func GetBlock(path string, blockSize, blockNum int) ([]string, error) {
	// Cette logique serait plus complexe dans une vraie implémentation de navigateur CLI
	// et dépendrait de la taille réelle du fichier et du nombre total de lignes.
	// Pour l'instant, c'est une simple wrapper autour de ReadFileRange.
	startLine := (blockNum-1)*blockSize + 1
	endLine := blockNum * blockSize
	return ReadFileRange(path, startLine, endLine)
}

// Simulate a large file by creating one if it doesn't exist
func CreateLargeTestFile(path string, numLines int) error {
	if _, err := os.Stat(path); os.IsNotExist(err) {
		file, err := os.Create(path)
		if err != nil {
			return fmt.Errorf("impossible de créer le fichier de test: %w", err)
		}
		defer file.Close()

		writer := bufio.NewWriter(file)
		for i := 0; i < numLines; i++ {
			_, err := writer.WriteString(fmt.Sprintf("Ceci est la ligne de test numéro %d.\n", i+1))
			if err != nil {
				return fmt.Errorf("impossible d'écrire dans le fichier de test: %w", err)
			}
		}
		writer.Flush()
	}
	return nil
}

// Simulate a binary file for testing
func CreateBinaryTestFile(path string, size int) error {
	if _, err := os.Stat(path); os.IsNotExist(err) {
		file, err := os.Create(path)
		if err != nil {
			return fmt.Errorf("impossible de créer le fichier binaire de test: %w", err)
		}
		defer file.Close()

		// Écrire des octets non-ASCII pour simuler un binaire
		binaryData := bytes.Repeat([]byte{0x00, 0xFF, 0x1A, 0xBE}, size/4)
		_, err = file.Write(binaryData[:size])
		if err != nil {
			return fmt.Errorf("impossible d'écrire des données binaires dans le fichier de test: %w", err)
		}
	}
	return nil
}
