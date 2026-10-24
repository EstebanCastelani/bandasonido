// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hindi (`hi`).
class AppLocalizationsHi extends AppLocalizations {
  AppLocalizationsHi([String locale = 'hi']) : super(locale);

  @override
  String get tuRolPodesMarcarMas => 'आपकी भूमिका (एक से अधिक चुन सकते हैं)';

  @override
  String get inicioDeSesionConGoogle => 'Google से लॉगिन रद्द किया गया।';

  @override
  String get elEmailNoEsValido => 'ईमेल मान्य नहीं है।';

  @override
  String get estaCuentaFueDeshabilitada => 'यह खाता अक्षम कर दिया गया है।';

  @override
  String get noExisteUnaCuentaCon => 'इस ईमेल से कोई खाता मौजूद नहीं है।';

  @override
  String get emailOContrasenaIncorrectos => 'ईमेल या पासवर्ड गलत है।';

  @override
  String get yaExisteUnaCuentaCon => 'इस ईमेल से पहले से एक खाता मौजूद है।';

  @override
  String get laContrasenaDebeTenerAl =>
      'पासवर्ड कम से कम 6 अक्षरों का होना चाहिए।';

  @override
  String get errorDeAutenticacion => 'प्रमाणीकरण में त्रुटि।';

  @override
  String get pausar => 'रोकें';

  @override
  String get reproducir => 'चलाएँ';

  @override
  String noSePudoReproducir(Object error) {
    return 'चलाया नहीं जा सका: $error';
  }

  @override
  String get bajandoElVolumen => 'आवाज़ कम हो रही है...';

  @override
  String fadeOutS(Object segundos) {
    return 'फ़ेड आउट ($segundos से.)';
  }

  @override
  String get detener => 'बंद करें';

  @override
  String get modoClaroOscuroParaEl =>
      'लाइट/डार्क मोड (ऐप के बाकी हिस्से के लिए)';

  @override
  String get colorDeLaApp => 'ऐप का रंग';

  @override
  String get comunicacionEnVivoEntreMusicos =>
      'संगीतकारों और साउंड इंजीनियरों के बीच\nलाइव संवाद';

  @override
  String get iniciarSesion => 'लॉग इन करें';

  @override
  String get crearCuenta => 'खाता बनाएँ';

  @override
  String get entrarComoInvitado => 'अतिथि के रूप में प्रवेश करें';

  @override
  String get tiempoReal => 'रियल टाइम';

  @override
  String get sincronizacionInstantanea => 'तुरंत\nसिंक';

  @override
  String get urgente => 'ज़रूरी';

  @override
  String get alertasVisualesYSonoras => 'दृश्य और\nध्वनि अलर्ट';

  @override
  String get multiSala => 'एकाधिक रूम';

  @override
  String get manejaVariasBandasYShows => 'कई बैंड और\nशो संभालें';

  @override
  String get setlistEnVivo => 'लाइव सेटलिस्ट';

  @override
  String get listaDeTemasCompartida => 'साझा\nगानों की सूची';

  @override
  String get completaEmailYContrasena => 'ईमेल और पासवर्ड भरें।';

  @override
  String get completaTuPerfil => 'अपनी प्रोफ़ाइल पूरी करें';

  @override
  String get tuNombre => 'आपका नाम';

  @override
  String get requerido => 'आवश्यक';

  @override
  String get tuRolEjSonidistaGuitarrista =>
      'आपकी भूमिका (जैसे: साउंड इंजीनियर, गिटारवादक)';

  @override
  String get guardar => 'सहेजें';

  @override
  String get recuperarContrasena => 'पासवर्ड पुनर्प्राप्त करें';

  @override
  String get tuEmail => 'आपका ईमेल';

  @override
  String get cancelar => 'रद्द करें';

  @override
  String get enviarEmail => 'ईमेल भेजें';

  @override
  String get teEnviamosUnEmailPara =>
      'हमने आपको पासवर्ड रीसेट करने के लिए एक ईमेल भेजा है।';

  @override
  String get tuRolEjSonidistaGuitarrista2 =>
      'आपकी भूमिका (जैसे: साउंड इंजीनियर, गिटारवादक, बैकअप गायक)';

