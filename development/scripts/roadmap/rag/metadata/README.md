# Metadata Extraction and Normalization

This module provides tools for extracting and normalizing metadata from tags.

## Features

- **Approximate Expressions**: Detect and normalize approximate expressions like "about 10 days" or "environ 10 jours".
- **Textual Numbers**: Convert textual numbers like "twenty" or "vingt" to numeric values.
- **Time Units**: Detect and normalize time units like "10 days" or "10 jours".
- **Tag Normalization**: Normalize tags by replacing textual numbers with numeric values, normalizing approximate expressions, and standardizing time units.

## Usage

### Approximate Expressions

```python
from approximate_expressions import get_approximate_expressions

text = "Le projet prendra environ 10 jours."
results = get_approximate_expressions(text, "French")

for result in results:
    print(f"{result.expression}: {result.info['Value']} (±{result.info['Precision'] * 100}%)")
```plaintext
### Textual Numbers

```python
from textual_numbers import get_textual_numbers

text = "La première tâche prendra vingt jours."
results = get_textual_numbers(text, "French")

for result in results:
    print(f"{result.textual_number}: {result.numeric_value}")
```plaintext
### Time Units

```python
from time_units import get_time_units

text = "Le projet prendra 10 jours et 5 heures."
results = get_time_units(text, "French")

for result in results:
    print(f"{result.expression}: {result.info['Value']} {result.info['Unit']}")
```plaintext
### Tag Normalization

```python
from tag_normalizer import TagNormalizer

normalizer = TagNormalizer()
tag = "Projet de vingt jours environ"
result = normalizer.normalize_tag(tag)

print(f"Tag original: {tag}")
print(f"Tag normalisé: {result['normalized_tag']}")
```plaintext
## Supported Languages

- French
- English

## Performance

The module is optimized for performance and can process hundreds of tags per second.

## Examples

See the test scripts for more examples:

- `test_simple.py`: Test the basic features
- `test_all_features.py`: Test all features together
- `test_performance.py`: Test the performance of the module
- `test_real_data.py`: Test the module with real data
- `test_english_data.py`: Test the module with English data
