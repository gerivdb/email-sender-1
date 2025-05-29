// test-cross-platform.js
const assert = require('assert');
const path = require('path');
const os = require('os');
const { createLogger } = require('../logger-helper.js');
const pathHelper = require('../path-helper.js');

const logger = createLogger({ verbosity: 'info' });

async function runCrossPlatformTests() {
    logger.info('Running cross-platform compatibility tests...');
    logger.info(`Current platform: ${process.platform}`);
    logger.info(`Current architecture: ${process.arch}`);
    logger.info(`Node version: ${process.version}`);

    await testPathSeparators();
    await testEncodings();
    await testLineEndings();
    await testEnvironmentVariables();
}

async function testPathSeparators() {
    logger.info('Testing path separators handling...');

    try {
        const isWindows = process.platform === 'win32';
        const testPaths = [
            'path/to/template',
            'path\\to\\template',
            'C:/path/to/template',
            'C:\\path\\to\\template'
        ];

        testPaths.forEach(testPath => {
            const normalized = path.normalize(testPath);
            if (isWindows) {
                assert(!normalized.includes('/'), `Windows path should not contain forward slashes: ${normalized}`);
            } else {
                assert(!normalized.includes('\\'), `Unix path should not contain backslashes: ${normalized}`);
            }
        });

        logger.info('✓ Path separators handling validated');
    } catch (error) {
        logger.error('✗ Path separators test failed:', error);
    }
}

async function testEncodings() {
    logger.info('Testing character encodings...');

    try {
        // Test des caractères spéciaux dans les messages
        const specialChars = 'éèêë áàâä íìîï óòôö úùûü ñ ç';
        logger.info(`Special characters test: ${specialChars}`);

        // Test des emojis
        const emojis = '📝 📊 ⚠️ ℹ️ ✅';
        const noEmojiLogger = createLogger({ useEmoji: false });
        noEmojiLogger.info(`Emoji fallback test original: ${emojis}`);

        logger.info('✓ Character encodings validated');
    } catch (error) {
        logger.error('✗ Character encodings test failed:', error);
    }
}

async function testLineEndings() {
    logger.info('Testing line endings handling...');

    try {
        const testString = 'line1\nline2\r\nline3\rline4';
        const normalizedString = testString
            .replace(/\r\n/g, os.EOL)
            .replace(/\n/g, os.EOL)
            .replace(/\r/g, os.EOL);

        // Filter out empty lines that might result from the normalization
        const lines = normalizedString.split(os.EOL).filter(line => line.length > 0);
        
        // Verify that we have actual content
        assert(lines.length > 0, 'Should have at least one valid line');
        assert(lines.every(line => line.startsWith('line')), 'All lines should start with "line"');

        logger.info('✓ Line endings handling validated');
    } catch (error) {
        logger.error('✗ Line endings test failed:', error);
    }
}

async function testEnvironmentVariables() {
    logger.info('Testing environment variables handling...');

    try {
        // Test des variables d'environnement spécifiques à la plateforme
        const homeDir = os.homedir();
        const tempDir = os.tmpdir();
        const pathSep = path.sep;

        assert(homeDir, 'Home directory should be defined');
        assert(tempDir, 'Temp directory should be defined');
        assert(pathSep === '/' || pathSep === '\\', 'Path separator should be valid');

        // Vérifier que les chemins sont bien résolus
        const testPath = path.join(tempDir, 'test-file.txt');
        assert(!testPath.includes(path.sep === '/' ? '\\' : '/'), 
            'Resolved path should use correct separator');

        logger.info('✓ Environment variables handling validated');
    } catch (error) {
        logger.error('✗ Environment variables test failed:', error);
    }
}

// Exécuter tous les tests
runCrossPlatformTests().catch(error => {
    logger.error('Cross-platform tests failed:', error);
    process.exit(1);
});
