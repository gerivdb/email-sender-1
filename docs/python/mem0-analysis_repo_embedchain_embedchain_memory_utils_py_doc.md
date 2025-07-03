Help on module utils:

NAME
    utils

FUNCTIONS
    merge_metadata_dict(left: Optional[dict[str, Any]], right: Optional[dict[str, Any]]) -> Optional[dict[str, Any]]
        Merge the metadatas of two BaseMessage types.

        Args:
            left (dict[str, Any]): metadata of human message
            right (dict[str, Any]): metadata of AI message

        Returns:
            dict[str, Any]: combined metadata dict with dedup
            to be saved in db.

DATA
    Optional = typing.Optional
        Optional[X] is equivalent to Union[X, None].

FILE
    d:\do\web\n8n_tests\projets\email_sender_1\mem0-analysis\repo\embedchain\embedchain\memory\utils.py


