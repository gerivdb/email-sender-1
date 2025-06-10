import { expect } from 'chai';
import { SelectionGranularizer, AtomicTask, EcosystemContext } from '../../selectionGranularizer';
import * as vscode from 'vscode';
import * as sinon from 'sinon';
import * as fs from 'fs';
import * as path from 'path';

describe('SelectionGranularizer', () => {
    let granularizer: SelectionGranularizer;
    let mockContext: vscode.ExtensionContext;
    let mockOutputChannel: vscode.OutputChannel;
    let fsStub: sinon.SinonStub;
    let workspaceStub: sinon.SinonStub;

    beforeEach(() => {
        // Mock extension context
        mockContext = {
            subscriptions: [],
            workspaceState: {} as any,
            globalState: {} as any,
            extensionUri: {} as any,
            extensionPath: '',
            storageUri: {} as any,
            globalStorageUri: {} as any,
            logUri: {} as any,
            storagePath: '',
            globalStoragePath: '',
            logPath: '',
            asAbsolutePath: sinon.stub().returns(''),
            environmentVariableCollection: {} as any,
            extension: {} as any,
            extensionMode: vscode.ExtensionMode.Development,
            secrets: {} as any,
            languageModelAccessInformation: {} as any
        };

        // Mock output channel
        mockOutputChannel = {
            show: sinon.stub(),
            hide: sinon.stub(),
            dispose: sinon.stub(),
            append: sinon.stub(),
            appendLine: sinon.stub(),
            clear: sinon.stub(),
            replace: sinon.stub(),
            name: 'Test Channel'
        };

        // Mock vscode.window.createOutputChannel
        sinon.stub(vscode.window, 'createOutputChannel').returns(mockOutputChannel);

        granularizer = new SelectionGranularizer(mockContext);

        // Setup file system stubs
        fsStub = sinon.stub(fs, 'existsSync');
        workspaceStub = sinon.stub(vscode.workspace, 'getWorkspaceFolder');
    });

    afterEach(() => {
        sinon.restore();
    });

    describe('constructor', () => {
        it('should initialize with context and create output channel', () => {
            expect(granularizer).to.be.instanceof(SelectionGranularizer);
            expect(vscode.window.createOutputChannel).to.have.been.calledWith('Selection Granularizer');
        });
    });

    describe('granularizeActiveSelection', () => {
        let mockEditor: vscode.TextEditor;
        let mockDocument: vscode.TextDocument;
        let mockSelection: vscode.Selection;

        beforeEach(() => {
            // Mock text selection
            mockSelection = new vscode.Selection(0, 0, 0, 10);
            
            // Mock document
            mockDocument = {
                getText: sinon.stub().returns('test selection content'),
                uri: vscode.Uri.file('/test/path/file.ts'),
                fileName: 'file.ts',
                isUntitled: false,
                languageId: 'typescript',
                version: 1,
                isDirty: false,
                isClosed: false,
                save: sinon.stub(),
                eol: vscode.EndOfLine.LF,
                lineCount: 1,
                lineAt: sinon.stub(),
                offsetAt: sinon.stub(),
                positionAt: sinon.stub(),
                getWordRangeAtPosition: sinon.stub(),
                validateRange: sinon.stub(),
                validatePosition: sinon.stub()
            } as any;

            // Mock editor
            mockEditor = {
                document: mockDocument,
                selection: mockSelection,
                selections: [mockSelection],
                visibleRanges: [],
                options: {} as any,
                viewColumn: vscode.ViewColumn.One,
                edit: sinon.stub(),
                insertSnippet: sinon.stub(),
                setDecorations: sinon.stub(),
                revealRange: sinon.stub(),
                show: sinon.stub(),
                hide: sinon.stub()
            };

            // Mock workspace folder
            const mockWorkspaceFolder = {
                uri: vscode.Uri.file('/test/workspace'),
                name: 'test-workspace',
                index: 0
            };

            workspaceStub.returns(mockWorkspaceFolder);
            sinon.stub(vscode.window, 'activeTextEditor').value(mockEditor);
        });

        it('should throw error when no active editor', async () => {
            sinon.stub(vscode.window, 'activeTextEditor').value(undefined);
            
            try {
                await granularizer.granularizeActiveSelection();
                expect.fail('Should have thrown error');
            } catch (error) {
                expect(error.message).to.equal('❌ Aucun éditeur actif détecté');
            }
        });

        it('should throw error when no text selected', async () => {
            mockDocument.getText = sinon.stub().returns('   '); // Only whitespace
            
            try {
                await granularizer.granularizeActiveSelection();
                expect.fail('Should have thrown error');
            } catch (error) {
                expect(error.message).to.equal('❌ Aucune sélection active dans l\'éditeur');
            }
        });

        it('should successfully granularize TypeScript selection', async () => {
            // Setup TypeScript project detection
            fsStub.withArgs('/test/workspace/package.json').returns(true);
            fsStub.withArgs('/test/workspace/go.mod').returns(false);
            fsStub.withArgs('/test/workspace/requirements.txt').returns(false);

            // Mock package.json content
            sinon.stub(fs, 'readFileSync').returns('{"name": "test-project"}');

            // Mock workspace.findFiles for architecture detection
            sinon.stub(vscode.workspace, 'findFiles').resolves([
                vscode.Uri.file('/test/workspace/src/interface.ts'),
                vscode.Uri.file('/test/workspace/src/service.ts')
            ]);

            // Mock workspace.openTextDocument and showTextDocument
            const mockReportDoc = { getText: () => 'report content' } as any;
            sinon.stub(vscode.workspace, 'openTextDocument').resolves(mockReportDoc);
            sinon.stub(vscode.window, 'showTextDocument').resolves({} as any);

            // Mock writeFileSync for report generation
            const writeFileStub = sinon.stub(fs, 'writeFileSync');

            const result = await granularizer.granularizeActiveSelection();

            expect(result).to.be.an('array');
            expect(result.length).to.be.greaterThan(0);
            
            // Verify hierarchical structure (levels 1-8)
            const levels = new Set(result.map(task => task.level));
            for (let level = 1; level <= 8; level++) {
                expect(levels.has(level)).to.be.true;
            }

            // Verify parent-child relationships
            const level1Tasks = result.filter(task => task.level === 1);
            expect(level1Tasks.length).to.be.greaterThan(0);
            
            const level2Tasks = result.filter(task => task.level === 2);
            level2Tasks.forEach(task => {
                expect(task.parent).to.be.a('string');
                expect(level1Tasks.some(parent => parent.id === task.parent)).to.be.true;
            });

            // Verify report generation
            expect(writeFileStub).to.have.been.called;
            expect(vscode.workspace.openTextDocument).to.have.been.called;
            expect(vscode.window.showTextDocument).to.have.been.called;
        });

        it('should detect Go project correctly', async () => {
            // Setup Go project detection
            fsStub.withArgs('/test/workspace/package.json').returns(false);
            fsStub.withArgs('/test/workspace/go.mod').returns(true);
            fsStub.withArgs('/test/workspace/requirements.txt').returns(false);

            sinon.stub(fs, 'readFileSync').returns('module test-project');
            sinon.stub(vscode.workspace, 'findFiles').resolves([]);
            sinon.stub(vscode.workspace, 'openTextDocument').resolves({} as any);
            sinon.stub(vscode.window, 'showTextDocument').resolves({} as any);
            sinon.stub(fs, 'writeFileSync');

            const result = await granularizer.granularizeActiveSelection();

            expect(result).to.be.an('array');
            
            // Check that Go-specific commands are included
            const level1Task = result.find(task => task.level === 1);
            expect(level1Task?.title).to.include('Go');
        });

        it('should detect Python project correctly', async () => {
            // Setup Python project detection
            fsStub.withArgs('/test/workspace/package.json').returns(false);
            fsStub.withArgs('/test/workspace/go.mod').returns(false);
            fsStub.withArgs('/test/workspace/requirements.txt').returns(true);

            sinon.stub(fs, 'readFileSync').returns('flask==2.0.0');
            sinon.stub(vscode.workspace, 'findFiles').resolves([]);
            sinon.stub(vscode.workspace, 'openTextDocument').resolves({} as any);
            sinon.stub(vscode.window, 'showTextDocument').resolves({} as any);
            sinon.stub(fs, 'writeFileSync');

            const result = await granularizer.granularizeActiveSelection();

            expect(result).to.be.an('array');
            
            // Check that Python-specific commands are included
            const level1Task = result.find(task => task.level === 1);
            expect(level1Task?.title).to.include('Python');
        });
    });

    describe('ecosystem analysis', () => {
        it('should detect camelCase naming convention', async () => {
            const granularizerPrivate = granularizer as any;
            
            // Mock findFiles to return camelCase files
            sinon.stub(vscode.workspace, 'findFiles').resolves([
                vscode.Uri.file('/test/userService.ts'),
                vscode.Uri.file('/test/dataManager.ts'),
                vscode.Uri.file('/test/configHelper.ts')
            ]);

            const context: EcosystemContext = {
                projectType: 'unknown',
                technologyStack: [],
                architecturePattern: 'unknown',
                namingConvention: 'unknown',
                buildCommands: [],
                testCommands: [],
                existingFiles: []
            };

            await granularizerPrivate.detectNamingConventions('/test/workspace', context);
            
            expect(context.namingConvention).to.equal('camelCase');
        });

        it('should detect PascalCase naming convention', async () => {
            const granularizerPrivate = granularizer as any;
            
            sinon.stub(vscode.workspace, 'findFiles').resolves([
                vscode.Uri.file('/test/UserService.ts'),
                vscode.Uri.file('/test/DataManager.ts'),
                vscode.Uri.file('/test/ConfigHelper.ts')
            ]);

            const context: EcosystemContext = {
                projectType: 'unknown',
                technologyStack: [],
                architecturePattern: 'unknown',
                namingConvention: 'unknown',
                buildCommands: [],
                testCommands: [],
                existingFiles: []
            };

            await granularizerPrivate.detectNamingConventions('/test/workspace', context);
            
            expect(context.namingConvention).to.equal('PascalCase');
        });

        it('should detect snake_case naming convention', async () => {
            const granularizerPrivate = granularizer as any;
            
            sinon.stub(vscode.workspace, 'findFiles').resolves([
                vscode.Uri.file('/test/user_service.py'),
                vscode.Uri.file('/test/data_manager.py'),
                vscode.Uri.file('/test/config_helper.py')
            ]);

            const context: EcosystemContext = {
                projectType: 'unknown',
                technologyStack: [],
                architecturePattern: 'unknown',
                namingConvention: 'unknown',
                buildCommands: [],
                testCommands: [],
                existingFiles: []
            };

            await granularizerPrivate.detectNamingConventions('/test/workspace', context);
            
            expect(context.namingConvention).to.equal('snake_case');
        });
    });

    describe('component identification', () => {
        it('should identify function components', () => {
            const granularizerPrivate = granularizer as any;
            const selectedText = 'function calculateSum(a, b) { return a + b; }';
            
            const components = granularizerPrivate.identifyRequiredComponents(selectedText);
            
            expect(components).to.be.an('array');
            expect(components.some(c => c.type === 'Function')).to.be.true;
        });

        it('should identify type components', () => {
            const granularizerPrivate = granularizer as any;
            const selectedText = 'interface User { name: string; email: string; }';
            
            const components = granularizerPrivate.identifyRequiredComponents(selectedText);
            
            expect(components).to.be.an('array');
            expect(components.some(c => c.type === 'Type')).to.be.true;
        });

        it('should identify dependency components', () => {
            const granularizerPrivate = granularizer as any;
            const selectedText = 'import { Service } from "./service"; require("express");';
            
            const components = granularizerPrivate.identifyRequiredComponents(selectedText);
            
            expect(components).to.be.an('array');
            expect(components.some(c => c.type === 'Dependency')).to.be.true;
        });

        it('should default to content processor', () => {
            const granularizerPrivate = granularizer as any;
            const selectedText = 'some generic content without special patterns';
            
            const components = granularizerPrivate.identifyRequiredComponents(selectedText);
            
            expect(components).to.be.an('array');
            expect(components.length).to.equal(1);
            expect(components[0].type).to.equal('Content');
            expect(components[0].name).to.equal('ContentProcessor');
        });
    });

    describe('hierarchical structure validation', () => {
        it('should validate correct hierarchical structure', async () => {
            const granularizerPrivate = granularizer as any;
            
            const tasks: AtomicTask[] = [
                {
                    id: 'task-1',
                    title: 'Level 1 Task',
                    level: 1,
                    children: ['task-2'],
                    description: 'Main task',
                    prerequisites: [],
                    outputs: [],
                    estimatedDuration: 60,
                    complexity: 'COMPLEXE',
                    commands: [],
                    validationCriteria: []
                },
                {
                    id: 'task-2',
                    title: 'Level 2 Task',
                    level: 2,
                    parent: 'task-1',
                    children: [],
                    description: 'Sub task',
                    prerequisites: [],
                    outputs: [],
                    estimatedDuration: 30,
                    complexity: 'COMPOSEE',
                    commands: [],
                    validationCriteria: []
                }
            ];

            // Add tasks for all levels 3-8
            for (let level = 3; level <= 8; level++) {
                tasks.push({
                    id: `task-${level}`,
                    title: `Level ${level} Task`,
                    level,
                    parent: level === 3 ? 'task-2' : `task-${level - 1}`,
                    children: level < 8 ? [`task-${level + 1}`] : [],
                    description: `Level ${level} task`,
                    prerequisites: [],
                    outputs: [],
                    estimatedDuration: 10,
                    complexity: 'ATOMIQUE',
                    commands: [],
                    validationCriteria: []
                });
            }

            const context: EcosystemContext = {
                projectType: 'TypeScript',
                technologyStack: ['TypeScript'],
                architecturePattern: 'SOLID',
                namingConvention: 'camelCase',
                buildCommands: ['npm run build'],
                testCommands: ['npm test'],
                existingFiles: []
            };

            // Should not throw
            await granularizerPrivate.validateArchitecturalCoherence(tasks, context);
        });

        it('should throw error for missing hierarchy level', async () => {
            const granularizerPrivate = granularizer as any;
            
            const tasks: AtomicTask[] = [
                {
                    id: 'task-1',
                    title: 'Level 1 Task',
                    level: 1,
                    children: [],
                    description: 'Main task',
                    prerequisites: [],
                    outputs: [],
                    estimatedDuration: 60,
                    complexity: 'COMPLEXE',
                    commands: [],
                    validationCriteria: []
                }
                // Missing levels 2-8
            ];

            const context: EcosystemContext = {
                projectType: 'TypeScript',
                technologyStack: ['TypeScript'],
                architecturePattern: 'SOLID',
                namingConvention: 'camelCase',
                buildCommands: ['npm run build'],
                testCommands: ['npm test'],
                existingFiles: []
            };

            try {
                await granularizerPrivate.validateArchitecturalCoherence(tasks, context);
                expect.fail('Should have thrown error');
            } catch (error) {
                expect(error.message).to.include('Niveau hiérarchique');
                expect(error.message).to.include('manquant');
            }
        });

        it('should throw error for invalid parent reference', async () => {
            const granularizerPrivate = granularizer as any;
            
            const tasks: AtomicTask[] = [];
            // Add all levels but with invalid parent reference
            for (let level = 1; level <= 8; level++) {
                tasks.push({
                    id: `task-${level}`,
                    title: `Level ${level} Task`,
                    level,
                    parent: level > 1 ? 'invalid-parent' : undefined,
                    children: [],
                    description: `Level ${level} task`,
                    prerequisites: [],
                    outputs: [],
                    estimatedDuration: 10,
                    complexity: 'ATOMIQUE',
                    commands: [],
                    validationCriteria: []
                });
            }

            const context: EcosystemContext = {
                projectType: 'TypeScript',
                technologyStack: ['TypeScript'],
                architecturePattern: 'SOLID',
                namingConvention: 'camelCase',
                buildCommands: ['npm run build'],
                testCommands: ['npm test'],
                existingFiles: []
            };

            try {
                await granularizerPrivate.validateArchitecturalCoherence(tasks, context);
                expect.fail('Should have thrown error');
            } catch (error) {
                expect(error.message).to.include('Parent');
                expect(error.message).to.include('introuvable');
            }
        });
    });

    describe('report generation', () => {
        it('should generate comprehensive markdown report', async () => {
            const granularizerPrivate = granularizer as any;
            
            const tasks: AtomicTask[] = [
                {
                    id: 'task-1',
                    title: '🏗️ Architecture principale',
                    level: 1,
                    children: ['task-2'],
                    description: 'Main architecture task',
                    prerequisites: ['System ready'],
                    outputs: ['Architecture complete'],
                    estimatedDuration: 120,
                    complexity: 'COMPLEXE',
                    commands: ['npm run build'],
                    validationCriteria: ['Build successful']
                },
                {
                    id: 'task-2',
                    title: '🔧 Sous-système spécialisé',
                    level: 2,
                    parent: 'task-1',
                    children: [],
                    description: 'Specialized subsystem',
                    prerequisites: ['Architecture ready'],
                    outputs: ['Subsystem functional'],
                    estimatedDuration: 60,
                    complexity: 'COMPOSEE',
                    commands: ['npm test'],
                    validationCriteria: ['Tests pass']
                }
            ];

            const context: EcosystemContext = {
                projectType: 'Node.js/TypeScript',
                technologyStack: ['JavaScript', 'TypeScript', 'Node.js'],
                architecturePattern: 'SOLID + Dependency Injection',
                namingConvention: 'camelCase',
                buildCommands: ['npm run build', 'npm run compile'],
                testCommands: ['npm test', 'npm run test:unit'],
                existingFiles: []
            };

            // Mock workspace folder
            const mockWorkspaceFolder = {
                uri: vscode.Uri.file('/test/workspace'),
                name: 'test-workspace',
                index: 0
            };
            sinon.stub(vscode.workspace, 'workspaceFolders').value([mockWorkspaceFolder]);

            // Mock file operations
            const writeFileStub = sinon.stub(fs, 'writeFileSync');
            const mockReportDoc = { getText: () => 'report content' } as any;
            sinon.stub(vscode.workspace, 'openTextDocument').resolves(mockReportDoc);
            sinon.stub(vscode.window, 'showTextDocument').resolves({} as any);

            await granularizerPrivate.generateCompletionReport(tasks, context);

            expect(writeFileStub).to.have.been.called;
            const reportContent = writeFileStub.getCall(0).args[1];
            
            // Verify report structure
            expect(reportContent).to.include('# Rapport de Granularisation Ultra-Précise');
            expect(reportContent).to.include('## 📊 Statistiques');
            expect(reportContent).to.include('**Tâches totales**: 2');
            expect(reportContent).to.include('**Écosystème détecté**: Node.js/TypeScript');
            expect(reportContent).to.include('**Stack technologique**: JavaScript, TypeScript, Node.js');
            expect(reportContent).to.include('## 🏗️ Structure Hiérarchique');
            expect(reportContent).to.include('## ⚡ Tâches par Niveau');
            expect(reportContent).to.include('## 🎯 Instructions d\'Exécution');
            expect(reportContent).to.include('## ✅ Critères de Validation');
        });
    });
});
