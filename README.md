# app_inventario_flutter

*** 
Base de Datos: Documentos\inventario.db

Remove-Item "$env:USERPROFILE\Documents\inventario.db" -ErrorAction SilentlyContinue

(C:\Users\***\AppData\Roaming\com.example\app_inventario_flutter)

***



A new Flutter project.

lib/
├── models/
│   └── proveedor.dart         ✓ (Ya lo tienes)
├── database/
│   ├── database_helper.dart   # NUEVO: Gestión de DB
│   └── proveedor_repository.dart  # NUEVO: Operaciones CRUD
├── screens/
│   ├── main_layout.dart       ✓ (Ya lo tienes)
│   └── pages/
│       ├── proveedores/
│       │   ├── proveedores_page.dart     # Página principal
│       │   ├── proveedores_list.dart     # Lista con búsqueda
│       │   ├── proveedor_card.dart       # Tarjeta individual
│       │   ├── proveedor_form.dart       # Formulario (Alta/Edición)
│       │   └── proveedor_controller.dart # Lógica de negocio
│       └── (otros pages...)
└── widgets/
    ├── main_app_bar.dart
    ├── main_drawer.dart
    ├── search_field.dart      # NUEVO: Campo de búsqueda reutilizable
    └── confirmation_dialog.dart # NUEVO: Diálogo de confirmación