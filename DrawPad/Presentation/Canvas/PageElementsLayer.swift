import UIKit

/// La capa de textos e imágenes de una hoja. Va **entre el papel y los
/// trazos**: se ve a través del lienzo transparente de PencilKit y los trazos
/// quedan por encima.
///
/// Normalmente no recibe toques (los recibe el lienzo, que está encima). En
/// el modo "mover texto e imágenes" el lienzo deja de atender toques y esta
/// capa permite seleccionar, arrastrar y, en las imágenes, cambiar el tamaño
/// con un pellizco.
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
        didSet { elementViews.values.forEach { $0.apply(theme: theme) } }
    }

    var isArranging = false {
        didSet {
            isUserInteractionEnabled = isArranging
            if !isArranging { select(nil) }
        }
    }

    private var elementViews: [UUID: PageElementView] = [:]

    override init(frame: CGRect) {
        super.init(frame: frame)
        isUserInteractionEnabled = false
        addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(backgroundTapped)))
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("PageElementsLayer se crea por código")
    }

    /// Deja la capa mostrando exactamente estos elementos, en este orden.
    func show(_ elements: [PageElement], selectedID: UUID?) {
        let ids = Set(elements.map(\.id))
        for (id, view) in elementViews where !ids.contains(id) {
            view.removeFromSuperview()
            elementViews[id] = nil
        }
        for element in elements {
            let view = elementViews[element.id] ?? makeView(for: element)
            view.update(with: element, theme: theme)
            bringSubviewToFront(view) // El orden de la lista es el de apilado.
        }
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
        elementViews[element.id] = view
        addSubview(view)
        return view
    }

    private func select(_ id: UUID?) {
        for (elementID, view) in elementViews {
            view.isSelected = elementID == id
        }
    }

    @objc private func backgroundTapped() {
        onElementSelected?(nil)
    }
}

/// La vista de un elemento: una etiqueta de texto o una imagen, con los
/// gestos para tocarlo, arrastrarlo y (si es imagen) cambiarle el tamaño.
@MainActor
private final class PageElementView: UIView {
    let elementID: UUID
    var onTapped: ((UUID) -> Void)?
    var onMoved: ((UUID, CGRect) -> Void)?

    var isSelected = false {
        didSet {
            layer.borderWidth = isSelected ? 2 : 0
        }
    }

    private let label = UILabel()
    private let imageView = UIImageView()
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
        for subview in [label, imageView] {
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
                // Para VoiceOver y para las pruebas de interfaz.
                isAccessibilityElement = true
                accessibilityLabel = text
                accessibilityTraits = .staticText
            case .image(let data):
                imageView.image = UIImage(data: data)
                imageView.isHidden = false
                label.isHidden = true
                isAccessibilityElement = true
                accessibilityLabel = "Imagen"
                accessibilityTraits = .image
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
        case .ended:
            onMoved?(elementID, frame)
        case .cancelled, .failed:
            frame = frameAtGestureStart
        default:
            break
        }
    }

    @objc private func pinched(_ gesture: UIPinchGestureRecognizer) {
        // Solo las imágenes cambian de tamaño; un texto se ajusta a su contenido.
        guard case .image = content else { return }
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
        case .ended:
            onMoved?(elementID, frame)
        case .cancelled, .failed:
            frame = frameAtGestureStart
        default:
            break
        }
    }
}
