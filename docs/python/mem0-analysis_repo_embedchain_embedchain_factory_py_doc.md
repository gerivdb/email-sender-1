Help on module factory:

NAME
    factory

CLASSES
    builtins.object
        EmbedderFactory
        LlmFactory
        VectorDBFactory

    class EmbedderFactory(builtins.object)
     |  Class methods defined here:
     |
     |  create(provider_name, config_data)
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
     |  provider_to_class = {'aws_bedrock': 'embedchain.embedder.aws_bedrock.A...
     |
     |  provider_to_config_class = {'aws_bedrock': 'embedchain.config.embedder...

    class LlmFactory(builtins.object)
     |  Class methods defined here:
     |
     |  create(provider_name, config_data)
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
     |  provider_to_class = {'anthropic': 'embedchain.llm.anthropic.AnthropicL...
     |
     |  provider_to_config_class = {'anthropic': 'embedchain.config.llm.base.B...

    class VectorDBFactory(builtins.object)
     |  Class methods defined here:
     |
     |  create(provider_name, config_data)
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
     |  provider_to_class = {'chroma': 'embedchain.vectordb.chroma.ChromaDB', ...
     |
     |  provider_to_config_class = {'chroma': 'embedchain.config.vector_db.chr...

FUNCTIONS
    load_class(class_type)

FILE
    d:\do\web\n8n_tests\projets\email_sender_1\mem0-analysis\repo\embedchain\embedchain\factory.py