  @override
  String get email => 'ईमेल';

  @override
  String get emailInvalido => 'अमान्य ईमेल';

  @override
  String get contrasena => 'पासवर्ड';

  @override
  String get minimo6Caracteres => 'कम से कम 6 अक्षर';

  @override
  String get olvidasteTuContrasena => 'पासवर्ड भूल गए?';

  @override
  String get registrarme => 'रजिस्टर करें';

  @override
  String get iniciarSesion2 => 'लॉग इन करें';

  @override
  String get yaTenesCuentaIniciarSesion => 'पहले से खाता है? लॉग इन करें';

  @override
  String get noTenesCuentaRegistrarme => 'खाता नहीं है? रजिस्टर करें';

  @override
  String get continuarConGoogle => 'Google से जारी रखें';

  @override
  String get continuarSinCuenta => 'बिना खाते के जारी रखें';

  @override
  String get cerrarSesionDeCuenta => 'खाते से लॉग आउट करें';

  @override
  String sesion(Object usuario) {
    return 'सत्र: $usuario';
  }

  @override
  String get crearNuevaSala => 'नया रूम बनाएँ';

  @override
  String get unirmeASala => 'रूम में शामिल हों';

  @override
  String get misSalas => 'मेरे रूम';

  @override
  String get misFrases => 'मेरे वाक्यांश';

  @override
  String get miRepertorio => 'मेरा संग्रह';

  @override
  String get misSecuencias => 'मेरे सीक्वेंस';

  @override
  String get accesoSonidista => 'साउंड इंजीनियर प्रवेश';

  @override
  String get elegiLaIdentidadVisualDe =>
      'ऐप की दृश्य शैली चुनें। यह इस डिवाइस पर सहेजी जाती है।';

  @override
  String get marcaAlMenosUnRol => 'कम से कम एक भूमिका चुनें।';

  @override
  String errorAlIngresar(Object error) {
    return 'लॉग इन में त्रुटि: $error';
  }

  @override
  String get configurarSala => 'रूम सेट करें';

  @override
  String get tuPinDeSala => 'आपके रूम का PIN';

  @override
  String get pinCopiado => 'PIN कॉपी हो गया';

  @override
  String get tuNombre2 => 'आपका नाम';

  @override
  String get empezar => 'शुरू करें';

  @override
  String get unirseASala => 'रूम में शामिल हों';

  @override
  String get codigoDeSala8Caracteres => 'रूम कोड (8 अक्षर)';

  @override
  String get unirme => 'शामिल हों';

  @override
  String get nombreParaEstaSala => 'इस रूम का नाम';

  @override
  String get ejBandaXEnsayoJueves => 'जैसे: बैंड X - गुरुवार रिहर्सल';

  @override
  String get misSalas2 => 'मेरे रूम';

  @override
  String get necesitasIniciarSesionParaTener =>
      'रूम का इतिहास रखने के लिए लॉग इन करना ज़रूरी है।';

  @override
  String get guardarUnHistorialDeVarias =>
      'कई रूम/बैंड का इतिहास सहेजकर एक टैप में वापस जाना Pro सुविधा है।';

  @override
  String get todaviaNoEntrasteANinguna =>
      'आप इस खाते से अभी तक किसी रूम में शामिल नहीं हुए हैं।';

  @override
  String get renombrar => 'नाम बदलें';

  @override
  String get quitarDelHistorial => 'इतिहास से हटाएँ';

  @override
  String get queQueresVerEnLa => 'आप रूम में क्या देखना चाहते हैं?';

  @override
  String get seGuardaEnEsteDispositivo =>
      'इस डिवाइस पर सहेजा जाता है। कम से कम एक बची रहनी चाहिए।';

  @override
  String urgenteEnviado(Object texto) {
    return 'ज़रूरी अनुरोध भेजा गया!: $texto';
  }

  @override
  String enviado(Object texto) {
    return 'भेजा गया: $texto';
  }

  @override
  String get cerrarSesion => 'लॉग आउट करें';

  @override
  String get codigoDeSalaCopiado => 'रूम कोड कॉपी हो गया';

  @override
  String sala(Object codigoSala) {
    return 'रूम: $codigoSala';
  }

