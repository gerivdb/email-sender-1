Help on module base:

NAME
    base

CLASSES
    abc.ABC(builtins.object)
        VectorStoreBase

    class VectorStoreBase(abc.ABC)
     |  Method resolution order:
     |      VectorStoreBase
     |      abc.ABC
     |      builtins.object
     |
     |  Methods defined here:
     |
     |  col_info(self)
     |      Get information about a collection.
     |
     |  create_col(self, name, vector_size, distance)
     |      Create a new collection.
     |
     |  delete(self, vector_id)
     |      Delete a vector by ID.
     |
     |  delete_col(self)
     |      Delete a collection.
     |
     |  get(self, vector_id)
     |      Retrieve a vector by ID.
     |
     |  insert(self, vectors, payloads=None, ids=None)
     |      Insert vectors into a collection.
     |
     |  list(self, filters=None, limit=None)
     |      List all memories.
     |
     |  list_cols(self)
     |      List all collections.
     |
     |  reset(self)
     |      Reset by delete the collection and recreate it.
     |
     |  search(self, query, vectors, limit=5, filters=None)
     |      Search for similar vectors.
     |
     |  update(self, vector_id, vector=None, payload=None)
     |      Update a vector and its payload.
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
     |  __abstractmethods__ = frozenset({'col_info', 'create_col', 'delete', '...

FILE
    d:\do\web\n8n_tests\projets\email_sender_1\mem0-analysis\repo\mem0\vector_stores\base.py


