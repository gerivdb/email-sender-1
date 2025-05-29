import sqlite3
import json
import os
from typing import Optional, Dict, Any, List, Tuple
from datetime import datetime
import logging

class DatabaseManager:
    def __init__(self, db_path: str):
        """Initialize the database manager with the path to the SQLite database file."""
        self.db_path = db_path
        self._ensure_db_exists()
        self.conn = None
        self.setup_logging()

    def setup_logging(self):
        """Set up logging configuration."""
        logging.basicConfig(
            level=logging.INFO,
            format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
        )
        self.logger = logging.getLogger('DatabaseManager')