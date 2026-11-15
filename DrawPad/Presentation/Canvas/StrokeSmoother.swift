import CoreGraphics

/// Suaviza una línea dibujada a mano: reduce el temblor sin cambiar dónde
/// empieza ni dónde acaba.
///
/// Es una media móvil: cada punto se acerca al promedio de sí mismo y sus dos
/// vecinos, con pesos 1-2-1. Un zigzag pequeño se aplana; una curva amplia
/// apenas cambia. Cada pasada suaviza un poco más.
///
/// No usa PencilKit (solo puntos), así que se puede probar con números.
enum StrokeSmoother {
    /// Pasadas por cada pulsación de "Suavizar trazos". Con más, el efecto de
    /// un solo toque es más fuerte pero las curvas cerradas encogen antes.
    static let defaultPasses = 2

    static func smooth(_ points: [CGPoint], passes: Int = defaultPasses) -> [CGPoint] {
        // Con menos de tres puntos no hay nada entre los extremos que mover.
        guard points.count > 2, passes > 0 else { return points }

        var current = points
        for _ in 0..<passes {
            var next = current
            for index in 1..<(current.count - 1) {
                next[index] = CGPoint(
                    x: (current[index - 1].x + 2 * current[index].x + current[index + 1].x) / 4,
                    y: (current[index - 1].y + 2 * current[index].y + current[index + 1].y) / 4
                )
            }
            current = next
        }
        return current
    }
}
