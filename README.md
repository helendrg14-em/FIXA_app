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

## Qué instalar (una sola vez)

| Programa | Para qué | Cómo comprobarlo |
|---|---|---|
| [Flutter **3.47.7**](https://docs.flutter.dev/install) | Compilar la app (la misma versión que el CI) | `flutter --version` |
| [Android Studio](https://developer.android.com/studio) | El SDK de Android y el emulador | `flutter doctor` sin errores en Android |
| Un emulador o un celular Android con depuración USB | Ejecutar la app | `flutter devices` |

En Android Studio: **More Actions → Virtual Device Manager → Create device**, elige un Pixel y
una imagen reciente de Android. Después acepta las licencias con `flutter doctor --android-licenses`.

No necesitas Docker ni el panel para trabajar en la app.

## Ejecutar

```bash
git clone https://github.com/helendrg14-em/FIXA_app.git
cd FIXA_app
git checkout develop
flutter pub get
flutter run
```

Por defecto usa la **API publicada en Render**: no hace falta configurar nada. Si estuvo
inactiva, el primer envío puede tardar hasta un minuto mientras despierta.

Otras opciones:

```bash
flutter run --dart-define=FIXA_API=http://10.0.2.2:5112/api/v1/publico
flutter run --dart-define=FIXA_MOCK=true
```

- La primera usa la **API de tu PC** (ver el README de Fixa_API). `10.0.2.2` es tu PC vista
  desde el emulador. Solo las versiones de desarrollo aceptan `http`, y solo hacia tu PC
  (`android/app/src/debug/res/xml/network_security_config.xml`); el APK publicado exige HTTPS.
- La segunda usa **datos de ejemplo** sin ninguna API, útil para trabajar en las pantallas.

### Problemas comunes

| Síntoma | Causa | Solución |
|---|---|---|
| `flutter doctor` marca Android en rojo | Falta el SDK o las licencias | Abre Android Studio una vez y ejecuta `flutter doctor --android-licenses` |
| `No devices found` | No hay emulador abierto | Inícialo desde el Virtual Device Manager |
| "No hay conexión con FIXA" | La API está despertando o no está levantada | Espera un minuto, o revisa que tu API local responda en `/salud` |
| La cámara o el GPS no funcionan en el emulador | El emulador no tiene cámara ni ubicación real | En el emulador, **⋯ → Location** para fijar una ubicación; la cámara usa una escena virtual |

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
