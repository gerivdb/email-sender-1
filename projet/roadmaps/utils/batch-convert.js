/**
 * Batch converter for roadmap files
 * 
 * This script converts all Markdown roadmap files to JSON format
 * and vice versa, maintaining the hierarchical structure.
 */

const fs = require('fs');
const path = require('path');
const converter = require('./cognitive-converter');

// Configuration
const config = {
  plansDir: path.join(__dirname, '../../roadmaps/plans'),
  jsonDir: path.join(__dirname, '../../roadmaps/json'),
  backupDir: path.join(__dirname, '../../roadmaps/backups'),
  maxLinesPerFile: 500, // Maximum lines per Markdown file
  createBackups: true,
  verbose: true
};

// Ensure directories exist
[config.jsonDir, config.backupDir].forEach(dir => {
  if (!fs.existsSync(dir)) {
    fs.mkdirSync(dir, { recursive: true });
  }
});

/**
 * Convert all Markdown roadmap files to JSON
 */
function convertAllMarkdownToJson() {
  console.log('Converting all Markdown roadmap files to JSON...');
  
  // Get all Markdown files in the plans directory
  const files = fs.readdirSync(config.plansDir)
    .filter(file => file.endsWith('.md'))
    .map(file => path.join(config.plansDir, file));
  
  console.log(`Found ${files.length} Markdown files.`);
  
  // Convert each file
  files.forEach(file => {
    const baseName = path.basename(file, '.md');
    const jsonPath = path.join(config.jsonDir, `${baseName}.json`);
    
    // Create backup if enabled
    if (config.createBackups && fs.existsSync(jsonPath)) {
      const backupPath = path.join(config.backupDir, `${baseName}.json.bak.${Date.now()}`);
      fs.copyFileSync(jsonPath, backupPath);
      if (config.verbose) {
        console.log(`Created backup: ${backupPath}`);
      }
    }
    
    // Convert the file
    try {
      converter.convertMarkdownFileToJson(file, jsonPath);
      if (config.verbose) {
        console.log(`Converted ${file} to ${jsonPath}`);
      }
    } catch (error) {
      console.error(`Error converting ${file}:`, error);
    }
  });
  
  console.log('Markdown to JSON conversion completed.');
}

/**
 * Convert all JSON roadmap files to Markdown
 */
function convertAllJsonToMarkdown() {
  console.log('Converting all JSON roadmap files to Markdown...');
  
  // Get all JSON files in the json directory
  const files = fs.readdirSync(config.jsonDir)
    .filter(file => file.endsWith('.json'))
    .map(file => path.join(config.jsonDir, file));
  
  console.log(`Found ${files.length} JSON files.`);
  
  // Convert each file
  files.forEach(file => {
    const baseName = path.basename(file, '.json');
    const markdownPath = path.join(config.plansDir, `${baseName}.md`);
    
    // Create backup if enabled
    if (config.createBackups && fs.existsSync(markdownPath)) {
      const backupPath = path.join(config.backupDir, `${baseName}.md.bak.${Date.now()}`);
      fs.copyFileSync(markdownPath, backupPath);
      if (config.verbose) {
        console.log(`Created backup: ${backupPath}`);
      }
    }
    
    // Convert the file
    try {
      converter.convertJsonFileToMarkdown(file, markdownPath);
      
      // Check if the file exceeds the maximum line limit
      const content = fs.readFileSync(markdownPath, 'utf8');
      const lines = content.split('\n');
      
      if (lines.length > config.maxLinesPerFile) {
        console.warn(`Warning: ${markdownPath} exceeds the maximum line limit (${lines.length} > ${config.maxLinesPerFile}).`);
        console.warn('Consider splitting this file into multiple smaller files.');
        
        // TODO: Implement automatic file splitting
      }
      
      if (config.verbose) {
        console.log(`Converted ${file} to ${markdownPath}`);
      }
    } catch (error) {
      console.error(`Error converting ${file}:`, error);
    }
  });
  
  console.log('JSON to Markdown conversion completed.');
}

/**
 * Split a large Markdown file into multiple smaller files
 * @param {string} filePath - Path to the Markdown file
 * @param {number} maxLines - Maximum lines per file
 */
