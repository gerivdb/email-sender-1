import os
import sys
import time
import logging
from pathlib import Path
import subprocess
import argparse
from watchdog.observers import Observer
from watchdog.events import FileSystemEventHandler

# Configuration du logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(message)s',
    datefmt='%Y-%m-%d %H:%M:%S'
)
logger = logging.getLogger(__name__)

# Chemin vers le dossier du journal
JOURNAL_DIR = Path("docs/journal_de_bord")
ENTRIES_DIR = JOURNAL_DIR / "entries"
SCRIPTS_DIR = Path("development/scripts/python/journal")

# Délai minimum entre deux reconstructions d'index (en secondes)
REBUILD_DELAY = 10

class JournalEventHandler(FileSystemEventHandler):
    def __init__(self):
        self.last_rebuild_time = 0
        self.rebuild_needed = False
        self.python_executable = sys.executable
    
    def on_any_event(self, event):
        # Ignorer les événements sur les fichiers temporaires et les dossiers
        if event.is_directory:
            return
        
        # Ignorer les fichiers qui ne sont pas des fichiers Markdown
        if not event.src_path.endswith('.md'):
            return
        
        # Ignorer les fichiers d'index générés
        if '/index.md' in event.src_path or '/tags/' in event.src_path:
            return
        
        # Ignorer les fichiers dans le dossier rag
        if '/rag/' in event.src_path:
            return
        
        logger.info(f"Modification détectée: {event.src_path}")
        self.rebuild_needed = True
    
    def check_rebuild(self):
        """Vérifie s'il faut reconstruire les index et le fait si nécessaire."""
        current_time = time.time()
        
        if self.rebuild_needed and (current_time - self.last_rebuild_time) > REBUILD_DELAY:
            logger.info("Reconstruction des index...")
            
            try:
                # Reconstruire l'index de recherche
                subprocess.run([
                    self.python_executable, 
                    str(SCRIPTS_DIR / "journal_search_simple.py"), 
                    "--rebuild"
                ], check=True)
                logger.info("Index de recherche reconstruit avec succès")
                
                # Reconstruire l'index RAG
                subprocess.run([
                    self.python_executable, 
                    str(SCRIPTS_DIR / "journal_rag_simple.py"), 
                    "--rebuild", 
                    "--export"
                ], check=True)
                logger.info("Index RAG reconstruit avec succès")
                
                self.last_rebuild_time = current_time
                self.rebuild_needed = False
            except subprocess.CalledProcessError as e:
                logger.error(f"Erreur lors de la reconstruction des index: {e}")

def start_watching(background=False):
    """Démarre la surveillance du dossier du journal."""
    logger.info(f"Démarrage de la surveillance du dossier: {JOURNAL_DIR}")
    
    # Créer les dossiers s'ils n'existent pas
    ENTRIES_DIR.mkdir(exist_ok=True, parents=True)
    
    # Créer le gestionnaire d'événements
    event_handler = JournalEventHandler()
    
    # Créer l'observateur
    observer = Observer()
    observer.schedule(event_handler, str(JOURNAL_DIR), recursive=True)
    observer.start()
    
    try:
        while True:
            # Vérifier s'il faut reconstruire les index
            event_handler.check_rebuild()
            time.sleep(1)
    except KeyboardInterrupt:
        observer.stop()
    
    observer.join()

def setup_as_service():
    """Configure le script comme un service Windows."""
    try:
        import win32serviceutil
        import win32service
        import win32event
        import servicemanager
        import socket
    except ImportError:
        logger.error("Les modules pywin32 sont nécessaires pour configurer un service Windows.")
        logger.error("Installez-les avec: pip install pywin32")
        return False
    
    class JournalWatcherService(win32serviceutil.ServiceFramework):
        _svc_name_ = "JournalWatcher"
        _svc_display_name_ = "Journal de Bord Watcher"
        _svc_description_ = "Surveille les modifications dans le journal de bord et reconstruit les index"
        
        def __init__(self, args):
            win32serviceutil.ServiceFramework.__init__(self, args)
            self.hWaitStop = win32event.CreateEvent(None, 0, 0, None)
            socket.setdefaulttimeout(60)
            self.is_running = True
        
        def SvcStop(self):
            self.ReportServiceStatus(win32service.SERVICE_STOP_PENDING)
            win32event.SetEvent(self.hWaitStop)
            self.is_running = False
        
        def SvcDoRun(self):
            servicemanager.LogMsg(
                servicemanager.EVENTLOG_INFORMATION_TYPE,
                servicemanager.PYS_SERVICE_STARTED,
                (self._svc_name_, '')
            )
            self.main()
        
        def main(self):
            # Créer le gestionnaire d'événements
            event_handler = JournalEventHandler()
            
            # Créer l'observateur
            observer = Observer()
            observer.schedule(event_handler, str(JOURNAL_DIR), recursive=True)
            observer.start()
            
            try:
                while self.is_running:
                    # Vérifier s'il faut reconstruire les index
                    event_handler.check_rebuild()
                    time.sleep(1)
                    
                    # Vérifier si le service doit s'arrêter
                    if win32event.WaitForSingleObject(self.hWaitStop, 1) == win32event.WAIT_OBJECT_0:
                        break
            finally:
                observer.stop()
                observer.join()
    
    # Enregistrer et démarrer le service
    if len(sys.argv) == 1:
        servicemanager.Initialize()
        servicemanager.PrepareToHostSingle(JournalWatcherService)
        servicemanager.StartServiceCtrlDispatcher()
    else:
        win32serviceutil.HandleCommandLine(JournalWatcherService)
    
    return True

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Surveillance du journal de bord")
    parser.add_argument("--service", action="store_true", help="Configurer comme un service Windows")
    parser.add_argument("--background", action="store_true", help="Exécuter en arrière-plan")
    
    args = parser.parse_args()
    
    if args.service:
        setup_as_service()
    else:
        start_watching(args.background)
