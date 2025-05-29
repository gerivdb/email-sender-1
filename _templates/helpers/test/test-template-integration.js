// test-template-integration.js
const assert = require('assert');
const path = require('path');
const { createLogger } = require('../logger-helper.js');
const metricsHelper = require('../metrics-helper.js');
const pathHelper = require('../path-helper.js');

const logger = createLogger({ verbosity: 'info' });

async function runIntegrationTests() {
    logger.info('Running template integration tests...');

    await testTemplateStructure();
    await testPathResolution();
    await testMetricsIntegration();
    await testWarningsIntegration();
}

async function testTemplateStructure() {
    logger.info('Testing template structure integration...');

    try {
        // Vérifier la structure des dossiers
        const commonFolders = pathHelper.config.commonFolders;
        assert(commonFolders.templates === '_templates', 'Templates folder should be _templates');
        assert(commonFolders.roadmaps.includes('roadmaps'), 'Roadmaps folder should be configured');

        // Vérifier la configuration du projet
        const projectRoot = pathHelper.config.projectRoot;
        assert(projectRoot.endsWith('EMAIL_SENDER_1'), 'Project root should be correctly detected');

        logger.info('✓ Template structure integration validated');
    } catch (error) {
        logger.error('✗ Template structure integration test failed:', error);
    }
}

async function testPathResolution() {
    logger.info('Testing path resolution integration...');

    try {
        // Vérifier que les chemins respectent l'OS
        const isWindows = process.platform === 'win32';
        const templatePath = path.join(pathHelper.config.commonFolders.templates, 'plan-dev');
        
        if (isWindows) {
            assert(templatePath.includes('\\'), 'Windows paths should use backslashes');
        } else {
            assert(templatePath.includes('/'), 'Unix paths should use forward slashes');
        }

        logger.info('✓ Path resolution integration validated');
    } catch (error) {
        logger.error('✗ Path resolution integration test failed:', error);
    }
}

async function testMetricsIntegration() {
    logger.info('Testing metrics integration...');

    try {
        // Vérifier l'intégration des métriques
        const metrics = metricsHelper.getDefaultMetrics();
        const warnings = metricsHelper.getDefaultWarnings();

        assert(metrics.totalTasks === 9, 'Default total tasks should be 9');
        assert(Array.isArray(warnings), 'Warnings should be an array');
        assert(warnings.some(w => w.severity === 'HAUTE'), 'Should include high severity warnings');

        logger.info('✓ Metrics integration validated');
    } catch (error) {
        logger.error('✗ Metrics integration test failed:', error);
    }
}

async function testWarningsIntegration() {
    logger.info('Testing warnings integration...');

    try {
        // Vérifier l'intégration des warnings avec le logger
        const warnings = metricsHelper.getDefaultWarnings();
        
        warnings.forEach(warning => {
            logger.warn(`[${warning.severity}] ${warning.message}`);
        });

        logger.info('✓ Warnings integration validated');
    } catch (error) {
        logger.error('✗ Warnings integration test failed:', error);
    }
}

// Exécuter tous les tests
runIntegrationTests().catch(error => {
    logger.error('Integration tests failed:', error);
    process.exit(1);
});
