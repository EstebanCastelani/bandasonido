// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get tuRolPodesMarcarMas => 'Ваша роль (можно выбрать несколько)';

  @override
  String get inicioDeSesionConGoogle => 'Вход через Google отменён.';

  @override
  String get elEmailNoEsValido => 'Недопустимый адрес эл. почты.';

  @override
  String get estaCuentaFueDeshabilitada => 'Эта учётная запись отключена.';

  @override
  String get noExisteUnaCuentaCon =>
      'Учётной записи с таким адресом не существует.';

  @override
  String get emailOContrasenaIncorrectos =>
      'Неверный адрес эл. почты или пароль.';

  @override
  String get yaExisteUnaCuentaCon =>
      'Учётная запись с таким адресом уже существует.';

  @override
  String get laContrasenaDebeTenerAl =>
      'Пароль должен содержать не менее 6 символов.';

  @override
  String get errorDeAutenticacion => 'Ошибка аутентификации.';

  @override
  String get pausar => 'Пауза';

  @override
  String get reproducir => 'Играть';

  @override
  String noSePudoReproducir(Object error) {
    return 'Не удалось воспроизвести: $error';
  }

  @override
  String get bajandoElVolumen => 'Снижение громкости...';

  @override
  String fadeOutS(Object segundos) {
    return 'Затухание ($segundos с)';
  }

  @override
  String get detener => 'Стоп';

  @override
  String get modoClaroOscuroParaEl =>
      'Светлая/тёмная тема (для остальной части приложения)';

  @override
  String get colorDeLaApp => 'Цвет приложения';

  @override
  String get comunicacionEnVivoEntreMusicos =>
      'Связь в реальном времени\nмежду музыкантами и звукорежиссёрами';

  @override
  String get iniciarSesion => 'Войти';

  @override
  String get crearCuenta => 'Создать аккаунт';

  @override
  String get entrarComoInvitado => 'Войти как гость';

  @override
  String get tiempoReal => 'Реальное время';

  @override
  String get sincronizacionInstantanea => 'Мгновенная\nсинхронизация';

  @override
  String get urgente => 'Срочно';

  @override
  String get alertasVisualesYSonoras => 'Визуальные\nи звуковые сигналы';

  @override
  String get multiSala => 'Несколько комнат';

  @override
  String get manejaVariasBandasYShows =>
      'Управляйте несколькими\nгруппами и концертами';

  @override
  String get setlistEnVivo => 'Сетлист вживую';

  @override
  String get listaDeTemasCompartida => 'Общий список\nпесен';

  @override
  String get completaEmailYContrasena => 'Введите эл. почту и пароль.';

  @override
  String get completaTuPerfil => 'Заполните профиль';

  @override
  String get tuNombre => 'Ваше имя';

  @override
  String get requerido => 'Обязательно';

  @override
  String get tuRolEjSonidistaGuitarrista =>
      'Ваша роль (напр.: звукорежиссёр, гитарист)';

  @override
  String get guardar => 'Сохранить';

  @override
  String get recuperarContrasena => 'Восстановить пароль';

  @override
  String get tuEmail => 'Ваша эл. почта';

  @override
  String get cancelar => 'Отмена';

  @override
  String get enviarEmail => 'Отправить письмо';

  @override
  String get teEnviamosUnEmailPara =>
      'Мы отправили вам письмо для сброса пароля.';

  @override
  String get tuRolEjSonidistaGuitarrista2 =>
      'Ваша роль (напр.: звукорежиссёр, гитарист, бэк-вокалист)';

  @override
  String get email => 'Эл. почта';

  @override
  String get emailInvalido => 'Недопустимый адрес';

  @override
  String get contrasena => 'Пароль';

  @override
  String get minimo6Caracteres => 'Минимум 6 символов';

  @override
  String get olvidasteTuContrasena => 'Забыли пароль?';

  @override
  String get registrarme => 'ЗАРЕГИСТРИРОВАТЬСЯ';

  @override
  String get iniciarSesion2 => 'ВОЙТИ';

  @override
  String get yaTenesCuentaIniciarSesion => 'Уже есть аккаунт? Войти';

  @override
  String get noTenesCuentaRegistrarme => 'Нет аккаунта? Зарегистрироваться';

  @override
  String get continuarConGoogle => 'Продолжить через Google';

  @override
  String get continuarSinCuenta => 'Продолжить без аккаунта';

  @override
  String get cerrarSesionDeCuenta => 'Выйти из аккаунта';

  @override
  String sesion(Object usuario) {
    return 'Сеанс: $usuario';
  }

  @override
  String get crearNuevaSala => 'СОЗДАТЬ НОВУЮ КОМНАТУ';

  @override
  String get unirmeASala => 'ВОЙТИ В КОМНАТУ';

  @override
  String get misSalas => 'МОИ КОМНАТЫ';

  @override
  String get misFrases => 'МОИ ФРАЗЫ';

  @override
  String get miRepertorio => 'МОЙ РЕПЕРТУАР';

  @override
  String get misSecuencias => 'МОИ СЕКВЕНЦИИ';

  @override
  String get accesoSonidista => 'ВХОД ДЛЯ ЗВУКОРЕЖИССЁРА';

  @override
  String get elegiLaIdentidadVisualDe =>
      'Выберите визуальный стиль приложения. Он сохранится на этом устройстве.';

  @override
  String get marcaAlMenosUnRol => 'Выберите хотя бы одну роль.';

  @override
  String errorAlIngresar(Object error) {
    return 'Ошибка входа: $error';
  }

  @override
  String get configurarSala => 'Настроить комнату';

  @override
  String get tuPinDeSala => 'PIN вашей комнаты';

  @override
  String get pinCopiado => 'PIN скопирован';

  @override
  String get tuNombre2 => 'Ваше имя';

  @override
  String get empezar => 'НАЧАТЬ';

  @override
  String get unirseASala => 'Войти в комнату';

  @override
  String get codigoDeSala8Caracteres => 'Код комнаты (8 символов)';

  @override
  String get unirme => 'ВОЙТИ';

  @override
  String get nombreParaEstaSala => 'Название комнаты';

  @override
  String get ejBandaXEnsayoJueves => 'Напр.: Группа X — репетиция в четверг';

  @override
  String get misSalas2 => 'Мои комнаты';

  @override
  String get necesitasIniciarSesionParaTener =>
      'Войдите в аккаунт, чтобы сохранялась история комнат.';

  @override
  String get guardarUnHistorialDeVarias =>
      'Хранить историю нескольких комнат/групп и возвращаться в одно касание — функция Pro.';

  @override
  String get todaviaNoEntrasteANinguna =>
      'Вы ещё не входили ни в одну комнату с этим аккаунтом.';

  @override
  String get renombrar => 'Переименовать';

  @override
  String get quitarDelHistorial => 'Удалить из истории';

  @override
  String get queQueresVerEnLa => 'Что показывать в комнате?';

  @override
  String get seGuardaEnEsteDispositivo =>
      'Сохраняется на этом устройстве. Должна остаться хотя бы одна.';

  @override
  String urgenteEnviado(Object texto) {
    return 'Срочное отправлено!: $texto';
  }

  @override
  String enviado(Object texto) {
    return 'Отправлено: $texto';
  }

  @override
  String get cerrarSesion => 'Выйти';

  @override
  String get codigoDeSalaCopiado => 'Код комнаты скопирован';

  @override
  String sala(Object codigoSala) {
    return 'КОМНАТА: $codigoSala';
  }

  @override
  String get pantallaSiempreEncendidaActivado => 'Экран всегда включён: вкл.';

  @override
  String get pantallaSiempreEncendidaDesactivado =>
      'Экран всегда включён: выкл.';

  @override
  String get elegirQueVerEnLa => 'Выбрать, что показывать в комнате';

  @override
  String get escribirPedidoPersonalizado => 'Написать свой запрос...';

  @override
  String get pedidoUrgenteActivado => 'Срочный запрос: вкл.';

  @override
  String get marcarElProximoPedidoComo =>
      'Отметить следующий запрос как срочный';

  @override
  String get misUltimosPedidos => 'МОИ ПОСЛЕДНИЕ ЗАПРОСЫ';

  @override
  String error(Object error) {
    return 'Ошибка: $error';
  }

  @override
  String get sinPedidosPropios => 'Нет ваших запросов';

  @override
  String eliminandoPedido(Object pedido) {
    return 'Удаление запроса: «$pedido»';
  }

  @override
  String consola(Object respuesta) {
    return 'Пульт: $respuesta';
  }

  @override
  String get desdeMiBiblioteca => 'Из моей библиотеки';

  @override
  String get buscarEnBibliotecasDeLa => 'Искать в библиотеках комнаты';

  @override
  String get necesitasIniciarSesionParaUsar =>
      'Войдите в аккаунт, чтобы пользоваться библиотекой.';

  @override
  String get tuBibliotecaEstaVacia => 'Ваша библиотека пуста.';

  @override
  String get titulo => 'Название...';

  @override
  String get tonalidad => 'Тональность...';

  @override
  String get sinResultados => 'Ничего не найдено.';

  @override
  String get noSePudoBuscarIntenta =>
      'Не удалось выполнить поиск. Повторите чуть позже.';

  @override
  String get todaviaNoHayBibliotecasPara =>
      'В этой комнате пока нет библиотек для поиска.';

  @override
  String de(Object propietario) {
    return 'от $propietario';
  }

  @override
  String get elSetlistEstaVacioNo => 'Сетлист пуст, экспортировать нечего.';

  @override
  String setlistSala(Object codigoSala) {
    return 'Сетлист — комната $codigoSala\n\n';
  }

  @override
  String get exportarSetlist => 'Экспорт сетлиста';

  @override
  String get copiadoAlPortapapeles => 'Скопировано в буфер обмена';

  @override
  String get copiar => 'Копировать';

  @override
  String setlistSala2(Object codigoSala) {
    return 'Сетлист — комната $codigoSala';
  }

  @override
  String get compartir => 'Поделиться';

  @override
  String get cerrar => 'Закрыть';

  @override
  String agregado(Object titulo) {
    return 'Добавлено: $titulo';
  }

  @override
  String get todaviaNoHayTemasEn => 'В списке пока нет песен.';

  @override
  String get cambiarEstadoDelTema => 'Изменить статус песни';

  @override
  String get pendiente => 'Ожидает';

  @override
  String get pausadoCorteTecnico => 'Пауза (технический перерыв)';

  @override
  String get tocado => 'Сыграна';

  @override
  String get pausado => 'ПАУЗА';

  @override
  String get proximo => 'СЛЕДУЮЩАЯ';

  @override
  String subidoPor(Object persona) {
    return 'Загрузил(а): $persona';
  }

  @override
  String get verCifradoTransponer => 'Показать аккорды (транспонировать)';

  @override
  String get exportarCompartirSetlist => 'Экспорт / отправка сетлиста';

  @override
  String get agregarCancion => 'Добавить песню';

  @override
  String get necesitasIniciarSesionParaUsar2 =>
      'Войдите в аккаунт, чтобы пользоваться секвенциями.';

  @override
  String get noTenesSecuenciasTodaviaSubilas =>
      'У вас пока нет секвенций.\nЗагрузите их в разделе «Мои секвенции» главного меню.';

  @override
  String get buscarSecuencia => 'Найти секвенцию...';

  @override
  String get yaEstaEnLaSala => 'Уже в комнате';

  @override
  String get elegiLasSecuenciasDeHoy => 'Выберите секвенции на сегодня';

  @override
  String cargarALaSala(Object cantidad) {
    return 'ДОБАВИТЬ В КОМНАТУ: $cantidad';
  }

  @override
  String noSePudieronCargar(Object error) {
    return 'Не удалось добавить: $error';
  }

  @override
  String get quitarDeLaSala => 'Убрать из комнаты';

  @override
  String quitarDeLasSecuenciasDe(Object titulo) {
    return 'Убрать «$titulo» из секвенций на сегодня? Она останется в библиотеке того, кто её загрузил.';
  }

  @override
  String get quitar => 'Убрать';

  @override
  String noSePudoGuardarEl(Object error) {
    return 'Не удалось сохранить настройку: $error';
  }

  @override
  String get seGuardaParaTodaLa =>
      'Сохраняется для всей комнаты. Тональность, темп и громкость меняются отдельно.';

  @override
  String get tono => 'ТОНАЛЬНОСТЬ';

  @override
  String get bajarUnSemitono => 'Понизить на полтона';

  @override
  String get subirUnSemitono => 'Повысить на полтона';

  @override
  String get elCambioDeTonoPor =>
      'Смена тональности пока работает только в веб-версии.';

  @override
  String get tempo => 'ТЕМП';

  @override
  String get masLento1 => 'Медленнее (1%)';

  @override
  String get masRapido1 => 'Быстрее (1%)';

  @override
  String get volumen => 'ГРОМКОСТЬ';

  @override
  String get bajar5 => 'Тише на 5%';

  @override
  String get subir5 => 'Громче на 5%';

  @override
  String get restablecerComoSeSubio => 'Сбросить (как при загрузке)';

  @override
  String noSePudieronCargarLas(Object error) {
    return 'Не удалось загрузить секвенции: $error';
  }

  @override
  String cargadaPor(Object persona) {
    return 'Добавил(а): $persona';
  }

  @override
  String get tonoTempoYVolumen => 'Тональность, темп и громкость';

  @override
  String get repetir => 'Повтор';

  @override
  String get todaviaNoHaySecuenciasCargadas =>
      'Секвенции на сегодня ещё не загружены.';

  @override
  String get todaviaNoHaySecuenciasCargadas2 =>
      'Секвенции на сегодня ещё не загружены.\nНажмите +, чтобы выбрать их из «Моих секвенций».';

  @override
  String get cargarSecuenciasDeHoy => 'Загрузить секвенции на сегодня';

  @override
  String get nuevaFrase => 'Новая фраза';

  @override
  String get textoDeLaFrase => 'Текст фразы';

  @override
  String get agregar => 'Добавить';

  @override
  String get editarFrase => 'Изменить фразу';

  @override
  String get misFrases2 => 'Мои фразы';

  @override
  String get necesitasIniciarSesionParaEditar =>
      'Войдите в аккаунт, чтобы редактировать фразы.';

  @override
  String get todaviaNoTenesFrasesPropias => 'У вас пока нет собственных фраз.';

  @override
  String get cargarFrasesPorDefecto => 'Загрузить стандартные фразы';

  @override
  String get funcionPro => 'Функция Pro';

  @override
  String get subirTusPropiasPartiturasCifrados =>
      'Загрузка собственных нот и аккордов в PDF входит в Sound Check Pro. Активируйте Pro-аккаунт, чтобы пользоваться этой функцией.';

  @override
  String get entendido => 'Понятно';

  @override
  String errorAlSubir(Object error) {
    return 'Ошибка загрузки: $error';
  }

  @override
  String get nuevaCancion => 'Новая песня';

  @override
  String get editarCancion => 'Изменить песню';

  @override
  String get titulo2 => 'Название';

  @override
  String get tonalidadOpcional => 'Тональность (необязательно)';

  @override
  String get cifradoEnTextoOpcionalPara =>
      'Аккорды текстом (необязательно, для транспонирования)';

  @override
  String get pegaLosAcordesAcaEj =>
      'Вставьте аккорды сюда. Напр.: [C]Amazing [G]grace...';

  @override
  String get regenerarCifrados => 'Пересоздать аккорды';

  @override
  String get seVaAVolverA =>
      'Каждый PDF из вашей библиотеки будет прочитан заново, чтобы собрать аккорды с расположением, как в исходном PDF.\n\nЭто заменит текст аккордов, сохранённый для каждой песни (в том числе правки вручную). Песни, у которых в PDF нет выделяемого текста, не изменятся.';

  @override
  String get regenerar => 'Пересоздать';

  @override
  String get preparando => 'Подготовка...';

  @override
  String procesandoDe(Object hechas, Object total) {
    return 'Обработано $hechas из $total...';
  }

  @override
  String actualizadas(Object cantidad) {
    return 'обновлено: $cantidad';
  }

  @override
  String sinTextoEnElPdf(Object cantidad) {
    return 'без текста в PDF: $cantidad';
  }

  @override
  String conError(Object cantidad) {
    return 'с ошибкой: $cantidad';
  }

  @override
  String cifrados(Object detalle) {
    return 'Аккорды: $detalle.';
  }

  @override
  String get eliminarCancion => 'Удалить песню?';

  @override
  String get seBorraDeTuBiblioteca =>
      'Она будет удалена из вашей библиотеки. Если она есть в сетлисте какой-либо комнаты, открыть её там будет нельзя.';

  @override
  String get eliminar => 'Удалить';

  @override
  String get miRepertorio2 => 'Мой репертуар';

  @override
  String get regenerarCifradosDesdeLosPdf => 'Пересоздать аккорды из PDF';

  @override
  String get necesitasIniciarSesionParaTener2 =>
      'Войдите в аккаунт, чтобы иметь библиотеку.';

  @override
  String get subirTusPropiasPartiturasEs =>
      'Загрузка собственных нот — функция Pro.';

  @override
  String get masInfo => 'Подробнее';

  @override
  String get todaviaNoSubisteNingunaCancion =>
      'Вы ещё не загрузили ни одной песни.';

  @override
  String tonalidad2(Object tonalidad) {
    return 'Тональность: $tonalidad';
  }

  @override
  String get subirTusPropiasSecuenciasEs =>
      'Загрузка собственных секвенций входит в Sound Check Pro. Активируйте Pro-аккаунт, чтобы пользоваться этой функцией.';

  @override
  String get archivoDemasiadoGrande => 'Файл слишком большой';

  @override
  String get archivosDemasiadoGrandes => 'Файлы слишком большие';

  @override
  String elMaximoPorArchivoEs(Object lista, Object limite) {
    return '$lista\n\nМаксимальный размер файла — $limite. Конвертируйте в MP3 (при 320 кбит/с целая песня занимает около 10–15 МБ) и загрузите снова либо загрузите через веб-версию, которая конвертирует автоматически.';
  }

  @override
  String convirtiendoAMp3(Object contador) {
    return 'Конвертация в MP3$contador';
  }

  @override
  String convirtiendoAMp32(Object porcentaje, Object contador) {
    return 'Конвертация в MP3 $porcentaje%$contador';
  }

  @override
  String subiendo(Object contador) {
    return 'Загрузка$contador';
  }

  @override
  String get secuenciasSubidas => 'Секвенции загружены';

  @override
  String get algunasSecuenciasNoSeSubieron =>
      'Некоторые секвенции не загружены';

  @override
  String seConvirtieronAMp3Porque(Object limite, Object lista) {
    return 'Преобразованы в MP3, так как превышали максимум $limite:\n$lista';
  }

  @override
  String noSePudieronSubir(Object lista) {
    return 'Не удалось загрузить:\n$lista';
  }

  @override
  String get renombrarSecuencia => 'Переименовать секвенцию';

  @override
  String get eliminarSecuencia => 'Удалить секвенцию';

  @override
  String eliminarDeTuBiblioteca(Object titulo) {
    return 'Удалить «$titulo» из вашей библиотеки?';
  }

  @override
  String get misSecuencias2 => 'Мои секвенции';

  @override
  String get necesitasIniciarSesionParaTener3 =>
      'Войдите в аккаунт, чтобы иметь секвенции.';

  @override
  String errorAlCargar(Object error) {
    return 'Ошибка загрузки: $error';
  }

  @override
  String get todaviaNoSubisteSecuenciasToca =>
      'Вы ещё не загрузили секвенции.\nНажмите кнопку ниже, чтобы загрузить аудиодорожки (MP3, WAV, M4A...).';

  @override
  String get subirSecuencias => 'Загрузить секвенции';

  @override
  String get restablecerTonoOriginal => 'Вернуть исходную тональность';

  @override
  String get sincronizadoConTodaLaSala =>
      'Синхронизировано со всей комнатой (нажмите, чтобы отключить)';

  @override
  String get desincronizadoCambiosSoloLocalesToca =>
      'Не синхронизировано — изменения только локальные (нажмите, чтобы включить синхронизацию)';

  @override
  String noSePudoCargarEl(Object error) {
    return 'Не удалось загрузить PDF.\n$error';
  }

  @override
  String errorAlIngresarAlPanel(Object error) {
    return 'Ошибка входа в панель: $error';
  }

  @override
  String get accesoSonidista2 => 'Вход для звукорежиссёра';

  @override
  String get pinDeSalaOCrear => 'PIN комнаты или Создать комнату';

  @override
  String get accederAlPanel => 'ВОЙТИ В ПАНЕЛЬ';

  @override
  String tuRespuesta(Object respuesta) {
    return 'Ваш ответ: $respuesta';
  }

  @override
  String get responderPrivado => 'Ответить лично';

  @override
  String responderA(Object musico) {
    return 'Ответить: $musico';
  }

  @override
  String pedido(Object pedido) {
    return 'Запрос: «$pedido»';
  }

  @override
  String get escribirRespuestaPrivada => 'Написать личный ответ...';

  @override
  String get enviar => 'Отправить';

  @override
  String consola2(Object codigoSala) {
    return 'Пульт: $codigoSala';
  }

  @override
  String get borrarTodo => 'Удалить всё?';

  @override
  String get no => 'Нет';

  @override
  String get si => 'Да';

  @override
  String get agrupadoPorRolActivado => 'Группировка по ролям: вкл.';

  @override
  String get verAgrupadoPorRol => 'Показать по ролям';

  @override
  String errorDeConexion(Object error) {
    return 'Ошибка соединения: $error';
  }

  @override
  String get esperandoPedidos => 'Ожидание запросов...';

  @override
  String get todaviaNoAtendisteNingunPedido =>
      'Вы ещё не обработали ни одного запроса';

  @override
  String get nombreApp => 'Sound Check Pro';

  @override
  String get rolMusico => 'Музыкант';

  @override
  String get rolCantante => 'Вокалист';

  @override
  String get rolSonidista => 'Звукорежиссёр';

  @override
  String get rolOtro => 'Другое';

  @override
  String rolesYUltimo(String lista, String ultimo) {
    return '$lista и $ultimo';
  }

  @override
  String get paletaEscenarioNombre => 'Сцена';

  @override
  String get paletaEscenarioTag => 'Неон: голубой и фиолетовый';

  @override
  String get paletaConsolaNombre => 'Пульт';

  @override
  String get paletaConsolaTag => 'Фиолетовый, изысканный';

  @override
  String get paletaPlacaNombre => 'Панель';

  @override
  String get paletaPlacaTag => 'Графит + янтарь VU';

  @override
  String get paletaWashNombre => 'Wash';

  @override
  String get paletaWashTag => 'Сине-зелёный сценический свет';

  @override
  String get paletaLuzDeTrabajoNombre => 'Рабочий свет';

  @override
  String get paletaLuzDeTrabajoTag => 'Максимальный контраст';

  @override
  String get paletaCamarinNombre => 'Гримёрка';

  @override
  String get paletaCamarinTag => 'Пастельно-розовый, мягкий';

  @override
  String get pestanaPedidos => 'Запросы';

  @override
  String get pestanaHistorial => 'История';

  @override
  String get pestanaSetlist => 'Сетлист';

  @override
  String get pestanaSecuencias => 'Секвенции';

  @override
  String get fraseVolumenRetorno => 'Громкость мониторов';

  @override
  String get fraseVolumenAl2 => 'Громкость на 2';

  @override
  String get fraseVolumenAl3 => 'Громкость на 3';

  @override
  String get fraseVolumenAl4 => 'Громкость на 4';

  @override
  String get fraseVolumenGuitarra => 'Громкость гитары';

  @override
  String get fraseVolumenTeclado => 'Громкость клавиш';

  @override
  String get fraseVolumenTalkback => 'Громкость talkback';

  @override
  String get fraseVolumenPista => 'Громкость дорожки';

  @override
  String get fraseVolumenClick => 'Громкость клика';

  @override
  String get fraseVolumenCoordinador => 'Громкость координатора';

  @override
  String get fraseVolumenGeneral => 'Общая громкость';

  @override
  String get fraseListo => 'Готово';

  @override
  String get tonoOriginal => 'Оригинал';

  @override
  String semitonosConSigno(String signo, int cantidad) {
    String _temp0 = intl.Intl.pluralLogic(
      cantidad,
      locale: localeName,
      other: '$signo$cantidad полутона',
      many: '$signo$cantidad полутонов',
      few: '$signo$cantidad полутона',
      one: '$signo$cantidad полутон',
    );
    return '$_temp0';
  }

  @override
  String ajusteTono(String valor) {
    return 'Тональность $valor';
  }

  @override
  String ajusteTempo(int valor) {
    return 'Темп $valor%';
  }

  @override
  String ajusteVolumen(int valor) {
    return 'Гр. $valor%';
  }

  @override
  String secuenciasParaHoy(int cantidad) {
    String _temp0 = intl.Intl.pluralLogic(
      cantidad,
      locale: localeName,
      other: '$cantidad секвенции на сегодня',
      many: '$cantidad секвенций на сегодня',
      few: '$cantidad секвенции на сегодня',
      one: '$cantidad секвенция на сегодня',
    );
    return '$_temp0';
  }

  @override
  String get idioma => 'Язык';

  @override
  String get idiomaAutomatico => 'Автоматически (язык устройства)';

  @override
  String get idiomaDescripcion =>
      'Выберите язык приложения. Он сохранится на этом устройстве.';

  @override
  String get escribiTuRol => 'Укажите свою роль.';

  @override
  String get configuracion => 'Настройки';

  @override
  String get colores => 'Цвета';
}
