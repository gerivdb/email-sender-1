package gen_rollback_spec

import (
	"fmt"
	"os"
	"path/filepath"
	"time"
)

func main() {
	outputFile := "specs/rollback_spec.md"

	// Ensure the specs directory exists
	err := os.MkdirAll(filepath.Dir(outputFile), 0o755)
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

	template := "# Spécification des Procédures de Rollback et de Restauration\n\n" +
		"Ce document détaille les procédures, les cas d'usage et les critères pour les opérations de sauvegarde et de restauration du projet.\n\n" +
		"## 1. Objectifs\n\n" +
		"- Assurer la capacité de restaurer le système à un état fonctionnel antérieur en cas de défaillance.\n" +
		"- Minimiser la perte de données et le temps d'arrêt.\n" +
		"- Fournir des directives claires pour la création et la gestion des sauvegardes.\n\n" +
		"## 2. Stratégies de Sauvegarde\n\n" +
		"### 2.1 Sauvegarde des Fichiers Critiques\n\n" +
		"Les fichiers critiques identifiés par l'audit (`docs/rollback_points_audit.md`) doivent être sauvegardés.\n" +
		"- **Fréquence**: Quotidienne pour les données, à chaque commit majeur pour le code et les configurations.\n" +
		"- **Localisation**: Stockage sécurisé et redondant (ex: S3, stockage réseau).\n" +
		"- **Méthode**: Utilisation de scripts automatisés.\n\n" +
		"### 2.2 Sauvegarde de la Base de Données (si applicable)\n\n" +
		"- **Type**: Sauvegarde complète régulière, sauvegardes incrémentielles/différentielles.\n" +
		"- **Fréquence**: Dépend de la criticité et du volume de changements des données.\n" +
		"- **Localisation**: Séparée des sauvegardes de fichiers, stockage sécurisé.\n\n" +
		"## 3. Procédures de Restauration\n\n" +
		"### 3.1 Restauration du Code et des Configurations\n\n" +
		"1. Cloner le dépôt Git à la révision souhaitée.\n" +
		"2. Restaurer les fichiers de configuration à partir de la dernière sauvegarde valide.\n" +
		"3. Exécuter les scripts de déploiement pour reconstruire l'environnement.\n\n" +
		"### 3.2 Restauration de la Base de Données (si applicable)\n\n" +
		"1. Arrêter les services qui accèdent à la base de données.\n" +
		"2. Utiliser les outils spécifiques à la base de données pour restaurer la sauvegarde.\n" +
		"3. Vérifier l'intégrité des données après restauration.\n\n" +
		"## 4. Cas d'Usage de Rollback\n\n" +
		"- **Déploiement échoué**: Revenir à la version précédente du code et de la configuration.\n" +
		"- **Corruption de données**: Restaurer la base de données à un point antérieur.\n" +
		"- **Attaque de sécurité**: Restaurer le système à un état propre avant l'attaque.\n\n" +
		"## 5. Critères de Validation\n\n" +
		"- **RPO (Recovery Point Objective)**: Perte de données maximale acceptable (ex: 1 heure).\n" +
		"- **RTO (Recovery Time Objective)**: Temps maximal pour restaurer le service (ex: 4 heures).\n" +
		"- **Intégrité des données**: Les données restaurées doivent être cohérentes et complètes.\n" +
		"- **Tests de Restauration**: Les procédures de restauration doivent être testées régulièrement dans un environnement isolé.\n\n" +
		"## 6. Outils et Scripts\n\n" +
		"- **Scripts de sauvegarde**: `scripts/backup.go` (à développer)\n" +
		"- **Scripts de restauration**: `scripts/restore.go` (à développer)\n" +
		"- **Outils de versionning**: Git, avec des conventions de taggage pour les points de restauration.\n\n" +
		"## 7. Traçabilité et Reporting\n\n" +
		"- Journalisation détaillée de toutes les opérations de sauvegarde et de restauration.\n" +
		"- Rapports automatisés sur l'état des sauvegardes et les résultats des restaurations.\n\n" +
		"---" +
		fmt.Sprintf("\n**Date de génération**: %s\n", time.Now().Format("2006-01-02 15:04:05 MST"))

	_, err = file.WriteString(template)
	if err != nil {
		fmt.Printf("Erreur lors de l'écriture dans le fichier de spécification: %v\n", err)
		os.Exit(1)
	}

	fmt.Printf("Le template de spécification de rollback a été généré dans %s\n", outputFile)
}
