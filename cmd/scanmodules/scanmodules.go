package scanmodules

import (
	"fmt"
	"os"

	"EMAIL_SENDER_1/scripts"	// Replace with the actual module path if different
)

func main() {
	fmt.Println("Starting scan for missing files...")
	healthyCommit := "a06a222f"	// Utilisation du commit sain identifié
	scripts.ScanMissingFiles(healthyCommit)
	fmt.Println("Scan for missing files completed.")
	os.Exit(0)
}
