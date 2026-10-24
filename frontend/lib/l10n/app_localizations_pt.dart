// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class AppLocalizationsPt extends AppLocalizations {
  AppLocalizationsPt([String locale = 'pt']) : super(locale);

  @override
  String get tuRolPodesMarcarMas => 'Sua função (você pode marcar mais de uma)';

  @override
  String get inicioDeSesionConGoogle => 'Login com o Google cancelado.';

  @override
  String get elEmailNoEsValido => 'O e-mail não é válido.';

  @override
  String get estaCuentaFueDeshabilitada => 'Esta conta foi desativada.';

  @override
  String get noExisteUnaCuentaCon => 'Não existe uma conta com esse e-mail.';

  @override
  String get emailOContrasenaIncorrectos => 'E-mail ou senha incorretos.';

  @override
  String get yaExisteUnaCuentaCon => 'Já existe uma conta com esse e-mail.';

  @override
  String get laContrasenaDebeTenerAl =>
      'A senha deve ter pelo menos 6 caracteres.';

  @override
  String get errorDeAutenticacion => 'Erro de autenticação.';

  @override
  String get pausar => 'Pausar';

  @override
  String get reproducir => 'Reproduzir';

  @override
  String noSePudoReproducir(Object error) {
    return 'Não foi possível reproduzir: $error';
  }

  @override
  String get bajandoElVolumen => 'Reduzindo o volume...';

  @override
  String fadeOutS(Object segundos) {
    return 'Fade out ($segundos s)';
  }

  @override
  String get detener => 'Parar';

  @override
  String get modoClaroOscuroParaEl => 'Modo claro/escuro (para o resto do app)';

  @override
  String get colorDeLaApp => 'Cor do app';

  @override
  String get comunicacionEnVivoEntreMusicos =>
      'Comunicação ao vivo\nentre músicos e técnicos de som';

  @override
  String get iniciarSesion => 'Entrar';

  @override
  String get crearCuenta => 'Criar conta';

  @override
  String get entrarComoInvitado => 'Entrar como convidado';

  @override
  String get tiempoReal => 'Tempo real';

  @override
  String get sincronizacionInstantanea => 'Sincronização\ninstantânea';

  @override
  String get urgente => 'Urgente';

  @override
  String get alertasVisualesYSonoras => 'Alertas visuais\ne sonoros';

  @override
  String get multiSala => 'Multissala';

  @override
  String get manejaVariasBandasYShows => 'Gerencie várias\nbandas e shows';

  @override
  String get setlistEnVivo => 'Setlist ao vivo';

  @override
  String get listaDeTemasCompartida => 'Lista de músicas\ncompartilhada';

  @override
  String get completaEmailYContrasena => 'Preencha e-mail e senha.';

  @override
  String get completaTuPerfil => 'Complete seu perfil';

  @override
  String get tuNombre => 'Seu nome';

  @override
  String get requerido => 'Obrigatório';

  @override
  String get tuRolEjSonidistaGuitarrista =>
      'Sua função (ex.: técnico de som, guitarrista)';

  @override
  String get guardar => 'Salvar';

  @override
  String get recuperarContrasena => 'Recuperar senha';

  @override
  String get tuEmail => 'Seu e-mail';

  @override
  String get cancelar => 'Cancelar';

  @override
  String get enviarEmail => 'Enviar e-mail';

  @override
  String get teEnviamosUnEmailPara =>
      'Enviamos um e-mail para você redefinir sua senha.';

  @override
  String get tuRolEjSonidistaGuitarrista2 =>
      'Sua função (ex.: técnico de som, guitarrista, corista)';

  @override
  String get email => 'E-mail';

  @override
  String get emailInvalido => 'E-mail inválido';

  @override
  String get contrasena => 'Senha';

  @override
  String get minimo6Caracteres => 'Mínimo de 6 caracteres';

  @override
  String get olvidasteTuContrasena => 'Esqueceu a senha?';

  @override
  String get registrarme => 'CADASTRAR';

  @override
  String get iniciarSesion2 => 'ENTRAR';

  @override
  String get yaTenesCuentaIniciarSesion => 'Já tem conta? Entrar';

  @override
  String get noTenesCuentaRegistrarme => 'Não tem conta? Cadastre-se';

  @override
  String get continuarConGoogle => 'Continuar com o Google';

  @override
  String get continuarSinCuenta => 'Continuar sem conta';

  @override
  String get cerrarSesionDeCuenta => 'Sair da conta';

  @override
  String sesion(Object usuario) {
    return 'Sessão: $usuario';
  }

  @override
  String get crearNuevaSala => 'CRIAR NOVA SALA';

  @override
  String get unirmeASala => 'ENTRAR EM UMA SALA';

  @override
  String get misSalas => 'MINHAS SALAS';

  @override
  String get misFrases => 'MINHAS FRASES';

  @override
  String get miRepertorio => 'MEU REPERTÓRIO';

  @override
  String get misSecuencias => 'MINHAS SEQUÊNCIAS';

  @override
  String get accesoSonidista => 'ACESSO DO TÉCNICO DE SOM';

  @override
  String get elegiLaIdentidadVisualDe =>
      'Escolha a identidade visual do app. Fica salva neste dispositivo.';

  @override
  String get marcaAlMenosUnRol => 'Marque pelo menos uma função.';

  @override
  String errorAlIngresar(Object error) {
    return 'Erro ao entrar: $error';
  }

  @override
  String get configurarSala => 'Configurar sala';

  @override
  String get tuPinDeSala => 'PIN da sua sala';

  @override
  String get pinCopiado => 'PIN copiado';

  @override
  String get tuNombre2 => 'Seu nome';

  @override
  String get empezar => 'COMEÇAR';

  @override
  String get unirseASala => 'Entrar em uma sala';

  @override
  String get codigoDeSala8Caracteres => 'Código da sala (8 caracteres)';

  @override
  String get unirme => 'ENTRAR';

  @override
  String get nombreParaEstaSala => 'Nome para esta sala';

  @override
  String get ejBandaXEnsayoJueves => 'Ex.: Banda X - Ensaio de quinta';

  @override
  String get misSalas2 => 'Minhas salas';

  @override
  String get necesitasIniciarSesionParaTener =>
      'Você precisa entrar para ter um histórico de salas.';

  @override
  String get guardarUnHistorialDeVarias =>
      'Guardar um histórico de várias salas/bandas para voltar com um toque é um recurso Pro.';

  @override
  String get todaviaNoEntrasteANinguna =>
      'Você ainda não entrou em nenhuma sala com esta conta.';

  @override
  String get renombrar => 'Renomear';

  @override
  String get quitarDelHistorial => 'Remover do histórico';

  @override
  String get queQueresVerEnLa => 'O que você quer ver na sala?';

  @override
  String get seGuardaEnEsteDispositivo =>
      'Fica salvo neste dispositivo. Precisa sobrar pelo menos uma.';

  @override
  String urgenteEnviado(Object texto) {
    return 'Urgente enviado!: $texto';
  }

  @override
  String enviado(Object texto) {
    return 'Enviado: $texto';
  }

  @override
  String get cerrarSesion => 'Sair';

  @override
  String get codigoDeSalaCopiado => 'Código da sala copiado';

  @override
  String sala(Object codigoSala) {
    return 'SALA: $codigoSala';
  }

  @override
  String get pantallaSiempreEncendidaActivado => 'Tela sempre ligada: ativado';

  @override
  String get pantallaSiempreEncendidaDesactivado =>
      'Tela sempre ligada: desativado';

  @override
  String get elegirQueVerEnLa => 'Escolher o que ver na sala';

  @override
  String get escribirPedidoPersonalizado => 'Escrever pedido personalizado...';

  @override
  String get pedidoUrgenteActivado => 'Pedido urgente: ativado';

  @override
  String get marcarElProximoPedidoComo =>
      'Marcar o próximo pedido como urgente';

  @override
  String get misUltimosPedidos => 'MEUS ÚLTIMOS PEDIDOS';

  @override
  String error(Object error) {
    return 'Erro: $error';
  }

  @override
  String get sinPedidosPropios => 'Nenhum pedido seu';

  @override
  String eliminandoPedido(Object pedido) {
    return 'Excluindo pedido: \"$pedido\"';
  }

  @override
  String consola(Object respuesta) {
    return 'Mesa: $respuesta';
  }

  @override
  String get desdeMiBiblioteca => 'Da minha biblioteca';

  @override
  String get buscarEnBibliotecasDeLa => 'Buscar nas bibliotecas da sala';

  @override
  String get necesitasIniciarSesionParaUsar =>
      'Você precisa entrar para usar sua biblioteca.';

  @override
  String get tuBibliotecaEstaVacia => 'Sua biblioteca está vazia.';

  @override
  String get titulo => 'Título...';

  @override
  String get tonalidad => 'Tom...';

  @override
  String get sinResultados => 'Sem resultados.';

  @override
  String get noSePudoBuscarIntenta =>
      'Não foi possível buscar. Tente de novo em instantes.';

  @override
  String get todaviaNoHayBibliotecasPara =>
      'Ainda não há bibliotecas para buscar nesta sala.';

  @override
  String de(Object propietario) {
    return 'de $propietario';
  }

  @override
  String get elSetlistEstaVacioNo =>
      'O setlist está vazio, não há nada para exportar.';

  @override
  String setlistSala(Object codigoSala) {
    return 'Setlist — Sala $codigoSala\n\n';
  }

  @override
  String get exportarSetlist => 'Exportar setlist';

  @override
  String get copiadoAlPortapapeles => 'Copiado para a área de transferência';

  @override
  String get copiar => 'Copiar';

  @override
  String setlistSala2(Object codigoSala) {
    return 'Setlist - Sala $codigoSala';
  }

  @override
  String get compartir => 'Compartilhar';

  @override
  String get cerrar => 'Fechar';

  @override
  String agregado(Object titulo) {
    return 'Adicionado: $titulo';
  }

  @override
  String get todaviaNoHayTemasEn => 'Ainda não há músicas na lista.';

  @override
  String get cambiarEstadoDelTema => 'Alterar o estado da música';

  @override
  String get pendiente => 'Pendente';

  @override
  String get pausadoCorteTecnico => 'Pausado (parada técnica)';

  @override
  String get tocado => 'Tocada';

  @override
  String get pausado => 'PAUSADO';

  @override
  String get proximo => 'PRÓXIMA';

  @override
  String subidoPor(Object persona) {
    return 'Enviado por $persona';
  }

  @override
  String get verCifradoTransponer => 'Ver cifra (transpor)';

  @override
  String get exportarCompartirSetlist => 'Exportar / compartilhar setlist';

  @override
  String get agregarCancion => 'Adicionar música';

  @override
  String get necesitasIniciarSesionParaUsar2 =>
      'Você precisa entrar para usar suas sequências.';

  @override
  String get noTenesSecuenciasTodaviaSubilas =>
      'Você ainda não tem sequências.\nEnvie-as em \"Minhas sequências\" no menu principal.';

  @override
  String get buscarSecuencia => 'Buscar sequência...';

  @override
  String get yaEstaEnLaSala => 'Já está na sala';

  @override
  String get elegiLasSecuenciasDeHoy => 'Escolha as sequências de hoje';

  @override
  String cargarALaSala(Object cantidad) {
    return 'ADICIONAR $cantidad À SALA';
  }

  @override
  String noSePudieronCargar(Object error) {
    return 'Não foi possível adicionar: $error';
  }

  @override
  String get quitarDeLaSala => 'Remover da sala';

  @override
  String quitarDeLasSecuenciasDe(Object titulo) {
    return 'Remover \"$titulo\" das sequências de hoje? Ela continua na biblioteca de quem a enviou.';
  }

  @override
  String get quitar => 'Remover';

  @override
  String noSePudoGuardarEl(Object error) {
    return 'Não foi possível salvar o ajuste: $error';
  }

  @override
  String get seGuardaParaTodaLa =>
      'Fica salvo para toda a sala. Tom, tempo e volume são alterados separadamente.';

  @override
  String get tono => 'TOM';

  @override
  String get bajarUnSemitono => 'Baixar um semitom';

  @override
  String get subirUnSemitono => 'Subir um semitom';

  @override
  String get elCambioDeTonoPor =>
      'A mudança de tom, por enquanto, só funciona na versão web.';

  @override
  String get tempo => 'TEMPO';

  @override
  String get masLento1 => 'Mais lento (1%)';

  @override
  String get masRapido1 => 'Mais rápido (1%)';

  @override
  String get volumen => 'VOLUME';

  @override
  String get bajar5 => 'Baixar 5%';

  @override
  String get subir5 => 'Subir 5%';

  @override
  String get restablecerComoSeSubio => 'Restaurar (como foi enviada)';

  @override
  String noSePudieronCargarLas(Object error) {
    return 'Não foi possível carregar as sequências: $error';
  }

  @override
  String cargadaPor(Object persona) {
    return 'Adicionada por $persona';
  }

  @override
  String get tonoTempoYVolumen => 'Tom, tempo e volume';

  @override
  String get repetir => 'Repetir';

  @override
  String get todaviaNoHaySecuenciasCargadas =>
      'Ainda não há sequências carregadas para hoje.';

  @override
  String get todaviaNoHaySecuenciasCargadas2 =>
      'Ainda não há sequências carregadas para hoje.\nToque em + para escolhê-las em \"Minhas sequências\".';

  @override
  String get cargarSecuenciasDeHoy => 'Carregar as sequências de hoje';

  @override
  String get nuevaFrase => 'Nova frase';

  @override
  String get textoDeLaFrase => 'Texto da frase';

  @override
  String get agregar => 'Adicionar';

  @override
  String get editarFrase => 'Editar frase';

  @override
  String get misFrases2 => 'Minhas frases';

  @override
  String get necesitasIniciarSesionParaEditar =>
      'Você precisa entrar para editar suas frases.';

  @override
  String get todaviaNoTenesFrasesPropias =>
      'Você ainda não tem frases próprias.';

  @override
  String get cargarFrasesPorDefecto => 'Carregar frases padrão';

  @override
  String get funcionPro => 'Recurso Pro';

  @override
  String get subirTusPropiasPartiturasCifrados =>
      'Enviar suas próprias partituras/cifras em PDF faz parte do Sound Check Pro. Ative sua conta Pro para usar este recurso.';

  @override
  String get entendido => 'Entendi';

  @override
  String errorAlSubir(Object error) {
    return 'Erro ao enviar: $error';
  }

  @override
  String get nuevaCancion => 'Nova música';

  @override
  String get editarCancion => 'Editar música';

  @override
  String get titulo2 => 'Título';

  @override
  String get tonalidadOpcional => 'Tom (opcional)';

  @override
  String get cifradoEnTextoOpcionalPara =>
      'Cifra em texto (opcional, para transpor)';

  @override
  String get pegaLosAcordesAcaEj =>
      'Cole os acordes aqui. Ex.: [C]Amazing [G]grace...';

  @override
  String get regenerarCifrados => 'Regenerar cifras';

  @override
  String get seVaAVolverA =>
      'Cada PDF da sua biblioteca será lido de novo para remontar a cifra com os acordes posicionados como no PDF original.\n\nIsso substitui a cifra em texto guardada em cada música (inclusive o que você editou à mão). As músicas cujo PDF não tem texto selecionável não são alteradas.';

  @override
  String get regenerar => 'Regenerar';

  @override
  String get preparando => 'Preparando...';

  @override
  String procesandoDe(Object hechas, Object total) {
    return 'Processando $hechas de $total...';
  }

  @override
  String actualizadas(Object cantidad) {
    return '$cantidad atualizadas';
  }

  @override
  String sinTextoEnElPdf(Object cantidad) {
    return '$cantidad sem texto no PDF';
  }

  @override
  String conError(Object cantidad) {
    return '$cantidad com erro';
  }

  @override
  String cifrados(Object detalle) {
    return 'Cifras: $detalle.';
  }

  @override
  String get eliminarCancion => 'Excluir música?';

  @override
  String get seBorraDeTuBiblioteca =>
      'Ela será removida da sua biblioteca. Se estiver no setlist de alguma sala, deixará de abrir.';

  @override
  String get eliminar => 'Excluir';

  @override
  String get miRepertorio2 => 'Meu repertório';

  @override
  String get regenerarCifradosDesdeLosPdf =>
      'Regenerar cifras a partir dos PDFs';

  @override
  String get necesitasIniciarSesionParaTener2 =>
      'Você precisa entrar para ter sua biblioteca.';

  @override
  String get subirTusPropiasPartiturasEs =>
      'Enviar suas próprias partituras é um recurso Pro.';

  @override
  String get masInfo => 'Mais informações';

  @override
  String get todaviaNoSubisteNingunaCancion =>
      'Você ainda não enviou nenhuma música.';

  @override
  String tonalidad2(Object tonalidad) {
    return 'Tom: $tonalidad';
  }

  @override
  String get subirTusPropiasSecuenciasEs =>
      'Enviar suas próprias sequências faz parte do Sound Check Pro. Ative sua conta Pro para usar este recurso.';

  @override
  String get archivoDemasiadoGrande => 'Arquivo grande demais';

  @override
  String get archivosDemasiadoGrandes => 'Arquivos grandes demais';

  @override
  String elMaximoPorArchivoEs(Object lista, Object limite) {
    return '$lista\n\nO máximo por arquivo é $limite. Converta para MP3 (a 320 kbps uma música inteira ocupa cerca de 10-15 MB) e envie de novo, ou envie pela versão web, que converte automaticamente.';
  }

  @override
  String convirtiendoAMp3(Object contador) {
    return 'Convertendo para MP3$contador';
  }

  @override
  String convirtiendoAMp32(Object porcentaje, Object contador) {
    return 'Convertendo para MP3 $porcentaje%$contador';
  }

  @override
  String subiendo(Object contador) {
    return 'Enviando$contador';
  }

  @override
  String get secuenciasSubidas => 'Sequências enviadas';

  @override
  String get algunasSecuenciasNoSeSubieron =>
      'Algumas sequências não foram enviadas';

  @override
  String seConvirtieronAMp3Porque(Object limite, Object lista) {
    return 'Foram convertidas para MP3 porque passavam do máximo de $limite:\n$lista';
  }

  @override
  String noSePudieronSubir(Object lista) {
    return 'Não foi possível enviar:\n$lista';
  }

  @override
  String get renombrarSecuencia => 'Renomear sequência';

  @override
  String get eliminarSecuencia => 'Excluir sequência';

  @override
  String eliminarDeTuBiblioteca(Object titulo) {
    return 'Excluir \"$titulo\" da sua biblioteca?';
  }

  @override
  String get misSecuencias2 => 'Minhas sequências';

  @override
  String get necesitasIniciarSesionParaTener3 =>
      'Você precisa entrar para ter sequências.';

  @override
  String errorAlCargar(Object error) {
    return 'Erro ao carregar: $error';
  }

  @override
  String get todaviaNoSubisteSecuenciasToca =>
      'Você ainda não enviou sequências.\nToque no botão abaixo para enviar suas faixas de áudio (MP3, WAV, M4A...).';

  @override
  String get subirSecuencias => 'Enviar sequências';

  @override
  String get restablecerTonoOriginal => 'Restaurar o tom original';

  @override
  String get sincronizadoConTodaLaSala =>
      'Sincronizado com toda a sala (toque para dessincronizar)';

  @override
  String get desincronizadoCambiosSoloLocalesToca =>
      'Dessincronizado — alterações só locais (toque para sincronizar de novo)';

  @override
  String noSePudoCargarEl(Object error) {
    return 'Não foi possível carregar o PDF.\n$error';
  }

  @override
  String errorAlIngresarAlPanel(Object error) {
    return 'Erro ao entrar no painel: $error';
  }

  @override
  String get accesoSonidista2 => 'Acesso do técnico de som';

  @override
  String get pinDeSalaOCrear => 'PIN da sala ou Criar sala';

  @override
  String get accederAlPanel => 'ENTRAR NO PAINEL';

  @override
  String tuRespuesta(Object respuesta) {
    return 'Sua resposta: $respuesta';
  }

  @override
  String get responderPrivado => 'Responder em particular';

  @override
  String responderA(Object musico) {
    return 'Responder a $musico';
  }

  @override
  String pedido(Object pedido) {
    return 'Pedido: \"$pedido\"';
  }

  @override
  String get escribirRespuestaPrivada => 'Escrever resposta particular...';

  @override
  String get enviar => 'Enviar';

  @override
  String consola2(Object codigoSala) {
    return 'Mesa: $codigoSala';
  }

  @override
  String get borrarTodo => 'Apagar tudo?';

  @override
  String get no => 'Não';

  @override
  String get si => 'Sim';

  @override
  String get agrupadoPorRolActivado => 'Agrupado por função: ativado';

  @override
  String get verAgrupadoPorRol => 'Ver agrupado por função';

  @override
  String errorDeConexion(Object error) {
    return 'Erro de conexão: $error';
  }

  @override
  String get esperandoPedidos => 'Aguardando pedidos...';

  @override
  String get todaviaNoAtendisteNingunPedido =>
      'Você ainda não atendeu nenhum pedido';

  @override
  String get nombreApp => 'Sound Check Pro';

  @override
  String get rolMusico => 'Músico';

  @override
  String get rolCantante => 'Cantor';

  @override
  String get rolSonidista => 'Técnico de som';

  @override
  String get rolOtro => 'Outro';

  @override
  String rolesYUltimo(String lista, String ultimo) {
    return '$lista e $ultimo';
  }

  @override
  String get paletaEscenarioNombre => 'Palco';

  @override
  String get paletaEscenarioTag => 'Neon ciano e violeta';

  @override
  String get paletaConsolaNombre => 'Mesa';

  @override
  String get paletaConsolaTag => 'Violeta, refinado';

  @override
  String get paletaPlacaNombre => 'Placa';

  @override
  String get paletaPlacaTag => 'Grafite + âmbar VU';

  @override
  String get paletaWashNombre => 'Wash';

  @override
  String get paletaWashTag => 'Azul-petróleo de luz de palco';

  @override
  String get paletaLuzDeTrabajoNombre => 'Luz de trabalho';

  @override
  String get paletaLuzDeTrabajoTag => 'Contraste máximo';

  @override
  String get paletaCamarinNombre => 'Camarim';

  @override
  String get paletaCamarinTag => 'Rosa pastel, suave';

  @override
  String get pestanaPedidos => 'Pedidos';

  @override
  String get pestanaHistorial => 'Histórico';

  @override
  String get pestanaSetlist => 'Setlist';

  @override
  String get pestanaSecuencias => 'Sequências';

  @override
  String get fraseVolumenRetorno => 'Volume do retorno';

  @override
  String get fraseVolumenAl2 => 'Volume no 2';

  @override
  String get fraseVolumenAl3 => 'Volume no 3';

  @override
  String get fraseVolumenAl4 => 'Volume no 4';

  @override
  String get fraseVolumenGuitarra => 'Volume da guitarra';

  @override
  String get fraseVolumenTeclado => 'Volume do teclado';

  @override
  String get fraseVolumenTalkback => 'Volume do talkback';

  @override
  String get fraseVolumenPista => 'Volume da pista';

  @override
  String get fraseVolumenClick => 'Volume do click';

  @override
  String get fraseVolumenCoordinador => 'Volume do coordenador';

  @override
  String get fraseVolumenGeneral => 'Volume geral';

  @override
  String get fraseListo => 'Pronto';

  @override
  String get tonoOriginal => 'Original';

  @override
  String semitonosConSigno(String signo, int cantidad) {
    String _temp0 = intl.Intl.pluralLogic(
      cantidad,
      locale: localeName,
      other: '$signo$cantidad semitons',
      one: '$signo$cantidad semitom',
    );
    return '$_temp0';
  }

  @override
  String ajusteTono(String valor) {
    return 'Tom $valor';
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
      other: '$cantidad sequências para hoje',
      one: '1 sequência para hoje',
    );
    return '$_temp0';
  }

  @override
  String get idioma => 'Idioma';

  @override
  String get idiomaDescripcion =>
      'Escolha o idioma do app. Fica salvo neste dispositivo.';

  @override
  String get escribiTuRol => 'Escreva sua função.';

  @override
  String get configuracion => 'Configurações';

  @override
  String get colores => 'Cores';

  @override
  String get escribiTuNombre => 'Escreva seu nome.';

  @override
  String get escribiElPin => 'Digite o PIN da sala.';

  @override
  String get pinDe8Caracteres => 'O código tem 8 caracteres.';

  @override
  String get errorSinConexion =>
      'Sem conexão. Verifique sua internet e tente de novo.';

  @override
  String get errorSinPermiso => 'Você não tem permissão para fazer isso.';

  @override
  String get errorGenerico => 'Algo deu errado. Tente de novo.';

  @override
  String get reintentar => 'Tentar de novo';

  @override
  String get deshacer => 'Desfazer';

  @override
  String get pedidoEliminado => 'Pedido excluído';

  @override
  String get marcarAtendido => 'Marcar como atendido';

  @override
  String get salirDeLaSala => 'Sair da sala';

  @override
  String get salirDeLaSalaPregunta => 'Sair da sala?';

  @override
  String get salirDeLaSalaDetalle =>
      'Para voltar você vai precisar do código da sala.';

  @override
  String get salir => 'Sair';

  @override
  String get fraseMasVolumen => 'Mais volume';

  @override
  String get fraseMenosVolumen => 'Menos volume';

  @override
  String get borrarBusqueda => 'Limpar busca';

  @override
  String get borrarTodosLosPedidos => 'Excluir todos os pedidos';

  @override
  String get entrarComoSonidistaPregunta => 'Entrar como técnico de som?';

  @override
  String get entrarComoSonidistaDetalle =>
      'Sua função menciona som. Você pode entrar no painel do técnico de som ou na tela de pedidos.';

  @override
  String get panelDelSonidista => 'Painel do técnico de som';

  @override
  String get pantallaDePedidos => 'Tela de pedidos';

  @override
  String get pedidoYaNoExiste => 'Esse pedido não existe mais.';

  @override
  String get noHayAcordesParaTransponer =>
      'Nenhum acorde encontrado para transpor.';

  @override
  String ajustadoPor(String persona) {
    return 'Ajustado por $persona';
  }

  @override
  String get sinConexionAviso =>
      'Sem conexão. Os pedidos serão enviados quando a rede voltar.';

  @override
  String get pedidoPendienteSinConexion =>
      'Sem conexão: o pedido será enviado quando a rede voltar. Não feche o app.';

  @override
  String get noSePudoEnviarPedido => 'Não foi possível enviar o pedido.';

  @override
  String versionApp(String version) {
    return 'Versão $version';
  }

  @override
  String get compartirEnlaceSala => 'Compartilhar link da sala';

  @override
  String enlaceSalaTexto(String enlace) {
    return 'Entre na minha sala no Sound Check Pro: $enlace';
  }
}
