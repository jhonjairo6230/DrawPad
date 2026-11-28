import Foundation

/// Una hoja Markdown abierta: su ViewModel y la vista web que la formatea,
/// creados juntos por ``AppContainer``. Para el cuaderno es una hoja más
/// (``PageSession``).
@MainActor
final class MarkdownPageModule: Identifiable {
    let viewModel: MarkdownPageViewModel
    let renderer: WebKitMarkdownRenderer

    init(viewModel: MarkdownPageViewModel, renderer: WebKitMarkdownRenderer) {
        self.viewModel = viewModel
        self.renderer = renderer
    }
}

extension MarkdownPageModule: PageSession {
    func flushPendingSave() {
        viewModel.flushPendingSave()
    }

    func discardPendingSave() {
        viewModel.discardPendingSave()
    }
}
