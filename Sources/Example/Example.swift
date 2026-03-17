import Foundation
import FoundationModels

@main
struct Example {
    static func main() async throws {
        // This code below is meant to be similar to the first code snippet in
        // <https://ai.google.dev/gemini-api/docs/openai>
        
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
}
