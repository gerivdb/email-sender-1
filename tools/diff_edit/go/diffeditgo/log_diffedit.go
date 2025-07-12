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
	// Récupération de l'utilisateur actuel
	u, uErr := user.Current()
	username := "unknown"

	if uErr == nil {
		username = u.Username
	}

	// Formatage du timestamp
	timestamp := time.Now().Format("2006-01-02 15:04:05")

	// Définition des permissions de fichier comme constante
	const logFilePerm = 0o600

	// Ouverture du fichier de log
	logFile, err := os.OpenFile("diffedit.log", os.O_APPEND|os.O_CREATE|os.O_WRONLY, logFilePerm)
	if err != nil {
		log.Printf("Erreur ouverture log: %v", err)
		return
	}

	// Utilisation de defer avec une fonction anonyme pour gérer l'erreur de fermeture
	defer func() {
		cerr := logFile.Close()
		if cerr != nil {
			log.Printf("Erreur fermeture log: %v", cerr)
		}
	}()

	// Initialisation du logger
	logger := log.New(logFile, "", 0)

	// Détermination du statut
	status := "OK"
	if !success {
		status = "FAIL"
	}

	// Écriture du log
	logger.Printf("[%s] %s | %s | %s | %s | %s | %s", timestamp, username, action, file, patch, status, errMsg)
}
