// security_test.go
package main

import "testing"

func TestInjection(t *testing.T) {
	input := "' OR 1=1; --"
	if IsInputMalicious(input) != true {
		t.Error("Injection non détectée")
	}
}

func TestAccessControl(t *testing.T) {
	if !HasAccess("admin", "confidentiel") {
		t.Error("Accès refusé à un admin")
	}
	if HasAccess("user", "confidentiel") {
		t.Error("Accès non autorisé accordé à un user")
	}
}

// Fonctions fictives pour l'exemple
func IsInputMalicious(s string) bool {
	return s == "' OR 1=1; --"
}

func HasAccess(role, resource string) bool {
	return role == "admin"
}
