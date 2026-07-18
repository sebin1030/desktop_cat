import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()

    // NSWindow와 FlutterView는 배경색을 각각 보관한다. 둘 다 clear여야
    // PNG의 투명 영역 뒤로 데스크톱이 보이고 검은 사각형이 생기지 않는다.
    self.isOpaque = false
    self.backgroundColor = NSColor.clear
    flutterViewController.backgroundColor = NSColor.clear

    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)

    RegisterGeneratedPlugins(registry: flutterViewController)

    super.awakeFromNib()
  }
}
