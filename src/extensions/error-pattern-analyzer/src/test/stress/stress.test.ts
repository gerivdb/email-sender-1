import { expect } from 'chai';
import { SelectionGranularizer, AtomicTask } from '../../selectionGranularizer';
import * as vscode from 'vscode';
import * as fs from 'fs';
import * as path from 'path';

/**
 * Tests de stress pour vérifier la robustesse et les performances
 * à 100% de réussite dans toutes les conditions
 */
describe('Stress Tests - 100% Success Rate', function() {
    this.timeout(120000); // 2 minutes timeout pour les tests de stress

    let granularizer: SelectionGranularizer;
    let stressWorkspace: string;

    before(() => {
        granularizer = new SelectionGranularizer({} as any);
        stressWorkspace = path.join(__dirname, '../../stress-workspace');
        
        if (!fs.existsSync(stressWorkspace)) {
            fs.mkdirSync(stressWorkspace, { recursive: true });
        }
    });

    after(() => {
        if (fs.existsSync(stressWorkspace)) {
            fs.rmSync(stressWorkspace, { recursive: true, force: true });
        }
    });

    describe('High Volume Processing', () => {
        it('should handle 100 consecutive granularizations without failure', async function() {
            this.timeout(300000); // 5 minutes pour ce test intensif

            const testFiles = [];
            const results = [];
            let successCount = 0;
            let failureCount = 0;

            // Créer 100 fichiers de test différents
            for (let i = 0; i < 100; i++) {
                const filePath = path.join(stressWorkspace, `test${i}.ts`);
                const content = generateTestContent(i);
                fs.writeFileSync(filePath, content);
                testFiles.push(filePath);
            }

            // Créer package.json pour la détection de projet
            const packageJsonPath = path.join(stressWorkspace, 'package.json');
            fs.writeFileSync(packageJsonPath, JSON.stringify({
                name: 'stress-test-project',
                scripts: { build: 'tsc', test: 'jest' }
            }));

            console.log('🏃‍♂️ Démarrage du test de stress: 100 granularisations...');

            // Traiter chaque fichier
            for (let i = 0; i < testFiles.length; i++) {
                const filePath = testFiles[i];
                
                try {
                    const testDocument = await vscode.workspace.openTextDocument(filePath);
                    const testEditor = await vscode.window.showTextDocument(testDocument);

                    // Sélectionner une portion aléatoire du contenu
                    const content = testDocument.getText();
                    const startPos = Math.floor(content.length * 0.1);
                    const endPos = Math.floor(content.length * 0.9);
                    
                    const selection = new vscode.Selection(
                        testDocument.positionAt(startPos),
                        testDocument.positionAt(endPos)
                    );
                    testEditor.selection = selection;

                    const startTime = Date.now();
                    const result = await granularizer.granularizeActiveSelection();
                    const endTime = Date.now();

                    // Validation de la structure
                    validateTaskStructure(result);
                    
                    results.push({
                        fileIndex: i,
                        taskCount: result.length,
                        executionTime: endTime - startTime,
                        success: true
                    });
                    
                    successCount++;
                    
                    if (i % 10 === 0) {
                        console.log(`✅ ${i + 1}/100 granularisations complétées (${successCount} succès, ${failureCount} échecs)`);
                    }

                    await vscode.commands.executeCommand('workbench.action.closeActiveEditor');
                    
                } catch (error) {
                    failureCount++;
                    console.error(`❌ Échec pour fichier ${i}: ${error.message}`);
                    
                    results.push({
                        fileIndex: i,
                        taskCount: 0,
                        executionTime: 0,
                        success: false,
                        error: error.message
                    });
                }
            }

            // Calcul des statistiques
            const successfulResults = results.filter(r => r.success);
            const avgExecutionTime = successfulResults.reduce((sum, r) => sum + r.executionTime, 0) / successfulResults.length;
            const avgTaskCount = successfulResults.reduce((sum, r) => sum + r.taskCount, 0) / successfulResults.length;
            const maxExecutionTime = Math.max(...successfulResults.map(r => r.executionTime));
            const minExecutionTime = Math.min(...successfulResults.map(r => r.executionTime));

            console.log(`📊 Statistiques finales:`);
            console.log(`   Succès: ${successCount}/100 (${(successCount/100*100).toFixed(1)}%)`);
            console.log(`   Échecs: ${failureCount}/100 (${(failureCount/100*100).toFixed(1)}%)`);
            console.log(`   Temps moyen: ${avgExecutionTime.toFixed(0)}ms`);
            console.log(`   Temps min/max: ${minExecutionTime}ms / ${maxExecutionTime}ms`);
            console.log(`   Tâches moyennes: ${avgTaskCount.toFixed(1)}`);

            // Exigence: 100% de réussite
            expect(successCount).to.equal(100, `Échec: seulement ${successCount}/100 granularisations réussies`);
            expect(failureCount).to.equal(0, 'Aucun échec n\'est acceptable');
            
            // Vérifications de performance
            expect(avgExecutionTime).to.be.lessThan(10000, 'Temps d\'exécution moyen trop élevé');
            expect(maxExecutionTime).to.be.lessThan(30000, 'Temps d\'exécution maximum trop élevé');
            expect(avgTaskCount).to.be.greaterThan(8, 'Nombre de tâches moyen insuffisant');
        });

        function generateTestContent(index: number): string {
            const templates = [
                // Template 1: Interface complexe
                `interface Entity${index} {
    id: string;
    name: string;
    metadata: Record<string, any>;
    createdAt: Date;
    updatedAt: Date;
}

class EntityManager${index} {
    private entities: Map<string, Entity${index}> = new Map();
    
    async create(data: Partial<Entity${index}>): Promise<Entity${index}> {
        const entity: Entity${index} = {
            id: generateId(),
            name: data.name || '',
            metadata: data.metadata || {},
            createdAt: new Date(),
            updatedAt: new Date()
        };
        this.entities.set(entity.id, entity);
        return entity;
    }
}`,

                // Template 2: Service avec dépendances
                `import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';

@Injectable()
export class DataService${index} {
    constructor(private http: HttpClient) {}
    
    getData(id: string): Observable<any> {
        return this.http.get(\`/api/data/\${id}\`);
    }
    
    postData(data: any): Observable<any> {
        return this.http.post('/api/data', data);
    }
}`,

                // Template 3: Utilitaires et helpers
                `export namespace Utils${index} {
    export function formatDate(date: Date): string {
        return date.toISOString().split('T')[0];
    }
    
    export function validateEmail(email: string): boolean {
        const regex = /^[^\\s@]+@[^\\s@]+\\.[^\\s@]+$/;
        return regex.test(email);
    }
    
    export class Logger {
        static info(message: string): void {
            console.log(\`[INFO] \${new Date().toISOString()}: \${message}\`);
        }
        
        static error(message: string, error?: Error): void {
            console.error(\`[ERROR] \${new Date().toISOString()}: \${message}\`, error);
        }
    }
}`,

                // Template 4: Composant React
                `import React, { useState, useEffect } from 'react';

interface Props${index} {
    title: string;
    onSave: (data: any) => void;
}

export const Component${index}: React.FC<Props${index}> = ({ title, onSave }) => {
    const [data, setData] = useState<any>(null);
    const [loading, setLoading] = useState(false);
    
    useEffect(() => {
        loadData();
    }, []);
    
    const loadData = async () => {
        setLoading(true);
        try {
            const response = await fetch('/api/data');
            const result = await response.json();
            setData(result);
        } finally {
            setLoading(false);
        }
    };
    
    return (
        <div>
            <h1>{title}</h1>
            {loading ? <div>Loading...</div> : <div>{JSON.stringify(data)}</div>}
        </div>
    );
};`
            ];

            return templates[index % templates.length];
        }

        function validateTaskStructure(tasks: AtomicTask[]): void {
            expect(tasks).to.be.an('array');
            expect(tasks.length).to.be.greaterThan(0);

            // Vérifier les 8 niveaux hiérarchiques
            const levels = [...new Set(tasks.map(t => t.level))].sort();
            expect(levels).to.deep.equal([1, 2, 3, 4, 5, 6, 7, 8]);

            // Vérifier l'intégrité des relations parent-enfant
            tasks.forEach(task => {
                if (task.parent) {
                    const parent = tasks.find(t => t.id === task.parent);
                    expect(parent).to.exist;
                    expect(parent!.level).to.be.lessThan(task.level);
                    expect(parent!.children).to.include(task.id);
                }
            });

            // Vérifier que chaque tâche a les propriétés requises
            tasks.forEach(task => {
                expect(task.id).to.be.a('string');
                expect(task.title).to.be.a('string');
                expect(task.level).to.be.a('number').within(1, 8);
                expect(task.description).to.be.a('string');
                expect(task.estimatedDuration).to.be.a('number').greaterThan(0);
                expect(['ATOMIQUE', 'COMPOSEE', 'COMPLEXE']).to.include(task.complexity);
            });
        }
    });

    describe('Memory and Resource Management', () => {
        it('should maintain stable memory usage during extended operation', async function() {
            this.timeout(180000); // 3 minutes

            const iterations = 50;
            const memoryUsages: number[] = [];
            
            console.log('🧠 Test de gestion mémoire: 50 itérations...');

            for (let i = 0; i < iterations; i++) {
                // Créer un fichier temporaire
                const filePath = path.join(stressWorkspace, `memory-test-${i}.ts`);
                const content = generateLargeContent(i);
                fs.writeFileSync(filePath, content);

                const testDocument = await vscode.workspace.openTextDocument(filePath);
                const testEditor = await vscode.window.showTextDocument(testDocument);

                // Sélection complète
                const fullRange = new vscode.Range(0, 0, testDocument.lineCount - 1, testDocument.lineAt(testDocument.lineCount - 1).text.length);
                testEditor.selection = new vscode.Selection(fullRange.start, fullRange.end);

                // Mesurer l'usage mémoire avant
                const memBefore = process.memoryUsage().heapUsed;

                try {
                    await granularizer.granularizeActiveSelection();
                } catch (error) {
                    console.error(`Erreur à l'itération ${i}: ${error.message}`);
                    throw error;
                }

                // Mesurer l'usage mémoire après
                const memAfter = process.memoryUsage().heapUsed;
                memoryUsages.push(memAfter);

                // Forcer garbage collection si disponible
                if (global.gc) {
                    global.gc();
                }

                await vscode.commands.executeCommand('workbench.action.closeActiveEditor');
                fs.unlinkSync(filePath);

                if (i % 10 === 0) {
                    const memMB = (memAfter / 1024 / 1024).toFixed(1);
                    console.log(`🔄 Itération ${i + 1}/${iterations}, Mémoire: ${memMB}MB`);
                }
            }

            // Analyser l'évolution de la mémoire
            const firstQuarter = memoryUsages.slice(0, Math.floor(iterations / 4));
            const lastQuarter = memoryUsages.slice(-Math.floor(iterations / 4));
            
            const avgFirst = firstQuarter.reduce((sum, mem) => sum + mem, 0) / firstQuarter.length;
            const avgLast = lastQuarter.reduce((sum, mem) => sum + mem, 0) / lastQuarter.length;
            
            const memoryGrowth = ((avgLast - avgFirst) / avgFirst) * 100;
            
            console.log(`📈 Croissance mémoire: ${memoryGrowth.toFixed(1)}%`);
            console.log(`💾 Mémoire moyenne début: ${(avgFirst / 1024 / 1024).toFixed(1)}MB`);
            console.log(`💾 Mémoire moyenne fin: ${(avgLast / 1024 / 1024).toFixed(1)}MB`);

            // Vérifier que la croissance mémoire reste raisonnable (< 50%)
            expect(memoryGrowth).to.be.lessThan(50, 'Croissance mémoire excessive détectée');
        });

        function generateLargeContent(index: number): string {
            let content = `// Large content file ${index}\n`;
            
            // Générer beaucoup de contenu pour stresser la mémoire
            for (let i = 0; i < 200; i++) {
                content += `
export interface LargeInterface${index}_${i} {
    property${i}_1: string;
    property${i}_2: number;
    property${i}_3: boolean;
    property${i}_4: Date;
    property${i}_5: any[];
    property${i}_6: Record<string, any>;
}

export class LargeClass${index}_${i} {
    private field${i}_1: string;
    private field${i}_2: number;
    
    constructor(data: LargeInterface${index}_${i}) {
        this.field${i}_1 = data.property${i}_1;
        this.field${i}_2 = data.property${i}_2;
    }
    
    public method${i}_1(): void {
        console.log('Method ${i}_1 called');
    }
    
    public method${i}_2(): string {
        return this.field${i}_1;
    }
    
    public async method${i}_3(): Promise<number> {
        return new Promise(resolve => {
            setTimeout(() => resolve(this.field${i}_2), 100);
        });
    }
}
`;
            }
            
            return content;
        }
    });

    describe('Concurrent Operations', () => {
        it('should handle multiple simultaneous granularizations', async function() {
            this.timeout(180000); // 3 minutes

            const concurrentCount = 10;
            const promises: Promise<AtomicTask[]>[] = [];
            
            console.log(`⚡ Test de concurrence: ${concurrentCount} granularisations simultanées...`);

            // Créer plusieurs fichiers pour les opérations concurrentes
            const testFiles = [];
            for (let i = 0; i < concurrentCount; i++) {
                const filePath = path.join(stressWorkspace, `concurrent-${i}.ts`);
                const content = generateConcurrentTestContent(i);
                fs.writeFileSync(filePath, content);
                testFiles.push(filePath);
            }

            // Lancer toutes les granularisations en parallèle
            for (let i = 0; i < concurrentCount; i++) {
                const promise = (async (index: number) => {
                    const testDocument = await vscode.workspace.openTextDocument(testFiles[index]);
                    const testEditor = await vscode.window.showTextDocument(testDocument);

                    const content = testDocument.getText();
                    const midPoint = Math.floor(content.length / 2);
                    const selection = new vscode.Selection(
                        testDocument.positionAt(0),
                        testDocument.positionAt(midPoint)
                    );
                    testEditor.selection = selection;

                    const result = await granularizer.granularizeActiveSelection();
                    await vscode.commands.executeCommand('workbench.action.closeActiveEditor');
                    
                    return result;
                })(i);

                promises.push(promise);
            }

            // Attendre que toutes les opérations se terminent
            const results = await Promise.allSettled(promises);

            // Vérifier que toutes les opérations ont réussi
            const successful = results.filter(r => r.status === 'fulfilled');
            const failed = results.filter(r => r.status === 'rejected');

            console.log(`✅ Succès: ${successful.length}/${concurrentCount}`);
            console.log(`❌ Échecs: ${failed.length}/${concurrentCount}`);

            if (failed.length > 0) {
                failed.forEach((failure, index) => {
                    console.error(`Échec ${index}: ${(failure as PromiseRejectedResult).reason}`);
                });
            }

            // Exigence: 100% de réussite même en concurrence
            expect(successful.length).to.equal(concurrentCount, 'Toutes les opérations concurrentes doivent réussir');
            expect(failed.length).to.equal(0, 'Aucun échec n\'est acceptable en concurrence');

            // Vérifier la qualité de chaque résultat
            successful.forEach((result, index) => {
                const tasks = (result as PromiseFulfilledResult<AtomicTask[]>).value;
                expect(tasks).to.be.an('array');
                expect(tasks.length).to.be.greaterThan(0);
                
                const levels = [...new Set(tasks.map(t => t.level))];
                expect(levels.length).to.equal(8, `Résultat concurrent ${index} doit avoir 8 niveaux`);
            });

            // Nettoyer les fichiers
            testFiles.forEach(file => fs.unlinkSync(file));
        });

        function generateConcurrentTestContent(index: number): string {
            return `
// Concurrent test content ${index}
import { EventEmitter } from 'events';

export class ConcurrentProcessor${index} extends EventEmitter {
    private data: Map<string, any> = new Map();
    private processing = false;
    
    constructor(private config: ProcessorConfig${index}) {
        super();
        this.setupHandlers();
    }
    
    private setupHandlers(): void {
        this.on('start', () => {
            this.processing = true;
        });
        
        this.on('complete', () => {
            this.processing = false;
        });
    }
    
    async process(input: ProcessorInput${index}): Promise<ProcessorOutput${index}> {
        if (this.processing) {
            throw new Error('Already processing');
        }
        
        this.emit('start');
        
        try {
            const result = await this.performProcessing(input);
            this.emit('complete', result);
            return result;
        } catch (error) {
            this.emit('error', error);
            throw error;
        }
    }
    
    private async performProcessing(input: ProcessorInput${index}): Promise<ProcessorOutput${index}> {
        // Simulation du traitement
        await new Promise(resolve => setTimeout(resolve, Math.random() * 100));
        
        return {
            id: input.id,
            processed: true,
            timestamp: new Date(),
            data: { ...input.data, processed: true }
        };
    }
}

export interface ProcessorConfig${index} {
    timeout: number;
    retries: number;
    batchSize: number;
}

export interface ProcessorInput${index} {
    id: string;
    data: Record<string, any>;
}

export interface ProcessorOutput${index} {
    id: string;
    processed: boolean;
    timestamp: Date;
    data: Record<string, any>;
}
`;
        }
    });
});
