const fs = require('fs');
const path = require('path');

function scanDir(dir, base = '') {
  let results = [];
  fs.readdirSync(dir).forEach(file => {
    const fullPath = path.join(dir, file);
    const stat = fs.statSync(fullPath);
    if (stat.isDirectory()) {
      results = results.concat(scanDir(fullPath, path.join(base, file)));
    } else {
      results.push({
        name: file,
        path: path.join(base, file),
        type: 'file',
        lang: file.endsWith('.go') ? 'Go' : file.endsWith('.js') ? 'Node.js' : file.endsWith('.py') ? 'Python' : 'unknown',
        role: '',
        deps: [],
        outputs: []
      });
    }
  });
  return results;
}

const roots = ['core', 'scripts', 'docs'];
let all = [];
roots.forEach(root => {
  if (fs.existsSync(root)) {
    all = all.concat(scanDir(root, root));
  }
});
fs.writeFileSync('init-cartographie-scan.json', JSON.stringify(all, null, 2));
console.log('Scan terminé, voir init-cartographie-scan.json');
