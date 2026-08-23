import 'package:flutter/material.dart';
import 'models/orden_mantenimiento.dart';

/// Tema visual de la aplicacion (AutoRent Perú).
class AppTheme {
  static const Color primario = Color(0xFF1565C0);

  static ThemeData get theme => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: primario),
        scaffoldBackgroundColor: const Color(0xFFF5F7FA),
        appBarTheme: const AppBarTheme(
          backgroundColor: primario,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        cardTheme: CardThemeData(
          elevation: 1,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(),
          isDense: true,
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
      );
}

/// Color asociado a cada estado de la orden (para chips y badges).
Color colorEstado(String estado) {
  switch (estado) {
    case EstadoOrden.pendienteInspeccion:
      return Colors.blueGrey;
    case EstadoOrden.inspeccionCompleta:
    case EstadoOrden.inspeccionPostergada:
      return Colors.indigo;
    case EstadoOrden.pendienteAutorizacion:
      return Colors.orange;
    case EstadoOrden.presupuestoAutorizado:
      return Colors.teal;
    case EstadoOrden.enMantenimiento:
      return Colors.purple;
    case EstadoOrden.pendienteConformidad:
      return Colors.amber.shade800;
    case EstadoOrden.correccionRequerida:
      return Colors.deepOrange;
    case EstadoOrden.cerrado:
      return Colors.green;
    case EstadoOrden.cerradaPorRechazo:
      return Colors.red;
    default:
      return Colors.grey;
  }
}
