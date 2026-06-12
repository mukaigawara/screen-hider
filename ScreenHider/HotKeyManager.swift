import AppKit
import Carbon.HIToolbox

/// システム全体で ⌘⇧D により暗転を解除（Accessibility 権限不要）
final class HotKeyManager {
  static let shared = HotKeyManager()

  private var hotKeyRef: EventHotKeyRef?

  private init() {}

  func register() {
    let hotKeyID = EventHotKeyID(signature: OSType(0x53434849), id: 1)
  var eventSpec = EventTypeSpec(
    eventClass: OSType(kEventClassKeyboard),
    eventKind: UInt32(kEventHotKeyPressed)
  )

  InstallEventHandler(
    GetApplicationEventTarget(),
    { _, event, _ -> OSStatus in
      var receivedID = EventHotKeyID()
      GetEventParameter(
        event,
        UInt32(kEventParamDirectObject),
        UInt32(typeEventHotKeyID),
        nil,
        MemoryLayout<EventHotKeyID>.size,
        nil,
        &receivedID
      )
      if receivedID.id == 1 {
        DispatchQueue.main.async {
          OverlayManager.shared.turnOff()
        }
      }
      return noErr
    },
    1,
    &eventSpec,
    nil,
    nil
  )

  RegisterEventHotKey(
    UInt32(kVK_ANSI_D),
    UInt32(cmdKey | shiftKey),
    hotKeyID,
    GetApplicationEventTarget(),
    0,
    &hotKeyRef
  )
  }
}
