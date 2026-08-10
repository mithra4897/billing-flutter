import AppKit
import Foundation

@main
final class PairingLauncher: NSObject, NSApplicationDelegate {
    private var receivedOpenRequest = false

    func applicationDidFinishLaunching(_ notification: Notification) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            guard let self, !self.receivedOpenRequest else { return }
            do {
                try self.installIfNeeded()
                self.show("The agent is installed. Open a .billingawpair file downloaded from your ERP to connect this computer.", error: false)
            } catch {
                self.show(error.localizedDescription, error: true)
            }
            NSApp.terminate(nil)
        }
    }

    func application(_ sender: NSApplication, openFiles filenames: [String]) {
        receivedOpenRequest = true
        guard let bundle = filenames.first else {
            sender.reply(toOpenOrPrint: .failure)
            return
        }
        let reply = handlePairing(bundle: bundle)
        sender.reply(toOpenOrPrint: reply ? .success : .failure)
        NSApp.terminate(nil)
    }

    func application(_ application: NSApplication, openFile filename: String) -> Bool {
        receivedOpenRequest = true
        let paired = handlePairing(bundle: filename)
        NSApp.terminate(nil)
        return paired
    }

    @discardableResult
    private func handlePairing(bundle: String) -> Bool {
        do {
            try pair(bundle: bundle)
            show("This computer is connected to Activity Watch.", error: false)
            return true
        } catch {
            show(error.localizedDescription, error: true)
            return false
        }
    }

    private func pair(bundle: String) throws {
        try installIfNeeded()
        let home = FileManager.default.homeDirectoryForCurrentUser
        let root = home.appendingPathComponent("Library/Application Support/BillingActivityWatch")
        let agent = root.appendingPathComponent("activity-watch-agent")
        let config = root.appendingPathComponent("activity-watch-agent.config.json")
        try run(agent, ["pair", "--config", config.path, "--bundle", bundle])
    }

    private func installIfNeeded() throws {
        let home = FileManager.default.homeDirectoryForCurrentUser
        let root = home.appendingPathComponent("Library/Application Support/BillingActivityWatch")
        let agent = root.appendingPathComponent("activity-watch-agent")
        let config = root.appendingPathComponent("activity-watch-agent.config.json")
        guard let packagedAgent = Bundle.main.url(forResource: "activity-watch-agent", withExtension: nil) else {
            throw NSError(domain: "BillingActivityWatch", code: 1, userInfo: [NSLocalizedDescriptionKey: "The packaged Activity Watch agent is missing."])
        }
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        if FileManager.default.fileExists(atPath: agent.path) {
            try FileManager.default.removeItem(at: agent)
        }
        try FileManager.default.copyItem(at: packagedAgent, to: agent)
        try FileManager.default.setAttributes([.posixPermissions: 0o700], ofItemAtPath: agent.path)
        if !FileManager.default.fileExists(atPath: config.path) {
            try run(agent, ["bootstrap", "--config", config.path])
        }
    }

    private func run(_ executable: URL, _ arguments: [String]) throws {
        let process = Process()
        process.executableURL = executable
        process.arguments = arguments
        let errors = Pipe()
        process.standardError = errors
        try process.run()
        process.waitUntilExit()
        guard process.terminationStatus == 0 else {
            let data = errors.fileHandleForReading.readDataToEndOfFile()
            let message = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines)
            throw NSError(
                domain: "BillingActivityWatch",
                code: Int(process.terminationStatus),
                userInfo: [NSLocalizedDescriptionKey: message?.isEmpty == false ? message! : "Activity Watch setup failed."]
            )
        }
    }

    private func show(_ message: String, error: Bool) {
        let alert = NSAlert()
        alert.messageText = error ? "Activity Watch setup failed" : "Billing Activity Watch"
        alert.informativeText = message
        alert.alertStyle = error ? .critical : .informational
        alert.runModal()
    }
}
