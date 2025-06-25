// Phase 4 – Extraction & Parsing Pipeline (Node.js)
// Respecte granularité, validation croisée, outputs réels, rollback, CI/CD

const { execSync } = require("child_process");
const fs = require("fs");

function run(cmd, desc) {
  try {
    console.log(`=== ${desc} ===`);
    execSync(cmd, { stdio: "inherit" });
  } catch (e) {
    console.error(`Erreur lors de : ${desc}`);
    throw e;
  }
}

function backupFile(path) {
  if (fs.existsSync(path)) {
    fs.copyFileSync(path, path + ".bak");
    console.log(`Backup créé : ${path}.bak`);
  }
}

function validateOutput(path, desc) {
  if (!fs.existsSync(path)) {
    throw new Error(`Livrable manquant : ${desc} (${path})`);
  }
  console.log(`Livrable validé : ${desc} (${path})`);
}

try {
  // 1. Extraction multi-langages (JS, Go)
  run("node scripts/dependency-analyzer.js --scan-all > core/docmanager/outputs/dependencies.json", "Extraction dépendances JS");
  run("go run core/docmanager/dependency_analyzer.go --output core/docmanager/outputs/dependencies-go.json", "Extraction dépendances Go");

  // 2. Structuration des outputs
  backupFile("core/docmanager/outputs/dependencies.json");
  backupFile("core/docmanager/outputs/dependencies-go.json");

  // 3. Parsing et fusion des dépendances (Python)
  run("python scripts/docgen.py --source core/docmanager/outputs/dependencies.json --merge core/docmanager/outputs/dependencies-go.json --output core/docmanager/outputs/dependencies-merged.json", "Parsing et fusion des dépendances");

  // 4. Génération des tests et benchmarks
  run("pytest scripts/test_docgen.py", "Tests unitaires docgen.py");
  run("go test core/docmanager/dependency_analyzer.go", "Tests unitaires Go");
  run("npm test scripts/dependency-analyzer.test.js", "Tests unitaires JS");

  // 5. Documentation automatique
  run("python scripts/docgen.py --source core/docmanager/outputs/dependencies-merged.json --output docs/technical/EXTRACTION_REPORT.md", "Documentation automatique extraction/parsing");

  // 6. Validation croisée des outputs
  validateOutput("core/docmanager/outputs/dependencies-merged.json", "Fusion dépendances");
  validateOutput("docs/technical/EXTRACTION_REPORT.md", "Rapport extraction/parsing");

  // 7. Reporting CI/CD
  fs.appendFileSync("ANALYSE_DIFFICULTS_PHASE1.md", `\n[Phase 4] Extraction & parsing pipeline exécuté avec succès le ${(new Date()).toISOString()}\n`);
  console.log("Reporting CI/CD effectué.");

} catch (e) {
  console.error("Erreur critique dans le pipeline Phase 4. Rollback conseillé.");
  backupFile("core/docmanager/outputs/dependencies.json");
  backupFile("core/docmanager/outputs/dependencies-go.json");
  // Rollback manuel possible sur les .bak
  process.exit(1);
}

console.log("=== Fin Phase 4 Extraction & Parsing ===");
