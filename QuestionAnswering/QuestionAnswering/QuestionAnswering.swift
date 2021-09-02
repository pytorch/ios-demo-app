//// Copyright (c) 2020 Facebook, Inc. and its affiliates.
// All rights reserved.
//
// This source code is licensed under the BSD-style license found in the
// LICENSE file in the root directory of this source tree.


import Foundation

class QuestionAnswering {
    private let MODEL_INPUT_LENGTH = 360
    private let EXTRA_ID_NUM = 3
    private let CLS = "[CLS]"
    private let SEP = "[SEP]"
    private let PAD = "[PAD]"
    private let START_LOGITS = "start_logits"
    private let END_LOGITS = "end_logits"
    
    private var token2id = [String: Int]()
    private var id2token = [Int: String]()
    
    private var module: InferenceModule = {
        if let filePath = Bundle.main.path(forResource: "qa360_quantized", ofType: "ptl"),
            let module = InferenceModule(fileAtPath: filePath) {
            return module
        } else {
            fatalError("Failed to load model file qa360_quantized.ptl")
        }
    }()
    
    
    lazy var vocab: [String] = {
        if let filePath = Bundle.main.path(forResource: "vocab", ofType: "txt"),
            let vocab = try? String(contentsOfFile: filePath) {
            return vocab.components(separatedBy: .newlines)
        } else {
            fatalError("vocab.txt file not found")
        }
    }()
    
    enum TokenizationError: Error {
        case Question_Too_Long
    }
    
    func tokenizer(question: String, text: String) throws -> [Int?] {
        let tokenIdsQuestion = wordPieceTokenizer(question)
        if tokenIdsQuestion.count >= MODEL_INPUT_LENGTH {
            throw TokenizationError.Question_Too_Long
        }
        
        let tokenIdsText = wordPieceTokenizer(text)
        let pad = token2id[PAD];
        var ids = Array(repeating: pad, count: MODEL_INPUT_LENGTH)
        ids[0] = token2id[CLS];
        for (i, tokenid) in tokenIdsQuestion.enumerated() {
            ids[i+1] = tokenid;
        }
        ids[tokenIdsQuestion.count + 1] = token2id[SEP]

        let maxTextLength = min(tokenIdsText.count, MODEL_INPUT_LENGTH - tokenIdsQuestion.count - EXTRA_ID_NUM)
        for i in 0..<maxTextLength {
            ids[tokenIdsQuestion.count + i + 2] = tokenIdsText[i]
        }
        ids[tokenIdsQuestion.count + maxTextLength + 2] = token2id[SEP];

        return ids
    }

    func wordPieceTokenizer(_ questionOrText: String) -> [Int] {
        // for each token, if it's in the vocab.txt (a key in mTokenIdMap), return its Id
        // else first find the largest subtoken (at least the first letter) that exists in vocab, then
        // (add "##" to the rest - even if the rest is a valid token - and get the largest token "##..."),
        // and repeat the () process.
        var tokenIds = [Int]();
        let pattern = #"(\w+|\S)"#
            let regex = try? NSRegularExpression(pattern: pattern, options: [])
            let nsrange = NSRange(questionOrText.startIndex..<questionOrText.endIndex, in: questionOrText)
            regex!.enumerateMatches(in: questionOrText, options: [], range: nsrange) { (match, _, stop) in
                guard let match = match else { return }
                let range = match.range(at:1)
                if let swiftRange = Range(range, in: questionOrText) {
                    let token = questionOrText[swiftRange].lowercased()
                    if let _ = token2id[token] {
                        tokenIds.append(token2id[token]!)
                    }
                    else {
                        for i in 0 ..< token.count {
                            let str = String(token.prefix(token.count - i - 1))
                            if let tid = token2id[str] {
                                tokenIds.append(tid);
                                var subToken = String(token.suffix(i + 1))
                                var j = 0
                                while j < subToken.count {
                                    if let subTid = token2id["##" + subToken.prefix(subToken.count - j)] {
                                        tokenIds.append(subTid)
                                        subToken = String(subToken.suffix(j))
                                        j = subToken.count - j
                                    }
                                    else if (j == subToken.count - 1) {
                                        tokenIds.append(token2id["##" + subToken]!)
                                        break
                                    }
                                    else {
                                        j += 1
                                    }
                                }
                                break
                            }
                        }
                    }
                }
            }

        return tokenIds
    }
    
    
    func answer(_ question: String, _ text: String) -> String {
        if text.isEmpty {
            return ""
        }
        
        if token2id.isEmpty {
            for (idx, word) in vocab.enumerated() {
                token2id[word] = idx
                id2token[idx] = word
            }
        }
        
        var result = ""
        do {
            let tokenIds = try tokenizer(question: question, text: text)
            if let tids = module.answer(tokenIds: tokenIds as [Any]) {
                for (n, tid) in tids.enumerated() {
                    result += id2token[tid.intValue]!
                    if n != tids.count - 1 {
                        result += " "
                    }
                }
                result = result.replacingOccurrences(of: " ##", with: "").replacingOccurrences(of: #" (?=\p{P})"#, with: "", options: .regularExpression
                )
            }
        }
        catch {
            return "Tokenization exception - Question_Too_Long"
        }
                        
        return result
    }
}
