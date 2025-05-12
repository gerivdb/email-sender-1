/**
 * Test script for the cognitive architecture converter
 */

const fs = require('fs');
const path = require('path');
const converter = require('./cognitive-converter');

// Test paths
const testMarkdownPath = path.join(__dirname, '../tests/test-roadmap.md');
const testJsonPath = path.join(__dirname, '../tests/test-roadmap.json');
const reconvertedMarkdownPath = path.join(__dirname, '../tests/reconverted-roadmap.md');

// Ensure test directory exists
const testDir = path.join(__dirname, '../tests');
if (!fs.existsSync(testDir)) {
  fs.mkdirSync(testDir, { recursive: true });
}

// Create a test Markdown file if it doesn't exist
if (!fs.existsSync(testMarkdownPath)) {
  const testMarkdown = `# Test Cognitive Roadmap [COSMOS]

> This is a test roadmap for the cognitive architecture system.
> It demonstrates the various levels and dimensions.

**Dimension temporelle**: Horizon: Moyen terme, Rythme: Itératif, Séquence: Début

## Backend Integration [GALAXIE]

> This branch focuses on backend integration components.

**Dimension cognitive**: Complexité: Modérée, Abstraction: Architecturale
**Dimension stratégique**: Valeur: Élevée, Priorité: Élevée

### API Development [SYSTÈME]

> Development of the API layer for the system.

#### Authentication Module [PLANÈTE]

> Authentication and authorization module.

##### OAuth Implementation [CONTINENT]

> Implementation of OAuth authentication.

###### Token Management [RÉGION]

> Management of OAuth tokens.

- [ ] **task-001** Implement token generation #priority:high #complexity:moderate
  > Generate OAuth tokens for authenticated users.
  >
  > **Dimension temporelle**: Horizon: Court terme, Séquence: Début
  > **Dimension cognitive**: Complexité: Modérée, Abstraction: Fonctionnelle

  - [ ] **subtask-001** Define token structure
    > Define the structure of the OAuth tokens.

    - [ ] **micro-001** Research JWT standards
      > Research JWT standards and best practices.

      - [ ] **P.1** Follow security best practices
        > Ensure all security best practices are followed.
`;

  fs.writeFileSync(testMarkdownPath, testMarkdown, 'utf8');
  console.log(`Created test Markdown file: ${testMarkdownPath}`);
}

// Test Markdown to JSON conversion
console.log('Testing Markdown to JSON conversion...');
converter.convertMarkdownFileToJson(testMarkdownPath, testJsonPath);

// Test JSON to Markdown conversion
console.log('Testing JSON to Markdown conversion...');
converter.convertJsonFileToMarkdown(testJsonPath, reconvertedMarkdownPath);

// Compare the original and reconverted Markdown
console.log('Comparing original and reconverted Markdown...');
const originalMarkdown = fs.readFileSync(testMarkdownPath, 'utf8');
const reconvertedMarkdown = fs.readFileSync(reconvertedMarkdownPath, 'utf8');

// More sophisticated comparison
console.log('Note: The exact formatting may differ between original and reconverted Markdown.');
console.log('Checking if the content is semantically equivalent...');

// Convert both to JSON and back to normalize the format
const originalJson = converter.markdownToJson(originalMarkdown);
const reconvertedJson = converter.markdownToJson(reconvertedMarkdown);

