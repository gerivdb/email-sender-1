package authentification

import (
	"testing"
)

func TestLoginSuccess(t *testing.T) {
	// TODO: remplacer par un appel réel à la fonction de login
	user := "testuser"
	pass := "password"
	if user != "testuser" || pass != "password" {
		t.Errorf("Login échoué pour utilisateur valide")
	}
}

func TestLoginEchec(t *testing.T) {
	// TODO: remplacer par un appel réel à la fonction de login
	user := "testuser"
	pass := "wrong"
	if user == "testuser" && pass == "password" {
		t.Errorf("Login accepté pour mot de passe invalide")
	}
}

func TestExpirationSession(t *testing.T) {
	// TODO: simuler une session expirée
	expired := true
	if !expired {
		t.Errorf("Expiration de session non détectée")
	}
}
