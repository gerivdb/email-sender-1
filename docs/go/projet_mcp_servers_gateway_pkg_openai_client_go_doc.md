# Package openai

## Types

### Client

Client wraps the OpenAI client with our configuration


#### Methods

##### Client.ChatCompletion

ChatCompletion handles chat completion requests


```go
func (c *Client) ChatCompletion(ctx context.Context, messages []openai.ChatCompletionMessageParamUnion) (*openai.ChatCompletion, error)
```

##### Client.ChatCompletionStream

ChatCompletionStream handles streaming chat completion requests


```go
func (c *Client) ChatCompletionStream(ctx context.Context, messages []openai.ChatCompletionMessageParamUnion, tools []openai.ChatCompletionToolParam) (*ssestream.Stream[openai.ChatCompletionChunk], error)
```

