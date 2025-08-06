// scripts/generate-modes-inventory.ts
// Générateur d’inventaire automatique des modes Roo (core/customs/marketplace)
// Scanne .roo/rules/rules.md pour extraire les fiches modes structurées

import * as fs from 'fs';
import * as path from 'path';

const RULES_MD = path.join(__dirname, '../.roo/rules/rules.md');
const OUTPUT_MD = path.join(__dirname, '../.roo/modes-inventory.md');
const OUTPUT_JSON = path.join(__dirname, '../.roo/modes-inventory.json');

function extractModeBlocks(md: string): string[] {
  // Recherche tous les blocs "#### Fiche Mode ..."
  const regex = /#### Fiche Mode[\s\S]+?(?=#### Fiche Mode|$)/g;
  return md.match(regex) || [];
}

function parseModeBlock(block: string) {
  // Extraction naïve des champs principaux (Slug, Emoji, Description, etc.)
  const get = (label: string) => {
    const m = block.match(new RegExp(`- \\*\\*${label}\\*\\*\\s*:?\\s*(.+)`));
    return m ? m[1].trim() : '';
  };
  return {
    slug: get('Slug'),
    emoji: get('Emoji'),
    description: get('Description'),
    workflow: get('Workflow principal'),
    principes: get('Principes hérités'),
    overrides: get('Overrides'),
    criteres: get('Critères d’acceptation'),
    cas_limites: get('Cas limites / exceptions'),
    liens: get('Liens utiles'),
    faq: get('FAQ / Glossaire'),
    raw: block.trim()
  };
}

function main() {
  const md = fs.readFileSync(RULES_MD, 'utf8');
  const blocks = extractModeBlocks(md);
  const modes = blocks.map(parseModeBlock);

  // Génération Markdown
  const mdOut = [
    '# Inventaire automatique des modes Roo',
    '',
    '| Slug | Emoji | Description |',
    '|------|-------|-------------|',
    ...modes.map(m =>
      `| ${m.slug} | ${m.emoji} | ${m.description} |`
    ),
    '',
    '---',
    '',
    '## Détail structuré',
    ...modes.map(m => m.raw)
  ].join('\n');

  fs.writeFileSync(OUTPUT_MD, mdOut, 'utf8');
  fs.writeFileSync(OUTPUT_JSON, JSON.stringify(modes, null, 2), 'utf8');
  console.log('Inventaire des modes Roo généré.');
}

if (require.main === module) main();