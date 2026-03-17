# FoundationModels-Server-Example

This repository demonstrates using private API in Apple's [Foundation Models](<https://developer.apple.com/documentation/FoundationModels>) framework to interact with HTTP servers exposing a [Chat Completions API](<https://platform.openai.com/docs/api-reference/chat>).

## Disclaimer

Usage of private API is discouraged because it could break at any time.

This repo serves only to explore the capabilities of the private API below.

## Private API

The API used in this repository looks like so:

```swift
public struct ServerLanguageModel {
    public struct `Protocol`: Equatable {
        public static var openAICompletions: Self { get }
    }
    
    public init(name: String, url: URL, headers: [String: String], protocol: Self.`Protocol`)
}

extension LanguageModelSession {
    public convenience init(model: ServerLanguageModel, tools: [any Tool] = [], transcript: Transcript)
    public convenience init(model: ServerLanguageModel, tools: [any Tool] = [], instructions: Instructions? = nil)
}
```

See [`Sources/Example/Shim.swift`](./Sources/Example/Shim.swift) in this repo for more details.

## Usage

The following code is based off of the first code snippet on <https://ai.google.dev/gemini-api/docs/openai>:

```swift
static func main() async throws {
    guard let geminiCompletionsURL = URL(string: "https://generativelanguage.googleapis.com/v1beta/openai") else {
        fatalError("Failed to create URL for Gemini API")
    }
    guard let geminiApiKey: String = ProcessInfo.processInfo.environment["GEMINI_API_KEY"] else {
        fatalError("GEMINI_API_KEY must be set in the environment")
    }
    
    let geminiCompletionsHeaders: [String: String] = [
        "Content-Type": "application/json",
        "Authorization": "Bearer \(geminiApiKey)"
    ]
    
    let model = ServerLanguageModel(
        name: "gemini-3-flash-preview",
        url: geminiCompletionsURL,
        headers: geminiCompletionsHeaders,
        protocol: .openAICompletions
    )
    
    let instructions = Instructions {
        "You are a helpful assistant."
    }
    let languageModelSession = LanguageModelSession(model: model, instructions: instructions)
    
    let response = try await languageModelSession.respond(to: "Explain to me how AI works")
    print(response.content)
}
```

Similar code appears in [`Sources/Example/Example.swift`](./Sources/Example/Example.swift) in this repo.

## Compatibility

I tested the code above on an iPhone 13 mini running iOS 26.3 and it worked without errors (and produced an expected result).

