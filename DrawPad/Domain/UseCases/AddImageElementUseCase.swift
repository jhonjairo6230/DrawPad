import Foundation

/// Añade una imagen a una hoja, reducida si hace falta para que quepa.
struct AddImageElementUseCase {
    private let elements: PageElementRepository
    private let now: () -> Date
    private let makeID: () -> UUID

    init(
        elements: PageElementRepository,
        now: @escaping () -> Date = Date.init,
        makeID: @escaping () -> UUID = UUID.init
    ) {
        self.elements = elements
        self.now = now
        self.makeID = makeID
    }

    /// - Parameters:
    ///   - imageSize: tamaño original de la imagen, en puntos.
    ///   - center: dónde colocarla, en coordenadas de la hoja.
    ///   - maxSize: tamaño máximo al insertarla. La imagen se reduce
    ///     conservando su proporción; nunca se amplía.
    /// - Throws: ``DrawingError/clipboardEmpty`` si la imagen no tiene datos o
    ///   su tamaño no es válido.
    func execute(
        pageID: UUID,
        imageData: Data,
        imageSize: CGSize,
        centeredAt center: CGPoint,
        maxSize: CGSize
    ) throws -> PageElement {
        guard !imageData.isEmpty, imageSize.width > 0, imageSize.height > 0 else {
            throw DrawingError.clipboardEmpty
        }
        let element = PageElement(
            id: makeID(),
            pageID: pageID,
            frame: PageElementLayout.frame(centeredAt: center, size: Self.fit(imageSize, within: maxSize)),
            content: .image(imageData),
            createdAt: now()
        )
        try elements.save(element)
        return element
    }

    /// `size` reducido para caber en `limit`, sin deformar ni ampliar.
    static func fit(_ size: CGSize, within limit: CGSize) -> CGSize {
        let scale = min(1, limit.width / size.width, limit.height / size.height)
        guard scale > 0 else { return size }
        return CGSize(width: size.width * scale, height: size.height * scale)
    }
}