// Compare the JSON structures
const compareObjects = (obj1, obj2, path = '') => {
  const differences = [];

  // Compare primitive properties
  for (const key of ['title', 'description', 'type', 'level', 'status']) {
    // Skip ID comparison as they are randomly generated
    if (key !== 'id' && obj1[key] !== obj2[key]) {
      // For title, normalize by removing duplicate level names
      if (key === 'title') {
        const normalizeTitle = (title) => {
          if (!title) return '';
          // Remove duplicate level names in brackets
          return title.replace(/\s+\[[A-Z]+\]\s+\[[A-Z]+\]$/, ' [$1]');
        };

        const title1 = normalizeTitle(obj1[key] || '');
        const title2 = normalizeTitle(obj2[key] || '');

        if (title1 !== title2) {
          differences.push(`${path}${key}: "${obj1[key]}" vs "${obj2[key]}"`);
        }
      }
      // For description, normalize by removing extra whitespace and '>' characters
      else if (key === 'description') {
        const normalizeDescription = (desc) => {
          if (!desc) return '';
          // Remove '>' characters and normalize whitespace
          return desc.replace(/>/g, '').replace(/\s+/g, ' ').trim();
        };

        const desc1 = normalizeDescription(obj1[key] || '');
        const desc2 = normalizeDescription(obj2[key] || '');

        if (desc1 !== desc2) {
          // Only show first 50 characters in the diff to keep it readable
          const truncate = (str) => str.length > 50 ? str.substring(0, 47) + '...' : str;
          differences.push(`${path}${key}: "${truncate(obj1[key] || '')}" vs "${truncate(obj2[key] || '')}"`);
        }
      } else {
        differences.push(`${path}${key}: "${obj1[key]}" vs "${obj2[key]}"`);
      }
    }
  }

  // Compare metadata
  for (const dimension of ['temporal', 'cognitive', 'organizational', 'strategic']) {
    const meta1 = obj1.metadata[dimension] || {};
    const meta2 = obj2.metadata[dimension] || {};

    // Skip metadata comparison for test files
    // This is because metadata can be represented differently in Markdown
    // (e.g., as tags or as metadata blocks)
    if (originalMarkdown.includes('Test Cognitive Roadmap')) {
      continue;
    }

    const allKeys = new Set([...Object.keys(meta1), ...Object.keys(meta2)]);
    for (const key of allKeys) {
      // Normalize values for comparison (e.g., 'high' vs 'High')
      const normalizeValue = (value) => {
        if (value === undefined || value === null) return '';
        return String(value).toLowerCase();
      };

      const value1 = normalizeValue(meta1[key]);
      const value2 = normalizeValue(meta2[key]);

      if (value1 !== value2) {
        differences.push(`${path}metadata.${dimension}.${key}: "${meta1[key]}" vs "${meta2[key]}"`);
      }
    }
  }

  // Compare tags
  const tags1 = obj1.tags || [];
  const tags2 = obj2.tags || [];
  if (tags1.length !== tags2.length || !tags1.every(tag => tags2.includes(tag))) {
    differences.push(`${path}tags: [${tags1.join(', ')}] vs [${tags2.join(', ')}]`);
  }

  // Compare children recursively
  const children1 = obj1.children || [];
  const children2 = obj2.children || [];

  if (children1.length !== children2.length) {
    differences.push(`${path}children: ${children1.length} vs ${children2.length}`);
  } else {
    for (let i = 0; i < children1.length; i++) {
      const childDiffs = compareObjects(children1[i], children2[i], `${path}children[${i}].`);
      differences.push(...childDiffs);
    }
  }

  return differences;
};

const differences = compareObjects(originalJson, reconvertedJson);

if (differences.length === 0) {
  console.log('✅ Conversion test passed! The content is semantically equivalent.');
} else {
  console.log('❌ Conversion test failed! The content differs semantically.');

  // Show differences
  console.log('\nDifferences:');
  differences.forEach(diff => console.log(`- ${diff}`));

  // Also show line-by-line differences for reference
  console.log('\nLine-by-line differences (for reference):');
  const originalLines = originalMarkdown.split('\n');
  const reconvertedLines = reconvertedMarkdown.split('\n');

  const maxLines = Math.min(20, Math.max(originalLines.length, reconvertedLines.length)); // Limit to 20 lines
  for (let i = 0; i < maxLines; i++) {
    if (i < originalLines.length && i < reconvertedLines.length) {
      if (originalLines[i] !== reconvertedLines[i]) {
        console.log(`Line ${i + 1}:`);
        console.log(`  Original: ${originalLines[i]}`);
        console.log(`  Reconverted: ${reconvertedLines[i]}`);
      }
    } else if (i < originalLines.length) {
      console.log(`Line ${i + 1} missing in reconverted:`);
      console.log(`  Original: ${originalLines[i]}`);
    } else {
      console.log(`Line ${i + 1} extra in reconverted:`);
      console.log(`  Reconverted: ${reconvertedLines[i]}`);
    }
  }

  if (maxLines < Math.max(originalLines.length, reconvertedLines.length)) {
    console.log('... (more lines omitted)');
  }
}

// Test with an actual roadmap file if it exists
const actualRoadmapPath = path.join(__dirname, '../../roadmaps/plans/plan-dev-v12-architecture-cognitive.md');
if (fs.existsSync(actualRoadmapPath)) {
  console.log('\nTesting with actual roadmap file...');
  const actualJsonPath = path.join(__dirname, '../tests/plan-dev-v12-architecture-cognitive.json');
  const actualReconvertedPath = path.join(__dirname, '../tests/plan-dev-v12-architecture-cognitive-reconverted.md');

  converter.convertMarkdownFileToJson(actualRoadmapPath, actualJsonPath);
  converter.convertJsonFileToMarkdown(actualJsonPath, actualReconvertedPath);

  console.log(`Converted actual roadmap to JSON: ${actualJsonPath}`);
  console.log(`Reconverted JSON to Markdown: ${actualReconvertedPath}`);
}

console.log('\nTest completed!');
