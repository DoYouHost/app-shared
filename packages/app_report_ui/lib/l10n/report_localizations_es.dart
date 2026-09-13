// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'report_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class ReportLocalizationsEs extends ReportLocalizations {
  ReportLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get bugReportTitle => 'Informar de un error o una idea';

  @override
  String get bugReportIntroHeader => 'Cómo funciona';

  @override
  String get bugReportStepRecord => 'Iniciar grabación';

  @override
  String get bugReportStepReproduce => 'Reproducir el problema';

  @override
  String get bugReportStepFinish => 'Volver y finalizar';

  @override
  String get bugReportReviewFirst =>
      'Puedes revisarlo todo antes de que salga del teléfono.';

  @override
  String get bugReportPrivacyHeader => 'Qué se incluye en el registro';

  @override
  String get bugReportStart => 'Iniciar grabación';

  @override
  String get bugReportRecordingHeader => 'Grabando';

  @override
  String get bugReportRecordingBody =>
      'Vuelve a la app y reproduce el problema. La barra de grabación permanecerá en pantalla — muévela a un lado o pliégala si te estorba, y úsala para marcar el momento del fallo y finalizar.';

  @override
  String get bugReportMark => 'Marcar el momento';

  @override
  String get bugReportMarked => 'Momento marcado';

  @override
  String get bugReportStop => 'Finalizar grabación';

  @override
  String get bugReportStopShort => 'Finalizar';

  @override
  String get bugReportBannerLabel => 'Grabando';

  @override
  String get bugReportBarMove => 'Mover la barra de grabación';

  @override
  String get bugReportBarCollapse => 'Plegar la barra de grabación';

  @override
  String get bugReportBarExpand => 'Desplegar la barra de grabación';

  @override
  String get bugReportReviewHeader => 'Revisar antes de enviar';

  @override
  String get bugReportReviewBody =>
      'Esto es todo lo que se ha grabado. Léelo detenidamente — más abajo puedes elegir si permanece en el teléfono o se envía como una incidencia pública.';

  @override
  String bugReportSummary(int records, int errors, int warnings) {
    return '$records registros · $errors errores · $warnings advertencias';
  }

  @override
  String bugReportMarkers(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count momentos marcados',
      one: '1 momento marcado',
    );
    return '$_temp0';
  }

  @override
  String get bugReportTruncated =>
      'La sesión fue larga — se descartaron los registros más antiguos.';

  @override
  String get bugReportEmpty => 'No se grabó nada.';

  @override
  String get bugReportShowRaw => 'Mostrar registro sin procesar';

  @override
  String get bugReportHideRaw => 'Ocultar registro sin procesar';

  @override
  String bugReportRawClipped(int kb) {
    return 'Los primeros $kb kB no se muestran aquí. El archivo que guardes contiene la sesión completa.';
  }

  @override
  String get bugReportSave => 'Guardar en un archivo';

  @override
  String get bugReportSaveShort => 'Guardar';

  @override
  String get bugReportSaved => 'Registro guardado en el archivo';

  @override
  String get bugReportSaveFailed => 'No se pudo guardar el registro.';

  @override
  String get bugReportDiscard => 'Descartar';

  @override
  String get bugReportDiscardQuestion => '¿Descartar esta grabación?';

  @override
  String get bugReportDiscardBody => 'El registro se eliminará del teléfono.';

  @override
  String get bugReportDiscardBodyQueued =>
      'El registro se eliminará del teléfono y se cancelará el informe en cola.';

  @override
  String bugReportLimit(int minutes) {
    return 'La grabación se detiene automáticamente tras $minutes minutos.';
  }

  @override
  String bugReportLimitReached(int minutes) {
    return 'Grabación finalizada — se alcanzó el límite de $minutes minutos.';
  }

  @override
  String bugReportSizeLimitReached(int megabytes) {
    return 'Grabación finalizada — el registro alcanzó su límite de $megabytes MB.';
  }

  @override
  String get bugReportShow => 'Mostrar';

  @override
  String get bugReportRecoveredHeader =>
      'Una grabación sobrevivió a un cierre inesperado';

  @override
  String get bugReportRecoveredBody =>
      'La app se cerró mientras estaba grabando. Lo que se llegó a registrar aún está en el teléfono — puedes revisarlo o descartarlo.';

  @override
  String get bugReportDestinationFile => 'Guardar en un archivo';

  @override
  String get bugReportDestinationIssue => 'Publicar en GitHub';

  @override
  String get bugReportDestinationFileBody =>
      'El registro se guarda donde elijas y permanece en tu teléfono. Tú decides si quieres enviarlo a algún sitio.';

  @override
  String get bugReportDestinationIssueBody =>
      'El registro y tu descripción se publicarán como una incidencia pública en GitHub, donde cualquiera podrá verlos y quedarán guardados permanentemente. Revisa primero el registro a continuación.';

  @override
  String get bugReportDescriptionLabel => '¿Qué salió mal?';

  @override
  String get bugReportDescriptionHint =>
      'Qué estabas haciendo, qué esperabas y qué ocurrió en su lugar.';

  @override
  String get bugReportDescriptionRequired =>
      'Explica qué salió mal — un registro sin descripción es prácticamente inservible.';

  @override
  String get bugReportSend => 'Enviar';

  @override
  String get bugReportSending => 'Enviando…';

  @override
  String bugReportSendWaiting(String clock) {
    return 'Enviando en $clock';
  }

  @override
  String get bugReportSendWaitingBody =>
      'El relay espacia los informes. Puedes salir de esta pantalla — se enviará por sí solo.';

  @override
  String get bugReportSent => 'Reporte enviado';

  @override
  String get bugReportSentBody =>
      'Gracias. La incidencia está abierta y el registro se ha adjuntado a ella.';

  @override
  String get bugReportOpenIssue => 'Abrir la incidencia';

  @override
  String get bugReportDone => 'Listo';

  @override
  String get bugReportSendFailedNotYet =>
      'El relay no acepta informes en este momento. Inténtalo de nuevo más tarde o guarda el registro en un archivo.';

  @override
  String get bugReportSendFailedRefused =>
      'El relay denegó este informe. Guarda el registro en un archivo y adjúntalo tú mismo.';

  @override
  String get bugReportSendFailedDuplicate => 'Esto ya ha sido reportado.';

  @override
  String get bugReportSendFailedUnreachable =>
      'No se pudo conectar con el relay. Comprueba la conexión o guarda el registro en un archivo.';

  @override
  String get bugReportSendFailedRejected =>
      'El relay rechazó este informe. Guarda el registro en un archivo y adjúntalo tú mismo.';

  @override
  String get bugReportSendFailedDemo =>
      'El modo demo no publica informes. Guarda el registro en un archivo en su lugar.';

  @override
  String get bugReportKindQuestion => '¿Qué quieres notificar?';

  @override
  String get bugReportKindBug => 'Error';

  @override
  String get bugReportKindChange => 'Cambio';

  @override
  String get bugReportKindFeature => 'Nueva función';

  @override
  String get bugReportChangeHeader => 'Solicitar un cambio';

  @override
  String get bugReportChangeBody => 'Algo funciona, pero no como debería.';

  @override
  String get bugReportChangeLabel => '¿Qué debería cambiar?';

  @override
  String get bugReportChangeHint =>
      'Qué hace ahora y qué debería hacer en su lugar.';

  @override
  String get bugReportFeatureHeader => 'Sugerir una función';

  @override
  String get bugReportFeatureBody => 'Algo que la app todavía no puede hacer.';

  @override
  String get bugReportFeatureLabel => '¿Qué falta?';

  @override
  String get bugReportFeatureHint =>
      'Qué quieres hacer y por qué la app no te lo permite.';

  @override
  String get bugReportRequestPrivacyHeader => 'Qué se envía';

  @override
  String get bugReportRequestWhatYouWrite => 'Lo que escribes';

  @override
  String get bugReportRequestVersions => 'Versión de la app y del servidor';

  @override
  String get bugReportRequestNoLog => 'Sin registro ni grabación';

  @override
  String get bugReportRequestPublic =>
      'Se convertirá en una incidencia pública en GitHub — cualquiera podrá leerla y quedará guardada permanentemente.';

  @override
  String get bugReportRequestRequired =>
      'Escribe lo que solicitas — una petición vacía no se puede tramitar.';

  @override
  String get bugReportRequestSentBody => 'Gracias. La incidencia está abierta.';

  @override
  String get bugReportCancelSend => 'Cancelar envío';

  @override
  String get bugReportRequestFailedNotYet =>
      'El relay no acepta solicitudes en este momento. Inténtalo de nuevo más tarde.';

  @override
  String get bugReportRequestFailedRefused =>
      'El relay denegó esta solicitud. Puedes abrir la incidencia tú mismo en GitHub.';

  @override
  String get bugReportRequestFailedUnreachable =>
      'No se pudo conectar con el relay. Comprueba la conexión e inténtalo de nuevo.';

  @override
  String get bugReportRequestFailedDemo =>
      'El modo demo no publica solicitudes.';

  @override
  String get bugReportRequestNotPrepared =>
      'La app no pudo preparar la solicitud. No se envió nada — inténtalo de nuevo.';

  @override
  String get bugReportQueuedBug =>
      'Esta cuenta atrás es del informe de error que ya enviaste.';

  @override
  String get bugReportQueuedChange =>
      'Esta cuenta atrás es de la solicitud de cambio que ya enviaste.';

  @override
  String get bugReportQueuedFeature =>
      'Esta cuenta atrás es de la solicitud de función que ya enviaste.';

  @override
  String get reportCancel => 'Cancelar';
}
