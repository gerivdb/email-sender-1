/**
 * Run All Cognitive Architecture Tools
 * 
 * This script runs all the cognitive architecture tools in sequence
 * to test the entire system.
 */

const { spawn } = require('child_process');
const path = require('path');
const fs = require('fs');

// Configuration
const config = {
  scripts: [
    {
      name: 'Generate Example',
      path: './generate-example.js',
      description: 'Generates an example cognitive roadmap'
    },
    {
      name: 'Test Converter',
      path: './test-converter.js',
      description: 'Tests the Markdown ↔ JSON converter'
    },
    {
      name: 'Convert v12 Roadmap',
      path: './convert-v12.js',
      description: 'Converts and validates the v12 architecture cognitive roadmap'
    },
    {
      name: 'Batch Convert',
      path: './batch-convert.js',
      args: ['--md-to-json'],
      description: 'Converts all Markdown roadmaps to JSON'
    }
  ],
  logDir: path.join(__dirname, '../logs'),
  timestamp: new Date().toISOString().replace(/:/g, '-')
};

// Ensure log directory exists
if (!fs.existsSync(config.logDir)) {
  fs.mkdirSync(config.logDir, { recursive: true });
}

/**
 * Run a script and return a promise that resolves when it completes
 * @param {object} script - Script configuration
 * @returns {Promise<object>} - Promise that resolves with the result
 */
function runScript(script) {
  return new Promise((resolve, reject) => {
    console.log(`\n=== Running ${script.name} ===`);
    console.log(`Description: ${script.description}`);
    
    const logFile = path.join(config.logDir, `${script.name.toLowerCase().replace(/\s+/g, '-')}-${config.timestamp}.log`);
    const logStream = fs.createWriteStream(logFile);
    
    const startTime = Date.now();
    const child = spawn('node', [script.path, ...(script.args || [])], {
      cwd: __dirname,
      stdio: ['ignore', 'pipe', 'pipe']
    });
    
    // Log output to console and file
    child.stdout.on('data', (data) => {
      process.stdout.write(data);
      logStream.write(data);
    });
    
    child.stderr.on('data', (data) => {
      process.stderr.write(data);
      logStream.write(data);
    });
    
    child.on('close', (code) => {
      const endTime = Date.now();
      const duration = (endTime - startTime) / 1000;
      
      const result = {
        name: script.name,
        exitCode: code,
        duration,
        logFile
      };
      
      logStream.end(`\nExit code: ${code}\nDuration: ${duration.toFixed(2)}s\n`);
      
      if (code === 0) {
        console.log(`✅ ${script.name} completed successfully in ${duration.toFixed(2)}s`);
        resolve(result);
      } else {
        console.error(`❌ ${script.name} failed with exit code ${code} after ${duration.toFixed(2)}s`);
        reject(result);
      }
    });
    
    child.on('error', (error) => {
      logStream.end(`\nError: ${error.message}\n`);
      reject({
        name: script.name,
        error,
        logFile
      });
    });
  });
}

/**
 * Run all scripts in sequence
 */
async function runAll() {
  console.log('=== Running All Cognitive Architecture Tools ===');
  console.log(`Timestamp: ${config.timestamp}`);
  console.log(`Log directory: ${config.logDir}`);
  
  const results = {
    successful: [],
    failed: []
  };
  
  for (const script of config.scripts) {
    try {
      const result = await runScript(script);
      results.successful.push(result);
    } catch (result) {
      results.failed.push(result);
      
      // Continue with next script even if this one failed
      console.log('Continuing with next script...');
    }
  }
  
  // Generate summary report
  console.log('\n=== Summary ===');
  console.log(`Total scripts: ${config.scripts.length}`);
  console.log(`Successful: ${results.successful.length}`);
  console.log(`Failed: ${results.failed.length}`);
  
  if (results.successful.length > 0) {
    console.log('\nSuccessful scripts:');
    results.successful.forEach(result => {
      console.log(`- ${result.name} (${result.duration.toFixed(2)}s)`);
    });
  }
  
  if (results.failed.length > 0) {
    console.log('\nFailed scripts:');
    results.failed.forEach(result => {
      console.log(`- ${result.name} (Exit code: ${result.exitCode})`);
    });
    
    // Exit with error code if any script failed
    process.exit(1);
  }
}

// Run all scripts
runAll().catch(error => {
  console.error('Error running scripts:', error);
  process.exit(1);
});
