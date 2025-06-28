console.log("This is a simple JavaScript file for Codacy CLI testing.");

function sum(a, b) {
  return a + b; // A simple function
}

// A potential issue: unused variable
const unusedVar = 10; 

// Another potential issue: console.log
console.log("Sum:", sum(5, 3));
