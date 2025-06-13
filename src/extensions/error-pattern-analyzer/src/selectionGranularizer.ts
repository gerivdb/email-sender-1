import * as vscode from 'vscode';
import * as fs from 'fs';
import * as path from 'path';

/**
 * Interface pour une tâche atomique granularisée
 */
export interface AtomicTask {
    id: string;
    title: string;
    level: number; // 1-8 selon la hiérarchie du prompt
    parent?: string;
    children: string[];
    description: string;
    prerequisites: string[];
    outputs: string[];
    estimatedDuration: number;
    complexity: 'ATOMIQUE' | 'COMPOSEE' | 'COMPLEXE';
    commands: string[];
    validationCriteria: string[];
}

/**
 * Interface pour l'analyse du contexte de l'écosystème
 */
export interface EcosystemContext {
    projectType: string;
    technologyStack: string[];
    architecturePattern: string;
    namingConvention: string;
    buildCommands: string[];
    testCommands: string[];
    existingFiles: string[];
}

/**
 * Classe principale pour la granularisation de sélection
 */
export class SelectionGranularizer {
    private context: vscode.ExtensionContext;
    private outputChannel: vscode.OutputChannel;

    constructor(context: vscode.ExtensionContext) {
        this.context = context;
        this.outputChannel = vscode.window.createOutputChannel('Selection Granularizer');
    }

    /**
     * Point d'entrée principal - granularise la sélection active
     */
    public async granularizeActiveSelection(): Promise<AtomicTask[]> {
        this.outputChannel.show();
        this.outputChannel.appendLine('🎯 Début de la granularisation ultra-précise...');

        // 1. Récupérer la sélection active
        const editor = vscode.window.activeTextEditor;
        if (!editor) {
            throw new Error('❌ Aucun éditeur actif détecté');
        }

        const selection = editor.selection;
        const selectedText = editor.document.getText(selection);
        
        if (!selectedText.trim()) {
            throw new Error('❌ Aucune sélection active dans l\'éditeur');
        }

        this.outputChannel.appendLine(`✅ Sélection récupérée: ${selectedText.length} caractères`);

        // 2. Analyser le contexte de l'écosystème
        const ecosystemContext = await this.analyzeEcosystemContext(editor.document.uri);
        this.outputChannel.appendLine(`🔍 Écosystème détecté: ${ecosystemContext.projectType}`);

        // 3. Granulariser selon les 8 niveaux de hiérarchie
        const atomicTasks = await this.performUltraGranularization(selectedText, ecosystemContext);
        
        this.outputChannel.appendLine(`🏗️ Granularisation terminée: ${atomicTasks.length} tâches atomiques créées`);

        // 4. Valider la cohérence architecturale
        await this.validateArchitecturalCoherence(atomicTasks, ecosystemContext);

        // 5. Générer le rapport final
        await this.generateCompletionReport(atomicTasks, ecosystemContext);

        return atomicTasks;
    }

    /**
     * Analyse automatique du contexte de l'écosystème
     */
    private async analyzeEcosystemContext(documentUri: vscode.Uri): Promise<EcosystemContext> {
        const workspaceFolder = vscode.workspace.getWorkspaceFolder(documentUri);
        if (!workspaceFolder) {
            throw new Error('❌ Workspace folder non détecté');
        }

        const rootPath = workspaceFolder.uri.fsPath;
        const context: EcosystemContext = {
            projectType: 'unknown',
            technologyStack: [],
            architecturePattern: 'unknown',
            namingConvention: 'unknown',
            buildCommands: [],
            testCommands: [],
            existingFiles: []
        };

        // Détecter le type de projet
        const packageJsonPath = path.join(rootPath, 'package.json');
        const goModPath = path.join(rootPath, 'go.mod');
        const requirementsPath = path.join(rootPath, 'requirements.txt');

        if (fs.existsSync(packageJsonPath)) {
            context.projectType = 'Node.js/TypeScript';
            context.technologyStack.push('JavaScript', 'TypeScript', 'Node.js');
            context.buildCommands.push('npm run build', 'npm run compile');
            context.testCommands.push('npm test', 'npm run test:unit');
        } else if (fs.existsSync(goModPath)) {
            context.projectType = 'Go';
            context.technologyStack.push('Go');
            context.buildCommands.push('go build', 'go install');
            context.testCommands.push('go test', 'go test -v');
        } else if (fs.existsSync(requirementsPath)) {
            context.projectType = 'Python';
            context.technologyStack.push('Python');
            context.buildCommands.push('python -m pip install -r requirements.txt');
            context.testCommands.push('python -m pytest', 'python -m unittest');
        }

        // Détecter les patterns architecturaux
        await this.detectArchitecturalPatterns(rootPath, context);

        // Analyser les conventions de nommage
        await this.detectNamingConventions(rootPath, context);

        return context;
    }

