// Package diffeditgo fournit des outils pour automatiser l'application de patchs.
package diffeditgo

import (
	"log"
	"os"
	"os/user"
	"time"
)

// LogDiffEdit gère un log avancé pour diffedit.
func LogDiffEdit(action, file, patch string, success bool, errMsg string) {
	u, uErr := user.Current()
	username := "unknown"
	if uErr == nil {
		username = u.Username
	}
	timestamp := time.Now().Format("2006-01-02 15:04:05")
	logFile, err := os.OpenFile("diffedit.log", os.O_APPEND|os.O_CREATE|os.O_WRONLY, 0o600)
	if err != nil {
		log.Printf("Erreur ouverture log: %v", err)
		return
	}
	if cerr := logFile.Close(); cerr != nil {
		log.Printf("Erreur fermeture log: %v", cerr)
	}

	logger := log.New(logFile, "", 0)
	status := "OK"

	if !success {
		status = "FAIL"
	}

	logger.Printf("[%s] %s | %s | %s | %s | %s | %s", timestamp, username, action, file, patch, status, errMsg)
}
