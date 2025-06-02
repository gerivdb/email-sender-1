
import coverage
cov = coverage.Coverage(
    source=["development.scripts.python.testing.examples"],
    omit=[
        "*/__pycache__/*",
        "*/site-packages/*",
    ],
    config_file='.coveragerc'
)
cov.start()

# Importe le module à tester
from development.scripts.python.testing.examples import test_example

# Lance tous les tests
import pytest
pytest.main(['development/scripts/python/testing/examples/test_example.py'])

# Arrête la couverture et génère un rapport
cov.stop()
cov.save()
percent = cov.report(include=['development/scripts/python/testing/examples/test_example.py'])
print(f"Total coverage: {percent}%")

