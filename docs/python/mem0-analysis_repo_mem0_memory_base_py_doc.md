Help on module base:

NAME
    base

CLASSES
    abc.ABC(builtins.object)
        MemoryBase

    class MemoryBase(abc.ABC)
     |  Method resolution order:
     |      MemoryBase
     |      abc.ABC
     |      builtins.object
     |
     |  Methods defined here:
     |
     |  delete(self, memory_id)
     |      Delete a memory by ID.
     |
     |      Args:
     |          memory_id (str): ID of the memory to delete.
     |
     |  get(self, memory_id)
     |      Retrieve a memory by ID.
     |
     |      Args:
     |          memory_id (str): ID of the memory to retrieve.
     |
     |      Returns:
     |          dict: Retrieved memory.
     |
     |  get_all(self)
     |      List all memories.
     |
     |      Returns:
     |          list: List of all memories.
     |
     |  history(self, memory_id)
     |      Get the history of changes for a memory by ID.
     |
     |      Args:
     |          memory_id (str): ID of the memory to get history for.
     |
     |      Returns:
     |          list: List of changes for the memory.
     |
     |  update(self, memory_id, data)
     |      Update a memory by ID.
     |
     |      Args:
     |          memory_id (str): ID of the memory to update.
     |          data (dict): Data to update the memory with.
     |
     |      Returns:
     |          dict: Updated memory.
     |
     |  ----------------------------------------------------------------------
     |  Data descriptors defined here:
     |
     |  __dict__
     |      dictionary for instance variables
     |
     |  __weakref__
     |      list of weak references to the object
     |
     |  ----------------------------------------------------------------------
     |  Data and other attributes defined here:
     |
     |  __abstractmethods__ = frozenset({'delete', 'get', 'get_all', 'history'...

FILE
    d:\do\web\n8n_tests\projets\email_sender_1\mem0-analysis\repo\mem0\memory\base.py


