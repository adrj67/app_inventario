/*
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../config/demo_config.dart';
import 'package:window_manager/window_manager.dart';

class DemoExpiradaPage extends StatelessWidget {
  const DemoExpiradaPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 550),
          child: Card(
            elevation: 8,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Padding(
              padding: const EdgeInsets.all(40),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Ícono de candado
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.lock_outline,
                      size: 60,
                      color: Colors.red.shade700,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Título
                  Text(
                    'Tu prueba ha expirado',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade800,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),

                  // Subtítulo
                  Text(
                    'Gracias por probar Inventario Pro durante ${DemoConfig.diasDemo} días.',
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.grey.shade600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Para seguir usando la aplicación, contactanos para adquirir la licencia.\nTus datos están a salvo.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),

                  // Datos de contacto
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'CONTACTANOS',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade900,
                            letterSpacing: 1.5,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildContactoRow(
                          Icons.email,
                          DemoConfig.emailContacto,
                          Colors.blue.shade700,
                        ),
                        const SizedBox(height: 12),
                        _buildContactoRow(
                          Icons.phone,
                          DemoConfig.telefonoContacto,
                          Colors.green.shade700,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Botón para cerrar
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        // Cerrar la aplicación
                        await windowManager.close();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade700,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      icon: const Icon(Icons.exit_to_app),
                      label: const Text(
                        'Cerrar aplicación',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Texto legal
                  Text(
                    'Tus datos están a salvo.\nSi comprás la licencia, no perderás nada.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade500,
                      fontStyle: FontStyle.italic,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContactoRow(IconData icono, String texto, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icono, size: 18, color: color),
        const SizedBox(width: 8),
        SelectableText(
          texto,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }
}
*/

import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import '../config/demo_config.dart';
import '../services/demo_service.dart';

class DemoExpiradaPage extends StatelessWidget {
  const DemoExpiradaPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 550),
          child: Card(
            elevation: 8,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Ícono de candado
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.lock_outline,
                      size: 60,
                      color: Colors.red.shade700,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Título
                  Text(
                    'Tu prueba ha expirado.\n\nTus datos están a salvo.\nSi comprás la licencia, \nno perderás nada.',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade800,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),

                  // Subtítulo
                  Text(
                    'Gracias por probar Inventario Pro durante ${DemoConfig.diasDemo} días.',
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.grey.shade800,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Para seguir usando la aplicación, contactanos para adquirir la licencia.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),

                  // Datos de contacto
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'CONTACTANOS',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade900,
                            letterSpacing: 1.5,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildContactoRow(
                          Icons.email,
                          DemoConfig.emailContacto,
                          Colors.blue.shade700,
                        ),
                        const SizedBox(height: 12),
                        _buildContactoRow(
                          Icons.phone,
                          DemoConfig.telefonoContacto,
                          Colors.green.shade700,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Botón para cerrar
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        // 🔥 Cerrar la app correctamente en Windows
                        await windowManager.close();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade700,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      icon: const Icon(Icons.exit_to_app),
                      label: const Text(
                        'Cerrar aplicación',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),

                  // 🔥 NUEVO: Botón resetear (solo en modo prueba)
                  if (DemoConfig.modoPruebaRapida) ...[
                    const SizedBox(height: 16),
                    TextButton.icon(
                      onPressed: () async {
                        await DemoService.resetear();
                        await windowManager.close();
                      },
                      icon: const Icon(Icons.refresh, size: 16),
                      label: const Text('Resetear demo (DEV)'),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.orange.shade700,
                      ),
                    ),
                  ],

                  const SizedBox(height: 12),

                  // Texto legal
                  /*Text(
                    'Tus datos están a salvo.\nSi comprás la licencia, no perderás nada.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade500,
                      fontStyle: FontStyle.italic,
                    ),
                    textAlign: TextAlign.center,
                  ),*/
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContactoRow(IconData icono, String texto, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icono, size: 18, color: color),
        const SizedBox(width: 8),
        SelectableText(
          texto,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }
}