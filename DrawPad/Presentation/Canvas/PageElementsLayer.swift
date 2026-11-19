import UIKit

/// La capa de textos, imágenes, figuras y conexiones de una hoja. Va **entre el papel y los
/// trazos**: se ve a través del lienzo transparente de PencilKit y los trazos
/// quedan por encima.
///
/// Normalmente no recibe toques (los recibe el lienzo, que está encima). En
/// el modo de mover el lienzo deja de atender toques y esta capa permite
/// seleccionar, arrastrar y, en imágenes y figuras, cambiar el tamaño con un
/// pellizco. Las conexiones se dibujan en una vista aparte, debajo, y se
/// seleccionan tocando cerca de la línea.
///
/// No sabe nada de guardar: avisa de lo que hizo el usuario con
/// `onElementMoved` y `onElementSelected`.
@MainActor
final class PageElementsLayer: UIView {
    /// El usuario soltó un elemento en una posición o tamaño nuevos.
    var onElementMoved: ((UUID, CGRect) -> Void)?
    /// El usuario tocó un elemento, o el fondo (`nil`) para deseleccionar.
    var onElementSelected: ((UUID?) -> Void)?

    var theme = CanvasTheme.light {
        didSet {
            elementViews.values.forEach { $0.apply(theme: theme) }
            connectorsView.theme = theme
        }
    }

    var isArranging = false {
        didSet {
            isUserInteractionEnabled = isArranging
            if !isArranging { select(nil) }
        }
    }

    private var elementViews: [UUID: PageElementView] = [:]
    private let connectorsView = ConnectorsView()
    /// Distancia máxima, en puntos de la hoja, a la que un toque selecciona
    /// una conexión.
    private let connectorHitDistance: CGFloat = 18

    override init(frame: CGRect) {
        super.init(frame: frame)
        isUserInteractionEnabled = false
        connectorsView.isUserInteractionEnabled = false
        addSubview(connectorsView)
        addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(backgroundTapped(_:))))
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        connectorsView.frame = bounds
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("PageElementsLayer se crea por código")
    }

    /// Deja la capa mostrando exactamente estos elementos, en este orden.
    func show(_ elements: [PageElement], selectedID: UUID?) {
        let placed = elements.filter { !$0.isConnector }
        let ids = Set(placed.map(\.id))
        for (id, view) in elementViews where !ids.contains(id) {
            view.removeFromSuperview()
            elementViews[id] = nil
        }
        for element in placed {
            let view = elementViews[element.id] ?? makeView(for: element)
            view.update(with: element, theme: theme)
            bringSubviewToFront(view) // El orden de la lista es el de apilado.
        }
        connectorsView.elements = elements
        connectorsView.selectedID = selectedID
        sendSubviewToBack(connectorsView)
        updateConnectors()
        select(selectedID)
    }

    // MARK: - Privado

    private func makeView(for element: PageElement) -> PageElementView {
        let view = PageElementView(elementID: element.id)
        view.onTapped = { [weak self] id in
            self?.onElementSelected?(id)
        }
        view.onMoved = { [weak self] id, frame in
            self?.onElementMoved?(id, frame)
        }
        view.onFrameChanging = { [weak self] in
            self?.updateConnectors()
        }
        elementViews[element.id] = view
        addSubview(view)
        return view
    }

    private func select(_ id: UUID?) {
        for (elementID, view) in elementViews {
            view.isSelected = elementID == id
        }
    }

    /// Las conexiones se recalculan con los marcos que tienen las vistas en
    /// este momento: así siguen a una figura mientras se arrastra.
    private func updateConnectors() {
        connectorsView.frames = elementViews.mapValues(\.frame)
        connectorsView.setNeedsDisplay()
    }

    /// Un toque fuera de los elementos selecciona la conexión más cercana, si
    /// hay una lo bastante cerca, o quita la selección.
    @objc private func backgroundTapped(_ gesture: UITapGestureRecognizer) {
        let point = gesture.location(in: self)
        let nearest = connectorsView.segments
            .map { (id: $0.connectorID, distance: DiagramGeometry.distance(from: point, toSegmentFrom: $0.start, to: $0.end)) }
            .min { $0.distance < $1.distance }
        if let nearest, nearest.distance <= connectorHitDistance {
            onElementSelected?(nearest.id)
        } else {
            onElementSelected?(nil)
        }
    }
}

/// La vista de un elemento: un texto, una imagen o una figura, con los
/// gestos para tocarlo, arrastrarlo y (imágenes y figuras) cambiarle el tamaño.
@MainActor
private final class PageElementView: UIView {
    let elementID: UUID
    var onTapped: ((UUID) -> Void)?
    var onMoved: ((UUID, CGRect) -> Void)?
    /// El marco está cambiando durante un gesto (para mover las conexiones).
    var onFrameChanging: (() -> Void)?

    var isSelected = false {
        didSet {
            layer.borderWidth = isSelected ? 2 : 0
        }
    }

    private let label = UILabel()
    private let imageView = UIImageView()
    private let shapeView = ShapeView()
    private var content: PageElement.Content?
    /// Marco al empezar un gesto, para calcular el nuevo a partir de él.
    private var frameAtGestureStart = CGRect.zero

