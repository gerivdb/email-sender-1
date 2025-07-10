// auth_test.go
package main

import "testing"

func TestAuthSuccess(t *testing.T) {
	if !AuthModule("admin", "admin") {
		t.Error("Authentification échouée alors qu’attendue")
	}
}

func TestAuthFailure(t *testing.T) {
	if AuthModule("user", "wrong") {
		t.Error("Authentification réussie alors qu’elle devrait échouer")
	}
}

// Fonction fictive pour l'exemple
func AuthModule(username, password string) bool {
	return username == "admin" && password == "admin"
}
