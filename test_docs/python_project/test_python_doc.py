"""
This is a test module for Python documentation.
It contains a simple class and a function.
"""

class MyClass:
    """
    A simple class to demonstrate Python documentation.
    
    Attributes:
        name (str): The name of the instance.
    """
    def __init__(self, name):
        self.name = name

    def greet(self, greeting="Hello"):
        """
        Greets the person with a given greeting.
        
        Args:
            greeting (str): The greeting message. Defaults to "Hello".
            
        Returns:
            str: The full greeting message.
        """
        return f"{greeting}, {self.name}!"

def multiply(a, b):
    """
    Multiplies two numbers.
    
    Args:
        a (int): The first number.
        b (int): The second number.
        
    Returns:
        int: The product of the two numbers.
    """
    return a * b