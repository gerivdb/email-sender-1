// Exemple de hook CacheManager dans un script Go existant (phase 4.4)

package dependency_manager

import (
	"fmt"
	"time"

	cachemanager "github.com/gerivdb/email-sender-1/development/managers/cache-manager"
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
