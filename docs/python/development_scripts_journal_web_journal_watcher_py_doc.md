Help on module journal_watcher:

NAME
    journal_watcher

CLASSES
    watchdog.events.FileSystemEventHandler(builtins.object)
        JournalEventHandler

    class JournalEventHandler(watchdog.events.FileSystemEventHandler)
     |  Method resolution order:
     |      JournalEventHandler
     |      watchdog.events.FileSystemEventHandler
     |      builtins.object
     |
     |  Methods defined here:
     |
     |  __init__(self)
     |      Initialize self.  See help(type(self)) for accurate signature.
     |
     |  check_rebuild(self)
     |      Vérifie s'il faut reconstruire les index et le fait si nécessaire.
     |
     |  on_any_event(self, event)
     |      Catch-all event handler.
     |
     |      :param event:
     |          The event object representing the file system event.
     |      :type event:
     |          :class:`FileSystemEvent`
     |
     |  ----------------------------------------------------------------------
     |  Methods inherited from watchdog.events.FileSystemEventHandler:
     |
     |  dispatch(self, event: 'FileSystemEvent') -> 'None'
     |      Dispatches events to the appropriate methods.
     |
     |      :param event:
     |          The event object representing the file system event.
     |      :type event:
     |          :class:`FileSystemEvent`
     |
     |  on_closed(self, event: 'FileClosedEvent') -> 'None'
     |      Called when a file opened for writing is closed.
     |
     |      :param event:
     |          Event representing file closing.
     |      :type event:
     |          :class:`FileClosedEvent`
     |
     |  on_closed_no_write(self, event: 'FileClosedNoWriteEvent') -> 'None'
     |      Called when a file opened for reading is closed.
     |
     |      :param event:
     |          Event representing file closing.
     |      :type event:
     |          :class:`FileClosedNoWriteEvent`
     |
     |  on_created(self, event: 'DirCreatedEvent | FileCreatedEvent') -> 'None'
     |      Called when a file or directory is created.
     |
     |      :param event:
     |          Event representing file/directory creation.
     |      :type event:
     |          :class:`DirCreatedEvent` or :class:`FileCreatedEvent`
     |
     |  on_deleted(self, event: 'DirDeletedEvent | FileDeletedEvent') -> 'None'
     |      Called when a file or directory is deleted.
     |
     |      :param event:
     |          Event representing file/directory deletion.
     |      :type event:
     |          :class:`DirDeletedEvent` or :class:`FileDeletedEvent`
     |
     |  on_modified(self, event: 'DirModifiedEvent | FileModifiedEvent') -> 'None'
     |      Called when a file or directory is modified.
     |
     |      :param event:
     |          Event representing file/directory modification.
     |      :type event:
     |          :class:`DirModifiedEvent` or :class:`FileModifiedEvent`
     |
     |  on_moved(self, event: 'DirMovedEvent | FileMovedEvent') -> 'None'
     |      Called when a file or a directory is moved or renamed.
     |
     |      :param event:
     |          Event representing file/directory movement.
     |      :type event:
     |          :class:`DirMovedEvent` or :class:`FileMovedEvent`
     |
     |  on_opened(self, event: 'FileOpenedEvent') -> 'None'
     |      Called when a file is opened.
     |
     |      :param event:
     |          Event representing file opening.
     |      :type event:
     |          :class:`FileOpenedEvent`
     |
     |  ----------------------------------------------------------------------
     |  Data descriptors inherited from watchdog.events.FileSystemEventHandler:
     |
     |  __dict__
     |      dictionary for instance variables
     |
     |  __weakref__
     |      list of weak references to the object

FUNCTIONS
    setup_as_service()
        Configure le script comme un service Windows.

    start_watching(background=False)
        Démarre la surveillance du dossier du journal.

DATA
    ENTRIES_DIR = WindowsPath('docs/journal_de_bord/entries')
    JOURNAL_DIR = WindowsPath('docs/journal_de_bord')
    REBUILD_DELAY = 10
    SCRIPTS_DIR = WindowsPath('development/scripts/python/journal')
    logger = <Logger journal_watcher (INFO)>

FILE
    d:\do\web\n8n_tests\projets\email_sender_1\development\scripts\journal\web\journal_watcher.py


