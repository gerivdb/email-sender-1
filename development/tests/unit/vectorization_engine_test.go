package tests

import (
	"context"
	"strings"
	"testing"
	"time"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
	"github.com/stretchr/testify/suite"
)

// === PHASE 5.1.1.2: TESTS DU MOTEUR DE VECTORISATION ===

// VectorizationEngineTestSuite suite de tests pour le moteur de vectorisation
type VectorizationEngineTestSuite struct {
	suite.Suite
	engine   VectorizationEngine
	ctx      context.Context
	testDocs map[string]TestDocument
}

// VectorizationEngine interface du moteur de vectorisation
type VectorizationEngine interface {
	GenerateEmbedding(ctx context.Context, text string) ([]float32, error)
	GenerateMarkdownEmbedding(ctx context.Context, markdown string) ([]float32, error)
	GenerateConfigEmbedding(ctx context.Context, config interface{}) ([]float32, error)
	ParseMarkdown(content string) (*MarkdownDocument, error)
	CacheEmbedding(key string, embedding []float32) error
	GetCachedEmbedding(key string) ([]float32, bool)
	ClearCache() error
	GetCacheMetrics() CacheMetrics
	SetCacheSize(size int) error
	OptimizeEmbedding(embedding []float32) ([]float32, error)
}

// MarkdownDocument représente un document Markdown parsé
type MarkdownDocument struct {
	Title       string              `json:"title"`
	Headers     []MarkdownHeader    `json:"headers"`
	Paragraphs  []string            `json:"paragraphs"`
	CodeBlocks  []MarkdownCodeBlock `json:"code_blocks"`
	Lists       []MarkdownList      `json:"lists"`
	Links       []MarkdownLink      `json:"links"`
	Metadata    map[string]string   `json:"metadata"`
	Structure   DocumentStructure   `json:"structure"`
}

// MarkdownHeader en-tête Markdown
type MarkdownHeader struct {
	Level   int    `json:"level"`
	Text    string `json:"text"`
	ID      string `json:"id"`
	LineNum int    `json:"line_num"`
}

// MarkdownCodeBlock bloc de code
type MarkdownCodeBlock struct {
	Language string `json:"language"`
	Content  string `json:"content"`
	LineNum  int    `json:"line_num"`
}

// MarkdownList liste Markdown
type MarkdownList struct {
	Type     string   `json:"type"` // ordered, unordered, checklist
	Items    []string `json:"items"`
	Nested   bool     `json:"nested"`
	LineNum  int      `json:"line_num"`
}

// MarkdownLink lien Markdown
type MarkdownLink struct {
	Text    string `json:"text"`
	URL     string `json:"url"`
	Title   string `json:"title,omitempty"`
	LineNum int    `json:"line_num"`
}

// DocumentStructure structure du document
type DocumentStructure struct {
	WordCount      int     `json:"word_count"`
	LineCount      int     `json:"line_count"`
	HeaderCount    int     `json:"header_count"`
	CodeBlockCount int     `json:"code_block_count"`
	ListCount      int     `json:"list_count"`
	LinkCount      int     `json:"link_count"`
	Complexity     float64 `json:"complexity"`
}

// CacheMetrics métriques du cache
type CacheMetrics struct {
	Hits       int64   `json:"hits"`
	Misses     int64   `json:"misses"`
	Size       int     `json:"size"`
	MaxSize    int     `json:"max_size"`
	HitRatio   float64 `json:"hit_ratio"`
	LastAccess time.Time `json:"last_access"`
}

// TestDocument document de test
type TestDocument struct {
	Name     string
	Content  string
	Type     string
	Expected ExpectedResult
}

// ExpectedResult résultat attendu
type ExpectedResult struct {
	EmbeddingSize int
	HasTitle      bool
	HeaderCount   int
	CodeBlocks    int
	WordCount     int
}

