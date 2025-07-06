Help on module rag:

NAME
    rag

CLASSES
    builtins.object
        RAGManager

    class RAGManager(builtins.object)
     |  RAGManager(data_path='dataset/locomo10_rag.json', chunk_size=500, k=1)
     |
     |  Methods defined here:
     |
     |  __init__(self, data_path='dataset/locomo10_rag.json', chunk_size=500, k=1)
     |      Initialize self.  See help(type(self)) for accurate signature.
     |
     |  calculate_embedding(self, document)
     |
     |  calculate_similarity(self, embedding1, embedding2)
     |
     |  clean_chat_history(self, chat_history)
     |
     |  create_chunks(self, chat_history, chunk_size=500)
     |      Create chunks using tiktoken for more accurate token counting
     |
     |  generate_response(self, question, context)
     |
     |  process_all_conversations(self, output_file_path)
     |
     |  search(self, query, chunks, embeddings, k=1)
     |      Search for the top-k most similar chunks to the query.
     |
     |      Args:
     |          query: The query string
     |          chunks: List of text chunks
     |          embeddings: List of embeddings for each chunk
     |          k: Number of top chunks to return (default: 1)
     |
     |      Returns:
     |          combined_chunks: The combined text of the top-k chunks
     |          search_time: Time taken for the search
     |
     |  ----------------------------------------------------------------------
     |  Data descriptors defined here:
     |
     |  __dict__
     |      dictionary for instance variables
     |
     |  __weakref__
     |      list of weak references to the object

DATA
    PROMPT = '\n# Question: \n{{QUESTION}}\n\n# Context: \n{{CONTEXT}}\n\n...

FILE
    d:\do\web\n8n_tests\projets\email_sender_1\mem0-analysis\repo\evaluation\src\rag.py