  @override
  String get pantallaSiempreEncendidaActivado => 'स्क्रीन हमेशा चालू: चालू';

  @override
  String get pantallaSiempreEncendidaDesactivado => 'स्क्रीन हमेशा चालू: बंद';

  @override
  String get elegirQueVerEnLa => 'चुनें कि रूम में क्या दिखे';

  @override
  String get escribirPedidoPersonalizado => 'अपना अनुरोध लिखें...';

  @override
  String get pedidoUrgenteActivado => 'ज़रूरी अनुरोध: चालू';

  @override
  String get marcarElProximoPedidoComo => 'अगले अनुरोध को ज़रूरी चिह्नित करें';

  @override
  String get misUltimosPedidos => 'मेरे हाल के अनुरोध';

  @override
  String error(Object error) {
    return 'त्रुटि: $error';
  }

  @override
  String get sinPedidosPropios => 'आपका कोई अनुरोध नहीं है';

  @override
  String eliminandoPedido(Object pedido) {
    return 'अनुरोध हटाया जा रहा है: \"$pedido\"';
  }

  @override
  String consola(Object respuesta) {
    return 'मिक्सर: $respuesta';
  }

  @override
  String get desdeMiBiblioteca => 'मेरी लाइब्रेरी से';

  @override
  String get buscarEnBibliotecasDeLa => 'रूम की लाइब्रेरी में खोजें';

  @override
  String get necesitasIniciarSesionParaUsar =>
      'अपनी लाइब्रेरी इस्तेमाल करने के लिए लॉग इन करें।';

  @override
  String get tuBibliotecaEstaVacia => 'आपकी लाइब्रेरी खाली है।';

  @override
  String get titulo => 'शीर्षक...';

  @override
  String get tonalidad => 'स्केल...';

  @override
  String get sinResultados => 'कोई परिणाम नहीं।';

  @override
  String get noSePudoBuscarIntenta =>
      'खोज नहीं हो सकी। कुछ देर बाद फिर कोशिश करें।';

  @override
  String get todaviaNoHayBibliotecasPara =>
      'इस रूम में खोजने के लिए अभी कोई लाइब्रेरी नहीं है।';

  @override
  String de(Object propietario) {
    return '$propietario की';
  }

  @override
  String get elSetlistEstaVacioNo =>
      'सेटलिस्ट खाली है, निर्यात करने के लिए कुछ नहीं है।';

  @override
  String setlistSala(Object codigoSala) {
    return 'सेटलिस्ट — रूम $codigoSala\n\n';
  }

  @override
  String get exportarSetlist => 'सेटलिस्ट निर्यात करें';

  @override
  String get copiadoAlPortapapeles => 'क्लिपबोर्ड पर कॉपी हो गया';

  @override
  String get copiar => 'कॉपी करें';

  @override
  String setlistSala2(Object codigoSala) {
    return 'सेटलिस्ट - रूम $codigoSala';
  }

  @override
  String get compartir => 'साझा करें';

  @override
  String get cerrar => 'बंद करें';

  @override
  String agregado(Object titulo) {
    return 'जोड़ा गया: $titulo';
  }

  @override
  String get todaviaNoHayTemasEn => 'सूची में अभी कोई गाना नहीं है।';

  @override
  String get cambiarEstadoDelTema => 'गाने की स्थिति बदलें';

  @override
  String get pendiente => 'प्रतीक्षित';

  @override
  String get pausadoCorteTecnico => 'रुका हुआ (तकनीकी रुकावट)';

  @override
  String get tocado => 'बज चुका';

  @override
  String get pausado => 'रुका हुआ';

  @override
  String get proximo => 'अगला';

  @override
  String subidoPor(Object persona) {
    return '$persona द्वारा अपलोड किया गया';
  }

  @override
  String get verCifradoTransponer => 'कॉर्ड देखें (स्केल बदलें)';

  @override
  String get exportarCompartirSetlist => 'सेटलिस्ट निर्यात / साझा करें';

  @override
  String get agregarCancion => 'गाना जोड़ें';

  @override
  String get necesitasIniciarSesionParaUsar2 =>
      'अपने सीक्वेंस इस्तेमाल करने के लिए लॉग इन करें।';

