import SwiftUI

/// Si la app permite editar o solo leer.
///
/// En el iPhone, DrawPad **solo lee**: muestra los cuadernos importados, se
/// pasa de hoja y se amplía, pero no se dibuja ni se cambia nada (ver
/// docs/adr/0018). Lo decide ``AppContainer`` y lo reparte por el entorno de
/// SwiftUI, para que cada pantalla esconda lo que no aplica.
private struct CanEditKey: EnvironmentKey {
    static let defaultValue = true
}

extension EnvironmentValues {
    var canEdit: Bool {
        get { self[CanEditKey.self] }
        set { self[CanEditKey.self] = newValue }
    }
}