// SetupSuite initialise la suite de tests
func (suite *VectorizationEngineTestSuite) SetupSuite() {
	suite.ctx = context.Background()
	
	// Initialiser les documents de test
	suite.testDocs = map[string]TestDocument{
		"simple_markdown": {
			Name: "Simple Markdown",
			Content: `# Test Document

This is a simple markdown document for testing.

## Section 1

Some content here with **bold** and *italic* text.

### Subsection

- Item 1
- Item 2
- Item 3

## Section 2

` + "```go\nfunc main() {\n    fmt.Println(\"Hello World\")\n}\n```" + `

[Link to example](https://example.com)
`,
			Type: "markdown",
			Expected: ExpectedResult{
				EmbeddingSize: 384, // Taille standard pour un modèle comme sentence-transformers
				HasTitle:      true,
				HeaderCount:   3,
				CodeBlocks:    1,
				WordCount:     20,
			},
		},
		"complex_markdown": {
			Name: "Complex Markdown",
			Content: `# Plan de Développement v56

**Progression: 75%**

## Phase 1: Architecture

### 1.1 Conception

- [x] **1.1.1** Définir les interfaces
  - [x] Micro-étape 1.1.1.1: Interface VectorizationEngine
  - [x] Micro-étape 1.1.1.2: Interface QdrantClient
  - [ ] Micro-étape 1.1.1.3: Interface CacheManager

#### 1.1.1 Détails d'implémentation

` + "```typescript\ninterface VectorizationEngine {\n  generateEmbedding(text: string): Promise<number[]>;\n}\n```" + `

### 1.2 Validation

- [ ] Tests unitaires
- [ ] Tests d'intégration

## Phase 2: Implémentation

Contenu de la phase 2...

### Métriques

| Composant | Progression | Tests |
|-----------|-------------|-------|
| Engine    | 90%         | ✅    |
| Client    | 85%         | ✅    |
| Cache     | 70%         | ⏳    |
`,
			Type: "plan_markdown",
			Expected: ExpectedResult{
				EmbeddingSize: 384,
				HasTitle:      true,
				HeaderCount:   5,
				CodeBlocks:    1,
				WordCount:     50,
			},
		},
		"config_json": {
			Name: "JSON Configuration",
			Content: `{
  "database": {
    "host": "localhost",
    "port": 5432,
    "name": "test_db"
  },
  "vectorization": {
    "enabled": true,
    "model": "sentence-transformers/all-MiniLM-L6-v2",
    "cache_size": 1000
  },
  "logging": {
    "level": "info",
    "file": "app.log"
  }
}`,
			Type: "json_config",
			Expected: ExpectedResult{
				EmbeddingSize: 384,
				HasTitle:      false,
				HeaderCount:   0,
				CodeBlocks:    0,
				WordCount:     25,
			},
		},
	}

	// Créer un mock engine pour les tests
	suite.engine = NewMockVectorizationEngine()
}

// === MICRO-ÉTAPE 5.1.1.2.1: TESTS DE GÉNÉRATION D'EMBEDDINGS ===

