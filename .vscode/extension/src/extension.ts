import * as vscode from 'vscode';
import * as https from 'https';
import * as http from 'http';
import { URL } from 'url';

// Utilitaire pour remplacer fetch
function httpRequest(url: string, options: { method?: string; headers?: Record<string, string>; body?: string } = {}): Promise<{ ok: boolean; status: number; json: () => Promise<any>; text: () => Promise<string> }> {
    return new Promise((resolve, reject) => {
        const parsedUrl = new URL(url);
        const client = parsedUrl.protocol === 'https:' ? https : http;
        
        const requestOptions = {
            hostname: parsedUrl.hostname,
            port: parsedUrl.port,
            path: parsedUrl.pathname + parsedUrl.search,
            method: options.method || 'GET',
            headers: {
                'Content-Type': 'application/json',
                ...options.headers
            }
        };

        const req = client.request(requestOptions, (res) => {
            let data = '';
            res.on('data', (chunk) => {
                data += chunk;
            });
            res.on('end', () => {
                resolve({
                    ok: res.statusCode! >= 200 && res.statusCode! < 300,
                    status: res.statusCode!,
                    json: () => Promise.resolve(JSON.parse(data)),
                    text: () => Promise.resolve(data)
                });
            });
        });

        req.on('error', reject);
        
        if (options.body) {
            req.write(options.body);
        }
        req.end();
    });
}
import * as path from 'path';
import * as fs from 'fs';

interface InfrastructureStatus {
    active: boolean;
    autoHealingEnabled: boolean;
    servicesMonitored: number;
    overall: string;
}

interface ServiceStatus {
    status: string;
    health: string;
    last_healthy: string;
}

class SystemHealthIndicator {
    private statusBarItem: vscode.StatusBarItem;
    private outputChannel: vscode.OutputChannel;
    private apiBaseUrl: string;

    constructor(statusBarItem: vscode.StatusBarItem, outputChannel: vscode.OutputChannel, apiBaseUrl: string) {
        this.statusBarItem = statusBarItem;
        this.outputChannel = outputChannel;
        this.apiBaseUrl = apiBaseUrl;
    }

    async updateHealthStatus(): Promise<void> {
        try {
            const health = await this.runQuickDiagnostic();
            
            if (health.healthy) {
                this.statusBarItem.text = "✅ System OK";
                this.statusBarItem.backgroundColor = undefined;
            } else {
                this.statusBarItem.text = "⚠️ Issues Detected";
                this.statusBarItem.backgroundColor = new vscode.ThemeColor('statusBarItem.warningBackground');
            }
            
            this.statusBarItem.tooltip = `System Health: ${health.status}\nServices: ${health.servicesCount}\nLast Check: ${new Date().toLocaleTimeString()}`;
            
        } catch (error) {
            this.statusBarItem.text = "❌ Health Check Failed";
            this.statusBarItem.backgroundColor = new vscode.ThemeColor('statusBarItem.errorBackground');
            this.outputChannel.appendLine(`Health check error: ${error}`);
        }
    }

    private async runQuickDiagnostic(): Promise<{healthy: boolean, status: string, servicesCount: number}> {
        try {
            const response = await httpRequest(`${this.apiBaseUrl}/status/health`);
            if (response.ok) {
                const data = await response.json();
                return {
                    healthy: data.overall === 'healthy',
                    status: data.overall,
                    servicesCount: data.servicesMonitored || 0
                };
            } else {
                return { healthy: false, status: 'api_error', servicesCount: 0 };
            }
        } catch (error) {
            return { healthy: false, status: 'connection_error', servicesCount: 0 };
        }
    }
}

export class SmartEmailSenderExtension {
    private context: vscode.ExtensionContext;
    private statusBarItem: vscode.StatusBarItem;
    private outputChannel: vscode.OutputChannel;
    private apiBaseUrl: string;
    private isInfrastructureRunning: boolean = false;
    private autoStartEnabled: boolean = true;
    private autoHealingEnabled: boolean = false;
    private healthIndicator: SystemHealthIndicator;

    constructor(context: vscode.ExtensionContext) {
        this.context = context;
        this.outputChannel = vscode.window.createOutputChannel('Smart Email Sender');
        
        // Configuration
        const config = vscode.workspace.getConfiguration('smartEmailSender');
        this.autoStartEnabled = config.get('autoStart', true);
        this.autoHealingEnabled = config.get('autoHealing', false);
        const apiPort = config.get('apiPort', 8080);
        this.apiBaseUrl = `http://localhost:${apiPort}`;        // Créer la status bar
        this.statusBarItem = vscode.window.createStatusBarItem(
            vscode.StatusBarAlignment.Left, 
            100
        );
        this.statusBarItem.command = 'smartEmailSender.showStatus';
        this.statusBarItem.show();
        
        // Initialiser le health indicator
        this.healthIndicator = new SystemHealthIndicator(this.statusBarItem, this.outputChannel, this.apiBaseUrl);
        
        this.updateStatusBar('⏳', 'Initializing...', 'yellow');
        
        // Enregistrer les commandes
        this.registerCommands();
        
        // Détecter si on est dans le workspace EMAIL_SENDER_1
        this.detectWorkspace();
    }

