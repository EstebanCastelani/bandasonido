import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_it.dart';
import 'app_localizations_pt.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('es'),
    Locale('fr'),
    Locale('it'),
    Locale('pt')
  ];

  /// No description provided for @tuRolPodesMarcarMas.
  ///
  /// In es, this message translates to:
  /// **'Tu rol (podés marcar más de uno)'**
  String get tuRolPodesMarcarMas;

  /// No description provided for @inicioDeSesionConGoogle.
  ///
  /// In es, this message translates to:
  /// **'Inicio de sesión con Google cancelado.'**
  String get inicioDeSesionConGoogle;

  /// No description provided for @elEmailNoEsValido.
  ///
  /// In es, this message translates to:
  /// **'El email no es válido.'**
  String get elEmailNoEsValido;

  /// No description provided for @estaCuentaFueDeshabilitada.
  ///
  /// In es, this message translates to:
  /// **'Esta cuenta fue deshabilitada.'**
  String get estaCuentaFueDeshabilitada;

  /// No description provided for @noExisteUnaCuentaCon.
  ///
  /// In es, this message translates to:
  /// **'No existe una cuenta con ese email.'**
  String get noExisteUnaCuentaCon;

  /// No description provided for @emailOContrasenaIncorrectos.
  ///
  /// In es, this message translates to:
  /// **'Email o contraseña incorrectos.'**
  String get emailOContrasenaIncorrectos;

  /// No description provided for @yaExisteUnaCuentaCon.
  ///
  /// In es, this message translates to:
  /// **'Ya existe una cuenta con ese email.'**
  String get yaExisteUnaCuentaCon;

  /// No description provided for @laContrasenaDebeTenerAl.
  ///
  /// In es, this message translates to:
  /// **'La contraseña debe tener al menos 6 caracteres.'**
  String get laContrasenaDebeTenerAl;

  /// No description provided for @errorDeAutenticacion.
  ///
  /// In es, this message translates to:
  /// **'Error de autenticación.'**
  String get errorDeAutenticacion;

  /// No description provided for @pausar.
  ///
  /// In es, this message translates to:
  /// **'Pausar'**
  String get pausar;

  /// No description provided for @reproducir.
  ///
  /// In es, this message translates to:
  /// **'Reproducir'**
  String get reproducir;

  /// No description provided for @noSePudoReproducir.
  ///
  /// In es, this message translates to:
  /// **'No se pudo reproducir: {error}'**
  String noSePudoReproducir(Object error);

  /// No description provided for @bajandoElVolumen.
  ///
  /// In es, this message translates to:
  /// **'Bajando el volumen...'**
  String get bajandoElVolumen;

  /// No description provided for @fadeOutS.
  ///
  /// In es, this message translates to:
  /// **'Fade out ({segundos} s)'**
  String fadeOutS(Object segundos);

  /// No description provided for @detener.
  ///
  /// In es, this message translates to:
  /// **'Detener'**
  String get detener;

  /// No description provided for @modoClaroOscuroParaEl.
  ///
  /// In es, this message translates to:
  /// **'Modo claro/oscuro (para el resto de la app)'**
  String get modoClaroOscuroParaEl;

  /// No description provided for @colorDeLaApp.
  ///
  /// In es, this message translates to:
  /// **'Color de la app'**
  String get colorDeLaApp;

  /// No description provided for @comunicacionEnVivoEntreMusicos.
  ///
  /// In es, this message translates to:
  /// **'Comunicación en vivo\nentre músicos y sonidistas'**
  String get comunicacionEnVivoEntreMusicos;

  /// No description provided for @iniciarSesion.
  ///
  /// In es, this message translates to:
  /// **'Iniciar sesión'**
  String get iniciarSesion;

  /// No description provided for @crearCuenta.
  ///
  /// In es, this message translates to:
  /// **'Crear cuenta'**
  String get crearCuenta;

  /// No description provided for @entrarComoInvitado.
  ///
  /// In es, this message translates to:
  /// **'Entrar como invitado'**
  String get entrarComoInvitado;

  /// No description provided for @tiempoReal.
  ///
  /// In es, this message translates to:
  /// **'Tiempo real'**
  String get tiempoReal;

  /// No description provided for @sincronizacionInstantanea.
  ///
  /// In es, this message translates to:
  /// **'Sincronización\ninstantánea'**
  String get sincronizacionInstantanea;

  /// No description provided for @urgente.
  ///
  /// In es, this message translates to:
  /// **'Urgente'**
  String get urgente;

  /// No description provided for @alertasVisualesYSonoras.
  ///
  /// In es, this message translates to:
  /// **'Alertas visuales\ny sonoras'**
  String get alertasVisualesYSonoras;

  /// No description provided for @multiSala.
  ///
  /// In es, this message translates to:
  /// **'Multi-sala'**
  String get multiSala;

  /// No description provided for @manejaVariasBandasYShows.
  ///
  /// In es, this message translates to:
  /// **'Manejá varias\nbandas y shows'**
  String get manejaVariasBandasYShows;

  /// No description provided for @setlistEnVivo.
  ///
  /// In es, this message translates to:
  /// **'Setlist en vivo'**
  String get setlistEnVivo;

  /// No description provided for @listaDeTemasCompartida.
  ///
  /// In es, this message translates to:
  /// **'Lista de temas\ncompartida'**
  String get listaDeTemasCompartida;

  /// No description provided for @completaEmailYContrasena.
  ///
  /// In es, this message translates to:
  /// **'Completá email y contraseña.'**
  String get completaEmailYContrasena;

  /// No description provided for @completaTuPerfil.
  ///
  /// In es, this message translates to:
  /// **'Completá tu perfil'**
  String get completaTuPerfil;

  /// No description provided for @tuNombre.
  ///
  /// In es, this message translates to:
  /// **'Tu nombre'**
  String get tuNombre;

  /// No description provided for @requerido.
  ///
  /// In es, this message translates to:
  /// **'Requerido'**
  String get requerido;

  /// No description provided for @tuRolEjSonidistaGuitarrista.
  ///
  /// In es, this message translates to:
  /// **'Tu rol (ej: sonidista, guitarrista)'**
  String get tuRolEjSonidistaGuitarrista;

  /// No description provided for @guardar.
  ///
  /// In es, this message translates to:
  /// **'Guardar'**
  String get guardar;

  /// No description provided for @recuperarContrasena.
  ///
  /// In es, this message translates to:
  /// **'Recuperar contraseña'**
  String get recuperarContrasena;

  /// No description provided for @tuEmail.
  ///
  /// In es, this message translates to:
  /// **'Tu email'**
  String get tuEmail;

  /// No description provided for @cancelar.
  ///
  /// In es, this message translates to:
  /// **'Cancelar'**
  String get cancelar;

  /// No description provided for @enviarEmail.
  ///
  /// In es, this message translates to:
  /// **'Enviar email'**
  String get enviarEmail;

  /// No description provided for @teEnviamosUnEmailPara.
  ///
  /// In es, this message translates to:
  /// **'Te enviamos un email para restablecer tu contraseña.'**
  String get teEnviamosUnEmailPara;

  /// No description provided for @tuRolEjSonidistaGuitarrista2.
  ///
  /// In es, this message translates to:
  /// **'Tu rol (ej: sonidista, guitarrista, corista)'**
  String get tuRolEjSonidistaGuitarrista2;

  /// No description provided for @email.
  ///
  /// In es, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @emailInvalido.
  ///
  /// In es, this message translates to:
  /// **'Email inválido'**
  String get emailInvalido;

  /// No description provided for @contrasena.
  ///
  /// In es, this message translates to:
  /// **'Contraseña'**
  String get contrasena;

  /// No description provided for @minimo6Caracteres.
  ///
  /// In es, this message translates to:
  /// **'Mínimo 6 caracteres'**
  String get minimo6Caracteres;

  /// No description provided for @olvidasteTuContrasena.
  ///
  /// In es, this message translates to:
  /// **'¿Olvidaste tu contraseña?'**
  String get olvidasteTuContrasena;

  /// No description provided for @registrarme.
  ///
  /// In es, this message translates to:
  /// **'REGISTRARME'**
  String get registrarme;

  /// No description provided for @iniciarSesion2.
  ///
  /// In es, this message translates to:
  /// **'INICIAR SESIÓN'**
  String get iniciarSesion2;

  /// No description provided for @yaTenesCuentaIniciarSesion.
  ///
  /// In es, this message translates to:
  /// **'¿Ya tenés cuenta? Iniciar sesión'**
  String get yaTenesCuentaIniciarSesion;

  /// No description provided for @noTenesCuentaRegistrarme.
  ///
  /// In es, this message translates to:
  /// **'¿No tenés cuenta? Registrarme'**
  String get noTenesCuentaRegistrarme;

  /// No description provided for @continuarConGoogle.
  ///
  /// In es, this message translates to:
  /// **'Continuar con Google'**
  String get continuarConGoogle;

  /// No description provided for @continuarSinCuenta.
  ///
  /// In es, this message translates to:
  /// **'Continuar sin cuenta'**
  String get continuarSinCuenta;

  /// No description provided for @cerrarSesionDeCuenta.
  ///
  /// In es, this message translates to:
  /// **'Cerrar sesión de cuenta'**
  String get cerrarSesionDeCuenta;

  /// No description provided for @sesion.
  ///
  /// In es, this message translates to:
  /// **'Sesión: {usuario}'**
  String sesion(Object usuario);

  /// No description provided for @crearNuevaSala.
  ///
  /// In es, this message translates to:
  /// **'CREAR NUEVA SALA'**
  String get crearNuevaSala;

  /// No description provided for @unirmeASala.
  ///
  /// In es, this message translates to:
  /// **'UNIRME A SALA'**
  String get unirmeASala;

  /// No description provided for @misSalas.
  ///
  /// In es, this message translates to:
  /// **'MIS SALAS'**
  String get misSalas;

  /// No description provided for @misFrases.
  ///
  /// In es, this message translates to:
  /// **'MIS FRASES'**
  String get misFrases;

  /// No description provided for @miRepertorio.
  ///
  /// In es, this message translates to:
  /// **'MI REPERTORIO'**
  String get miRepertorio;

  /// No description provided for @misSecuencias.
  ///
  /// In es, this message translates to:
  /// **'MIS SECUENCIAS'**
  String get misSecuencias;

  /// No description provided for @accesoSonidista.
  ///
  /// In es, this message translates to:
  /// **'ACCESO SONIDISTA'**
  String get accesoSonidista;

  /// No description provided for @elegiLaIdentidadVisualDe.
  ///
  /// In es, this message translates to:
  /// **'Elegí la identidad visual de la app. Se guarda en este dispositivo.'**
  String get elegiLaIdentidadVisualDe;

  /// No description provided for @marcaAlMenosUnRol.
  ///
  /// In es, this message translates to:
  /// **'Marcá al menos un rol.'**
  String get marcaAlMenosUnRol;

  /// No description provided for @errorAlIngresar.
  ///
  /// In es, this message translates to:
  /// **'Error al ingresar: {error}'**
  String errorAlIngresar(Object error);

  /// No description provided for @configurarSala.
  ///
  /// In es, this message translates to:
  /// **'Configurar Sala'**
  String get configurarSala;

  /// No description provided for @tuPinDeSala.
  ///
  /// In es, this message translates to:
  /// **'Tu PIN de Sala'**
  String get tuPinDeSala;

  /// No description provided for @pinCopiado.
  ///
  /// In es, this message translates to:
  /// **'PIN copiado'**
  String get pinCopiado;

  /// No description provided for @tuNombre2.
  ///
  /// In es, this message translates to:
  /// **'Tu Nombre'**
  String get tuNombre2;

  /// No description provided for @empezar.
  ///
  /// In es, this message translates to:
  /// **'EMPEZAR'**
  String get empezar;

  /// No description provided for @unirseASala.
  ///
  /// In es, this message translates to:
  /// **'Unirse a Sala'**
  String get unirseASala;

  /// No description provided for @codigoDeSala8Caracteres.
  ///
  /// In es, this message translates to:
  /// **'Código de sala (8 caracteres)'**
  String get codigoDeSala8Caracteres;

  /// No description provided for @unirme.
  ///
  /// In es, this message translates to:
  /// **'UNIRME'**
  String get unirme;

  /// No description provided for @nombreParaEstaSala.
  ///
  /// In es, this message translates to:
  /// **'Nombre para esta sala'**
  String get nombreParaEstaSala;

  /// No description provided for @ejBandaXEnsayoJueves.
  ///
  /// In es, this message translates to:
  /// **'Ej: Banda X - Ensayo jueves'**
  String get ejBandaXEnsayoJueves;

  /// No description provided for @misSalas2.
  ///
  /// In es, this message translates to:
  /// **'Mis salas'**
  String get misSalas2;

  /// No description provided for @necesitasIniciarSesionParaTener.
  ///
  /// In es, this message translates to:
  /// **'Necesitás iniciar sesión para tener un historial de salas.'**
  String get necesitasIniciarSesionParaTener;

  /// No description provided for @guardarUnHistorialDeVarias.
  ///
  /// In es, this message translates to:
  /// **'Guardar un historial de varias salas/bandas para volver a entrar con un toque es una función Pro.'**
  String get guardarUnHistorialDeVarias;

  /// No description provided for @todaviaNoEntrasteANinguna.
  ///
  /// In es, this message translates to:
  /// **'Todavía no entraste a ninguna sala con esta cuenta.'**
  String get todaviaNoEntrasteANinguna;

  /// No description provided for @renombrar.
  ///
  /// In es, this message translates to:
  /// **'Renombrar'**
  String get renombrar;

  /// No description provided for @quitarDelHistorial.
  ///
  /// In es, this message translates to:
  /// **'Quitar del historial'**
  String get quitarDelHistorial;

  /// No description provided for @queQueresVerEnLa.
  ///
  /// In es, this message translates to:
  /// **'¿Qué querés ver en la sala?'**
  String get queQueresVerEnLa;

  /// No description provided for @seGuardaEnEsteDispositivo.
  ///
  /// In es, this message translates to:
  /// **'Se guarda en este dispositivo. Tiene que quedar al menos una.'**
  String get seGuardaEnEsteDispositivo;

  /// No description provided for @urgenteEnviado.
  ///
  /// In es, this message translates to:
  /// **'¡Urgente enviado!: {texto}'**
  String urgenteEnviado(Object texto);

  /// No description provided for @enviado.
  ///
  /// In es, this message translates to:
  /// **'Enviado: {texto}'**
  String enviado(Object texto);

  /// No description provided for @cerrarSesion.
  ///
  /// In es, this message translates to:
  /// **'Cerrar Sesión'**
  String get cerrarSesion;

  /// No description provided for @codigoDeSalaCopiado.
  ///
  /// In es, this message translates to:
  /// **'Código de sala copiado'**
  String get codigoDeSalaCopiado;

  /// No description provided for @sala.
  ///
  /// In es, this message translates to:
  /// **'SALA: {codigoSala}'**
  String sala(Object codigoSala);

  /// No description provided for @pantallaSiempreEncendidaActivado.
  ///
  /// In es, this message translates to:
  /// **'Pantalla siempre encendida: activado'**
  String get pantallaSiempreEncendidaActivado;

  /// No description provided for @pantallaSiempreEncendidaDesactivado.
  ///
  /// In es, this message translates to:
  /// **'Pantalla siempre encendida: desactivado'**
  String get pantallaSiempreEncendidaDesactivado;

  /// No description provided for @elegirQueVerEnLa.
  ///
  /// In es, this message translates to:
  /// **'Elegir qué ver en la sala'**
  String get elegirQueVerEnLa;

  /// No description provided for @escribirPedidoPersonalizado.
  ///
  /// In es, this message translates to:
  /// **'Escribir pedido personalizado...'**
  String get escribirPedidoPersonalizado;

  /// No description provided for @pedidoUrgenteActivado.
  ///
  /// In es, this message translates to:
  /// **'Pedido urgente: activado'**
  String get pedidoUrgenteActivado;

  /// No description provided for @marcarElProximoPedidoComo.
  ///
  /// In es, this message translates to:
  /// **'Marcar el próximo pedido como urgente'**
  String get marcarElProximoPedidoComo;

  /// No description provided for @misUltimosPedidos.
  ///
  /// In es, this message translates to:
  /// **'MIS ÚLTIMOS PEDIDOS'**
  String get misUltimosPedidos;

  /// No description provided for @error.
  ///
  /// In es, this message translates to:
  /// **'Error: {error}'**
  String error(Object error);

  /// No description provided for @sinPedidosPropios.
  ///
  /// In es, this message translates to:
  /// **'Sin pedidos propios'**
  String get sinPedidosPropios;

  /// No description provided for @eliminandoPedido.
  ///
  /// In es, this message translates to:
  /// **'Eliminando pedido: \"{pedido}\"'**
  String eliminandoPedido(Object pedido);

  /// No description provided for @consola.
  ///
  /// In es, this message translates to:
  /// **'Consola: {respuesta}'**
  String consola(Object respuesta);

  /// No description provided for @desdeMiBiblioteca.
  ///
  /// In es, this message translates to:
  /// **'Desde mi biblioteca'**
  String get desdeMiBiblioteca;

  /// No description provided for @buscarEnBibliotecasDeLa.
  ///
  /// In es, this message translates to:
  /// **'Buscar en bibliotecas de la sala'**
  String get buscarEnBibliotecasDeLa;

  /// No description provided for @necesitasIniciarSesionParaUsar.
  ///
  /// In es, this message translates to:
  /// **'Necesitás iniciar sesión para usar tu biblioteca.'**
  String get necesitasIniciarSesionParaUsar;

  /// No description provided for @tuBibliotecaEstaVacia.
  ///
  /// In es, this message translates to:
  /// **'Tu biblioteca está vacía.'**
  String get tuBibliotecaEstaVacia;

  /// No description provided for @titulo.
  ///
  /// In es, this message translates to:
  /// **'Título...'**
  String get titulo;

  /// No description provided for @tonalidad.
  ///
  /// In es, this message translates to:
  /// **'Tonalidad...'**
  String get tonalidad;

  /// No description provided for @sinResultados.
  ///
  /// In es, this message translates to:
  /// **'Sin resultados.'**
  String get sinResultados;

  /// No description provided for @noSePudoBuscarIntenta.
  ///
  /// In es, this message translates to:
  /// **'No se pudo buscar. Intentá de nuevo en un momento.'**
  String get noSePudoBuscarIntenta;

  /// No description provided for @todaviaNoHayBibliotecasPara.
  ///
  /// In es, this message translates to:
  /// **'Todavía no hay bibliotecas para buscar en esta sala.'**
  String get todaviaNoHayBibliotecasPara;

  /// No description provided for @de.
  ///
  /// In es, this message translates to:
  /// **'de {propietario}'**
  String de(Object propietario);

  /// No description provided for @elSetlistEstaVacioNo.
  ///
  /// In es, this message translates to:
  /// **'El setlist está vacío, no hay nada para exportar.'**
  String get elSetlistEstaVacioNo;

  /// No description provided for @setlistSala.
  ///
  /// In es, this message translates to:
  /// **'Setlist — Sala {codigoSala}\n\n'**
  String setlistSala(Object codigoSala);

  /// No description provided for @exportarSetlist.
  ///
  /// In es, this message translates to:
  /// **'Exportar setlist'**
  String get exportarSetlist;

  /// No description provided for @copiadoAlPortapapeles.
  ///
  /// In es, this message translates to:
  /// **'Copiado al portapapeles'**
  String get copiadoAlPortapapeles;

  /// No description provided for @copiar.
  ///
  /// In es, this message translates to:
  /// **'Copiar'**
  String get copiar;

  /// No description provided for @setlistSala2.
  ///
  /// In es, this message translates to:
  /// **'Setlist - Sala {codigoSala}'**
  String setlistSala2(Object codigoSala);

  /// No description provided for @compartir.
  ///
  /// In es, this message translates to:
  /// **'Compartir'**
  String get compartir;

  /// No description provided for @cerrar.
  ///
  /// In es, this message translates to:
  /// **'Cerrar'**
  String get cerrar;

  /// No description provided for @agregado.
  ///
  /// In es, this message translates to:
  /// **'Agregado: {titulo}'**
  String agregado(Object titulo);

  /// No description provided for @todaviaNoHayTemasEn.
  ///
  /// In es, this message translates to:
  /// **'Todavía no hay temas en la lista.'**
  String get todaviaNoHayTemasEn;

  /// No description provided for @cambiarEstadoDelTema.
  ///
  /// In es, this message translates to:
  /// **'Cambiar estado del tema'**
  String get cambiarEstadoDelTema;

  /// No description provided for @pendiente.
  ///
  /// In es, this message translates to:
  /// **'Pendiente'**
  String get pendiente;

  /// No description provided for @pausadoCorteTecnico.
  ///
  /// In es, this message translates to:
  /// **'Pausado (corte técnico)'**
  String get pausadoCorteTecnico;

  /// No description provided for @tocado.
  ///
  /// In es, this message translates to:
  /// **'Tocado'**
  String get tocado;

  /// No description provided for @pausado.
  ///
  /// In es, this message translates to:
  /// **'PAUSADO'**
  String get pausado;

  /// No description provided for @proximo.
  ///
  /// In es, this message translates to:
  /// **'PRÓXIMO'**
  String get proximo;

  /// No description provided for @subidoPor.
  ///
  /// In es, this message translates to:
  /// **'Subido por {persona}'**
  String subidoPor(Object persona);

  /// No description provided for @verCifradoTransponer.
  ///
  /// In es, this message translates to:
  /// **'Ver cifrado (transponer)'**
  String get verCifradoTransponer;

  /// No description provided for @exportarCompartirSetlist.
  ///
  /// In es, this message translates to:
  /// **'Exportar / compartir setlist'**
  String get exportarCompartirSetlist;

  /// No description provided for @agregarCancion.
  ///
  /// In es, this message translates to:
  /// **'Agregar canción'**
  String get agregarCancion;

  /// No description provided for @necesitasIniciarSesionParaUsar2.
  ///
  /// In es, this message translates to:
  /// **'Necesitás iniciar sesión para usar tus secuencias.'**
  String get necesitasIniciarSesionParaUsar2;

  /// No description provided for @noTenesSecuenciasTodaviaSubilas.
  ///
  /// In es, this message translates to:
  /// **'No tenés secuencias todavía.\nSubilas desde \"Mis secuencias\" en el menú principal.'**
  String get noTenesSecuenciasTodaviaSubilas;

  /// No description provided for @buscarSecuencia.
  ///
  /// In es, this message translates to:
  /// **'Buscar secuencia...'**
  String get buscarSecuencia;

  /// No description provided for @yaEstaEnLaSala.
  ///
  /// In es, this message translates to:
  /// **'Ya está en la sala'**
  String get yaEstaEnLaSala;

  /// No description provided for @elegiLasSecuenciasDeHoy.
  ///
  /// In es, this message translates to:
  /// **'Elegí las secuencias de hoy'**
  String get elegiLasSecuenciasDeHoy;

  /// No description provided for @cargarALaSala.
  ///
  /// In es, this message translates to:
  /// **'CARGAR {cantidad} A LA SALA'**
  String cargarALaSala(Object cantidad);

  /// No description provided for @noSePudieronCargar.
  ///
  /// In es, this message translates to:
  /// **'No se pudieron cargar: {error}'**
  String noSePudieronCargar(Object error);

  /// No description provided for @quitarDeLaSala.
  ///
  /// In es, this message translates to:
  /// **'Quitar de la sala'**
  String get quitarDeLaSala;

  /// No description provided for @quitarDeLasSecuenciasDe.
  ///
  /// In es, this message translates to:
  /// **'¿Quitar \"{titulo}\" de las secuencias de hoy? Sigue estando en la biblioteca de quien la subió.'**
  String quitarDeLasSecuenciasDe(Object titulo);

  /// No description provided for @quitar.
  ///
  /// In es, this message translates to:
  /// **'Quitar'**
  String get quitar;

  /// No description provided for @noSePudoGuardarEl.
  ///
  /// In es, this message translates to:
  /// **'No se pudo guardar el ajuste: {error}'**
  String noSePudoGuardarEl(Object error);

  /// No description provided for @seGuardaParaTodaLa.
  ///
  /// In es, this message translates to:
  /// **'Se guarda para toda la sala. Tono, tempo y volumen se cambian por separado.'**
  String get seGuardaParaTodaLa;

  /// No description provided for @tono.
  ///
  /// In es, this message translates to:
  /// **'TONO'**
  String get tono;

  /// No description provided for @bajarUnSemitono.
  ///
  /// In es, this message translates to:
  /// **'Bajar un semitono'**
  String get bajarUnSemitono;

  /// No description provided for @subirUnSemitono.
  ///
  /// In es, this message translates to:
  /// **'Subir un semitono'**
  String get subirUnSemitono;

  /// No description provided for @elCambioDeTonoPor.
  ///
  /// In es, this message translates to:
  /// **'El cambio de tono por ahora solo funciona en la versión web.'**
  String get elCambioDeTonoPor;

  /// No description provided for @tempo.
  ///
  /// In es, this message translates to:
  /// **'TEMPO'**
  String get tempo;

  /// No description provided for @masLento1.
  ///
  /// In es, this message translates to:
  /// **'Más lento (1%)'**
  String get masLento1;

  /// No description provided for @masRapido1.
  ///
  /// In es, this message translates to:
  /// **'Más rápido (1%)'**
  String get masRapido1;

  /// No description provided for @volumen.
  ///
  /// In es, this message translates to:
  /// **'VOLUMEN'**
  String get volumen;

  /// No description provided for @bajar5.
  ///
  /// In es, this message translates to:
  /// **'Bajar 5%'**
  String get bajar5;

  /// No description provided for @subir5.
  ///
  /// In es, this message translates to:
  /// **'Subir 5%'**
  String get subir5;

  /// No description provided for @restablecerComoSeSubio.
  ///
  /// In es, this message translates to:
  /// **'Restablecer (como se subió)'**
  String get restablecerComoSeSubio;

  /// No description provided for @noSePudieronCargarLas.
  ///
  /// In es, this message translates to:
  /// **'No se pudieron cargar las secuencias: {error}'**
  String noSePudieronCargarLas(Object error);

  /// No description provided for @cargadaPor.
  ///
  /// In es, this message translates to:
  /// **'Cargada por {persona}'**
  String cargadaPor(Object persona);

  /// No description provided for @tonoTempoYVolumen.
  ///
  /// In es, this message translates to:
  /// **'Tono, tempo y volumen'**
  String get tonoTempoYVolumen;

  /// No description provided for @repetir.
  ///
  /// In es, this message translates to:
  /// **'Repetir'**
  String get repetir;

  /// No description provided for @todaviaNoHaySecuenciasCargadas.
  ///
  /// In es, this message translates to:
  /// **'Todavía no hay secuencias cargadas para hoy.'**
  String get todaviaNoHaySecuenciasCargadas;

  /// No description provided for @todaviaNoHaySecuenciasCargadas2.
  ///
  /// In es, this message translates to:
  /// **'Todavía no hay secuencias cargadas para hoy.\nTocá + para elegirlas de \"Mis secuencias\".'**
  String get todaviaNoHaySecuenciasCargadas2;

  /// No description provided for @cargarSecuenciasDeHoy.
  ///
  /// In es, this message translates to:
  /// **'Cargar secuencias de hoy'**
  String get cargarSecuenciasDeHoy;

  /// No description provided for @nuevaFrase.
  ///
  /// In es, this message translates to:
  /// **'Nueva frase'**
  String get nuevaFrase;

  /// No description provided for @textoDeLaFrase.
  ///
  /// In es, this message translates to:
  /// **'Texto de la frase'**
  String get textoDeLaFrase;

  /// No description provided for @agregar.
  ///
  /// In es, this message translates to:
  /// **'Agregar'**
  String get agregar;

  /// No description provided for @editarFrase.
  ///
  /// In es, this message translates to:
  /// **'Editar frase'**
  String get editarFrase;

  /// No description provided for @misFrases2.
  ///
  /// In es, this message translates to:
  /// **'Mis frases'**
  String get misFrases2;

  /// No description provided for @necesitasIniciarSesionParaEditar.
  ///
  /// In es, this message translates to:
  /// **'Necesitás iniciar sesión para editar tus frases.'**
  String get necesitasIniciarSesionParaEditar;

  /// No description provided for @todaviaNoTenesFrasesPropias.
  ///
  /// In es, this message translates to:
  /// **'Todavía no tenés frases propias cargadas.'**
  String get todaviaNoTenesFrasesPropias;

  /// No description provided for @cargarFrasesPorDefecto.
  ///
  /// In es, this message translates to:
  /// **'Cargar frases por defecto'**
  String get cargarFrasesPorDefecto;

  /// No description provided for @funcionPro.
  ///
  /// In es, this message translates to:
  /// **'Función Pro'**
  String get funcionPro;

  /// No description provided for @subirTusPropiasPartiturasCifrados.
  ///
  /// In es, this message translates to:
  /// **'Subir tus propias partituras/cifrados en PDF es parte de Sound Check Pro. Activá tu cuenta Pro para usar esta función.'**
  String get subirTusPropiasPartiturasCifrados;

  /// No description provided for @entendido.
  ///
  /// In es, this message translates to:
  /// **'Entendido'**
  String get entendido;

  /// No description provided for @errorAlSubir.
  ///
  /// In es, this message translates to:
  /// **'Error al subir: {error}'**
  String errorAlSubir(Object error);

  /// No description provided for @nuevaCancion.
  ///
  /// In es, this message translates to:
  /// **'Nueva canción'**
  String get nuevaCancion;

  /// No description provided for @editarCancion.
  ///
  /// In es, this message translates to:
  /// **'Editar canción'**
  String get editarCancion;

  /// No description provided for @titulo2.
  ///
  /// In es, this message translates to:
  /// **'Título'**
  String get titulo2;

  /// No description provided for @tonalidadOpcional.
  ///
  /// In es, this message translates to:
  /// **'Tonalidad (opcional)'**
  String get tonalidadOpcional;

  /// No description provided for @cifradoEnTextoOpcionalPara.
  ///
  /// In es, this message translates to:
  /// **'Cifrado en texto (opcional, para transponer)'**
  String get cifradoEnTextoOpcionalPara;

  /// No description provided for @pegaLosAcordesAcaEj.
  ///
  /// In es, this message translates to:
  /// **'Pegá los acordes acá. Ej: [C]Amazing [G]grace...'**
  String get pegaLosAcordesAcaEj;

  /// No description provided for @regenerarCifrados.
  ///
  /// In es, this message translates to:
  /// **'Regenerar cifrados'**
  String get regenerarCifrados;

  /// No description provided for @seVaAVolverA.
  ///
  /// In es, this message translates to:
  /// **'Se va a volver a leer cada PDF de tu biblioteca para rearmar el cifrado con los acordes ubicados como en el PDF original.\n\nEsto reemplaza el cifrado en texto que tengas guardado en cada canción (incluido lo que hayas editado a mano). Las canciones cuyo PDF no tiene texto seleccionable no se tocan.'**
  String get seVaAVolverA;

  /// No description provided for @regenerar.
  ///
  /// In es, this message translates to:
  /// **'Regenerar'**
  String get regenerar;

  /// No description provided for @preparando.
  ///
  /// In es, this message translates to:
  /// **'Preparando...'**
  String get preparando;

  /// No description provided for @procesandoDe.
  ///
  /// In es, this message translates to:
  /// **'Procesando {hechas} de {total}...'**
  String procesandoDe(Object hechas, Object total);

  /// No description provided for @actualizadas.
  ///
  /// In es, this message translates to:
  /// **'{cantidad} actualizadas'**
  String actualizadas(Object cantidad);

  /// No description provided for @sinTextoEnElPdf.
  ///
  /// In es, this message translates to:
  /// **'{cantidad} sin texto en el PDF'**
  String sinTextoEnElPdf(Object cantidad);

  /// No description provided for @conError.
  ///
  /// In es, this message translates to:
  /// **'{cantidad} con error'**
  String conError(Object cantidad);

  /// No description provided for @cifrados.
  ///
  /// In es, this message translates to:
  /// **'Cifrados: {detalle}.'**
  String cifrados(Object detalle);

  /// No description provided for @eliminarCancion.
  ///
  /// In es, this message translates to:
  /// **'¿Eliminar canción?'**
  String get eliminarCancion;

  /// No description provided for @seBorraDeTuBiblioteca.
  ///
  /// In es, this message translates to:
  /// **'Se borra de tu biblioteca. Si está en el setlist de alguna sala, va a dejar de abrir.'**
  String get seBorraDeTuBiblioteca;

  /// No description provided for @eliminar.
  ///
  /// In es, this message translates to:
  /// **'Eliminar'**
  String get eliminar;

  /// No description provided for @miRepertorio2.
  ///
  /// In es, this message translates to:
  /// **'Mi repertorio'**
  String get miRepertorio2;

  /// No description provided for @regenerarCifradosDesdeLosPdf.
  ///
  /// In es, this message translates to:
  /// **'Regenerar cifrados desde los PDF'**
  String get regenerarCifradosDesdeLosPdf;

  /// No description provided for @necesitasIniciarSesionParaTener2.
  ///
  /// In es, this message translates to:
  /// **'Necesitás iniciar sesión para tener tu biblioteca.'**
  String get necesitasIniciarSesionParaTener2;

  /// No description provided for @subirTusPropiasPartiturasEs.
  ///
  /// In es, this message translates to:
  /// **'Subir tus propias partituras es una función Pro.'**
  String get subirTusPropiasPartiturasEs;

  /// No description provided for @masInfo.
  ///
  /// In es, this message translates to:
  /// **'Más info'**
  String get masInfo;

  /// No description provided for @todaviaNoSubisteNingunaCancion.
  ///
  /// In es, this message translates to:
  /// **'Todavía no subiste ninguna canción.'**
  String get todaviaNoSubisteNingunaCancion;

  /// No description provided for @tonalidad2.
  ///
  /// In es, this message translates to:
  /// **'Tonalidad: {tonalidad}'**
  String tonalidad2(Object tonalidad);

  /// No description provided for @subirTusPropiasSecuenciasEs.
  ///
  /// In es, this message translates to:
  /// **'Subir tus propias secuencias es parte de Sound Check Pro. Activá tu cuenta Pro para usar esta función.'**
  String get subirTusPropiasSecuenciasEs;

  /// No description provided for @archivoDemasiadoGrande.
  ///
  /// In es, this message translates to:
  /// **'Archivo demasiado grande'**
  String get archivoDemasiadoGrande;

  /// No description provided for @archivosDemasiadoGrandes.
  ///
  /// In es, this message translates to:
  /// **'Archivos demasiado grandes'**
  String get archivosDemasiadoGrandes;

  /// No description provided for @elMaximoPorArchivoEs.
  ///
  /// In es, this message translates to:
  /// **'{lista}\n\nEl máximo por archivo es {limite}. Convertilo a MP3 (a 320 kbps una canción entera ocupa unos 10-15 MB) y volvé a subirlo, o subilo desde la versión web, que lo convierte sola.'**
  String elMaximoPorArchivoEs(Object lista, Object limite);

  /// No description provided for @convirtiendoAMp3.
  ///
  /// In es, this message translates to:
  /// **'Convirtiendo a MP3{contador}'**
  String convirtiendoAMp3(Object contador);

  /// No description provided for @convirtiendoAMp32.
  ///
  /// In es, this message translates to:
  /// **'Convirtiendo a MP3 {porcentaje}%{contador}'**
  String convirtiendoAMp32(Object porcentaje, Object contador);

  /// No description provided for @subiendo.
  ///
  /// In es, this message translates to:
  /// **'Subiendo{contador}'**
  String subiendo(Object contador);

  /// No description provided for @secuenciasSubidas.
  ///
  /// In es, this message translates to:
  /// **'Secuencias subidas'**
  String get secuenciasSubidas;

  /// No description provided for @algunasSecuenciasNoSeSubieron.
  ///
  /// In es, this message translates to:
  /// **'Algunas secuencias no se subieron'**
  String get algunasSecuenciasNoSeSubieron;

  /// No description provided for @seConvirtieronAMp3Porque.
  ///
  /// In es, this message translates to:
  /// **'Se convirtieron a MP3 porque pasaban el máximo de {limite}:\n{lista}'**
  String seConvirtieronAMp3Porque(Object limite, Object lista);

  /// No description provided for @noSePudieronSubir.
  ///
  /// In es, this message translates to:
  /// **'No se pudieron subir:\n{lista}'**
  String noSePudieronSubir(Object lista);

  /// No description provided for @renombrarSecuencia.
  ///
  /// In es, this message translates to:
  /// **'Renombrar secuencia'**
  String get renombrarSecuencia;

  /// No description provided for @eliminarSecuencia.
  ///
  /// In es, this message translates to:
  /// **'Eliminar secuencia'**
  String get eliminarSecuencia;

  /// No description provided for @eliminarDeTuBiblioteca.
  ///
  /// In es, this message translates to:
  /// **'¿Eliminar \"{titulo}\" de tu biblioteca?'**
  String eliminarDeTuBiblioteca(Object titulo);

  /// No description provided for @misSecuencias2.
  ///
  /// In es, this message translates to:
  /// **'Mis secuencias'**
  String get misSecuencias2;

  /// No description provided for @necesitasIniciarSesionParaTener3.
  ///
  /// In es, this message translates to:
  /// **'Necesitás iniciar sesión para tener tus secuencias.'**
  String get necesitasIniciarSesionParaTener3;

  /// No description provided for @errorAlCargar.
  ///
  /// In es, this message translates to:
  /// **'Error al cargar: {error}'**
  String errorAlCargar(Object error);

  /// No description provided for @todaviaNoSubisteSecuenciasToca.
  ///
  /// In es, this message translates to:
  /// **'Todavía no subiste secuencias.\nTocá el botón de abajo para cargar tus pistas de audio (MP3, WAV, M4A...).'**
  String get todaviaNoSubisteSecuenciasToca;

  /// No description provided for @subirSecuencias.
  ///
  /// In es, this message translates to:
  /// **'Subir secuencias'**
  String get subirSecuencias;

  /// No description provided for @restablecerTonoOriginal.
  ///
  /// In es, this message translates to:
  /// **'Restablecer tono original'**
  String get restablecerTonoOriginal;

  /// No description provided for @sincronizadoConTodaLaSala.
  ///
  /// In es, this message translates to:
  /// **'Sincronizado con toda la sala (tocá para desincronizar)'**
  String get sincronizadoConTodaLaSala;

  /// No description provided for @desincronizadoCambiosSoloLocalesToca.
  ///
  /// In es, this message translates to:
  /// **'Desincronizado — cambios solo locales (tocá para volver a sincronizar)'**
  String get desincronizadoCambiosSoloLocalesToca;

  /// No description provided for @noSePudoCargarEl.
  ///
  /// In es, this message translates to:
  /// **'No se pudo cargar el PDF.\n{error}'**
  String noSePudoCargarEl(Object error);

  /// No description provided for @errorAlIngresarAlPanel.
  ///
  /// In es, this message translates to:
  /// **'Error al ingresar al panel: {error}'**
  String errorAlIngresarAlPanel(Object error);

  /// No description provided for @accesoSonidista2.
  ///
  /// In es, this message translates to:
  /// **'Acceso Sonidista'**
  String get accesoSonidista2;

  /// No description provided for @pinDeSalaOCrear.
  ///
  /// In es, this message translates to:
  /// **'PIN de Sala o Crear Sala'**
  String get pinDeSalaOCrear;

  /// No description provided for @accederAlPanel.
  ///
  /// In es, this message translates to:
  /// **'ACCEDER AL PANEL'**
  String get accederAlPanel;

  /// No description provided for @tuRespuesta.
  ///
  /// In es, this message translates to:
  /// **'Tu respuesta: {respuesta}'**
  String tuRespuesta(Object respuesta);

  /// No description provided for @responderPrivado.
  ///
  /// In es, this message translates to:
  /// **'Responder privado'**
  String get responderPrivado;

  /// No description provided for @responderA.
  ///
  /// In es, this message translates to:
  /// **'Responder a {musico}'**
  String responderA(Object musico);

  /// No description provided for @pedido.
  ///
  /// In es, this message translates to:
  /// **'Pedido: \"{pedido}\"'**
  String pedido(Object pedido);

  /// No description provided for @escribirRespuestaPrivada.
  ///
  /// In es, this message translates to:
  /// **'Escribir respuesta privada...'**
  String get escribirRespuestaPrivada;

  /// No description provided for @enviar.
  ///
  /// In es, this message translates to:
  /// **'Enviar'**
  String get enviar;

  /// No description provided for @consola2.
  ///
  /// In es, this message translates to:
  /// **'Consola: {codigoSala}'**
  String consola2(Object codigoSala);

  /// No description provided for @borrarTodo.
  ///
  /// In es, this message translates to:
  /// **'¿Borrar todo?'**
  String get borrarTodo;

  /// No description provided for @no.
  ///
  /// In es, this message translates to:
  /// **'No'**
  String get no;

  /// No description provided for @si.
  ///
  /// In es, this message translates to:
  /// **'Sí'**
  String get si;

  /// No description provided for @agrupadoPorRolActivado.
  ///
  /// In es, this message translates to:
  /// **'Agrupado por rol: activado'**
  String get agrupadoPorRolActivado;

  /// No description provided for @verAgrupadoPorRol.
  ///
  /// In es, this message translates to:
  /// **'Ver agrupado por rol'**
  String get verAgrupadoPorRol;

  /// No description provided for @errorDeConexion.
  ///
  /// In es, this message translates to:
  /// **'Error de conexión: {error}'**
  String errorDeConexion(Object error);

  /// No description provided for @esperandoPedidos.
  ///
  /// In es, this message translates to:
  /// **'Esperando pedidos...'**
  String get esperandoPedidos;

  /// No description provided for @todaviaNoAtendisteNingunPedido.
  ///
  /// In es, this message translates to:
  /// **'Todavía no atendiste ningún pedido'**
  String get todaviaNoAtendisteNingunPedido;

  /// No description provided for @nombreApp.
  ///
  /// In es, this message translates to:
  /// **'Sound Check Pro'**
  String get nombreApp;

  /// No description provided for @rolMusico.
  ///
  /// In es, this message translates to:
  /// **'Músico'**
  String get rolMusico;

  /// No description provided for @rolCantante.
  ///
  /// In es, this message translates to:
  /// **'Cantante'**
  String get rolCantante;

  /// No description provided for @rolSonidista.
  ///
  /// In es, this message translates to:
  /// **'Sonidista'**
  String get rolSonidista;

  /// No description provided for @rolOtro.
  ///
  /// In es, this message translates to:
  /// **'Otro'**
  String get rolOtro;

  /// No description provided for @rolesYUltimo.
  ///
  /// In es, this message translates to:
  /// **'{lista} y {ultimo}'**
  String rolesYUltimo(String lista, String ultimo);

  /// No description provided for @paletaEscenarioNombre.
  ///
  /// In es, this message translates to:
  /// **'Escenario'**
  String get paletaEscenarioNombre;

  /// No description provided for @paletaEscenarioTag.
  ///
  /// In es, this message translates to:
  /// **'Neón celeste y violeta'**
  String get paletaEscenarioTag;

  /// No description provided for @paletaConsolaNombre.
  ///
  /// In es, this message translates to:
  /// **'Consola'**
  String get paletaConsolaNombre;

  /// No description provided for @paletaConsolaTag.
  ///
  /// In es, this message translates to:
  /// **'Violeta, refinado'**
  String get paletaConsolaTag;

  /// No description provided for @paletaPlacaNombre.
  ///
  /// In es, this message translates to:
  /// **'Placa'**
  String get paletaPlacaNombre;

  /// No description provided for @paletaPlacaTag.
  ///
  /// In es, this message translates to:
  /// **'Grafito + ámbar VU'**
  String get paletaPlacaTag;

  /// No description provided for @paletaWashNombre.
  ///
  /// In es, this message translates to:
  /// **'Wash'**
  String get paletaWashNombre;

  /// No description provided for @paletaWashTag.
  ///
  /// In es, this message translates to:
  /// **'Teal de luz de escenario'**
  String get paletaWashTag;

  /// No description provided for @paletaLuzDeTrabajoNombre.
  ///
  /// In es, this message translates to:
  /// **'Luz de trabajo'**
  String get paletaLuzDeTrabajoNombre;

  /// No description provided for @paletaLuzDeTrabajoTag.
  ///
  /// In es, this message translates to:
  /// **'Máximo contraste'**
  String get paletaLuzDeTrabajoTag;

  /// No description provided for @paletaCamarinNombre.
  ///
  /// In es, this message translates to:
  /// **'Camarín'**
  String get paletaCamarinNombre;

  /// No description provided for @paletaCamarinTag.
  ///
  /// In es, this message translates to:
  /// **'Rosa pastel, suave'**
  String get paletaCamarinTag;

  /// No description provided for @pestanaPedidos.
  ///
  /// In es, this message translates to:
  /// **'Pedidos'**
  String get pestanaPedidos;

  /// No description provided for @pestanaHistorial.
  ///
  /// In es, this message translates to:
  /// **'Historial'**
  String get pestanaHistorial;

  /// No description provided for @pestanaSetlist.
  ///
  /// In es, this message translates to:
  /// **'Setlist'**
  String get pestanaSetlist;

  /// No description provided for @pestanaSecuencias.
  ///
  /// In es, this message translates to:
  /// **'Secuencias'**
  String get pestanaSecuencias;

  /// No description provided for @fraseVolumenRetorno.
  ///
  /// In es, this message translates to:
  /// **'Volumen retorno'**
  String get fraseVolumenRetorno;

  /// No description provided for @fraseVolumenAl2.
  ///
  /// In es, this message translates to:
  /// **'Volumen al 2'**
  String get fraseVolumenAl2;

  /// No description provided for @fraseVolumenAl3.
  ///
  /// In es, this message translates to:
  /// **'Volumen al 3'**
  String get fraseVolumenAl3;

  /// No description provided for @fraseVolumenAl4.
  ///
  /// In es, this message translates to:
  /// **'Volumen al 4'**
  String get fraseVolumenAl4;

  /// No description provided for @fraseVolumenGuitarra.
  ///
  /// In es, this message translates to:
  /// **'Volumen guitarra'**
  String get fraseVolumenGuitarra;

  /// No description provided for @fraseVolumenTeclado.
  ///
  /// In es, this message translates to:
  /// **'Volumen teclado'**
  String get fraseVolumenTeclado;

  /// No description provided for @fraseVolumenTalkback.
  ///
  /// In es, this message translates to:
  /// **'Volumen Talkback'**
  String get fraseVolumenTalkback;

  /// No description provided for @fraseVolumenPista.
  ///
  /// In es, this message translates to:
  /// **'Volumen pista'**
  String get fraseVolumenPista;

  /// No description provided for @fraseVolumenClick.
  ///
  /// In es, this message translates to:
  /// **'Volumen click'**
  String get fraseVolumenClick;

  /// No description provided for @fraseVolumenCoordinador.
  ///
  /// In es, this message translates to:
  /// **'Volumen coordinador'**
  String get fraseVolumenCoordinador;

  /// No description provided for @fraseVolumenGeneral.
  ///
  /// In es, this message translates to:
  /// **'Volumen general'**
  String get fraseVolumenGeneral;

  /// No description provided for @fraseListo.
  ///
  /// In es, this message translates to:
  /// **'Listo'**
  String get fraseListo;

  /// No description provided for @tonoOriginal.
  ///
  /// In es, this message translates to:
  /// **'Original'**
  String get tonoOriginal;

  /// No description provided for @semitonosConSigno.
  ///
  /// In es, this message translates to:
  /// **'{cantidad, plural, =1{{signo}{cantidad} semitono} other{{signo}{cantidad} semitonos}}'**
  String semitonosConSigno(String signo, int cantidad);

  /// No description provided for @ajusteTono.
  ///
  /// In es, this message translates to:
  /// **'Tono {valor}'**
  String ajusteTono(String valor);

  /// No description provided for @ajusteTempo.
  ///
  /// In es, this message translates to:
  /// **'Tempo {valor}%'**
  String ajusteTempo(int valor);

  /// No description provided for @ajusteVolumen.
  ///
  /// In es, this message translates to:
  /// **'Vol {valor}%'**
  String ajusteVolumen(int valor);

  /// No description provided for @secuenciasParaHoy.
  ///
  /// In es, this message translates to:
  /// **'{cantidad, plural, =1{1 secuencia para hoy} other{{cantidad} secuencias para hoy}}'**
  String secuenciasParaHoy(int cantidad);

  /// No description provided for @idioma.
  ///
  /// In es, this message translates to:
  /// **'Idioma'**
  String get idioma;

  /// No description provided for @idiomaDescripcion.
  ///
  /// In es, this message translates to:
  /// **'Elegí el idioma de la app. Se guarda en este dispositivo.'**
  String get idiomaDescripcion;

  /// No description provided for @escribiTuRol.
  ///
  /// In es, this message translates to:
  /// **'Escribí tu rol.'**
  String get escribiTuRol;

  /// No description provided for @configuracion.
  ///
  /// In es, this message translates to:
  /// **'Configuración'**
  String get configuracion;

  /// No description provided for @colores.
  ///
  /// In es, this message translates to:
  /// **'Colores'**
  String get colores;

  /// No description provided for @escribiTuNombre.
  ///
  /// In es, this message translates to:
  /// **'Escribí tu nombre.'**
  String get escribiTuNombre;

  /// No description provided for @escribiElPin.
  ///
  /// In es, this message translates to:
  /// **'Escribí el PIN de la sala.'**
  String get escribiElPin;

  /// No description provided for @pinDe8Caracteres.
  ///
  /// In es, this message translates to:
  /// **'El código tiene 8 caracteres.'**
  String get pinDe8Caracteres;

  /// No description provided for @errorSinConexion.
  ///
  /// In es, this message translates to:
  /// **'No hay conexión. Revisá tu internet e intentá de nuevo.'**
  String get errorSinConexion;

  /// No description provided for @errorSinPermiso.
  ///
  /// In es, this message translates to:
  /// **'No tenés permiso para hacer esto.'**
  String get errorSinPermiso;

  /// No description provided for @errorGenerico.
  ///
  /// In es, this message translates to:
  /// **'Algo salió mal. Intentá de nuevo.'**
  String get errorGenerico;

  /// No description provided for @reintentar.
  ///
  /// In es, this message translates to:
  /// **'Reintentar'**
  String get reintentar;

  /// No description provided for @deshacer.
  ///
  /// In es, this message translates to:
  /// **'Deshacer'**
  String get deshacer;

  /// No description provided for @pedidoEliminado.
  ///
  /// In es, this message translates to:
  /// **'Pedido eliminado'**
  String get pedidoEliminado;

  /// No description provided for @marcarAtendido.
  ///
  /// In es, this message translates to:
  /// **'Marcar como atendido'**
  String get marcarAtendido;

  /// No description provided for @salirDeLaSala.
  ///
  /// In es, this message translates to:
  /// **'Salir de la sala'**
  String get salirDeLaSala;

  /// No description provided for @salirDeLaSalaPregunta.
  ///
  /// In es, this message translates to:
  /// **'¿Salir de la sala?'**
  String get salirDeLaSalaPregunta;

  /// No description provided for @salirDeLaSalaDetalle.
  ///
  /// In es, this message translates to:
  /// **'Para volver a entrar vas a necesitar el código de la sala.'**
  String get salirDeLaSalaDetalle;

  /// No description provided for @salir.
  ///
  /// In es, this message translates to:
  /// **'Salir'**
  String get salir;

  /// No description provided for @fraseMasVolumen.
  ///
  /// In es, this message translates to:
  /// **'Más volumen'**
  String get fraseMasVolumen;

  /// No description provided for @fraseMenosVolumen.
  ///
  /// In es, this message translates to:
  /// **'Menos volumen'**
  String get fraseMenosVolumen;

  /// No description provided for @borrarBusqueda.
  ///
  /// In es, this message translates to:
  /// **'Borrar búsqueda'**
  String get borrarBusqueda;

  /// No description provided for @borrarTodosLosPedidos.
  ///
  /// In es, this message translates to:
  /// **'Borrar todos los pedidos'**
  String get borrarTodosLosPedidos;

  /// No description provided for @entrarComoSonidistaPregunta.
  ///
  /// In es, this message translates to:
  /// **'¿Entrar como sonidista?'**
  String get entrarComoSonidistaPregunta;

  /// No description provided for @entrarComoSonidistaDetalle.
  ///
  /// In es, this message translates to:
  /// **'Tu rol menciona sonido. Podés entrar al panel del sonidista o a la pantalla de pedidos.'**
  String get entrarComoSonidistaDetalle;

  /// No description provided for @panelDelSonidista.
  ///
  /// In es, this message translates to:
  /// **'Panel del sonidista'**
  String get panelDelSonidista;

  /// No description provided for @pantallaDePedidos.
  ///
  /// In es, this message translates to:
  /// **'Pantalla de pedidos'**
  String get pantallaDePedidos;

  /// No description provided for @pedidoYaNoExiste.
  ///
  /// In es, this message translates to:
  /// **'Ese pedido ya no existe.'**
  String get pedidoYaNoExiste;

  /// No description provided for @noHayAcordesParaTransponer.
  ///
  /// In es, this message translates to:
  /// **'No se encontraron acordes para transponer.'**
  String get noHayAcordesParaTransponer;

  /// No description provided for @ajustadoPor.
  ///
  /// In es, this message translates to:
  /// **'Ajustado por {persona}'**
  String ajustadoPor(String persona);

  /// No description provided for @sinConexionAviso.
  ///
  /// In es, this message translates to:
  /// **'Sin conexión. Los pedidos se enviarán cuando vuelva la red.'**
  String get sinConexionAviso;

  /// No description provided for @pedidoPendienteSinConexion.
  ///
  /// In es, this message translates to:
  /// **'Sin conexión: el pedido se enviará cuando vuelva la red. No cierres la app.'**
  String get pedidoPendienteSinConexion;

  /// No description provided for @noSePudoEnviarPedido.
  ///
  /// In es, this message translates to:
  /// **'No se pudo enviar el pedido.'**
  String get noSePudoEnviarPedido;

  /// No description provided for @versionApp.
  ///
  /// In es, this message translates to:
  /// **'Versión {version}'**
  String versionApp(String version);

  /// No description provided for @compartirEnlaceSala.
  ///
  /// In es, this message translates to:
  /// **'Compartir enlace de la sala'**
  String get compartirEnlaceSala;

  /// No description provided for @enlaceSalaTexto.
  ///
  /// In es, this message translates to:
  /// **'Unite a mi sala en Sound Check Pro: {enlace}'**
  String enlaceSalaTexto(String enlace);

  /// No description provided for @salaQuitadaDelHistorial.
  ///
  /// In es, this message translates to:
  /// **'Sala quitada del historial'**
  String get salaQuitadaDelHistorial;

  /// No description provided for @eliminarCuenta.
  ///
  /// In es, this message translates to:
  /// **'Eliminar mi cuenta'**
  String get eliminarCuenta;

  /// No description provided for @eliminarCuentaExplicacion.
  ///
  /// In es, this message translates to:
  /// **'Se van a borrar de forma permanente tu cuenta, tu perfil, tus frases, tu repertorio y tus secuencias (con los archivos que subiste) y tu historial de salas. Esto no se puede deshacer. Los pedidos y las salas que comparten otras personas no se borran.'**
  String get eliminarCuentaExplicacion;

  /// No description provided for @eliminarCuentaContrasena.
  ///
  /// In es, this message translates to:
  /// **'Contraseña actual (para confirmar)'**
  String get eliminarCuentaContrasena;

  /// No description provided for @eliminarDefinitivamente.
  ///
  /// In es, this message translates to:
  /// **'Eliminar definitivamente'**
  String get eliminarDefinitivamente;

  /// No description provided for @eliminarCuentaPregunta.
  ///
  /// In es, this message translates to:
  /// **'¿Eliminar tu cuenta para siempre?'**
  String get eliminarCuentaPregunta;

  /// No description provided for @eliminandoCuenta.
  ///
  /// In es, this message translates to:
  /// **'Eliminando tu cuenta…'**
  String get eliminandoCuenta;

  /// No description provided for @cuentaEliminada.
  ///
  /// In es, this message translates to:
  /// **'Tu cuenta y tus datos fueron eliminados'**
  String get cuentaEliminada;

  /// No description provided for @noSePudoEliminarCuenta.
  ///
  /// In es, this message translates to:
  /// **'No se pudo eliminar la cuenta. Revisá tu conexión y probá de nuevo.'**
  String get noSePudoEliminarCuenta;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'es', 'fr', 'it', 'pt'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'fr':
      return AppLocalizationsFr();
    case 'it':
      return AppLocalizationsIt();
    case 'pt':
      return AppLocalizationsPt();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
