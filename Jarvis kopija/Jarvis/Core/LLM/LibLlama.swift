//
//  LibLlama.swift
//  Jarvis
//
//  Thin Swift wrapper around llama.cpp based on the official
//  `examples/llama.swiftui/llama.cpp.swift/LibLlama.swift`.
//
import Foundation
import llama

enum LlamaError: Error {
    case couldNotInitializeContext
}

func llama_batch_clear(_ batch: inout llama_batch) {
    batch.n_tokens = 0
}

func llama_batch_add(
    _ batch: inout llama_batch,
    _ id: llama_token,
    _ pos: llama_pos,
    _ seq_ids: [llama_seq_id],
    _ logits: Bool
) {
    batch.token   [Int(batch.n_tokens)] = id
    batch.pos     [Int(batch.n_tokens)] = pos
    batch.n_seq_id[Int(batch.n_tokens)] = Int32(seq_ids.count)
    if let seqIdBase = batch.seq_id {
        let idx = Int(batch.n_tokens)
        if let dest = seqIdBase[idx] {
            for i in 0..<seq_ids.count {
                dest[Int(i)] = seq_ids[i]
            }
        }
    }
    batch.logits  [Int(batch.n_tokens)] = logits ? 1 : 0

    batch.n_tokens += 1
}

actor LlamaContext {
    private var model: OpaquePointer
    private var context: OpaquePointer
    private var vocab: OpaquePointer
    private var sampling: UnsafeMutablePointer<llama_sampler>
    private var batch: llama_batch
    private var tokensList: [llama_token]
    var isDone: Bool = false

    /// This variable is used to store temporarily invalid cchars
    private var temporaryInvalidCChars: [CChar]

    private let batchCapacity: Int32 = 512
    var nLen: Int32 = 256
    var nCur: Int32 = 0

    var nDecode: Int32 = 0

    init(model: OpaquePointer, context: OpaquePointer) {
        self.model = model
        self.context = context
        self.tokensList = []
        self.batch = llama_batch_init(batchCapacity, 0, 1)
        self.temporaryInvalidCChars = []
        let sparams = llama_sampler_chain_default_params()
        self.sampling = llama_sampler_chain_init(sparams)
        // Lower temperature for more deterministic / accurate answers.
        llama_sampler_chain_add(self.sampling, llama_sampler_init_temp(0.1))
        llama_sampler_chain_add(self.sampling, llama_sampler_init_dist(1234))
        vocab = llama_model_get_vocab(model)
    }

    func configure(maxTokens: Int32) {
        nLen = min(maxTokens, 256)
    }

    deinit {
        llama_sampler_free(sampling)
        llama_batch_free(batch)
        llama_model_free(model)
        llama_free(context)
        llama_backend_free()
    }

    static func createContext(path: String, ctxSize: Int32) throws -> LlamaContext {
        llama_backend_init()
        var modelParams = llama_model_default_params()

        #if targetEnvironment(simulator)
        // Simulator has no real GPU; keep everything on CPU.
        modelParams.n_gpu_layers = 0
        #else
        // On-device, offload as many layers as possible to GPU (Metal)
        // for much faster inference, especially with Phi-3 / Gemma.
        modelParams.n_gpu_layers = -1
        #endif

        guard let model = llama_model_load_from_file(path, modelParams) else {
            throw LlamaError.couldNotInitializeContext
        }

        let nThreads = max(1, min(8, ProcessInfo.processInfo.processorCount - 2))

        var ctxParams = llama_context_default_params()
        ctxParams.n_ctx = UInt32(ctxSize)
        ctxParams.n_threads       = Int32(nThreads)
        ctxParams.n_threads_batch = Int32(nThreads)

        guard let context = llama_init_from_model(model, ctxParams) else {
            throw LlamaError.couldNotInitializeContext
        }

        return LlamaContext(model: model, context: context)
    }

    func completionInit(text: String) {
        tokensList = tokenize(text: text, addBOS: true)
        temporaryInvalidCChars = []
        isDone = false

        let nCtx = llama_n_ctx(context)
        let nKVReq = tokensList.count + (Int(nLen) - tokensList.count)

        if nKVReq > nCtx {
            print("warning: required KV cache size \(nKVReq) > n_ctx \(nCtx)")
        }

        llama_batch_clear(&batch)

        // Never exceed the batch capacity; keep the last N tokens of the prompt.
        let maxPromptTokens = min(tokensList.count, Int(batchCapacity))
        let startIndex = tokensList.count - maxPromptTokens
        let promptSlice = tokensList[startIndex..<tokensList.count]

        for (i, token) in promptSlice.enumerated() {
            llama_batch_add(&batch, token, Int32(i), [0], false)
        }
        batch.logits[Int(batch.n_tokens) - 1] = 1 // true

        if llama_decode(context, batch) != 0 {
            print("llama_decode() failed during prompt")
        }

        nCur = batch.n_tokens
    }

    /// One step of generation, returning the next UTF‑8 fragment.
    func completionStep() -> String {
        if isDone {
            return ""
        }

        var newTokenID: llama_token = 0
        newTokenID = llama_sampler_sample(sampling, context, batch.n_tokens - 1)

        if llama_vocab_is_eog(vocab, newTokenID) || nCur == nLen {
            isDone = true
            let newTokenStr = String(cString: temporaryInvalidCChars + [0])
            temporaryInvalidCChars.removeAll()
            return newTokenStr
        }

        let newTokenCChars = tokenToPiece(token: newTokenID)
        temporaryInvalidCChars.append(contentsOf: newTokenCChars)
        let newTokenStr: String
        if let string = String(validatingUTF8: temporaryInvalidCChars + [0]) {
            temporaryInvalidCChars.removeAll()
            newTokenStr = string
        } else if (0 ..< temporaryInvalidCChars.count).contains(where: { idx in
            let suffix = Array(temporaryInvalidCChars.suffix(idx))
            return !suffix.isEmpty && String(validatingUTF8: suffix + [0]) != nil
        }) {
            let string = String(cString: temporaryInvalidCChars + [0])
            temporaryInvalidCChars.removeAll()
            newTokenStr = string
        } else {
            newTokenStr = ""
        }

        llama_batch_clear(&batch)
        llama_batch_add(&batch, newTokenID, nCur, [0], true)

        nDecode += 1
        nCur    += 1

        if llama_decode(context, batch) != 0 {
            print("failed to evaluate llama during generation")
        }

        return newTokenStr
    }

    func clear() {
        tokensList.removeAll()
        temporaryInvalidCChars.removeAll()
        llama_memory_clear(llama_get_memory(context), true)
    }

    private func tokenize(text: String, addBOS: Bool) -> [llama_token] {
        let utf8Count = text.utf8.count
        let nTokens = utf8Count + (addBOS ? 1 : 0) + 1
        let tokens = UnsafeMutablePointer<llama_token>.allocate(capacity: nTokens)
        let tokenCount = llama_tokenize(vocab, text, Int32(utf8Count), tokens, Int32(nTokens), addBOS, false)

        var swiftTokens: [llama_token] = []
        for i in 0..<tokenCount {
            swiftTokens.append(tokens[Int(i)])
        }

        tokens.deallocate()

        return swiftTokens
    }

    /// - note: The result does not contain null-terminator
    private func tokenToPiece(token: llama_token) -> [CChar] {
        let result = UnsafeMutablePointer<Int8>.allocate(capacity: 8)
        result.initialize(repeating: Int8(0), count: 8)
        defer {
            result.deallocate()
        }
        let nTokens = llama_token_to_piece(vocab, token, result, 8, 0, false)

        if nTokens < 0 {
            let newResult = UnsafeMutablePointer<Int8>.allocate(capacity: Int(-nTokens))
            newResult.initialize(repeating: Int8(0), count: Int(-nTokens))
            defer {
                newResult.deallocate()
            }
            let nNewTokens = llama_token_to_piece(vocab, token, newResult, -nTokens, 0, false)
            let bufferPointer = UnsafeBufferPointer(start: newResult, count: Int(nNewTokens))
            return Array(bufferPointer)
        } else {
            let bufferPointer = UnsafeBufferPointer(start: result, count: Int(nTokens))
            return Array(bufferPointer)
        }
    }
}

