// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'report_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Polish (`pl`).
class ReportLocalizationsPl extends ReportLocalizations {
  ReportLocalizationsPl([String locale = 'pl']) : super(locale);

  @override
  String get bugReportTitle => 'Zgłoś błąd lub pomysł';

  @override
  String get bugReportIntroHeader => 'Jak to działa';

  @override
  String get bugReportStepRecord => 'Włącz nagrywanie';

  @override
  String get bugReportStepReproduce => 'Odtwórz problem';

  @override
  String get bugReportStepFinish => 'Wróć tutaj i zakończ';

  @override
  String get bugReportReviewFirst => 'Wszystko czytasz, zanim opuści telefon.';

  @override
  String get bugReportPrivacyHeader => 'Co trafia do logu';

  @override
  String get bugReportStart => 'Rozpocznij nagrywanie';

  @override
  String get bugReportRecordingHeader => 'Nagrywanie trwa';

  @override
  String get bugReportRecordingBody =>
      'Wróć do aplikacji i odtwórz problem. Pasek nagrywania zostaje z Tobą — przesuń go albo zwiń, jeśli zasłania. Oznacz nim moment awarii i zakończ nagrywanie.';

  @override
  String get bugReportMark => 'Oznacz moment';

  @override
  String get bugReportMarked => 'Moment oznaczony';

  @override
  String get bugReportStop => 'Zakończ nagrywanie';

  @override
  String get bugReportStopShort => 'Zakończ';

  @override
  String get bugReportBannerLabel => 'Nagrywanie';

  @override
  String get bugReportBarMove => 'Przesuń pasek nagrywania';

  @override
  String get bugReportBarCollapse => 'Zwiń pasek nagrywania';

  @override
  String get bugReportBarExpand => 'Rozwiń pasek nagrywania';

  @override
  String get bugReportReviewHeader => 'Przejrzyj przed wysłaniem';

  @override
  String get bugReportReviewBody =>
      'To wszystko, co zostało nagrane. Przejrzyj to — poniżej wybierasz, czy log zostaje w telefonie, czy idzie jako publiczne zgłoszenie.';

  @override
  String bugReportSummary(int records, int errors, int warnings) {
    return '$records rekordów · $errors błędów · $warnings ostrzeżeń';
  }

