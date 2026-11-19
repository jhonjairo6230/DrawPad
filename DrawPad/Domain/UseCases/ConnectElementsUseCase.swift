import Foundation

/// Une dos elementos de la misma hoja con una flecha o una línea.
struct ConnectElementsUseCase {
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

    /// Si ya hay una conexión entre esos dos elementos (en ese sentido), la
    /// devuelve con el estilo pedido en lugar de duplicarla.
    /// - Throws: ``DrawingError/invalidConnection`` si se une un elemento
    ///   consigo mismo o con una conexión, o ``DrawingError/elementNotFound``
    ///   si alguno no está en la hoja.
    func execute(pageID: UUID, from fromID: UUID, to toID: UUID, style: ConnectorStyle) throws -> PageElement {
        guard fromID != toID else { throw DrawingError.invalidConnection }
        let onPage = try elements.listElements(pageID: pageID)
        guard let from = onPage.first(where: { $0.id == fromID }),
              let to = onPage.first(where: { $0.id == toID }) else {
            throw DrawingError.elementNotFound
        }
        guard !from.isConnector, !to.isConnector else { throw DrawingError.invalidConnection }

        let existing = onPage.first { element in
            guard case .connector(let connector) = element.content else { return false }
            return connector.fromID == fromID && connector.toID == toID
        }
        if var existing, case .connector(var connector) = existing.content {
            connector.style = style
            existing.content = .connector(connector)
            try elements.save(existing)
            return existing
        }

        let element = PageElement(
            id: makeID(),
            pageID: pageID,
            frame: .zero,
            content: .connector(Connector(fromID: fromID, toID: toID, style: style)),
            createdAt: now()
        )
        try elements.save(element)
        return element
    }
}
