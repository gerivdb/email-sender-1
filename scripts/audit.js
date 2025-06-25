// scripts/audit.js
// Audit de l’existant pour scripts Node.js/Python/Markdown

const fs = require('fs');
const path = require('path');

function auditExistingScripts(root) {
  let filesFound = [];
  function walk(dir) {
    fs.readdirSync(dir).forEach(file => {
      const fullPath = path.join(dir, file);
      if (fs.statSync(fullPath).isDirectory()) {
        walk(fullPath);
      } else if (
        fullPath.endsWith('.js') ||
        fullPath.endsWith('.py') ||
        fullPath.endsWith('.go') ||
        fullPath.endsWith('.md')
      ) {
        filesFound.push(fullPath);
      }
    });
  }
  walk(root);
  return { filesFound };
}

module.exports = { auditExistingScripts };
