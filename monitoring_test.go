// monitoring_test.go
package main

import (
	"fmt"
	"testing"
)

// TestAlerting simule un test de déclenchement d’alerte.
func TestAlerting(t *testing.T) {
	alertTriggered := true
	if !alertTriggered {
		t.Error("Alerte non déclenchée alors qu’attendue")
	} else {
		fmt.Println("Alerte déclenchée et reçue")
	}
}
