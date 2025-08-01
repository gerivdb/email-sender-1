// move-files.js
// Auteur : Roo (IA)
// Version : 1.0
// Date : 2025-08-01
// Description : Script Node.js pour déplacer des fichiers selon une config YAML, avec dry-run, log, rollback, audit.
// Usage : node move-files.js [--config file-moves.yaml] [--dry-run] [--rollback] [--log move-files.log]

// Dépendance standard : 'fs', 'path', 'process'
// Dépendance externe : 'yaml' (npm install yaml) — commenter si non disponible

const fs = require('fs');
const path = require('path');
const process = require('process');
let YAML;
try {
  YAML = require('yaml');
} catch (e) {
  console.error("La dépendance 'yaml' est requise. Installez-la avec 'npm install yaml'.");
  process.exit(1);
}

const argv = require('minimist')(process.argv.slice(2));
const configPath = argv.config || 'file-moves.yaml';
const dryRun = !!argv['dry-run'];
const rollback = !!argv.rollback;
const logPath = argv.log || 'move-files.log';

function writeLog(msg) {
  const entry = `${new Date().toISOString()} ${msg}\n`;
  fs.appendFileSync(logPath, entry);
  console.log(entry.trim());
}

function loadYamlConfig(file) {
  const content = fs.readFileSync(file, 'utf8');
  return YAML.parse(content);
}

function validateSchema(yaml) {
  if (!yaml.moves) {
    writeLog("ERREUR : Section 'moves' manquante dans la config.");
    process.exit(1);
  }
}

function doMove(src, dst) {
  if (dryRun) {
    writeLog(`DRY-RUN : ${src} => ${dst}`);
  } else {
    if (fs.existsSync(src)) {
      fs.renameSync(src, dst);
      writeLog(`MOVE : ${src} => ${dst}`);
    } else {
      writeLog(`ERREUR : Source introuvable ${src}`);
    }
  }
}

function doRollback(logFile) {
  const lines = fs.readFileSync(logFile, 'utf8').split('\n').filter(l => l.includes('MOVE :'));
  for (const line of lines) {
    const match = line.match(/MOVE : (.+) => (.+)$/);
    if (match) {
      const src = match[2];
      const dst = match[1];
      if (fs.existsSync(src)) {
        fs.renameSync(src, dst);
        writeLog(`ROLLBACK : ${src} => ${dst}`);
      }
    }
  }
}

writeLog("=== Début du script move-files.js ===");
if (rollback) {
  doRollback(logPath);
  writeLog("Rollback terminé.");
  process.exit(0);
}

const yaml = loadYamlConfig(configPath);
validateSchema(yaml);

for (const move of yaml.moves) {
  doMove(move.source, move.destination);
}

writeLog("=== Fin du script move-files.js ===");