  @override
  String bugReportMarkers(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count oznaczonych momentów',
      few: '$count oznaczone momenty',
      one: '1 oznaczony moment',
    );
    return '$_temp0';
  }

  @override
  String get bugReportTruncated =>
      'Sesja była długa — najstarsze rekordy zostały odrzucone.';

  @override
  String get bugReportEmpty => 'Nic nie zostało nagrane.';

  @override
  String get bugReportShowRaw => 'Pokaż surowy log';

  @override
  String get bugReportHideRaw => 'Ukryj surowy log';

  @override
  String bugReportRawClipped(int kb) {
    return 'Pierwsze $kb kB nie są tu pokazane. Zapisany plik zawiera całą sesję.';
  }

  @override
  String get bugReportSave => 'Zapisz do pliku';

  @override
  String get bugReportSaveShort => 'Zapisz';

  @override
  String get bugReportSaved => 'Log zapisany do pliku';

  @override
  String get bugReportSaveFailed => 'Nie udało się zapisać loga.';

  @override
  String get bugReportDiscard => 'Odrzuć';

  @override
  String get bugReportDiscardQuestion => 'Odrzucić to nagranie?';

  @override
  String get bugReportDiscardBody => 'Log zostanie usunięty z telefonu.';

  @override
  String get bugReportDiscardBodyQueued =>
      'Log zostanie usunięty z telefonu, a zakolejkowana wysyłka anulowana.';

  @override
  String bugReportLimit(int minutes) {
    return 'Nagrywanie zatrzyma się samo po $minutes min.';
  }

  @override
  String bugReportLimitReached(int minutes) {
    return 'Nagrywanie zakończone — minął limit $minutes min.';
  }

  @override
  String bugReportSizeLimitReached(int megabytes) {
    return 'Nagrywanie zakończone — log osiągnął limit $megabytes MB.';
  }

  @override
  String get bugReportShow => 'Pokaż';

  @override
  String get bugReportRecoveredHeader => 'Nagranie przetrwało awarię';

  @override
  String get bugReportRecoveredBody =>
      'Aplikacja zamknęła się w trakcie nagrywania. To, co zdążyła zapisać, jest nadal w telefonie — obejrzyj albo wyrzuć.';

  @override
  String get bugReportDestinationFile => 'Zapisz do pliku';

  @override
  String get bugReportDestinationIssue => 'Zgłoś na GitHubie';

  @override
  String get bugReportDestinationFileBody =>
      'Log zapisze się tam, gdzie wskażesz, i zostanie w telefonie. Sam decydujesz, czy gdziekolwiek go wyślesz.';

  @override
  String get bugReportDestinationIssueBody =>
      'Log i Twój opis trafią jako publiczne zgłoszenie na GitHuba — każdy będzie mógł je przeczytać i zostaną tam na zawsze. Przejrzyj najpierw log poniżej.';

  @override
  String get bugReportDescriptionLabel => 'Co poszło nie tak?';

  @override
  String get bugReportDescriptionHint =>
      'Co robiłeś, czego się spodziewałeś, co stało się zamiast tego.';

  @override
  String get bugReportDescriptionRequired =>
      'Napisz, co poszło nie tak — log bez opisu jest prawie bezużyteczny.';

  @override
  String get bugReportSend => 'Zgłoś';

  @override
  String get bugReportSending => 'Wysyłanie…';

  @override
  String bugReportSendWaiting(String clock) {
    return 'Wysyłka za $clock';
  }

  @override
  String get bugReportSendWaitingBody =>
      'Relay rozkłada zgłoszenia w czasie. Możesz zamknąć ten ekran — wyśle się samo.';

  @override
  String get bugReportSent => 'Zgłoszenie wysłane';

  @override
  String get bugReportSentBody =>
      'Dzięki. Zgłoszenie jest otwarte, a log do niego dołączony.';

  @override
  String get bugReportOpenIssue => 'Otwórz zgłoszenie';

  @override
  String get bugReportDone => 'Gotowe';

  @override
  String get bugReportSendFailedNotYet =>
      'Relay w tej chwili nie przyjmuje zgłoszeń. Spróbuj później albo zapisz log do pliku.';

  @override
  String get bugReportSendFailedRefused =>
      'Relay odmówił przyjęcia tego zgłoszenia. Zapisz log do pliku i dołącz go sam.';

  @override
  String get bugReportSendFailedDuplicate => 'To już zostało zgłoszone.';

  @override
  String get bugReportSendFailedUnreachable =>
      'Nie udało się połączyć z relayem. Sprawdź połączenie albo zapisz log do pliku.';

  @override
  String get bugReportSendFailedRejected =>
      'Relay odrzucił to zgłoszenie. Zapisz log do pliku i dołącz go sam.';

  @override
  String get bugReportSendFailedDemo =>
      'Tryb demo nie publikuje zgłoszeń. Zapisz log do pliku.';

  @override
  String get bugReportKindQuestion => 'Co zgłaszasz?';

  @override
  String get bugReportKindBug => 'Błąd';

  @override
  String get bugReportKindChange => 'Zmianę';

  @override
  String get bugReportKindFeature => 'Funkcję';

  @override
  String get bugReportChangeHeader => 'Prośba o zmianę';

  @override
  String get bugReportChangeBody => 'Coś działa, ale nie tak, jak powinno.';

  @override
  String get bugReportChangeLabel => 'Co powinno się zmienić?';

  @override
  String get bugReportChangeHint =>
      'Co robi teraz, a co powinno robić zamiast tego.';

  @override
  String get bugReportFeatureHeader => 'Propozycja funkcji';

  @override
  String get bugReportFeatureBody => 'Czegoś aplikacja jeszcze nie potrafi.';

  @override
  String get bugReportFeatureLabel => 'Czego brakuje?';

  @override
  String get bugReportFeatureHint =>
      'Co chcesz zrobić i dlaczego aplikacja na to nie pozwala.';

  @override
  String get bugReportRequestPrivacyHeader => 'Co zostanie wysłane';

  @override
  String get bugReportRequestWhatYouWrite => 'To, co napiszesz';

  @override
  String get bugReportRequestVersions => 'Wersja aplikacji i serwera';

  @override
  String get bugReportRequestNoLog => 'Żadnego loga, żadnego nagrania';

  @override
  String get bugReportRequestPublic =>
      'Powstaje publiczne zgłoszenie na GitHubie — każdy może je przeczytać i zostaje na stałe.';

  @override
  String get bugReportRequestRequired =>
      'Napisz, o co prosisz — z pustego zgłoszenia nic nie wynika.';

  @override
  String get bugReportRequestSentBody => 'Dzięki. Zgłoszenie jest otwarte.';

  @override
  String get bugReportCancelSend => 'Anuluj wysyłanie';

  @override
  String get bugReportRequestFailedNotYet =>
      'Relay w tej chwili nie przyjmuje zgłoszeń. Spróbuj później.';

  @override
  String get bugReportRequestFailedRefused =>
      'Relay odmówił przyjęcia tego zgłoszenia. Możesz otworzyć je samodzielnie na GitHubie.';

  @override
  String get bugReportRequestFailedUnreachable =>
      'Nie udało się połączyć z relayem. Sprawdź połączenie i spróbuj ponownie.';

  @override
  String get bugReportRequestFailedDemo => 'Tryb demo nie publikuje zgłoszeń.';

  @override
  String get bugReportRequestNotPrepared =>
      'Aplikacja nie zdołała przygotować zgłoszenia. Nic nie wysłano — spróbuj ponownie.';

  @override
  String get bugReportQueuedBug =>
      'To odliczanie dotyczy wysłanego już zgłoszenia błędu.';

  @override
  String get bugReportQueuedChange =>
      'To odliczanie dotyczy wysłanej już prośby o zmianę.';

  @override
  String get bugReportQueuedFeature =>
      'To odliczanie dotyczy wysłanej już prośby o funkcję.';

  @override
  String get reportCancel => 'Anuluj';
}
