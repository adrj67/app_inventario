import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

class LogoService {
  static const String _carpetaApp = 'InventarioPro';
  static const String _prefijoLogo = 'logo_';

  // Carpeta donde se guarda el logo
  static Future<Directory> _obtenerCarpetaLogo() async {
    final documents = await getApplicationDocumentsDirectory();
    final carpeta = Directory(path.join(documents.path, _carpetaApp));

    if (!await carpeta.exists()) {
      await carpeta.create(recursive: true);
    }

    return carpeta;
  }

  // Abre el selector de archivos y devuelve la ruta elegida
  static Future<String?> seleccionarArchivo() async {
    final resultado = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
      dialogTitle: 'Seleccionar logo de la empresa',
    );

    if (resultado == null || resultado.files.isEmpty) return null;
    return resultado.files.first.path;
  }

  // Copia el archivo a la carpeta de la app con un nombre ÚNICO
  // Devuelve la nueva ruta
  static Future<String> copiarLogo(String rutaOrigen) async {
    final carpeta = await _obtenerCarpetaLogo();

    // 1. Eliminar TODOS los logos viejos
    await _eliminarTodosLosLogos();

    // 2. Obtener extensión del archivo
    final extension = path.extension(rutaOrigen).toLowerCase();
    final extensionFinal = extension.isEmpty ? '.png' : extension;

    // 3. Generar nombre ÚNICO con timestamp
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final nombreArchivo = '$_prefijoLogo$timestamp$extensionFinal';
    final destino = path.join(carpeta.path, nombreArchivo);

    // 4. Copiar el archivo
    final archivoOrigen = File(rutaOrigen);
    await archivoOrigen.copy(destino);

    return destino;
  }

  // Elimina TODOS los archivos que empiecen con "logo_"
  static Future<void> _eliminarTodosLosLogos() async {
    try {
      final carpeta = await _obtenerCarpetaLogo();
      if (!await carpeta.exists()) return;

      final archivos = carpeta.listSync();
      for (final archivo in archivos) {
        if (archivo is File) {
          final nombre = path.basename(archivo.path);
          if (nombre.startsWith(_prefijoLogo)) {
            try {
              await archivo.delete();
            } catch (e) {
              // Ignorar errores
            }
          }
        }
      }
    } catch (e) {
      // Ignorar errores
    }
  }

  // Obtiene la ruta del logo actual (si existe y el archivo está presente)
  static Future<String?> obtenerRutaLogo() async {
    try {
      final carpeta = await _obtenerCarpetaLogo();
      if (!await carpeta.exists()) return null;

      final archivos = carpeta.listSync();
      for (final archivo in archivos) {
        if (archivo is File) {
          final nombre = path.basename(archivo.path);
          if (nombre.startsWith(_prefijoLogo)) {
            // Verificar que el archivo exista y tenga contenido
            final stat = await archivo.stat();
            if (stat.size > 0) {
              return archivo.path;
            }
          }
        }
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  // Elimina el logo actual
  static Future<void> eliminarLogo() async {
    await _eliminarTodosLosLogos();
  }

  // Verifica si hay un logo configurado
  static Future<bool> tieneLogo() async {
    final ruta = await obtenerRutaLogo();
    return ruta != null;
  }
}