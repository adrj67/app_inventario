import 'package:flutter/material.dart';

class ProductosFilterController extends ChangeNotifier {
  // Filtros actuales
  int? _categoriaId;
  int? _marcaId;
  int? _ubicacionId;
  String _estado = 'todos';

  // Getters
  int? get categoriaId => _categoriaId;
  int? get marcaId => _marcaId;
  int? get ubicacionId => _ubicacionId;
  String get estado => _estado;

  // Contador interno para forzar rebuild
  int _contador = 0;
  int get contador => _contador;

  /// Aplica un filtro por categoría y limpia los demás
  void filtrarPorCategoria(int categoriaId) {
    _categoriaId = categoriaId;
    _marcaId = null;
    _ubicacionId = null;
    _estado = 'todos';
    _contador++;
    notifyListeners();
  }

  /// Aplica un filtro por marca y limpia los demás
  void filtrarPorMarca(int marcaId) {
    _categoriaId = null;
    _marcaId = marcaId;
    _ubicacionId = null;
    _estado = 'todos';
    _contador++;
    notifyListeners();
  }

  /// Aplica un filtro por ubicación y limpia los demás
  void filtrarPorUbicacion(int ubicacionId) {
    _categoriaId = null;
    _marcaId = null;
    _ubicacionId = ubicacionId;
    _estado = 'todos';
    _contador++;
    notifyListeners();
  }

  /// Limpia todos los filtros
  void limpiar() {
    _categoriaId = null;
    _marcaId = null;
    _ubicacionId = null;
    _estado = 'todos';
    _contador++;
    notifyListeners();
  }
}