    private registerCommands() {        const commands = [
            vscode.commands.registerCommand('smartEmailSender.startStack', () => this.startInfrastructure()),
            vscode.commands.registerCommand('smartEmailSender.stopStack', () => this.stopInfrastructure()),
            vscode.commands.registerCommand('smartEmailSender.restartStack', () => this.restartInfrastructure()),
            vscode.commands.registerCommand('smartEmailSender.showStatus', () => this.showDetailedStatus()),
            vscode.commands.registerCommand('smartEmailSender.enableAutoHealing', () => this.toggleAutoHealing()),
            vscode.commands.registerCommand('smartEmailSender.showLogs', () => this.showLogs()),
            vscode.commands.registerCommand('smartEmailSender.runEmergencyDiagnostic', () => this.runEmergencyDiagnostic())
        ];

        commands.forEach(cmd => this.context.subscriptions.push(cmd));
        this.context.subscriptions.push(this.statusBarItem);
        this.context.subscriptions.push(this.outputChannel);
    }

    private async detectWorkspace() {
        if (!vscode.workspace.workspaceFolders) {
            this.updateStatusBar('❌', 'No workspace', 'red');
            return;
        }

        const workspaceRoot = vscode.workspace.workspaceFolders[0].uri.fsPath;
        const isEmailSenderWorkspace = workspaceRoot.includes('EMAIL_SENDER_1') || 
                                     fs.existsSync(path.join(workspaceRoot, 'cmd', 'infrastructure-api-server'));

        if (isEmailSenderWorkspace) {
            this.logOutput('📁 Smart Email Sender workspace detected');
            this.updateStatusBar('🏠', 'Workspace detected', 'blue');
            
            if (this.autoStartEnabled) {
                this.logOutput('🚀 Auto-start enabled, starting infrastructure...');
                await this.autoStartInfrastructure();
            } else {
                this.updateStatusBar('⚡', 'Ready (auto-start disabled)', 'yellow');
            }
        } else {
            this.updateStatusBar('📁', 'Not Email Sender workspace', 'gray');
        }
    }

    private async autoStartInfrastructure() {
        try {
            // Vérifier si l'API server est déjà en cours d'exécution
            const isRunning = await this.checkApiServerStatus();
            if (isRunning) {
                this.logOutput('✅ Infrastructure already running');
                this.isInfrastructureRunning = true;
                await this.updateStatusFromApi();
                return;
            }

            // Démarrer l'infrastructure via PowerShell
            this.logOutput('🚀 Starting infrastructure...');
            this.updateStatusBar('⏳', 'Starting infrastructure...', 'yellow');

            const workspaceRoot = vscode.workspace.workspaceFolders![0].uri.fsPath;
            const scriptPath = path.join(workspaceRoot, 'scripts', 'phase2-advanced-monitoring.ps1');
            
            const autoHealingFlag = this.autoHealingEnabled ? '-EnableAutoHealing' : '';
            const command = `powershell.exe -ExecutionPolicy Bypass -File "${scriptPath}" -Action start ${autoHealingFlag}`;

            const terminal = vscode.window.createTerminal({
                name: 'Smart Infrastructure',
                cwd: workspaceRoot
            });
            
            terminal.sendText(command);
            terminal.show();

            // Attendre un peu puis vérifier le statut
            await this.delay(10000);
            await this.updateStatusFromApi();

        } catch (error) {
            this.logOutput(`❌ Auto-start failed: ${error}`);
            this.updateStatusBar('❌', 'Auto-start failed', 'red');
        }
    }

