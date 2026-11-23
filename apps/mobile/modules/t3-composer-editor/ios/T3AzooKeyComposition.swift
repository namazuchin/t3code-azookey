import Foundation
#if canImport(KanaKanjiConverterModuleWithDefaultDictionary)
import KanaKanjiConverterModuleWithDefaultDictionary
#endif

// All state is provisional until takeCommit(); do not put it in the UITextView or the draft.
struct T3AzooKeyComposition {
  private(set) var roman = ""
  private(set) var candidates: [String] = []
  private(set) var candidateIndex = 0
  var isActive: Bool { !roman.isEmpty }

  mutating func append(_ letter: String) {
    roman += letter
    clearCandidates()
  }

  mutating func backspace() {
    if !roman.isEmpty { roman.removeLast() }
    clearCandidates()
  }

  mutating func convert(_ values: [String], kana: String) {
    var seen = Set<String>()
    candidates = (values + [kana]).filter { !$0.isEmpty && seen.insert($0).inserted }
    candidateIndex = 0
  }

  mutating func cycle(_ step: Int) {
    guard !candidates.isEmpty else { return }
    candidateIndex = (candidateIndex + step + candidates.count) % candidates.count
  }

  func preview(kana: String) -> String {
    guard isActive else { return "" }
    if candidates.isEmpty { return kana }
    return "\(candidates[candidateIndex])  \(candidateIndex + 1)/\(candidates.count)"
  }

  mutating func takeCommit(kana: String) -> String? {
    guard isActive else { return nil }
    let result = candidates.isEmpty ? kana : candidates[candidateIndex]
    self = Self()
    return result
  }

  private mutating func clearCandidates() {
    candidates = []
    candidateIndex = 0
  }
}

@MainActor
final class T3AzooKeyEngine {
  nonisolated static var isAvailable: Bool {
#if canImport(KanaKanjiConverterModuleWithDefaultDictionary) || T3_COMPOSER_TESTS
    true
#else
    false
#endif
  }

#if canImport(KanaKanjiConverterModuleWithDefaultDictionary)
  private lazy var converter = KanaKanjiConverter()
  private lazy var options = ConvertRequestOptions.withDefaultDictionary(
    N_best: 8,
    requireJapanesePrediction: false,
    requireEnglishPrediction: false,
    keyboardLanguage: .ja_JP,
    unicodeCandidate: false,
    learningType: .nothing,
    maxMemoryCount: 0,
    memoryDirectoryURL: FileManager.default.temporaryDirectory,
    sharedContainerURL: FileManager.default.temporaryDirectory,
    zenzaiMode: .off,
    metadata: nil
  )

  private func composing(_ roman: String) -> ComposingText {
    var input = ComposingText()
    input.insertAtCursorPosition(roman, inputStyle: .roman2kana)
    return input
  }

  func kana(_ roman: String, final: Bool = false) -> String {
    // A trailing n is ambiguous while typing, but means ん when committing.
    String(composing(final && roman.hasSuffix("n") && !roman.hasSuffix("nn") ? roman + "n" : roman).convertTarget)
  }

  func convert(_ roman: String) -> [String] {
    let input = composing(roman.hasSuffix("n") && !roman.hasSuffix("nn") ? roman + "n" : roman)
    return converter.requestCandidates(input, options: options).mainResults.map(\.text)
  }
#elseif T3_COMPOSER_TESTS
  func kana(_ roman: String, final: Bool = false) -> String { roman == "nihongo" ? "にほんご" : roman }
  func convert(_ roman: String) -> [String] { roman == "nihongo" ? ["日本語", "にほんご"] : [] }
#else
  func kana(_ roman: String, final: Bool = false) -> String { roman }
  func convert(_ roman: String) -> [String] { [] }
#endif
}