// TestGenerateEmbeddings teste la génération d'embeddings
func (suite *VectorizationEngineTestSuite) TestGenerateEmbeddings() {
	
	// Test génération d'embedding simple
	suite.T().Run("SimpleTextEmbedding", func(t *testing.T) {
		text := "This is a simple test text for embedding generation."
		
		embedding, err := suite.engine.GenerateEmbedding(suite.ctx, text)
		assert.NoError(t, err)
		assert.NotNil(t, embedding)
		assert.Greater(t, len(embedding), 0)
		
		// Vérifier que l'embedding a une taille standard
		assert.Equal(t, 384, len(embedding))
		
		// Vérifier que l'embedding contient des valeurs non nulles
		hasNonZero := false
		for _, val := range embedding {
			if val != 0 {
				hasNonZero = true
				break
			}
		}
		assert.True(t, hasNonZero, "Embedding should contain non-zero values")
	})

	// Test génération d'embedding Markdown
	suite.T().Run("MarkdownEmbedding", func(t *testing.T) {
		testDoc := suite.testDocs["simple_markdown"]
		
		embedding, err := suite.engine.GenerateMarkdownEmbedding(suite.ctx, testDoc.Content)
		assert.NoError(t, err)
		assert.NotNil(t, embedding)
		assert.Equal(t, testDoc.Expected.EmbeddingSize, len(embedding))
	})

	// Test génération d'embedding configuration
	suite.T().Run("ConfigEmbedding", func(t *testing.T) {
		config := map[string]interface{}{
			"database": map[string]interface{}{
				"host": "localhost",
				"port": 5432,
			},
			"cache": map[string]interface{}{
				"enabled": true,
				"size":    1000,
			},
		}
		
		embedding, err := suite.engine.GenerateConfigEmbedding(suite.ctx, config)
		assert.NoError(t, err)
		assert.NotNil(t, embedding)
		assert.Equal(t, 384, len(embedding))
	})

	// Test embeddings pour textes similaires
	suite.T().Run("SimilarTextsEmbeddings", func(t *testing.T) {
		text1 := "The cat sits on the mat."
		text2 := "A cat is sitting on a mat."
		text3 := "The dog runs in the park."
		
		emb1, err1 := suite.engine.GenerateEmbedding(suite.ctx, text1)
		emb2, err2 := suite.engine.GenerateEmbedding(suite.ctx, text2)
		emb3, err3 := suite.engine.GenerateEmbedding(suite.ctx, text3)
		
		assert.NoError(t, err1)
		assert.NoError(t, err2)
		assert.NoError(t, err3)
		
		// Calculer les similarités
		sim12 := calculateCosineSimilarity(emb1, emb2)
		sim13 := calculateCosineSimilarity(emb1, emb3)
		
		// Les textes 1 et 2 devraient être plus similaires que 1 et 3
		assert.Greater(t, sim12, sim13)
		t.Logf("Similarity 1-2: %.3f, Similarity 1-3: %.3f", sim12, sim13)
	})

	// Test texte vide
	suite.T().Run("EmptyText", func(t *testing.T) {
		embedding, err := suite.engine.GenerateEmbedding(suite.ctx, "")
		assert.Error(t, err)
		assert.Nil(t, embedding)
	})

	// Test texte très long
	suite.T().Run("LongText", func(t *testing.T) {
		longText := strings.Repeat("This is a very long text. ", 1000)
		
		embedding, err := suite.engine.GenerateEmbedding(suite.ctx, longText)
		assert.NoError(t, err)
		assert.NotNil(t, embedding)
		assert.Equal(t, 384, len(embedding))
	})
}

// === MICRO-ÉTAPE 5.1.1.2.2: TESTS DE PARSING MARKDOWN ===

