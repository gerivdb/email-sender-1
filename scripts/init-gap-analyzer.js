const fs = require('fs');
const path = require('path');
const data = JSON.parse(fs.readFileSync('init-cartographie-scan.json'));

// Index pour détection de doublons, orphelins, etc.
const nameIndex = {};
const pathIndex = {};
const extIndex = {};
const testIndex = {};
const docIndex = {};
const allPaths = new Set();
const allNames = new Set();
const allDeps = new Set();
const report = [];

// 1. Indexation de base
data.forEach(entry => {
  allPaths.add(entry.path);
  allNames.add(entry.name);
  // Index par nom (pour doublons)
  if (!nameIndex[entry.name]) nameIndex[entry.name] = [];
  nameIndex[entry.name].push(entry.path);
  // Index par extension
  const ext = path.extname(entry.name);
  if (!extIndex[ext]) extIndex[ext] = [];
  extIndex[ext].push(entry.path);
  // Index tests
  if (entry.name.match(/(\.test\.js|_test\.go|^test_.*\.py)/)) testIndex[entry.name] = entry.path;
  // Index doc
  if (entry.name.endsWith('.md')) docIndex[entry.name] = entry.path;
  // Index dépendances (si renseignées)
  if (entry.deps && entry.deps.length) entry.deps.forEach(dep => allDeps.add(dep));
});

// 2. Règle : Langage non détecté
data.forEach(entry => {
  if (entry.lang === 'unknown') {
    report.push({
      module: entry.name,
      ecart: 'Langage non détecté',
      risque: 'Non analysé',
      recommandation: 'Compléter manuellement'
    });
  }
});

// 3. Règle : Doublons de nom
Object.keys(nameIndex).forEach(name => {
  if (nameIndex[name].length > 1) {
    report.push({
      module: name,
      ecart: 'Doublon de nom',
      risque: 'Collision potentielle',
      recommandation: `Renommer un des fichiers : ${nameIndex[name].join(', ')}`
    });
  }
});

// 4. Règle : Extensions non attendues
const allowedExts = ['.go', '.js', '.py', '.md', '.json', '.yaml', '.yml', '.sh', '.txt'];
Object.keys(extIndex).forEach(ext => {
  if (!allowedExts.includes(ext)) {
    extIndex[ext].forEach(p => {
      report.push({
        module: p,
        ecart: `Extension inhabituelle (${ext})`,
        risque: 'Fichier potentiellement mal placé ou inutile',
        recommandation: 'Vérifier la pertinence du fichier'
      });
    });
  }
});

// 5. Règle : Fichiers vides ou trop volumineux
data.forEach(entry => {
  try {
    const stats = fs.statSync(entry.path);
    if (stats.size === 0) {
      report.push({
        module: entry.path,
        ecart: 'Fichier vide',
        risque: 'Oubli de contenu',
        recommandation: 'Compléter ou supprimer'
      });
    }
    if (stats.size > 5 * 1024 * 1024) { // >5Mo
      report.push({
        module: entry.path,
        ecart: 'Fichier très volumineux',
        risque: 'Dump accidentel ou binaire non versionné',
        recommandation: 'Vérifier la nécessité et le format'
      });
    }
  } catch (e) {}
});

// 6. Règle : Orphelins (aucune dépendance ne pointe dessus)
data.forEach(entry => {
  if (!allDeps.has(entry.path) && !entry.name.endsWith('.md') && !entry.name.endsWith('.json')) {
    report.push({
      module: entry.path,
      ecart: 'Fichier orphelin',
      risque: 'Non utilisé',
      recommandation: 'Vérifier si ce fichier est utile ou à supprimer'
    });
  }
});

// 7. Règle : Dépendances non résolues (pour JS/Go/Python)
data.forEach(entry => {
  if (entry.deps && entry.deps.length) {
    entry.deps.forEach(dep => {
      if (!allPaths.has(dep)) {
        report.push({
          module: entry.path,
          ecart: `Dépendance non résolue (${dep})`,
          risque: 'Erreur de build potentielle',
          recommandation: 'Corriger le chemin ou ajouter le fichier manquant'
        });
      }
    });
  }
});

// 8. Règle : Absence de tests associés
data.forEach(entry => {
  if ((entry.lang === 'Go' && !data.find(e => e.name === entry.name.replace('.go', '_test.go'))) ||
      (entry.lang === 'Node.js' && !data.find(e => e.name === entry.name.replace('.js', '.test.js'))) ||
      (entry.lang === 'Python' && !data.find(e => e.name === 'test_' + entry.name))) {
    if (!entry.name.match(/(\.test\.js|_test\.go|^test_.*\.py)/)) {
      report.push({
        module: entry.path,
        ecart: 'Pas de test associé',
        risque: 'Non couvert par des tests',
        recommandation: 'Ajouter un fichier de test'
      });
    }
  }
});

// 9. Règle : Absence de documentation associée
data.forEach(entry => {
  if (!entry.name.endsWith('.md') && !entry.name.endsWith('.json')) {
    const docName = entry.name.replace(/\.[^.]+$/, '.md');
    if (!data.find(e => e.name === docName)) {
      report.push({
        module: entry.path,
        ecart: 'Pas de documentation associée',
        risque: 'Non documenté',
        recommandation: `Ajouter ${docName} ou un commentaire de doc`
      });
    }
  }
});

// 10. Règle : Conventions de nommage
data.forEach(entry => {
  if (/[A-Z\s]/.test(entry.name) || /[^a-zA-Z0-9._-]/.test(entry.name)) {
    report.push({
      module: entry.path,
      ecart: 'Nom de fichier non conforme',
      risque: 'Portabilité réduite',
      recommandation: 'Utiliser uniquement minuscules, chiffres, tirets, underscores, points'
    });
  }
});

// Score d’intégrité globale
const integrityScore = 100 - Math.round((report.length / data.length) * 100);

let md = `# INIT_GAP_ANALYSIS.md

**Score d'intégrité globale du dépôt : ${integrityScore}%**

| Module/Fichier | Écart identifié | Risque | Recommandation |
|---|---|---|---|
`;
md += report.map(r => `| ${r.module} | ${r.ecart} | ${r.risque} | ${r.recommandation} |`).join('\n');
fs.writeFileSync('INIT_GAP_ANALYSIS.md', md);
console.log('Analyse d\'écart générée dans INIT_GAP_ANALYSIS.md');