    init(elementID: UUID) {
        self.elementID = elementID
        super.init(frame: .zero)
        layer.borderColor = UIColor.systemBlue.cgColor
        layer.cornerRadius = 4

        label.numberOfLines = 0
        label.font = PageElementStyle.font
        imageView.contentMode = .scaleToFill
        for subview in [label, imageView, shapeView] {
            subview.frame = bounds
            subview.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            addSubview(subview)
        }

        addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(tapped)))
        addGestureRecognizer(UIPanGestureRecognizer(target: self, action: #selector(panned)))
        addGestureRecognizer(UIPinchGestureRecognizer(target: self, action: #selector(pinched)))
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("PageElementView se crea por código")
    }

    func update(with element: PageElement, theme: CanvasTheme) {
        if content != element.content {
            content = element.content
            switch element.content {
            case .text(let text):
                label.text = text
                label.isHidden = false
                imageView.isHidden = true
                shapeView.isHidden = true
                // Para VoiceOver y para las pruebas de interfaz.
                isAccessibilityElement = true
                accessibilityLabel = text
                accessibilityTraits = .staticText
            case .image(let data):
                imageView.image = UIImage(data: data)
                imageView.isHidden = false
                label.isHidden = true
                shapeView.isHidden = true
                isAccessibilityElement = true
                accessibilityLabel = "Imagen"
                accessibilityTraits = .image
            case .shape(let shape):
                shapeView.shape = shape
                shapeView.isHidden = false
                label.isHidden = true
                imageView.isHidden = true
                isAccessibilityElement = true
                accessibilityLabel = shape.label.isEmpty ? shape.kind.title : "\(shape.kind.title): \(shape.label)"
                accessibilityTraits = .staticText
            case .mermaid(let diagram):
                imageView.image = UIImage(data: diagram.image)
                imageView.isHidden = false
                label.isHidden = true
                shapeView.isHidden = true
                isAccessibilityElement = true
                accessibilityLabel = "Diagrama Mermaid"
                accessibilityTraits = .image
            case .connector:
                break // Las conexiones no tienen vista propia.
            }
        }
        apply(theme: theme)

        var frame = element.frame
        if case .text(let text) = element.content {
            // El alto de un texto lo decide su contenido, no lo guardado.
            frame.size.height = PageElementStyle.height(of: text, width: frame.width)
        }
        self.frame = frame
    }

    func apply(theme: CanvasTheme) {
        label.textColor = PageElementStyle.textColor(for: theme)
        shapeView.theme = theme
    }

    // MARK: - Gestos

    @objc private func tapped() {
        onTapped?(elementID)
    }

    @objc private func panned(_ gesture: UIPanGestureRecognizer) {
        switch gesture.state {
        case .began:
            frameAtGestureStart = frame
            onTapped?(elementID) // Arrastrar algo también lo selecciona.
        case .changed:
            // En coordenadas de la capa: así el zoom de la hoja no afecta.
            let translation = gesture.translation(in: superview)
            frame.origin = CGPoint(
                x: frameAtGestureStart.origin.x + translation.x,
                y: frameAtGestureStart.origin.y + translation.y
            )
            onFrameChanging?()
        case .ended:
            onMoved?(elementID, frame)
        case .cancelled, .failed:
            frame = frameAtGestureStart
        default:
            break
        }
    }

    @objc private func pinched(_ gesture: UIPinchGestureRecognizer) {
        // Imágenes y figuras cambian de tamaño; un texto se ajusta a su contenido.
        switch content {
        case .some(.image), .some(.shape), .some(.mermaid): break
        default: return
        }
        switch gesture.state {
        case .began:
            frameAtGestureStart = frame
            onTapped?(elementID)
        case .changed:
            // Crece o encoge alrededor de su centro, sin deformarse.
            let start = frameAtGestureStart
            let size = CGSize(width: start.width * gesture.scale, height: start.height * gesture.scale)
            guard min(size.width, size.height) >= PageElementLayout.minimumSide else { return }
            frame = CGRect(
                x: start.midX - size.width / 2,
                y: start.midY - size.height / 2,
                width: size.width,
                height: size.height
            )
            onFrameChanging?()
        case .ended:
            onMoved?(elementID, frame)
        case .cancelled, .failed:
            frame = frameAtGestureStart
            onFrameChanging?()
        default:
            break
        }
    }
}

/// Dibuja una figura de diagrama ocupando toda la vista.
@MainActor
private final class ShapeView: UIView {
    var shape: DiagramShape? {
        didSet { setNeedsDisplay() }
    }

    var theme = CanvasTheme.light {
        didSet { setNeedsDisplay() }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        isOpaque = false
        contentMode = .redraw // Repintar al cambiar de tamaño, no estirar.
        isUserInteractionEnabled = false
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("ShapeView se crea por código")
    }

    override func draw(_ rect: CGRect) {
        guard let shape else { return }
        DiagramRenderer.draw(shape, in: bounds, theme: theme)
    }
}

/// Dibuja todas las conexiones de la hoja. No recibe toques: la capa decide
/// qué conexión se tocó con ``segments``.
@MainActor
private final class ConnectorsView: UIView {
    var elements: [PageElement] = []
    /// Marco actual de cada elemento (el de su vista).
    var frames: [UUID: CGRect] = [:]
    var selectedID: UUID?
    var theme = CanvasTheme.light {
        didSet { setNeedsDisplay() }
    }

    var segments: [DiagramGeometry.Segment] {
        DiagramGeometry.segments(for: elements, frames: frames)
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        isOpaque = false
        contentMode = .redraw
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("ConnectorsView se crea por código")
    }

    override func draw(_ rect: CGRect) {
        DiagramRenderer.draw(segments, theme: theme, highlighted: selectedID)
    }
}
