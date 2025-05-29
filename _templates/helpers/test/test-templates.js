// test-templates.js
const ejs = require('ejs');
const assert = require('assert');
const fs = require('fs').promises;
const path = require('path');
const { createLogger } = require('../logger-helper.js');

const logger = createLogger({ verbosity: 'info' });

async function runTemplateTests() {
    logger.info('Running template tests...');
    
    await testTemplateStructure();
    await testTemplateRendering();
    await testTemplateDynamicPaths();
}

async function testTemplateStructure() {
    logger.info('Testing template structure...');
    
    try {
        // Test main templates existence
        const templateFiles = [
            'index.ejs.t',
            'new.ejs.t',
            'warnings.ejs',
            'toc.ejs'
        ];
        
        for (const file of templateFiles) {
            const exists = await fileExists(path.join('..', 'plan-dev', 'new', file));
            assert(exists, `Template ${file} should exist`);
        }
        
        logger.info('✓ Template structure validated');
    } catch (error) {
        logger.error('✗ Template structure test failed:', error);
    }
}

async function testTemplateRendering() {
    logger.info('Testing template rendering...');
    
    try {
        // Test rendering with sample data
        const sampleData = {
            name: 'test-plan',
            version: 'v1',
            description: 'Test plan',
            phases: 3
        };
        
        const template = await fs.readFile(path.join('..', 'plan-dev', 'new', 'index.ejs.t'), 'utf8');
        const rendered = ejs.render(template, sampleData);
        
        assert(rendered.includes(sampleData.name), 'Rendered template should include plan name');
        assert(rendered.includes(sampleData.version), 'Rendered template should include version');
        
        logger.info('✓ Template rendering validated');
    } catch (error) {
        logger.error('✗ Template rendering test failed:', error);
    }
}

async function testTemplateDynamicPaths() {
    logger.info('Testing template dynamic paths...');
    
    try {
        // Test path generation with different platforms
        const windowsPath = calculateDestinationPath('test-plan', 'windows');
        const unixPath = calculateDestinationPath('test-plan', 'unix');
        
        assert(!windowsPath.includes('/'), 'Windows path should use backslashes');
        assert(!unixPath.includes('\\'), 'Unix path should use forward slashes');
        
        logger.info('✓ Dynamic paths validated');
    } catch (error) {
        logger.error('✗ Dynamic paths test failed:', error);
    }
}

function calculateDestinationPath(name, platform) {
    const base = platform === 'windows' ? 'D:\\plans' : '/plans';
    const separator = platform === 'windows' ? '\\' : '/';
    return `${base}${separator}${name}`;
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
runTemplateTests().catch(error => {
    logger.error('Tests failed:', error);
    process.exit(1);
});
