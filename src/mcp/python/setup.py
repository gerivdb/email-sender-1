from setuptools import setup, find_packages

with open("README.md", "r", encoding="utf-8") as fh:
    long_description = fh.read()

setup(
    name="pymcpfy",
    version="0.1.0",
    author="Nimesh Kiran Verma",
    author_email="nimesh.aug11@gmail.com",
    description="A Python library to expose web framework APIs via Model Context Protocol (MCP)",
    long_description=long_description,
    long_description_content_type="text/markdown",
    url="https://github.com/nimeshkverma/pymcpfy",
    packages=find_packages(),
    classifiers=[
        "Development Status :: 3 - Alpha",
        "Intended Audience :: Developers",
        "License :: OSI Approved :: MIT License",
        "Operating System :: OS Independent",
        "Programming Language :: Python :: 3",
        "Programming Language :: Python :: 3.8",
        "Programming Language :: Python :: 3.9",
        "Programming Language :: Python :: 3.10",
        "Programming Language :: Python :: 3.11",
    ],
    python_requires=">=3.8",
    install_requires=[
        "mcp>=0.1.0",  # Base MCP SDK
        "pydantic>=2.0.0",
        "typing-extensions>=4.0.0",
        "PyYAML>=6.0",
        "websockets>=10.0",
    ],
    extras_require={
        "django": ["django>=3.2"],
        "flask": ["flask>=2.0.0"],
        "fastapi": ["fastapi>=0.70.0", "uvicorn>=0.15.0"],
        "dev": [
            "pytest>=7.0.0",
            "pytest-asyncio>=0.18.0",
            "pytest-cov>=3.0.0",
            "black>=22.0.0",
            "isort>=5.0.0",
            "mypy>=0.900",
            "flake8>=4.0.0",
        ],
    },
)