  @override
  String get noTenesSecuenciasTodaviaSubilas =>
      'आपके पास अभी कोई सीक्वेंस नहीं है।\nमुख्य मेनू में \"मेरे सीक्वेंस\" से अपलोड करें।';

  @override
  String get buscarSecuencia => 'सीक्वेंस खोजें...';

  @override
  String get yaEstaEnLaSala => 'पहले से रूम में है';

  @override
  String get elegiLasSecuenciasDeHoy => 'आज के सीक्वेंस चुनें';

  @override
  String cargarALaSala(Object cantidad) {
    return '$cantidad रूम में जोड़ें';
  }

  @override
  String noSePudieronCargar(Object error) {
    return 'जोड़ा नहीं जा सका: $error';
  }

  @override
  String get quitarDeLaSala => 'रूम से हटाएँ';

  @override
  String quitarDeLasSecuenciasDe(Object titulo) {
    return '\"$titulo\" को आज के सीक्वेंस से हटाएँ? यह अपलोड करने वाले की लाइब्रेरी में बना रहेगा।';
  }

  @override
  String get quitar => 'हटाएँ';

  @override
  String noSePudoGuardarEl(Object error) {
    return 'बदलाव सहेजा नहीं जा सका: $error';
  }

  @override
  String get seGuardaParaTodaLa =>
      'पूरे रूम के लिए सहेजा जाता है। स्केल, टेम्पो और आवाज़ अलग-अलग बदले जाते हैं।';

  @override
  String get tono => 'स्केल';

  @override
  String get bajarUnSemitono => 'एक सेमीटोन कम करें';

  @override
  String get subirUnSemitono => 'एक सेमीटोन बढ़ाएँ';

  @override
  String get elCambioDeTonoPor =>
      'स्केल बदलना फ़िलहाल केवल वेब संस्करण में काम करता है।';

  @override
  String get tempo => 'टेम्पो';

  @override
  String get masLento1 => 'धीमा (1%)';

  @override
  String get masRapido1 => 'तेज़ (1%)';

  @override
  String get volumen => 'आवाज़';

  @override
  String get bajar5 => '5% कम करें';

  @override
  String get subir5 => '5% बढ़ाएँ';

  @override
  String get restablecerComoSeSubio => 'रीसेट करें (अपलोड जैसा)';

  @override
  String noSePudieronCargarLas(Object error) {
    return 'सीक्वेंस लोड नहीं हो सके: $error';
  }

  @override
  String cargadaPor(Object persona) {
    return '$persona द्वारा जोड़ा गया';
  }

  @override
  String get tonoTempoYVolumen => 'स्केल, टेम्पो और आवाज़';

  @override
  String get repetir => 'दोहराएँ';

  @override
  String get todaviaNoHaySecuenciasCargadas =>
      'आज के लिए अभी कोई सीक्वेंस लोड नहीं है।';

  @override
  String get todaviaNoHaySecuenciasCargadas2 =>
      'आज के लिए अभी कोई सीक्वेंस लोड नहीं है।\n\"मेरे सीक्वेंस\" से चुनने के लिए + दबाएँ।';

  @override
  String get cargarSecuenciasDeHoy => 'आज के सीक्वेंस लोड करें';

  @override
  String get nuevaFrase => 'नया वाक्यांश';

  @override
  String get textoDeLaFrase => 'वाक्यांश का पाठ';

  @override
  String get agregar => 'जोड़ें';

  @override
  String get editarFrase => 'वाक्यांश संपादित करें';

  @override
  String get misFrases2 => 'मेरे वाक्यांश';

  @override
  String get necesitasIniciarSesionParaEditar =>
      'अपने वाक्यांश संपादित करने के लिए लॉग इन करें।';

  @override
  String get todaviaNoTenesFrasesPropias => 'आपके अपने वाक्यांश अभी नहीं हैं।';

  @override
  String get cargarFrasesPorDefecto => 'डिफ़ॉल्ट वाक्यांश लोड करें';

  @override
  String get funcionPro => 'Pro सुविधा';

  @override
  String get subirTusPropiasPartiturasCifrados =>
      'अपने PDF स्वरलिपि/कॉर्ड अपलोड करना Sound Check Pro का हिस्सा है। इस सुविधा के लिए अपना Pro खाता सक्रिय करें।';

