// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get tuRolPodesMarcarMas => 'دورك (يمكنك اختيار أكثر من دور)';

  @override
  String get inicioDeSesionConGoogle => 'تم إلغاء تسجيل الدخول عبر Google.';

  @override
  String get elEmailNoEsValido => 'البريد الإلكتروني غير صالح.';

  @override
  String get estaCuentaFueDeshabilitada => 'تم تعطيل هذا الحساب.';

  @override
  String get noExisteUnaCuentaCon => 'لا يوجد حساب بهذا البريد الإلكتروني.';

  @override
  String get emailOContrasenaIncorrectos =>
      'البريد الإلكتروني أو كلمة المرور غير صحيحة.';

  @override
  String get yaExisteUnaCuentaCon => 'يوجد حساب بهذا البريد الإلكتروني بالفعل.';

  @override
  String get laContrasenaDebeTenerAl =>
      'يجب أن تتكوّن كلمة المرور من 6 أحرف على الأقل.';

  @override
  String get errorDeAutenticacion => 'خطأ في المصادقة.';

  @override
  String get pausar => 'إيقاف مؤقت';

  @override
  String get reproducir => 'تشغيل';

  @override
  String noSePudoReproducir(Object error) {
    return 'تعذّر التشغيل: $error';
  }

  @override
  String get bajandoElVolumen => 'جارٍ خفض الصوت...';

  @override
  String fadeOutS(Object segundos) {
    return 'تلاشي ($segundos ث)';
  }

  @override
  String get detener => 'إيقاف';

  @override
  String get modoClaroOscuroParaEl => 'الوضع الفاتح/الداكن (لبقية التطبيق)';

  @override
  String get colorDeLaApp => 'لون التطبيق';

  @override
  String get comunicacionEnVivoEntreMusicos =>
      'تواصل مباشر\nبين الموسيقيين ومهندسي الصوت';

  @override
  String get iniciarSesion => 'تسجيل الدخول';

  @override
  String get crearCuenta => 'إنشاء حساب';

  @override
  String get entrarComoInvitado => 'الدخول كضيف';

  @override
  String get tiempoReal => 'وقت فعلي';

  @override
  String get sincronizacionInstantanea => 'مزامنة\nفورية';

  @override
  String get urgente => 'عاجل';

  @override
  String get alertasVisualesYSonoras => 'تنبيهات مرئية\nوصوتية';

  @override
  String get multiSala => 'غرف متعددة';

  @override
  String get manejaVariasBandasYShows => 'أدِر عدة فرق\nوحفلات';

  @override
  String get setlistEnVivo => 'قائمة الأغاني المباشرة';

  @override
  String get listaDeTemasCompartida => 'قائمة أغانٍ\nمشتركة';

  @override
  String get completaEmailYContrasena => 'أدخل البريد الإلكتروني وكلمة المرور.';

  @override
  String get completaTuPerfil => 'أكمل ملفك الشخصي';

  @override
  String get tuNombre => 'اسمك';

  @override
  String get requerido => 'مطلوب';

  @override
  String get tuRolEjSonidistaGuitarrista => 'دورك (مثل: مهندس صوت، عازف جيتار)';

  @override
  String get guardar => 'حفظ';

  @override
  String get recuperarContrasena => 'استعادة كلمة المرور';

  @override
  String get tuEmail => 'بريدك الإلكتروني';

  @override
  String get cancelar => 'إلغاء';

  @override
  String get enviarEmail => 'إرسال البريد';

  @override
  String get teEnviamosUnEmailPara =>
      'أرسلنا إليك رسالة لإعادة تعيين كلمة المرور.';

  @override
  String get tuRolEjSonidistaGuitarrista2 =>
      'دورك (مثل: مهندس صوت، عازف جيتار، مغنٍّ مرافق)';

  @override
  String get email => 'البريد الإلكتروني';

  @override
  String get emailInvalido => 'بريد إلكتروني غير صالح';

  @override
  String get contrasena => 'كلمة المرور';

  @override
  String get minimo6Caracteres => '6 أحرف على الأقل';

  @override
  String get olvidasteTuContrasena => 'نسيت كلمة المرور؟';

  @override
  String get registrarme => 'إنشاء حساب';

  @override
  String get iniciarSesion2 => 'تسجيل الدخول';

  @override
  String get yaTenesCuentaIniciarSesion => 'لديك حساب؟ سجّل الدخول';

  @override
  String get noTenesCuentaRegistrarme => 'ليس لديك حساب؟ سجّل الآن';

  @override
  String get continuarConGoogle => 'المتابعة عبر Google';

  @override
  String get continuarSinCuenta => 'المتابعة بدون حساب';

  @override
  String get cerrarSesionDeCuenta => 'تسجيل الخروج من الحساب';

  @override
  String sesion(Object usuario) {
    return 'الجلسة: $usuario';
  }

  @override
  String get crearNuevaSala => 'إنشاء غرفة جديدة';

  @override
  String get unirmeASala => 'الانضمام إلى غرفة';

  @override
  String get misSalas => 'غرفي';

  @override
  String get misFrases => 'عباراتي';

  @override
  String get miRepertorio => 'ريبرتواري';

  @override
  String get misSecuencias => 'تسلسلاتي';

  @override
  String get accesoSonidista => 'دخول مهندس الصوت';

  @override
  String get elegiLaIdentidadVisualDe =>
      'اختر الهوية البصرية للتطبيق. تُحفظ على هذا الجهاز.';

  @override
  String get marcaAlMenosUnRol => 'اختر دورًا واحدًا على الأقل.';

  @override
  String errorAlIngresar(Object error) {
    return 'خطأ في تسجيل الدخول: $error';
  }

  @override
  String get configurarSala => 'إعداد الغرفة';

  @override
  String get tuPinDeSala => 'رمز PIN لغرفتك';

  @override
  String get pinCopiado => 'تم نسخ رمز PIN';

  @override
  String get tuNombre2 => 'اسمك';

  @override
  String get empezar => 'ابدأ';

  @override
  String get unirseASala => 'الانضمام إلى غرفة';

  @override
  String get codigoDeSala8Caracteres => 'رمز الغرفة (8 أحرف)';

  @override
  String get unirme => 'انضمام';

  @override
  String get nombreParaEstaSala => 'اسم هذه الغرفة';

  @override
  String get ejBandaXEnsayoJueves => 'مثال: فرقة X - بروفة الخميس';

  @override
  String get misSalas2 => 'غرفي';

  @override
  String get necesitasIniciarSesionParaTener =>
      'يجب تسجيل الدخول للاحتفاظ بسجل الغرف.';

  @override
  String get guardarUnHistorialDeVarias =>
      'حفظ سجل عدة غرف/فرق للعودة إليها بلمسة واحدة ميزة Pro.';

  @override
  String get todaviaNoEntrasteANinguna =>
      'لم تنضم إلى أي غرفة بهذا الحساب بعد.';

  @override
  String get renombrar => 'إعادة تسمية';

  @override
  String get quitarDelHistorial => 'إزالة من السجل';

  @override
  String get queQueresVerEnLa => 'ماذا تريد أن ترى في الغرفة؟';

  @override
  String get seGuardaEnEsteDispositivo =>
      'يُحفظ على هذا الجهاز. يجب أن يبقى خيار واحد على الأقل.';

  @override
  String urgenteEnviado(Object texto) {
    return 'تم إرسال طلب عاجل!: $texto';
  }

  @override
  String enviado(Object texto) {
    return 'تم الإرسال: $texto';
  }

  @override
  String get cerrarSesion => 'تسجيل الخروج';

  @override
  String get codigoDeSalaCopiado => 'تم نسخ رمز الغرفة';

  @override
  String sala(Object codigoSala) {
    return 'الغرفة: $codigoSala';
  }

  @override
  String get pantallaSiempreEncendidaActivado =>
      'الشاشة دائمًا قيد التشغيل: مفعّل';

  @override
  String get pantallaSiempreEncendidaDesactivado =>
      'الشاشة دائمًا قيد التشغيل: معطّل';

  @override
  String get elegirQueVerEnLa => 'اختر ما يظهر في الغرفة';

  @override
  String get escribirPedidoPersonalizado => 'اكتب طلبًا مخصصًا...';

  @override
  String get pedidoUrgenteActivado => 'طلب عاجل: مفعّل';

  @override
  String get marcarElProximoPedidoComo => 'تحديد الطلب التالي كعاجل';

  @override
  String get misUltimosPedidos => 'آخر طلباتي';

  @override
  String error(Object error) {
    return 'خطأ: $error';
  }

  @override
  String get sinPedidosPropios => 'لا توجد طلبات لك';

  @override
  String eliminandoPedido(Object pedido) {
    return 'جارٍ حذف الطلب: \"$pedido\"';
  }

  @override
  String consola(Object respuesta) {
    return 'الميكسر: $respuesta';
  }

  @override
  String get desdeMiBiblioteca => 'من مكتبتي';

  @override
  String get buscarEnBibliotecasDeLa => 'البحث في مكتبات الغرفة';

  @override
  String get necesitasIniciarSesionParaUsar =>
      'يجب تسجيل الدخول لاستخدام مكتبتك.';

  @override
  String get tuBibliotecaEstaVacia => 'مكتبتك فارغة.';

  @override
  String get titulo => 'العنوان...';

  @override
  String get tonalidad => 'المقام...';

  @override
  String get sinResultados => 'لا توجد نتائج.';

  @override
  String get noSePudoBuscarIntenta => 'تعذّر البحث. حاول مرة أخرى بعد قليل.';

  @override
  String get todaviaNoHayBibliotecasPara =>
      'لا توجد مكتبات للبحث فيها في هذه الغرفة بعد.';

  @override
  String de(Object propietario) {
    return 'من $propietario';
  }

  @override
  String get elSetlistEstaVacioNo => 'قائمة الأغاني فارغة، لا يوجد ما يُصدَّر.';

  @override
  String setlistSala(Object codigoSala) {
    return 'قائمة الأغاني — الغرفة $codigoSala\n\n';
  }

  @override
  String get exportarSetlist => 'تصدير قائمة الأغاني';

  @override
  String get copiadoAlPortapapeles => 'تم النسخ إلى الحافظة';

  @override
  String get copiar => 'نسخ';

  @override
  String setlistSala2(Object codigoSala) {
    return 'قائمة الأغاني - الغرفة $codigoSala';
  }

  @override
  String get compartir => 'مشاركة';

  @override
  String get cerrar => 'إغلاق';

  @override
  String agregado(Object titulo) {
    return 'تمت الإضافة: $titulo';
  }

  @override
  String get todaviaNoHayTemasEn => 'لا توجد أغانٍ في القائمة بعد.';

  @override
  String get cambiarEstadoDelTema => 'تغيير حالة الأغنية';

  @override
  String get pendiente => 'قيد الانتظار';

  @override
  String get pausadoCorteTecnico => 'متوقفة مؤقتًا (انقطاع تقني)';

  @override
  String get tocado => 'تم عزفها';

  @override
  String get pausado => 'متوقفة مؤقتًا';

  @override
  String get proximo => 'التالية';

  @override
  String subidoPor(Object persona) {
    return 'رفعها $persona';
  }

  @override
  String get verCifradoTransponer => 'عرض الكوردات (تغيير المقام)';

  @override
  String get exportarCompartirSetlist => 'تصدير / مشاركة قائمة الأغاني';

  @override
  String get agregarCancion => 'إضافة أغنية';

  @override
  String get necesitasIniciarSesionParaUsar2 =>
      'يجب تسجيل الدخول لاستخدام تسلسلاتك.';

  @override
  String get noTenesSecuenciasTodaviaSubilas =>
      'ليس لديك تسلسلات بعد.\nارفعها من \"تسلسلاتي\" في القائمة الرئيسية.';

  @override
  String get buscarSecuencia => 'ابحث عن تسلسل...';

  @override
  String get yaEstaEnLaSala => 'موجود في الغرفة بالفعل';

  @override
  String get elegiLasSecuenciasDeHoy => 'اختر تسلسلات اليوم';

  @override
  String cargarALaSala(Object cantidad) {
    return 'إضافة $cantidad إلى الغرفة';
  }

  @override
  String noSePudieronCargar(Object error) {
    return 'تعذّرت الإضافة: $error';
  }

  @override
  String get quitarDeLaSala => 'إزالة من الغرفة';

  @override
  String quitarDeLasSecuenciasDe(Object titulo) {
    return 'هل تريد إزالة \"$titulo\" من تسلسلات اليوم؟ ستبقى في مكتبة من رفعها.';
  }

  @override
  String get quitar => 'إزالة';

  @override
  String noSePudoGuardarEl(Object error) {
    return 'تعذّر حفظ التعديل: $error';
  }

  @override
  String get seGuardaParaTodaLa =>
      'يُحفظ لكل الغرفة. المقام والإيقاع والصوت تُضبط بشكل منفصل.';

  @override
  String get tono => 'المقام';

  @override
  String get bajarUnSemitono => 'خفض نصف نغمة';

  @override
  String get subirUnSemitono => 'رفع نصف نغمة';

  @override
  String get elCambioDeTonoPor => 'تغيير المقام يعمل حاليًا في نسخة الويب فقط.';

  @override
  String get tempo => 'الإيقاع';

  @override
  String get masLento1 => 'أبطأ (1%)';

  @override
  String get masRapido1 => 'أسرع (1%)';

  @override
  String get volumen => 'مستوى الصوت';

  @override
  String get bajar5 => 'خفض 5%';

  @override
  String get subir5 => 'رفع 5%';

  @override
  String get restablecerComoSeSubio => 'إعادة الضبط (كما رُفع)';

  @override
  String noSePudieronCargarLas(Object error) {
    return 'تعذّر تحميل التسلسلات: $error';
  }

  @override
  String cargadaPor(Object persona) {
    return 'أضافها $persona';
  }

  @override
  String get tonoTempoYVolumen => 'المقام والإيقاع ومستوى الصوت';

  @override
  String get repetir => 'تكرار';

  @override
  String get todaviaNoHaySecuenciasCargadas => 'لم تُحمَّل تسلسلات لليوم بعد.';

  @override
  String get todaviaNoHaySecuenciasCargadas2 =>
      'لم تُحمَّل تسلسلات لليوم بعد.\nاضغط + لاختيارها من \"تسلسلاتي\".';

  @override
  String get cargarSecuenciasDeHoy => 'تحميل تسلسلات اليوم';

  @override
  String get nuevaFrase => 'عبارة جديدة';

  @override
  String get textoDeLaFrase => 'نص العبارة';

  @override
  String get agregar => 'إضافة';

  @override
  String get editarFrase => 'تعديل العبارة';

  @override
  String get misFrases2 => 'عباراتي';

  @override
  String get necesitasIniciarSesionParaEditar =>
      'يجب تسجيل الدخول لتعديل عباراتك.';

  @override
  String get todaviaNoTenesFrasesPropias => 'ليس لديك عبارات خاصة بعد.';

  @override
  String get cargarFrasesPorDefecto => 'تحميل العبارات الافتراضية';

  @override
  String get funcionPro => 'ميزة Pro';

  @override
  String get subirTusPropiasPartiturasCifrados =>
      'رفع النوتات/الكوردات الخاصة بك بصيغة PDF جزء من Sound Check Pro. فعّل حساب Pro لاستخدام هذه الميزة.';

  @override
  String get entendido => 'حسنًا';

  @override
  String errorAlSubir(Object error) {
    return 'خطأ في الرفع: $error';
  }

  @override
  String get nuevaCancion => 'أغنية جديدة';

  @override
  String get editarCancion => 'تعديل الأغنية';

  @override
  String get titulo2 => 'العنوان';

  @override
  String get tonalidadOpcional => 'المقام (اختياري)';

  @override
  String get cifradoEnTextoOpcionalPara =>
      'الكوردات كنص (اختياري، لتغيير المقام)';

  @override
  String get pegaLosAcordesAcaEj =>
      'الصق الكوردات هنا. مثال: [C]Amazing [G]grace...';

  @override
  String get regenerarCifrados => 'إعادة إنشاء الكوردات';

  @override
  String get seVaAVolverA =>
      'ستُقرأ كل ملفات PDF في مكتبتك من جديد لإعادة بناء الكوردات بمواضعها كما في ملف PDF الأصلي.\n\nسيستبدل هذا نص الكوردات المحفوظ لكل أغنية (بما في ذلك ما عدّلته يدويًا). الأغاني التي لا يحتوي ملف PDF فيها على نص قابل للتحديد لن تتغير.';

  @override
  String get regenerar => 'إعادة إنشاء';

  @override
  String get preparando => 'جارٍ التحضير...';

  @override
  String procesandoDe(Object hechas, Object total) {
    return 'جارٍ معالجة $hechas من $total...';
  }

  @override
  String actualizadas(Object cantidad) {
    return 'تم تحديث $cantidad';
  }

  @override
  String sinTextoEnElPdf(Object cantidad) {
    return '$cantidad بلا نص في PDF';
  }

  @override
  String conError(Object cantidad) {
    return '$cantidad بها خطأ';
  }

  @override
  String cifrados(Object detalle) {
    return 'الكوردات: $detalle.';
  }

  @override
  String get eliminarCancion => 'حذف الأغنية؟';

  @override
  String get seBorraDeTuBiblioteca =>
      'ستُحذف من مكتبتك. إذا كانت في قائمة أغاني غرفة ما فلن تُفتح بعد الآن.';

  @override
  String get eliminar => 'حذف';

  @override
  String get miRepertorio2 => 'ريبرتواري';

  @override
  String get regenerarCifradosDesdeLosPdf =>
      'إعادة إنشاء الكوردات من ملفات PDF';

  @override
  String get necesitasIniciarSesionParaTener2 =>
      'يجب تسجيل الدخول لامتلاك مكتبة.';

  @override
  String get subirTusPropiasPartiturasEs => 'رفع النوتات الخاصة بك ميزة Pro.';

  @override
  String get masInfo => 'مزيد من المعلومات';

  @override
  String get todaviaNoSubisteNingunaCancion => 'لم ترفع أي أغنية بعد.';

  @override
  String tonalidad2(Object tonalidad) {
    return 'المقام: $tonalidad';
  }

  @override
  String get subirTusPropiasSecuenciasEs =>
      'رفع التسلسلات الخاصة بك جزء من Sound Check Pro. فعّل حساب Pro لاستخدام هذه الميزة.';

  @override
  String get archivoDemasiadoGrande => 'الملف كبير جدًا';

  @override
  String get archivosDemasiadoGrandes => 'الملفات كبيرة جدًا';

  @override
  String elMaximoPorArchivoEs(Object lista, Object limite) {
    return '$lista\n\nالحد الأقصى للملف الواحد هو $limite. حوّله إلى MP3 (بسرعة 320 كيلوبت/ث تشغل الأغنية الكاملة نحو 10-15 ميغابايت) وأعد رفعه، أو ارفعه من نسخة الويب التي تحوّل تلقائيًا.';
  }

  @override
  String convirtiendoAMp3(Object contador) {
    return 'جارٍ التحويل إلى MP3$contador';
  }

  @override
  String convirtiendoAMp32(Object porcentaje, Object contador) {
    return 'جارٍ التحويل إلى MP3 $porcentaje%$contador';
  }

  @override
  String subiendo(Object contador) {
    return 'جارٍ الرفع$contador';
  }

  @override
  String get secuenciasSubidas => 'تم رفع التسلسلات';

  @override
  String get algunasSecuenciasNoSeSubieron => 'لم يتم رفع بعض التسلسلات';

  @override
  String seConvirtieronAMp3Porque(Object limite, Object lista) {
    return 'تم تحويلها إلى MP3 لأنها تجاوزت الحد الأقصى $limite:\n$lista';
  }

  @override
  String noSePudieronSubir(Object lista) {
    return 'تعذّر الرفع:\n$lista';
  }

  @override
  String get renombrarSecuencia => 'إعادة تسمية التسلسل';

  @override
  String get eliminarSecuencia => 'حذف التسلسل';

  @override
  String eliminarDeTuBiblioteca(Object titulo) {
    return 'هل تريد حذف \"$titulo\" من مكتبتك؟';
  }

  @override
  String get misSecuencias2 => 'تسلسلاتي';

  @override
  String get necesitasIniciarSesionParaTener3 =>
      'يجب تسجيل الدخول لامتلاك تسلسلات.';

  @override
  String errorAlCargar(Object error) {
    return 'خطأ في التحميل: $error';
  }

  @override
  String get todaviaNoSubisteSecuenciasToca =>
      'لم ترفع تسلسلات بعد.\nاضغط الزر أدناه لرفع مساراتك الصوتية (MP3 وWAV وM4A...).';

  @override
  String get subirSecuencias => 'رفع تسلسلات';

  @override
  String get restablecerTonoOriginal => 'استعادة المقام الأصلي';

  @override
  String get sincronizadoConTodaLaSala =>
      'متزامن مع كل الغرفة (اضغط لإلغاء المزامنة)';

  @override
  String get desincronizadoCambiosSoloLocalesToca =>
      'غير متزامن — التغييرات محلية فقط (اضغط لإعادة المزامنة)';

  @override
  String noSePudoCargarEl(Object error) {
    return 'تعذّر تحميل ملف PDF.\n$error';
  }

  @override
  String errorAlIngresarAlPanel(Object error) {
    return 'خطأ في الدخول إلى اللوحة: $error';
  }

  @override
  String get accesoSonidista2 => 'دخول مهندس الصوت';

  @override
  String get pinDeSalaOCrear => 'رمز PIN للغرفة أو إنشاء غرفة';

  @override
  String get accederAlPanel => 'الدخول إلى اللوحة';

  @override
  String tuRespuesta(Object respuesta) {
    return 'ردّك: $respuesta';
  }

  @override
  String get responderPrivado => 'الرد بشكل خاص';

  @override
  String responderA(Object musico) {
    return 'الرد على $musico';
  }

  @override
  String pedido(Object pedido) {
    return 'الطلب: \"$pedido\"';
  }

  @override
  String get escribirRespuestaPrivada => 'اكتب ردًا خاصًا...';

  @override
  String get enviar => 'إرسال';

  @override
  String consola2(Object codigoSala) {
    return 'الميكسر: $codigoSala';
  }

  @override
  String get borrarTodo => 'مسح الكل؟';

  @override
  String get no => 'لا';

  @override
  String get si => 'نعم';

  @override
  String get agrupadoPorRolActivado => 'التجميع حسب الدور: مفعّل';

  @override
  String get verAgrupadoPorRol => 'العرض مجمّعًا حسب الدور';

  @override
  String errorDeConexion(Object error) {
    return 'خطأ في الاتصال: $error';
  }

  @override
  String get esperandoPedidos => 'في انتظار الطلبات...';

  @override
  String get todaviaNoAtendisteNingunPedido => 'لم تعالج أي طلب بعد';

  @override
  String get nombreApp => 'Sound Check Pro';

  @override
  String get rolMusico => 'موسيقي';

  @override
  String get rolCantante => 'مغنٍّ';

  @override
  String get rolSonidista => 'مهندس صوت';

  @override
  String get rolOtro => 'آخر';

  @override
  String rolesYUltimo(String lista, String ultimo) {
    return '$lista و$ultimo';
  }

  @override
  String get paletaEscenarioNombre => 'المسرح';

  @override
  String get paletaEscenarioTag => 'نيون سماوي وبنفسجي';

  @override
  String get paletaConsolaNombre => 'الميكسر';

  @override
  String get paletaConsolaTag => 'بنفسجي، أنيق';

  @override
  String get paletaPlacaNombre => 'اللوحة';

  @override
  String get paletaPlacaTag => 'رمادي جرافيت + كهرمان VU';

  @override
  String get paletaWashNombre => 'الإضاءة الشاملة';

  @override
  String get paletaWashTag => 'أزرق مخضرّ كإضاءة المسرح';

  @override
  String get paletaLuzDeTrabajoNombre => 'ضوء العمل';

  @override
  String get paletaLuzDeTrabajoTag => 'أقصى تباين';

  @override
  String get paletaCamarinNombre => 'غرفة الفنانين';

  @override
  String get paletaCamarinTag => 'وردي باستيل، ناعم';

  @override
  String get pestanaPedidos => 'الطلبات';

  @override
  String get pestanaHistorial => 'السجل';

  @override
  String get pestanaSetlist => 'قائمة الأغاني';

  @override
  String get pestanaSecuencias => 'التسلسلات';

  @override
  String get fraseVolumenRetorno => 'صوت المونيتور';

  @override
  String get fraseVolumenAl2 => 'الصوت على 2';

  @override
  String get fraseVolumenAl3 => 'الصوت على 3';

  @override
  String get fraseVolumenAl4 => 'الصوت على 4';

  @override
  String get fraseVolumenGuitarra => 'صوت الجيتار';

  @override
  String get fraseVolumenTeclado => 'صوت الكيبورد';

  @override
  String get fraseVolumenTalkback => 'صوت التوك باك';

  @override
  String get fraseVolumenPista => 'صوت المسار';

  @override
  String get fraseVolumenClick => 'صوت الكليك';

  @override
  String get fraseVolumenCoordinador => 'صوت المنسّق';

  @override
  String get fraseVolumenGeneral => 'الصوت العام';

  @override
  String get fraseListo => 'جاهز';

  @override
  String get tonoOriginal => 'الأصلي';

  @override
  String semitonosConSigno(String signo, int cantidad) {
    String _temp0 = intl.Intl.pluralLogic(
      cantidad,
      locale: localeName,
      other: '$signo$cantidad نصف نغمة',
      many: '$signo$cantidad نصف نغمة',
      few: '$signo$cantidad أنصاف نغمات',
      two: '$signo$cantidad نصفا نغمة',
      one: '$signo$cantidad نصف نغمة',
    );
    return '$_temp0';
  }

  @override
  String ajusteTono(String valor) {
    return 'المقام $valor';
  }

  @override
  String ajusteTempo(int valor) {
    return 'الإيقاع $valor%';
  }

  @override
  String ajusteVolumen(int valor) {
    return 'الصوت $valor%';
  }

  @override
  String secuenciasParaHoy(int cantidad) {
    String _temp0 = intl.Intl.pluralLogic(
      cantidad,
      locale: localeName,
      other: '$cantidad تسلسل لليوم',
      many: '$cantidad تسلسلًا لليوم',
      few: '$cantidad تسلسلات لليوم',
      two: 'تسلسلان لليوم',
      one: 'تسلسل واحد لليوم',
    );
    return '$_temp0';
  }

  @override
  String get idioma => 'اللغة';

  @override
  String get idiomaAutomatico => 'تلقائي (لغة الجهاز)';

  @override
  String get idiomaDescripcion => 'اختر لغة التطبيق. تُحفظ على هذا الجهاز.';
}
