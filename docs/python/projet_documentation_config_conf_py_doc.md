Help on module conf:

NAME
    conf

DESCRIPTION
    # Configuration file for the Sphinx documentation builder.
    #
    # This file only contains a selection of the most common options. For a full
    # list see the documentation:
    # https://www.sphinx-doc.org/en/master/usage/configuration.html

FUNCTIONS
    extract_powershell_docs(module_name)
        Extract documentation from PowerShell module.

DATA
    author = 'EMAIL_SENDER_1 Team'
    autosummary_generate = True
    copyright = '2025, EMAIL_SENDER_1 Team'
    exclude_patterns = ['_build', 'Thumbs.db', '.DS_Store']
    extensions = ['sphinx.ext.autodoc', 'sphinx.ext.viewcode', 'sphinx.ext...
    html_context = {'extract_powershell_docs': <function extract_powershel...
    html_static_path = ['_static']
    html_theme = 'sphinx_rtd_theme'
    intersphinx_mapping = {'python': ('https://docs.python.org/3', None), ...
    master_doc = 'index'
    napoleon_google_docstring = True
    napoleon_include_init_with_doc = False
    napoleon_include_private_with_doc = False
    napoleon_include_special_with_doc = True
    napoleon_numpy_docstring = True
    napoleon_type_aliases = None
    napoleon_use_admonition_for_examples = False
    napoleon_use_admonition_for_notes = False
    napoleon_use_admonition_for_references = False
    napoleon_use_ivar = False
    napoleon_use_param = True
    napoleon_use_rtype = True
    powershell_modules = ['CycleDetector', 'DependencyManager', 'MCPManage...
    project = 'EMAIL_SENDER_1'
    release = '1.0.0'
    source_suffix = ['.rst', '.md']
    templates_path = ['_templates']
    todo_include_todos = True

FILE
    d:\do\web\n8n_tests\projets\email_sender_1\projet\documentation\config\conf.py


