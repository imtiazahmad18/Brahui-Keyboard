import UIKit

class KeyboardViewController: UIInputViewController {

    private var nextKeyboardButton: UIButton!
    private var rowsStackView: UIStackView!
    private var suggestionsScrollView: UIScrollView!
    private var suggestionsStackView: UIStackView!
    private var harakatScrollView: UIScrollView!
    private var harakatStackView: UIStackView!
    private var isHarakatVisible = false

    private var currentLayoutId = "brahvi_normal"
    private var previousLanguageId = "brahvi_normal"

    // App Group UserDefaults for shared settings
    private let appGroupDefaults = UserDefaults(suiteName: "group.com.brahvi.keyboard")

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadLayout(currentLayoutId)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        applyThemeColors()
    }

    private func setupUI() {
        view.backgroundColor = UIColor(red: 15/255, green: 23/255, blue: 42/255, alpha: 1.0) // Navy dark default

        // 1. Suggestions Bar
        suggestionsStackView = UIStackView()
        suggestionsStackView.axis = .horizontal
        suggestionsStackView.distribution = .fillEqually
        suggestionsStackView.alignment = .center
        suggestionsStackView.spacing = 8
        suggestionsStackView.translatesAutoresizingMaskIntoConstraints = false

        suggestionsScrollView = UIScrollView()
        suggestionsScrollView.showsHorizontalScrollIndicator = false
        suggestionsScrollView.translatesAutoresizingMaskIntoConstraints = false
        suggestionsScrollView.addSubview(suggestionsStackView)
        view.addSubview(suggestionsScrollView)

        // 2. Harakat Bar (Hidden by default)
        harakatStackView = UIStackView()
        harakatStackView.axis = .horizontal
        harakatStackView.spacing = 8
        harakatStackView.translatesAutoresizingMaskIntoConstraints = false

        harakatScrollView = UIScrollView()
        harakatScrollView.showsHorizontalScrollIndicator = false
        harakatScrollView.isHidden = true
        harakatScrollView.translatesAutoresizingMaskIntoConstraints = false
        harakatScrollView.addSubview(harakatStackView)
        view.addSubview(harakatScrollView)

        setupHarakatButtons()

        // 3. Rows Stack View
        rowsStackView = UIStackView()
        rowsStackView.axis = .vertical
        rowsStackView.distribution = .fillEqually
        rowsStackView.spacing = 6
        rowsStackView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(rowsStackView)

        // Auto Layout
        NSLayoutConstraint.activate([
            suggestionsScrollView.topAnchor.constraint(equalTo: view.topAnchor),
            suggestionsScrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            suggestionsScrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            suggestionsScrollView.heightAnchor.constraint(equalToConstant: 38),

            suggestionsStackView.topAnchor.constraint(equalTo: suggestionsScrollView.topAnchor),
            suggestionsStackView.bottomAnchor.constraint(equalTo: suggestionsScrollView.bottomAnchor),
            suggestionsStackView.leadingAnchor.constraint(equalTo: suggestionsScrollView.leadingAnchor, constant: 8),
            suggestionsStackView.trailingAnchor.constraint(equalTo: suggestionsScrollView.trailingAnchor, constant: -8),
            suggestionsStackView.heightAnchor.constraint(equalTo: suggestionsScrollView.heightAnchor),

            harakatScrollView.topAnchor.constraint(equalTo: suggestionsScrollView.bottomAnchor),
            harakatScrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            harakatScrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            harakatScrollView.heightAnchor.constraint(equalToConstant: 44),

            harakatStackView.topAnchor.constraint(equalTo: harakatScrollView.topAnchor),
            harakatStackView.bottomAnchor.constraint(equalTo: harakatScrollView.bottomAnchor),
            harakatStackView.leadingAnchor.constraint(equalTo: harakatScrollView.leadingAnchor, constant: 8),
            harakatStackView.trailingAnchor.constraint(equalTo: harakatScrollView.trailingAnchor, constant: -8),
            harakatStackView.heightAnchor.constraint(equalTo: harakatScrollView.heightAnchor),

            rowsStackView.topAnchor.constraint(equalTo: harakatScrollView.bottomAnchor, constant: 4),
            rowsStackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 4),
            rowsStackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -4),
            rowsStackView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -4)
        ])
    }

    private func setupHarakatButtons() {
        let marks: [(String, String)] = [
            ("◌َ", "\u{064E}"), // Zabar
            ("◌ِ", "\u{0650}"), // Zer
            ("◌ُ", "\u{064F}"), // Pesh
            ("◌ّ", "\u{0651}"), // Tashdeed
            ("◌ْ", "\u{0652}"), // Sukun
            ("◌ٰ", "\u{0670}"), // Khari Zabar
            ("◌ً", "\u{064B}"), // Do Zabar
            ("◌ٍ", "\u{064D}"), // Do Zer
            ("◌ٌ", "\u{064C}"), // Do Pesh
            ("◌ٓ", "\u{0653}")  // Maddah
        ]

        for (label, output) in marks {
            let btn = UIButton(type: .system)
            btn.setTitle(label, for: .normal)
            btn.titleLabel?.font = UIFont.systemFont(ofSize: 20, weight: .bold)
            btn.setTitleColor(.white, for: .normal)
            btn.backgroundColor = UIColor(red: 30/255, green: 41/255, blue: 59/255, alpha: 1.0)
            btn.layer.cornerRadius = 6
            btn.widthAnchor.constraint(equalToConstant: 44).isActive = true
            btn.addAction(UIAction(handler: { [weak self] _ in
                self?.textDocumentProxy.insertText(output)
                self?.toggleHarakat()
            }), for: .touchUpInside)
            harakatStackView.addArrangedSubview(btn)
        }
    }

    private func toggleHarakat() {
        isHarakatVisible = !isHarakatVisible
        UIView.animate(withDuration: 0.2) {
            self.harakatScrollView.isHidden = !self.isHarakatVisible
        }
    }

    private func loadLayout(_ layoutId: String) {
        currentLayoutId = layoutId
        rowsStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }

        // Determine rows based on layout ID
        let rows = getLayoutKeys(layoutId)
        for row in rows {
            let rowStack = UIStackView()
            rowStack.axis = .horizontal
            rowStack.distribution = .fillProportionally
            rowStack.spacing = 5

            for key in row {
                let keyBtn = createKeyButton(key)
                rowStack.addArrangedSubview(keyBtn)
            }
            rowsStackView.addArrangedSubview(rowStack)
        }
    }

    private func createKeyButton(_ key: (label: String, output: String, type: String, weight: CGFloat)) -> UIButton {
        let btn = UIButton(type: .system)
        btn.setTitle(key.label, for: .normal)
        btn.layer.cornerRadius = 7
        btn.layer.masksToBounds = true

        let isSpecialChar = key.label == "ڷ"
        if isSpecialChar {
            btn.layer.borderWidth = 1.5
            btn.layer.borderColor = UIColor.systemTeal.cgColor
        }

        // Set font size
        if key.type == "space" {
            btn.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        } else if key.label.count > 2 {
            btn.titleLabel?.font = UIFont.systemFont(ofSize: 13, weight: .medium)
        } else {
            btn.titleLabel?.font = UIFont(name: "NotoSansArabic-Regular", size: 19) ?? UIFont.systemFont(ofSize: 19, weight: .medium)
        }

        // Colors
        if key.type == "action" {
            btn.backgroundColor = UIColor(red: 56/255, green: 189/255, blue: 248/255, alpha: 1.0)
            btn.setTitleColor(UIColor(red: 15/255, green: 23/255, blue: 42/255, alpha: 1.0), for: .normal)
        } else if key.type == "special" {
            btn.backgroundColor = UIColor(red: 20/255, green: 30/255, blue: 51/255, alpha: 1.0)
            btn.setTitleColor(UIColor(red: 148/255, green: 163/255, blue: 184/255, alpha: 1.0), for: .normal)
        } else {
            btn.backgroundColor = UIColor(red: 30/255, green: 41/255, blue: 59/255, alpha: 1.0)
            btn.setTitleColor(UIColor(red: 248/255, green: 250/255, blue: 252/255, alpha: 1.0), for: .normal)
        }

        // Action handlers
        btn.addAction(UIAction(handler: { [weak self] _ in
            self?.handleKeyPress(key)
        }), for: .touchUpInside)

        // Next keyboard support (Apple Globe)
        if key.type == "globe" {
            btn.addTarget(self, action: #selector(handleInputModeList(from:with:)), for: .allTouchEvents)
        }

        return btn
    }

    private func handleKeyPress(_ key: (label: String, output: String, type: String, weight: CGFloat)) {
        // Feedback
        if appGroupDefaults?.bool(forKey: "hapticFeedback") ?? true {
            let feedback = UIImpactFeedbackGenerator(style: .light)
            feedback.impactOccurred()
        }

        switch key.type {
        case "char":
            textDocumentProxy.insertText(key.output)
        case "space":
            textDocumentProxy.insertText(" ")
        case "backspace":
            textDocumentProxy.deleteBackward()
        case "return":
            textDocumentProxy.insertText("\n")
        case "shift":
            if currentLayoutId == "brahvi_normal" {
                loadLayout("brahvi_shift")
            } else if currentLayoutId == "brahvi_shift" {
                loadLayout("brahvi_normal")
            } else if currentLayoutId == "english_normal" {
                loadLayout("english_shift")
            } else if currentLayoutId == "english_shift" {
                loadLayout("english_normal")
            }
        case "lang":
            if currentLayoutId.hasPrefix("brahvi") {
                previousLanguageId = "english_normal"
                loadLayout("english_normal")
            } else {
                previousLanguageId = "brahvi_normal"
                loadLayout("brahvi_normal")
            }
        case "123":
            if currentLayoutId != "numbers_symbols" {
                previousLanguageId = currentLayoutId
                loadLayout("numbers_symbols")
            } else {
                loadLayout(previousLanguageId)
            }
        case "harakat":
            toggleHarakat()
        default:
            break
        }
    }

    private func applyThemeColors() {
        // Shared theme colors can be synced from appGroupDefaults
    }

    private func getLayoutKeys(_ layoutId: String) -> [[(label: String, output: String, type: String, weight: CGFloat)]] {
        if layoutId == "english_normal" {
            return [
                [("q","q","char",1),("w","w","char",1),("e","e","char",1),("r","r","char",1),("t","t","char",1),("y","y","char",1),("u","u","char",1),("i","i","char",1),("o","o","char",1),("p","p","char",1)],
                [("a","a","char",1),("s","s","char",1),("d","d","char",1),("f","f","char",1),("g","g","char",1),("h","h","char",1),("j","j","char",1),("k","k","char",1),("l","l","char",1)],
                [("⇧","","shift",1.3),("z","z","char",1),("x","x","char",1),("c","c","char",1),("v","v","char",1),("b","b","char",1),("n","n","char",1),("m","m","char",1),("⌫","","backspace",1.3)],
                [("123","","123",1.2),("بر","","lang",1.2),("space"," ","space",4.0),(". ", ". ", "char", 1.0),("↵","\n","action",1.3)]
            ]
        } else if layoutId == "numbers_symbols" {
            return [
                [("1","1","char",1),("2","2","char",1),("3","3","char",1),("4","4","char",1),("5","5","char",1),("6","6","char",1),("7","7","char",1),("8","8","char",1),("9","9","char",1),("0","0","char",1)],
                [("-","-","char",1),("/","/","char",1),(": ",": ","char",1),("; ","; ","char",1),("(","(","char",1),(") ",") ","char",1),("₨","₨","char",1),("&","&","char",1),("@","@","char",1),("\"","\"","char",1)],
                [("=","=","special",1.3),(". ", ". ", "char", 1), (", ", ", ", "char", 1), ("?", "?", "char", 1), ("!", "!", "char", 1), ("'", "'", "char", 1), ("+", "+", "char", 1), ("⌫", "", "backspace", 1.3)],
                [("ABC / بر","","123",1.5),("space"," ","space",5.0),("۔","۔","char",1.0),("↵","\n","action",1.5)]
            ]
        }

        // Default: Brahvi Normal RTL Layout
        return [
            [("ق","ق","char",1),("و","و","char",1),("ع","ع","char",1),("ر","ر","char",1),("ت","ت","char",1),("ے","ے","char",1),("ء","ء","char",1),("ی","ی","char",1),("ہ","ہ","char",1),("پ","پ","char",1)],
            [("ا","ا","char",1),("س","س","char",1),("د","د","char",1),("ف","ف","char",1),("گ","گ","char",1),("ح","ح","char",1),("ج","ج","char",1),("ک","ک","char",1),("ل","ل","char",1),("ڷ","ڷ","char",1),("م","م","char",1)],
            [("⇧","","shift",1.3),("ٹ","ٹ","char",1),("ز","ز","char",1),("ڑ","ڑ","char",1),("ڈ","ڈ","char",1),("ن","ن","char",1),("ب","ب","char",1),("چ","چ","char",1),("خ","خ","char",1),("⌫","","backspace",1.3)],
            [("123","","123",1.2),("EN","","lang",1.0),("◌َ","","harakat",1.0),("space"," ","space",3.8),("۔","۔","char",1.0),("↵","\n","action",1.3)]
        ]
    }
}
