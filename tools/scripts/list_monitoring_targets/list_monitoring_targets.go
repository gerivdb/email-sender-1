// tools/scripts/list_monitoring_targets/list_monitoring_targets.go
package main

import (
	"fmt"
)

func main() {
	fmt.Println("- Latence API")
	fmt.Println("- Taux d’erreur 5xx")
	fmt.Println("- Utilisation mémoire")
	fmt.Println("- Alerte CPU > 90%")
}
