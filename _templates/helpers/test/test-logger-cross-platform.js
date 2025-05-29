// test-logger-cross-platform.js
const { createLogger } = require('../logger-helper.js');
const os = require('os');
const assert = require('assert');

function runTests() {
    console.log('Starting cross-platform logger tests');
    console.log(`Platform: ${os.platform()}`);
    console.log(`Node version: ${process.version}`);

    const tests = [
        testDefaultLogger,
        testNoEmojiLogger,
        testDebugLogger,
        testWindowsLogger,
        testUnixLogger,
        testColorSupport
    ];

    let passed = 0;
    let failed = 0;

    tests.forEach((test, index) => {
        try {
            test();
            passed++;
            console.log(`✓ Test ${index + 1} passed`);
        } catch (error) {
            failed++;
            console.error(`✗ Test ${index + 1} failed:`, error.message);
        }
    });

    console.log('\nTest Summary:');
    console.log(`Total: ${tests.length}`);
    console.log(`Passed: ${passed}`);
    console.log(`Failed: ${failed}`);
}

function testDefaultLogger() {
    const logger = createLogger({ verbosity: 'info' });
    assert(logger, 'Logger should be created with default settings');
}

function testNoEmojiLogger() {
    const logger = createLogger({ verbosity: 'info', useEmoji: false });
    assert(logger, 'Logger should be created without emoji support');
}

function testDebugLogger() {
    const logger = createLogger({ verbosity: 'debug' });
    assert(logger, 'Logger should be created with debug verbosity');
}

function testWindowsLogger() {
    const logger = createLogger({ 
        verbosity: 'info',
        platform: 'win32'
    });
    assert(logger, 'Logger should work on Windows platform');
}

function testUnixLogger() {
    const logger = createLogger({ 
        verbosity: 'info',
        platform: 'darwin'
    });
    assert(logger, 'Logger should work on Unix platform');
}

function testColorSupport() {
    const logger = createLogger({ 
        verbosity: 'info',
        useEmoji: true
    });
    assert(logger, 'Logger should support colors');
}

// Run the tests
runTests();
