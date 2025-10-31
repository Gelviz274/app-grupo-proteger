# 🛡️ Grupo Proteger

> **Facilitando la vida, protegiendo el futuro.**

Bienvenido a **Grupo Proteger**, una aplicación móvil desarrollada en **Flutter** cuyo propósito es simplificar y agilizar el proceso de afiliación de trabajadores (dependientes, independientes o voluntarios) al sistema de seguridad social colombiano: **Salud, Pensión, Riesgos Laborales y Caja de Compensación Familiar**.

---

## ✨ Características Destacadas

**Grupo Proteger** transforma un proceso tradicionalmente burocrático en una experiencia 100% digital, eficiente y transparente:

- **Afiliación digital integral:** Unifica el proceso para EPS, AFP, ARL y CCF.
- **Seguridad y autenticación:** Registro y acceso protegidos para todos los usuarios.
- **Gestión documental eficiente:** Sube y administra fácilmente los documentos requeridos.
- **UX de alto nivel:** Interfaz moderna, intuitiva y adaptable para Android e iOS.
- **Comunicación clara:** Notificaciones y mensajes que acompañan al usuario en cada paso.

---

## 🛠️ Stack Tecnológico

La aplicación está construida sobre tecnologías modernas y escalables:

| Área         | Tecnología             | Propósito                                       |
| :----------- | :--------------------- | :----------------------------------------------- |
| **Frontend** | 💙 Dart & Flutter      | Desarrollo multiplataforma nativo                |
| **Backend**  | 🟢 Supabase            | Base de datos, autenticación y almacenamiento    |
| **UI/UX**    | 🎨 Google Fonts, Cupertino Icons | Diseño profesional y consistente        |
| **Utilidades** | 📂 file_picker, url_launcher, fluttertoast | Manejo de archivos, enlaces y notificaciones |

---

## 📂 Estructura del Proyecto

Una visión organizada de la arquitectura del repositorio:

```
├── android/                   # Configuración específica para Android
├── ios/                       # Configuración específica para iOS
├── lib/                       # Código fuente principal (modularizado)
│   ├── components/
│   ├── screens/
│   ├── services/
│   └── styles/
|   └── utils/
├── assets/                    # Imágenes, logotipos y recursos estáticos
├── test/                      # Pruebas unitarias y de widgets
├── pubspec.yaml               # Dependencias, SDK y recursos
├── analysis_options.yaml      # Reglas de análisis de código (linting)
└── README.md                  # Este archivo
```

---

## 🚀 Instalación y Puesta en Marcha

Sigue estos pasos para ejecutar la aplicación localmente:

### 1. Requisitos

- **Flutter SDK** versión `3.9.2` o superior
- **Dart SDK**
- IDE compatible (VS Code, Android Studio, IntelliJ)

### 2. Instalación

```bash
# Clona el repositorio
git clone https://github.com/Gelviz274/app-grupo-proteger.git
cd app-grupo-proteger

# Instala las dependencias
flutter pub get

# Ejecuta la aplicación (emulador o dispositivo físico)
flutter run
```

> **Nota:** Es necesario configurar tu propia instancia de **Supabase** y añadir las credenciales correspondientes para el correcto funcionamiento de autenticación y base de datos.

---

## 📦 Dependencias Principales

| Paquete            | Descripción                                            |
| :----------------- | :-----------------------------------------------------|
| supabase_flutter   | Integración con backend Supabase                       |
| fluttertoast       | Mensajes temporales (toast) para el usuario            |
| google_fonts       | Tipografías profesionales de Google                    |
| file_picker        | Selección de documentos para la afiliación             |
| uuid               | Generación de identificadores únicos                   |
| url_launcher       | Apertura de enlaces externos                           |
| app_links          | Deep linking y enlaces dentro de la app                |

Consulta todas las dependencias en [`pubspec.yaml`](https://github.com/Gelviz274/app-grupo-proteger/blob/main/pubspec.yaml).

---

## 🤝 Contribuciones

¡Las contribuciones son bienvenidas!  
Si encuentras un bug, tienes una idea o quieres mejorar el proyecto:

1. Abre un [Issue](https://github.com/Gelviz274/app-grupo-proteger/issues) claro y detallado.
2. Envía un [Pull Request](https://github.com/Gelviz274/app-grupo-proteger/pulls) siguiendo las buenas prácticas del repositorio.

---

**© 2025 Grupo Proteger. Desarrollado con ❤️ y Flutter.**
