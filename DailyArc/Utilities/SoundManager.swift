import AVFoundation
import UIKit

enum SoundManager {
    enum Sound: String {
        case pop = "pop"           // habit completion — 0.15s bright bubble
        case chime = "chime"       // badge unlock — 0.5s ascending two-note
        case fanfare = "fanfare"   // major milestone — 1.0s ascending scale
        case settle = "settle"     // streak loss — 0.3s descending half-step
    }

    /// Play a sound. Respects silent mode via system sound API.
    /// Uses system sounds as placeholders until custom .caf files are bundled.
    static func play(_ sound: Sound) {
        guard UserDefaults.standard.object(forKey: "soundsEnabled") == nil
                || UserDefaults.standard.bool(forKey: "soundsEnabled") else { return }

        switch sound {
        case .pop:
            AudioServicesPlaySystemSound(1104)
        case .chime:
            AudioServicesPlaySystemSound(1025)
        case .fanfare:
            AudioServicesPlaySystemSound(1026)
        case .settle:
            AudioServicesPlaySystemSound(1057)
        }
    }
}
