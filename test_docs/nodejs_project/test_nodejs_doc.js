/**
 * @file This is a test module for Node.js documentation.
 * It contains a simple class and a function.
 */

/**
 * Represents a simple class to demonstrate Node.js documentation.
 * @class
 */
class MyNodeClass {
    /**
     * Creates an instance of MyNodeClass.
     * @param {string} name - The name of the instance.
     */
    constructor(name) {
        this.name = name;
    }

    /**
     * Greets the person with a given greeting.
     * @param {string} [greeting="Hello"] - The greeting message.
     * @returns {string} The full greeting message.
     */
    greet(greeting = "Hello") {
        return `${greeting}, ${this.name}!`;
    }
}

/**
 * Divides two numbers.
 * @param {number} a - The first number.
 * @param {number} b - The second number.
 * @returns {number} The result of the division.
 */
function divide(a, b) {
    if (b === 0) {
        throw new Error("Cannot divide by zero.");
    }
    return a / b;
}

module.exports = { MyNodeClass, divide };