Apple Intelligence is unavailable on the iPhone 13 mini, so this test shows that this private API does not require a device that supports Apple Intelligence (which makes sense, as it's mostly just making HTTP requests).

## Features

### Streaming

Response streaming seems to work via the various `streamResponse` functions on [`LanguageModelSession`](<https://developer.apple.com/documentation/foundationmodels/languagemodelsession>). I tested on macOS 26.3 using [`streamResponse(to:options:)`](<https://developer.apple.com/documentation/foundationmodels/languagemodelsession/streamresponse(to:options:)>) in particular.

### Structured output

Producing structured output seems to work using the provided functions.

Here's a sample, modifying the previous sample code above:

```swift
@Generable
struct Pet {
    @Guide(description: "The name of the pet, as referred to by other people.")
    let name: String
    
    @Guide(description: "The species of the pet")
    let species: String
    
    @Guide(description: "Age of the pet. Measured in Earth solar years.", .minimum(0))
    let age: Int
}
```

```swift
let response = try await languageModelSession.respond(to: "Please provide a few ideas for pets.", generating: [Pet].self)
```

The section below contains the payload sent for the request above (from testing on macOS 26.3)

<details>

<summary>Payload</summary>

```json
{
   "messages" : [
      {
         "content" : "You are a helpful assistant.",
         "role" : "system"
      },
      {
         "content" : "Please provide a few ideas for pets.",
         "role" : "user"
      }
   ],
   "model" : "gemini-3-flash-preview",
   "response_format" : {
      "json_schema" : {
         "name" : "Array<Pet>",
         "schema" : {
            "$defs" : {
               "Pet" : {
                  "additionalProperties" : false,
                  "properties" : {
                     "age" : {
                        "description" : "Age of the pet. Measured in Earth solar years.",
                        "minimum" : 0,
                        "type" : "integer"
                     },
                     "name" : {
                        "description" : "The name of the pet, as referred to by other people.",
                        "type" : "string"
                     },
                     "species" : {
                        "description" : "The species of the pet",
                        "type" : "string"
                     }
                  },
                  "required" : [
                     "name",
                     "species",
                     "age"
                  ],
                  "title" : "Pet",
                  "type" : "object",
                  "x-order" : [
                     "name",
                     "species",
                     "age"
                  ]
               }
            },
            "items" : {
               "$ref" : "#/$defs/Pet"
            },
            "type" : "array"
         },
         "strict" : true
      },
      "type" : "json_schema"
   },
   "stream" : true,
   "tools" : []
}
```

</details>

## Testing notes

### Function calling with Gemini

In my testing on macOS 26.3, function calling did not work using this API as the client and Gemini as the server.

Here's the code I tried:

```swift
// based on <https://ai.google.dev/gemini-api/docs/openai#function-calling>

struct WeatherTool: Tool {
    let name: String = "get_weather"
    let description: String = "Get the weather in a given location"
    
    @Generable
    enum Unit: String {
        case celsius
        case fahrenheit
    }
    
    @Generable
    struct Arguments {
        @Guide(description: "The city and state, e.g. Chicago, IL")
        let location: String
        
        let unit: Unit?
    }
    
    @Generable
    struct Output {
        let temperature: Double
        let unit: Unit
    }
    
    func call(arguments: Arguments) async throws -> Output {
        return .init(temperature: 25, unit: .celsius)
    }
}
```

```swift
let tools: [any Tool] = [
    WeatherTool(),
]
let languageModelSession = LanguageModelSession(model: model, tools: tools)

let response = try await languageModelSession.respond(to: "What's the weather like in Chicago today?")
```

This produced the following error:

```swift
DecodingError.keyNotFound(
    CodingKeys(stringValue: "index", intValue: nil),
    DecodingError.Context(
        codingPath: [
            CodingKeys(stringValue: "choices", intValue: nil),
            _CodingKey(stringValue: "Index 0", intValue: 0),
            CodingKeys(stringValue: "delta", intValue: nil),
            CodingKeys(stringValue: "tool_calls", intValue: nil),
            _CodingKey(stringValue: "Index 0", intValue: 0)
        ],
        debugDescription: "No value associated with key CodingKeys(stringValue: \"index\", intValue: nil) (\"index\").",
        underlyingError: nil
    )
)
```

The section below contains the underlying HTTP request and response payloads for the call above.

<details>

<summary>Payloads</summary>

Request:

```json
{
   "messages" : [
      {
         "content" : [],
         "role" : "system"
      },
      {
         "content" : "What's the weather like in Chicago today?",
         "role" : "user"
      }
   ],
   "model" : "gemini-3-flash-preview",
   "stream" : true,
   "tools" : [
      {
         "function" : {
            "description" : "Get the weather in a given location",
            "name" : "get_weather",
            "parameters" : {
               "additionalProperties" : false,
               "properties" : {
                  "location" : {
                     "description" : "The city and state, e.g. Chicago, IL",
                     "type" : "string"
                  },
                  "unit" : {
                     "enum" : [
                        "celsius",
                        "fahrenheit"
                     ],
                     "type" : "string"
                  }
               },
               "required" : [
                  "location"
               ],
               "title" : "Arguments",
               "type" : "object",
               "x-order" : [
                  "location",
                  "unit"
               ]
            }
         },
         "type" : "function"
      }
   ]
}
```

Response:

```json
{
   "choices" : [
      {
         "delta" : {
            "role" : "assistant",
            "tool_calls" : [
               {
                  "function" : {
                     "arguments" : "{\"location\":\"Chicago, IL\"}",
                     "name" : "get_weather"
                  },
                  "id" : "<redacted>",
                  "type" : "function"
               }
            ]
         },
         "index" : 0
      }
   ],
   "created" : 1773733688,
   "id" : "<redacted>",
   "model" : "gemini-3-flash-preview",
   "object" : "chat.completion.chunk"
}
```

</details>

We can see that the `Decodable` type that the `FoundationModels` framework is using to decode this JSON does not match the response from the Gemini API.

**The issue here appears to be on the Gemini side**. The spec for the HTTP API is here: <https://developers.openai.com/api/reference/resources/chat/subresources/completions/streaming-events>. Under `tool_calls`, the field `index` is a non-optional number.

### Using an MLX LM server

[MLX LM](<https://github.com/ml-explore/mlx-lm>) provides an HTTP server that's compatible with the Chat Completions API.

You can run this simply with `mlx_lm.server`. We can connect by using `http://localhost:8080/` as the `url` parameter to the `ServerLanguageModel` `init`.

Using `mlx-lm` version `0.31.1` and macOS 26.3, from what I can tell, as soon as the first response comes back from the server, the `respond(to:)` function returns, producing an empty response.

Even if I switch to the streaming API, the sequence ends up being empty:

```swift
let responseStream = languageModelSession.streamResponse(to: "Explain to me how AI works")
for try await snapshot in responseStream {
    print(snapshot.content)
}
```

If I connect to the same server using the [OpenAI Python library](<https://github.com/openai/openai-python>), and making the equivalent request, the responses appear to be as expected (using both streaming and non-streaming modes).
