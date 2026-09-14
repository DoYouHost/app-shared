// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'report_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class ReportLocalizationsDe extends ReportLocalizations {
  ReportLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get bugReportTitle => 'Fehler oder Idee melden';

  @override
  String get bugReportIntroHeader => 'So funktioniert es';

  @override
  String get bugReportStepRecord => 'Aufzeichnung starten';

  @override
  String get bugReportStepReproduce => 'Problem reproduzieren';

  @override
  String get bugReportStepFinish => 'Zurückkehren und abschließen';

  @override
  String get bugReportReviewFirst =>
      'Du kannst alles lesen, bevor es das Smartphone verlässt.';

  @override
  String get bugReportPrivacyHeader => 'Was im Log landet';

  @override
  String get bugReportStart => 'Aufzeichnung starten';

  @override
  String get bugReportRecordingHeader => 'Aufzeichnung läuft';

  @override
  String get bugReportRecordingBody =>
      'Kehre zur App zurück und reproduziere das Problem. Die Aufzeichnungsleiste bleibt sichtbar — schiebe sie beiseite oder klappe sie ein, wenn sie stört, und nutze sie, um den Moment des Fehlers zu markieren und die Aufnahme zu beenden.';

  @override
  String get bugReportMark => 'Moment markieren';

  @override
  String get bugReportMarked => 'Moment markiert';

  @override
  String get bugReportStop => 'Aufzeichnung beenden';

  @override
  String get bugReportStopShort => 'Beenden';

  @override
  String get bugReportBannerLabel => 'Aufzeichnung';

  @override
  String get bugReportBarMove => 'Aufzeichnungsleiste verschieben';

  @override
  String get bugReportBarCollapse => 'Aufzeichnungsleiste einklappen';

  @override
  String get bugReportBarExpand => 'Aufzeichnungsleiste ausklappen';

  @override
  String get bugReportReviewHeader => 'Vor dem Senden überprüfen';

  @override
  String get bugReportReviewBody =>
      'Dies ist alles, was aufgezeichnet wurde. Lies es durch — unten entscheidest du, ob es auf dem Smartphone bleibt oder als öffentliches Issue gemeldet wird.';

  @override
  String bugReportSummary(int records, int errors, int warnings) {
    return '$records Einträge · $errors Fehler · $warnings Warnungen';
  }

  @override
  String bugReportMarkers(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count markierte Momente',
      one: '1 markierter Moment',
    );
    return '$_temp0';
  }

  @override
  String get bugReportTruncated =>
      'Die Sitzung war lang — die ältesten Einträge wurden verworfen.';

  @override
  String get bugReportEmpty => 'Es wurde nichts aufgezeichnet.';

  @override
  String get bugReportShowRaw => 'Roh-Log anzeigen';

  @override
  String get bugReportHideRaw => 'Roh-Log ausblenden';

  @override
  String bugReportRawClipped(int kb) {
    return 'Die ersten $kb kB werden hier nicht angezeigt. Die gespeicherte Datei enthält die gesamte Sitzung.';
  }

  @override
  String get bugReportSave => 'In Datei speichern';

  @override
  String get bugReportSaveShort => 'Speichern';

  @override
  String get bugReportSaved => 'Log in Datei gespeichert';

  @override
  String get bugReportSaveFailed => 'Das Log konnte nicht gespeichert werden.';

  @override
  String get bugReportDiscard => 'Verwerfen';

  @override
  String get bugReportDiscardQuestion => 'Diese Aufzeichnung verwerfen?';

  @override
  String get bugReportDiscardBody => 'Das Log wird vom Smartphone gelöscht.';

  @override
  String get bugReportDiscardBodyQueued =>
      'Das Log wird vom Smartphone gelöscht und der Bericht in der Warteschlange abgebrochen.';

  @override
  String bugReportLimit(int minutes) {
    return 'Eine Aufzeichnung stoppt automatisch nach $minutes Minuten.';
  }

  @override
  String bugReportLimitReached(int minutes) {
    return 'Aufzeichnung beendet — das Limit von $minutes Minuten wurde erreicht.';
  }

  @override
  String bugReportSizeLimitReached(int megabytes) {
    return 'Aufzeichnung beendet — das Log hat das Limit von $megabytes MB erreicht.';
  }

  @override
  String get bugReportShow => 'Anzeigen';

  @override
  String get bugReportRecoveredHeader =>
      'Eine Aufzeichnung hat einen Absturz überstanden';

  @override
  String get bugReportRecoveredBody =>
      'Die App wurde während der Aufzeichnung geschlossen. Was bereits aufgezeichnet wurde, befindet sich noch auf dem Smartphone — schau es dir an oder verwirf es.';

  @override
  String get bugReportDestinationFile => 'In Datei speichern';

  @override
  String get bugReportDestinationIssue => 'Auf GitHub melden';

  @override
  String get bugReportDestinationFileBody =>
      'Das Log wird am gewählten Ort gespeichert und verbleibt auf deinem Smartphone. Du entscheidest, ob du es irgendwohin sendest.';

  @override
  String get bugReportDestinationIssueBody =>
      'Das Log und deine Beschreibung werden als öffentliches Issue auf GitHub veröffentlicht, wo sie jeder lesen kann und dauerhaft bleiben. Gehe zuerst das Log unten durch.';

  @override
  String get bugReportDescriptionLabel => 'Was ist schiefgelaufen?';

  @override
  String get bugReportDescriptionHint =>
      'Was hast du getan, was hast du erwartet und was ist stattdessen passiert.';

  @override
  String get bugReportDescriptionRequired =>
      'Beschreibe, was schiefgelaufen ist — ein Log ohne Beschreibung ist kaum brauchbar.';

  @override
  String get bugReportSend => 'Melden';

  @override
  String get bugReportSending => 'Wird gesendet…';

  @override
  String bugReportSendWaiting(String clock) {
    return 'Wird in $clock gesendet';
  }

  @override
  String get bugReportSendWaitingBody =>
      'Das Relay staffelt Berichte zeitlich. Du kannst diesen Bildschirm verlassen — der Bericht wird automatisch gesendet.';

  @override
  String get bugReportSent => 'Bericht gesendet';

  @override
  String get bugReportSentBody =>
      'Vielen Dank. Das Issue ist eröffnet und das Log ist angehängt.';

  @override
  String get bugReportOpenIssue => 'Issue öffnen';

  @override
  String get bugReportDone => 'Fertig';

  @override
  String get bugReportSendFailedNotYet =>
      'Das Relay nimmt derzeit keine Berichte an. Versuche es später erneut oder speichere das Log in einer Datei.';

  @override
  String get bugReportSendFailedRefused =>
      'Das Relay hat diesen Bericht abgelehnt. Speichere das Log in einer Datei und hänge es selbst an.';

  @override
  String get bugReportSendFailedDuplicate => 'Dies wurde bereits gemeldet.';

  @override
  String get bugReportSendFailedUnreachable =>
      'Das Relay konnte nicht erreicht werden. Prüfe die Verbindung oder speichere das Log in einer Datei.';

  @override
  String get bugReportSendFailedRejected =>
      'Das Relay hat diesen Bericht zurückgewiesen. Speichere das Log in einer Datei und hänge es selbst an.';

  @override
  String get bugReportSendFailedDemo =>
      'Der Demo-Modus veröffentlicht keine Berichte. Speichere das Log stattdessen in einer Datei.';

  @override
  String get bugReportKindQuestion => 'Was möchtest du melden?';

  @override
  String get bugReportKindBug => 'Fehler';

  @override
  String get bugReportKindChange => 'Änderung';

  @override
  String get bugReportKindFeature => 'Neue Funktion';

  @override
  String get bugReportChangeHeader => 'Änderung vorschlagen';

  @override
  String get bugReportChangeBody =>
      'Etwas funktioniert, aber nicht so, wie es sollte.';

  @override
  String get bugReportChangeLabel => 'Was sollte sich ändern?';

  @override
  String get bugReportChangeHint =>
      'Was es jetzt tut und was es stattdessen tun sollte.';

  @override
  String get bugReportFeatureHeader => 'Neue Funktion vorschlagen';

  @override
  String get bugReportFeatureBody => 'Etwas, das die App noch nicht kann.';

  @override
  String get bugReportFeatureLabel => 'Was fehlt?';

  @override
  String get bugReportFeatureHint =>
      'Was du tun möchtest und warum die App dies nicht zulässt.';

  @override
  String get bugReportRequestPrivacyHeader => 'Was gesendet wird';

  @override
  String get bugReportRequestWhatYouWrite => 'Was du schreibst';

  @override
  String get bugReportRequestVersions => 'App- und Server-Version';

  @override
  String get bugReportRequestNoLog => 'Kein Log, keine Aufzeichnung';

  @override
  String get bugReportRequestPublic =>
      'Es wird ein öffentliches Issue auf GitHub — jeder kann es lesen und es bleibt dauerhaft bestehen.';

  @override
  String get bugReportRequestRequired =>
      'Beschreibe dein Anliegen — ein leeres Anliegen kann nicht bearbeitet werden.';

  @override
  String get bugReportRequestSentBody => 'Vielen Dank. Das Issue ist eröffnet.';

  @override
  String get bugReportCancelSend => 'Senden abbrechen';

  @override
  String get bugReportRequestFailedNotYet =>
      'Das Relay nimmt derzeit keine Berichte an. Versuche es später erneut.';

  @override
  String get bugReportRequestFailedRefused =>
      'Das Relay hat diese Anfrage abgelehnt. Du kannst das Issue selbst auf GitHub eröffnen.';

  @override
  String get bugReportRequestFailedUnreachable =>
      'Das Relay konnte nicht erreicht werden. Prüfe die Verbindung und versuche es erneut.';

  @override
  String get bugReportRequestFailedDemo =>
      'Der Demo-Modus veröffentlicht keine Berichte.';

  @override
  String get bugReportRequestNotPrepared =>
      'Die App konnte den Bericht nicht zusammenstellen. Es wurde nichts gesendet — versuche es erneut.';

  @override
  String get bugReportQueuedBug =>
      'Dieser Countdown gilt für den Fehlerbericht, den du bereits gesendet hast.';

  @override
  String get bugReportQueuedChange =>
      'Dieser Countdown gilt für den Änderungswunsch, den du bereits gesendet hast.';

  @override
  String get bugReportQueuedFeature =>
      'Dieser Countdown gilt für den Funktionswunsch, den du bereits gesendet hast.';
}
