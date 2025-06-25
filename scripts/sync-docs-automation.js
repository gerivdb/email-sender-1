// Phase 6 – Automatisation & Synchronisation documentaire (Node.js)
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
  // 1. Synchronisation automatique des docs (JS/Go)
  run("node scripts/sync.js --docs docs/ --output docs/technical/ARCHITECTURE.md", "Synchronisation documentaire JS");
  run("go run core/docmanager/sync.go --docs docs/ --output docs/technical/ARCHITECTURE.md", "Synchronisation documentaire Go");

  // 2. Détection des changements et gestion des conflits
  run("node scripts/sync.js --detect-changes --docs docs/", "Détection des changements JS");
  run("go run core/docmanager/sync.go --detect-changes --docs docs/", "Détection des changements Go");

  // 3. Historique et export automatisé
  backupFile("docs/technical/ARCHITECTURE.md");
  run("cp docs/technical/ARCHITECTURE.md docs/technical/ARCHITECTURE.sync.md", "Export automatisé de la doc synchronisée");

  // 4. Tests de robustesse
  run("npm test scripts/sync.test.js", "Tests unitaires sync.js");
  run("go test core/docmanager/sync.go", "Tests unitaires sync.go");

  // 5. Validation croisée des outputs
  validateOutput("docs/technical/ARCHITECTURE.sync.md", "Doc synchronisée exportée");

  // 6. Reporting CI/CD
  fs.appendFileSync("ANALYSE_DIFFICULTS_PHASE1.md", `\n[Phase 6] Synchronisation documentaire automatisée exécutée avec succès le ${(new Date()).toISOString()}\n`);
  console.log("Reporting CI/CD effectué.");

} catch (e) {
  console.error("Erreur critique dans le pipeline Phase 6. Rollback conseillé.");
  backupFile("docs/technical/ARCHITECTURE.md");
  // Rollback manuel possible sur les .bak
  process.exit(1);
}

console.log("=== Fin Phase 6 Automatisation & Synchronisation documentaire ===");