// TestMarkdownParsing teste le parsing Markdown
func (suite *VectorizationEngineTestSuite) TestMarkdownParsing() {
	
	// Test parsing document simple
	suite.T().Run("SimpleMarkdownParsing", func(t *testing.T) {
		testDoc := suite.testDocs["simple_markdown"]
		
		parsed, err := suite.engine.ParseMarkdown(testDoc.Content)
		assert.NoError(t, err)
		assert.NotNil(t, parsed)
		
		// Vérifier la structure
		assert.Equal(t, "Test Document", parsed.Title)
		assert.Equal(t, testDoc.Expected.HeaderCount, len(parsed.Headers))
		assert.Equal(t, testDoc.Expected.CodeBlocks, len(parsed.CodeBlocks))
		assert.Greater(t, len(parsed.Paragraphs), 0)
		assert.Greater(t, len(parsed.Lists), 0)
		assert.Greater(t, len(parsed.Links), 0)
		
		// Vérifier les en-têtes
		expectedHeaders := []struct {
			level int
			text  string
		}{
			{1, "Test Document"},
			{2, "Section 1"},
			{3, "Subsection"},
			{2, "Section 2"},
		}
		
		for i, expected := range expectedHeaders {
			if i < len(parsed.Headers) {
				assert.Equal(t, expected.level, parsed.Headers[i].Level)
				assert.Equal(t, expected.text, parsed.Headers[i].Text)
			}
		}
		
		// Vérifier le bloc de code
		if len(parsed.CodeBlocks) > 0 {
			assert.Equal(t, "go", parsed.CodeBlocks[0].Language)
			assert.Contains(t, parsed.CodeBlocks[0].Content, "func main()")
		}
		
		// Vérifier la liste
		if len(parsed.Lists) > 0 {
			assert.Equal(t, "unordered", parsed.Lists[0].Type)
			assert.Equal(t, 3, len(parsed.Lists[0].Items))
		}
		
		// Vérifier les liens
		if len(parsed.Links) > 0 {
			assert.Equal(t, "Link to example", parsed.Links[0].Text)
			assert.Equal(t, "https://example.com", parsed.Links[0].URL)
		}
	})

	// Test parsing document complexe
	suite.T().Run("ComplexMarkdownParsing", func(t *testing.T) {
		testDoc := suite.testDocs["complex_markdown"]
		
		parsed, err := suite.engine.ParseMarkdown(testDoc.Content)
		assert.NoError(t, err)
		assert.NotNil(t, parsed)
		
		// Vérifier la structure complexe
		assert.Equal(t, "Plan de Développement v56", parsed.Title)
		assert.Equal(t, testDoc.Expected.HeaderCount, len(parsed.Headers))
		
		// Vérifier les tâches avec checkboxes
		hasChecklistItems := false
		for _, list := range parsed.Lists {
			if list.Type == "checklist" {
				hasChecklistItems = true
				break
			}
		}
		assert.True(t, hasChecklistItems, "Should detect checklist items")
		
		// Vérifier les blocs de code TypeScript
		if len(parsed.CodeBlocks) > 0 {
			assert.Equal(t, "typescript", parsed.CodeBlocks[0].Language)
			assert.Contains(t, parsed.CodeBlocks[0].Content, "interface")
		}
		
		// Vérifier les métadonnées extraites
		assert.Contains(t, parsed.Metadata, "progression")
		assert.Equal(t, "75%", parsed.Metadata["progression"])
	})

	// Test parsing avec erreurs
	suite.T().Run("MalformedMarkdown", func(t *testing.T) {
		malformedContent := `# Incomplete Header
		
		` + "```\nUnclosed code block\n" + `
		
		[Incomplete link](
		`
		
		parsed, err := suite.engine.ParseMarkdown(malformedContent)
		// Le parsing devrait réussir même avec un contenu malformé
		assert.NoError(t, err)
		assert.NotNil(t, parsed)
		
		// Mais certains éléments peuvent être manqués ou corrigés
		assert.Equal(t, "Incomplete Header", parsed.Title)
	})

	// Test performance parsing
	suite.T().Run("LargeMarkdownParsing", func(t *testing.T) {
		// Générer un gros document Markdown
		var largeContent strings.Builder
		largeContent.WriteString("# Large Document\n\n")
		
		for i := 0; i < 1000; i++ {
			largeContent.WriteString(fmt.Sprintf("## Section %d\n\nContent for section %d.\n\n", i, i))
			if i%10 == 0 {
				largeContent.WriteString("```go\nfunc example() {}\n```\n\n")
			}
		}
		
		start := time.Now()
		parsed, err := suite.engine.ParseMarkdown(largeContent.String())
		duration := time.Since(start)
		
		assert.NoError(t, err)
		assert.NotNil(t, parsed)
		assert.Equal(t, 1000, len(parsed.Headers)-1) // -1 pour le titre principal
		
		t.Logf("Parsing large document (1000 sections) took: %v", duration)
		assert.Less(t, duration, 5*time.Second, "Parsing should be reasonably fast")
	})
}

// === MICRO-ÉTAPE 5.1.1.2.3: TESTS DE CACHE ET OPTIMISATIONS ===