    /**
     * Détecte les patterns architecturaux automatiquement
     */
    private async detectArchitecturalPatterns(rootPath: string, context: EcosystemContext): Promise<void> {
        const files = await vscode.workspace.findFiles('**/*.{ts,js,go,py}', '**/node_modules/**', 100);
        
        let interfaceCount = 0;
        let dependencyInjectionCount = 0;
        let singleResponsibilityCount = 0;

        for (const file of files) {
            const content = fs.readFileSync(file.fsPath, 'utf8');
            
            // Détecter SOLID
            if (content.includes('interface') && content.includes('{')) {
                interfaceCount++;
            }
            if (content.includes('inject') || content.includes('dependency')) {
                dependencyInjectionCount++;
            }
            if (content.split('\n').length < 50) { // Fichiers courts = Single Responsibility
                singleResponsibilityCount++;
            }
        }

        if (interfaceCount > 5 && dependencyInjectionCount > 2) {
            context.architecturePattern = 'SOLID + Dependency Injection';
        } else if (interfaceCount > 3) {
            context.architecturePattern = 'Interface-based';
        } else {
            context.architecturePattern = 'Procedural';
        }
    }

    /**
     * Détecte les conventions de nommage automatiquement
     */
    private async detectNamingConventions(rootPath: string, context: EcosystemContext): Promise<void> {
        const files = await vscode.workspace.findFiles('**/*.{ts,js,go,py}', '**/node_modules/**', 50);
        
        let camelCaseCount = 0;
        let pascalCaseCount = 0;
        let snakeCaseCount = 0;

        for (const file of files) {
            const fileName = path.basename(file.fsPath, path.extname(file.fsPath));
            
            if (/^[a-z][a-zA-Z0-9]*$/.test(fileName)) {
                camelCaseCount++;
            } else if (/^[A-Z][a-zA-Z0-9]*$/.test(fileName)) {
                pascalCaseCount++;
            } else if (/_/.test(fileName)) {
                snakeCaseCount++;
            }
        }

        if (camelCaseCount > pascalCaseCount && camelCaseCount > snakeCaseCount) {
            context.namingConvention = 'camelCase';
        } else if (pascalCaseCount > snakeCaseCount) {
            context.namingConvention = 'PascalCase';
        } else {
            context.namingConvention = 'snake_case';
        }
    }

    /**
     * Granularisation ultra-précise selon les 8 niveaux de hiérarchie
     */
    private async performUltraGranularization(selectedText: string, context: EcosystemContext): Promise<AtomicTask[]> {
        const tasks: AtomicTask[] = [];
        let taskIdCounter = 1;

        // NIVEAU 1: Architecture principale
        const level1Task: AtomicTask = {
            id: `task-${taskIdCounter++}`,
            title: `🏗️ [${context.projectType}] Architecture principale pour sélection`,
            level: 1,
            children: [],
            description: `Implémentation architecturale pour traiter la sélection: "${selectedText.substring(0, 100)}..."`,
            prerequisites: [`Écosystème ${context.projectType} configuré`, 'Build système fonctionnel'],
            outputs: ['Structure architecturale complète', 'Points d\'intégration définis'],
            estimatedDuration: 240, // minutes
            complexity: 'COMPLEXE',
            commands: context.buildCommands,
            validationCriteria: ['Build sans erreurs', 'Architecture cohérente avec existant']
        };
        tasks.push(level1Task);

        // NIVEAU 2: Sous-systèmes spécialisés
        const level2Tasks = await this.createLevel2Tasks(selectedText, context, level1Task.id, taskIdCounter);
        tasks.push(...level2Tasks);
        taskIdCounter += level2Tasks.length;
        level1Task.children = level2Tasks.map(t => t.id);

        // NIVEAU 3-8: Granularisation récursive
        for (const level2Task of level2Tasks) {
            const subTasks = await this.createRecursiveSubTasks(selectedText, context, level2Task, 3, 8, taskIdCounter);
            tasks.push(...subTasks);
            taskIdCounter += subTasks.length;
        }

        return tasks;
    }

