package main

import (
	"fmt"
	"log"
	"os"
	"path/filepath"
)

func main() {
	log.Println("cmd/gen_read_file_spec/gen_read_file_spec.go: main() called")
	outputFile := "specs/read_file_spec.md"

	// Ensure the specs directory exists
	err := os.MkdirAll(filepath.Dir(outputFile), 0755)
	if err != nil {
		fmt.Printf("Erreur lors de la création du répertoire specs: %v\n", err)
		os.Exit(1)
	}

	file, err := os.Create(outputFile)
	if err != nil {
		fmt.Printf("Erreur lors de la création du fichier de spécification: %v\n", err)
		os.Exit(1)
	}
	defer file.Close()

	template := `
# Spécification fonctionnelle et technique pour read_file

Ce document détaille la spécification des améliorations apportées à la fonction ` + "`read_file`" + `, basées sur l'analyse des besoins utilisateurs.

## 1. Fonctionnalités

### 1.1 Lecture par plage de lignes

- **Description**: Permettre la lecture d'un fichier en spécifiant une plage de lignes (début et fin).
- **API Proposée**: ` + "`" + `ReadFileRange(path string, startLine, endLine int) ([]string, error)` + "`" + `
- **Cas d'usage**:
    - Lire uniquement les 100 premières lignes d'un fichier de log.
    - Extraire une section spécifique d'un fichier de configuration.
- **Critères d'acceptation**:
    - La fonction doit retourner les lignes exactes dans la plage spécifiée.
    - Gérer les cas où la plage dépasse la fin du fichier ou est invalide.
    - Performance optimisée pour les fichiers volumineux.

### 1.2 Navigation par bloc

- **Description**: Permettre une navigation interactive dans le fichier par blocs prédéfinis (ex: 50, 100, 500 lignes).
- **CLI Proposée**: ` + "`" + `read_file_navigator --file <path> --block-size <size> [next|prev|goto <block_num>|start|end]` + "`" + `
- **Cas d'usage**:
    - Parcourir un fichier de log géant bloc par bloc.
    - Atteindre rapidement une section spécifique sans charger tout le fichier en mémoire.
- **Critères d'acceptation**:
    - La CLI doit afficher le contenu du bloc demandé.
    - Les commandes de navigation doivent fonctionner correctement (suivant, précédent, aller à, début, fin).
    - Afficher l'état actuel (numéro de bloc, plage de lignes).

### 1.3 Détection et affichage de fichiers binaires (Preview Hex)

- **Description**: Détecter si un fichier est binaire et, si oui, offrir une option pour afficher son contenu en format hexadécimal.
- **API Proposée**:
    - ` + "`" + `IsBinaryFile(path string) (bool, error)` + "`" + `
    - ` + "`" + `PreviewHex(path string, offset, length int) ([]byte, error)` + "`" + `
- **Cas d'usage**:
    - Empêcher l'affichage de caractères illisibles pour les fichiers binaires.
    - Inspecter le contenu brut de fichiers binaires (images, exécutables).
- **Critères d'acceptation**:
    - Détection fiable des fichiers binaires.
    - L'affichage hexadécimal doit être clair et facile à lire.
    - Gérer les grandes tailles de fichiers sans problème de performance.

### 1.4 Intégration avec la sélection active de l'éditeur (VSCode)

- **Description**: Permettre à l'utilisateur de sélectionner une partie de texte dans l'éditeur et d'utiliser les fonctionnalités améliorées de `read_file` sur cette sélection.
- **Extension VSCode Proposée**: Commande "Read File: Analyze Selection"
- **Cas d'usage**:
    - Analyser une section de code ou de log directement depuis VSCode.
    - Appliquer des transformations ou des validations sur une sélection.
- **Critères d'acceptation**:
    - L'extension doit récupérer la sélection active de l'éditeur.
    - Elle doit pouvoir invoquer l'API Go (`read_file_navigator` ou `ReadFileRange`) avec la sélection comme entrée.
    - Les résultats doivent être affichés de manière conviviale dans VSCode (panel de sortie, nouvelle fenêtre).

### 1.5 Gestion optimisée des fichiers volumineux

- **Description**: S'assurer que les opérations sur les fichiers volumineux sont performantes et ne causent pas de problèmes de mémoire ou de troncature.
- **Optimisations**:
    - Lecture en streaming / lecture différée.
    - Utilisation de buffers optimisés.
    - Éviter de charger tout le fichier en mémoire.
- **Critères d'acceptation**:
    - Pas de troncature des fichiers, quelle que soit leur taille.
    - Temps de réponse acceptables pour les opérations sur des fichiers de plusieurs Go.
    - Consommation mémoire stable et raisonnable.

## 2. Critères d'Acceptation Généraux

- **Performance**: Toutes les nouvelles fonctionnalités doivent être performantes, même sur des fichiers très volumineux.
- **Fiabilité**: Les fonctions doivent être robustes et gérer les cas d'erreur (fichier non trouvé, permissions, corruption).
- **Facilité d'utilisation**: Les APIs et CLIs doivent être intuitives et bien documentées.
- **Tests**: Couverture de tests élevée pour toutes les nouvelles fonctionnalités.
- **Compatibilité**: Maintenir la compatibilité avec l'usage actuel de `read_file` (si applicable).
- **Sécurité**: Aucune vulnérabilité introduite.

## 3. Diagrammes (Optionnel)

Des diagrammes UML (classes, séquences) ou d'architecture pourraient être ajoutés ici pour clarifier les interactions entre les composants.

## 4. Plan de Tests (Résumé)

- **Tests Unitaires**: Pour chaque nouvelle fonction et méthode.
- **Tests d'Intégration**: Pour les interactions entre la CLI, l'API et l'extension VSCode.
- **Tests de Performance**: Benchmarks sur des fichiers de différentes tailles.
- **Tests de Régression**: S'assurer que les fonctionnalités existantes ne sont pas cassées.

## 5. Exigences Non Fonctionnelles

- **Scalabilité**: La solution doit être capable de gérer des fichiers de taille croissante.
- **Maintenabilité**: Code propre, modulaire et bien commenté.
- **Observabilité**: Logging adéquat pour le débogage et le monitoring.

---
`
	_, err = file.WriteString(template)
	if err != nil {
		fmt.Printf("Erreur lors de l'écriture dans le fichier de spécification: %v\n", err)
		os.Exit(1)
	}

	fmt.Printf("Le template de spécification a été généré dans %s\n", outputFile)
}
