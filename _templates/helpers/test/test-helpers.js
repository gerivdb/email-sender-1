// test-helpers.js
const assert = require('assert');
const { createLogger } = require('../logger-helper.js');
const metricsHelper = require('../metrics-helper.js');
const pathHelper = require('../path-helper.js');
const os = require('os');

function runHelperTests() {
    console.log('Running helper tests...');
    console.log(`Platform: ${os.platform()}`);
    console.log(`Node version: ${process.version}\n`);

    testLoggerHelper();
    testMetricsHelper();
    testPathHelper();
}

function testLoggerHelper() {
    console.log('Testing Logger Helper...');
    
    const logger = createLogger({ verbosity: 'debug' });
    
    // Test logging levels
    try {
        logger.debug('Debug message');
        logger.info('Info message');
        logger.warn('Warning message');
        logger.error('Error message');
        console.log('✓ Logger levels working correctly');
    } catch (error) {
        console.error('✗ Logger levels test failed:', error);
    }
    
    // Test emoji fallbacks
    try {
        const noEmojiLogger = createLogger({ useEmoji: false });
        noEmojiLogger.info('Message without emoji');
        console.log('✓ Emoji fallback working correctly');
    } catch (error) {
        console.error('✗ Emoji fallback test failed:', error);
    }
}

function testMetricsHelper() {
    console.log('\nTesting Metrics Helper...');
    
    try {
        const metrics = metricsHelper.getDefaultMetrics();
        assert(metrics.totalTasks === 9);
        assert(metrics.completedTasks === 0);
        assert(metrics.efficiency === 0);
        assert(metrics.testCoverage === 0);
        console.log('✓ Default metrics working correctly');
    } catch (error) {
        console.error('✗ Default metrics test failed:', error);
    }
    
    try {
        const warnings = metricsHelper.getDefaultWarnings();
        assert(Array.isArray(warnings));
        assert(warnings.length > 0);
        assert(warnings[0].severity === 'HAUTE');
        console.log('✓ Default warnings working correctly');
    } catch (error) {
        console.error('✗ Default warnings test failed:', error);
    }
}

function testPathHelper() {
    console.log('\nTesting Path Helper...');
    
    // Test configuration access
    try {
        assert(pathHelper.config.projectRoot);
        assert(pathHelper.config.commonFolders);
        console.log('✓ Path helper configuration accessible');
    } catch (error) {
        console.error('✗ Path helper configuration test failed:', error);
    }
    
    // Test common folders structure
    try {
        const { commonFolders } = pathHelper.config;
        assert(commonFolders.roadmaps === 'roadmaps/plans/consolidated');
        assert(commonFolders.templates === '_templates');
        console.log('✓ Common folders structure correct');
    } catch (error) {
        console.error('✗ Common folders structure test failed:', error);
    }    // Test project structure
    try {
        assert(pathHelper.config.commonFolders.scripts);
        assert(pathHelper.config.projectRoot);
        console.log('✓ Project structure correctly defined');
    } catch (error) {
        console.error('✗ Project structure test failed:', error);
    }
}

// Run all tests
runHelperTests();