  @override
  String get entendido => 'समझ गया';

  @override
  String errorAlSubir(Object error) {
    return 'अपलोड में त्रुटि: $error';
  }

  @override
  String get nuevaCancion => 'नया गाना';

  @override
  String get editarCancion => 'गाना संपादित करें';

  @override
  String get titulo2 => 'शीर्षक';

  @override
  String get tonalidadOpcional => 'स्केल (वैकल्पिक)';

  @override
  String get cifradoEnTextoOpcionalPara =>
      'पाठ रूप में कॉर्ड (वैकल्पिक, स्केल बदलने के लिए)';

  @override
  String get pegaLosAcordesAcaEj =>
      'कॉर्ड यहाँ चिपकाएँ। जैसे: [C]Amazing [G]grace...';

  @override
  String get regenerarCifrados => 'कॉर्ड फिर से बनाएँ';

  @override
  String get seVaAVolverA =>
      'आपकी लाइब्रेरी की हर PDF दोबारा पढ़ी जाएगी ताकि कॉर्ड वैसे ही जमाए जाएँ जैसे मूल PDF में हैं।\n\nइससे हर गाने का सहेजा हुआ पाठ-कॉर्ड बदल जाएगा (आपके हाथ से किए संपादन भी)। जिन गानों की PDF में चुनने योग्य पाठ नहीं है, वे नहीं बदलेंगे।';

  @override
  String get regenerar => 'फिर से बनाएँ';

  @override
  String get preparando => 'तैयारी हो रही है...';

  @override
  String procesandoDe(Object hechas, Object total) {
    return '$total में से $hechas संसाधित हो रहे हैं...';
  }

  @override
  String actualizadas(Object cantidad) {
    return '$cantidad अपडेट हुए';
  }

  @override
  String sinTextoEnElPdf(Object cantidad) {
    return '$cantidad में PDF में पाठ नहीं';
  }

  @override
  String conError(Object cantidad) {
    return '$cantidad में त्रुटि';
  }

  @override
  String cifrados(Object detalle) {
    return 'कॉर्ड: $detalle।';
  }

  @override
  String get eliminarCancion => 'गाना हटाएँ?';

  @override
  String get seBorraDeTuBiblioteca =>
      'यह आपकी लाइब्रेरी से हट जाएगा। अगर यह किसी रूम की सेटलिस्ट में है तो वहाँ खुलेगा नहीं।';

  @override
  String get eliminar => 'हटाएँ';

  @override
  String get miRepertorio2 => 'मेरा संग्रह';

  @override
  String get regenerarCifradosDesdeLosPdf => 'PDF से कॉर्ड फिर से बनाएँ';

  @override
  String get necesitasIniciarSesionParaTener2 =>
      'लाइब्रेरी रखने के लिए लॉग इन करें।';

  @override
  String get subirTusPropiasPartiturasEs =>
      'अपनी स्वरलिपि अपलोड करना Pro सुविधा है।';

  @override
  String get masInfo => 'अधिक जानकारी';

  @override
  String get todaviaNoSubisteNingunaCancion =>
      'आपने अभी तक कोई गाना अपलोड नहीं किया है।';

  @override
  String tonalidad2(Object tonalidad) {
    return 'स्केल: $tonalidad';
  }

  @override
  String get subirTusPropiasSecuenciasEs =>
      'अपने सीक्वेंस अपलोड करना Sound Check Pro का हिस्सा है। इस सुविधा के लिए अपना Pro खाता सक्रिय करें।';

  @override
  String get archivoDemasiadoGrande => 'फ़ाइल बहुत बड़ी है';

  @override
  String get archivosDemasiadoGrandes => 'फ़ाइलें बहुत बड़ी हैं';

  @override
  String elMaximoPorArchivoEs(Object lista, Object limite) {
    return '$lista\n\nप्रति फ़ाइल अधिकतम आकार $limite है। MP3 में बदलें (320 kbps पर पूरा गाना लगभग 10-15 MB का होता है) और फिर अपलोड करें, या वेब संस्करण से अपलोड करें, जो अपने आप बदल देता है।';
  }

