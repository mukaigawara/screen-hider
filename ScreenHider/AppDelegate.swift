import AppKit
import Combine

final class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {
  private var statusItem: NSStatusItem?
  private var cancellables = Set<AnyCancellable>()

  private let menu = NSMenu()
  private let toggleMenuItem = NSMenuItem()
  private let fadeSubmenu = NSMenu()
  private let fadeSubmenuItem = NSMenuItem()

  func applicationDidFinishLaunching(_ notification: Notification) {
    let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    statusItem = item

    setupMenu()
    item.menu = menu
    menu.delegate = self

    OverlayManager.shared.$isDimmed
      .receive(on: DispatchQueue.main)
      .sink { [weak self] _ in
        self?.updateStatusItemImage()
      }
      .store(in: &cancellables)

    OverlayManager.shared.startObservingScreenChanges()
    HotKeyManager.shared.register()
    OverlayManager.shared.applyDimmingIfNeeded()
    updateStatusItemImage()
  }

  private func setupMenu() {
    toggleMenuItem.target = self
    toggleMenuItem.action = #selector(toggleFromMenu)
    menu.addItem(toggleMenuItem)

    menu.addItem(NSMenuItem.separator())

    fadeSubmenuItem.title = "アニメーション"
    fadeSubmenuItem.submenu = fadeSubmenu
    menu.addItem(fadeSubmenuItem)

    menu.addItem(NSMenuItem.separator())

    let helpHeader = NSMenuItem(title: "解除方法（暗転中）", action: nil, keyEquivalent: "")
    helpHeader.isEnabled = false
    menu.addItem(helpHeader)

    let helpClick = NSMenuItem(title: "  暗い画面をクリック", action: nil, keyEquivalent: "")
    helpClick.isEnabled = false
    menu.addItem(helpClick)

    let helpEsc = NSMenuItem(title: "  Esc キー", action: nil, keyEquivalent: "")
    helpEsc.isEnabled = false
    menu.addItem(helpEsc)

    let helpHotKey = NSMenuItem(title: "  ⌘⇧D", action: nil, keyEquivalent: "")
    helpHotKey.isEnabled = false
    menu.addItem(helpHotKey)

    menu.addItem(NSMenuItem.separator())

    let quitItem = NSMenuItem(title: "ScreenHiderを終了", action: #selector(quit), keyEquivalent: "q")
    quitItem.target = self
    menu.addItem(quitItem)

    refreshMenu()
  }

  func menuWillOpen(_ menu: NSMenu) {
    refreshMenu()
  }

  private func refreshMenu() {
    toggleMenuItem.title = OverlayManager.shared.isDimmed ? "明るくする" : "画面を暗くする"

    fadeSubmenu.removeAllItems()

    let offItem = NSMenuItem(
      title: "なし",
      action: #selector(setFadeAnimation(_:)),
      keyEquivalent: ""
    )
    offItem.target = self
    offItem.representedObject = NSNumber(value: false)
    if !OverlayManager.shared.fadeAnimationEnabled {
      offItem.state = .on
    }
    fadeSubmenu.addItem(offItem)

    let onItem = NSMenuItem(
      title: "あり",
      action: #selector(setFadeAnimation(_:)),
      keyEquivalent: ""
    )
    onItem.target = self
    onItem.representedObject = NSNumber(value: true)
    if OverlayManager.shared.fadeAnimationEnabled {
      onItem.state = .on
    }
    fadeSubmenu.addItem(onItem)
  }

  @objc private func toggleFromMenu() {
    OverlayManager.shared.toggle()
  }

  @objc private func setFadeAnimation(_ sender: NSMenuItem) {
    guard let number = sender.representedObject as? NSNumber else { return }
    OverlayManager.shared.setFadeAnimationEnabled(number.boolValue)
  }

  @objc private func quit() {
    OverlayManager.shared.turnOff()
    NSApp.terminate(nil)
  }

  private func updateStatusItemImage() {
    let symbolName = OverlayManager.shared.isDimmed ? "moon.fill" : "sun.max.fill"
    let image = NSImage(systemSymbolName: symbolName, accessibilityDescription: "ScreenHider")
    image?.isTemplate = true
    statusItem?.button?.image = image
    statusItem?.button?.imagePosition = .imageOnly
  }
}