    /**
     * Crée les tâches de niveau 2 (sous-systèmes spécialisés)
     */
    private async createLevel2Tasks(selectedText: string, context: EcosystemContext, parentId: string, startId: number): Promise<AtomicTask[]> {
        const tasks: AtomicTask[] = [];
        
        // Analyser la sélection pour identifier les composants nécessaires
        const components = this.identifyRequiredComponents(selectedText);
        
        components.forEach((component, index) => {
            const task: AtomicTask = {
                id: `task-${startId + index}`,
                title: `🔧 [${component.type}] ${component.name}`,
                level: 2,
                parent: parentId,
                children: [],
                description: `Sous-système spécialisé pour ${component.functionality}`,
                prerequisites: [`Architecture principale validée`],
                outputs: [`Module ${component.name} fonctionnel`, 'API interface définie'],
                estimatedDuration: 120,
                complexity: 'COMPOSEE',
                commands: [`Implémenter ${component.name}`, `Tester ${component.name}`],
                validationCriteria: [`Module ${component.name} opérationnel`, 'Tests unitaires passent']
            };
            tasks.push(task);
        });

        return tasks;
    }

    /**
     * Identifie les composants requis basés sur la sélection
     */
    private identifyRequiredComponents(selectedText: string): Array<{type: string, name: string, functionality: string}> {
        const components = [];
        
        // Analyse basique du contenu pour identifier les besoins
        if (selectedText.includes('function') || selectedText.includes('def') || selectedText.includes('func')) {
            components.push({
                type: 'Function',
                name: 'FunctionProcessor',
                functionality: 'traitement des fonctions identifiées'
            });
        }
        
        if (selectedText.includes('class') || selectedText.includes('interface') || selectedText.includes('type')) {
            components.push({
                type: 'Type',
                name: 'TypeProcessor',
                functionality: 'gestion des types et interfaces'
            });
        }
        
        if (selectedText.includes('import') || selectedText.includes('require') || selectedText.includes('from')) {
            components.push({
                type: 'Dependency',
                name: 'DependencyManager',
                functionality: 'résolution des dépendances'
            });
        }

        // Composant par défaut si aucun pattern spécifique détecté
        if (components.length === 0) {
            components.push({
                type: 'Content',
                name: 'ContentProcessor',
                functionality: 'traitement générique du contenu sélectionné'
            });
        }

        return components;
    }

    /**
     * Création récursive des sous-tâches pour les niveaux 3-8
     */
    private async createRecursiveSubTasks(
        selectedText: string, 
        context: EcosystemContext, 
        parentTask: AtomicTask, 
        currentLevel: number, 
        maxLevel: number, 
        startId: number
    ): Promise<AtomicTask[]> {
        if (currentLevel > maxLevel) {
            return [];
        }

        const tasks: AtomicTask[] = [];
        const subTaskCount = Math.max(1, Math.floor(4 - currentLevel / 2)); // Diminue avec la profondeur
        
        for (let i = 0; i < subTaskCount; i++) {
            const task: AtomicTask = {
                id: `task-${startId + tasks.length}`,
                title: this.generateLevelSpecificTitle(currentLevel, parentTask.title, i),
                level: currentLevel,
                parent: parentTask.id,
                children: [],
                description: this.generateLevelSpecificDescription(currentLevel, selectedText),
                prerequisites: [parentTask.title],
                outputs: this.generateLevelSpecificOutputs(currentLevel),
                estimatedDuration: Math.max(5, 60 / Math.pow(2, currentLevel - 1)),
                complexity: currentLevel <= 4 ? 'COMPOSEE' : 'ATOMIQUE',
                commands: this.generateLevelSpecificCommands(currentLevel, context),
                validationCriteria: this.generateLevelSpecificValidation(currentLevel)
            };
            
            tasks.push(task);
            parentTask.children.push(task.id);

            // Récursion pour le niveau suivant
            if (currentLevel < maxLevel) {
                const subTasks = await this.createRecursiveSubTasks(
                    selectedText, 
                    context, 
                    task, 
                    currentLevel + 1, 
                    maxLevel, 
                    startId + tasks.length + 1
                );
                tasks.push(...subTasks);
            }
        }

        return tasks;
    }