  @override
  String convirtiendoAMp3(Object contador) {
    return 'MP3 में बदला जा रहा है$contador';
  }

  @override
  String convirtiendoAMp32(Object porcentaje, Object contador) {
    return 'MP3 में बदला जा रहा है $porcentaje%$contador';
  }

  @override
  String subiendo(Object contador) {
    return 'अपलोड हो रहा है$contador';
  }

  @override
  String get secuenciasSubidas => 'सीक्वेंस अपलोड हो गए';

  @override
  String get algunasSecuenciasNoSeSubieron => 'कुछ सीक्वेंस अपलोड नहीं हुए';

  @override
  String seConvirtieronAMp3Porque(Object limite, Object lista) {
    return 'अधिकतम $limite से बड़े होने के कारण MP3 में बदले गए:\n$lista';
  }

  @override
  String noSePudieronSubir(Object lista) {
    return 'अपलोड नहीं हो सके:\n$lista';
  }

  @override
  String get renombrarSecuencia => 'सीक्वेंस का नाम बदलें';

  @override
  String get eliminarSecuencia => 'सीक्वेंस हटाएँ';

  @override
  String eliminarDeTuBiblioteca(Object titulo) {
    return '\"$titulo\" को अपनी लाइब्रेरी से हटाएँ?';
  }

  @override
  String get misSecuencias2 => 'मेरे सीक्वेंस';

  @override
  String get necesitasIniciarSesionParaTener3 =>
      'सीक्वेंस रखने के लिए लॉग इन करें।';

  @override
  String errorAlCargar(Object error) {
    return 'लोड करने में त्रुटि: $error';
  }

  @override
  String get todaviaNoSubisteSecuenciasToca =>
      'आपने अभी कोई सीक्वेंस अपलोड नहीं किया है।\nअपने ऑडियो ट्रैक (MP3, WAV, M4A...) अपलोड करने के लिए नीचे का बटन दबाएँ।';

  @override
  String get subirSecuencias => 'सीक्वेंस अपलोड करें';

  @override
  String get restablecerTonoOriginal => 'मूल स्केल पर लौटें';

  @override
  String get sincronizadoConTodaLaSala =>
      'पूरे रूम से सिंक है (सिंक बंद करने के लिए दबाएँ)';

  @override
  String get desincronizadoCambiosSoloLocalesToca =>
      'सिंक बंद है — बदलाव केवल इस डिवाइस पर (फिर सिंक करने के लिए दबाएँ)';

  @override
  String noSePudoCargarEl(Object error) {
    return 'PDF लोड नहीं हो सकी।\n$error';
  }

  @override
  String errorAlIngresarAlPanel(Object error) {
    return 'पैनल में प्रवेश में त्रुटि: $error';
  }

  @override
  String get accesoSonidista2 => 'साउंड इंजीनियर प्रवेश';

  @override
  String get pinDeSalaOCrear => 'रूम PIN या रूम बनाएँ';

  @override
  String get accederAlPanel => 'पैनल में प्रवेश करें';

  @override
  String tuRespuesta(Object respuesta) {
    return 'आपका उत्तर: $respuesta';
  }

  @override
  String get responderPrivado => 'निजी तौर पर उत्तर दें';

  @override
  String responderA(Object musico) {
    return '$musico को उत्तर दें';
  }

  @override
  String pedido(Object pedido) {
    return 'अनुरोध: \"$pedido\"';
  }

  @override
  String get escribirRespuestaPrivada => 'निजी उत्तर लिखें...';

  @override
  String get enviar => 'भेजें';

  @override
  String consola2(Object codigoSala) {
    return 'मिक्सर: $codigoSala';
  }

  @override
  String get borrarTodo => 'सब मिटाएँ?';

  @override
  String get no => 'नहीं';

  @override
  String get si => 'हाँ';

  @override
  String get agrupadoPorRolActivado => 'भूमिका के अनुसार समूह: चालू';

  @override
  String get verAgrupadoPorRol => 'भूमिका के अनुसार समूह में देखें';

  @override
  String errorDeConexion(Object error) {
    return 'कनेक्शन त्रुटि: $error';
  }

