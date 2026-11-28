import Foundation

/// Escribe y lee cuadernos en archivos `.drawpad`: un JSON con todo el
/// cuaderno (los datos binarios, en Base64).
///
/// El JSON no usa las entidades de dominio directamente sino tipos propios
/// (`ArchiveFile`…): así el formato del archivo no cambia sin querer si
/// cambia una entidad, y se puede leer un archivo de una versión anterior.
///
/// Cada archivo lleva `format` y `version`. Esta app escribe la versión
/// ``currentVersion`` y lee esa y las anteriores; una más nueva se rechaza
/// con un mensaje claro.
///
/// Versiones:
/// - 1: cuadernos de dibujo.
/// - 2: hojas Markdown (`kind` y `markdown` en cada hoja). Una app que solo
///   conoce la 1 las rechaza en vez de leerlas como hojas de dibujo vacías.
struct JSONNotebookArchiveCoder: NotebookArchiveCoder {
    static let formatIdentifier = "drawpad-notebook"
    static let currentVersion = 2

    let fileExtension = "drawpad"

    func encode(_ bundle: NotebookBundle) throws -> Data {
        let file = ArchiveFile(
            format: Self.formatIdentifier,
            version: Self.currentVersion,
            notebook: NotebookDTO(bundle.notebook),
            pages: bundle.pages.map(PageDTO.init),
            elements: bundle.elements.map(ElementDTO.init)
        )
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        do {
            return try encoder.encode(file)
        } catch {
            throw DrawingError.exportFailed
        }
    }

    func decode(_ data: Data) throws -> NotebookBundle {
        // Primero solo la cabecera: así un archivo más nuevo, con campos que
        // esta versión no conoce, da el mensaje correcto y no "archivo dañado".
        guard let header = try? JSONDecoder().decode(ArchiveHeader.self, from: data),
              header.format == Self.formatIdentifier else {
            throw DrawingError.importFailed
        }
        guard header.version <= Self.currentVersion else {
            throw DrawingError.unsupportedArchiveVersion
        }
        guard let file = try? JSONDecoder().decode(ArchiveFile.self, from: data) else {
            throw DrawingError.importFailed
        }
        let notebook = file.notebook.entity
        return NotebookBundle(
            notebook: notebook,
            pages: file.pages.map { $0.entity(notebookID: notebook.id) },
            elements: file.elements.compactMap(\.entity)
        )
    }
}

// MARK: - Formato del archivo (versiones 1 y 2)

private struct ArchiveHeader: Decodable {
    let format: String
    let version: Int
}

private struct ArchiveFile: Codable {
    let format: String
    let version: Int
    let notebook: NotebookDTO
    let pages: [PageDTO]
    let elements: [ElementDTO]
}

private struct NotebookDTO: Codable {
    let id: UUID
    let title: String
    let createdAt: Date
    let coverColor: String
    let coverStyle: String
    let coverStrokes: Data?
    let coverImage: Data?

    init(_ notebook: Notebook) {
        id = notebook.id
        title = notebook.title
        createdAt = notebook.createdAt
        coverColor = notebook.cover.color.rawValue
        coverStyle = notebook.cover.style.rawValue
        coverStrokes = notebook.cover.drawing?.strokesData
        coverImage = notebook.cover.drawing?.imageData
    }

    var entity: Notebook {
        var drawing: CoverDrawing?
        if let coverStrokes, let coverImage {
            drawing = CoverDrawing(strokesData: coverStrokes, imageData: coverImage)
        }
        return Notebook(
            id: id,
            title: title,
            createdAt: createdAt,
            cover: NotebookCover(
                // Un valor desconocido (de una versión futura) cae en el estándar.
                color: CoverColor(rawValue: coverColor) ?? NotebookCover.standard.color,
                style: CoverStyle(rawValue: coverStyle) ?? NotebookCover.standard.style,
                drawing: drawing
            )
        )
    }
}

private struct PageDTO: Codable {
    let id: UUID
    let strokes: Data
    let thumbnail: Data?
    let createdAt: Date
    let updatedAt: Date
    let background: String
    let theme: String
    /// Versión 2. En archivos de la versión 1 no está: hoja de dibujo.
    let kind: String?
    let markdown: String?

    init(_ page: Drawing) {
        id = page.id
        strokes = page.strokesData
        thumbnail = page.thumbnailData
        createdAt = page.createdAt
        updatedAt = page.updatedAt
        background = page.background.rawValue
        theme = page.theme.rawValue
        kind = page.kind.rawValue
        markdown = page.kind == .markdown ? page.markdown : nil
    }

    /// La hoja siempre pertenece al cuaderno del archivo.
    func entity(notebookID: UUID) -> Drawing {
        Drawing(
            id: id,
            notebookID: notebookID,
            strokesData: strokes,
            thumbnailData: thumbnail,
            createdAt: createdAt,
            updatedAt: updatedAt,
            background: CanvasBackground(rawValue: background) ?? .blank,
            theme: CanvasTheme(rawValue: theme) ?? .light,
            kind: kind.flatMap(PageKind.init(rawValue:)) ?? .drawing,
            markdown: markdown ?? ""
        )
    }
}

private struct ElementDTO: Codable {
    let id: UUID
    let pageID: UUID
    let kind: String
    let x: Double
    let y: Double
    let width: Double
    let height: Double
    let createdAt: Date
    var text: String?
    var image: Data?
    var shape: String?
    var quarterTurns: Int?
    var fromID: UUID?
    var toID: UUID?
    var connectorStyle: String?

    init(_ element: PageElement) {
        id = element.id
        pageID = element.pageID
        x = element.frame.origin.x
        y = element.frame.origin.y
        width = element.frame.width
        height = element.frame.height
        createdAt = element.createdAt
        switch element.content {
        case .text(let value):
            kind = "text"
            text = value
        case .image(let value):
            kind = "image"
            image = value
        case .shape(let value):
            kind = "shape"
            text = value.label
            shape = value.kind.rawValue
            quarterTurns = value.quarterTurns
        case .mermaid(let value):
            kind = "mermaid"
            text = value.source
            image = value.image
        case .connector(let value):
            kind = "connector"
            fromID = value.fromID
            toID = value.toID
            connectorStyle = value.style.rawValue
        }
    }

    /// `nil` si el tipo es desconocido o le faltan datos: ese elemento se
    /// omite, el resto del cuaderno se importa igual.
    var entity: PageElement? {
        let content: PageElement.Content
        switch kind {
        case "text":
            guard let text else { return nil }
            content = .text(text)
        case "image":
            guard let image else { return nil }
            content = .image(image)
        case "shape":
            guard let shapeKind = shape.flatMap(ShapeKind.init(rawValue:)) else { return nil }
            content = .shape(DiagramShape(
                kind: shapeKind,
                label: text ?? "",
                quarterTurns: ((quarterTurns ?? 0) % 4 + 4) % 4
            ))
        case "mermaid":
            guard let text, let image else { return nil }
            content = .mermaid(MermaidDiagram(source: text, image: image))
        case "connector":
            guard let fromID, let toID else { return nil }
            content = .connector(Connector(
                fromID: fromID,
                toID: toID,
                style: connectorStyle.flatMap(ConnectorStyle.init(rawValue:)) ?? .arrow
            ))
        default:
            return nil
        }
        return PageElement(
            id: id,
            pageID: pageID,
            frame: CGRect(x: x, y: y, width: width, height: height),
            content: content,
            createdAt: createdAt
        )
    }
}
