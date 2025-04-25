// Sample JavaScript file
function greet(name) {
    return Hello, \!;
}

class Person {
    constructor(name, age) {
        this.name = name;
        this.age = age;
    }
    
    sayHello() {
        console.log(greet(this.name));
    }
}

const person = new Person('John', 30);
person.sayHello();

// Event listener
document.addEventListener('DOMContentLoaded', () => {
    console.log('Document loaded');
});