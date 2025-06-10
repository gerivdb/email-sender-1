import { expect } from 'chai';
import * as vscode from 'vscode';
import * as path from 'path';
import * as fs from 'fs';
import { SelectionGranularizer } from '../../selectionGranularizer';

/**
 * Tests d'intégration pour la granularisation ultra-précise
 * Ces tests vérifient le comportement complet de bout en bout
 */
describe('Granularization Integration Tests', function() {
    // Timeout plus long pour les tests d'intégration
    this.timeout(30000);

    let extension: vscode.Extension<any>;
    let tempWorkspace: string;
    let granularizer: SelectionGranularizer;

    before(async () => {
        // Charger l'extension
        extension = vscode.extensions.getExtension('error-pattern-analyzer')!;
        await extension.activate();

        // Créer un workspace temporaire
        tempWorkspace = path.join(__dirname, '../../test-workspace');
        if (!fs.existsSync(tempWorkspace)) {
            fs.mkdirSync(tempWorkspace, { recursive: true });
        }

        granularizer = new SelectionGranularizer({} as any);
    });

    after(() => {
        // Nettoyage du workspace temporaire
        if (fs.existsSync(tempWorkspace)) {
            fs.rmSync(tempWorkspace, { recursive: true, force: true });
        }
    });

    describe('End-to-End Granularization Flow', () => {
        let testDocument: vscode.TextDocument;
        let testEditor: vscode.TextEditor;

        beforeEach(async () => {
            // Créer un fichier de test TypeScript
            const testFilePath = path.join(tempWorkspace, 'test.ts');
            const testContent = `
// Test TypeScript code for granularization
interface User {
    id: string;
    name: string;
    email: string;
}

class UserService {
    private users: User[] = [];

    constructor(private dataStore: DataStore) {}

    async createUser(userData: Partial<User>): Promise<User> {
        const user: User = {
            id: generateId(),
            name: userData.name || '',
            email: userData.email || ''
        };
        
        this.users.push(user);
        await this.dataStore.save(user);
        return user;
    }

    async findUserById(id: string): Promise<User | null> {
        return this.users.find(user => user.id === id) || null;
    }
}

function generateId(): string {
    return Math.random().toString(36).substr(2, 9);
}
`.trim();

            fs.writeFileSync(testFilePath, testContent, 'utf8');

            // Ouvrir le document dans VS Code
            testDocument = await vscode.workspace.openTextDocument(testFilePath);
            testEditor = await vscode.window.showTextDocument(testDocument);
        });

        afterEach(async () => {
            // Fermer l'éditeur
            await vscode.commands.executeCommand('workbench.action.closeActiveEditor');
        });

        it('should granularize TypeScript interface selection with 100% success', async () => {
            // Sélectionner l'interface User
            const interfaceStart = testDocument.getText().indexOf('interface User');
            const interfaceEnd = testDocument.getText().indexOf('}', interfaceStart) + 1;
            
            const startPos = testDocument.positionAt(interfaceStart);
            const endPos = testDocument.positionAt(interfaceEnd);
            const selection = new vscode.Selection(startPos, endPos);
            
            testEditor.selection = selection;

            // Créer un package.json pour détecter le projet TypeScript
            const packageJsonPath = path.join(tempWorkspace, 'package.json');
            const packageJsonContent = {
                name: 'test-project',
                version: '1.0.0',
                dependencies: {
                    typescript: '^4.0.0'
                },
                scripts: {
                    build: 'tsc',
                    test: 'jest'
                }
            };
            fs.writeFileSync(packageJsonPath, JSON.stringify(packageJsonContent, null, 2));

            // Exécuter la granularisation
            const result = await granularizer.granularizeActiveSelection();

            // Vérifications de réussite à 100%
            expect(result).to.be.an('array');
            expect(result.length).to.be.greaterThan(0);

            // Vérifier la structure hiérarchique complète (8 niveaux)
            const levels = [...new Set(result.map(task => task.level))].sort();
            expect(levels).to.deep.equal([1, 2, 3, 4, 5, 6, 7, 8]);

            // Vérifier l'intégrité des relations parent-enfant
            for (const task of result) {
                if (task.parent) {
                    const parent = result.find(t => t.id === task.parent);
                    expect(parent).to.exist;
                    expect(parent!.level).to.be.lessThan(task.level);
                    expect(parent!.children).to.include(task.id);
                }
            }

            // Vérifier que le rapport a été généré
            const reportPath = path.join(tempWorkspace, 'GRANULARIZATION_REPORT.md');
            expect(fs.existsSync(reportPath)).to.be.true;

            const reportContent = fs.readFileSync(reportPath, 'utf8');
            expect(reportContent).to.include('# Rapport de Granularisation Ultra-Précise');
            expect(reportContent).to.include('Node.js/TypeScript'); // Type de projet détecté
            expect(reportContent).to.include('8'); // Niveaux hiérarchiques

            console.log(`✅ Granularisation réussie: ${result.length} tâches créées`);
        });

        it('should granularize class method selection correctly', async () => {
            // Sélectionner la méthode createUser
            const methodStart = testDocument.getText().indexOf('async createUser');
            const methodEnd = testDocument.getText().indexOf('    }', methodStart) + 5;
            
            const startPos = testDocument.positionAt(methodStart);
            const endPos = testDocument.positionAt(methodEnd);
            const selection = new vscode.Selection(startPos, endPos);
            
            testEditor.selection = selection;

            const result = await granularizer.granularizeActiveSelection();

            // Vérifier la détection de composants fonction
            expect(result.some(task => 
                task.title.includes('Function') || 
                task.description.includes('function')
            )).to.be.true;

            // Vérifier la complexité appropriée pour une méthode
            const level1Task = result.find(task => task.level === 1);
            expect(level1Task?.complexity).to.equal('COMPLEXE');

            const atomicTasks = result.filter(task => task.level >= 6);
            atomicTasks.forEach(task => {
                expect(task.complexity).to.equal('ATOMIQUE');
                expect(task.estimatedDuration).to.be.lessThan(30);
            });
        });

        it('should handle function selection with dependency analysis', async () => {
            // Sélectionner la fonction generateId avec ses dépendances
            const functionStart = testDocument.getText().indexOf('function generateId');
            const functionEnd = testDocument.getText().lastIndexOf('}') + 1;
            
            const startPos = testDocument.positionAt(functionStart);
            const endPos = testDocument.positionAt(functionEnd);
            const selection = new vscode.Selection(startPos, endPos);
            
            testEditor.selection = selection;

            const result = await granularizer.granularizeActiveSelection();

            // Vérifier que les tâches incluent la validation appropriée
            const validationCriteria = result.flatMap(task => task.validationCriteria);
            expect(validationCriteria.some(criteria => 
                criteria.includes('Build') || criteria.includes('Test')
            )).to.be.true;

            // Vérifier la génération de commandes appropriées
            const commands = result.flatMap(task => task.commands);
            expect(commands.length).to.be.greaterThan(0);
        });
    });

    describe('Multi-Project Type Detection', () => {
        it('should detect Go project architecture', async () => {
            // Créer un projet Go
            const goModPath = path.join(tempWorkspace, 'go.mod');
            const goModContent = `module test-go-project

go 1.19

require (
    github.com/gorilla/mux v1.8.0
)`;
            fs.writeFileSync(goModPath, goModContent);

            // Créer un fichier Go
            const goFilePath = path.join(tempWorkspace, 'main.go');
            const goContent = `package main

import (
    "fmt"
    "net/http"
)

type Server struct {
    port string
}

func (s *Server) Start() error {
    return http.ListenAndServe(":"+s.port, nil)
}

func main() {
    server := &Server{port: "8080"}
    fmt.Println("Starting server...")
    server.Start()
}`;
            fs.writeFileSync(goFilePath, goContent);

            const testDocument = await vscode.workspace.openTextDocument(goFilePath);
            const testEditor = await vscode.window.showTextDocument(testDocument);

            // Sélectionner la struct Server
            const structStart = testDocument.getText().indexOf('type Server');
            const structEnd = testDocument.getText().indexOf('}', structStart) + 1;
            
            const startPos = testDocument.positionAt(structStart);
            const endPos = testDocument.positionAt(structEnd);
            testEditor.selection = new vscode.Selection(startPos, endPos);

            const result = await granularizer.granularizeActiveSelection();

            // Vérifier la détection du projet Go
            const level1Task = result.find(task => task.level === 1);
            expect(level1Task?.title).to.include('Go');

            // Vérifier les commandes Go appropriées
            const commands = result.flatMap(task => task.commands);
            expect(commands.some(cmd => cmd.includes('go build') || cmd.includes('go test'))).to.be.true;

            await vscode.commands.executeCommand('workbench.action.closeActiveEditor');
        });

        it('should detect Python project with requirements.txt', async () => {
            // Créer un projet Python
            const requirementsPath = path.join(tempWorkspace, 'requirements.txt');
            const requirementsContent = `flask==2.0.0
requests==2.25.1
pytest==6.2.0`;
            fs.writeFileSync(requirementsPath, requirementsContent);

            // Créer un fichier Python
            const pyFilePath = path.join(tempWorkspace, 'app.py');
            const pyContent = `from flask import Flask, request, jsonify
import requests

app = Flask(__name__)

class UserService:
    def __init__(self):
        self.users = []
    
    def create_user(self, user_data):
        user = {
            'id': len(self.users) + 1,
            'name': user_data.get('name', ''),
            'email': user_data.get('email', '')
        }
        self.users.append(user)
        return user

@app.route('/users', methods=['POST'])
def create_user():
    service = UserService()
    user = service.create_user(request.json)
    return jsonify(user)

if __name__ == '__main__':
    app.run(debug=True)`;
            fs.writeFileSync(pyFilePath, pyContent);

            const testDocument = await vscode.workspace.openTextDocument(pyFilePath);
            const testEditor = await vscode.window.showTextDocument(testDocument);

            // Sélectionner la classe UserService
            const classStart = testDocument.getText().indexOf('class UserService');
            const classEnd = testDocument.getText().indexOf('    return user') + 15;
            
            const startPos = testDocument.positionAt(classStart);
            const endPos = testDocument.positionAt(classEnd);
            testEditor.selection = new vscode.Selection(startPos, endPos);

            const result = await granularizer.granularizeActiveSelection();

            // Vérifier la détection du projet Python
            const level1Task = result.find(task => task.level === 1);
            expect(level1Task?.title).to.include('Python');

            // Vérifier les commandes Python appropriées
            const commands = result.flatMap(task => task.commands);
            expect(commands.some(cmd => 
                cmd.includes('python') || 
                cmd.includes('pytest') || 
                cmd.includes('pip')
            )).to.be.true;

            await vscode.commands.executeCommand('workbench.action.closeActiveEditor');
        });
    });

    describe('Error Handling and Edge Cases', () => {
        it('should handle empty selection gracefully', async () => {
            const testFilePath = path.join(tempWorkspace, 'empty.ts');
            fs.writeFileSync(testFilePath, 'const x = 1;');

            const testDocument = await vscode.workspace.openTextDocument(testFilePath);
            const testEditor = await vscode.window.showTextDocument(testDocument);

            // Sélection vide
            testEditor.selection = new vscode.Selection(0, 0, 0, 0);

            try {
                await granularizer.granularizeActiveSelection();
                expect.fail('Should have thrown error for empty selection');
            } catch (error) {
                expect(error.message).to.include('Aucune sélection active');
            }

            await vscode.commands.executeCommand('workbench.action.closeActiveEditor');
        });

        it('should handle unknown project type', async () => {
            // Créer un fichier sans contexte de projet identifiable
            const unknownFilePath = path.join(tempWorkspace, 'unknown.txt');
            const unknownContent = 'This is some unknown content type that should still be processed.';
            fs.writeFileSync(unknownFilePath, unknownContent);

            const testDocument = await vscode.workspace.openTextDocument(unknownFilePath);
            const testEditor = await vscode.window.showTextDocument(testDocument);

            // Sélectionner tout le contenu
            const fullRange = new vscode.Range(0, 0, testDocument.lineCount - 1, testDocument.lineAt(testDocument.lineCount - 1).text.length);
            testEditor.selection = new vscode.Selection(fullRange.start, fullRange.end);

            const result = await granularizer.granularizeActiveSelection();

            // Doit quand même produire une granularisation
            expect(result).to.be.an('array');
            expect(result.length).to.be.greaterThan(0);

            // Doit avoir tous les 8 niveaux même pour contenu inconnu
            const levels = [...new Set(result.map(task => task.level))];
            expect(levels.length).to.equal(8);

            // Doit utiliser ContentProcessor par défaut
            expect(result.some(task => 
                task.title.includes('Content') || 
                task.description.includes('contenu')
            )).to.be.true;

            await vscode.commands.executeCommand('workbench.action.closeActiveEditor');
        });
    });

    describe('Performance and Scalability', () => {
        it('should handle large selection efficiently', async function() {
            this.timeout(60000); // 1 minute timeout for performance test

            // Créer un gros fichier avec beaucoup de contenu
            const largeFilePath = path.join(tempWorkspace, 'large.ts');
            let largeContent = '// Large TypeScript file for performance testing\n';
            
            // Générer 1000 lignes de code TypeScript
            for (let i = 0; i < 1000; i++) {
                largeContent += `interface User${i} {\n`;
                largeContent += `    id: string;\n`;
                largeContent += `    name: string;\n`;
                largeContent += `    value${i}: number;\n`;
                largeContent += `}\n\n`;
                
                largeContent += `class Service${i} {\n`;
                largeContent += `    process(user: User${i}): User${i} {\n`;
                largeContent += `        return { ...user, value${i}: user.value${i} * 2 };\n`;
                largeContent += `    }\n`;
                largeContent += `}\n\n`;
            }

            fs.writeFileSync(largeFilePath, largeContent);

            const testDocument = await vscode.workspace.openTextDocument(largeFilePath);
            const testEditor = await vscode.window.showTextDocument(testDocument);

            // Sélectionner une portion significative
            const selectionStart = testDocument.positionAt(1000); // Début à partir de 1000 caractères
            const selectionEnd = testDocument.positionAt(5000);   // Sélection de 4000 caractères
            testEditor.selection = new vscode.Selection(selectionStart, selectionEnd);

            const startTime = Date.now();
            const result = await granularizer.granularizeActiveSelection();
            const endTime = Date.now();

            const executionTime = endTime - startTime;
            console.log(`⏱️ Temps d'exécution pour grande sélection: ${executionTime}ms`);

            // Vérifier que l'exécution reste dans des limites raisonnables (< 30 secondes)
            expect(executionTime).to.be.lessThan(30000);

            // Vérifier que la granularisation fonctionne toujours
            expect(result).to.be.an('array');
            expect(result.length).to.be.greaterThan(0);

            // Vérifier l'intégrité de la structure hiérarchique
            const levels = [...new Set(result.map(task => task.level))].sort();
            expect(levels).to.deep.equal([1, 2, 3, 4, 5, 6, 7, 8]);

            await vscode.commands.executeCommand('workbench.action.closeActiveEditor');
        });
    });

    describe('Report Quality Validation', () => {
        it('should generate detailed and actionable reports', async () => {
            // Setup un cas de test complexe
            const complexFilePath = path.join(tempWorkspace, 'complex.ts');
            const complexContent = `
import { EventEmitter } from 'events';
import { promises as fs } from 'fs';

interface DataProcessor {
    process<T>(data: T): Promise<T>;
}

class AsyncDataProcessor extends EventEmitter implements DataProcessor {
    private cache = new Map<string, any>();
    
    constructor(private options: ProcessorOptions) {
        super();
    }
    
    async process<T>(data: T): Promise<T> {
        const key = this.generateKey(data);
        
        if (this.cache.has(key)) {
            this.emit('cache-hit', key);
            return this.cache.get(key);
        }
        
        const result = await this.performProcessing(data);
        this.cache.set(key, result);
        this.emit('processed', result);
        
        return result;
    }
    
    private generateKey<T>(data: T): string {
        return JSON.stringify(data);
    }
    
    private async performProcessing<T>(data: T): Promise<T> {
        // Simulation du traitement
        await new Promise(resolve => setTimeout(resolve, 100));
        return { ...data as any, processed: true };
    }
}

interface ProcessorOptions {
    maxCacheSize: number;
    timeout: number;
}
`;

            fs.writeFileSync(complexFilePath, complexContent);

            // Créer un package.json avec des scripts de build/test détaillés
            const packageJsonPath = path.join(tempWorkspace, 'package.json');
            const packageJson = {
                name: 'complex-project',
                scripts: {
                    build: 'tsc --build',
                    'build:watch': 'tsc --build --watch',
                    test: 'jest --coverage',
                    'test:unit': 'jest --testMatch="**/*.unit.test.ts"',
                    'test:integration': 'jest --testMatch="**/*.integration.test.ts"',
                    lint: 'eslint src/**/*.ts',
                    'lint:fix': 'eslint src/**/*.ts --fix'
                }
            };
            fs.writeFileSync(packageJsonPath, JSON.stringify(packageJson, null, 2));

            const testDocument = await vscode.workspace.openTextDocument(complexFilePath);
            const testEditor = await vscode.window.showTextDocument(testDocument);

            // Sélectionner la classe complète
            const classStart = testDocument.getText().indexOf('class AsyncDataProcessor');
            const classEnd = testDocument.getText().lastIndexOf('}') + 1;
            
            const startPos = testDocument.positionAt(classStart);
            const endPos = testDocument.positionAt(classEnd);
            testEditor.selection = new vscode.Selection(startPos, endPos);

            const result = await granularizer.granularizeActiveSelection();

            // Vérifier que le rapport contient des informations détaillées
            const reportPath = path.join(tempWorkspace, 'GRANULARIZATION_REPORT.md');
            expect(fs.existsSync(reportPath)).to.be.true;

            const reportContent = fs.readFileSync(reportPath, 'utf8');

            // Vérifier la présence de sections essentielles
            expect(reportContent).to.include('# Rapport de Granularisation Ultra-Précise');
            expect(reportContent).to.include('## 📊 Statistiques');
            expect(reportContent).to.include('## 🏗️ Structure Hiérarchique');
            expect(reportContent).to.include('## ⚡ Tâches par Niveau');
            expect(reportContent).to.include('## 🎯 Instructions d\'Exécution');
            expect(reportContent).to.include('## ✅ Critères de Validation');

            // Vérifier la détection de la stack technologique
            expect(reportContent).to.include('JavaScript, TypeScript, Node.js');

            // Vérifier la détection des scripts de build
            expect(reportContent).to.include('tsc --build');
            expect(reportContent).to.include('jest');

            // Vérifier la structure hiérarchique dans le rapport
            for (let level = 1; level <= 8; level++) {
                expect(reportContent).to.include(`Niveau ${level}`);
            }

            // Vérifier que les tâches ont des durées estimées réalistes
            const totalDuration = result.reduce((sum, task) => sum + task.estimatedDuration, 0);
            expect(totalDuration).to.be.greaterThan(0);
            expect(totalDuration).to.be.lessThan(1440); // Moins de 24h

            console.log(`📊 Rapport généré avec ${result.length} tâches, durée totale estimée: ${totalDuration} minutes`);

            await vscode.commands.executeCommand('workbench.action.closeActiveEditor');
        });
    });
});
