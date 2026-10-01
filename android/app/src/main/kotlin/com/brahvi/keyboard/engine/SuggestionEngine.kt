package com.brahvi.keyboard.engine

import android.content.Context
import org.json.JSONObject

class SuggestionEngine(private val context: Context) {
    private val brahviRoot = TrieNode()
    private val englishRoot = TrieNode()
    @Volatile private var isInitialized = false

    private class TrieNode {
        val children = HashMap<Char, TrieNode>()
        var isWord = false
        var frequency = 0
    }

    fun initialize() {
        if (isInitialized) return
        Thread {
            try {
                loadDictionary("dictionaries/brahvi_dictionary.json", brahviRoot)
                loadDictionary("dictionaries/english_dictionary.json", englishRoot)
            } catch (_: Exception) {
                seedFallbackData()
            }
            isInitialized = true
        }.start()
    }

    private fun loadDictionary(relative: String, root: TrieNode) {
        val obj = AssetLoader.readJson(context, relative)
        if (obj == null) {
            if (root === brahviRoot) seedFallbackData()
            return
        }
        val wordsArray = obj.getJSONArray("words")
        for (i in 0 until wordsArray.length()) {
            val item = wordsArray.getJSONObject(i)
            insert(root, item.getString("word"), item.getInt("frequency"))
        }
    }

    private fun seedFallbackData() {
        val brahviSeeds = listOf(
            "براہوئی" to 1200, "سلّام" to 1100, "ای" to 1050, "نی" to 1000,
            "نن" to 950, "نم" to 900, "دا" to 970, "او" to 980, "ڷول" to 500,
            "ڷٹ" to 480, "ڷک" to 460, "ڷمب" to 440, "جوڑ" to 760, "خیر" to 850
        )
        for ((word, freq) in brahviSeeds) insert(brahviRoot, word, freq)
    }

    private fun insert(root: TrieNode, word: String, frequency: Int) {
        var current = root
        for (ch in word) {
            current = current.children.getOrPut(ch) { TrieNode() }
        }
        current.isWord = true
        current.frequency = frequency
    }

    fun learn(word: String, language: String) {
        if (word.trim().length < 2) return
        val root = if (language.equals("english", true)) englishRoot else brahviRoot
        insert(root, word.trim(), 80)
    }

    fun getSuggestions(prefix: String, language: String, max: Int = 3): List<String> {
        if (prefix.isBlank()) return emptyList()
        return try {
            val root = if (language.equals("english", ignoreCase = true)) englishRoot else brahviRoot
            var current = root
            for (ch in prefix) {
                current = current.children[ch] ?: return emptyList()
            }
            val results = ArrayList<Pair<String, Int>>()
            collect(current, prefix, results)
            results.sortByDescending { it.second }
            results.take(max).map { it.first }
        } catch (_: Exception) {
            emptyList()
        }
    }

    fun autocorrect(word: String, language: String): String? {
        if (word.length < 3) return null
        val suggestions = getSuggestions(word, language, 1)
        val candidate = suggestions.firstOrNull() ?: return null
        if (candidate != word && candidate.startsWith(word)) return candidate
        return null
    }

    private fun collect(node: TrieNode, currentPrefix: String, results: MutableList<Pair<String, Int>>) {
        if (node.isWord) results.add(Pair(currentPrefix, node.frequency))
        for ((char, child) in node.children) {
            collect(child, currentPrefix + char, results)
        }
    }
}
