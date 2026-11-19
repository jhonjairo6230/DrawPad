import Foundation
import Observation

/// Estado y acciones de una hoja Markdown (patrón MVVM).
///
/// Tiene dos modos: **leer** (el documento formateado) y **editar** (el
/// texto con el teclado). Al escribir se guarda solo, igual que el lienzo: un
/// segundo después de la última tecla (*debounce*), y al salir de la hoja o
/// de la app.
@MainActor
@Observable
final class MarkdownPageViewModel {
    enum Mode: Hashable {
        case read
        case edit
    }

    private(set) var text = ""
    var mode: Mode = .read
    var alert: AlertMessage?
    /// Archivo `.md` listo para compartir.
    var sharedFile: SharedFile?

    private let pageID: UUID
    /// Nombre del archivo al exportar ("Física - Hoja 2").
    private let shareName: String
    private let loadPage: LoadDrawingUseCase
    private let saveMarkdown: SaveMarkdownUseCase
    private let exportMarkdown: ExportMarkdownUseCase
    private let autosaveDelay: Duration

    @ObservationIgnored private var pendingSave: Task<Void, Never>?
    @ObservationIgnored private var hasLoaded = false

    init(
        pageID: UUID,
        shareName: String,
        loadPage: LoadDrawingUseCase,
        saveMarkdown: SaveMarkdownUseCase,
        exportMarkdown: ExportMarkdownUseCase,
        autosaveDelay: Duration = .seconds(1)
    ) {
        self.pageID = pageID
        self.shareName = shareName
        self.loadPage = loadPage
        self.saveMarkdown = saveMarkdown
        self.exportMarkdown = exportMarkdown
        self.autosaveDelay = autosaveDelay
    }

    var hasPendingChanges: Bool { pendingSave != nil }

    func onAppear() {
        guard !hasLoaded else { return }
        hasLoaded = true
        do {
            text = try loadPage.execute(id: pageID).markdown
        } catch {
            alert = AlertMessage(error: error)
        }
    }

    /// El usuario escribió: se guarda cuando deje de teclear.
    func updateText(_ newText: String) {
        guard newText != text else { return }
        text = newText
        pendingSave?.cancel()
        let delay = autosaveDelay
        pendingSave = Task { [weak self] in
            do {
                try await Task.sleep(for: delay)
            } catch {
                return
            }
            self?.saveNow()
        }
    }

    func flushPendingSave() {
        guard hasPendingChanges else { return }
        saveNow()
    }

    func discardPendingSave() {
        pendingSave?.cancel()
        pendingSave = nil
    }

    /// Guarda lo pendiente y abre la hoja de compartir con el `.md`.
    func export() {
        flushPendingSave()
        do {
            let url = try exportMarkdown.execute(id: pageID, name: shareName)
            sharedFile = SharedFile(url: url)
        } catch {
            alert = AlertMessage(error: error)
        }
    }

    private func saveNow() {
        pendingSave?.cancel()
        pendingSave = nil
        do {
            try saveMarkdown.execute(id: pageID, markdown: text)
        } catch {
            alert = AlertMessage(error: error)
        }
    }
}
