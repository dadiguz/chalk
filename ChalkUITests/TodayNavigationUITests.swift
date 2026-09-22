import XCTest

final class TodayNavigationUITests: XCTestCase {
    override func setUp() {
        continueAfterFailure = false
    }

    @MainActor
    func testArrowsMoveBetweenDays() {
        let app = XCUIApplication()
        app.launchArguments = ["-seedDemoData"]
        app.launch()

        let previous = app.buttons["Día anterior"]
        let next = app.buttons["Día siguiente"]
        XCTAssertTrue(previous.waitForExistence(timeout: 10))
        XCTAssertTrue(app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Hoy'")).firstMatch.waitForExistence(timeout: 10))

        // Área táctil completa, no solo el ícono de la flecha.
        XCTAssertGreaterThanOrEqual(previous.frame.width, 43.5)
        XCTAssertGreaterThanOrEqual(previous.frame.height, 43.5)

        // Tocar el borde del círculo, lejos del ícono, también debe funcionar.
        previous.coordinate(withNormalizedOffset: CGVector(dx: 0.15, dy: 0.2)).tap()
        XCTAssertTrue(app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Ayer'")).firstMatch.waitForExistence(timeout: 3),
                      "La flecha izquierda no cambió a Ayer")

        XCTAssertTrue(next.isEnabled)
        next.tap()
        XCTAssertTrue(app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Hoy'")).firstMatch.waitForExistence(timeout: 3),
                      "La flecha derecha no regresó a Hoy")
        XCTAssertFalse(next.isEnabled, "No se puede avanzar más allá de hoy")
    }
}