    /**
     * Génère un titre spécifique selon le niveau
     */
    private generateLevelSpecificTitle(level: number, parentTitle: string, index: number): string {
        const icons = ['⚙️', '📋', '🔍', '🎯', '🔬', '⚡'];
        const icon = icons[level - 3] || '🔸';
        
        const levelNames = [
            'Méthode', 'Tâche atomique', 'Élément granulaire', 
            'Instruction exécutable', 'Micro-opération', 'Étape atomique'
        ];
        const levelName = levelNames[level - 3] || 'Sous-tâche';
        
        return `${icon} [NIVEAU ${level}] ${levelName} ${index + 1} - ${parentTitle.split(' ')[0]}`;
    }

    /**
     * Génère une description spécifique selon le niveau
     */
    private generateLevelSpecificDescription(level: number, selectedText: string): string {
        const snippet = selectedText.substring(0, 50).replace(/\n/g, ' ').trim();
        
        switch (level) {
            case 3: return `Implémentation de méthode pour traitement de: "${snippet}..."`;
            case 4: return `Tâche atomique d'exécution pour: "${snippet}..."`;
            case 5: return `Élément granulaire de traitement pour: "${snippet}..."`;
            case 6: return `Instruction exécutable directe pour: "${snippet}..."`;
            case 7: return `Micro-opération unitaire pour: "${snippet}..."`;
            case 8: return `Étape atomique indivisible pour: "${snippet}..."`;
            default: return `Traitement spécialisé pour: "${snippet}..."`;
        }
    }

    /**
     * Génère les outputs spécifiques selon le niveau
     */
    private generateLevelSpecificOutputs(level: number): string[] {
        switch (level) {
            case 3: return ['Méthode implémentée', 'Tests unitaires méthode'];
            case 4: return ['Tâche exécutée', 'Résultat validé'];
            case 5: return ['Élément traité', 'Status confirmé'];
            case 6: return ['Instruction exécutée', 'Output capturé'];
            case 7: return ['Opération complétée', 'State updated'];
            case 8: return ['Étape finalisée', 'Commit atomique'];
            default: return ['Sortie générée', 'Validation passée'];
        }
    }

    /**
     * Génère les commandes spécifiques selon le niveau
     */
    private generateLevelSpecificCommands(level: number, context: EcosystemContext): string[] {
        const baseCommands = [];
        
        if (level <= 4) {
            baseCommands.push(...context.buildCommands);
        }
        if (level >= 6) {
            baseCommands.push(...context.testCommands);
        }
        
        return baseCommands.length > 0 ? baseCommands : ['Exécution manuelle requise'];
    }

    /**
     * Génère les critères de validation spécifiques selon le niveau
     */
    private generateLevelSpecificValidation(level: number): string[] {
        switch (level) {
            case 3: return ['Méthode compile sans erreurs', 'Tests unitaires passent'];
            case 4: return ['Tâche exécutée avec succès', 'Output conforme'];
            case 5: return ['Élément traité correctement', 'Pas d\'effets de bord'];
            case 6: return ['Instruction exécutée', 'Résultat attendu obtenu'];
            case 7: return ['Opération atomique réussie', 'State cohérent'];
            case 8: return ['Étape indivisible complétée', 'Invariants préservés'];
            default: return ['Validation générique passée'];
        }
    }

    /**
     * Valide la cohérence architecturale
     */
    private async validateArchitecturalCoherence(tasks: AtomicTask[], context: EcosystemContext): Promise<void> {
        this.outputChannel.appendLine('🔍 Validation de la cohérence architecturale...');
        
        // Vérifier la hiérarchie
        const levels = new Set(tasks.map(t => t.level));
        for (let level = 1; level <= 8; level++) {
            if (!levels.has(level)) {
                throw new Error(`❌ Niveau hiérarchique ${level} manquant`);
            }
        }

        // Vérifier les dépendances
        for (const task of tasks) {
            if (task.parent) {
                const parent = tasks.find(t => t.id === task.parent);
                if (!parent) {
                    throw new Error(`❌ Parent ${task.parent} introuvable pour tâche ${task.id}`);
                }
                if (parent.level >= task.level) {
                    throw new Error(`❌ Hiérarchie incorrecte: parent ${parent.level} >= enfant ${task.level}`);
                }
            }
        }

        this.outputChannel.appendLine('✅ Cohérence architecturale validée');
    }

