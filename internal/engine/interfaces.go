package engine

// PatternMatcher définit l'interface pour tout moteur de matching de pattern
// Match retourne tous les PatternResult trouvés dans le contenu donné
// Score retourne un score de confiance pour un résultat donné

type PatternMatcher interface {
	Match(content string) []PatternResult
	Score(result PatternResult) float64
}

// PatternResult représente un résultat de matching de pattern
// Position = ligne/colonne, Message = description, Severity = niveau

type PatternResult struct {
	Line     int
	Column   int
	Message  string
	Severity string            // "error", "warning", "info"
	Context  map[string]string // groupes nommés extraits
}

// PatternConfig représente la configuration d'un pattern

type PatternConfig struct {
	ID          string
	Regex       string
	Description string
	Severity    string
	Options     map[string]interface{} // ex: multiline, case-insensitive
}

// RegexMatcher implémente PatternMatcher pour les regex

type RegexMatcher struct {
	Config PatternConfig
}

func (rm *RegexMatcher) Match(content string) []PatternResult {
	// TODO: implémentation réelle
	return nil
}

func (rm *RegexMatcher) Score(result PatternResult) float64 {
	// TODO: implémentation réelle
	return 1.0
}
