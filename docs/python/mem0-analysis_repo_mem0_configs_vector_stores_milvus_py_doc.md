Help on module milvus:

NAME
    milvus

CLASSES
    builtins.str(builtins.object)
        MetricType(builtins.str, enum.Enum)
    enum.Enum(builtins.object)
        MetricType(builtins.str, enum.Enum)
    pydantic.main.BaseModel(builtins.object)
        MilvusDBConfig

    class MetricType(builtins.str, enum.Enum)
     |  MetricType(*values)
     |
     |  Metric Constant for milvus/ zilliz server.
     |
     |  Method resolution order:
     |      MetricType
     |      builtins.str
     |      enum.Enum
     |      builtins.object
     |
     |  Methods defined here:
     |
     |  __format__(self, format_spec) from enum.Enum
     |      Default object formatter.
     |
     |      Return str(self) if format_spec is empty. Raise TypeError otherwise.
     |
     |  __new__(cls, value) from enum.Enum
     |      Create and return a new object.  See help(type) for accurate signature.
     |
     |  __repr__(self) from enum.Enum
     |      Return repr(self).
     |
     |  __str__(self) -> str
     |      Return str(self).
     |
     |  ----------------------------------------------------------------------
     |  Data and other attributes defined here:
     |
     |  COSINE = <MetricType.COSINE: 'COSINE'>
     |
     |  HAMMING = <MetricType.HAMMING: 'HAMMING'>
     |
     |  IP = <MetricType.IP: 'IP'>
     |
     |  JACCARD = <MetricType.JACCARD: 'JACCARD'>
     |
     |  L2 = <MetricType.L2: 'L2'>
     |
     |  ----------------------------------------------------------------------
     |  Methods inherited from builtins.str:
     |
     |  __add__(self, value, /)
     |      Return self+value.
     |
     |  __contains__(self, key, /)
     |      Return bool(key in self).
     |
     |  __eq__(self, value, /)
     |      Return self==value.
     |
     |  __ge__(self, value, /)
     |      Return self>=value.
     |
     |  __getitem__(self, key, /)
     |      Return self[key].
     |
     |  __getnewargs__(...)
     |
     |  __gt__(self, value, /)
     |      Return self>value.
     |
     |  __hash__(self, /)
     |      Return hash(self).
     |
     |  __iter__(self, /)
     |      Implement iter(self).
     |
     |  __le__(self, value, /)
     |      Return self<=value.
     |
     |  __len__(self, /)
     |      Return len(self).
     |
     |  __lt__(self, value, /)
     |      Return self<value.
     |
     |  __mod__(self, value, /)
     |      Return self%value.
     |
     |  __mul__(self, value, /)
     |      Return self*value.
     |
     |  __ne__(self, value, /)
     |      Return self!=value.
     |
     |  __rmod__(self, value, /)
     |      Return value%self.
     |
     |  __rmul__(self, value, /)
     |      Return value*self.
     |
     |  __sizeof__(self, /)
     |      Return the size of the string in memory, in bytes.
     |
     |  capitalize(self, /)
     |      Return a capitalized version of the string.
     |
     |      More specifically, make the first character have upper case and the rest lower
     |      case.
     |
     |  casefold(self, /)
     |      Return a version of the string suitable for caseless comparisons.
     |
     |  center(self, width, fillchar=' ', /)
     |      Return a centered string of length width.
     |
     |      Padding is done using the specified fill character (default is a space).
     |
     |  count(...)
     |      S.count(sub[, start[, end]]) -> int
     |
     |      Return the number of non-overlapping occurrences of substring sub in
     |      string S[start:end].  Optional arguments start and end are
     |      interpreted as in slice notation.
     |
     |  encode(self, /, encoding='utf-8', errors='strict')
     |      Encode the string using the codec registered for encoding.
     |
     |      encoding
     |        The encoding in which to encode the string.
     |      errors
     |        The error handling scheme to use for encoding errors.
     |        The default is 'strict' meaning that encoding errors raise a
     |        UnicodeEncodeError.  Other possible values are 'ignore', 'replace' and
     |        'xmlcharrefreplace' as well as any other name registered with
     |        codecs.register_error that can handle UnicodeEncodeErrors.
     |
     |  endswith(...)
     |      S.endswith(suffix[, start[, end]]) -> bool
     |
     |      Return True if S ends with the specified suffix, False otherwise.
     |      With optional start, test S beginning at that position.
     |      With optional end, stop comparing S at that position.
     |      suffix can also be a tuple of strings to try.
     |
     |  expandtabs(self, /, tabsize=8)
     |      Return a copy where all tab characters are expanded using spaces.
     |
     |      If tabsize is not given, a tab size of 8 characters is assumed.
     |
     |  find(...)
     |      S.find(sub[, start[, end]]) -> int
     |
     |      Return the lowest index in S where substring sub is found,
     |      such that sub is contained within S[start:end].  Optional
     |      arguments start and end are interpreted as in slice notation.
     |
     |      Return -1 on failure.
     |
     |  format(...)
     |      S.format(*args, **kwargs) -> str
     |
     |      Return a formatted version of S, using substitutions from args and kwargs.
     |      The substitutions are identified by braces ('{' and '}').
     |
     |  format_map(...)
     |      S.format_map(mapping) -> str
     |
     |      Return a formatted version of S, using substitutions from mapping.
     |      The substitutions are identified by braces ('{' and '}').
     |
     |  index(...)
     |      S.index(sub[, start[, end]]) -> int
     |
     |      Return the lowest index in S where substring sub is found,
     |      such that sub is contained within S[start:end].  Optional
     |      arguments start and end are interpreted as in slice notation.
     |
     |      Raises ValueError when the substring is not found.
     |
     |  isalnum(self, /)
     |      Return True if the string is an alpha-numeric string, False otherwise.
     |
     |      A string is alpha-numeric if all characters in the string are alpha-numeric and
     |      there is at least one character in the string.
     |
     |  isalpha(self, /)
     |      Return True if the string is an alphabetic string, False otherwise.
     |
     |      A string is alphabetic if all characters in the string are alphabetic and there
     |      is at least one character in the string.
     |
     |  isascii(self, /)
     |      Return True if all characters in the string are ASCII, False otherwise.
     |
     |      ASCII characters have code points in the range U+0000-U+007F.
     |      Empty string is ASCII too.
     |
     |  isdecimal(self, /)
     |      Return True if the string is a decimal string, False otherwise.
     |
     |      A string is a decimal string if all characters in the string are decimal and
     |      there is at least one character in the string.
     |
     |  isdigit(self, /)
     |      Return True if the string is a digit string, False otherwise.
     |
     |      A string is a digit string if all characters in the string are digits and there
     |      is at least one character in the string.
     |
     |  isidentifier(self, /)
     |      Return True if the string is a valid Python identifier, False otherwise.
     |
     |      Call keyword.iskeyword(s) to test whether string s is a reserved identifier,
     |      such as "def" or "class".
     |
     |  islower(self, /)
     |      Return True if the string is a lowercase string, False otherwise.
     |
     |      A string is lowercase if all cased characters in the string are lowercase and
     |      there is at least one cased character in the string.
     |
     |  isnumeric(self, /)
     |      Return True if the string is a numeric string, False otherwise.
     |
     |      A string is numeric if all characters in the string are numeric and there is at
     |      least one character in the string.
     |
     |  isprintable(self, /)
     |      Return True if the string is printable, False otherwise.
     |
     |      A string is printable if all of its characters are considered printable in
     |      repr() or if it is empty.
     |
     |  isspace(self, /)
     |      Return True if the string is a whitespace string, False otherwise.
     |
     |      A string is whitespace if all characters in the string are whitespace and there
     |      is at least one character in the string.
     |
     |  istitle(self, /)
     |      Return True if the string is a title-cased string, False otherwise.
     |
     |      In a title-cased string, upper- and title-case characters may only
     |      follow uncased characters and lowercase characters only cased ones.
     |
     |  isupper(self, /)
     |      Return True if the string is an uppercase string, False otherwise.
     |
     |      A string is uppercase if all cased characters in the string are uppercase and
     |      there is at least one cased character in the string.
     |
     |  join(self, iterable, /)
     |      Concatenate any number of strings.
     |
     |      The string whose method is called is inserted in between each given string.
     |      The result is returned as a new string.
     |
     |      Example: '.'.join(['ab', 'pq', 'rs']) -> 'ab.pq.rs'
     |
     |  ljust(self, width, fillchar=' ', /)
     |      Return a left-justified string of length width.
     |
     |      Padding is done using the specified fill character (default is a space).
     |
     |  lower(self, /)
     |      Return a copy of the string converted to lowercase.
     |
     |  lstrip(self, chars=None, /)
     |      Return a copy of the string with leading whitespace removed.
     |
     |      If chars is given and not None, remove characters in chars instead.
     |
     |  partition(self, sep, /)
     |      Partition the string into three parts using the given separator.
     |
     |      This will search for the separator in the string.  If the separator is found,
     |      returns a 3-tuple containing the part before the separator, the separator
     |      itself, and the part after it.
     |
     |      If the separator is not found, returns a 3-tuple containing the original string
     |      and two empty strings.
     |
     |  removeprefix(self, prefix, /)
     |      Return a str with the given prefix string removed if present.
     |
     |      If the string starts with the prefix string, return string[len(prefix):].
     |      Otherwise, return a copy of the original string.
     |
     |  removesuffix(self, suffix, /)
     |      Return a str with the given suffix string removed if present.
     |
     |      If the string ends with the suffix string and that suffix is not empty,
     |      return string[:-len(suffix)]. Otherwise, return a copy of the original
     |      string.
     |
     |  replace(self, old, new, count=-1, /)
     |      Return a copy with all occurrences of substring old replaced by new.
     |
     |        count
     |          Maximum number of occurrences to replace.
     |          -1 (the default value) means replace all occurrences.
     |
     |      If the optional argument count is given, only the first count occurrences are
     |      replaced.
     |
     |  rfind(...)
     |      S.rfind(sub[, start[, end]]) -> int
     |
     |      Return the highest index in S where substring sub is found,
     |      such that sub is contained within S[start:end].  Optional
     |      arguments start and end are interpreted as in slice notation.
     |
     |      Return -1 on failure.
     |
     |  rindex(...)
     |      S.rindex(sub[, start[, end]]) -> int
     |
     |      Return the highest index in S where substring sub is found,
     |      such that sub is contained within S[start:end].  Optional
     |      arguments start and end are interpreted as in slice notation.
     |
     |      Raises ValueError when the substring is not found.
     |
     |  rjust(self, width, fillchar=' ', /)
     |      Return a right-justified string of length width.
     |
     |      Padding is done using the specified fill character (default is a space).
     |
     |  rpartition(self, sep, /)
     |      Partition the string into three parts using the given separator.
     |
     |      This will search for the separator in the string, starting at the end. If
     |      the separator is found, returns a 3-tuple containing the part before the
     |      separator, the separator itself, and the part after it.
     |
     |      If the separator is not found, returns a 3-tuple containing two empty strings
     |      and the original string.
     |
     |  rsplit(self, /, sep=None, maxsplit=-1)
     |      Return a list of the substrings in the string, using sep as the separator string.
     |
     |        sep
     |          The separator used to split the string.
     |
     |          When set to None (the default value), will split on any whitespace
     |          character (including \n \r \t \f and spaces) and will discard
     |          empty strings from the result.
     |        maxsplit
     |          Maximum number of splits.
     |          -1 (the default value) means no limit.
     |
     |      Splitting starts at the end of the string and works to the front.
     |
     |  rstrip(self, chars=None, /)
     |      Return a copy of the string with trailing whitespace removed.
     |
     |      If chars is given and not None, remove characters in chars instead.
     |
     |  split(self, /, sep=None, maxsplit=-1)
     |      Return a list of the substrings in the string, using sep as the separator string.
     |
     |        sep
     |          The separator used to split the string.
     |
     |          When set to None (the default value), will split on any whitespace
     |          character (including \n \r \t \f and spaces) and will discard
     |          empty strings from the result.
     |        maxsplit
     |          Maximum number of splits.
     |          -1 (the default value) means no limit.
     |
     |      Splitting starts at the front of the string and works to the end.
     |
     |      Note, str.split() is mainly useful for data that has been intentionally
     |      delimited.  With natural text that includes punctuation, consider using
     |      the regular expression module.
     |
     |  splitlines(self, /, keepends=False)
     |      Return a list of the lines in the string, breaking at line boundaries.
     |
     |      Line breaks are not included in the resulting list unless keepends is given and
     |      true.
     |
     |  startswith(...)
     |      S.startswith(prefix[, start[, end]]) -> bool
     |
     |      Return True if S starts with the specified prefix, False otherwise.
     |      With optional start, test S beginning at that position.
     |      With optional end, stop comparing S at that position.
     |      prefix can also be a tuple of strings to try.
     |
     |  strip(self, chars=None, /)
     |      Return a copy of the string with leading and trailing whitespace removed.
     |
     |      If chars is given and not None, remove characters in chars instead.
     |
     |  swapcase(self, /)
     |      Convert uppercase characters to lowercase and lowercase characters to uppercase.
     |
     |  title(self, /)
     |      Return a version of the string where each word is titlecased.
     |
     |      More specifically, words start with uppercased characters and all remaining
     |      cased characters have lower case.
     |
     |  translate(self, table, /)
     |      Replace each character in the string using the given translation table.
     |
     |        table
     |          Translation table, which must be a mapping of Unicode ordinals to
     |          Unicode ordinals, strings, or None.
     |
     |      The table must implement lookup/indexing via __getitem__, for instance a
     |      dictionary or list.  If this operation raises LookupError, the character is
     |      left untouched.  Characters mapped to None are deleted.
     |
     |  upper(self, /)
     |      Return a copy of the string converted to uppercase.
     |
     |  zfill(self, width, /)
     |      Pad a numeric string with zeros on the left, to fill a field of the given width.
     |
     |      The string is never truncated.
     |
     |  ----------------------------------------------------------------------
     |  Static methods inherited from builtins.str:
     |
     |  maketrans(...)
     |      Return a translation table usable for str.translate().
     |
     |      If there is only one argument, it must be a dictionary mapping Unicode
     |      ordinals (integers) or characters to Unicode ordinals, strings or None.
     |      Character keys will be then converted to ordinals.
     |      If there are two arguments, they must be strings of equal length, and
     |      in the resulting dictionary, each character in x will be mapped to the
     |      character at the same position in y. If there is a third argument, it
     |      must be a string, whose characters will be mapped to None in the result.
     |
     |  ----------------------------------------------------------------------
     |  Methods inherited from enum.Enum:
     |
     |  __dir__(self)
     |      Returns public methods and other interesting attributes.
     |
     |  __init__(self, *args, **kwds)
     |      Initialize self.  See help(type(self)) for accurate signature.
     |
     |  __reduce_ex__(self, proto)
     |      Helper for pickle.
     |
     |  ----------------------------------------------------------------------
     |  Data descriptors inherited from enum.Enum:
     |
     |  name
     |      The name of the Enum member.
     |
     |  value
     |      The value of the Enum member.
     |
     |  ----------------------------------------------------------------------
     |  Readonly properties inherited from enum.EnumType:
     |
     |  __members__
     |      Returns a mapping of member name->value.
     |
     |      This mapping lists all enum members, including aliases. Note that this
     |      is a read-only view of the internal mapping.

    class MilvusDBConfig(pydantic.main.BaseModel)
     |  MilvusDBConfig(*, url: str = 'http://localhost:19530', token: str = None, collection_name: str = 'mem0', embedding_model_dims: int = 1536, metric_type: str = 'L2') -> None
     |
     |  Method resolution order:
     |      MilvusDBConfig
     |      pydantic.main.BaseModel
     |      builtins.object
     |
     |  Class methods defined here:
     |
     |  validate_extra_fields(values: Dict[str, Any]) -> Dict[str, Any]
     |
     |  ----------------------------------------------------------------------
     |  Data descriptors defined here:
     |
     |  __weakref__
     |      list of weak references to the object
     |
     |  ----------------------------------------------------------------------
     |  Data and other attributes defined here:
     |
     |  __abstractmethods__ = frozenset()
     |
     |  __annotations__ = {'collection_name': <class 'str'>, 'embedding_model_...
     |
     |  __class_vars__ = set()
     |
     |  __private_attributes__ = {}
     |
     |  __pydantic_complete__ = True
     |
     |  __pydantic_computed_fields__ = {}
     |
     |  __pydantic_core_schema__ = {'cls': <class 'milvus.MilvusDBConfig'>, 'c...
     |
     |  __pydantic_custom_init__ = False
     |
     |  __pydantic_decorators__ = DecoratorInfos(validators={}, field_validato...
     |
     |  __pydantic_fields__ = {'collection_name': FieldInfo(annotation=str, re...
     |
     |  __pydantic_generic_metadata__ = {'args': (), 'origin': None, 'paramete...
     |
     |  __pydantic_parent_namespace__ = None
     |
     |  __pydantic_post_init__ = None
     |
     |  __pydantic_serializer__ = SchemaSerializer(serializer=Model(
     |      Model...
     |
     |  __pydantic_setattr_handlers__ = {}
     |
     |  __pydantic_validator__ = SchemaValidator(title="MilvusDBConfig", valid...
     |
     |  __signature__ = <Signature (*, url: str = 'http://localhost:1953...ms:...
     |
     |  model_config = {'arbitrary_types_allowed': True}
     |
     |  ----------------------------------------------------------------------
     |  Methods inherited from pydantic.main.BaseModel:
     |
     |  __copy__(self) -> 'Self'
     |      Returns a shallow copy of the model.
     |
     |  __deepcopy__(self, memo: 'dict[int, Any] | None' = None) -> 'Self'
     |      Returns a deep copy of the model.
     |
     |  __delattr__(self, item: 'str') -> 'Any'
     |      Implement delattr(self, name).
     |
     |  __eq__(self, other: 'Any') -> 'bool'
     |      Return self==value.
     |
     |  __getattr__(self, item: 'str') -> 'Any'
     |
     |  __getstate__(self) -> 'dict[Any, Any]'
     |      Helper for pickle.
     |
     |  __init__(self, /, **data: 'Any') -> 'None'
     |      Create a new model by parsing and validating input data from keyword arguments.
     |
     |      Raises [`ValidationError`][pydantic_core.ValidationError] if the input data cannot be
     |      validated to form a valid model.
     |
     |      `self` is explicitly positional-only to allow `self` as a field name.
     |
     |  __iter__(self) -> 'TupleGenerator'
     |      So `dict(model)` works.
     |
     |  __pretty__(self, fmt: 'typing.Callable[[Any], Any]', **kwargs: 'Any') -> 'typing.Generator[Any, None, None]' from pydantic._internal._repr.Representation
     |      Used by devtools (https://python-devtools.helpmanual.io/) to pretty print objects.
     |
     |  __replace__(self, **changes: 'Any') -> 'Self'
     |      # Because we make use of `@dataclass_transform()`, `__replace__` is already synthesized by
     |      # type checkers, so we define the implementation in this `if not TYPE_CHECKING:` block:
     |
     |  __repr__(self) -> 'str'
     |      Return repr(self).
     |
     |  __repr_args__(self) -> '_repr.ReprArgs'
     |
     |  __repr_name__(self) -> 'str' from pydantic._internal._repr.Representation
     |      Name of the instance's class, used in __repr__.
     |
     |  __repr_recursion__(self, object: 'Any') -> 'str' from pydantic._internal._repr.Representation
     |      Returns the string representation of a recursive object.
     |
     |  __repr_str__(self, join_str: 'str') -> 'str' from pydantic._internal._repr.Representation
     |
     |  __rich_repr__(self) -> 'RichReprResult' from pydantic._internal._repr.Representation
     |      Used by Rich (https://rich.readthedocs.io/en/stable/pretty.html) to pretty print objects.
     |
     |  __setattr__(self, name: 'str', value: 'Any') -> 'None'
     |      Implement setattr(self, name, value).
     |
     |  __setstate__(self, state: 'dict[Any, Any]') -> 'None'
     |
     |  __str__(self) -> 'str'
     |      Return str(self).
     |
     |  copy(self, *, include: 'AbstractSetIntStr | MappingIntStrAny | None' = None, exclude: 'AbstractSetIntStr | MappingIntStrAny | None' = None, update: 'Dict[str, Any] | None' = None, deep: 'bool' = False) -> 'Self'
     |      Returns a copy of the model.
     |
     |      !!! warning "Deprecated"
     |          This method is now deprecated; use `model_copy` instead.
     |
     |      If you need `include` or `exclude`, use:
     |
     |      ```python {test="skip" lint="skip"}
     |      data = self.model_dump(include=include, exclude=exclude, round_trip=True)
     |      data = {**data, **(update or {})}
     |      copied = self.model_validate(data)
     |      ```
     |
     |      Args:
     |          include: Optional set or mapping specifying which fields to include in the copied model.
     |          exclude: Optional set or mapping specifying which fields to exclude in the copied model.
     |          update: Optional dictionary of field-value pairs to override field values in the copied model.
     |          deep: If True, the values of fields that are Pydantic models will be deep-copied.
     |
     |      Returns:
     |          A copy of the model with included, excluded and updated fields as specified.
     |
     |  dict(self, *, include: 'IncEx | None' = None, exclude: 'IncEx | None' = None, by_alias: 'bool' = False, exclude_unset: 'bool' = False, exclude_defaults: 'bool' = False, exclude_none: 'bool' = False) -> 'Dict[str, Any]'
     |
     |  json(self, *, include: 'IncEx | None' = None, exclude: 'IncEx | None' = None, by_alias: 'bool' = False, exclude_unset: 'bool' = False, exclude_defaults: 'bool' = False, exclude_none: 'bool' = False, encoder: 'Callable[[Any], Any] | None' = PydanticUndefined, models_as_dict: 'bool' = PydanticUndefined, **dumps_kwargs: 'Any') -> 'str'
     |
     |  model_copy(self, *, update: 'Mapping[str, Any] | None' = None, deep: 'bool' = False) -> 'Self'
     |      !!! abstract "Usage Documentation"
     |          [`model_copy`](../concepts/serialization.md#model_copy)
     |
     |      Returns a copy of the model.
     |
     |      !!! note
     |          The underlying instance's [`__dict__`][object.__dict__] attribute is copied. This
     |          might have unexpected side effects if you store anything in it, on top of the model
     |          fields (e.g. the value of [cached properties][functools.cached_property]).
     |
     |      Args:
     |          update: Values to change/add in the new model. Note: the data is not validated
     |              before creating the new model. You should trust this data.
     |          deep: Set to `True` to make a deep copy of the model.
     |
     |      Returns:
     |          New model instance.
     |
     |  model_dump(self, *, mode: "Literal['json', 'python'] | str" = 'python', include: 'IncEx | None' = None, exclude: 'IncEx | None' = None, context: 'Any | None' = None, by_alias: 'bool | None' = None, exclude_unset: 'bool' = False, exclude_defaults: 'bool' = False, exclude_none: 'bool' = False, round_trip: 'bool' = False, warnings: "bool | Literal['none', 'warn', 'error']" = True, fallback: 'Callable[[Any], Any] | None' = None, serialize_as_any: 'bool' = False) -> 'dict[str, Any]'
     |      !!! abstract "Usage Documentation"
     |          [`model_dump`](../concepts/serialization.md#modelmodel_dump)
     |
     |      Generate a dictionary representation of the model, optionally specifying which fields to include or exclude.
     |
     |      Args:
     |          mode: The mode in which `to_python` should run.
     |              If mode is 'json', the output will only contain JSON serializable types.
     |              If mode is 'python', the output may contain non-JSON-serializable Python objects.
     |          include: A set of fields to include in the output.
     |          exclude: A set of fields to exclude from the output.
     |          context: Additional context to pass to the serializer.
     |          by_alias: Whether to use the field's alias in the dictionary key if defined.
     |          exclude_unset: Whether to exclude fields that have not been explicitly set.
     |          exclude_defaults: Whether to exclude fields that are set to their default value.
     |          exclude_none: Whether to exclude fields that have a value of `None`.
     |          round_trip: If True, dumped values should be valid as input for non-idempotent types such as Json[T].
     |          warnings: How to handle serialization errors. False/"none" ignores them, True/"warn" logs errors,
     |              "error" raises a [`PydanticSerializationError`][pydantic_core.PydanticSerializationError].
     |          fallback: A function to call when an unknown value is encountered. If not provided,
     |              a [`PydanticSerializationError`][pydantic_core.PydanticSerializationError] error is raised.
     |          serialize_as_any: Whether to serialize fields with duck-typing serialization behavior.
     |
     |      Returns:
     |          A dictionary representation of the model.
     |
     |  model_dump_json(self, *, indent: 'int | None' = None, include: 'IncEx | None' = None, exclude: 'IncEx | None' = None, context: 'Any | None' = None, by_alias: 'bool | None' = None, exclude_unset: 'bool' = False, exclude_defaults: 'bool' = False, exclude_none: 'bool' = False, round_trip: 'bool' = False, warnings: "bool | Literal['none', 'warn', 'error']" = True, fallback: 'Callable[[Any], Any] | None' = None, serialize_as_any: 'bool' = False) -> 'str'
     |      !!! abstract "Usage Documentation"
     |          [`model_dump_json`](../concepts/serialization.md#modelmodel_dump_json)
     |
     |      Generates a JSON representation of the model using Pydantic's `to_json` method.
     |
     |      Args:
     |          indent: Indentation to use in the JSON output. If None is passed, the output will be compact.
     |          include: Field(s) to include in the JSON output.
     |          exclude: Field(s) to exclude from the JSON output.
     |          context: Additional context to pass to the serializer.
     |          by_alias: Whether to serialize using field aliases.
     |          exclude_unset: Whether to exclude fields that have not been explicitly set.
     |          exclude_defaults: Whether to exclude fields that are set to their default value.
     |          exclude_none: Whether to exclude fields that have a value of `None`.
     |          round_trip: If True, dumped values should be valid as input for non-idempotent types such as Json[T].
     |          warnings: How to handle serialization errors. False/"none" ignores them, True/"warn" logs errors,
     |              "error" raises a [`PydanticSerializationError`][pydantic_core.PydanticSerializationError].
     |          fallback: A function to call when an unknown value is encountered. If not provided,
     |              a [`PydanticSerializationError`][pydantic_core.PydanticSerializationError] error is raised.
     |          serialize_as_any: Whether to serialize fields with duck-typing serialization behavior.
     |
     |      Returns:
     |          A JSON string representation of the model.
     |
     |  model_post_init(self, context: 'Any', /) -> 'None'
     |      Override this method to perform additional initialization after `__init__` and `model_construct`.
     |      This is useful if you want to do some validation that requires the entire model to be initialized.
     |
     |  ----------------------------------------------------------------------
     |  Class methods inherited from pydantic.main.BaseModel:
     |
     |  __class_getitem__(typevar_values: 'type[Any] | tuple[type[Any], ...]') -> 'type[BaseModel] | _forward_ref.PydanticRecursiveRef'
     |
     |  __get_pydantic_core_schema__(source: 'type[BaseModel]', handler: 'GetCoreSchemaHandler', /) -> 'CoreSchema'
     |
     |  __get_pydantic_json_schema__(core_schema: 'CoreSchema', handler: 'GetJsonSchemaHandler', /) -> 'JsonSchemaValue'
     |      Hook into generating the model's JSON schema.
     |
     |      Args:
     |          core_schema: A `pydantic-core` CoreSchema.
     |              You can ignore this argument and call the handler with a new CoreSchema,
     |              wrap this CoreSchema (`{'type': 'nullable', 'schema': current_schema}`),
     |              or just call the handler with the original schema.
     |          handler: Call into Pydantic's internal JSON schema generation.
     |              This will raise a `pydantic.errors.PydanticInvalidForJsonSchema` if JSON schema
     |              generation fails.
     |              Since this gets called by `BaseModel.model_json_schema` you can override the
     |              `schema_generator` argument to that function to change JSON schema generation globally
     |              for a type.
     |
     |      Returns:
     |          A JSON schema, as a Python object.
     |
     |  __pydantic_init_subclass__(**kwargs: 'Any') -> 'None'
     |      This is intended to behave just like `__init_subclass__`, but is called by `ModelMetaclass`
     |      only after the class is actually fully initialized. In particular, attributes like `model_fields` will
     |      be present when this is called.
     |
     |      This is necessary because `__init_subclass__` will always be called by `type.__new__`,
     |      and it would require a prohibitively large refactor to the `ModelMetaclass` to ensure that
     |      `type.__new__` was called in such a manner that the class would already be sufficiently initialized.
     |
     |      This will receive the same `kwargs` that would be passed to the standard `__init_subclass__`, namely,
     |      any kwargs passed to the class definition that aren't used internally by pydantic.
     |
     |      Args:
     |          **kwargs: Any keyword arguments passed to the class definition that aren't used internally
     |              by pydantic.
     |
     |  construct(_fields_set: 'set[str] | None' = None, **values: 'Any') -> 'Self'
     |
     |  from_orm(obj: 'Any') -> 'Self'
     |
     |  model_construct(_fields_set: 'set[str] | None' = None, **values: 'Any') -> 'Self'
     |      Creates a new instance of the `Model` class with validated data.
     |
     |      Creates a new model setting `__dict__` and `__pydantic_fields_set__` from trusted or pre-validated data.
     |      Default values are respected, but no other validation is performed.
     |
     |      !!! note
     |          `model_construct()` generally respects the `model_config.extra` setting on the provided model.
     |          That is, if `model_config.extra == 'allow'`, then all extra passed values are added to the model instance's `__dict__`
     |          and `__pydantic_extra__` fields. If `model_config.extra == 'ignore'` (the default), then all extra passed values are ignored.
     |          Because no validation is performed with a call to `model_construct()`, having `model_config.extra == 'forbid'` does not result in
     |          an error if extra values are passed, but they will be ignored.
     |
     |      Args:
     |          _fields_set: A set of field names that were originally explicitly set during instantiation. If provided,
     |              this is directly used for the [`model_fields_set`][pydantic.BaseModel.model_fields_set] attribute.
     |              Otherwise, the field names from the `values` argument will be used.
     |          values: Trusted or pre-validated data dictionary.
     |
     |      Returns:
     |          A new instance of the `Model` class with validated data.
     |
     |  model_json_schema(by_alias: 'bool' = True, ref_template: 'str' = '#/$defs/{model}', schema_generator: 'type[GenerateJsonSchema]' = <class 'pydantic.json_schema.GenerateJsonSchema'>, mode: 'JsonSchemaMode' = 'validation') -> 'dict[str, Any]'
     |      Generates a JSON schema for a model class.
     |
     |      Args:
     |          by_alias: Whether to use attribute aliases or not.
     |          ref_template: The reference template.
     |          schema_generator: To override the logic used to generate the JSON schema, as a subclass of
     |              `GenerateJsonSchema` with your desired modifications
     |          mode: The mode in which to generate the schema.
     |
     |      Returns:
     |          The JSON schema for the given model class.
     |
     |  model_parametrized_name(params: 'tuple[type[Any], ...]') -> 'str'
     |      Compute the class name for parametrizations of generic classes.
     |
     |      This method can be overridden to achieve a custom naming scheme for generic BaseModels.
     |
     |      Args:
     |          params: Tuple of types of the class. Given a generic class
     |              `Model` with 2 type variables and a concrete model `Model[str, int]`,
     |              the value `(str, int)` would be passed to `params`.
     |
     |      Returns:
     |          String representing the new class where `params` are passed to `cls` as type variables.
     |
     |      Raises:
     |          TypeError: Raised when trying to generate concrete names for non-generic models.
     |
     |  model_rebuild(*, force: 'bool' = False, raise_errors: 'bool' = True, _parent_namespace_depth: 'int' = 2, _types_namespace: 'MappingNamespace | None' = None) -> 'bool | None'
     |      Try to rebuild the pydantic-core schema for the model.
     |
     |      This may be necessary when one of the annotations is a ForwardRef which could not be resolved during
     |      the initial attempt to build the schema, and automatic rebuilding fails.
     |
     |      Args:
     |          force: Whether to force the rebuilding of the model schema, defaults to `False`.
     |          raise_errors: Whether to raise errors, defaults to `True`.
     |          _parent_namespace_depth: The depth level of the parent namespace, defaults to 2.
     |          _types_namespace: The types namespace, defaults to `None`.
     |
     |      Returns:
     |          Returns `None` if the schema is already "complete" and rebuilding was not required.
     |          If rebuilding _was_ required, returns `True` if rebuilding was successful, otherwise `False`.
     |
     |  model_validate(obj: 'Any', *, strict: 'bool | None' = None, from_attributes: 'bool | None' = None, context: 'Any | None' = None, by_alias: 'bool | None' = None, by_name: 'bool | None' = None) -> 'Self'
     |      Validate a pydantic model instance.
     |
     |      Args:
     |          obj: The object to validate.
     |          strict: Whether to enforce types strictly.
     |          from_attributes: Whether to extract data from object attributes.
     |          context: Additional context to pass to the validator.
     |          by_alias: Whether to use the field's alias when validating against the provided input data.
     |          by_name: Whether to use the field's name when validating against the provided input data.
     |
     |      Raises:
     |          ValidationError: If the object could not be validated.
     |
     |      Returns:
     |          The validated model instance.
     |
     |  model_validate_json(json_data: 'str | bytes | bytearray', *, strict: 'bool | None' = None, context: 'Any | None' = None, by_alias: 'bool | None' = None, by_name: 'bool | None' = None) -> 'Self'
     |      !!! abstract "Usage Documentation"
     |          [JSON Parsing](../concepts/json.md#json-parsing)
     |
     |      Validate the given JSON data against the Pydantic model.
     |
     |      Args:
     |          json_data: The JSON data to validate.
     |          strict: Whether to enforce types strictly.
     |          context: Extra variables to pass to the validator.
     |          by_alias: Whether to use the field's alias when validating against the provided input data.
     |          by_name: Whether to use the field's name when validating against the provided input data.
     |
     |      Returns:
     |          The validated Pydantic model.
     |
     |      Raises:
     |          ValidationError: If `json_data` is not a JSON string or the object could not be validated.
     |
     |  model_validate_strings(obj: 'Any', *, strict: 'bool | None' = None, context: 'Any | None' = None, by_alias: 'bool | None' = None, by_name: 'bool | None' = None) -> 'Self'
     |      Validate the given object with string data against the Pydantic model.
     |
     |      Args:
     |          obj: The object containing string data to validate.
     |          strict: Whether to enforce types strictly.
     |          context: Extra variables to pass to the validator.
     |          by_alias: Whether to use the field's alias when validating against the provided input data.
     |          by_name: Whether to use the field's name when validating against the provided input data.
     |
     |      Returns:
     |          The validated Pydantic model.
     |
     |  parse_file(path: 'str | Path', *, content_type: 'str | None' = None, encoding: 'str' = 'utf8', proto: 'DeprecatedParseProtocol | None' = None, allow_pickle: 'bool' = False) -> 'Self'
     |
     |  parse_obj(obj: 'Any') -> 'Self'
     |
     |  parse_raw(b: 'str | bytes', *, content_type: 'str | None' = None, encoding: 'str' = 'utf8', proto: 'DeprecatedParseProtocol | None' = None, allow_pickle: 'bool' = False) -> 'Self'
     |
     |  schema(by_alias: 'bool' = True, ref_template: 'str' = '#/$defs/{model}') -> 'Dict[str, Any]'
     |
     |  schema_json(*, by_alias: 'bool' = True, ref_template: 'str' = '#/$defs/{model}', **dumps_kwargs: 'Any') -> 'str'
     |
     |  update_forward_refs(**localns: 'Any') -> 'None'
     |
     |  validate(value: 'Any') -> 'Self'
     |
     |  ----------------------------------------------------------------------
     |  Readonly properties inherited from pydantic.main.BaseModel:
     |
     |  __fields_set__
     |
     |  model_extra
     |      Get extra fields set during validation.
     |
     |      Returns:
     |          A dictionary of extra fields, or `None` if `config.extra` is not set to `"allow"`.
     |
     |  model_fields_set
     |      Returns the set of fields that have been explicitly set on this model instance.
     |
     |      Returns:
     |          A set of strings representing the fields that have been set,
     |              i.e. that were not filled from defaults.
     |
     |  ----------------------------------------------------------------------
     |  Data descriptors inherited from pydantic.main.BaseModel:
     |
     |  __dict__
     |      dictionary for instance variables
     |
     |  __pydantic_extra__
     |
     |  __pydantic_fields_set__
     |
     |  __pydantic_private__
     |
     |  ----------------------------------------------------------------------
     |  Data and other attributes inherited from pydantic.main.BaseModel:
     |
     |  __hash__ = None
     |
     |  __pydantic_root_model__ = False
     |
     |  model_computed_fields = {}
     |
     |  model_fields = {'collection_name': FieldInfo(annotation=str, required=...

DATA
    Dict = typing.Dict
        A generic version of dict.

FILE
    d:\do\web\n8n_tests\projets\email_sender_1\mem0-analysis\repo\mem0\configs\vector_stores\milvus.py