// TestCacheAndOptimizations teste le cache et les optimisations
func (suite *VectorizationEngineTestSuite) TestCacheAndOptimizations() {
	
	// Test cache de base
	suite.T().Run("BasicCaching", func(t *testing.T) {
		key := "test_cache_key"
		embedding := []float32{0.1, 0.2, 0.3, 0.4}
		
		// Mettre en cache
		err := suite.engine.CacheEmbedding(key, embedding)
		assert.NoError(t, err)
		
		// Récupérer du cache
		cachedEmbedding, found := suite.engine.GetCachedEmbedding(key)
		assert.True(t, found)
		assert.Equal(t, embedding, cachedEmbedding)
		
		// Test clé inexistante
		_, found = suite.engine.GetCachedEmbedding("nonexistent_key")
		assert.False(t, found)
	})

	// Test métriques du cache
	suite.T().Run("CacheMetrics", func(t *testing.T) {
		// Nettoyer le cache
		suite.engine.ClearCache()
		
		// Effectuer quelques opérations
		suite.engine.CacheEmbedding("key1", []float32{0.1, 0.2})
		suite.engine.CacheEmbedding("key2", []float32{0.3, 0.4})
		
		// Hit
		_, found := suite.engine.GetCachedEmbedding("key1")
		assert.True(t, found)
		
		// Miss
		_, found = suite.engine.GetCachedEmbedding("key3")
		assert.False(t, found)
		
		// Vérifier les métriques
		metrics := suite.engine.GetCacheMetrics()
		assert.Equal(t, int64(1), metrics.Hits)
		assert.Equal(t, int64(1), metrics.Misses)
		assert.Equal(t, 2, metrics.Size)
		assert.Equal(t, 0.5, metrics.HitRatio)
	})

	// Test limite de taille du cache
	suite.T().Run("CacheSizeLimit", func(t *testing.T) {
		// Définir une petite taille de cache
		err := suite.engine.SetCacheSize(3)
		assert.NoError(t, err)
		
		suite.engine.ClearCache()
		
		// Ajouter plus d'éléments que la limite
		for i := 0; i < 5; i++ {
			key := fmt.Sprintf("key_%d", i)
			embedding := []float32{float32(i), float32(i) * 0.1}
			err := suite.engine.CacheEmbedding(key, embedding)
			assert.NoError(t, err)
		}
		
		// Vérifier que la taille est respectée
		metrics := suite.engine.GetCacheMetrics()
		assert.LessOrEqual(t, metrics.Size, metrics.MaxSize)
		assert.Equal(t, 3, metrics.MaxSize)
	})

	// Test optimisation d'embedding
	suite.T().Run("EmbeddingOptimization", func(t *testing.T) {
		originalEmbedding := make([]float32, 384)
		for i := range originalEmbedding {
			originalEmbedding[i] = float32(i) * 0.01
		}
		
		optimizedEmbedding, err := suite.engine.OptimizeEmbedding(originalEmbedding)
		assert.NoError(t, err)
		assert.NotNil(t, optimizedEmbedding)
		
		// L'embedding optimisé peut avoir une taille différente ou être normalisé
		assert.LessOrEqual(t, len(optimizedEmbedding), len(originalEmbedding))
		
		// Vérifier que l'optimisation préserve l'information importante
		if len(optimizedEmbedding) == len(originalEmbedding) {
			// Test de normalisation
			var norm float32
			for _, val := range optimizedEmbedding {
				norm += val * val
			}
			norm = float32(math.Sqrt(float64(norm)))
			assert.InDelta(t, 1.0, norm, 0.01, "Optimized embedding should be normalized")
		}
	})

	// Test performance avec cache
	suite.T().Run("CachePerformance", func(t *testing.T) {
		suite.engine.ClearCache()
		text := "This is a test text for performance measurement."
		
		// Premier appel (sans cache)
		start := time.Now()
		embedding1, err := suite.engine.GenerateEmbedding(suite.ctx, text)
		duration1 := time.Since(start)
		assert.NoError(t, err)
		
		// Deuxième appel (avec cache si implémenté)
		start = time.Now()
		embedding2, err := suite.engine.GenerateEmbedding(suite.ctx, text)
		duration2 := time.Since(start)
		assert.NoError(t, err)
		
		// Vérifier que les embeddings sont identiques
		assert.Equal(t, embedding1, embedding2)
		
		t.Logf("First call: %v, Second call: %v", duration1, duration2)
		
		// Si le cache est implémenté, le deuxième appel devrait être plus rapide
		// (ce test peut être conditionnel selon l'implémentation)
	})

	// Test nettoyage du cache
	suite.T().Run("CacheClear", func(t *testing.T) {
		// Ajouter des éléments
		suite.engine.CacheEmbedding("test1", []float32{0.1, 0.2})
		suite.engine.CacheEmbedding("test2", []float32{0.3, 0.4})
		
		// Vérifier qu'ils sont présents
		metrics := suite.engine.GetCacheMetrics()
		assert.Greater(t, metrics.Size, 0)
		
		// Nettoyer
		err := suite.engine.ClearCache()
		assert.NoError(t, err)
		
		// Vérifier que le cache est vide
		metrics = suite.engine.GetCacheMetrics()
		assert.Equal(t, 0, metrics.Size)
		
		// Vérifier que les éléments ont été supprimés
		_, found := suite.engine.GetCachedEmbedding("test1")
		assert.False(t, found)
	})
}

