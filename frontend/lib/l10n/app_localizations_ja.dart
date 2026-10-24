// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class AppLocalizationsJa extends AppLocalizations {
  AppLocalizationsJa([String locale = 'ja']) : super(locale);

  @override
  String get tuRolPodesMarcarMas => 'あなたの役割（複数選択できます）';

  @override
  String get inicioDeSesionConGoogle => 'Googleでのログインをキャンセルしました。';

  @override
  String get elEmailNoEsValido => 'メールアドレスが正しくありません。';

  @override
  String get estaCuentaFueDeshabilitada => 'このアカウントは無効化されています。';

  @override
  String get noExisteUnaCuentaCon => 'このメールアドレスのアカウントは存在しません。';

  @override
  String get emailOContrasenaIncorrectos => 'メールアドレスまたはパスワードが違います。';

  @override
  String get yaExisteUnaCuentaCon => 'このメールアドレスのアカウントはすでに存在します。';

  @override
  String get laContrasenaDebeTenerAl => 'パスワードは6文字以上にしてください。';

  @override
  String get errorDeAutenticacion => '認証エラー。';

  @override
  String get pausar => '一時停止';

  @override
  String get reproducir => '再生';

  @override
  String noSePudoReproducir(Object error) {
    return '再生できませんでした：$error';
  }

  @override
  String get bajandoElVolumen => '音量を下げています...';

  @override
  String fadeOutS(Object segundos) {
    return 'フェードアウト（$segundos秒）';
  }

  @override
  String get detener => '停止';

  @override
  String get modoClaroOscuroParaEl => 'ライト/ダークモード（アプリのその他の部分）';

  @override
  String get colorDeLaApp => 'アプリの色';

  @override
  String get comunicacionEnVivoEntreMusicos => 'ミュージシャンとPAエンジニアの\nリアルタイム連絡';

  @override
  String get iniciarSesion => 'ログイン';

  @override
  String get crearCuenta => 'アカウント作成';

  @override
  String get entrarComoInvitado => 'ゲストとして入る';

  @override
  String get tiempoReal => 'リアルタイム';

  @override
  String get sincronizacionInstantanea => '瞬時に\n同期';

  @override
  String get urgente => '緊急';

  @override
  String get alertasVisualesYSonoras => '視覚と音による\n通知';

  @override
  String get multiSala => '複数ルーム';

  @override
  String get manejaVariasBandasYShows => '複数のバンドや\nライブを管理';

  @override
  String get setlistEnVivo => 'ライブセットリスト';

  @override
  String get listaDeTemasCompartida => '共有される\n曲リスト';

  @override
  String get completaEmailYContrasena => 'メールアドレスとパスワードを入力してください。';

  @override
  String get completaTuPerfil => 'プロフィールを完成させましょう';

  @override
  String get tuNombre => 'お名前';

  @override
  String get requerido => '必須';

  @override
  String get tuRolEjSonidistaGuitarrista => 'あなたの役割（例：PAエンジニア、ギタリスト）';

  @override
  String get guardar => '保存';

  @override
  String get recuperarContrasena => 'パスワードを再設定';

  @override
  String get tuEmail => 'メールアドレス';

  @override
  String get cancelar => 'キャンセル';

  @override
  String get enviarEmail => 'メールを送信';

  @override
  String get teEnviamosUnEmailPara => 'パスワード再設定用のメールを送信しました。';

  @override
  String get tuRolEjSonidistaGuitarrista2 => 'あなたの役割（例：PAエンジニア、ギタリスト、コーラス）';

  @override
  String get email => 'メールアドレス';

  @override
  String get emailInvalido => 'メールアドレスが無効です';

  @override
  String get contrasena => 'パスワード';

  @override
  String get minimo6Caracteres => '6文字以上';

  @override
  String get olvidasteTuContrasena => 'パスワードをお忘れですか？';

  @override
  String get registrarme => '登録';

  @override
  String get iniciarSesion2 => 'ログイン';

  @override
  String get yaTenesCuentaIniciarSesion => 'アカウントをお持ちですか？ログイン';

  @override
  String get noTenesCuentaRegistrarme => 'アカウントがありませんか？登録';

  @override
  String get continuarConGoogle => 'Googleで続行';

  @override
  String get continuarSinCuenta => 'アカウントなしで続行';

  @override
  String get cerrarSesionDeCuenta => 'アカウントからログアウト';

  @override
  String sesion(Object usuario) {
    return 'ログイン中：$usuario';
  }

  @override
  String get crearNuevaSala => '新しいルームを作成';

  @override
  String get unirmeASala => 'ルームに参加';

  @override
  String get misSalas => 'マイルーム';

  @override
  String get misFrases => 'マイフレーズ';

  @override
  String get miRepertorio => 'マイレパートリー';

  @override
  String get misSecuencias => 'マイシーケンス';

  @override
  String get accesoSonidista => 'PAエンジニア用';

  @override
  String get elegiLaIdentidadVisualDe => 'アプリの見た目を選んでください。この端末に保存されます。';

  @override
  String get marcaAlMenosUnRol => '役割を1つ以上選択してください。';

  @override
  String errorAlIngresar(Object error) {
    return 'ログインエラー：$error';
  }

  @override
  String get configurarSala => 'ルームの設定';

  @override
  String get tuPinDeSala => 'ルームのPIN';

  @override
  String get pinCopiado => 'PINをコピーしました';

  @override
  String get tuNombre2 => 'お名前';

  @override
  String get empezar => 'はじめる';

  @override
  String get unirseASala => 'ルームに参加';

  @override
  String get codigoDeSala8Caracteres => 'ルームコード（8文字）';

  @override
  String get unirme => '参加';

  @override
  String get nombreParaEstaSala => 'このルームの名前';

  @override
  String get ejBandaXEnsayoJueves => '例：Xバンド - 木曜リハ';

  @override
  String get misSalas2 => 'マイルーム';

  @override
  String get necesitasIniciarSesionParaTener => 'ルーム履歴を保存するにはログインが必要です。';

  @override
  String get guardarUnHistorialDeVarias =>
      '複数のルーム/バンドの履歴を保存してワンタップで戻れる機能はProです。';

  @override
  String get todaviaNoEntrasteANinguna => 'このアカウントでまだルームに参加していません。';

  @override
  String get renombrar => '名前を変更';

  @override
  String get quitarDelHistorial => '履歴から削除';

  @override
  String get queQueresVerEnLa => 'ルームで何を表示しますか？';

  @override
  String get seGuardaEnEsteDispositivo => 'この端末に保存されます。最低1つは残す必要があります。';

  @override
  String urgenteEnviado(Object texto) {
    return '緊急リクエストを送信しました！：$texto';
  }

  @override
  String enviado(Object texto) {
    return '送信しました：$texto';
  }

  @override
  String get cerrarSesion => 'ログアウト';

  @override
  String get codigoDeSalaCopiado => 'ルームコードをコピーしました';

  @override
  String sala(Object codigoSala) {
    return 'ルーム：$codigoSala';
  }

  @override
  String get pantallaSiempreEncendidaActivado => '画面常時オン：オン';

  @override
  String get pantallaSiempreEncendidaDesactivado => '画面常時オン：オフ';

  @override
  String get elegirQueVerEnLa => 'ルームで表示する内容を選択';

  @override
  String get escribirPedidoPersonalizado => 'カスタムリクエストを入力...';

  @override
  String get pedidoUrgenteActivado => '緊急リクエスト：オン';

  @override
  String get marcarElProximoPedidoComo => '次のリクエストを緊急にする';

  @override
  String get misUltimosPedidos => '最近のリクエスト';

  @override
  String error(Object error) {
    return 'エラー：$error';
  }

  @override
  String get sinPedidosPropios => '自分のリクエストはありません';

  @override
  String eliminandoPedido(Object pedido) {
    return 'リクエストを削除中：「$pedido」';
  }

  @override
  String consola(Object respuesta) {
    return '卓：$respuesta';
  }

  @override
  String get desdeMiBiblioteca => 'マイライブラリから';

  @override
  String get buscarEnBibliotecasDeLa => 'ルームのライブラリを検索';

  @override
  String get necesitasIniciarSesionParaUsar => 'ライブラリを使うにはログインが必要です。';

  @override
  String get tuBibliotecaEstaVacia => 'ライブラリは空です。';

  @override
  String get titulo => 'タイトル...';

  @override
  String get tonalidad => 'キー...';

  @override
  String get sinResultados => '結果がありません。';

  @override
  String get noSePudoBuscarIntenta => '検索できませんでした。しばらくしてからもう一度お試しください。';

  @override
  String get todaviaNoHayBibliotecasPara => 'このルームには検索できるライブラリがまだありません。';

  @override
  String de(Object propietario) {
    return '$propietarioさんの';
  }

  @override
  String get elSetlistEstaVacioNo => 'セットリストが空のため、書き出す内容がありません。';

  @override
  String setlistSala(Object codigoSala) {
    return 'セットリスト — ルーム $codigoSala\n\n';
  }

  @override
  String get exportarSetlist => 'セットリストを書き出す';

  @override
  String get copiadoAlPortapapeles => 'クリップボードにコピーしました';

  @override
  String get copiar => 'コピー';

  @override
  String setlistSala2(Object codigoSala) {
    return 'セットリスト - ルーム $codigoSala';
  }

  @override
  String get compartir => '共有';

  @override
  String get cerrar => '閉じる';

  @override
  String agregado(Object titulo) {
    return '追加しました：$titulo';
  }

  @override
  String get todaviaNoHayTemasEn => 'リストにはまだ曲がありません。';

  @override
  String get cambiarEstadoDelTema => '曲の状態を変更';

  @override
  String get pendiente => '未演奏';

  @override
  String get pausadoCorteTecnico => '一時停止（機材トラブル）';

  @override
  String get tocado => '演奏済み';

  @override
  String get pausado => '一時停止中';

  @override
  String get proximo => '次';

  @override
  String subidoPor(Object persona) {
    return '追加：$persona';
  }

  @override
  String get verCifradoTransponer => 'コード譜を見る（移調）';

  @override
  String get exportarCompartirSetlist => 'セットリストを書き出し / 共有';

  @override
  String get agregarCancion => '曲を追加';

  @override
  String get necesitasIniciarSesionParaUsar2 => 'シーケンスを使うにはログインが必要です。';

  @override
  String get noTenesSecuenciasTodaviaSubilas =>
      'シーケンスはまだありません。\nメインメニューの「マイシーケンス」からアップロードしてください。';

  @override
  String get buscarSecuencia => 'シーケンスを検索...';

  @override
  String get yaEstaEnLaSala => 'ルームに追加済み';

  @override
  String get elegiLasSecuenciasDeHoy => '今日使うシーケンスを選択';

  @override
  String cargarALaSala(Object cantidad) {
    return '$cantidad件をルームに追加';
  }

  @override
  String noSePudieronCargar(Object error) {
    return '追加できませんでした：$error';
  }

  @override
  String get quitarDeLaSala => 'ルームから外す';

  @override
  String quitarDeLasSecuenciasDe(Object titulo) {
    return '「$titulo」を今日のシーケンスから外しますか？アップロードした人のライブラリには残ります。';
  }

  @override
  String get quitar => '外す';

  @override
  String noSePudoGuardarEl(Object error) {
    return '調整を保存できませんでした：$error';
  }

  @override
  String get seGuardaParaTodaLa => 'ルーム全体に保存されます。キー・テンポ・音量は個別に変更されます。';

  @override
  String get tono => 'キー';

  @override
  String get bajarUnSemitono => '半音下げる';

  @override
  String get subirUnSemitono => '半音上げる';

  @override
  String get elCambioDeTonoPor => 'キー変更は現在Web版でのみ動作します。';

  @override
  String get tempo => 'テンポ';

  @override
  String get masLento1 => '遅く（1%）';

  @override
  String get masRapido1 => '速く（1%）';

  @override
  String get volumen => '音量';

  @override
  String get bajar5 => '5%下げる';

  @override
  String get subir5 => '5%上げる';

  @override
  String get restablecerComoSeSubio => 'リセット（アップロード時の状態）';

  @override
  String noSePudieronCargarLas(Object error) {
    return 'シーケンスを読み込めませんでした：$error';
  }

  @override
  String cargadaPor(Object persona) {
    return '追加：$persona';
  }

  @override
  String get tonoTempoYVolumen => 'キー・テンポ・音量';

  @override
  String get repetir => 'リピート';

  @override
  String get todaviaNoHaySecuenciasCargadas => '今日のシーケンスはまだ読み込まれていません。';

  @override
  String get todaviaNoHaySecuenciasCargadas2 =>
      '今日のシーケンスはまだ読み込まれていません。\n＋をタップして「マイシーケンス」から選んでください。';

  @override
  String get cargarSecuenciasDeHoy => '今日のシーケンスを読み込む';

  @override
  String get nuevaFrase => '新しいフレーズ';

  @override
  String get textoDeLaFrase => 'フレーズの文';

  @override
  String get agregar => '追加';

  @override
  String get editarFrase => 'フレーズを編集';

  @override
  String get misFrases2 => 'マイフレーズ';

  @override
  String get necesitasIniciarSesionParaEditar => 'フレーズを編集するにはログインが必要です。';

  @override
  String get todaviaNoTenesFrasesPropias => '自分のフレーズはまだありません。';

  @override
  String get cargarFrasesPorDefecto => '既定のフレーズを読み込む';

  @override
  String get funcionPro => 'Pro機能';

  @override
  String get subirTusPropiasPartiturasCifrados =>
      '自分の楽譜/コード譜（PDF）のアップロードはSound Check Proの機能です。Proアカウントを有効にしてご利用ください。';

  @override
  String get entendido => '了解';

  @override
  String errorAlSubir(Object error) {
    return 'アップロードエラー：$error';
  }

  @override
  String get nuevaCancion => '新しい曲';

  @override
  String get editarCancion => '曲を編集';

  @override
  String get titulo2 => 'タイトル';

  @override
  String get tonalidadOpcional => 'キー（任意）';

  @override
  String get cifradoEnTextoOpcionalPara => 'テキストのコード譜（任意・移調用）';

  @override
  String get pegaLosAcordesAcaEj => 'ここにコードを貼り付けます。例：[C]Amazing [G]grace...';

  @override
  String get regenerarCifrados => 'コード譜を再生成';

  @override
  String get seVaAVolverA =>
      'ライブラリ内の各PDFを読み直し、元のPDFと同じ位置にコードを置いたコード譜を作り直します。\n\n各曲に保存されているテキストのコード譜（手で編集した内容も含む）は置き換えられます。PDFに選択可能なテキストがない曲は変更されません。';

  @override
  String get regenerar => '再生成';

  @override
  String get preparando => '準備中...';

  @override
  String procesandoDe(Object hechas, Object total) {
    return '処理中 $hechas/$total...';
  }

  @override
  String actualizadas(Object cantidad) {
    return '$cantidad件を更新';
  }

  @override
  String sinTextoEnElPdf(Object cantidad) {
    return '$cantidad件はPDFにテキストなし';
  }

  @override
  String conError(Object cantidad) {
    return '$cantidad件でエラー';
  }

  @override
  String cifrados(Object detalle) {
    return 'コード譜：$detalle。';
  }

  @override
  String get eliminarCancion => '曲を削除しますか？';

  @override
  String get seBorraDeTuBiblioteca =>
      'ライブラリから削除されます。ルームのセットリストに入っている場合、開けなくなります。';

  @override
  String get eliminar => '削除';

  @override
  String get miRepertorio2 => 'マイレパートリー';

  @override
  String get regenerarCifradosDesdeLosPdf => 'PDFからコード譜を再生成';

  @override
  String get necesitasIniciarSesionParaTener2 => 'ライブラリを持つにはログインが必要です。';

  @override
  String get subirTusPropiasPartiturasEs => '自分の楽譜のアップロードはPro機能です。';

  @override
  String get masInfo => '詳細';

  @override
  String get todaviaNoSubisteNingunaCancion => 'まだ曲をアップロードしていません。';

  @override
  String tonalidad2(Object tonalidad) {
    return 'キー：$tonalidad';
  }

  @override
  String get subirTusPropiasSecuenciasEs =>
      '自分のシーケンスのアップロードはSound Check Proの機能です。Proアカウントを有効にしてご利用ください。';

  @override
  String get archivoDemasiadoGrande => 'ファイルが大きすぎます';

  @override
  String get archivosDemasiadoGrandes => 'ファイルが大きすぎます';

  @override
  String elMaximoPorArchivoEs(Object lista, Object limite) {
    return '$lista\n\n1ファイルの上限は$limiteです。MP3に変換（320 kbpsで1曲あたり約10〜15 MB）して再度アップロードするか、自動変換されるWeb版からアップロードしてください。';
  }

  @override
  String convirtiendoAMp3(Object contador) {
    return 'MP3に変換中$contador';
  }

  @override
  String convirtiendoAMp32(Object porcentaje, Object contador) {
    return 'MP3に変換中 $porcentaje%$contador';
  }

  @override
  String subiendo(Object contador) {
    return 'アップロード中$contador';
  }

  @override
  String get secuenciasSubidas => 'シーケンスをアップロードしました';

  @override
  String get algunasSecuenciasNoSeSubieron => '一部のシーケンスはアップロードされませんでした';

  @override
  String seConvirtieronAMp3Porque(Object limite, Object lista) {
    return '上限の$limiteを超えていたため、MP3に変換しました：\n$lista';
  }

  @override
  String noSePudieronSubir(Object lista) {
    return 'アップロードできませんでした：\n$lista';
  }

  @override
  String get renombrarSecuencia => 'シーケンス名を変更';

  @override
  String get eliminarSecuencia => 'シーケンスを削除';

  @override
  String eliminarDeTuBiblioteca(Object titulo) {
    return '「$titulo」をライブラリから削除しますか？';
  }

  @override
  String get misSecuencias2 => 'マイシーケンス';

  @override
  String get necesitasIniciarSesionParaTener3 => 'シーケンスを持つにはログインが必要です。';

  @override
  String errorAlCargar(Object error) {
    return '読み込みエラー：$error';
  }

  @override
  String get todaviaNoSubisteSecuenciasToca =>
      'シーケンスはまだアップロードされていません。\n下のボタンをタップして音声トラック（MP3、WAV、M4Aなど）をアップロードしてください。';

  @override
  String get subirSecuencias => 'シーケンスをアップロード';

  @override
  String get restablecerTonoOriginal => '元のキーに戻す';

  @override
  String get sincronizadoConTodaLaSala => 'ルーム全体と同期中（タップで同期を解除）';

  @override
  String get desincronizadoCambiosSoloLocalesToca =>
      '同期解除中 — 変更はこの端末のみ（タップで再同期）';

  @override
  String noSePudoCargarEl(Object error) {
    return 'PDFを読み込めませんでした。\n$error';
  }

  @override
  String errorAlIngresarAlPanel(Object error) {
    return 'パネルへの入室エラー：$error';
  }

  @override
  String get accesoSonidista2 => 'PAエンジニア用';

  @override
  String get pinDeSalaOCrear => 'ルームPINまたはルームを作成';

  @override
  String get accederAlPanel => 'パネルに入る';

  @override
  String tuRespuesta(Object respuesta) {
    return 'あなたの返信：$respuesta';
  }

  @override
  String get responderPrivado => '個別に返信';

  @override
  String responderA(Object musico) {
    return '$musicoに返信';
  }

  @override
  String pedido(Object pedido) {
    return 'リクエスト：「$pedido」';
  }

  @override
  String get escribirRespuestaPrivada => '個別の返信を入力...';

  @override
  String get enviar => '送信';

  @override
  String consola2(Object codigoSala) {
    return '卓：$codigoSala';
  }

  @override
  String get borrarTodo => 'すべて消去しますか？';

  @override
  String get no => 'いいえ';

  @override
  String get si => 'はい';

  @override
  String get agrupadoPorRolActivado => '役割別にグループ化：オン';

  @override
  String get verAgrupadoPorRol => '役割別に表示';

  @override
  String errorDeConexion(Object error) {
    return '接続エラー：$error';
  }

  @override
  String get esperandoPedidos => 'リクエスト待機中...';

  @override
  String get todaviaNoAtendisteNingunPedido => 'まだ対応したリクエストはありません';

  @override
  String get nombreApp => 'Sound Check Pro';

  @override
  String get rolMusico => 'ミュージシャン';

  @override
  String get rolCantante => 'ボーカル';

  @override
  String get rolSonidista => 'PAエンジニア';

  @override
  String get rolOtro => 'その他';

  @override
  String rolesYUltimo(String lista, String ultimo) {
    return '$lista、$ultimo';
  }

  @override
  String get paletaEscenarioNombre => 'ステージ';

  @override
  String get paletaEscenarioTag => 'シアンとバイオレットのネオン';

  @override
  String get paletaConsolaNombre => 'コンソール';

  @override
  String get paletaConsolaTag => 'バイオレット、上品';

  @override
  String get paletaPlacaNombre => 'パネル';

  @override
  String get paletaPlacaTag => 'グラファイト + VUアンバー';

  @override
  String get paletaWashNombre => 'ウォッシュ';

  @override
  String get paletaWashTag => '舞台照明のティールブルー';

  @override
  String get paletaLuzDeTrabajoNombre => '作業灯';

  @override
  String get paletaLuzDeTrabajoTag => '最大コントラスト';

  @override
  String get paletaCamarinNombre => '楽屋';

  @override
  String get paletaCamarinTag => 'パステルピンク、やわらか';

  @override
  String get pestanaPedidos => 'リクエスト';

  @override
  String get pestanaHistorial => '履歴';

  @override
  String get pestanaSetlist => 'セットリスト';

  @override
  String get pestanaSecuencias => 'シーケンス';

  @override
  String get fraseVolumenRetorno => 'モニターの音量';

  @override
  String get fraseVolumenAl2 => '2番の音量';

  @override
  String get fraseVolumenAl3 => '3番の音量';

  @override
  String get fraseVolumenAl4 => '4番の音量';

  @override
  String get fraseVolumenGuitarra => 'ギターの音量';

  @override
  String get fraseVolumenTeclado => 'キーボードの音量';

  @override
  String get fraseVolumenTalkback => 'トークバックの音量';

  @override
  String get fraseVolumenPista => 'トラックの音量';

  @override
  String get fraseVolumenClick => 'クリックの音量';

  @override
  String get fraseVolumenCoordinador => 'コーディネーターの音量';

  @override
  String get fraseVolumenGeneral => '全体の音量';

  @override
  String get fraseListo => 'OK';

  @override
  String get tonoOriginal => 'オリジナル';

  @override
  String semitonosConSigno(String signo, int cantidad) {
    String _temp0 = intl.Intl.pluralLogic(
      cantidad,
      locale: localeName,
      other: '$signo$cantidad半音',
    );
    return '$_temp0';
  }

  @override
  String ajusteTono(String valor) {
    return 'キー $valor';
  }

  @override
  String ajusteTempo(int valor) {
    return 'テンポ $valor%';
  }

  @override
  String ajusteVolumen(int valor) {
    return '音量 $valor%';
  }

  @override
  String secuenciasParaHoy(int cantidad) {
    String _temp0 = intl.Intl.pluralLogic(
      cantidad,
      locale: localeName,
      other: '今日のシーケンス $cantidad件',
    );
    return '$_temp0';
  }

  @override
  String get idioma => '言語';

  @override
  String get idiomaAutomatico => '自動（端末の言語）';

  @override
  String get idiomaDescripcion => 'アプリの言語を選択してください。この端末に保存されます。';
}
