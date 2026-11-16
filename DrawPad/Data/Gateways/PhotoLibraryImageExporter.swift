import Foundation
import Photos

/// Añade imágenes a la app Fotos con el framework `Photos`.
///
/// Pide el permiso mínimo (`.addOnly`): DrawPad puede añadir fotos, pero no
/// leer la fototeca del usuario. El texto del permiso está en `project.yml`
/// (`NSPhotoLibraryAddUsageDescription`).
final class PhotoLibraryImageExporter: ImageLibrary {
    func addPNG(_ pngData: Data) async throws {
        let status = await PHPhotoLibrary.requestAuthorization(for: .addOnly)
        guard status == .authorized || status == .limited else {
            throw DrawingError.photoLibraryAccessDenied
        }
        do {
            try await PHPhotoLibrary.shared().performChanges {
                PHAssetCreationRequest.forAsset().addResource(with: .photo, data: pngData, options: nil)
            }
        } catch {
            throw DrawingError.exportFailed
        }
    }
}