// TestVectorizationEngineSuite exécute la suite de tests
func TestVectorizationEngineSuite(t *testing.T) {
	suite.Run(t, new(VectorizationEngineTestSuite))
}

// === MOCK IMPLEMENTATION ===

// MockVectorizationEngine implémentation mock
type MockVectorizationEngine struct {
	cache map[string][]float32
	hits  int64
	misses int64
	maxCacheSize int
	mu    sync.RWMutex
}

// NewMockVectorizationEngine crée un nouveau mock
func NewMockVectorizationEngine() *MockVectorizationEngine {
	return &MockVectorizationEngine{
		cache: make(map[string][]float32),
		maxCacheSize: 1000,
	}
}

func (m *MockVectorizationEngine) GenerateEmbedding(ctx context.Context, text string) ([]float32, error) {
	if text == "" {
		return nil, fmt.Errorf("empty text")
	}
	
	// Vérifier le cache d'abord
	m.mu.RLock()
	if cached, found := m.cache[text]; found {
		m.hits++
		m.mu.RUnlock()
		return cached, nil
	}
	m.misses++
	m.mu.RUnlock()
	
	// Générer un embedding mock basé sur le texte
	embedding := make([]float32, 384)
	hash := simpleHash(text)
	for i := range embedding {
		embedding[i] = float32((hash+int(i))%1000) / 1000.0 - 0.5
	}
	
	// Mettre en cache
	m.CacheEmbedding(text, embedding)
	
	return embedding, nil
}

func (m *MockVectorizationEngine) GenerateMarkdownEmbedding(ctx context.Context, markdown string) ([]float32, error) {
	// Pour le mock, utiliser la même logique que GenerateEmbedding
	return m.GenerateEmbedding(ctx, markdown)
}

func (m *MockVectorizationEngine) GenerateConfigEmbedding(ctx context.Context, config interface{}) ([]float32, error) {
	// Convertir la config en string pour l'embedding
	configStr := fmt.Sprintf("%+v", config)
	return m.GenerateEmbedding(ctx, configStr)
}

