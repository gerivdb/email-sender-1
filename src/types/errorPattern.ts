// Types partagés pour l'extension
export interface ErrorPattern {
  id: string;
  regex: string;
  description: string;
}

export interface AnalyzerResult {
  patternId: string;
  matches: Array<{ line: number; text: string }>;
}
