import SwiftUI

@main
struct MaxNitsControlApp: App {
    @StateObject private var model = Model()

    var body: some Scene {
        Window("MaxNits 控制台", id: "main") {
            PanelView().environmentObject(model)
        }
        .windowResizability(.contentSize)

        MenuBarExtra {
            PanelView().environmentObject(model)
        } label: {
            Image(systemName: model.boostOn ? "sun.max.fill" : "sun.max")
        }
        .menuBarExtraStyle(.window)
    }
}

struct PanelView: View {
    @EnvironmentObject private var model: Model

    private var statusText: String {
        if !model.cliAvailable { return "未安装 maxnits" }
        if !model.daemonRunning { return "守护进程未运行" }
        return model.boostOn ? "增强已开启" : "增强已关闭"
    }

    private var statusColor: Color {
        if !model.cliAvailable { return .red }
        return model.boostOn ? .orange : .secondary
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            header
            levelCard
            displaysCard
            footer
        }
        .padding(18)
        .frame(width: 340)
    }

    private var header: some View {
        HStack(spacing: 12) {
            Image(systemName: model.boostOn ? "sun.max.fill" : "sun.max")
                .font(.system(size: 26))
                .foregroundStyle(model.boostOn ? Color.orange : Color.secondary)
                .frame(width: 34)
            VStack(alignment: .leading, spacing: 2) {
                Text("XDR 亮度增强").font(.headline)
                HStack(spacing: 5) {
                    Circle().fill(statusColor).frame(width: 7, height: 7)
                    Text(statusText).font(.subheadline).foregroundStyle(.secondary)
                }
            }
            Spacer()
            Toggle("亮度增强", isOn: Binding(
                get: { model.boostOn },
                set: { model.setBoost(on: $0) }
            ))
            .labelsHidden()
            .toggleStyle(.switch)
            .controlSize(.large)
            .disabled(!model.cliAvailable)
        }
    }

    private var levelCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                Text("增强强度").font(.subheadline).foregroundStyle(.secondary)
                Spacer()
                Text("\(Int(model.level.rounded()))%")
                    .font(.system(size: 30, weight: .semibold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(model.boostOn ? .primary : .secondary)
            }
            HStack(spacing: 8) {
                Image(systemName: "sun.min").foregroundStyle(.secondary)
                Slider(value: $model.level, in: 0...100, step: 1) { editing in
                    model.isDragging = editing
                    if !editing { model.setLevel(model.level) }
                }
                .tint(.orange)
                Image(systemName: "sun.max.fill").foregroundStyle(.secondary)
            }
            HStack(spacing: 8) {
                ForEach([25, 50, 75, 100], id: \.self) { preset in
                    Button("\(preset)%") { model.setLevel(Double(preset)) }
                        .frame(maxWidth: .infinity)
                }
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
            Text("松开滑块或点预设后生效，并自动开启增强。")
                .font(.caption).foregroundStyle(.secondary)
            if let error = model.errorText {
                Text(error).font(.caption).foregroundStyle(.red)
            }
        }
        .padding(14)
        .background(.quaternary.opacity(0.5), in: RoundedRectangle(cornerRadius: 12))
        .disabled(!model.cliAvailable)
    }

    private var displaysCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("显示器 EDR 余量").font(.subheadline).foregroundStyle(.secondary)
            ForEach(model.displays) { display in
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "display")
                    VStack(alignment: .leading, spacing: 2) {
                        Text(display.name)
                        Text(String(format: "当前 %.2f× / 上限 %.2f×", display.current, display.potential))
                            .font(.caption).monospacedDigit().foregroundStyle(.secondary)
                    }
                }
            }
            if !model.detail.isEmpty {
                Text(model.detail).font(.caption).foregroundStyle(.secondary)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.quaternary.opacity(0.5), in: RoundedRectangle(cornerRadius: 12))
    }

    private var footer: some View {
        VStack(alignment: .leading, spacing: 10) {
            Toggle("登录时自动启动守护进程", isOn: Binding(
                get: { model.loginEnabled },
                set: { model.setLogin($0) }
            ))
            .disabled(!model.cliAvailable)
            HStack {
                Button("停止守护进程") { model.quitDaemon() }
                    .disabled(!model.daemonRunning)
                Spacer()
                Button("退出控制台") { NSApplication.shared.terminate(nil) }
            }
        }
    }
}
