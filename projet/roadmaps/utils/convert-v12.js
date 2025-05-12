/**
 * Convert v12 Architecture Cognitive Roadmap
 * 
 * This script converts the plan-dev-v12-architecture-cognitive.md file
 * to JSON format and validates its structure.
 */

const fs = require('fs');
const path = require('path');
const converter = require('./cognitive-converter');

// Paths
const markdownPath = path.join(__dirname, '../../roadmaps/plans/plan-dev-v12-architecture-cognitive.md');
const jsonPath = path.join(__dirname, '../../roadmaps/json/plan-dev-v12-architecture-cognitive.json');
const validationReportPath = path.join(__dirname, '../../roadmaps/reports/v12-validation-report.md');

// Ensure directories exist
const jsonDir = path.dirname(jsonPath);
const reportsDir = path.dirname(validationReportPath);
[jsonDir, reportsDir].forEach(dir => {
  if (!fs.existsSync(dir)) {
    fs.mkdirSync(dir, { recursive: true });
  }
});

/**
 * Validate the roadmap structure
 * @param {object} roadmap - The roadmap object to validate
 * @returns {object} Validation results
 */
function validateRoadmap(roadmap) {
  const results = {
    valid: true,
    errors: [],
    warnings: [],
    stats: {
      totalElements: 0,
      byLevel: {},
      byStatus: {
        planned: 0,
        in_progress: 0,
        completed: 0,
        blocked: 0,
        cancelled: 0
      },
      byDimension: {
        temporal: 0,
        cognitive: 0,
        organizational: 0,
        strategic: 0
      }
    }
  };
  
  // Recursive validation function
  function validateElement(element, path = []) {
    results.stats.totalElements++;
    
    // Count by level
    const level = element.level || 0;
    results.stats.byLevel[level] = (results.stats.byLevel[level] || 0) + 1;
    
    // Count by status
    const status = element.status || 'planned';
    results.stats.byStatus[status] = (results.stats.byStatus[status] || 0) + 1;
    
    // Count dimensions
    for (const dim of Object.keys(element.metadata || {})) {
      if (Object.keys(element.metadata[dim]).length > 0) {
        results.stats.byDimension[dim]++;
      }
    }
    
    // Validate required fields
    if (!element.id) {
      results.errors.push(`Missing ID at path: ${path.join('.')}`);
      results.valid = false;
    }
    
    if (!element.title) {
      results.errors.push(`Missing title at path: ${path.join('.')}`);
      results.valid = false;
    }
    
    // Validate level-type consistency
    if (element.level && element.type) {
      const levelDef = hierarchyDefinitions.levels.find(l => l.level === element.level);
      if (levelDef && levelDef.type !== element.type) {
        results.warnings.push(`Level-type mismatch at path: ${path.join('.')}. Level ${element.level} should have type '${levelDef.type}' but has '${element.type}'.`);
      }
    }
    
    // Validate children recursively
    if (element.children && Array.isArray(element.children)) {
      element.children.forEach((child, index) => {
        validateElement(child, [...path, 'children', index]);
      });
    }
  }
  
  // Start validation from the root
  validateElement(roadmap);
  
  return results;
}

/**
 * Generate a validation report in Markdown format
 * @param {object} results - Validation results
 * @returns {string} Markdown report
 */
function generateValidationReport(results) {
  let report = '# Validation Report for v12 Architecture Cognitive Roadmap\n\n';
  
  // Overall status
  report += `## Overall Status\n\n`;
  report += `- **Valid**: ${results.valid ? '✅ Yes' : '❌ No'}\n`;
  report += `- **Total Elements**: ${results.stats.totalElements}\n`;
  report += `- **Errors**: ${results.errors.length}\n`;
  report += `- **Warnings**: ${results.warnings.length}\n\n`;
  
  // Statistics by level
  report += `## Statistics by Level\n\n`;
  report += `| Level | Count |\n`;
  report += `|-------|-------|\n`;
  
  const levels = Object.keys(results.stats.byLevel).sort((a, b) => Number(a) - Number(b));
  for (const level of levels) {
    const levelName = level === '0' ? 'Unknown' : hierarchyDefinitions.levels.find(l => l.level === Number(level))?.name || `Level ${level}`;
    report += `| ${levelName} | ${results.stats.byLevel[level]} |\n`;
  }
  report += '\n';
  
  // Statistics by status
  report += `## Statistics by Status\n\n`;
  report += `| Status | Count |\n`;
  report += `|--------|-------|\n`;
  for (const [status, count] of Object.entries(results.stats.byStatus)) {
    if (count > 0) {
      report += `| ${status.charAt(0).toUpperCase() + status.slice(1)} | ${count} |\n`;
    }
  }
  report += '\n';
  
  // Statistics by dimension
  report += `## Statistics by Dimension\n\n`;
  report += `| Dimension | Elements with this dimension |\n`;
  report += `|-----------|-----------------------------|\n`;
  for (const [dimension, count] of Object.entries(results.stats.byDimension)) {
    const dimensionName = dimensionDefinitions.dimensions.find(d => d.key === dimension)?.name || dimension;
    report += `| ${dimensionName} | ${count} |\n`;
  }
  report += '\n';
  
  // Errors
  if (results.errors.length > 0) {
    report += `## Errors\n\n`;
    for (const error of results.errors) {
      report += `- ${error}\n`;
    }
    report += '\n';
  }
  
  // Warnings
  if (results.warnings.length > 0) {
    report += `## Warnings\n\n`;
    for (const warning of results.warnings) {
      report += `- ${warning}\n`;
    }
    report += '\n';
  }
  
  return report;
}

// Main function
async function main() {
  console.log(`Converting ${markdownPath} to JSON...`);
  
  try {
    // Convert Markdown to JSON
    converter.convertMarkdownFileToJson(markdownPath, jsonPath);
    console.log(`Converted to ${jsonPath}`);
    
    // Load the JSON for validation
    const jsonContent = fs.readFileSync(jsonPath, 'utf8');
    const roadmap = JSON.parse(jsonContent);
    
    // Validate the roadmap
    console.log('Validating roadmap structure...');
    const validationResults = validateRoadmap(roadmap);
    
    // Generate and save validation report
    const report = generateValidationReport(validationResults);
    fs.writeFileSync(validationReportPath, report, 'utf8');
    console.log(`Validation report saved to ${validationReportPath}`);
    
    // Print summary
    console.log('\nValidation Summary:');
    console.log(`- Valid: ${validationResults.valid ? 'Yes' : 'No'}`);
    console.log(`- Total Elements: ${validationResults.stats.totalElements}`);
    console.log(`- Errors: ${validationResults.errors.length}`);
    console.log(`- Warnings: ${validationResults.warnings.length}`);
    
    if (!validationResults.valid) {
      console.error('\nValidation failed. See the report for details.');
      process.exit(1);
    }
    
    console.log('\nConversion and validation completed successfully.');
  } catch (error) {
    console.error('Error:', error);
    process.exit(1);
  }
}

// Load hierarchy definitions
let hierarchyDefinitions;
let dimensionDefinitions;

try {
  hierarchyDefinitions = require('../models/hierarchy-definitions.json');
  dimensionDefinitions = require('../models/dimension-definitions.json');
} catch (error) {
  console.error('Error loading definitions:', error);
  process.exit(1);
}

// Run the main function
main();
