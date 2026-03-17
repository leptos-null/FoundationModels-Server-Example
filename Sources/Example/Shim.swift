import Foundation
import FoundationModels

// These declarations act as interfaces for private API in `FoundationModels`
//
// Reconstructed based on outputs from:
//   `ipsw swift-dump /System/Volumes/Preboot/Cryptexes/OS/System/Library/dyld/dyld_shared_cache_arm64e /System/Library/Frameworks/FoundationModels.framework/Versions/A/FoundationModels --demangle`
// and
//   `swift demangle < "$(xcrun --sdk macosx --show-sdk-path)"/System/Library/Frameworks/FoundationModels.framework/FoundationModels.tbd`
//   (`dyld_info -function_starts /System/Library/Frameworks/FoundationModels.framework/FoundationModels | swift demangle` shows similar info)
//
// Thanks to <https://swiftrocks.com/using-silgenname-to-call-private-swift-code> for the info on `_silgen_name` to "forward declare" Swift functions

public struct ServerLanguageModel {
    public struct `Protocol`: Equatable {
        enum Kind {
            case openAI
        }
        
        let kind: Self.Kind
        
        public static var openAICompletions: Self {
            @_silgen_name("$s16FoundationModels19ServerLanguageModelV8ProtocolV17openAICompletionsAEvgZ")
            get
        }
        
        @_silgen_name("$s16FoundationModels19ServerLanguageModelV8ProtocolV2eeoiySbAE_AEtFZ")
        public static func == (lhs: Self, rhs: Self) -> Bool
    }
    
    let model: String
    let url: URL
    let headers: [String: String]
    let `protocol`: Self.`Protocol`
    let authenticator: Authenticator?
    let supportsGuidedGeneration: Bool
    
    @_silgen_name("$s16FoundationModels19ServerLanguageModelV4name3url7headers8protocolACSS_0A03URLVSDyS2SGAC8ProtocolVtcfC")
    public init(name: String, url: URL, headers: [String: String], protocol: Self.`Protocol`)
}

extension ServerLanguageModel {
    protocol Authenticator {
        // not sure what the requirements are
    }
}

extension LanguageModelSession {
    @_silgen_name("$s16FoundationModels20LanguageModelSessionC5model5tools10transcriptAcA06ServercD0V_SayAA4Tool_pGAA10TranscriptVtcfC")
    public convenience init(model: ServerLanguageModel, tools: [any Tool] = [], transcript: Transcript)
    
    @_silgen_name("$s16FoundationModels20LanguageModelSessionC5model5tools12instructionsAcA06ServercD0V_SayAA4Tool_pGAA12InstructionsVSgtcfC")
    public convenience init(model: ServerLanguageModel, tools: [any Tool] = [], instructions: Instructions? = nil)
}