    private async startInfrastructure() {
        try {
            this.logOutput('🚀 Starting infrastructure stack...');
            this.updateStatusBar('⏳', 'Starting...', 'yellow');

            const workspaceRoot = vscode.workspace.workspaceFolders![0].uri.fsPath;
            const scriptPath = path.join(workspaceRoot, 'scripts', 'phase2-advanced-monitoring.ps1');
            
            const autoHealingFlag = this.autoHealingEnabled ? '-EnableAutoHealing' : '';
            const command = `powershell.exe -ExecutionPolicy Bypass -File "${scriptPath}" -Action start ${autoHealingFlag}`;

            const terminal = vscode.window.createTerminal({
                name: 'Smart Infrastructure - Start',
                cwd: workspaceRoot
            });
            
            terminal.sendText(command);
            terminal.show();

            vscode.window.showInformationMessage('Infrastructure stack is starting...');
            
            // Vérifier le statut après démarrage
            await this.delay(15000);
            await this.updateStatusFromApi();

        } catch (error) {
            vscode.window.showErrorMessage(`Failed to start infrastructure: ${error}`);
            this.logOutput(`❌ Start failed: ${error}`);
        }
    }

    private async stopInfrastructure() {
        try {
            this.logOutput('🛑 Stopping infrastructure stack...');
            this.updateStatusBar('⏳', 'Stopping...', 'yellow');

            const workspaceRoot = vscode.workspace.workspaceFolders![0].uri.fsPath;
            const scriptPath = path.join(workspaceRoot, 'scripts', 'phase2-advanced-monitoring.ps1');
            
            const command = `powershell.exe -ExecutionPolicy Bypass -File "${scriptPath}" -Action stop`;

            const terminal = vscode.window.createTerminal({
                name: 'Smart Infrastructure - Stop',
                cwd: workspaceRoot
            });
            
            terminal.sendText(command);
            terminal.show();

            vscode.window.showInformationMessage('Infrastructure stack is stopping...');
            
            this.isInfrastructureRunning = false;
            this.updateStatusBar('⏹️', 'Stopped', 'gray');

        } catch (error) {
            vscode.window.showErrorMessage(`Failed to stop infrastructure: ${error}`);
            this.logOutput(`❌ Stop failed: ${error}`);
        }
    }

    private async restartInfrastructure() {
        this.logOutput('🔄 Restarting infrastructure stack...');
        await this.stopInfrastructure();
        await this.delay(5000);
        await this.startInfrastructure();
    }

    private async showDetailedStatus() {
        try {
            const status = await this.getInfrastructureStatus();
            const services = await this.getServicesStatus();

            let statusMessage = `📊 Smart Email Sender Infrastructure Status\n\n`;
            statusMessage += `Overall Status: ${status.overall}\n`;
            statusMessage += `Monitoring Active: ${status.active}\n`;
            statusMessage += `Auto-Healing: ${status.autoHealingEnabled}\n`;
            statusMessage += `Services Monitored: ${status.servicesMonitored}\n\n`;

            if (services) {
                statusMessage += `🔧 Services:\n`;
                for (const [serviceName, serviceData] of Object.entries(services)) {
                    const service = serviceData as ServiceStatus;
                    const icon = service.health === 'healthy' ? '✅' : '❌';
                    statusMessage += `${icon} ${serviceName}: ${service.status} (${service.health})\n`;
                }
            }

            vscode.window.showInformationMessage(statusMessage, { modal: true });

        } catch (error) {
            vscode.window.showErrorMessage(`Failed to get status: ${error}`);
        }
    }

    private async toggleAutoHealing() {
        try {
            this.autoHealingEnabled = !this.autoHealingEnabled;
            
            const action = this.autoHealingEnabled ? 'enable' : 'disable';
            const response = await httpRequest(`${this.apiBaseUrl}/api/v1/auto-healing/${action}`, {
                method: 'POST'
            });

            if (response.ok) {
                const message = `Auto-healing ${this.autoHealingEnabled ? 'enabled' : 'disabled'}`;
                vscode.window.showInformationMessage(message);
                this.logOutput(`🔧 ${message}`);
                await this.updateStatusFromApi();
            } else {
                throw new Error(`HTTP ${response.status}`);
            }

        } catch (error) {
            vscode.window.showErrorMessage(`Failed to toggle auto-healing: ${error}`);
        }
    }    private showLogs() {
        this.outputChannel.show();
    }    private async runEmergencyDiagnostic() {
        try {
            this.logOutput('🚨 Starting Emergency Diagnostic & Repair...');
            vscode.window.showInformationMessage('🚨 Emergency Diagnostic starting...');

            const workspaceRoot = vscode.workspace.workspaceFolders![0].uri.fsPath;
            const scriptPath = path.join(workspaceRoot, 'Emergency-Diagnostic-Test.ps1');
            
            // Vérifier si le script existe
            if (!fs.existsSync(scriptPath)) {
                throw new Error('Emergency diagnostic script not found');
            }

            // Demander le type de diagnostic à l'utilisateur
            const action = await vscode.window.showQuickPick([
                { label: '🔍 Full Diagnostic + Repair + Monitoring', value: '-AllPhases' },
                { label: '🔬 Diagnostic Only', value: '-RunDiagnostic' },
                { label: '🔧 Repair Only', value: '-RunRepair' },
                { label: '🛑 Emergency Stop', value: '-EmergencyStop' }
            ], {
                placeHolder: 'Select emergency diagnostic action'
            });

            if (!action) return;

            this.updateStatusBar('🚨', 'Emergency Diagnostic Running...', 'red');

            const command = `powershell.exe -ExecutionPolicy Bypass -File "${scriptPath}" ${action.value}`;

            const terminal = vscode.window.createTerminal({
                name: 'Emergency Diagnostic',
                cwd: workspaceRoot
            });
            
            terminal.sendText(command);
            terminal.show();

            this.logOutput(`🚨 Emergency diagnostic launched with: ${action.label}`);
            
            // Mettre à jour le health indicator après diagnostic
            setTimeout(async () => {
                await this.healthIndicator.updateHealthStatus();
                await this.updateStatusFromApi();
            }, 10000);

        } catch (error) {
            this.logOutput(`❌ Emergency diagnostic failed: ${error}`);
            vscode.window.showErrorMessage(`Emergency diagnostic failed: ${error}`);
            this.updateStatusBar('❌', 'Emergency diagnostic failed', 'red');
        }
    }

