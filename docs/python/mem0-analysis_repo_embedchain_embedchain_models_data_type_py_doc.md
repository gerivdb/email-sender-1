Help on module data_type:

NAME
    data_type

CLASSES
    enum.Enum(builtins.object)
        DataType
        DirectDataType
        IndirectDataType
        SpecialDataType

    class DataType(enum.Enum)
     |  DataType(*values)
     |
     |  Method resolution order:
     |      DataType
     |      enum.Enum
     |      builtins.object
     |
     |  Data and other attributes defined here:
     |
     |  AUDIO = <DataType.AUDIO: 'audio'>
     |
     |  BEEHIIV = <DataType.BEEHIIV: 'beehiiv'>
     |
     |  CSV = <DataType.CSV: 'csv'>
     |
     |  CUSTOM = <DataType.CUSTOM: 'custom'>
     |
     |  DIRECTORY = <DataType.DIRECTORY: 'directory'>
     |
     |  DISCORD = <DataType.DISCORD: 'discord'>
     |
     |  DOCS_SITE = <DataType.DOCS_SITE: 'docs_site'>
     |
     |  DOCX = <DataType.DOCX: 'docx'>
     |
     |  DROPBOX = <DataType.DROPBOX: 'dropbox'>
     |
     |  EXCEL_FILE = <DataType.EXCEL_FILE: 'excel_file'>
     |
     |  GMAIL = <DataType.GMAIL: 'gmail'>
     |
     |  GOOGLE_DRIVE = <DataType.GOOGLE_DRIVE: 'google_drive'>
     |
     |  IMAGE = <DataType.IMAGE: 'image'>
     |
     |  JSON = <DataType.JSON: 'json'>
     |
     |  MDX = <DataType.MDX: 'mdx'>
     |
     |  NOTION = <DataType.NOTION: 'notion'>
     |
     |  OPENAPI = <DataType.OPENAPI: 'openapi'>
     |
     |  PDF_FILE = <DataType.PDF_FILE: 'pdf_file'>
     |
     |  QNA_PAIR = <DataType.QNA_PAIR: 'qna_pair'>
     |
     |  RSSFEED = <DataType.RSSFEED: 'rss_feed'>
     |
     |  SITEMAP = <DataType.SITEMAP: 'sitemap'>
     |
     |  SLACK = <DataType.SLACK: 'slack'>
     |
     |  SUBSTACK = <DataType.SUBSTACK: 'substack'>
     |
     |  TEXT = <DataType.TEXT: 'text'>
     |
     |  TEXT_FILE = <DataType.TEXT_FILE: 'text_file'>
     |
     |  UNSTRUCTURED = <DataType.UNSTRUCTURED: 'unstructured'>
     |
     |  WEB_PAGE = <DataType.WEB_PAGE: 'web_page'>
     |
     |  XML = <DataType.XML: 'xml'>
     |
     |  YOUTUBE_CHANNEL = <DataType.YOUTUBE_CHANNEL: 'youtube_channel'>
     |
     |  YOUTUBE_VIDEO = <DataType.YOUTUBE_VIDEO: 'youtube_video'>
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
     |  Static methods inherited from enum.EnumType:
     |
     |  __contains__(value)
     |      Return True if `value` is in `cls`.
     |
     |      `value` is in `cls` if:
     |      1) `value` is a member of `cls`, or
     |      2) `value` is the value of one of the `cls`'s members.
     |
     |  __getitem__(name)
     |      Return the member matching `name`.
     |
     |  __iter__()
     |      Return members in definition order.
     |
     |  __len__()
     |      Return the number of members (no aliases)
     |
     |  ----------------------------------------------------------------------
     |  Readonly properties inherited from enum.EnumType:
     |
     |  __members__
     |      Returns a mapping of member name->value.
     |
     |      This mapping lists all enum members, including aliases. Note that this
     |      is a read-only view of the internal mapping.

    class DirectDataType(enum.Enum)
     |  DirectDataType(*values)
     |
     |  DirectDataType enum contains data types that contain raw data directly.
     |
     |  Method resolution order:
     |      DirectDataType
     |      enum.Enum
     |      builtins.object
     |
     |  Data and other attributes defined here:
     |
     |  TEXT = <DirectDataType.TEXT: 'text'>
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
     |  Static methods inherited from enum.EnumType:
     |
     |  __contains__(value)
     |      Return True if `value` is in `cls`.
     |
     |      `value` is in `cls` if:
     |      1) `value` is a member of `cls`, or
     |      2) `value` is the value of one of the `cls`'s members.
     |
     |  __getitem__(name)
     |      Return the member matching `name`.
     |
     |  __iter__()
     |      Return members in definition order.
     |
     |  __len__()
     |      Return the number of members (no aliases)
     |
     |  ----------------------------------------------------------------------
     |  Readonly properties inherited from enum.EnumType:
     |
     |  __members__
     |      Returns a mapping of member name->value.
     |
     |      This mapping lists all enum members, including aliases. Note that this
     |      is a read-only view of the internal mapping.

    class IndirectDataType(enum.Enum)
     |  IndirectDataType(*values)
     |
     |  IndirectDataType enum contains data types that contain references to data stored elsewhere.
     |
     |  Method resolution order:
     |      IndirectDataType
     |      enum.Enum
     |      builtins.object
     |
     |  Data and other attributes defined here:
     |
     |  AUDIO = <IndirectDataType.AUDIO: 'audio'>
     |
     |  BEEHIIV = <IndirectDataType.BEEHIIV: 'beehiiv'>
     |
     |  CSV = <IndirectDataType.CSV: 'csv'>
     |
     |  CUSTOM = <IndirectDataType.CUSTOM: 'custom'>
     |
     |  DIRECTORY = <IndirectDataType.DIRECTORY: 'directory'>
     |
     |  DISCORD = <IndirectDataType.DISCORD: 'discord'>
     |
     |  DOCS_SITE = <IndirectDataType.DOCS_SITE: 'docs_site'>
     |
     |  DOCX = <IndirectDataType.DOCX: 'docx'>
     |
     |  DROPBOX = <IndirectDataType.DROPBOX: 'dropbox'>
     |
     |  EXCEL_FILE = <IndirectDataType.EXCEL_FILE: 'excel_file'>
     |
     |  GMAIL = <IndirectDataType.GMAIL: 'gmail'>
     |
     |  GOOGLE_DRIVE = <IndirectDataType.GOOGLE_DRIVE: 'google_drive'>
     |
     |  IMAGE = <IndirectDataType.IMAGE: 'image'>
     |
     |  JSON = <IndirectDataType.JSON: 'json'>
     |
     |  MDX = <IndirectDataType.MDX: 'mdx'>
     |
     |  NOTION = <IndirectDataType.NOTION: 'notion'>
     |
     |  OPENAPI = <IndirectDataType.OPENAPI: 'openapi'>
     |
     |  PDF_FILE = <IndirectDataType.PDF_FILE: 'pdf_file'>
     |
     |  RSSFEED = <IndirectDataType.RSSFEED: 'rss_feed'>
     |
     |  SITEMAP = <IndirectDataType.SITEMAP: 'sitemap'>
     |
     |  SLACK = <IndirectDataType.SLACK: 'slack'>
     |
     |  SUBSTACK = <IndirectDataType.SUBSTACK: 'substack'>
     |
     |  TEXT_FILE = <IndirectDataType.TEXT_FILE: 'text_file'>
     |
     |  UNSTRUCTURED = <IndirectDataType.UNSTRUCTURED: 'unstructured'>
     |
     |  WEB_PAGE = <IndirectDataType.WEB_PAGE: 'web_page'>
     |
     |  XML = <IndirectDataType.XML: 'xml'>
     |
     |  YOUTUBE_CHANNEL = <IndirectDataType.YOUTUBE_CHANNEL: 'youtube_channel'...
     |
     |  YOUTUBE_VIDEO = <IndirectDataType.YOUTUBE_VIDEO: 'youtube_video'>
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
     |  Static methods inherited from enum.EnumType:
     |
     |  __contains__(value)
     |      Return True if `value` is in `cls`.
     |
     |      `value` is in `cls` if:
     |      1) `value` is a member of `cls`, or
     |      2) `value` is the value of one of the `cls`'s members.
     |
     |  __getitem__(name)
     |      Return the member matching `name`.
     |
     |  __iter__()
     |      Return members in definition order.
     |
     |  __len__()
     |      Return the number of members (no aliases)
     |
     |  ----------------------------------------------------------------------
     |  Readonly properties inherited from enum.EnumType:
     |
     |  __members__
     |      Returns a mapping of member name->value.
     |
     |      This mapping lists all enum members, including aliases. Note that this
     |      is a read-only view of the internal mapping.

    class SpecialDataType(enum.Enum)
     |  SpecialDataType(*values)
     |
     |  SpecialDataType enum contains data types that are neither direct nor indirect, or simply require special attention.
     |
     |  Method resolution order:
     |      SpecialDataType
     |      enum.Enum
     |      builtins.object
     |
     |  Data and other attributes defined here:
     |
     |  QNA_PAIR = <SpecialDataType.QNA_PAIR: 'qna_pair'>
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
     |  Static methods inherited from enum.EnumType:
     |
     |  __contains__(value)
     |      Return True if `value` is in `cls`.
     |
     |      `value` is in `cls` if:
     |      1) `value` is a member of `cls`, or
     |      2) `value` is the value of one of the `cls`'s members.
     |
     |  __getitem__(name)
     |      Return the member matching `name`.
     |
     |  __iter__()
     |      Return members in definition order.
     |
     |  __len__()
     |      Return the number of members (no aliases)
     |
     |  ----------------------------------------------------------------------
     |  Readonly properties inherited from enum.EnumType:
     |
     |  __members__
     |      Returns a mapping of member name->value.
     |
     |      This mapping lists all enum members, including aliases. Note that this
     |      is a read-only view of the internal mapping.

FILE
    d:\do\web\n8n_tests\projets\email_sender_1\mem0-analysis\repo\embedchain\embedchain\models\data_type.py


