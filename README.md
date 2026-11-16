# FIXA — App del ciudadano (Flutter, Android)

El vecino reporta baches, fallas de alumbrado y microbasurales sin crear cuenta, recibe un
código y una clave, y consulta el avance de su reporte. Equipo DevCore, Univalle Santa Cruz, 2-2026.

La app habla con la API en ASP.NET ([Fixa_API](https://github.com/helendrg14-em/Fixa_API)),
solo con las rutas públicas `/api/v1/publico`.

## Qué hace

| Requerimiento | Dónde |
|---|---|
| R04: reporte con categoría, foto y ubicación | `lib/features/reportar` |
| RNF04: la foto viaja en WebP y pesa menos de 3 MB | `reportar_screen.dart` |
| R05: código y clave de seguimiento | `lib/features/seguimiento/enviado_screen.dart` |
| R06: seguimiento con código y clave, o desde «Mis reportes» | `lib/features/seguimiento` |
| Mapa de casos y aviso de casos cercanos | `lib/features/mapa`, `lib/features/reportar/alerta_cercano.dart` |

## Ejecutar

```bash
flutter pub get
flutter run
```

Por defecto usa la API publicada en Render. Para otra API o datos de ejemplo:

```bash
flutter run --dart-define=FIXA_API=http://10.0.2.2:5112/api/v1/publico
flutter run --dart-define=FIXA_MOCK=true
```

`10.0.2.2` es tu PC vista desde el emulador de Android.

## Pruebas

```bash
flutter analyze
flutter test
```

Corren solas en GitHub en cada push y pull request (`.github/workflows/ci.yml`).

## Seguridad

- Sin cuenta ni datos personales: solo se guardan en el celular el código y la clave de cada
  reporte, cifrados con `flutter_secure_storage`.
- Toda la comunicación va por HTTPS; la app no acepta tráfico sin cifrar.
- Cada envío lleva una clave de idempotencia: si se corta la señal y se reenvía, no se duplica.

## Publicar el APK

```bash
flutter build apk --release
```

El archivo se sube como `fixa.apk` a GitHub Releases; el portal enlaza siempre a la última versión.