func (m *MockVectorizationEngine) ParseMarkdown(content string) (*MarkdownDocument, error) {
	doc := &MarkdownDocument{
		Headers:    []MarkdownHeader{},
		Paragraphs: []string{},
		CodeBlocks: []MarkdownCodeBlock{},
		Lists:      []MarkdownList{},
		Links:      []MarkdownLink{},
		Metadata:   make(map[string]string),
	}
	
	lines := strings.Split(content, "\n")
	var currentParagraph strings.Builder
	lineNum := 0
	
	for _, line := range lines {
		lineNum++
		line = strings.TrimSpace(line)
		
		if line == "" {
			if currentParagraph.Len() > 0 {
				doc.Paragraphs = append(doc.Paragraphs, currentParagraph.String())
				currentParagraph.Reset()
			}
			continue
		}
		
		// Détecter les en-têtes
		if strings.HasPrefix(line, "#") {
			level := 0
			for _, char := range line {
				if char == '#' {
					level++
				} else {
					break
				}
			}
			
			text := strings.TrimSpace(line[level:])
			if level == 1 && doc.Title == "" {
				doc.Title = text
			}
			
			doc.Headers = append(doc.Headers, MarkdownHeader{
				Level:   level,
				Text:    text,
				ID:      strings.ToLower(strings.ReplaceAll(text, " ", "-")),
				LineNum: lineNum,
			})
			continue
		}
		
		// Détecter les blocs de code
		if strings.HasPrefix(line, "```") {
			language := strings.TrimPrefix(line, "```")
			codeLines := []string{}
			
			// Lire jusqu'à la fermeture
			for i := lineNum; i < len(lines); i++ {
				nextLine := lines[i]
				if strings.TrimSpace(nextLine) == "```" {
					lineNum = i + 1
					break
				}
				codeLines = append(codeLines, nextLine)
			}
			
			doc.CodeBlocks = append(doc.CodeBlocks, MarkdownCodeBlock{
				Language: language,
				Content:  strings.Join(codeLines, "\n"),
				LineNum:  lineNum,
			})
			continue
		}
		
		// Détecter les listes
		if strings.HasPrefix(line, "- ") || strings.HasPrefix(line, "* ") {
			listItems := []string{strings.TrimPrefix(strings.TrimPrefix(line, "- "), "* ")}
			listType := "unordered"
			
			// Vérifier si c'est une checklist
			if strings.HasPrefix(listItems[0], "[") {
				listType = "checklist"
				listItems[0] = strings.TrimPrefix(listItems[0], "[ ] ")
				listItems[0] = strings.TrimPrefix(listItems[0], "[x] ")
			}
			
			doc.Lists = append(doc.Lists, MarkdownList{
				Type:    listType,
				Items:   listItems,
				LineNum: lineNum,
			})
			continue
		}
		
		// Détecter les liens
		if strings.Contains(line, "](") {
			// Parsing simple des liens
			start := strings.Index(line, "[")
			end := strings.Index(line, "](")
			urlEnd := strings.Index(line[end+2:], ")")
			
			if start >= 0 && end > start && urlEnd > 0 {
				text := line[start+1 : end]
				url := line[end+2 : end+2+urlEnd]
				
				doc.Links = append(doc.Links, MarkdownLink{
					Text:    text,
					URL:     url,
					LineNum: lineNum,
				})
			}
		}
		
		// Détecter la progression
		if strings.Contains(line, "Progression:") && strings.Contains(line, "%") {
			progStart := strings.Index(line, "Progression:")
			progPart := line[progStart+12:]
			progEnd := strings.Index(progPart, "%")
			if progEnd > 0 {
				progression := strings.TrimSpace(progPart[:progEnd+1])
				doc.Metadata["progression"] = progression
			}
		}
		
		// Ajouter au paragraphe courant
		if currentParagraph.Len() > 0 {
			currentParagraph.WriteString(" ")
		}
		currentParagraph.WriteString(line)
	}
	
	// Ajouter le dernier paragraphe
	if currentParagraph.Len() > 0 {
		doc.Paragraphs = append(doc.Paragraphs, currentParagraph.String())
	}
	
	// Calculer la structure
	doc.Structure = DocumentStructure{
		WordCount:      countWords(content),
		LineCount:      len(lines),
		HeaderCount:    len(doc.Headers),
		CodeBlockCount: len(doc.CodeBlocks),
		ListCount:      len(doc.Lists),
		LinkCount:      len(doc.Links),
		Complexity:     calculateComplexity(doc),
	}
	
	return doc, nil
}

