// Measures how you press the PushToTalk hotkey: how long you hold it and how fast you tap it twice.
// Build and run from the repository root:
//   mkdir -p build && swiftc -O -o build/taptimer tools/taptimer.swift && build/taptimer
// Optional argument: the key code to watch (default: the hotkey saved by PushToTalk, or Right Option = 61).
// Press the key the way you normally use it, then press Ctrl-C in Terminal to print the summary.
import AppKit

let keyCode: UInt16 = CommandLine.arguments.dropFirst().first.flatMap { UInt16($0) }
    ?? (UserDefaults(suiteName: "com.yulrizka.PushToTalk")?.object(forKey: "prefKeyCode") as? Int).map { UInt16($0) }
    ?? 61
let flagForKey: [UInt16: NSEvent.ModifierFlags] = [
    0x3F: .function, 0x3A: .option, 0x3D: .option, 0x37: .command, 0x36: .command,
    0x38: .shift, 0x3C: .shift, 0x3B: .control, 0x3E: .control, 0x39: .capsLock,
]
let flag = flagForKey[keyCode] ?? .function
var pressedAt: TimeInterval?
var lastPress: TimeInterval?
var holds: [TimeInterval] = []
var gaps: [TimeInterval] = []
let start = ProcessInfo.processInfo.systemUptime

func ms(_ t: TimeInterval) -> String { String(format: "%4.0f ms", t * 1000) }

func handle(_ event: NSEvent) {
    guard event.keyCode == keyCode else { return }
    let t = event.timestamp
    let stamp = String(format: "%8.3f s", t - start)
    if event.modifierFlags.contains(flag) {
        var note = ""
        if let last = lastPress { gaps.append(t - last); note = "  gap since previous press \(ms(t - last))" }
        print("\(stamp)  DOWN\(note)")
        pressedAt = t
        lastPress = t
    } else {
        var note = ""
        if let down = pressedAt { holds.append(t - down); note = "  held \(ms(t - down))" }
        print("\(stamp)  UP  \(note)")
        pressedAt = nil
    }
}

func percentile(_ values: [TimeInterval], _ p: Double) -> TimeInterval {
    let sorted = values.sorted()
    return sorted[min(sorted.count - 1, Int(Double(sorted.count - 1) * p))]
}

func summary() {
    print("\n===== summary for key code \(keyCode) =====")
    print("presses: \(holds.count + (pressedAt == nil ? 0 : 1))")
    if !holds.isEmpty {
        print("hold      min \(ms(holds.min()!))  median \(ms(percentile(holds, 0.5)))  p90 \(ms(percentile(holds, 0.9)))  max \(ms(holds.max()!))")
    }
    let quick = gaps.filter { $0 < 1.0 }
    if !gaps.isEmpty {
        print("press-to-press, all:          min \(ms(gaps.min()!))  median \(ms(percentile(gaps, 0.5)))  p90 \(ms(percentile(gaps, 0.9)))  max \(ms(gaps.max()!))")
    }
    if !quick.isEmpty {
        print("press-to-press, under 1 s:    min \(ms(quick.min()!))  median \(ms(percentile(quick, 0.5)))  p90 \(ms(percentile(quick, 0.9)))  max \(ms(quick.max()!))  (\(quick.count) taps)")
        print("suggested double-tap window:  \(ms(percentile(quick, 0.9) * 1.25)) (p90 of the quick taps plus 25%)")
        print("set it with: defaults write com.yulrizka.PushToTalk prefDoubleTapInterval -float \(String(format: "%.2f", percentile(quick, 0.9) * 1.25))")
    }
    print("system double-click interval: \(ms(NSEvent.doubleClickInterval))")
}

print("Watching key code \(keyCode). Press it as you normally would (single holds, double taps), then Ctrl-C.")
let app = NSApplication.shared
app.setActivationPolicy(.prohibited)
NSEvent.addGlobalMonitorForEvents(matching: .flagsChanged) { handle($0) }
NSEvent.addLocalMonitorForEvents(matching: .flagsChanged) { handle($0); return $0 }
signal(SIGINT, SIG_IGN)
let sigint = DispatchSource.makeSignalSource(signal: SIGINT, queue: .main)
sigint.setEventHandler { summary(); exit(0) }
sigint.resume()
app.run()
