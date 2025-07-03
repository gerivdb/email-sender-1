Help on module callbacks:

NAME
    callbacks

CLASSES
    langchain_core.callbacks.streaming_stdout.StreamingStdOutCallbackHandler(langchain_core.callbacks.base.BaseCallbackHandler)
        StreamingStdOutCallbackHandlerYield

    class StreamingStdOutCallbackHandlerYield(langchain_core.callbacks.streaming_stdout.StreamingStdOutCallbackHandler)
     |  StreamingStdOutCallbackHandlerYield(q: queue.Queue) -> None
     |
     |  This is a callback handler that yields the tokens as they are generated.
     |  For a usage example, see the :func:`generate` function below.
     |
     |  Method resolution order:
     |      StreamingStdOutCallbackHandlerYield
     |      langchain_core.callbacks.streaming_stdout.StreamingStdOutCallbackHandler
     |      langchain_core.callbacks.base.BaseCallbackHandler
     |      langchain_core.callbacks.base.LLMManagerMixin
     |      langchain_core.callbacks.base.ChainManagerMixin
     |      langchain_core.callbacks.base.ToolManagerMixin
     |      langchain_core.callbacks.base.RetrieverManagerMixin
     |      langchain_core.callbacks.base.CallbackManagerMixin
     |      langchain_core.callbacks.base.RunManagerMixin
     |      builtins.object
     |
     |  Methods defined here:
     |
     |  __init__(self, q: queue.Queue) -> None
     |      Initialize the callback handler.
     |      q: The queue to write the tokens to as they are generated.
     |
     |  on_llm_end(self, response: langchain_core.outputs.llm_result.LLMResult, **kwargs: Any) -> None
     |      Run when LLM ends running.
     |
     |  on_llm_error(self, error: Union[Exception, KeyboardInterrupt], **kwargs: Any) -> None
     |      Run when LLM errors.
     |
     |  on_llm_new_token(self, token: str, **kwargs: Any) -> None
     |      Run on new LLM token. Only available when streaming is enabled.
     |
     |  on_llm_start(self, serialized: dict[str, typing.Any], prompts: list[str], **kwargs: Any) -> None
     |      Run when LLM starts running.
     |
     |  ----------------------------------------------------------------------
     |  Data and other attributes defined here:
     |
     |  __annotations__ = {'q': <class 'queue.Queue'>}
     |
     |  ----------------------------------------------------------------------
     |  Methods inherited from langchain_core.callbacks.streaming_stdout.StreamingStdOutCallbackHandler:
     |
     |  on_agent_action(self, action: 'AgentAction', **kwargs: 'Any') -> 'Any'
     |      Run on agent action.
     |
     |      Args:
     |          action (AgentAction): The agent action.
     |          **kwargs (Any): Additional keyword arguments.
     |
     |  on_agent_finish(self, finish: 'AgentFinish', **kwargs: 'Any') -> 'None'
     |      Run on the agent end.
     |
     |      Args:
     |          finish (AgentFinish): The agent finish.
     |          **kwargs (Any): Additional keyword arguments.
     |
     |  on_chain_end(self, outputs: 'dict[str, Any]', **kwargs: 'Any') -> 'None'
     |      Run when a chain ends running.
     |
     |      Args:
     |          outputs (dict[str, Any]): The outputs of the chain.
     |          **kwargs (Any): Additional keyword arguments.
     |
     |  on_chain_error(self, error: 'BaseException', **kwargs: 'Any') -> 'None'
     |      Run when chain errors.
     |
     |      Args:
     |          error (BaseException): The error that occurred.
     |          **kwargs (Any): Additional keyword arguments.
     |
     |  on_chain_start(self, serialized: 'dict[str, Any]', inputs: 'dict[str, Any]', **kwargs: 'Any') -> 'None'
     |      Run when a chain starts running.
     |
     |      Args:
     |          serialized (dict[str, Any]): The serialized chain.
     |          inputs (dict[str, Any]): The inputs to the chain.
     |          **kwargs (Any): Additional keyword arguments.
     |
     |  on_chat_model_start(self, serialized: 'dict[str, Any]', messages: 'list[list[BaseMessage]]', **kwargs: 'Any') -> 'None'
     |      Run when LLM starts running.
     |
     |      Args:
     |          serialized (dict[str, Any]): The serialized LLM.
     |          messages (list[list[BaseMessage]]): The messages to run.
     |          **kwargs (Any): Additional keyword arguments.
     |
     |  on_text(self, text: 'str', **kwargs: 'Any') -> 'None'
     |      Run on an arbitrary text.
     |
     |      Args:
     |          text (str): The text to print.
     |          **kwargs (Any): Additional keyword arguments.
     |
     |  on_tool_end(self, output: 'Any', **kwargs: 'Any') -> 'None'
     |      Run when tool ends running.
     |
     |      Args:
     |          output (Any): The output of the tool.
     |          **kwargs (Any): Additional keyword arguments.
     |
     |  on_tool_error(self, error: 'BaseException', **kwargs: 'Any') -> 'None'
     |      Run when tool errors.
     |
     |      Args:
     |          error (BaseException): The error that occurred.
     |          **kwargs (Any): Additional keyword arguments.
     |
     |  on_tool_start(self, serialized: 'dict[str, Any]', input_str: 'str', **kwargs: 'Any') -> 'None'
     |      Run when the tool starts running.
     |
     |      Args:
     |          serialized (dict[str, Any]): The serialized tool.
     |          input_str (str): The input string.
     |          **kwargs (Any): Additional keyword arguments.
     |
     |  ----------------------------------------------------------------------
     |  Readonly properties inherited from langchain_core.callbacks.base.BaseCallbackHandler:
     |
     |  ignore_agent
     |      Whether to ignore agent callbacks.
     |
     |  ignore_chain
     |      Whether to ignore chain callbacks.
     |
     |  ignore_chat_model
     |      Whether to ignore chat model callbacks.
     |
     |  ignore_custom_event
     |      Ignore custom event.
     |
     |  ignore_llm
     |      Whether to ignore LLM callbacks.
     |
     |  ignore_retriever
     |      Whether to ignore retriever callbacks.
     |
     |  ignore_retry
     |      Whether to ignore retry callbacks.
     |
     |  ----------------------------------------------------------------------
     |  Data and other attributes inherited from langchain_core.callbacks.base.BaseCallbackHandler:
     |
     |  raise_error = False
     |
     |  run_inline = False
     |
     |  ----------------------------------------------------------------------
     |  Data descriptors inherited from langchain_core.callbacks.base.LLMManagerMixin:
     |
     |  __dict__
     |      dictionary for instance variables
     |
     |  __weakref__
     |      list of weak references to the object
     |
     |  ----------------------------------------------------------------------
     |  Methods inherited from langchain_core.callbacks.base.RetrieverManagerMixin:
     |
     |  on_retriever_end(self, documents: 'Sequence[Document]', *, run_id: 'UUID', parent_run_id: 'Optional[UUID]' = None, **kwargs: 'Any') -> 'Any'
     |      Run when Retriever ends running.
     |
     |      Args:
     |          documents (Sequence[Document]): The documents retrieved.
     |          run_id (UUID): The run ID. This is the ID of the current run.
     |          parent_run_id (UUID): The parent run ID. This is the ID of the parent run.
     |          kwargs (Any): Additional keyword arguments.
     |
     |  on_retriever_error(self, error: 'BaseException', *, run_id: 'UUID', parent_run_id: 'Optional[UUID]' = None, **kwargs: 'Any') -> 'Any'
     |      Run when Retriever errors.
     |
     |      Args:
     |          error (BaseException): The error that occurred.
     |          run_id (UUID): The run ID. This is the ID of the current run.
     |          parent_run_id (UUID): The parent run ID. This is the ID of the parent run.
     |          kwargs (Any): Additional keyword arguments.
     |
     |  ----------------------------------------------------------------------
     |  Methods inherited from langchain_core.callbacks.base.CallbackManagerMixin:
     |
     |  on_retriever_start(self, serialized: 'dict[str, Any]', query: 'str', *, run_id: 'UUID', parent_run_id: 'Optional[UUID]' = None, tags: 'Optional[list[str]]' = None, metadata: 'Optional[dict[str, Any]]' = None, **kwargs: 'Any') -> 'Any'
     |      Run when the Retriever starts running.
     |
     |      Args:
     |          serialized (dict[str, Any]): The serialized Retriever.
     |          query (str): The query.
     |          run_id (UUID): The run ID. This is the ID of the current run.
     |          parent_run_id (UUID): The parent run ID. This is the ID of the parent run.
     |          tags (Optional[list[str]]): The tags.
     |          metadata (Optional[dict[str, Any]]): The metadata.
     |          kwargs (Any): Additional keyword arguments.
     |
     |  ----------------------------------------------------------------------
     |  Methods inherited from langchain_core.callbacks.base.RunManagerMixin:
     |
     |  on_custom_event(self, name: 'str', data: 'Any', *, run_id: 'UUID', tags: 'Optional[list[str]]' = None, metadata: 'Optional[dict[str, Any]]' = None, **kwargs: 'Any') -> 'Any'
     |      Override to define a handler for a custom event.
     |
     |      Args:
     |          name: The name of the custom event.
     |          data: The data for the custom event. Format will match
     |                the format specified by the user.
     |          run_id: The ID of the run.
     |          tags: The tags associated with the custom event
     |              (includes inherited tags).
     |          metadata: The metadata associated with the custom event
     |              (includes inherited metadata).
     |
     |      .. versionadded:: 0.2.15
     |
     |  on_retry(self, retry_state: 'RetryCallState', *, run_id: 'UUID', parent_run_id: 'Optional[UUID]' = None, **kwargs: 'Any') -> 'Any'
     |      Run on a retry event.
     |
     |      Args:
     |          retry_state (RetryCallState): The retry state.
     |          run_id (UUID): The run ID. This is the ID of the current run.
     |          parent_run_id (UUID): The parent run ID. This is the ID of the parent run.
     |          kwargs (Any): Additional keyword arguments.

