// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get tuRolPodesMarcarMas =>
      'Votre rôle (vous pouvez en cocher plusieurs)';

  @override
  String get inicioDeSesionConGoogle => 'Connexion avec Google annulée.';

  @override
  String get elEmailNoEsValido => 'L’e-mail n’est pas valide.';

  @override
  String get estaCuentaFueDeshabilitada => 'Ce compte a été désactivé.';

  @override
  String get noExisteUnaCuentaCon => 'Aucun compte n’existe avec cet e-mail.';

  @override
  String get emailOContrasenaIncorrectos => 'E-mail ou mot de passe incorrect.';

  @override
  String get yaExisteUnaCuentaCon => 'Un compte existe déjà avec cet e-mail.';

  @override
  String get laContrasenaDebeTenerAl =>
      'Le mot de passe doit contenir au moins 6 caractères.';

  @override
  String get errorDeAutenticacion => 'Erreur d’authentification.';

  @override
  String get pausar => 'Pause';

  @override
  String get reproducir => 'Lire';

  @override
  String noSePudoReproducir(Object error) {
    return 'Lecture impossible : $error';
  }

  @override
  String get bajandoElVolumen => 'Baisse du volume...';

  @override
  String fadeOutS(Object segundos) {
    return 'Fondu de sortie ($segundos s)';
  }

  @override
  String get detener => 'Arrêter';

  @override
  String get modoClaroOscuroParaEl =>
      'Mode clair/sombre (pour le reste de l’app)';

  @override
  String get colorDeLaApp => 'Couleur de l’app';

  @override
  String get comunicacionEnVivoEntreMusicos =>
      'Communication en direct\nentre musiciens et ingénieurs du son';

  @override
  String get iniciarSesion => 'Se connecter';

  @override
  String get crearCuenta => 'Créer un compte';

  @override
  String get entrarComoInvitado => 'Entrer en tant qu’invité';

  @override
  String get tiempoReal => 'Temps réel';

  @override
  String get sincronizacionInstantanea => 'Synchronisation\ninstantanée';

  @override
  String get urgente => 'Urgent';

  @override
  String get alertasVisualesYSonoras => 'Alertes visuelles\net sonores';

  @override
  String get multiSala => 'Multi-salle';

  @override
  String get manejaVariasBandasYShows => 'Gérez plusieurs\ngroupes et concerts';

  @override
  String get setlistEnVivo => 'Setlist en direct';

  @override
  String get listaDeTemasCompartida => 'Liste de morceaux\npartagée';

  @override
  String get completaEmailYContrasena =>
      'Renseignez l’e-mail et le mot de passe.';

  @override
  String get completaTuPerfil => 'Complétez votre profil';

  @override
  String get tuNombre => 'Votre nom';

  @override
  String get requerido => 'Obligatoire';

  @override
  String get tuRolEjSonidistaGuitarrista =>
      'Votre rôle (ex. : ingé son, guitariste)';

  @override
  String get guardar => 'Enregistrer';

  @override
  String get recuperarContrasena => 'Récupérer le mot de passe';

  @override
  String get tuEmail => 'Votre e-mail';

  @override
  String get cancelar => 'Annuler';

  @override
  String get enviarEmail => 'Envoyer l’e-mail';

  @override
  String get teEnviamosUnEmailPara =>
      'Nous vous avons envoyé un e-mail pour réinitialiser votre mot de passe.';

  @override
  String get tuRolEjSonidistaGuitarrista2 =>
      'Votre rôle (ex. : ingé son, guitariste, choriste)';

  @override
  String get email => 'E-mail';

  @override
  String get emailInvalido => 'E-mail invalide';

  @override
  String get contrasena => 'Mot de passe';

  @override
  String get minimo6Caracteres => '6 caractères minimum';

  @override
  String get olvidasteTuContrasena => 'Mot de passe oublié ?';

  @override
  String get registrarme => 'S’INSCRIRE';

  @override
  String get iniciarSesion2 => 'SE CONNECTER';

  @override
  String get yaTenesCuentaIniciarSesion => 'Déjà un compte ? Connectez-vous';

  @override
  String get noTenesCuentaRegistrarme => 'Pas de compte ? Inscrivez-vous';

  @override
  String get continuarConGoogle => 'Continuer avec Google';

  @override
  String get continuarSinCuenta => 'Continuer sans compte';

  @override
  String get cerrarSesionDeCuenta => 'Se déconnecter du compte';

  @override
  String sesion(Object usuario) {
    return 'Session : $usuario';
  }

  @override
  String get crearNuevaSala => 'CRÉER UNE NOUVELLE SALLE';

  @override
  String get unirmeASala => 'REJOINDRE UNE SALLE';

  @override
  String get misSalas => 'MES SALLES';

  @override
  String get misFrases => 'MES PHRASES';

  @override
  String get miRepertorio => 'MON RÉPERTOIRE';

  @override
  String get misSecuencias => 'MES SÉQUENCES';

  @override
  String get accesoSonidista => 'ACCÈS INGÉ SON';

  @override
  String get elegiLaIdentidadVisualDe =>
      'Choisissez l’identité visuelle de l’app. Elle est conservée sur cet appareil.';

  @override
  String get marcaAlMenosUnRol => 'Cochez au moins un rôle.';

  @override
  String errorAlIngresar(Object error) {
    return 'Erreur de connexion : $error';
  }

  @override
  String get configurarSala => 'Configurer la salle';

  @override
  String get tuPinDeSala => 'Le PIN de votre salle';

  @override
  String get pinCopiado => 'PIN copié';

  @override
  String get tuNombre2 => 'Votre nom';

  @override
  String get empezar => 'COMMENCER';

  @override
  String get unirseASala => 'Rejoindre une salle';

  @override
  String get codigoDeSala8Caracteres => 'Code de la salle (8 caractères)';

  @override
  String get unirme => 'REJOINDRE';

  @override
  String get nombreParaEstaSala => 'Nom de cette salle';

  @override
  String get ejBandaXEnsayoJueves => 'Ex. : Groupe X - Répétition du jeudi';

  @override
  String get misSalas2 => 'Mes salles';

  @override
  String get necesitasIniciarSesionParaTener =>
      'Vous devez vous connecter pour avoir un historique de salles.';

  @override
  String get guardarUnHistorialDeVarias =>
      'Garder un historique de plusieurs salles/groupes pour y revenir en un clic est une fonction Pro.';

  @override
  String get todaviaNoEntrasteANinguna =>
      'Vous n’avez encore rejoint aucune salle avec ce compte.';

  @override
  String get renombrar => 'Renommer';

  @override
  String get quitarDelHistorial => 'Retirer de l’historique';

  @override
  String get queQueresVerEnLa => 'Que voulez-vous voir dans la salle ?';

  @override
  String get seGuardaEnEsteDispositivo =>
      'Conservé sur cet appareil. Il doit en rester au moins une.';

  @override
  String urgenteEnviado(Object texto) {
    return 'Urgent envoyé ! : $texto';
  }

  @override
  String enviado(Object texto) {
    return 'Envoyé : $texto';
  }

  @override
  String get cerrarSesion => 'Se déconnecter';

  @override
  String get codigoDeSalaCopiado => 'Code de la salle copié';

  @override
  String sala(Object codigoSala) {
    return 'SALLE : $codigoSala';
  }

  @override
  String get pantallaSiempreEncendidaActivado =>
      'Écran toujours allumé : activé';

  @override
  String get pantallaSiempreEncendidaDesactivado =>
      'Écran toujours allumé : désactivé';

  @override
  String get elegirQueVerEnLa => 'Choisir ce qu’on voit dans la salle';

  @override
  String get escribirPedidoPersonalizado =>
      'Écrire une demande personnalisée...';

  @override
  String get pedidoUrgenteActivado => 'Demande urgente : activée';

  @override
  String get marcarElProximoPedidoComo =>
      'Marquer la prochaine demande comme urgente';

  @override
  String get misUltimosPedidos => 'MES DERNIÈRES DEMANDES';

  @override
  String error(Object error) {
    return 'Erreur : $error';
  }

  @override
  String get sinPedidosPropios => 'Aucune demande de votre part';

  @override
  String eliminandoPedido(Object pedido) {
    return 'Suppression de la demande : « $pedido »';
  }

  @override
  String consola(Object respuesta) {
    return 'Console : $respuesta';
  }

  @override
  String get desdeMiBiblioteca => 'Depuis ma bibliothèque';

  @override
  String get buscarEnBibliotecasDeLa =>
      'Chercher dans les bibliothèques de la salle';

  @override
  String get necesitasIniciarSesionParaUsar =>
      'Vous devez vous connecter pour utiliser votre bibliothèque.';

  @override
  String get tuBibliotecaEstaVacia => 'Votre bibliothèque est vide.';

  @override
  String get titulo => 'Titre...';

  @override
  String get tonalidad => 'Tonalité...';

  @override
  String get sinResultados => 'Aucun résultat.';

  @override
  String get noSePudoBuscarIntenta =>
      'Recherche impossible. Réessayez dans un instant.';

  @override
  String get todaviaNoHayBibliotecasPara =>
      'Aucune bibliothèque à explorer dans cette salle pour l’instant.';

  @override
  String de(Object propietario) {
    return 'de $propietario';
  }

  @override
  String get elSetlistEstaVacioNo =>
      'La setlist est vide, il n’y a rien à exporter.';

  @override
  String setlistSala(Object codigoSala) {
    return 'Setlist — Salle $codigoSala\n\n';
  }

  @override
  String get exportarSetlist => 'Exporter la setlist';

  @override
  String get copiadoAlPortapapeles => 'Copié dans le presse-papiers';

  @override
  String get copiar => 'Copier';

  @override
  String setlistSala2(Object codigoSala) {
    return 'Setlist - Salle $codigoSala';
  }

  @override
  String get compartir => 'Partager';

  @override
  String get cerrar => 'Fermer';

  @override
  String agregado(Object titulo) {
    return 'Ajouté : $titulo';
  }

  @override
  String get todaviaNoHayTemasEn =>
      'Aucun morceau dans la liste pour l’instant.';

  @override
  String get cambiarEstadoDelTema => 'Changer l’état du morceau';

  @override
  String get pendiente => 'En attente';

  @override
  String get pausadoCorteTecnico => 'En pause (arrêt technique)';

  @override
  String get tocado => 'Joué';

  @override
  String get pausado => 'EN PAUSE';

  @override
  String get proximo => 'SUIVANT';

  @override
  String subidoPor(Object persona) {
    return 'Ajouté par $persona';
  }

  @override
  String get verCifradoTransponer => 'Voir les accords (transposer)';

  @override
  String get exportarCompartirSetlist => 'Exporter / partager la setlist';

  @override
  String get agregarCancion => 'Ajouter un morceau';

  @override
  String get necesitasIniciarSesionParaUsar2 =>
      'Vous devez vous connecter pour utiliser vos séquences.';

  @override
  String get noTenesSecuenciasTodaviaSubilas =>
      'Vous n’avez pas encore de séquences.\nImportez-les dans « Mes séquences » depuis le menu principal.';

  @override
  String get buscarSecuencia => 'Chercher une séquence...';

  @override
  String get yaEstaEnLaSala => 'Déjà dans la salle';

  @override
  String get elegiLasSecuenciasDeHoy => 'Choisissez les séquences du jour';

  @override
  String cargarALaSala(Object cantidad) {
    return 'AJOUTER $cantidad À LA SALLE';
  }

  @override
  String noSePudieronCargar(Object error) {
    return 'Impossible d’ajouter : $error';
  }

  @override
  String get quitarDeLaSala => 'Retirer de la salle';

  @override
  String quitarDeLasSecuenciasDe(Object titulo) {
    return 'Retirer « $titulo » des séquences du jour ? Elle reste dans la bibliothèque de la personne qui l’a importée.';
  }

  @override
  String get quitar => 'Retirer';

  @override
  String noSePudoGuardarEl(Object error) {
    return 'Impossible d’enregistrer le réglage : $error';
  }

  @override
  String get seGuardaParaTodaLa =>
      'Enregistré pour toute la salle. Tonalité, tempo et volume se règlent séparément.';

  @override
  String get tono => 'TONALITÉ';

  @override
  String get bajarUnSemitono => 'Baisser d’un demi-ton';

  @override
  String get subirUnSemitono => 'Monter d’un demi-ton';

  @override
  String get elCambioDeTonoPor =>
      'Le changement de tonalité ne fonctionne pour l’instant que sur la version web.';

  @override
  String get tempo => 'TEMPO';

  @override
  String get masLento1 => 'Plus lent (1 %)';

  @override
  String get masRapido1 => 'Plus rapide (1 %)';

  @override
  String get volumen => 'VOLUME';

  @override
  String get bajar5 => 'Baisser de 5 %';

  @override
  String get subir5 => 'Monter de 5 %';

  @override
  String get restablecerComoSeSubio => 'Réinitialiser (comme à l’import)';

  @override
  String noSePudieronCargarLas(Object error) {
    return 'Impossible de charger les séquences : $error';
  }

  @override
  String cargadaPor(Object persona) {
    return 'Ajoutée par $persona';
  }

  @override
  String get tonoTempoYVolumen => 'Tonalité, tempo et volume';

  @override
  String get repetir => 'Répéter';

  @override
  String get todaviaNoHaySecuenciasCargadas =>
      'Aucune séquence chargée pour aujourd’hui.';

  @override
  String get todaviaNoHaySecuenciasCargadas2 =>
      'Aucune séquence chargée pour aujourd’hui.\nAppuyez sur + pour les choisir dans « Mes séquences ».';

  @override
  String get cargarSecuenciasDeHoy => 'Charger les séquences du jour';

  @override
  String get nuevaFrase => 'Nouvelle phrase';

  @override
  String get textoDeLaFrase => 'Texte de la phrase';

  @override
  String get agregar => 'Ajouter';

  @override
  String get editarFrase => 'Modifier la phrase';

  @override
  String get misFrases2 => 'Mes phrases';

  @override
  String get necesitasIniciarSesionParaEditar =>
      'Vous devez vous connecter pour modifier vos phrases.';

  @override
  String get todaviaNoTenesFrasesPropias =>
      'Vous n’avez pas encore de phrases personnelles.';

  @override
  String get cargarFrasesPorDefecto => 'Charger les phrases par défaut';

  @override
  String get funcionPro => 'Fonction Pro';

  @override
  String get subirTusPropiasPartiturasCifrados =>
      'Importer vos propres partitions/grilles d’accords en PDF fait partie de Sound Check Pro. Activez votre compte Pro pour utiliser cette fonction.';

  @override
  String get entendido => 'Compris';

  @override
  String errorAlSubir(Object error) {
    return 'Erreur lors de l’import : $error';
  }

  @override
  String get nuevaCancion => 'Nouveau morceau';

  @override
  String get editarCancion => 'Modifier le morceau';

  @override
  String get titulo2 => 'Titre';

  @override
  String get tonalidadOpcional => 'Tonalité (facultatif)';

  @override
  String get cifradoEnTextoOpcionalPara =>
      'Accords en texte (facultatif, pour transposer)';

  @override
  String get pegaLosAcordesAcaEj =>
      'Collez les accords ici. Ex. : [C]Amazing [G]grace...';

  @override
  String get regenerarCifrados => 'Régénérer les accords';

  @override
  String get seVaAVolverA =>
      'Chaque PDF de votre bibliothèque sera relu pour reconstruire la grille d’accords, avec les accords placés comme dans le PDF d’origine.\n\nCela remplace la grille en texte enregistrée pour chaque morceau (y compris ce que vous avez modifié à la main). Les morceaux dont le PDF n’a pas de texte sélectionnable ne sont pas modifiés.';

  @override
  String get regenerar => 'Régénérer';

  @override
  String get preparando => 'Préparation...';

  @override
  String procesandoDe(Object hechas, Object total) {
    return 'Traitement $hechas sur $total...';
  }

  @override
  String actualizadas(Object cantidad) {
    return '$cantidad mis à jour';
  }

  @override
  String sinTextoEnElPdf(Object cantidad) {
    return '$cantidad sans texte dans le PDF';
  }

  @override
  String conError(Object cantidad) {
    return '$cantidad en erreur';
  }

  @override
  String cifrados(Object detalle) {
    return 'Accords : $detalle.';
  }

  @override
  String get eliminarCancion => 'Supprimer le morceau ?';

  @override
  String get seBorraDeTuBiblioteca =>
      'Il sera supprimé de votre bibliothèque. S’il figure dans la setlist d’une salle, il ne s’ouvrira plus.';

  @override
  String get eliminar => 'Supprimer';

  @override
  String get miRepertorio2 => 'Mon répertoire';

  @override
  String get regenerarCifradosDesdeLosPdf =>
      'Régénérer les accords à partir des PDF';

  @override
  String get necesitasIniciarSesionParaTener2 =>
      'Vous devez vous connecter pour avoir votre bibliothèque.';

  @override
  String get subirTusPropiasPartiturasEs =>
      'Importer vos propres partitions est une fonction Pro.';

  @override
  String get masInfo => 'Plus d’infos';

  @override
  String get todaviaNoSubisteNingunaCancion =>
      'Vous n’avez encore importé aucun morceau.';

  @override
  String tonalidad2(Object tonalidad) {
    return 'Tonalité : $tonalidad';
  }

  @override
  String get subirTusPropiasSecuenciasEs =>
      'Importer vos propres séquences fait partie de Sound Check Pro. Activez votre compte Pro pour utiliser cette fonction.';

  @override
  String get archivoDemasiadoGrande => 'Fichier trop volumineux';

  @override
  String get archivosDemasiadoGrandes => 'Fichiers trop volumineux';

  @override
  String elMaximoPorArchivoEs(Object lista, Object limite) {
    return '$lista\n\nLe maximum par fichier est de $limite. Convertissez en MP3 (à 320 kbps, un morceau entier fait environ 10 à 15 Mo) et réimportez, ou importez depuis la version web, qui convertit automatiquement.';
  }

  @override
  String convirtiendoAMp3(Object contador) {
    return 'Conversion en MP3$contador';
  }

  @override
  String convirtiendoAMp32(Object porcentaje, Object contador) {
    return 'Conversion en MP3 $porcentaje %$contador';
  }

  @override
  String subiendo(Object contador) {
    return 'Import en cours$contador';
  }

  @override
  String get secuenciasSubidas => 'Séquences importées';

  @override
  String get algunasSecuenciasNoSeSubieron =>
      'Certaines séquences n’ont pas été importées';

  @override
  String seConvirtieronAMp3Porque(Object limite, Object lista) {
    return 'Converties en MP3 car elles dépassaient le maximum de $limite :\n$lista';
  }

  @override
  String noSePudieronSubir(Object lista) {
    return 'Import impossible :\n$lista';
  }

  @override
  String get renombrarSecuencia => 'Renommer la séquence';

  @override
  String get eliminarSecuencia => 'Supprimer la séquence';

  @override
  String eliminarDeTuBiblioteca(Object titulo) {
    return 'Supprimer « $titulo » de votre bibliothèque ?';
  }

  @override
  String get misSecuencias2 => 'Mes séquences';

  @override
  String get necesitasIniciarSesionParaTener3 =>
      'Vous devez vous connecter pour avoir des séquences.';

  @override
  String errorAlCargar(Object error) {
    return 'Erreur de chargement : $error';
  }

  @override
  String get todaviaNoSubisteSecuenciasToca =>
      'Vous n’avez pas encore importé de séquences.\nAppuyez sur le bouton ci-dessous pour importer vos pistes audio (MP3, WAV, M4A...).';

  @override
  String get subirSecuencias => 'Importer des séquences';

  @override
  String get restablecerTonoOriginal => 'Rétablir la tonalité d’origine';

  @override
  String get sincronizadoConTodaLaSala =>
      'Synchronisé avec toute la salle (touchez pour désynchroniser)';

  @override
  String get desincronizadoCambiosSoloLocalesToca =>
      'Désynchronisé — modifications locales uniquement (touchez pour resynchroniser)';

  @override
  String noSePudoCargarEl(Object error) {
    return 'Impossible de charger le PDF.\n$error';
  }

  @override
  String errorAlIngresarAlPanel(Object error) {
    return 'Erreur d’accès au panneau : $error';
  }

  @override
  String get accesoSonidista2 => 'Accès ingé son';

  @override
  String get pinDeSalaOCrear => 'PIN de la salle ou Créer une salle';

  @override
  String get accederAlPanel => 'ACCÉDER AU PANNEAU';

  @override
  String tuRespuesta(Object respuesta) {
    return 'Votre réponse : $respuesta';
  }

  @override
  String get responderPrivado => 'Répondre en privé';

  @override
  String responderA(Object musico) {
    return 'Répondre à $musico';
  }

  @override
  String pedido(Object pedido) {
    return 'Demande : « $pedido »';
  }

  @override
  String get escribirRespuestaPrivada => 'Écrire une réponse privée...';

  @override
  String get enviar => 'Envoyer';

  @override
  String consola2(Object codigoSala) {
    return 'Console : $codigoSala';
  }

  @override
  String get borrarTodo => 'Tout effacer ?';

  @override
  String get no => 'Non';

  @override
  String get si => 'Oui';

  @override
  String get agrupadoPorRolActivado => 'Groupé par rôle : activé';

  @override
  String get verAgrupadoPorRol => 'Afficher groupé par rôle';

  @override
  String errorDeConexion(Object error) {
    return 'Erreur de connexion : $error';
  }

  @override
  String get esperandoPedidos => 'En attente de demandes...';

  @override
  String get todaviaNoAtendisteNingunPedido =>
      'Vous n’avez traité aucune demande pour l’instant';

  @override
  String get nombreApp => 'Sound Check Pro';

  @override
  String get rolMusico => 'Musicien';

  @override
  String get rolCantante => 'Chanteur';

  @override
  String get rolSonidista => 'Ingénieur du son';

  @override
  String get rolOtro => 'Autre';

  @override
  String rolesYUltimo(String lista, String ultimo) {
    return '$lista et $ultimo';
  }

  @override
  String get paletaEscenarioNombre => 'Scène';

  @override
  String get paletaEscenarioTag => 'Néon cyan et violet';

  @override
  String get paletaConsolaNombre => 'Console';

  @override
  String get paletaConsolaTag => 'Violet, raffiné';

  @override
  String get paletaPlacaNombre => 'Plaque';

  @override
  String get paletaPlacaTag => 'Graphite + ambre VU';

  @override
  String get paletaWashNombre => 'Wash';

  @override
  String get paletaWashTag => 'Bleu canard de projecteur';

  @override
  String get paletaLuzDeTrabajoNombre => 'Lumière de service';

  @override
  String get paletaLuzDeTrabajoTag => 'Contraste maximal';

  @override
  String get paletaCamarinNombre => 'Loge';

  @override
  String get paletaCamarinTag => 'Rose pastel, doux';

  @override
  String get pestanaPedidos => 'Demandes';

  @override
  String get pestanaHistorial => 'Historique';

  @override
  String get pestanaSetlist => 'Setlist';

  @override
  String get pestanaSecuencias => 'Séquences';

  @override
  String get fraseVolumenRetorno => 'Volume du retour';

  @override
  String get fraseVolumenAl2 => 'Volume sur le 2';

  @override
  String get fraseVolumenAl3 => 'Volume sur le 3';

  @override
  String get fraseVolumenAl4 => 'Volume sur le 4';

  @override
  String get fraseVolumenGuitarra => 'Volume de la guitare';

  @override
  String get fraseVolumenTeclado => 'Volume du clavier';

  @override
  String get fraseVolumenTalkback => 'Volume du talkback';

  @override
  String get fraseVolumenPista => 'Volume de la piste';

  @override
  String get fraseVolumenClick => 'Volume du clic';

  @override
  String get fraseVolumenCoordinador => 'Volume du coordinateur';

  @override
  String get fraseVolumenGeneral => 'Volume général';

  @override
  String get fraseListo => 'Prêt';

  @override
  String get tonoOriginal => 'Original';

  @override
  String semitonosConSigno(String signo, int cantidad) {
    String _temp0 = intl.Intl.pluralLogic(
      cantidad,
      locale: localeName,
      other: '$signo$cantidad demi-tons',
      one: '$signo$cantidad demi-ton',
    );
    return '$_temp0';
  }

  @override
  String ajusteTono(String valor) {
    return 'Tonalité $valor';
  }

  @override
  String ajusteTempo(int valor) {
    return 'Tempo $valor %';
  }

  @override
  String ajusteVolumen(int valor) {
    return 'Vol $valor %';
  }

  @override
  String secuenciasParaHoy(int cantidad) {
    String _temp0 = intl.Intl.pluralLogic(
      cantidad,
      locale: localeName,
      other: '$cantidad séquences pour aujourd’hui',
      one: '1 séquence pour aujourd’hui',
    );
    return '$_temp0';
  }

  @override
  String get idioma => 'Langue';

  @override
  String get idiomaDescripcion =>
      'Choisissez la langue de l’app. Elle est conservée sur cet appareil.';

  @override
  String get escribiTuRol => 'Saisissez votre rôle.';

  @override
  String get configuracion => 'Paramètres';

  @override
  String get colores => 'Couleurs';

  @override
  String get escribiTuNombre => 'Saisissez votre nom.';

  @override
  String get escribiElPin => 'Saisissez le PIN de la salle.';

  @override
  String get pinDe8Caracteres => 'Le code comporte 8 caractères.';

  @override
  String get errorSinConexion =>
      'Pas de connexion. Vérifiez votre internet et réessayez.';

  @override
  String get errorSinPermiso => 'Vous n’avez pas l’autorisation de faire cela.';

  @override
  String get errorGenerico => 'Une erreur s’est produite. Réessayez.';

  @override
  String get reintentar => 'Réessayer';

  @override
  String get deshacer => 'Annuler';

  @override
  String get pedidoEliminado => 'Demande supprimée';

  @override
  String get marcarAtendido => 'Marquer comme traitée';

  @override
  String get salirDeLaSala => 'Quitter la salle';

  @override
  String get salirDeLaSalaPregunta => 'Quitter la salle ?';

  @override
  String get salirDeLaSalaDetalle =>
      'Pour revenir, vous aurez besoin du code de la salle.';

  @override
  String get salir => 'Quitter';

  @override
  String get fraseMasVolumen => 'Plus de volume';

  @override
  String get fraseMenosVolumen => 'Moins de volume';

  @override
  String get borrarBusqueda => 'Effacer la recherche';

  @override
  String get borrarTodosLosPedidos => 'Supprimer toutes les demandes';

  @override
  String get entrarComoSonidistaPregunta =>
      'Entrer en tant qu’ingénieur du son ?';

  @override
  String get entrarComoSonidistaDetalle =>
      'Votre rôle mentionne le son. Vous pouvez entrer dans le panneau de l’ingénieur du son ou sur l’écran des demandes.';

  @override
  String get panelDelSonidista => 'Panneau de l’ingénieur du son';

  @override
  String get pantallaDePedidos => 'Écran des demandes';

  @override
  String get pedidoYaNoExiste => 'Cette demande n’existe plus.';

  @override
  String get noHayAcordesParaTransponer => 'Aucun accord à transposer.';

  @override
  String ajustadoPor(String persona) {
    return 'Réglé par $persona';
  }

  @override
  String get sinConexionAviso =>
      'Pas de connexion. Les demandes seront envoyées au retour du réseau.';

  @override
  String get pedidoPendienteSinConexion =>
      'Pas de connexion : la demande sera envoyée au retour du réseau. Ne fermez pas l’app.';

  @override
  String get noSePudoEnviarPedido => 'La demande n’a pas pu être envoyée.';

  @override
  String versionApp(String version) {
    return 'Version $version';
  }

  @override
  String get compartirEnlaceSala => 'Partager le lien de la salle';

  @override
  String enlaceSalaTexto(String enlace) {
    return 'Rejoignez ma salle sur Sound Check Pro : $enlace';
  }

  @override
  String get salaQuitadaDelHistorial => 'Salle retirée de l’historique';

  @override
  String get eliminarCuenta => 'Supprimer mon compte';

  @override
  String get eliminarCuentaExplicacion =>
      'Votre compte, votre profil, vos phrases, votre répertoire et vos séquences (avec les fichiers importés) ainsi que votre historique de salles seront supprimés définitivement. Cette action est irréversible. Les demandes et les salles partagées avec d’autres personnes ne sont pas supprimées.';

  @override
  String get eliminarCuentaContrasena => 'Mot de passe actuel (pour confirmer)';

  @override
  String get eliminarDefinitivamente => 'Supprimer définitivement';

  @override
  String get eliminarCuentaPregunta => 'Supprimer votre compte pour toujours ?';

  @override
  String get eliminandoCuenta => 'Suppression de votre compte…';

  @override
  String get cuentaEliminada => 'Votre compte et vos données ont été supprimés';

  @override
  String get noSePudoEliminarCuenta =>
      'Impossible de supprimer le compte. Vérifiez votre connexion et réessayez.';
}
