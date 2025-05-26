package patterns

// PatternRepository définit l'interface pour la gestion des patterns

type PatternRepository interface {
	Load() error
	Save() error
	List() []PatternConfig
}

// PatternConfig pour la configuration des patterns (identique à engine)
type PatternConfig struct {
	ID          string
	Regex       string
	Description string
	Severity    string
	Options     map[string]interface{}
}

// FilePatternRepository implémente PatternRepository pour les fichiers

type FilePatternRepository struct {
	patterns []PatternConfig
}

func (fpr *FilePatternRepository) Load() error {
	// TODO: chargement réel
	return nil
}

func (fpr *FilePatternRepository) Save() error {
	// TODO: sauvegarde réelle
	return nil
}

func (fpr *FilePatternRepository) List() []PatternConfig {
	return fpr.patterns
}
