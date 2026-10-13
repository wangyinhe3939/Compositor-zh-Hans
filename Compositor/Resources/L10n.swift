import Foundation

/// Localizes presentation text while document values and shortcut identifiers stay stable.
nonisolated enum L10n {
    static func text(_ key: String, _ arguments: CVarArg...) -> String {
        var value = key
        for table in ["Localizable", "Help", "Messages"] {
            let candidate = Bundle.main.localizedString(forKey: key, value: key, table: table)
            if candidate != key { value = candidate; break }
        }
        return arguments.isEmpty ? value : String(format: value, locale: Locale.current, arguments: arguments)
    }
}