func (m *MockVectorizationEngine) CacheEmbedding(key string, embedding []float32) error {
	m.mu.Lock()
	defer m.mu.Unlock()
	
	// Vérifier la limite de taille
	if len(m.cache) >= m.maxCacheSize {
		// Supprimer un élément aléatoire (LRU serait mieux mais c'est un mock)
		for k := range m.cache {
			delete(m.cache, k)
			break
		}
	}
	
	m.cache[key] = embedding
	return nil
}

func (m *MockVectorizationEngine) GetCachedEmbedding(key string) ([]float32, bool) {
	m.mu.RLock()
	defer m.mu.RUnlock()
	
	embedding, found := m.cache[key]
	return embedding, found
}

func (m *MockVectorizationEngine) ClearCache() error {
	m.mu.Lock()
	defer m.mu.Unlock()
	
	m.cache = make(map[string][]float32)
	m.hits = 0
	m.misses = 0
	return nil
}

func (m *MockVectorizationEngine) GetCacheMetrics() CacheMetrics {
	m.mu.RLock()
	defer m.mu.RUnlock()
	
	hitRatio := 0.0
	if m.hits+m.misses > 0 {
		hitRatio = float64(m.hits) / float64(m.hits+m.misses)
	}
	
	return CacheMetrics{
		Hits:       m.hits,
		Misses:     m.misses,
		Size:       len(m.cache),
		MaxSize:    m.maxCacheSize,
		HitRatio:   hitRatio,
		LastAccess: time.Now(),
	}
}

func (m *MockVectorizationEngine) SetCacheSize(size int) error {
	m.mu.Lock()
	defer m.mu.Unlock()
	
	m.maxCacheSize = size
	
	// Réduire le cache si nécessaire
	for len(m.cache) > size {
		for k := range m.cache {
			delete(m.cache, k)
			break
		}
	}
	
	return nil
}

func (m *MockVectorizationEngine) OptimizeEmbedding(embedding []float32) ([]float32, error) {
	// Normalisation simple pour le mock
	optimized := make([]float32, len(embedding))
	copy(optimized, embedding)
	
	// Calculer la norme
	var norm float32
	for _, val := range optimized {
		norm += val * val
	}
	norm = float32(math.Sqrt(float64(norm)))
	
	// Normaliser
	if norm > 0 {
		for i := range optimized {
			optimized[i] /= norm
		}
	}
	
	return optimized, nil
}

// === FONCTIONS UTILITAIRES ===

import (
	"fmt"
	"math"
	"strings"
	"sync"
)

// calculateCosineSimilarity calcule la similarité cosinus
func calculateCosineSimilarity(a, b []float32) float64 {
	if len(a) != len(b) {
		return 0.0
	}
	
	var dotProduct, normA, normB float64
	for i := range a {
		dotProduct += float64(a[i]) * float64(b[i])
		normA += float64(a[i]) * float64(a[i])
		normB += float64(b[i]) * float64(b[i])
	}
	
	if normA == 0 || normB == 0 {
		return 0.0
	}
	
	return dotProduct / (math.Sqrt(normA) * math.Sqrt(normB))
}

// simpleHash fonction de hash simple
func simpleHash(s string) int {
	h := 0
	for _, c := range s {
		h = 31*h + int(c)
	}
	if h < 0 {
		h = -h
	}
	return h
}

// countWords compte les mots dans un texte
func countWords(text string) int {
	words := strings.Fields(text)
	return len(words)
}

// calculateComplexity calcule la complexité d'un document
func calculateComplexity(doc *MarkdownDocument) float64 {
	complexity := 0.0
	
	// Facteurs de complexité
	complexity += float64(doc.Structure.HeaderCount) * 0.1
	complexity += float64(doc.Structure.CodeBlockCount) * 0.3
	complexity += float64(doc.Structure.ListCount) * 0.2
	complexity += float64(doc.Structure.LinkCount) * 0.1
	complexity += float64(doc.Structure.WordCount) * 0.001
	
	return complexity
}
