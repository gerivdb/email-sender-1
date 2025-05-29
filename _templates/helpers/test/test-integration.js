// test-integration.js
const { spawn } = require('child_process');
const assert = require('assert');
const fs = require('fs').promises;
const path = require('path');
const { createLogger } = require('../logger-helper.js');

const logger = createLogger({ verbosity: 'info' });

async function runIntegrationTests() {
    logger.info('Running integration tests...');
    
    await testTemplateGeneration();
    await testCrossTemplateIntegration();
    await testErrorHandling();
}

async function testTemplateGeneration() {
    logger.info('Testing template generation...');
    
    try {
        // Test generating a plan with hygen
        const result = await runHygenCommand(['plan-dev', 'new', '--name', 'test-integration']);
        
        // Verify the generated files
        const files = [
            'plan-dev-test-integration.md',
            'generated/test-integration/index.md',
            'generated/test-integration/toc.md'
        ];
        
        for (const file of files) {
            const exists = await fileExists(file);
            assert(exists, `Generated file ${file} should exist`);
        }
        
        logger.info('✓ Template generation validated');
    } catch (error) {
        logger.error('✗ Template generation test failed:', error);
    }
}

async function testCrossTemplateIntegration() {
    logger.info('Testing cross-template integration...');
    
    try {
        // Test interactions between different templates
        await runHygenCommand(['plan-dev', 'new', '--name', 'cross-test']);
        await runHygenCommand(['roadmap', 'new', '--name', 'cross-test-roadmap']);
        
        // Verify cross-references
        const planContent = await fs.readFile('plan-dev-cross-test.md', 'utf8');
        const roadmapContent = await fs.readFile('cross-test-roadmap.md', 'utf8');
        
        assert(planContent.includes('roadmap'), 'Plan should reference roadmap');
        assert(roadmapContent.includes('plan-dev'), 'Roadmap should reference plan');
        
        logger.info('✓ Cross-template integration validated');
    } catch (error) {
        logger.error('✗ Cross-template integration test failed:', error);
    }
}

async function testErrorHandling() {
    logger.info('Testing error handling...');
    
    try {
        // Test invalid template name
        const result = await runHygenCommand(['plan-dev', 'new', '--name', '']);
        assert(result.code !== 0, 'Should fail with invalid name');
        
        // Test missing required arguments
        const result2 = await runHygenCommand(['plan-dev', 'new']);
        assert(result2.code !== 0, 'Should fail without required arguments');
        
        logger.info('✓ Error handling validated');
    } catch (error) {
        logger.error('✗ Error handling test failed:', error);
    }
}

function runHygenCommand(args) {
    return new Promise((resolve, reject) => {
        const hygen = spawn('hygen', args, { shell: true });
        
        let stdout = '';
        let stderr = '';
        
        hygen.stdout.on('data', data => stdout += data);
        hygen.stderr.on('data', data => stderr += data);
        
        hygen.on('close', code => {
            resolve({ code, stdout, stderr });
        });
        
        hygen.on('error', reject);
    });
}

async function fileExists(filepath) {
    try {
        await fs.access(filepath);
        return true;
    } catch {
        return false;
    }
}

// Run all tests
runIntegrationTests().catch(error => {
    logger.error('Tests failed:', error);
    process.exit(1);
});
