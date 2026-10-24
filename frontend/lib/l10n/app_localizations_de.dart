// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get tuRolPodesMarcarMas => 'Deine Rolle (du kannst mehrere wählen)';

  @override
  String get inicioDeSesionConGoogle => 'Anmeldung mit Google abgebrochen.';

  @override
  String get elEmailNoEsValido => 'Die E-Mail-Adresse ist ungültig.';

  @override
  String get estaCuentaFueDeshabilitada => 'Dieses Konto wurde deaktiviert.';

  @override
  String get noExisteUnaCuentaCon =>
      'Es gibt kein Konto mit dieser E-Mail-Adresse.';

  @override
  String get emailOContrasenaIncorrectos => 'E-Mail oder Passwort falsch.';

  @override
  String get yaExisteUnaCuentaCon =>
      'Es gibt bereits ein Konto mit dieser E-Mail-Adresse.';

  @override
  String get laContrasenaDebeTenerAl =>
      'Das Passwort muss mindestens 6 Zeichen lang sein.';

  @override
  String get errorDeAutenticacion => 'Authentifizierungsfehler.';

  @override
  String get pausar => 'Pause';

  @override
  String get reproducir => 'Abspielen';

  @override
  String noSePudoReproducir(Object error) {
    return 'Wiedergabe nicht möglich: $error';
  }

  @override
  String get bajandoElVolumen => 'Lautstärke wird gesenkt...';

  @override
  String fadeOutS(Object segundos) {
    return 'Ausblenden ($segundos s)';
  }

  @override
  String get detener => 'Stopp';

  @override
  String get modoClaroOscuroParaEl =>
      'Hell-/Dunkelmodus (für den Rest der App)';

  @override
  String get colorDeLaApp => 'App-Farbe';

  @override
  String get comunicacionEnVivoEntreMusicos =>
      'Live-Kommunikation\nzwischen Musikern und Tontechnikern';

  @override
  String get iniciarSesion => 'Anmelden';

  @override
  String get crearCuenta => 'Konto erstellen';

  @override
  String get entrarComoInvitado => 'Als Gast eintreten';

  @override
  String get tiempoReal => 'Echtzeit';

  @override
  String get sincronizacionInstantanea => 'Sofortige\nSynchronisierung';

  @override
  String get urgente => 'Dringend';

  @override
  String get alertasVisualesYSonoras => 'Visuelle und\nakustische Warnungen';

  @override
  String get multiSala => 'Mehrere Räume';

  @override
  String get manejaVariasBandasYShows => 'Verwalte mehrere\nBands und Shows';

  @override
  String get setlistEnVivo => 'Live-Setlist';

  @override
  String get listaDeTemasCompartida => 'Gemeinsame\nSongliste';

  @override
  String get completaEmailYContrasena => 'Bitte E-Mail und Passwort eingeben.';

  @override
  String get completaTuPerfil => 'Vervollständige dein Profil';

  @override
  String get tuNombre => 'Dein Name';

  @override
  String get requerido => 'Pflichtfeld';

  @override
  String get tuRolEjSonidistaGuitarrista =>
      'Deine Rolle (z. B. Tontechniker, Gitarrist)';

  @override
  String get guardar => 'Speichern';

  @override
  String get recuperarContrasena => 'Passwort zurücksetzen';

  @override
  String get tuEmail => 'Deine E-Mail';

  @override
  String get cancelar => 'Abbrechen';

  @override
  String get enviarEmail => 'E-Mail senden';

  @override
  String get teEnviamosUnEmailPara =>
      'Wir haben dir eine E-Mail zum Zurücksetzen deines Passworts geschickt.';

  @override
  String get tuRolEjSonidistaGuitarrista2 =>
      'Deine Rolle (z. B. Tontechniker, Gitarrist, Sänger)';

  @override
  String get email => 'E-Mail';

  @override
  String get emailInvalido => 'Ungültige E-Mail';

  @override
  String get contrasena => 'Passwort';

  @override
  String get minimo6Caracteres => 'Mindestens 6 Zeichen';

  @override
  String get olvidasteTuContrasena => 'Passwort vergessen?';

  @override
  String get registrarme => 'REGISTRIEREN';

  @override
  String get iniciarSesion2 => 'ANMELDEN';

  @override
  String get yaTenesCuentaIniciarSesion => 'Schon ein Konto? Anmelden';

  @override
  String get noTenesCuentaRegistrarme => 'Noch kein Konto? Registrieren';

  @override
  String get continuarConGoogle => 'Weiter mit Google';

  @override
  String get continuarSinCuenta => 'Ohne Konto fortfahren';

  @override
  String get cerrarSesionDeCuenta => 'Vom Konto abmelden';

  @override
  String sesion(Object usuario) {
    return 'Sitzung: $usuario';
  }

  @override
  String get crearNuevaSala => 'NEUEN RAUM ERSTELLEN';

  @override
  String get unirmeASala => 'EINEM RAUM BEITRETEN';

  @override
  String get misSalas => 'MEINE RÄUME';

  @override
  String get misFrases => 'MEINE SÄTZE';

  @override
  String get miRepertorio => 'MEIN REPERTOIRE';

  @override
  String get misSecuencias => 'MEINE SEQUENZEN';

  @override
  String get accesoSonidista => 'ZUGANG TONTECHNIKER';

  @override
  String get elegiLaIdentidadVisualDe =>
      'Wähle die visuelle Identität der App. Sie wird auf diesem Gerät gespeichert.';

  @override
  String get marcaAlMenosUnRol => 'Wähle mindestens eine Rolle.';

  @override
  String errorAlIngresar(Object error) {
    return 'Fehler beim Anmelden: $error';
  }

  @override
  String get configurarSala => 'Raum einrichten';

  @override
  String get tuPinDeSala => 'Die PIN deines Raums';

  @override
  String get pinCopiado => 'PIN kopiert';

  @override
  String get tuNombre2 => 'Dein Name';

  @override
  String get empezar => 'LOS GEHT’S';

  @override
  String get unirseASala => 'Einem Raum beitreten';

  @override
  String get codigoDeSala8Caracteres => 'Raumcode (8 Zeichen)';

  @override
  String get unirme => 'BEITRETEN';

  @override
  String get nombreParaEstaSala => 'Name für diesen Raum';

  @override
  String get ejBandaXEnsayoJueves => 'z. B.: Band X – Donnerstagsprobe';

  @override
  String get misSalas2 => 'Meine Räume';

  @override
  String get necesitasIniciarSesionParaTener =>
      'Du musst dich anmelden, um einen Raumverlauf zu haben.';

  @override
  String get guardarUnHistorialDeVarias =>
      'Einen Verlauf mehrerer Räume/Bands zu speichern, um mit einem Tipp zurückzukehren, ist eine Pro-Funktion.';

  @override
  String get todaviaNoEntrasteANinguna =>
      'Du bist mit diesem Konto noch keinem Raum beigetreten.';

  @override
  String get renombrar => 'Umbenennen';

  @override
  String get quitarDelHistorial => 'Aus dem Verlauf entfernen';

  @override
  String get queQueresVerEnLa => 'Was möchtest du im Raum sehen?';

  @override
  String get seGuardaEnEsteDispositivo =>
      'Wird auf diesem Gerät gespeichert. Mindestens eine muss übrig bleiben.';

  @override
  String urgenteEnviado(Object texto) {
    return 'Dringend gesendet!: $texto';
  }

  @override
  String enviado(Object texto) {
    return 'Gesendet: $texto';
  }

  @override
  String get cerrarSesion => 'Abmelden';

  @override
  String get codigoDeSalaCopiado => 'Raumcode kopiert';

  @override
  String sala(Object codigoSala) {
    return 'RAUM: $codigoSala';
  }

  @override
  String get pantallaSiempreEncendidaActivado => 'Display immer an: aktiviert';

  @override
  String get pantallaSiempreEncendidaDesactivado =>
      'Display immer an: deaktiviert';

  @override
  String get elegirQueVerEnLa => 'Auswählen, was im Raum angezeigt wird';

  @override
  String get escribirPedidoPersonalizado => 'Eigene Anfrage schreiben...';

  @override
  String get pedidoUrgenteActivado => 'Dringende Anfrage: aktiviert';

  @override
  String get marcarElProximoPedidoComo =>
      'Nächste Anfrage als dringend markieren';

  @override
  String get misUltimosPedidos => 'MEINE LETZTEN ANFRAGEN';

  @override
  String error(Object error) {
    return 'Fehler: $error';
  }

  @override
  String get sinPedidosPropios => 'Keine eigenen Anfragen';

  @override
  String eliminandoPedido(Object pedido) {
    return 'Anfrage wird gelöscht: „$pedido“';
  }

  @override
  String consola(Object respuesta) {
    return 'Pult: $respuesta';
  }

  @override
  String get desdeMiBiblioteca => 'Aus meiner Bibliothek';

  @override
  String get buscarEnBibliotecasDeLa => 'In den Bibliotheken des Raums suchen';

  @override
  String get necesitasIniciarSesionParaUsar =>
      'Du musst dich anmelden, um deine Bibliothek zu nutzen.';

  @override
  String get tuBibliotecaEstaVacia => 'Deine Bibliothek ist leer.';

  @override
  String get titulo => 'Titel...';

  @override
  String get tonalidad => 'Tonart...';

  @override
  String get sinResultados => 'Keine Ergebnisse.';

  @override
  String get noSePudoBuscarIntenta =>
      'Suche nicht möglich. Versuche es gleich noch einmal.';

  @override
  String get todaviaNoHayBibliotecasPara =>
      'In diesem Raum gibt es noch keine Bibliotheken zum Durchsuchen.';

  @override
  String de(Object propietario) {
    return 'von $propietario';
  }

  @override
  String get elSetlistEstaVacioNo =>
      'Die Setlist ist leer, es gibt nichts zu exportieren.';

  @override
  String setlistSala(Object codigoSala) {
    return 'Setlist — Raum $codigoSala\n\n';
  }

  @override
  String get exportarSetlist => 'Setlist exportieren';

  @override
  String get copiadoAlPortapapeles => 'In die Zwischenablage kopiert';

  @override
  String get copiar => 'Kopieren';

  @override
  String setlistSala2(Object codigoSala) {
    return 'Setlist - Raum $codigoSala';
  }

  @override
  String get compartir => 'Teilen';

  @override
  String get cerrar => 'Schließen';

  @override
  String agregado(Object titulo) {
    return 'Hinzugefügt: $titulo';
  }

  @override
  String get todaviaNoHayTemasEn => 'Noch keine Songs in der Liste.';

  @override
  String get cambiarEstadoDelTema => 'Songstatus ändern';

  @override
  String get pendiente => 'Ausstehend';

  @override
  String get pausadoCorteTecnico => 'Pausiert (technische Unterbrechung)';

  @override
  String get tocado => 'Gespielt';

  @override
  String get pausado => 'PAUSIERT';

  @override
  String get proximo => 'NÄCHSTER';

  @override
  String subidoPor(Object persona) {
    return 'Hochgeladen von $persona';
  }

  @override
  String get verCifradoTransponer => 'Akkorde ansehen (transponieren)';

  @override
  String get exportarCompartirSetlist => 'Setlist exportieren / teilen';

  @override
  String get agregarCancion => 'Song hinzufügen';

  @override
  String get necesitasIniciarSesionParaUsar2 =>
      'Du musst dich anmelden, um deine Sequenzen zu nutzen.';

  @override
  String get noTenesSecuenciasTodaviaSubilas =>
      'Du hast noch keine Sequenzen.\nLade sie unter „Meine Sequenzen“ im Hauptmenü hoch.';

  @override
  String get buscarSecuencia => 'Sequenz suchen...';

  @override
  String get yaEstaEnLaSala => 'Bereits im Raum';

  @override
  String get elegiLasSecuenciasDeHoy => 'Wähle die Sequenzen für heute';

  @override
  String cargarALaSala(Object cantidad) {
    return '$cantidad IN DEN RAUM LADEN';
  }

  @override
  String noSePudieronCargar(Object error) {
    return 'Hinzufügen nicht möglich: $error';
  }

  @override
  String get quitarDeLaSala => 'Aus dem Raum entfernen';

  @override
  String quitarDeLasSecuenciasDe(Object titulo) {
    return '„$titulo“ aus den heutigen Sequenzen entfernen? Sie bleibt in der Bibliothek der Person, die sie hochgeladen hat.';
  }

  @override
  String get quitar => 'Entfernen';

  @override
  String noSePudoGuardarEl(Object error) {
    return 'Einstellung konnte nicht gespeichert werden: $error';
  }

  @override
  String get seGuardaParaTodaLa =>
      'Wird für den ganzen Raum gespeichert. Tonart, Tempo und Lautstärke werden getrennt geändert.';

  @override
  String get tono => 'TONART';

  @override
  String get bajarUnSemitono => 'Einen Halbton tiefer';

  @override
  String get subirUnSemitono => 'Einen Halbton höher';

  @override
  String get elCambioDeTonoPor =>
      'Die Tonartänderung funktioniert vorerst nur in der Webversion.';

  @override
  String get tempo => 'TEMPO';

  @override
  String get masLento1 => 'Langsamer (1 %)';

  @override
  String get masRapido1 => 'Schneller (1 %)';

  @override
  String get volumen => 'LAUTSTÄRKE';

  @override
  String get bajar5 => '5 % leiser';

  @override
  String get subir5 => '5 % lauter';

  @override
  String get restablecerComoSeSubio => 'Zurücksetzen (wie hochgeladen)';

  @override
  String noSePudieronCargarLas(Object error) {
    return 'Sequenzen konnten nicht geladen werden: $error';
  }

  @override
  String cargadaPor(Object persona) {
    return 'Hinzugefügt von $persona';
  }

  @override
  String get tonoTempoYVolumen => 'Tonart, Tempo und Lautstärke';

  @override
  String get repetir => 'Wiederholen';

  @override
  String get todaviaNoHaySecuenciasCargadas =>
      'Für heute sind noch keine Sequenzen geladen.';

  @override
  String get todaviaNoHaySecuenciasCargadas2 =>
      'Für heute sind noch keine Sequenzen geladen.\nTippe auf +, um sie aus „Meine Sequenzen“ auszuwählen.';

  @override
  String get cargarSecuenciasDeHoy => 'Heutige Sequenzen laden';

  @override
  String get nuevaFrase => 'Neuer Satz';

  @override
  String get textoDeLaFrase => 'Text des Satzes';

  @override
  String get agregar => 'Hinzufügen';

  @override
  String get editarFrase => 'Satz bearbeiten';

  @override
  String get misFrases2 => 'Meine Sätze';

  @override
  String get necesitasIniciarSesionParaEditar =>
      'Du musst dich anmelden, um deine Sätze zu bearbeiten.';

  @override
  String get todaviaNoTenesFrasesPropias => 'Du hast noch keine eigenen Sätze.';

  @override
  String get cargarFrasesPorDefecto => 'Standardsätze laden';

  @override
  String get funcionPro => 'Pro-Funktion';

  @override
  String get subirTusPropiasPartiturasCifrados =>
      'Das Hochladen eigener Noten/Akkordblätter als PDF gehört zu Sound Check Pro. Aktiviere dein Pro-Konto, um diese Funktion zu nutzen.';

  @override
  String get entendido => 'Verstanden';

  @override
  String errorAlSubir(Object error) {
    return 'Fehler beim Hochladen: $error';
  }

  @override
  String get nuevaCancion => 'Neuer Song';

  @override
  String get editarCancion => 'Song bearbeiten';

  @override
  String get titulo2 => 'Titel';

  @override
  String get tonalidadOpcional => 'Tonart (optional)';

  @override
  String get cifradoEnTextoOpcionalPara =>
      'Akkorde als Text (optional, zum Transponieren)';

  @override
  String get pegaLosAcordesAcaEj =>
      'Füge die Akkorde hier ein. Z. B.: [C]Amazing [G]grace...';

  @override
  String get regenerarCifrados => 'Akkorde neu erzeugen';

  @override
  String get seVaAVolverA =>
      'Jedes PDF in deiner Bibliothek wird erneut gelesen, um das Akkordblatt mit den Akkorden an den Positionen des Original-PDFs neu aufzubauen.\n\nDadurch wird der für jeden Song gespeicherte Akkordtext ersetzt (auch von Hand Bearbeitetes). Songs, deren PDF keinen markierbaren Text enthält, bleiben unverändert.';

  @override
  String get regenerar => 'Neu erzeugen';

  @override
  String get preparando => 'Wird vorbereitet...';

  @override
  String procesandoDe(Object hechas, Object total) {
    return 'Verarbeite $hechas von $total...';
  }

  @override
  String actualizadas(Object cantidad) {
    return '$cantidad aktualisiert';
  }

  @override
  String sinTextoEnElPdf(Object cantidad) {
    return '$cantidad ohne Text im PDF';
  }

  @override
  String conError(Object cantidad) {
    return '$cantidad mit Fehler';
  }

  @override
  String cifrados(Object detalle) {
    return 'Akkorde: $detalle.';
  }

  @override
  String get eliminarCancion => 'Song löschen?';

  @override
  String get seBorraDeTuBiblioteca =>
      'Er wird aus deiner Bibliothek entfernt. Ist er in der Setlist eines Raums, lässt er sich dort nicht mehr öffnen.';

  @override
  String get eliminar => 'Löschen';

  @override
  String get miRepertorio2 => 'Mein Repertoire';

  @override
  String get regenerarCifradosDesdeLosPdf =>
      'Akkorde aus den PDFs neu erzeugen';

  @override
  String get necesitasIniciarSesionParaTener2 =>
      'Du musst dich anmelden, um eine Bibliothek zu haben.';

  @override
  String get subirTusPropiasPartiturasEs =>
      'Das Hochladen eigener Noten ist eine Pro-Funktion.';

  @override
  String get masInfo => 'Mehr Infos';

  @override
  String get todaviaNoSubisteNingunaCancion =>
      'Du hast noch keinen Song hochgeladen.';

  @override
  String tonalidad2(Object tonalidad) {
    return 'Tonart: $tonalidad';
  }

  @override
  String get subirTusPropiasSecuenciasEs =>
      'Das Hochladen eigener Sequenzen gehört zu Sound Check Pro. Aktiviere dein Pro-Konto, um diese Funktion zu nutzen.';

  @override
  String get archivoDemasiadoGrande => 'Datei zu groß';

  @override
  String get archivosDemasiadoGrandes => 'Dateien zu groß';

  @override
  String elMaximoPorArchivoEs(Object lista, Object limite) {
    return '$lista\n\nDas Maximum pro Datei beträgt $limite. Konvertiere in MP3 (bei 320 kbps belegt ein ganzer Song etwa 10–15 MB) und lade erneut hoch, oder lade über die Webversion hoch, die automatisch konvertiert.';
  }

  @override
  String convirtiendoAMp3(Object contador) {
    return 'Konvertiere in MP3$contador';
  }

  @override
  String convirtiendoAMp32(Object porcentaje, Object contador) {
    return 'Konvertiere in MP3 $porcentaje %$contador';
  }

  @override
  String subiendo(Object contador) {
    return 'Lade hoch$contador';
  }

  @override
  String get secuenciasSubidas => 'Sequenzen hochgeladen';

  @override
  String get algunasSecuenciasNoSeSubieron =>
      'Einige Sequenzen wurden nicht hochgeladen';

  @override
  String seConvirtieronAMp3Porque(Object limite, Object lista) {
    return 'Sie wurden in MP3 konvertiert, weil sie das Maximum von $limite überschritten:\n$lista';
  }

  @override
  String noSePudieronSubir(Object lista) {
    return 'Hochladen nicht möglich:\n$lista';
  }

  @override
  String get renombrarSecuencia => 'Sequenz umbenennen';

  @override
  String get eliminarSecuencia => 'Sequenz löschen';

  @override
  String eliminarDeTuBiblioteca(Object titulo) {
    return '„$titulo“ aus deiner Bibliothek löschen?';
  }

  @override
  String get misSecuencias2 => 'Meine Sequenzen';

  @override
  String get necesitasIniciarSesionParaTener3 =>
      'Du musst dich anmelden, um Sequenzen zu haben.';

  @override
  String errorAlCargar(Object error) {
    return 'Fehler beim Laden: $error';
  }

  @override
  String get todaviaNoSubisteSecuenciasToca =>
      'Du hast noch keine Sequenzen hochgeladen.\nTippe auf die Schaltfläche unten, um deine Audiospuren hochzuladen (MP3, WAV, M4A...).';

  @override
  String get subirSecuencias => 'Sequenzen hochladen';

  @override
  String get restablecerTonoOriginal => 'Originaltonart wiederherstellen';

  @override
  String get sincronizadoConTodaLaSala =>
      'Mit dem ganzen Raum synchronisiert (tippen zum Trennen)';

  @override
  String get desincronizadoCambiosSoloLocalesToca =>
      'Nicht synchronisiert — Änderungen nur lokal (tippen zum erneuten Synchronisieren)';

  @override
  String noSePudoCargarEl(Object error) {
    return 'Das PDF konnte nicht geladen werden.\n$error';
  }

  @override
  String errorAlIngresarAlPanel(Object error) {
    return 'Fehler beim Öffnen des Panels: $error';
  }

  @override
  String get accesoSonidista2 => 'Zugang Tontechniker';

  @override
  String get pinDeSalaOCrear => 'Raum-PIN oder Raum erstellen';

  @override
  String get accederAlPanel => 'PANEL ÖFFNEN';

  @override
  String tuRespuesta(Object respuesta) {
    return 'Deine Antwort: $respuesta';
  }

  @override
  String get responderPrivado => 'Privat antworten';

  @override
  String responderA(Object musico) {
    return '$musico antworten';
  }

  @override
  String pedido(Object pedido) {
    return 'Anfrage: „$pedido“';
  }

  @override
  String get escribirRespuestaPrivada => 'Private Antwort schreiben...';

  @override
  String get enviar => 'Senden';

  @override
  String consola2(Object codigoSala) {
    return 'Pult: $codigoSala';
  }

  @override
  String get borrarTodo => 'Alles löschen?';

  @override
  String get no => 'Nein';

  @override
  String get si => 'Ja';

  @override
  String get agrupadoPorRolActivado => 'Nach Rolle gruppiert: aktiviert';

  @override
  String get verAgrupadoPorRol => 'Nach Rolle gruppiert anzeigen';

  @override
  String errorDeConexion(Object error) {
    return 'Verbindungsfehler: $error';
  }

  @override
  String get esperandoPedidos => 'Warte auf Anfragen...';

  @override
  String get todaviaNoAtendisteNingunPedido =>
      'Du hast noch keine Anfrage bearbeitet';

  @override
  String get nombreApp => 'Sound Check Pro';

  @override
  String get rolMusico => 'Musiker';

  @override
  String get rolCantante => 'Sänger';

  @override
  String get rolSonidista => 'Tontechniker';

  @override
  String get rolOtro => 'Sonstige';

  @override
  String rolesYUltimo(String lista, String ultimo) {
    return '$lista und $ultimo';
  }

  @override
  String get paletaEscenarioNombre => 'Bühne';

  @override
  String get paletaEscenarioTag => 'Neon in Cyan und Violett';

  @override
  String get paletaConsolaNombre => 'Pult';

  @override
  String get paletaConsolaTag => 'Violett, edel';

  @override
  String get paletaPlacaNombre => 'Frontplatte';

  @override
  String get paletaPlacaTag => 'Graphit + VU-Bernstein';

  @override
  String get paletaWashNombre => 'Wash';

  @override
  String get paletaWashTag => 'Petrolblau wie Bühnenlicht';

  @override
  String get paletaLuzDeTrabajoNombre => 'Arbeitslicht';

  @override
  String get paletaLuzDeTrabajoTag => 'Maximaler Kontrast';

  @override
  String get paletaCamarinNombre => 'Garderobe';

  @override
  String get paletaCamarinTag => 'Pastellrosa, sanft';

  @override
  String get pestanaPedidos => 'Anfragen';

  @override
  String get pestanaHistorial => 'Verlauf';

  @override
  String get pestanaSetlist => 'Setlist';

  @override
  String get pestanaSecuencias => 'Sequenzen';

  @override
  String get fraseVolumenRetorno => 'Lautstärke Monitor';

  @override
  String get fraseVolumenAl2 => 'Lautstärke auf 2';

  @override
  String get fraseVolumenAl3 => 'Lautstärke auf 3';

  @override
  String get fraseVolumenAl4 => 'Lautstärke auf 4';

  @override
  String get fraseVolumenGuitarra => 'Lautstärke Gitarre';

  @override
  String get fraseVolumenTeclado => 'Lautstärke Keyboard';

  @override
  String get fraseVolumenTalkback => 'Lautstärke Talkback';

  @override
  String get fraseVolumenPista => 'Lautstärke Playback';

  @override
  String get fraseVolumenClick => 'Lautstärke Click';

  @override
  String get fraseVolumenCoordinador => 'Lautstärke Koordinator';

  @override
  String get fraseVolumenGeneral => 'Gesamtlautstärke';

  @override
  String get fraseListo => 'Fertig';

  @override
  String get tonoOriginal => 'Original';

  @override
  String semitonosConSigno(String signo, int cantidad) {
    String _temp0 = intl.Intl.pluralLogic(
      cantidad,
      locale: localeName,
      other: '$signo$cantidad Halbtöne',
      one: '$signo$cantidad Halbton',
    );
    return '$_temp0';
  }

  @override
  String ajusteTono(String valor) {
    return 'Tonart $valor';
  }

  @override
  String ajusteTempo(int valor) {
    return 'Tempo $valor %';
  }

  @override
  String ajusteVolumen(int valor) {
    return 'Lautst. $valor %';
  }

  @override
  String secuenciasParaHoy(int cantidad) {
    String _temp0 = intl.Intl.pluralLogic(
      cantidad,
      locale: localeName,
      other: '$cantidad Sequenzen für heute',
      one: '1 Sequenz für heute',
    );
    return '$_temp0';
  }

  @override
  String get idioma => 'Sprache';

  @override
  String get idiomaAutomatico => 'Automatisch (Gerätesprache)';

  @override
  String get idiomaDescripcion =>
      'Wähle die Sprache der App. Sie wird auf diesem Gerät gespeichert.';

  @override
  String get escribiTuRol => 'Gib deine Rolle ein.';

  @override
  String get configuracion => 'Einstellungen';

  @override
  String get colores => 'Farben';
}
