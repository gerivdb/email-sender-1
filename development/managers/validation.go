package validation

import (
	"fmt"
	"log"

	dependency_manager "email_sender/development/managers/dependency-manager"
	security_manager "email_sender/development/managers/security-manager"
	storage_manager "email_sender/development/managers/storage-manager"
)

// ValidateAllManagers exécute une série de validations pour tous les managers.
func ValidateAllManagers() {
	fmt.Println("=== Exécution de la validation des Managers ===")

	// Test Storage Manager
	fmt.Println("\n1. Validation du Storage Manager:")
	storageManager, err := storage_manager.NewStorageManager()
	if err != nil {
		fmt.Printf("   ⚠️  Erreur d'initialisation du Storage Manager: %v\n", err)
	} else {
		fmt.Println("   ✅ Storage Manager initialisé avec succès")
		// Ici, vous pourriez ajouter des appels à des méthodes de test du storageManager
	}

	// Test Dependency Manager
	fmt.Println("\n2. Validation du Dependency Manager:")
	depManager, err := dependency_manager.NewDependencyManager()
	if err != nil {
		log.Printf("   ❌ Erreur d'initialisation du Dependency Manager: %v\n", err)
	} else {
		fmt.Println("   ✅ Dependency Manager initialisé avec succès")
		// Ici, vous pourriez ajouter des appels à des méthodes de test du depManager
		configFiles := depManager.DetectConfigFiles(".")
		fmt.Printf("   📁 %d fichiers de configuration détectés\n", len(configFiles))
	}

	// Test Security Manager
	fmt.Println("\n3. Validation du Security Manager:")
	secManager, err := security_manager.NewSecurityManager()
	if err != nil {
		log.Printf("   ❌ Erreur d'initialisation du Security Manager: %v\n", err)
	} else {
		fmt.Println("   ✅ Security Manager initialisé avec succès")
		// Ici, vous pourriez ajouter des appels à des méthodes de test du secManager
		testEmail := "test@example.com"
		isValid := secManager.ValidateInput(testEmail, "email")
		if isValid {
			fmt.Println("   ✅ Validation d'entrée fonctionnelle")
		}
	}

	fmt.Println("\n=== STATUT DE VALIDATION DES MANAGERS ===")
	fmt.Println("✅ Validation terminée.")
	// Utiliser les variables pour éviter les erreurs de "declared and not used"
	_ = storageManager
	_ = depManager
	_ = secManager
}