FUNCTIONS
    generate(rq: queue.Queue)
        This is a generator that yields the items in the queue until it reaches the stop item.

        Usage example:
        ```
        def askQuestion(callback_fn: StreamingStdOutCallbackHandlerYield):
            llm = OpenAI(streaming=True, callbacks=[callback_fn])
            return llm.invoke(prompt="Write a poem about a tree.")

        @app.route("/", methods=["GET"])
        def generate_output():
            q = Queue()
            callback_fn = StreamingStdOutCallbackHandlerYield(q)
            threading.Thread(target=askQuestion, args=(callback_fn,)).start()
            return Response(generate(q), mimetype="text/event-stream")
        ```

DATA
    STOP_ITEM = '[END]'
    Union = typing.Union
        Union type; Union[X, Y] means either X or Y.

        On Python 3.10 and higher, the | operator
        can also be used to denote unions;
        X | Y means the same thing to the type checker as Union[X, Y].

        To define a union, use e.g. Union[int, str]. Details:
        - The arguments must be types and there must be at least one.
        - None as an argument is a special case and is replaced by
          type(None).
        - Unions of unions are flattened, e.g.::

            assert Union[Union[int, str], float] == Union[int, str, float]

        - Unions of a single argument vanish, e.g.::

            assert Union[int] == int  # The constructor actually returns int

        - Redundant arguments are skipped, e.g.::

            assert Union[int, str, int] == Union[int, str]

        - When comparing unions, the argument order is ignored, e.g.::

            assert Union[int, str] == Union[str, int]

        - You cannot subclass or instantiate a union.
        - You can use Optional[X] as a shorthand for Union[X, None].

FILE
    d:\do\web\n8n_tests\projets\email_sender_1\mem0-analysis\repo\embedchain\embedchain\helpers\callbacks.py


