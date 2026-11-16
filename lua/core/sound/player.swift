// The sound player nvim keeps open for the whole session, so a sound starts the moment it is asked
// for instead of after afplay wakes the audio device for every keypress. The engine stays running,
// which keeps the device awake, and every file is decoded once and kept in memory.
// Reads one command per line on stdin:
//   play <channel> <token> <volume> <path>   plays a file on a channel, cutting what it was playing
//   stop <channel>                           cuts the channel short
// and writes "done <channel> <token>" when a sound ends on its own or gets cut.
// It quits when stdin closes, so it never outlives nvim.
import AVFoundation
import Foundation

final class Player {
  private let engine = AVAudioEngine()
  private var nodes: [String: AVAudioPlayerNode] = [:]
  private var formats: [String: AVAudioFormat] = [:]
  private var tokens: [String: String] = [:]
  private var buffers: [String: AVAudioPCMBuffer] = [:]

  init() {
    // touching the mixer builds the graph, the engine refuses to start without an output
    _ = engine.mainMixerNode
    try? engine.start()
  }

  private func say(_ line: String) {
    FileHandle.standardOutput.write((line + "\n").data(using: .utf8)!)
  }

  private func buffer(_ path: String) -> AVAudioPCMBuffer? {
    if let cached = buffers[path] {
      return cached
    }
    guard let file = try? AVAudioFile(forReading: URL(fileURLWithPath: path)),
      let read = AVAudioPCMBuffer(
        pcmFormat: file.processingFormat, frameCapacity: AVAudioFrameCount(file.length)),
      (try? file.read(into: read)) != nil
    else {
      return nil
    }
    buffers[path] = read
    return read
  }

  // each channel has its own node, connected again only when a file brings another format
  private func node(_ channel: String, _ format: AVAudioFormat) -> AVAudioPlayerNode {
    let node = nodes[channel] ?? AVAudioPlayerNode()
    if nodes[channel] == nil {
      engine.attach(node)
      nodes[channel] = node
    }
    if formats[channel] != format {
      engine.connect(node, to: engine.mainMixerNode, format: format)
      formats[channel] = format
    }
    return node
  }

  private func finish(_ channel: String, _ token: String) {
    guard tokens[channel] == token else {
      return
    }
    tokens[channel] = nil
    say("done \(channel) \(token)")
  }

  func stop(_ channel: String) {
    guard let token = tokens[channel] else {
      return
    }
    nodes[channel]?.stop()
    finish(channel, token)
  }

  func play(_ channel: String, _ token: String, _ volume: Float, _ path: String) {
    stop(channel)
    guard let sound = buffer(path) else {
      say("done \(channel) \(token)")
      return
    }
    if !engine.isRunning {
      try? engine.start()
    }
    let player = node(channel, sound.format)
    player.volume = volume
    tokens[channel] = token
    player.scheduleBuffer(sound, at: nil, options: .interrupts, completionCallbackType: .dataPlayedBack) {
      _ in
      DispatchQueue.main.async { self.finish(channel, token) }
    }
    player.play()
  }

  func run(_ line: String) {
    let parts = line.split(separator: " ", maxSplits: 4).map(String.init)
    if parts.first == "play", parts.count == 5 {
      play(parts[1], parts[2], Float(parts[3]) ?? 1, parts[4])
    } else if parts.first == "stop", parts.count == 2 {
      stop(parts[1])
    }
  }
}

let player = Player()

// stdin is read off the main thread, every command runs on it where the engine lives
Thread.detachNewThread {
  while let line = readLine() {
    DispatchQueue.main.async { player.run(line) }
  }
  DispatchQueue.main.async { exit(0) }
}
RunLoop.main.run()
