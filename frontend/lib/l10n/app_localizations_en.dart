// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get tuRolPodesMarcarMas => 'Your role (you can pick more than one)';

  @override
  String get inicioDeSesionConGoogle => 'Google sign-in was cancelled.';

  @override
  String get elEmailNoEsValido => 'The email is not valid.';

  @override
  String get estaCuentaFueDeshabilitada => 'This account has been disabled.';

  @override
  String get noExisteUnaCuentaCon => 'There is no account with that email.';

  @override
  String get emailOContrasenaIncorrectos => 'Incorrect email or password.';

  @override
  String get yaExisteUnaCuentaCon =>
      'An account with that email already exists.';

  @override
  String get laContrasenaDebeTenerAl =>
      'The password must be at least 6 characters long.';

  @override
  String get errorDeAutenticacion => 'Authentication error.';

  @override
  String get pausar => 'Pause';

  @override
  String get reproducir => 'Play';

  @override
  String noSePudoReproducir(Object error) {
    return 'Could not play: $error';
  }

  @override
  String get bajandoElVolumen => 'Fading out...';

  @override
  String fadeOutS(Object segundos) {
    return 'Fade out ($segundos s)';
  }

  @override
  String get detener => 'Stop';

  @override
  String get modoClaroOscuroParaEl =>
      'Light/dark mode (for the rest of the app)';

  @override
  String get colorDeLaApp => 'App color';

  @override
  String get comunicacionEnVivoEntreMusicos =>
      'Live communication\nbetween musicians and sound engineers';

  @override
  String get iniciarSesion => 'Sign in';

  @override
  String get crearCuenta => 'Create account';

  @override
  String get entrarComoInvitado => 'Continue as guest';

  @override
  String get tiempoReal => 'Real time';

  @override
  String get sincronizacionInstantanea => 'Instant\nsync';

  @override
  String get urgente => 'Urgent';

  @override
  String get alertasVisualesYSonoras => 'Visual and\naudible alerts';

  @override
  String get multiSala => 'Multi-room';

  @override
  String get manejaVariasBandasYShows => 'Manage several\nbands and shows';

  @override
  String get setlistEnVivo => 'Live setlist';

  @override
  String get listaDeTemasCompartida => 'Shared\nsong list';

  @override
  String get completaEmailYContrasena => 'Enter your email and password.';

  @override
  String get completaTuPerfil => 'Complete your profile';

  @override
  String get tuNombre => 'Your name';

  @override
  String get requerido => 'Required';

  @override
  String get tuRolEjSonidistaGuitarrista =>
      'Your role (e.g. sound engineer, guitarist)';

  @override
  String get guardar => 'Save';

  @override
  String get recuperarContrasena => 'Reset password';

  @override
  String get tuEmail => 'Your email';

  @override
  String get cancelar => 'Cancel';

  @override
  String get enviarEmail => 'Send email';

  @override
  String get teEnviamosUnEmailPara =>
      'We sent you an email to reset your password.';

  @override
  String get tuRolEjSonidistaGuitarrista2 =>
      'Your role (e.g. sound engineer, guitarist, backing vocalist)';

  @override
  String get email => 'Email';

  @override
  String get emailInvalido => 'Invalid email';

  @override
  String get contrasena => 'Password';

  @override
  String get minimo6Caracteres => 'At least 6 characters';

  @override
  String get olvidasteTuContrasena => 'Forgot your password?';

  @override
  String get registrarme => 'SIGN UP';

  @override
  String get iniciarSesion2 => 'SIGN IN';

  @override
  String get yaTenesCuentaIniciarSesion => 'Already have an account? Sign in';

  @override
  String get noTenesCuentaRegistrarme => 'Don’t have an account? Sign up';

  @override
  String get continuarConGoogle => 'Continue with Google';

  @override
  String get continuarSinCuenta => 'Continue without an account';

  @override
  String get cerrarSesionDeCuenta => 'Sign out of your account';

  @override
  String sesion(Object usuario) {
    return 'Signed in as: $usuario';
  }

  @override
  String get crearNuevaSala => 'CREATE NEW ROOM';

  @override
  String get unirmeASala => 'JOIN A ROOM';

  @override
  String get misSalas => 'MY ROOMS';

  @override
  String get misFrases => 'MY PHRASES';

  @override
  String get miRepertorio => 'MY REPERTOIRE';

  @override
  String get misSecuencias => 'MY TRACKS';

  @override
  String get accesoSonidista => 'SOUND ENGINEER ACCESS';

  @override
  String get elegiLaIdentidadVisualDe =>
      'Choose the look of the app. It is saved on this device.';

  @override
  String get marcaAlMenosUnRol => 'Select at least one role.';

  @override
  String errorAlIngresar(Object error) {
    return 'Error signing in: $error';
  }

  @override
  String get configurarSala => 'Room setup';

  @override
  String get tuPinDeSala => 'Your room PIN';

  @override
  String get pinCopiado => 'PIN copied';

  @override
  String get tuNombre2 => 'Your name';

  @override
  String get empezar => 'START';

  @override
  String get unirseASala => 'Join a room';

  @override
  String get codigoDeSala8Caracteres => 'Room code (8 characters)';

  @override
  String get unirme => 'JOIN';

  @override
  String get nombreParaEstaSala => 'Name for this room';

  @override
  String get ejBandaXEnsayoJueves => 'E.g. Band X - Thursday rehearsal';

  @override
  String get misSalas2 => 'My rooms';

  @override
  String get necesitasIniciarSesionParaTener =>
      'You need to sign in to keep a room history.';

  @override
  String get guardarUnHistorialDeVarias =>
      'Keeping a history of several rooms/bands so you can rejoin with one tap is a Pro feature.';

  @override
  String get todaviaNoEntrasteANinguna =>
      'You haven’t joined any room with this account yet.';

  @override
  String get renombrar => 'Rename';

  @override
  String get quitarDelHistorial => 'Remove from history';

  @override
  String get queQueresVerEnLa => 'What do you want to see in the room?';

  @override
  String get seGuardaEnEsteDispositivo =>
      'Saved on this device. At least one must remain.';

  @override
  String urgenteEnviado(Object texto) {
    return 'Urgent request sent!: $texto';
  }

  @override
  String enviado(Object texto) {
    return 'Sent: $texto';
  }

  @override
  String get cerrarSesion => 'Sign out';

  @override
  String get codigoDeSalaCopiado => 'Room code copied';

  @override
  String sala(Object codigoSala) {
    return 'ROOM: $codigoSala';
  }

  @override
  String get pantallaSiempreEncendidaActivado => 'Keep screen on: enabled';

  @override
  String get pantallaSiempreEncendidaDesactivado => 'Keep screen on: disabled';

  @override
  String get elegirQueVerEnLa => 'Choose what to see in the room';

  @override
  String get escribirPedidoPersonalizado => 'Write a custom request...';

  @override
  String get pedidoUrgenteActivado => 'Urgent request: enabled';

  @override
  String get marcarElProximoPedidoComo => 'Mark the next request as urgent';

  @override
  String get misUltimosPedidos => 'MY LATEST REQUESTS';

  @override
  String error(Object error) {
    return 'Error: $error';
  }

  @override
  String get sinPedidosPropios => 'No requests of your own';

  @override
  String eliminandoPedido(Object pedido) {
    return 'Deleting request: \"$pedido\"';
  }

  @override
  String consola(Object respuesta) {
    return 'Console: $respuesta';
  }

  @override
  String get desdeMiBiblioteca => 'From my library';

  @override
  String get buscarEnBibliotecasDeLa => 'Search the room’s libraries';

  @override
  String get necesitasIniciarSesionParaUsar =>
      'You need to sign in to use your library.';

  @override
  String get tuBibliotecaEstaVacia => 'Your library is empty.';

  @override
  String get titulo => 'Title...';

  @override
  String get tonalidad => 'Key...';

  @override
  String get sinResultados => 'No results.';

  @override
  String get noSePudoBuscarIntenta =>
      'Search failed. Please try again in a moment.';

  @override
  String get todaviaNoHayBibliotecasPara =>
      'There are no libraries to search in this room yet.';

  @override
  String de(Object propietario) {
    return 'from $propietario';
  }

  @override
  String get elSetlistEstaVacioNo =>
      'The setlist is empty, there is nothing to export.';

  @override
  String setlistSala(Object codigoSala) {
    return 'Setlist — Room $codigoSala\n\n';
  }

  @override
  String get exportarSetlist => 'Export setlist';

  @override
  String get copiadoAlPortapapeles => 'Copied to the clipboard';

  @override
  String get copiar => 'Copy';

  @override
  String setlistSala2(Object codigoSala) {
    return 'Setlist - Room $codigoSala';
  }

  @override
  String get compartir => 'Share';

  @override
  String get cerrar => 'Close';

  @override
  String agregado(Object titulo) {
    return 'Added: $titulo';
  }

  @override
  String get todaviaNoHayTemasEn => 'There are no songs in the list yet.';

  @override
  String get cambiarEstadoDelTema => 'Change song status';

  @override
  String get pendiente => 'Pending';

  @override
  String get pausadoCorteTecnico => 'Paused (technical break)';

  @override
  String get tocado => 'Played';

  @override
  String get pausado => 'PAUSED';

  @override
  String get proximo => 'NEXT';

  @override
  String subidoPor(Object persona) {
    return 'Uploaded by $persona';
  }

  @override
  String get verCifradoTransponer => 'View chord chart (transpose)';

  @override
  String get exportarCompartirSetlist => 'Export / share setlist';

  @override
  String get agregarCancion => 'Add song';

  @override
  String get necesitasIniciarSesionParaUsar2 =>
      'You need to sign in to use your tracks.';

  @override
  String get noTenesSecuenciasTodaviaSubilas =>
      'You don’t have any tracks yet.\nUpload them from \"My tracks\" in the main menu.';

  @override
  String get buscarSecuencia => 'Search tracks...';

  @override
  String get yaEstaEnLaSala => 'Already in the room';

  @override
  String get elegiLasSecuenciasDeHoy => 'Choose today’s tracks';

  @override
  String cargarALaSala(Object cantidad) {
    return 'ADD $cantidad TO THE ROOM';
  }

  @override
  String noSePudieronCargar(Object error) {
    return 'Could not add them: $error';
  }

  @override
  String get quitarDeLaSala => 'Remove from the room';

  @override
  String quitarDeLasSecuenciasDe(Object titulo) {
    return 'Remove \"$titulo\" from today’s tracks? It stays in the library of whoever uploaded it.';
  }

  @override
  String get quitar => 'Remove';

  @override
  String noSePudoGuardarEl(Object error) {
    return 'Could not save the setting: $error';
  }

  @override
  String get seGuardaParaTodaLa =>
      'Saved for the whole room. Pitch, tempo and volume are changed separately.';

  @override
  String get tono => 'PITCH';

  @override
  String get bajarUnSemitono => 'Down one semitone';

  @override
  String get subirUnSemitono => 'Up one semitone';

  @override
  String get elCambioDeTonoPor =>
      'Pitch change only works in the web version for now.';

  @override
  String get tempo => 'TEMPO';

  @override
  String get masLento1 => 'Slower (1%)';

  @override
  String get masRapido1 => 'Faster (1%)';

  @override
  String get volumen => 'VOLUME';

  @override
  String get bajar5 => 'Down 5%';

  @override
  String get subir5 => 'Up 5%';

  @override
  String get restablecerComoSeSubio => 'Reset (as uploaded)';

  @override
  String noSePudieronCargarLas(Object error) {
    return 'Could not load the tracks: $error';
  }

  @override
  String cargadaPor(Object persona) {
    return 'Added by $persona';
  }

  @override
  String get tonoTempoYVolumen => 'Pitch, tempo and volume';

  @override
  String get repetir => 'Repeat';

  @override
  String get todaviaNoHaySecuenciasCargadas =>
      'No tracks have been added for today yet.';

  @override
  String get todaviaNoHaySecuenciasCargadas2 =>
      'No tracks have been added for today yet.\nTap + to pick them from \"My tracks\".';

  @override
  String get cargarSecuenciasDeHoy => 'Add today’s tracks';

  @override
  String get nuevaFrase => 'New phrase';

  @override
  String get textoDeLaFrase => 'Phrase text';

  @override
  String get agregar => 'Add';

  @override
  String get editarFrase => 'Edit phrase';

  @override
  String get misFrases2 => 'My phrases';

  @override
  String get necesitasIniciarSesionParaEditar =>
      'You need to sign in to edit your phrases.';

  @override
  String get todaviaNoTenesFrasesPropias =>
      'You don’t have any phrases of your own yet.';

  @override
  String get cargarFrasesPorDefecto => 'Load default phrases';

  @override
  String get funcionPro => 'Pro feature';

  @override
  String get subirTusPropiasPartiturasCifrados =>
      'Uploading your own scores/chord charts as PDF is part of Sound Check Pro. Activate your Pro account to use this feature.';

  @override
  String get entendido => 'Got it';

  @override
  String errorAlSubir(Object error) {
    return 'Upload error: $error';
  }

  @override
  String get nuevaCancion => 'New song';

  @override
  String get editarCancion => 'Edit song';

  @override
  String get titulo2 => 'Title';

  @override
  String get tonalidadOpcional => 'Key (optional)';

  @override
  String get cifradoEnTextoOpcionalPara =>
      'Chord chart as text (optional, for transposing)';

  @override
  String get pegaLosAcordesAcaEj =>
      'Paste the chords here. E.g. [C]Amazing [G]grace...';

  @override
  String get regenerarCifrados => 'Rebuild chord charts';

  @override
  String get seVaAVolverA =>
      'Every PDF in your library will be read again to rebuild the chord chart with the chords placed as in the original PDF.\n\nThis replaces the chord chart text saved in each song (including anything you edited by hand). Songs whose PDF has no selectable text are left untouched.';

  @override
  String get regenerar => 'Rebuild';

  @override
  String get preparando => 'Preparing...';

  @override
  String procesandoDe(Object hechas, Object total) {
    return 'Processing $hechas of $total...';
  }

  @override
  String actualizadas(Object cantidad) {
    return '$cantidad updated';
  }

  @override
  String sinTextoEnElPdf(Object cantidad) {
    return '$cantidad with no text in the PDF';
  }

  @override
  String conError(Object cantidad) {
    return '$cantidad with errors';
  }

  @override
  String cifrados(Object detalle) {
    return 'Chord charts: $detalle.';
  }

  @override
  String get eliminarCancion => 'Delete song?';

  @override
  String get seBorraDeTuBiblioteca =>
      'It is removed from your library. If it is in the setlist of a room, it will stop opening.';

  @override
  String get eliminar => 'Delete';

  @override
  String get miRepertorio2 => 'My repertoire';

  @override
  String get regenerarCifradosDesdeLosPdf =>
      'Rebuild chord charts from the PDFs';

  @override
  String get necesitasIniciarSesionParaTener2 =>
      'You need to sign in to have a library.';

  @override
  String get subirTusPropiasPartiturasEs =>
      'Uploading your own scores is a Pro feature.';

  @override
  String get masInfo => 'More info';

  @override
  String get todaviaNoSubisteNingunaCancion =>
      'You haven’t uploaded any songs yet.';

  @override
  String tonalidad2(Object tonalidad) {
    return 'Key: $tonalidad';
  }

  @override
  String get subirTusPropiasSecuenciasEs =>
      'Uploading your own tracks is part of Sound Check Pro. Activate your Pro account to use this feature.';

  @override
  String get archivoDemasiadoGrande => 'File too large';

  @override
  String get archivosDemasiadoGrandes => 'Files too large';

  @override
  String elMaximoPorArchivoEs(Object lista, Object limite) {
    return '$lista\n\nThe maximum per file is $limite. Convert it to MP3 (at 192 kbps a whole song takes about 6-9 MB) and upload it again, or upload it from the web version, which converts it automatically.';
  }

  @override
  String convirtiendoAMp3(Object contador) {
    return 'Converting to MP3$contador';
  }

  @override
  String convirtiendoAMp32(Object porcentaje, Object contador) {
    return 'Converting to MP3 $porcentaje%$contador';
  }

  @override
  String subiendo(Object contador) {
    return 'Uploading$contador';
  }

  @override
  String get secuenciasSubidas => 'Tracks uploaded';

  @override
  String get algunasSecuenciasNoSeSubieron => 'Some tracks were not uploaded';

  @override
  String seConvirtieronAMp3Porque(Object limite, Object lista) {
    return 'These were converted to MP3 so they stay under $limite and 192 kbps:\n$lista';
  }

  @override
  String noSePudieronSubir(Object lista) {
    return 'Could not upload:\n$lista';
  }

  @override
  String get renombrarSecuencia => 'Rename track';

  @override
  String get eliminarSecuencia => 'Delete track';

  @override
  String eliminarDeTuBiblioteca(Object titulo) {
    return 'Delete \"$titulo\" from your library?';
  }

  @override
  String get misSecuencias2 => 'My tracks';

  @override
  String get necesitasIniciarSesionParaTener3 =>
      'You need to sign in to have tracks.';

  @override
  String errorAlCargar(Object error) {
    return 'Error loading: $error';
  }

  @override
  String get todaviaNoSubisteSecuenciasToca =>
      'You haven’t uploaded any tracks yet.\nTap the button below to upload your audio tracks (MP3, WAV, M4A...).';

  @override
  String get subirSecuencias => 'Upload tracks';

  @override
  String get restablecerTonoOriginal => 'Reset to original pitch';

  @override
  String get sincronizadoConTodaLaSala =>
      'Synced with the whole room (tap to unsync)';

  @override
  String get desincronizadoCambiosSoloLocalesToca =>
      'Not synced — changes are local only (tap to sync again)';

  @override
  String noSePudoCargarEl(Object error) {
    return 'Could not load the PDF.\n$error';
  }

  @override
  String errorAlIngresarAlPanel(Object error) {
    return 'Error entering the panel: $error';
  }

  @override
  String get accesoSonidista2 => 'Sound engineer access';

  @override
  String get pinDeSalaOCrear => 'Room PIN or Create room';

  @override
  String get accederAlPanel => 'ENTER THE PANEL';

  @override
  String tuRespuesta(Object respuesta) {
    return 'Your reply: $respuesta';
  }

  @override
  String get responderPrivado => 'Reply privately';

  @override
  String responderA(Object musico) {
    return 'Reply to $musico';
  }

  @override
  String pedido(Object pedido) {
    return 'Request: \"$pedido\"';
  }

  @override
  String get escribirRespuestaPrivada => 'Write a private reply...';

  @override
  String get enviar => 'Send';

  @override
  String consola2(Object codigoSala) {
    return 'Console: $codigoSala';
  }

  @override
  String get borrarTodo => 'Delete everything?';

  @override
  String get no => 'No';

  @override
  String get si => 'Yes';

  @override
  String get agrupadoPorRolActivado => 'Grouped by role: enabled';

  @override
  String get verAgrupadoPorRol => 'View grouped by role';

  @override
  String errorDeConexion(Object error) {
    return 'Connection error: $error';
  }

  @override
  String get esperandoPedidos => 'Waiting for requests...';

  @override
  String get todaviaNoAtendisteNingunPedido =>
      'You haven’t handled any request yet';

  @override
  String get nombreApp => 'Sound Check Pro';

  @override
  String get rolMusico => 'Musician';

  @override
  String get rolCantante => 'Singer';

  @override
  String get rolSonidista => 'Sound engineer';

  @override
  String get rolOtro => 'Other';

  @override
  String rolesYUltimo(String lista, String ultimo) {
    return '$lista and $ultimo';
  }

  @override
  String get paletaEscenarioNombre => 'Stage';

  @override
  String get paletaEscenarioTag => 'Cyan and violet neon';

  @override
  String get paletaConsolaNombre => 'Console';

  @override
  String get paletaConsolaTag => 'Violet, refined';

  @override
  String get paletaPlacaNombre => 'Plate';

  @override
  String get paletaPlacaTag => 'Graphite + VU amber';

  @override
  String get paletaWashNombre => 'Wash';

  @override
  String get paletaWashTag => 'Stage-light teal';

  @override
  String get paletaLuzDeTrabajoNombre => 'Work light';

  @override
  String get paletaLuzDeTrabajoTag => 'Maximum contrast';

  @override
  String get paletaCamarinNombre => 'Dressing room';

  @override
  String get paletaCamarinTag => 'Soft pastel pink';

  @override
  String get pestanaPedidos => 'Requests';

  @override
  String get pestanaHistorial => 'History';

  @override
  String get pestanaSetlist => 'Setlist';

  @override
  String get pestanaSecuencias => 'Tracks';

  @override
  String get fraseVolumenRetorno => 'Monitor volume';

  @override
  String get fraseVolumenAl2 => 'Volume to 2';

  @override
  String get fraseVolumenAl3 => 'Volume to 3';

  @override
  String get fraseVolumenAl4 => 'Volume to 4';

  @override
  String get fraseVolumenGuitarra => 'Guitar volume';

  @override
  String get fraseVolumenTeclado => 'Keys volume';

  @override
  String get fraseVolumenTalkback => 'Talkback volume';

  @override
  String get fraseVolumenPista => 'Backing track volume';

  @override
  String get fraseVolumenClick => 'Click volume';

  @override
  String get fraseVolumenCoordinador => 'Coordinator volume';

  @override
  String get fraseVolumenGeneral => 'Master volume';

  @override
  String get fraseListo => 'Done';

  @override
  String get tonoOriginal => 'Original';

  @override
  String semitonosConSigno(String signo, int cantidad) {
    String _temp0 = intl.Intl.pluralLogic(
      cantidad,
      locale: localeName,
      other: '$signo$cantidad semitones',
      one: '$signo$cantidad semitone',
    );
    return '$_temp0';
  }

  @override
  String ajusteTono(String valor) {
    return 'Pitch $valor';
  }

  @override
  String ajusteTempo(int valor) {
    return 'Tempo $valor%';
  }

  @override
  String ajusteVolumen(int valor) {
    return 'Vol $valor%';
  }

  @override
  String secuenciasParaHoy(int cantidad) {
    String _temp0 = intl.Intl.pluralLogic(
      cantidad,
      locale: localeName,
      other: '$cantidad tracks for today',
      one: '1 track for today',
    );
    return '$_temp0';
  }

  @override
  String get idioma => 'Language';

  @override
  String get idiomaDescripcion =>
      'Choose the app language. It is saved on this device.';

  @override
  String get escribiTuRol => 'Enter your role.';

  @override
  String get configuracion => 'Settings';

  @override
  String get colores => 'Colors';

  @override
  String get escribiTuNombre => 'Enter your name.';

  @override
  String get escribiElPin => 'Enter the room PIN.';

  @override
  String get pinDe8Caracteres => 'The code has 8 characters.';

  @override
  String get errorSinConexion =>
      'No connection. Check your internet and try again.';

  @override
  String get errorSinPermiso => 'You don’t have permission to do this.';

  @override
  String get errorGenerico => 'Something went wrong. Please try again.';

  @override
  String get reintentar => 'Retry';

  @override
  String get deshacer => 'Undo';

  @override
  String get pedidoEliminado => 'Request deleted';

  @override
  String get marcarAtendido => 'Mark as handled';

  @override
  String get salirDeLaSala => 'Leave the room';

  @override
  String get salirDeLaSalaPregunta => 'Leave the room?';

  @override
  String get salirDeLaSalaDetalle => 'To come back you’ll need the room code.';

  @override
  String get salir => 'Leave';

  @override
  String get fraseMasVolumen => 'More volume';

  @override
  String get fraseMenosVolumen => 'Less volume';

  @override
  String get borrarBusqueda => 'Clear search';

  @override
  String get borrarTodosLosPedidos => 'Delete all requests';

  @override
  String get entrarComoSonidistaPregunta => 'Enter as sound engineer?';

  @override
  String get entrarComoSonidistaDetalle =>
      'Your role mentions sound. You can enter the sound engineer panel or the requests screen.';

  @override
  String get panelDelSonidista => 'Sound engineer panel';

  @override
  String get pantallaDePedidos => 'Requests screen';

  @override
  String get pedidoYaNoExiste => 'That request no longer exists.';

  @override
  String get noHayAcordesParaTransponer => 'No chords found to transpose.';

  @override
  String ajustadoPor(String persona) {
    return 'Adjusted by $persona';
  }

  @override
  String get sinConexionAviso =>
      'No connection. Requests will be sent when the network is back.';

  @override
  String get pedidoPendienteSinConexion =>
      'No connection: the request will be sent when the network is back. Don’t close the app.';

  @override
  String get noSePudoEnviarPedido => 'The request could not be sent.';

  @override
  String versionApp(String version) {
    return 'Version $version';
  }

  @override
  String get compartirEnlaceSala => 'Share room link';

  @override
  String enlaceSalaTexto(String enlace) {
    return 'Join my room in Sound Check Pro: $enlace';
  }

  @override
  String get salaQuitadaDelHistorial => 'Room removed from history';

  @override
  String get eliminarCuenta => 'Delete my account';

  @override
  String get eliminarCuentaExplicacion =>
      'Your account, profile, phrases, repertoire and sequences (including the files you uploaded) and your room history will be permanently deleted. This cannot be undone. Requests and rooms shared with other people are not deleted.';

  @override
  String get eliminarCuentaContrasena => 'Current password (to confirm)';

  @override
  String get eliminarDefinitivamente => 'Delete permanently';

  @override
  String get eliminarCuentaPregunta => 'Delete your account forever?';

  @override
  String get eliminandoCuenta => 'Deleting your account…';

  @override
  String get cuentaEliminada => 'Your account and data were deleted';

  @override
  String get noSePudoEliminarCuenta =>
      'The account could not be deleted. Check your connection and try again.';

  @override
  String get alertas => 'Request alerts';

  @override
  String get alertasExplicacion =>
      'How the console alerts you when a request arrives. Urgent ones sound twice, vibrate harder and flash red.';

  @override
  String get alertaSonido => 'Sound';

  @override
  String get alertaVolumen => 'Alert volume';

  @override
  String get alertaVibracion => 'Vibration';

  @override
  String get alertaDestello => 'Red flash on urgent';

  @override
  String get probarAlerta => 'Test alert';

  @override
  String get probarAlertaUrgente => 'Test urgent alert';

  @override
  String get respuestasRapidas => 'Quick replies';

  @override
  String get respRapidaYaEsta => 'Done';

  @override
  String get respRapidaUnMomento => 'One moment';

  @override
  String get respRapidaLoVeo => 'On it';

  @override
  String get respRapidaNoPuedoAhora => 'Can’t right now';

  @override
  String get respRapidaRevisaCable => 'Check your cable';

  @override
  String get pedidoEnviado => 'Sent';

  @override
  String get pedidoVisto => 'Seen by the sound engineer';

  @override
  String get pedidoAtendido => 'Done';

  @override
  String get masOpciones => 'More options';

  @override
  String get modoShow => 'Show mode (lock screen)';

  @override
  String get modoShowDesbloquear => 'Press and hold the lock to unlock';

  @override
  String get alertas2 => 'Alerts';

  @override
  String listosSinConexion(int listos, int total) {
    return 'Offline: $listos of $total songs ready';
  }

  @override
  String get aceptarYSubir => 'Accept and upload';

  @override
  String get omitirEste => 'Skip this one';

  @override
  String get cancelarTodos => 'Cancel all';

  @override
  String get subiendoArchivo => 'Uploading…';

  @override
  String progresoCola(int actual, int total) {
    return '$actual of $total';
  }

  @override
  String resumenSubidos(int cantidad) {
    String _temp0 = intl.Intl.pluralLogic(
      cantidad,
      locale: localeName,
      other: '$cantidad uploaded',
      one: '1 uploaded',
    );
    return '$_temp0';
  }

  @override
  String resumenOmitidos(int cantidad) {
    String _temp0 = intl.Intl.pluralLogic(
      cantidad,
      locale: localeName,
      other: '$cantidad skipped',
      one: '1 skipped',
    );
    return '$_temp0';
  }

  @override
  String resumenSinProcesar(int cantidad) {
    String _temp0 = intl.Intl.pluralLogic(
      cantidad,
      locale: localeName,
      other: '$cantidad not processed',
      one: '1 not processed',
    );
    return '$_temp0';
  }

  @override
  String cantidadCanciones(int cantidad) {
    String _temp0 = intl.Intl.pluralLogic(
      cantidad,
      locale: localeName,
      other: '$cantidad songs',
      one: '1 song',
    );
    return '$_temp0';
  }

  @override
  String noSeEncontraronCanciones(String busqueda) {
    return 'No songs found for “$busqueda”';
  }

  @override
  String get volverAlVisor => 'Back to the song';

  @override
  String archivoPesaMasDelMaximo(Object tamano, Object maximo) {
    return 'The file is $tamano and the maximum is $maximo. Try a lighter version.';
  }

  @override
  String espacioInsuficiente(Object usado, Object cuota) {
    return 'Not enough space: you are using $usado of $cuota. Delete songs or sequences to free up room.';
  }

  @override
  String get compartirSalaTitulo => 'Share room';

  @override
  String get compartirSalaAyuda =>
      'Scan the code with your phone camera to join, or share the link.';

  @override
  String corregirAcordes(int cantidad, String ejemplos) {
    String _temp0 = intl.Intl.pluralLogic(
      cantidad,
      locale: localeName,
      other: 'Fix $cantidad misspelled chords',
      one: 'Fix 1 misspelled chord',
    );
    return '$_temp0 ($ejemplos)';
  }

  @override
  String get exportarChordPro => 'Export repertoire (ChordPro)';

  @override
  String get exportarCopia => 'Save backup copy';

  @override
  String get importarTexto => 'Import songs from text';

  @override
  String get nadaParaExportar => 'There are no songs with chords to export';

  @override
  String get importarSinCanciones => 'No songs were found in the files';

  @override
  String importarArchivoMal(String archivo) {
    return 'Could not read $archivo';
  }

  @override
  String get guiaTitulo => 'How Sound Check Pro works';

  @override
  String get guiaPaso1 =>
      'Create a room or join with the 8-character code (or by scanning the QR). Musicians and the sound engineer stay connected live.';

  @override
  String get guiaPaso2 =>
      'Send one-tap requests to the sound engineer (\"more guitar\", \"monitor volume\") and see when they are seen and handled.';

  @override
  String get guiaPaso3 =>
      'Upload your lyric and chord PDFs to your repertoire, build the room setlist and, with Pro, transpose the key for the whole band.';

  @override
  String get comoFunciona => 'How it works';

  @override
  String get vacioRepertorioTitulo => 'Your repertoire is empty';

  @override
  String get vacioRepertorioAyuda =>
      'Upload your lyric and chord PDFs, or import songs from a text file using the menu above.';

  @override
  String get subirUnPdf => 'Upload a PDF';

  @override
  String get vacioSetlistTitulo => 'There are no songs in the list yet';

  @override
  String get vacioSetlistAyuda =>
      'Tap + to add songs from your repertoire or the room libraries.';

  @override
  String get vacioSalasTitulo => 'You have not joined any room yet';

  @override
  String get vacioSalasAyuda =>
      'When you join a room it will show up here so you can get back quickly.';

  @override
  String get instalarApp => 'Install on your phone';

  @override
  String get instalarAppTitulo => 'Install the app';

  @override
  String get instalarIphone =>
      'iPhone: open this page in Safari, tap Share and choose \"Add to Home Screen\".';

  @override
  String get instalarAndroid =>
      'Android: in Chrome tap the ⋮ menu and choose \"Install app\" or \"Add to Home screen\".';

  @override
  String get autoDesplazamiento => 'Auto-scroll';

  @override
  String get velocidadLenta => 'Slow';

  @override
  String get velocidadNormal => 'Normal';

  @override
  String get velocidadRapida => 'Fast';

  @override
  String comprimiendoAudio(Object contador) {
    return 'Compressing audio$contador';
  }

  @override
  String comprimiendoAudio2(Object porcentaje, Object contador) {
    return 'Compressing audio $porcentaje%$contador';
  }

  @override
  String seComprimieronAudios(Object lista) {
    return 'Compressed to save space (AAC, up to 128 kbps):\n$lista';
  }

  @override
  String get audioNoSoportado =>
      'This audio could not be read. Try an MP3 or a 16-bit WAV.';

  @override
  String audioMuyLargo(Object limite) {
    return 'This audio is too long to fit in $limite. Try a shorter one or split it into parts.';
  }

  @override
  String archivoCompartidoIlegible(Object nombre) {
    return '\"$nombre\" could not be read or is larger than 12 MB.';
  }

  @override
  String get soloAppPaga => 'Paid app only';

  @override
  String get planPro => 'Pro plan';

  @override
  String get planProSubtitulo => 'More tools for your band';

  @override
  String get planProRepertorio =>
      'My repertoire with no limit: the free version allows up to 4 PDFs.';

  @override
  String get planProSecuencias =>
      'My tracks with no limit: the free version allows up to 3 audio tracks.';

  @override
  String get planProTono =>
      'Raise and lower the key of chord sheets and tracks; everyone in the room sees and hears it.';

  @override
  String get planProPrecio => 'Price: coming soon';

  @override
  String get planProTuPlanPro => 'Your plan: Pro';

  @override
  String get planProTuPlanGratis => 'Your plan: free';

  @override
  String get planProSiempreGratis =>
      'Always free: create and join rooms, send and receive requests, the setlist and your phrases.';

  @override
  String get accesosInicioTitulo => 'Home screen';

  @override
  String get accesosInicioMostrar =>
      'Show My phrases, My repertoire and My tracks on the home screen';

  @override
  String get accesosInicioAyuda =>
      'If you turn it off, you will still find them in the menu at the top right.';

  @override
  String get accesosInicioSoloPro => 'Available with the Pro version.';

  @override
  String get proGratisTitulo => 'Free Pro';

  @override
  String get proGratisAyuda =>
      'People with these emails get Pro for free. They must sign in to the app with that same (verified) email.';

  @override
  String get proGratisMail => 'Email';

  @override
  String get proGratisNota => 'Note (optional)';

  @override
  String get proGratisMailInvalido => 'That email does not look valid.';

  @override
  String get proGratisAgregado => 'Added.';

  @override
  String get proGratisQuitado => 'Removed.';

  @override
  String get proGratisQuitarTitulo => 'Remove free Pro from this email?';

  @override
  String get proGratisVacio => 'You have not added anyone yet.';

  @override
  String get planProEspacio => 'More space for your files: 2 GB per account.';

  @override
  String limiteGratisPdfs(int n) {
    return 'The free version lets you keep up to $n PDFs. With Pro, no limit.';
  }

  @override
  String limiteGratisSecuencias(int n) {
    return 'The free version lets you keep up to $n tracks. With Pro, no limit.';
  }

  @override
  String limiteGratisSubidos(int n) {
    return 'Because of the free version limit, only the first $n are uploaded.';
  }

  @override
  String get fueraDelCupoGratis =>
      'Outside the free version allowance. It stays saved and comes back with Pro.';

  @override
  String get tonoSoloPro => 'Changing the key is a Pro feature.';

  @override
  String misSalasLimiteGratis(int n) {
    return 'The free version keeps your last $n rooms. With Pro, all of them.';
  }

  @override
  String get planProSalas =>
      'My rooms without limit: the free version keeps the last 2.';

  @override
  String get salaYaNoExiste =>
      'That room no longer exists: it was deleted after a long time without activity.';
}