function splitMarkdownFile(filePath, maxLines = config.maxLinesPerFile) {
  console.log(`Splitting ${filePath} into smaller files...`);
  
  // Read the file
  const content = fs.readFileSync(filePath, 'utf8');
  const lines = content.split('\n');
  
  if (lines.length <= maxLines) {
    console.log(`File ${filePath} does not need splitting (${lines.length} <= ${maxLines}).`);
    return;
  }
  
  // Create backup
  if (config.createBackups) {
    const backupPath = path.join(config.backupDir, `${path.basename(filePath)}.bak.${Date.now()}`);
    fs.copyFileSync(filePath, backupPath);
    console.log(`Created backup: ${backupPath}`);
  }
  
  // Find logical splitting points (headers)
  const splitPoints = [];
  let currentHeader = null;
  let currentHeaderLine = 0;
  
  for (let i = 0; i < lines.length; i++) {
    const line = lines[i];
    const headerMatch = line.match(/^(#+)\s+/);
    
    if (headerMatch && headerMatch[1].length <= 2) { // Only split at level 1 or 2 headers
      if (currentHeader && i - currentHeaderLine > 50) { // Ensure sections are reasonably sized
        splitPoints.push({
          line: currentHeaderLine,
          header: currentHeader
        });
      }
      
      currentHeader = line;
      currentHeaderLine = i;
    }
  }
  
  // Add the last header
  if (currentHeader) {
    splitPoints.push({
      line: currentHeaderLine,
      header: currentHeader
    });
  }
  
  // Sort split points by line number
  splitPoints.sort((a, b) => a.line - b.line);
  
  // If no suitable split points found, use arbitrary splitting
  if (splitPoints.length <= 1) {
    console.warn(`No suitable split points found in ${filePath}. Using arbitrary splitting.`);
    
    // Split into chunks of maxLines
    const chunks = [];
    for (let i = 0; i < lines.length; i += maxLines) {
      chunks.push(lines.slice(i, i + maxLines));
    }
    
    // Write each chunk to a separate file
    const baseName = path.basename(filePath, '.md');
    const dirName = path.dirname(filePath);
    
    chunks.forEach((chunk, index) => {
      const newPath = path.join(dirName, `${baseName}-part${index + 1}.md`);
      fs.writeFileSync(newPath, chunk.join('\n'), 'utf8');
      console.log(`Created ${newPath} with ${chunk.length} lines.`);
    });
    
    return;
  }
  
  // Split at logical points
  const chunks = [];
  for (let i = 0; i < splitPoints.length; i++) {
    const startLine = splitPoints[i].line;
    const endLine = i < splitPoints.length - 1 ? splitPoints[i + 1].line : lines.length;
    
    chunks.push({
      header: splitPoints[i].header,
      content: lines.slice(startLine, endLine).join('\n')
    });
  }
  
  // Write each chunk to a separate file
  const baseName = path.basename(filePath, '.md');
  const dirName = path.dirname(filePath);
  
  chunks.forEach((chunk, index) => {
    // Extract a name from the header
    const headerText = chunk.header.replace(/^#+\s+/, '').replace(/\s+\[.*\]$/, '');
    const sanitizedHeader = headerText.toLowerCase().replace(/[^a-z0-9]+/g, '-');
    
    const newPath = path.join(dirName, `${baseName}-${sanitizedHeader}.md`);
    fs.writeFileSync(newPath, chunk.content, 'utf8');
    console.log(`Created ${newPath} with ${chunk.content.split('\n').length} lines.`);
  });
  
  console.log(`Split ${filePath} into ${chunks.length} files.`);
}

// Main function
function main() {
  const args = process.argv.slice(2);
  
  if (args.includes('--help') || args.includes('-h')) {
    console.log('Usage: node batch-convert.js [options]');
    console.log('Options:');
    console.log('  --md-to-json    Convert Markdown files to JSON');
    console.log('  --json-to-md    Convert JSON files to Markdown');
    console.log('  --split <file>  Split a large Markdown file into smaller files');
    console.log('  --all           Perform all conversions');
    console.log('  --no-backup     Disable backups');
    console.log('  --quiet         Reduce verbosity');
    return;
  }
  
  // Process options
  if (args.includes('--no-backup')) {
    config.createBackups = false;
  }
  
  if (args.includes('--quiet')) {
    config.verbose = false;
  }
  
  // Perform conversions
  if (args.includes('--md-to-json') || args.includes('--all')) {
    convertAllMarkdownToJson();
  }
  
  if (args.includes('--json-to-md') || args.includes('--all')) {
    convertAllJsonToMarkdown();
  }
  
  // Split a file if requested
  const splitIndex = args.indexOf('--split');
  if (splitIndex !== -1 && splitIndex < args.length - 1) {
    const filePath = args[splitIndex + 1];
    splitMarkdownFile(filePath);
  }
  
  // If no specific action requested, show help
  if (args.length === 0) {
    console.log('No action specified. Use --help for usage information.');
  }
}

// Run the main function
main();