  @override
  String get esperandoPedidos => 'अनुरोधों की प्रतीक्षा...';

  @override
  String get todaviaNoAtendisteNingunPedido =>
      'आपने अभी तक कोई अनुरोध पूरा नहीं किया';

  @override
  String get nombreApp => 'Sound Check Pro';

  @override
  String get rolMusico => 'संगीतकार';

  @override
  String get rolCantante => 'गायक';

  @override
  String get rolSonidista => 'साउंड इंजीनियर';

  @override
  String get rolOtro => 'अन्य';

  @override
  String rolesYUltimo(String lista, String ultimo) {
    return '$lista और $ultimo';
  }

  @override
  String get paletaEscenarioNombre => 'मंच';

  @override
  String get paletaEscenarioTag => 'सियान और बैंगनी नियॉन';

  @override
  String get paletaConsolaNombre => 'मिक्सर';

  @override
  String get paletaConsolaTag => 'बैंगनी, परिष्कृत';

  @override
  String get paletaPlacaNombre => 'पैनल';

  @override
  String get paletaPlacaTag => 'ग्रेफ़ाइट + VU एम्बर';

  @override
  String get paletaWashNombre => 'वॉश';

  @override
  String get paletaWashTag => 'मंच की रोशनी जैसा नीला-हरा';

  @override
  String get paletaLuzDeTrabajoNombre => 'वर्क लाइट';

  @override
  String get paletaLuzDeTrabajoTag => 'अधिकतम कंट्रास्ट';

  @override
  String get paletaCamarinNombre => 'ग्रीन रूम';

  @override
  String get paletaCamarinTag => 'पेस्टल गुलाबी, कोमल';

  @override
  String get pestanaPedidos => 'अनुरोध';

  @override
  String get pestanaHistorial => 'इतिहास';

  @override
  String get pestanaSetlist => 'सेटलिस्ट';

  @override
  String get pestanaSecuencias => 'सीक्वेंस';

  @override
  String get fraseVolumenRetorno => 'मॉनिटर की आवाज़';

  @override
  String get fraseVolumenAl2 => '2 पर आवाज़';

  @override
  String get fraseVolumenAl3 => '3 पर आवाज़';

  @override
  String get fraseVolumenAl4 => '4 पर आवाज़';

  @override
  String get fraseVolumenGuitarra => 'गिटार की आवाज़';

  @override
  String get fraseVolumenTeclado => 'कीबोर्ड की आवाज़';

  @override
  String get fraseVolumenTalkback => 'टॉकबैक की आवाज़';

  @override
  String get fraseVolumenPista => 'ट्रैक की आवाज़';

  @override
  String get fraseVolumenClick => 'क्लिक की आवाज़';

  @override
  String get fraseVolumenCoordinador => 'कोऑर्डिनेटर की आवाज़';

  @override
  String get fraseVolumenGeneral => 'कुल आवाज़';

  @override
  String get fraseListo => 'तैयार';

  @override
  String get tonoOriginal => 'मूल';

  @override
  String semitonosConSigno(String signo, int cantidad) {
    String _temp0 = intl.Intl.pluralLogic(
      cantidad,
      locale: localeName,
      other: '$signo$cantidad सेमीटोन',
      one: '$signo$cantidad सेमीटोन',
    );
    return '$_temp0';
  }

  @override
  String ajusteTono(String valor) {
    return 'स्केल $valor';
  }

  @override
  String ajusteTempo(int valor) {
    return 'टेम्पो $valor%';
  }

  @override
  String ajusteVolumen(int valor) {
    return 'आवाज़ $valor%';
  }

  @override
  String secuenciasParaHoy(int cantidad) {
    String _temp0 = intl.Intl.pluralLogic(
      cantidad,
      locale: localeName,
      other: 'आज के लिए $cantidad सीक्वेंस',
      one: 'आज के लिए 1 सीक्वेंस',
    );
    return '$_temp0';
  }

  @override
  String get idioma => 'भाषा';

  @override
  String get idiomaAutomatico => 'स्वचालित (डिवाइस की भाषा)';

  @override
  String get idiomaDescripcion =>
      'ऐप की भाषा चुनें। यह इस डिवाइस पर सहेजी जाती है।';
}