    private async checkApiServerStatus(): Promise<boolean> {
        try {            const response = await httpRequest(`${this.apiBaseUrl}/api/v1/infrastructure/status`, {
                method: 'GET'
            });
            return response.ok;
        } catch {
            return false;
        }
    }

    private async getInfrastructureStatus(): Promise<InfrastructureStatus> {
        const response = await httpRequest(`${this.apiBaseUrl}/api/v1/monitoring/status`);
        if (!response.ok) {
            throw new Error(`HTTP ${response.status}`);
        }
        const data = await response.json();
        return data.data;
    }

    private async getServicesStatus(): Promise<any> {
        const response = await httpRequest(`${this.apiBaseUrl}/api/v1/infrastructure/status`);
        if (!response.ok) {
            throw new Error(`HTTP ${response.status}`);
        }
        const data = await response.json();
        return data.data;
    }

    private async updateStatusFromApi() {
        try {
            const isRunning = await this.checkApiServerStatus();
            
            if (!isRunning) {
                this.updateStatusBar('❌', 'API Server not running', 'red');
                this.isInfrastructureRunning = false;
                return;
            }

            const status = await this.getInfrastructureStatus();
            this.isInfrastructureRunning = true;

            let icon = '✅';
            let text = 'Running';
            let color = 'lightgreen';

            if (!status.active) {
                icon = '⚠️';
                text = 'Monitoring inactive';
                color = 'yellow';
            }

            if (status.autoHealingEnabled) {
                icon = '💚';
                text += ' + Auto-Healing';
            }

            this.updateStatusBar(icon, `${text} (${status.servicesMonitored} services)`, color);

        } catch (error) {
            this.updateStatusBar('❌', 'Status check failed', 'red');
            this.logOutput(`⚠️ Status update failed: ${error}`);
        }
    }

    private updateStatusBar(icon: string, text: string, color: string) {
        this.statusBarItem.text = `${icon} Smart Infrastructure: ${text}`;
        this.statusBarItem.tooltip = `Smart Email Sender Infrastructure\nClick for detailed status`;
        // Note: VS Code doesn't support colored status bar items directly
    }

    private logOutput(message: string) {
        const timestamp = new Date().toLocaleTimeString();
        this.outputChannel.appendLine(`[${timestamp}] ${message}`);
    }

    private delay(ms: number): Promise<void> {
        return new Promise(resolve => setTimeout(resolve, ms));
    }

    public dispose() {
        this.statusBarItem.dispose();
        this.outputChannel.dispose();
    }
}

export function activate(context: vscode.ExtensionContext) {
    console.log('Smart Email Sender workspace extension is now active!');
    
    const extension = new SmartEmailSenderExtension(context);
    
    // Actualiser le statut périodiquement
    const statusInterval = setInterval(async () => {
        if (extension['isInfrastructureRunning']) {
            await extension['updateStatusFromApi']();
        }
    }, 30000); // Toutes les 30 secondes

    // Monitoring santé système plus fréquent
    const healthInterval = setInterval(async () => {
        await extension['healthIndicator']['updateHealthStatus']();
    }, 15000); // Toutes les 15 secondes

    context.subscriptions.push({
        dispose: () => {
            clearInterval(statusInterval);
            clearInterval(healthInterval);
            extension.dispose();
        }
    });
}

export function deactivate() {
    console.log('Smart Email Sender workspace extension is now deactivated!');
}
