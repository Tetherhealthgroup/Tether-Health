import Foundation
import SwiftUI

/// The Swift reader for the shared intercept tokens.
///
/// Addendum §2.1 requires the intercept to be built three times — Dart, SwiftUI
/// and an Android overlay — and warns the three drift apart within two sprints
/// unless the colours and copy live in one file all of them read. That file is
/// `assets/unplug/intercept_tokens.json`, which Flutter ships inside the app
/// bundle; this type reads it, and `ShieldConfiguration` draws nothing that is
/// not in here.
///
/// The extensions cannot ask the app for this: they are separate processes with
/// a tight memory budget and no Flutter. They read the same file out of the main
/// bundle, so there is exactly one copy on disk and exactly one source of truth.
public struct InterceptTokens: Sendable {

    public let version: String
    public let colors: [String: UInt32]
    public let copy: [String: String]
    public let breathSeconds: Int
    public let latencyMinMs: Int
    public let latencyMaxMs: Int

    public func color(_ name: String) -> Color {
        guard let packed = colors[name] else { return .clear }
        return Color(
            red: Double((packed >> 16) & 0xFF) / 255.0,
            green: Double((packed >> 8) & 0xFF) / 255.0,
            blue: Double(packed & 0xFF) / 255.0
        )
    }

    public func uiColor(_ name: String) -> UIColor {
        guard let packed = colors[name] else { return .clear }
        return UIColor(
            red: CGFloat((packed >> 16) & 0xFF) / 255.0,
            green: CGFloat((packed >> 8) & 0xFF) / 255.0,
            blue: CGFloat(packed & 0xFF) / 255.0,
            alpha: 1
        )
    }

    public func text(_ name: String, _ values: [String: String] = [:]) -> String {
        guard let template = copy[name] else { return "" }
        return values.reduce(template) { result, entry in
            result.replacingOccurrences(of: "{\(entry.key)}", with: entry.value)
        }
    }

    /// Where Flutter places the asset inside the app bundle.
    ///
    /// The extensions look in the *main* bundle rather than their own, because
    /// only the app target carries `App.framework`'s flutter_assets.
    public static let assetSubpath = "flutter_assets/assets/unplug/intercept_tokens.json"

    /// Reads the token file, or returns nil when it cannot be read.
    ///
    /// Callers must handle nil rather than substitute a default: a default here
    /// would hide from the shield exactly the drift this file exists to prevent,
    /// and an intercept drawn in the wrong colours is worse than one that
    /// reports a problem.
    public static func load() -> InterceptTokens? {
        for bundle in candidateBundles() {
            if let url = bundle.url(forResource: assetSubpath, withExtension: nil),
               let data = try? Data(contentsOf: url),
               let parsed = parse(data) {
                return parsed
            }
        }
        return nil
    }

    /// The app bundle first, then this extension's own, then the containing app.
    private static func candidateBundles() -> [Bundle] {
        var bundles = [Bundle.main]
        // An extension's Bundle.main is the extension. The app that contains it
        // is two directory levels up from the extension bundle.
        let containing = Bundle.main.bundleURL
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        if let host = Bundle(url: containing) {
            bundles.append(host)
        }
        if let frameworks = Bundle.main.privateFrameworksURL,
           let appFramework = Bundle(url: frameworks.appendingPathComponent("App.framework")) {
            bundles.append(appFramework)
        }
        return bundles
    }

    static func parse(_ data: Data) -> InterceptTokens? {
        guard
            let root = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
            let version = root["version"] as? String,
            let rawColors = root["colors"] as? [String: String],
            let copy = root["copy"] as? [String: String],
            let timing = root["timing"] as? [String: Int],
            let breathSeconds = timing["breathSeconds"],
            let latencyMin = timing["androidOverlayLatencyMsMin"],
            let latencyMax = timing["androidOverlayLatencyMsMax"]
        else { return nil }

        var colors: [String: UInt32] = [:]
        for (name, value) in rawColors {
            guard value.count == 7, value.hasPrefix("#"),
                  let packed = UInt32(value.dropFirst(), radix: 16)
            else { return nil }
            colors[name] = packed
        }

        return InterceptTokens(
            version: version,
            colors: colors,
            copy: copy,
            breathSeconds: breathSeconds,
            latencyMinMs: latencyMin,
            latencyMaxMs: latencyMax
        )
    }
}
