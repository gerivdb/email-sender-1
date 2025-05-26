package parser

// FileAnalyzer définit l'interface pour l'analyse de fichiers

type FileAnalyzer interface {
	Analyze(path string) AnalysisResult
}

// AnalysisResult contient les résultats d'analyse d'un fichier

type AnalysisResult struct {
	Errors   []string
	Warnings []string
	Infos    []string
}

// TextFileAnalyzer implémente FileAnalyzer pour les fichiers texte

type TextFileAnalyzer struct{}

func (tfa *TextFileAnalyzer) Analyze(path string) AnalysisResult {
	// TODO: implémentation réelle
	return AnalysisResult{}
}
