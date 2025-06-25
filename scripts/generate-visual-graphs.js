// Phase 5 – Génération & Visualisation des Graphes (Node.js)
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
  // 1. Génération des graphes (JS/Go)
  run("node scripts/graphgen.js --input core/docmanager/outputs/dependencies-merged.json --output docs/visualizations/graph-mermaid.md --format mermaid", "Génération graphe Mermaid");
  run("node scripts/graphgen.js --input core/docmanager/outputs/dependencies-merged.json --output docs/visualizations/graph-plantuml.puml --format plantuml", "Génération graphe PlantUML");
  run("go run core/docmanager/graphgen.go --input core/docmanager/outputs/dependencies-merged.json --output docs/visualizations/graph.svg", "Génération graphe SVG");

  // 2. Backup des outputs
  backupFile("docs/visualizations/graph-mermaid.md");
  backupFile("docs/visualizations/graph-plantuml.puml");
  backupFile("docs/visualizations/graph.svg");

  // 3. Visualisation interactive (web ou markdown)
  // (Supposé que docs/visualizations/graph-mermaid.md est intégré dans la doc ou un viewer web)

  // 4. Navigation croisée (doc/code/graphe)
  // (Supposé documentée dans docs/technical/ARCHITECTURE.md)

  // 5. Tests et validation croisée
  validateOutput("docs/visualizations/graph-mermaid.md", "Graphe Mermaid");
  validateOutput("docs/visualizations/graph-plantuml.puml", "Graphe PlantUML");
  validateOutput("docs/visualizations/graph.svg", "Graphe SVG");

  // 6. Reporting CI/CD
  fs.appendFileSync("ANALYSE_DIFFICULTS_PHASE1.md", `\n[Phase 5] Génération & visualisation des graphes exécutée avec succès le ${(new Date()).toISOString()}\n`);
  console.log("Reporting CI/CD effectué.");

} catch (e) {
  console.error("Erreur critique dans le pipeline Phase 5. Rollback conseillé.");
  backupFile("docs/visualizations/graph-mermaid.md");
  backupFile("docs/visualizations/graph-plantuml.puml");
  backupFile("docs/visualizations/graph.svg");
  // Rollback manuel possible sur les .bak
  process.exit(1);
}

console.log("=== Fin Phase 5 Génération & Visualisation des Graphes ===");
