/**
 * Script pour générer un rapport de couverture détaillé
 */

import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

// Obtenir le chemin du répertoire actuel
const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

// Chemin vers le rapport de couverture JSON
const coverageSummaryPath = path.join(__dirname, '..', 'coverage', 'coverage-summary.json');

// Vérifier si le fichier existe
if (!fs.existsSync(coverageSummaryPath)) {
  console.error('Le fichier de rapport de couverture n\'existe pas. Exécutez d\'abord "npm run test:coverage".');
  process.exit(1);
}

// Lire le rapport de couverture
const coverageSummary = JSON.parse(fs.readFileSync(coverageSummaryPath, 'utf8'));

// Fonction pour formater le pourcentage
function formatPercentage(percentage) {
  return `${percentage.toFixed(2)}%`;
}

// Fonction pour formater la couverture
function formatCoverage(coverage) {
  return {
    statements: formatPercentage(coverage.statements.pct),
    branches: formatPercentage(coverage.branches.pct),
    functions: formatPercentage(coverage.functions.pct),
    lines: formatPercentage(coverage.lines.pct)
  };
}

// Générer le rapport
console.log('=== Rapport de couverture détaillé ===\n');

// Couverture globale
console.log('Couverture globale:');
const totalCoverage = coverageSummary.total;
const formattedTotalCoverage = formatCoverage(totalCoverage);
console.log(`  Statements: ${formattedTotalCoverage.statements}`);
console.log(`  Branches:   ${formattedTotalCoverage.branches}`);
console.log(`  Functions:  ${formattedTotalCoverage.functions}`);
console.log(`  Lines:      ${formattedTotalCoverage.lines}`);
console.log('');

// Couverture par fichier
console.log('Couverture par fichier:');
Object.keys(coverageSummary).forEach(key => {
  if (key !== 'total') {
    const fileCoverage = coverageSummary[key];
    const formattedFileCoverage = formatCoverage(fileCoverage);
    console.log(`\n${key}:`);
    console.log(`  Statements: ${formattedFileCoverage.statements}`);
    console.log(`  Branches:   ${formattedFileCoverage.branches}`);
    console.log(`  Functions:  ${formattedFileCoverage.functions}`);
    console.log(`  Lines:      ${formattedFileCoverage.lines}`);
  }
});

// Identifier les fichiers avec une faible couverture
console.log('\n=== Fichiers avec une faible couverture (<50%) ===\n');
Object.keys(coverageSummary).forEach(key => {
  if (key !== 'total') {
    const fileCoverage = coverageSummary[key];
    if (
      fileCoverage.statements.pct < 50 ||
      fileCoverage.branches.pct < 50 ||
      fileCoverage.functions.pct < 50 ||
      fileCoverage.lines.pct < 50
    ) {
      const formattedFileCoverage = formatCoverage(fileCoverage);
      console.log(`${key}:`);
      console.log(`  Statements: ${formattedFileCoverage.statements}`);
      console.log(`  Branches:   ${formattedFileCoverage.branches}`);
      console.log(`  Functions:  ${formattedFileCoverage.functions}`);
      console.log(`  Lines:      ${formattedFileCoverage.lines}`);
      console.log('');
    }
  }
});

console.log('Rapport de couverture généré avec succès.');
console.log('Pour voir le rapport HTML complet, ouvrez le fichier "coverage/lcov-report/index.html" dans votre navigateur.');
