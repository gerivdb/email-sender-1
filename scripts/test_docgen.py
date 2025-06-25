# scripts/test_docgen.py
# Tests unitaires pour DocGen (Phase 1)

import unittest
from docgen import DocGen

class TestDocGen(unittest.TestCase):
    def test_generate_docs(self):
        docgen = DocGen()
        try:
            docgen.generate_docs("./src")
        except Exception as e:
            self.fail(f"generate_docs a échoué: {e}")

    def test_export_diagrams(self):
        docgen = DocGen()
        try:
            docgen.export_diagrams("mermaid")
        except Exception as e:
            self.fail(f"export_diagrams a échoué: {e}")

if __name__ == "__main__":
    unittest.main()
