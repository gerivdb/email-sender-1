"""Base transport implementation."""

from abc import ABC, abstractmethod
from typing import Any, Dict, Optional

from ...config import TransportConfig

class BaseTransport(ABC):
    """Base transport class."""

    def __init__(self, config: TransportConfig):
        """Initialize base transport."""
        self.config = config

    @abstractmethod
    async def start(self):
        """Start transport."""
        pass

    @abstractmethod
    async def stop(self):
        """Stop transport."""
        pass

    @abstractmethod
    async def broadcast(self, message: Dict[str, Any]):
        """Broadcast message to all connected clients."""
        pass
