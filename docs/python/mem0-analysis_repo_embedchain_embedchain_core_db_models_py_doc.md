Help on module models:

NAME
    models

CLASSES
    sqlalchemy.orm.decl_api.Base(builtins.object)
        ChatHistory
        DataSource

    class ChatHistory(sqlalchemy.orm.decl_api.Base)
     |  ChatHistory(**kwargs)
     |
     |  Method resolution order:
     |      ChatHistory
     |      sqlalchemy.orm.decl_api.Base
     |      builtins.object
     |
     |  Methods defined here:
     |
     |  __init__(self, **kwargs) from sqlalchemy.orm.instrumentation
     |      A simple constructor that allows initialization from kwargs.
     |
     |      Sets attributes on the constructed instance using the names and
     |      values in ``kwargs``.
     |
     |      Only keys that are present as
     |      attributes of the instance's class are allowed. These could be,
     |      for example, any mapped columns or relationships.
     |
     |  ----------------------------------------------------------------------
     |  Data descriptors defined here:
     |
     |  answer
     |
     |  app_id
     |
     |  created_at
     |
     |  id
     |
     |  meta_data
     |
     |  question
     |
     |  session_id
     |
     |  ----------------------------------------------------------------------
     |  Data and other attributes defined here:
     |
     |  __mapper__ = <Mapper at 0x28128c9e420; ChatHistory>
     |
     |  __table__ = Table('ec_chat_history', MetaData(), Column('app...0x28128...
     |
     |  __tablename__ = 'ec_chat_history'
     |
     |  ----------------------------------------------------------------------
     |  Data descriptors inherited from sqlalchemy.orm.decl_api.Base:
     |
     |  __dict__
     |      dictionary for instance variables
     |
     |  __weakref__
     |      list of weak references to the object
     |
     |  ----------------------------------------------------------------------
     |  Data and other attributes inherited from sqlalchemy.orm.decl_api.Base:
     |
     |  __abstract__ = True
     |
     |  metadata = MetaData()
     |
     |  registry = <sqlalchemy.orm.decl_api.registry object>

    class DataSource(sqlalchemy.orm.decl_api.Base)
     |  DataSource(**kwargs)
     |
     |  Method resolution order:
     |      DataSource
     |      sqlalchemy.orm.decl_api.Base
     |      builtins.object
     |
     |  Methods defined here:
     |
     |  __init__(self, **kwargs) from sqlalchemy.orm.instrumentation
     |      A simple constructor that allows initialization from kwargs.
     |
     |      Sets attributes on the constructed instance using the names and
     |      values in ``kwargs``.
     |
     |      Only keys that are present as
     |      attributes of the instance's class are allowed. These could be,
     |      for example, any mapped columns or relationships.
     |
     |  ----------------------------------------------------------------------
     |  Data descriptors defined here:
     |
     |  app_id
     |
     |  hash
     |
     |  id
     |
     |  is_uploaded
     |
     |  meta_data
     |
     |  type
     |
     |  value
     |
     |  ----------------------------------------------------------------------
     |  Data and other attributes defined here:
     |
     |  __mapper__ = <Mapper at 0x28128e39700; DataSource>
     |
     |  __table__ = Table('ec_data_sources', MetaData(), Column('id'...ault=Sc...
     |
     |  __tablename__ = 'ec_data_sources'
     |
     |  ----------------------------------------------------------------------
     |  Data descriptors inherited from sqlalchemy.orm.decl_api.Base:
     |
     |  __dict__
     |      dictionary for instance variables
     |
     |  __weakref__
     |      list of weak references to the object
     |
     |  ----------------------------------------------------------------------
     |  Data and other attributes inherited from sqlalchemy.orm.decl_api.Base:
     |
     |  __abstract__ = True
     |
     |  metadata = MetaData()
     |
     |  registry = <sqlalchemy.orm.decl_api.registry object>

DATA
    func = <sqlalchemy.sql.functions._FunctionGenerator object>
    metadata = MetaData()

FILE
    d:\do\web\n8n_tests\projets\email_sender_1\mem0-analysis\repo\embedchain\embedchain\core\db\models.py


