// Exemple de hook CacheManager dans un script Go existant (phase 4.4)

package main

import (
	"fmt"
	"time"

	cachemanager "email_sender/development/managers/cache-manager"
)

func main() {
	cm := cachemanager.NewCacheManager(
		cachemanager.NewLMCacheAdapter(),
		cachemanager.NewRedisAdapter(),
		cachemanager.NewSQLiteAdapter(),
	)

	entry := cachemanager.LogEntry{
		Timestamp: time.Now(),
		Level:     "INFO",
		Source:    "dependency-manager",
		Message:   "Démarrage du scan des dépendances",
	}

	_ = cm.StoreLog(entry)

	fmt.Println("Scan des dépendances lancé.")
}
