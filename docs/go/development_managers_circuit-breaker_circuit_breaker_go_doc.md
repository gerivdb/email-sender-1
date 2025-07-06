# Package circuitbreaker

Package circuitbreaker provides a unified circuit breaker implementation
for Section 1.4 - Implementation des Recommandations


## Types

### CircuitBreaker

CircuitBreaker implements the circuit breaker pattern with ErrorManager integration


#### Methods

##### CircuitBreaker.Execute

Execute executes a function with circuit breaker protection


```go
func (cb *CircuitBreaker) Execute(ctx context.Context, fn func() error) error
```

##### CircuitBreaker.ForceState

ForceState forces the circuit breaker to a specific state (for testing)


```go
func (cb *CircuitBreaker) ForceState(state State, reason string)
```

##### CircuitBreaker.Reset

Reset resets the circuit breaker to initial state


```go
func (cb *CircuitBreaker) Reset()
```

##### CircuitBreaker.SetStateChangeCallback

SetStateChangeCallback sets a callback for state changes


```go
func (cb *CircuitBreaker) SetStateChangeCallback(callback func(from, to State, reason string))
```

##### CircuitBreaker.State

State returns the current state


```go
func (cb *CircuitBreaker) State() State
```

##### CircuitBreaker.Stats

Stats returns current statistics


```go
func (cb *CircuitBreaker) Stats() map[string]interface{}
```

### Config

Config holds configuration for circuit breaker


### ErrorEntry

ErrorEntry represents an error entry for the ErrorManager


### ErrorManager

ErrorManager interface for error reporting


### State

State represents the current state of a circuit breaker


#### Methods

##### State.String

String returns string representation of the state


```go
func (s State) String() string
```