    /**
     * Génère le rapport final de completion
     */
    private async generateCompletionReport(tasks: AtomicTask[], context: EcosystemContext): Promise<void> {
        const reportPath = path.join(vscode.workspace.workspaceFolders![0].uri.fsPath, 'GRANULARIZATION_REPORT.md');
        
        const report = `# Rapport de Granularisation Ultra-Précise

## 📊 Statistiques

- **Tâches totales**: ${tasks.length}
- **Niveaux hiérarchiques**: 8
- **Écosystème détecté**: ${context.projectType}
- **Stack technologique**: ${context.technologyStack.join(', ')}
- **Pattern architectural**: ${context.architecturePattern}
- **Convention de nommage**: ${context.namingConvention}

## 🏗️ Structure Hiérarchique

${this.generateHierarchicalStructure(tasks)}

## ⚡ Tâches par Niveau

${this.generateTasksByLevel(tasks)}

## 🎯 Instructions d'Exécution

${this.generateExecutionInstructions(tasks, context)}

## ✅ Critères de Validation

${this.generateValidationCriteria(tasks)}

---
*Rapport généré automatiquement par Selection Granularizer*
*Date: ${new Date().toISOString()}*
`;

        fs.writeFileSync(reportPath, report, 'utf8');
        this.outputChannel.appendLine(`📄 Rapport généré: ${reportPath}`);
        
        // Ouvrir le rapport dans VS Code
        const doc = await vscode.workspace.openTextDocument(reportPath);
        await vscode.window.showTextDocument(doc);
    }

    /**
     * Génère la structure hiérarchique pour le rapport
     */
    private generateHierarchicalStructure(tasks: AtomicTask[]): string {
        const level1Tasks = tasks.filter(t => t.level === 1);
        return level1Tasks.map(task => this.generateTaskTree(task, tasks, '')).join('\n');
    }

    /**
     * Génère l'arbre des tâches récursivement
     */
    private generateTaskTree(task: AtomicTask, allTasks: AtomicTask[], indent: string): string {
        const children = allTasks.filter(t => t.parent === task.id);
        let result = `${indent}- ${task.title}\n`;
        
        for (const child of children) {
            result += this.generateTaskTree(child, allTasks, indent + '  ');
        }
        
        return result;
    }

    /**
     * Génère la section des tâches par niveau
     */
    private generateTasksByLevel(tasks: AtomicTask[]): string {
        let result = '';
        
        for (let level = 1; level <= 8; level++) {
            const levelTasks = tasks.filter(t => t.level === level);
            if (levelTasks.length > 0) {
                result += `\n### Niveau ${level} (${levelTasks.length} tâches)\n\n`;
                levelTasks.forEach(task => {
                    result += `- **${task.title}**\n`;
                    result += `  - Durée estimée: ${task.estimatedDuration} min\n`;
                    result += `  - Complexité: ${task.complexity}\n`;
                    result += `  - Prérequis: ${task.prerequisites.join(', ')}\n\n`;
                });
            }
        }
        
        return result;
    }

    /**
     * Génère les instructions d'exécution
     */
    private generateExecutionInstructions(tasks: AtomicTask[], context: EcosystemContext): string {
        let result = '\n### Commandes de Build\n\n';
        result += context.buildCommands.map(cmd => `\`\`\`bash\n${cmd}\n\`\`\``).join('\n\n');
        
        result += '\n\n### Commandes de Test\n\n';
        result += context.testCommands.map(cmd => `\`\`\`bash\n${cmd}\n\`\`\``).join('\n\n');
        
        return result;
    }

    /**
     * Génère les critères de validation
     */
    private generateValidationCriteria(tasks: AtomicTask[]): string {
        const allCriteria = new Set<string>();
        tasks.forEach(task => task.validationCriteria.forEach(criteria => allCriteria.add(criteria)));
        
        return Array.from(allCriteria).map(criteria => `- ${criteria}`).join('\n');
    }
}
