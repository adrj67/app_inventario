abstract class BaseModel {
  int? id;
  bool activo = true;
  DateTime fechaCreacion = DateTime.now();
  DateTime fechaModificacion = DateTime.now();

  Map<String, dynamic> toMap();
  void fromMap(Map<String, dynamic> map);
}