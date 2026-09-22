import Foundation
import Testing
@testable import Chalk

struct HandwritingLayoutTests {
    @Test(arguments: ["Chalkduster", "RealChalk"])
    func buildsStrokesForEveryLetter(fontName: String) async {
        let start = ContinuousClock.now
        let layout = await HandwritingLayout.make(text: "Chalk", fontName: fontName, fontSize: 104)
        print("⏱ \(fontName): \(ContinuousClock.now - start), strokes: \(layout.strokes.count), brush: \(layout.brushWidth), size: \(layout.size)")
        #expect(layout.strokes.count >= 5)
        #expect(layout.brushWidth > 0)
    }
}
