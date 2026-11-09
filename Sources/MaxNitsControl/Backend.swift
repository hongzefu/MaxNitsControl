import AppKit
import Foundation

/// 调用本机已安装的 `maxnits` 命令行；GUI 不直接碰显示器，只做转发。
enum MaxNitsCLI {
    static let path: String? = {
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        let candidates = [
            "\(home)/.local/bin/maxnits",
            "/opt/homebrew/bin/maxnits",
            "/usr/local/bin/maxnits",
            "\(home)/maxnits/dist/MaxNits.app/Contents/MacOS/MaxNits",
        ]
        return candidates.first { FileManager.default.isExecutableFile(atPath: $0) }
    }()

    struct Result {
        let code: Int32
        let output: String
    }

    static func run(_ args: [String]) async -> Result {
        guard let path else { return Result(code: -1, output: "找不到 maxnits 命令") }
        return await Task.detached {
            let process = Process()
            process.executableURL = URL(fileURLWithPath: path)
            process.arguments = args
            let pipe = Pipe()
            process.standardOutput = pipe
            process.standardError = pipe
            process.standardInput = FileHandle.nullDevice
            do {
                try process.run()
            } catch {
                return Result(code: -1, output: error.localizedDescription)
            }
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            process.waitUntilExit()
            let text = String(data: data, encoding: .utf8)?
                .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            return Result(code: process.terminationStatus, output: text)
        }.value
    }
}

struct DisplayInfo: Identifiable {
    let id: Int
    let name: String
    let current: Double
    let potential: Double
}

@MainActor
final class Model: ObservableObject {
    @Published var daemonRunning = false
    @Published var boostOn = false
    @Published var level: Double = 100
    @Published var detail = ""
    @Published var loginEnabled = false
    @Published var displays: [DisplayInfo] = []
    @Published var errorText: String?
    /// 拖动滑块期间不让轮询结果覆盖手上的值。
    var isDragging = false

    let cliAvailable = MaxNitsCLI.path != nil
    private var busy = false

    private static let loginPlist = FileManager.default.homeDirectoryForCurrentUser
        .appendingPathComponent("Library/LaunchAgents/io.github.yogeshvar.MaxNits.plist")

    init() {
        Task { [weak self] in
            while let self {
                await self.refresh()
                try? await Task.sleep(nanoseconds: 2_000_000_000)
            }
        }
    }

    func refresh() async {
        displays = NSScreen.screens.enumerated().map { index, screen in
            DisplayInfo(
                id: index,
                name: screen.localizedName,
                current: screen.maximumExtendedDynamicRangeColorComponentValue,
                potential: screen.maximumPotentialExtendedDynamicRangeColorComponentValue
            )
        }
        loginEnabled = FileManager.default.fileExists(atPath: Self.loginPlist.path)
        guard cliAvailable, !busy else { return }
        let result = await MaxNitsCLI.run(["status"])
        guard !busy else { return }
        apply(status: result)
    }

    /// `maxnits status` 输出形如 `ON 70 <说明>`；守护进程没起时输出提示并返回 1。
    private func apply(status result: MaxNitsCLI.Result) {
        let parts = result.output.split(separator: " ", maxSplits: 2).map(String.init)
        guard result.code == 0, parts.count >= 2,
              parts[0] == "ON" || parts[0] == "OFF", let percent = Double(parts[1]) else {
            daemonRunning = false
            boostOn = false
            detail = ""
            return
        }
        daemonRunning = true
        boostOn = parts[0] == "ON"
        if !isDragging { level = percent }
        detail = parts.count > 2 ? parts[2] : ""
    }

    private func perform(_ args: [String]) async {
        guard cliAvailable else { return }
        busy = true
        let result = await MaxNitsCLI.run(args)
        errorText = result.code == 0 ? nil : (result.output.isEmpty ? "命令失败：maxnits \(args.joined(separator: " "))" : result.output)
        let status = await MaxNitsCLI.run(["status"])
        busy = false
        apply(status: status)
        loginEnabled = FileManager.default.fileExists(atPath: Self.loginPlist.path)
    }

    func setBoost(on: Bool) {
        boostOn = on
        Task { await perform([on ? "on" : "off"]) }
    }

    func setLevel(_ value: Double) {
        let percent = Int(value.rounded())
        level = Double(percent)
        boostOn = true
        Task { await perform(["set", String(percent)]) }
    }

    func quitDaemon() {
        Task { await perform(["quit"]) }
    }

    func setLogin(_ enabled: Bool) {
        loginEnabled = enabled
        Task { await perform([enabled ? "enable-login" : "disable-login"]) }
    }
}
