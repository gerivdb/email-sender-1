// Script Go — capture_terminal.go
// Capture stdout/stderr et envoie les logs à CacheManager (squelette)

package scripts

import (
	"bytes"
	"encoding/json"
	"fmt"
	"net/http"
	"os"
	"os/exec"
	"time"

	cachemanager "github.com/gerivdb/email-sender-1/development/managers/cache-manager"
)

func main() {
	if len(os.Args) < 2 {
		fmt.Println("Usage: capture_terminal <commande> [args...]")
		os.Exit(1)
	}

	cmd := exec.Command(os.Args[1], os.Args[2:]...)
	output, err := cmd.CombinedOutput()
	msg := "Commande exécutée avec succès"
	level := "INFO"
	if err != nil {
		msg = "Erreur d’exécution: " + err.Error()
		level = "ERROR"
	}
	entry := cachemanager.LogEntry{
		Timestamp: time.Now(),
		Level:     level,
		Source:    "capture_terminal",
		Message:   msg,
		Context:   map[string]interface{}{"args": os.Args[1:], "output": string(output)},
	}

	// Envoi du log à l’API REST
	jsonData, _ := json.Marshal(entry)
	http.Post("http://localhost:8080/logs", "application/json", bytes.NewBuffer(jsonData))

	fmt.Println(string(output))
}
