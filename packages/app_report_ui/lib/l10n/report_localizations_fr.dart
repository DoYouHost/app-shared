// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'report_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class ReportLocalizationsFr extends ReportLocalizations {
  ReportLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get bugReportTitle => 'Signaler un bug ou proposer une idée';

  @override
  String get bugReportIntroHeader => 'Comment ça fonctionne';

  @override
  String get bugReportStepRecord => 'Lancer l\'enregistrement';

  @override
  String get bugReportStepReproduce => 'Reproduire le problème';

  @override
  String get bugReportStepFinish => 'Revenir et terminer';

  @override
  String get bugReportReviewFirst =>
      'Vous pouvez tout relire avant que cela ne quitte le téléphone.';

  @override
  String get bugReportPrivacyHeader => 'Ce qui figure dans le journal';

  @override
  String get bugReportStart => 'Lancer l\'enregistrement';

  @override
  String get bugReportRecordingHeader => 'Enregistrement';

  @override
  String get bugReportRecordingBody =>
      'Revenez dans l\'application et reproduisez le problème. La barre d\'enregistrement reste visible — faites-la glisser sur le côté ou réduisez-la si elle vous gêne, et utilisez-la pour marquer l\'instant du problème et terminer.';

  @override
  String get bugReportMark => 'Marquer ce moment';

  @override
  String get bugReportMarked => 'Moment marqué';

  @override
  String get bugReportStop => 'Terminer l\'enregistrement';

  @override
  String get bugReportStopShort => 'Terminer';

  @override
  String get bugReportBannerLabel => 'Enregistrement';

  @override
  String get bugReportBarMove => 'Déplacer la barre d\'enregistrement';

  @override
  String get bugReportBarCollapse => 'Réduire la barre d\'enregistrement';

  @override
  String get bugReportBarExpand => 'Développer la barre d\'enregistrement';

  @override
  String get bugReportReviewHeader => 'Vérifier avant d\'envoyer';

  @override
  String get bugReportReviewBody =>
      'Voici tout ce qui a été enregistré. Relisez-le attentivement — vous pouvez choisir ci-dessous de le conserver sur le téléphone ou de le publier sous forme de ticket public.';

  @override
  String bugReportSummary(int records, int errors, int warnings) {
    return '$records entrées · $errors erreurs · $warnings avertissements';
  }

  @override
  String bugReportMarkers(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count moments marqués',
      one: '1 moment marqué',
    );
    return '$_temp0';
  }

  @override
  String get bugReportTruncated =>
      'La session était longue — les entrées les plus anciennes ont été supprimées.';

  @override
  String get bugReportEmpty => 'Rien n\'a été enregistré.';

  @override
  String get bugReportShowRaw => 'Afficher le journal brut';

  @override
  String get bugReportHideRaw => 'Masquer le journal brut';

  @override
  String bugReportRawClipped(int kb) {
    return 'Les $kb premiers ko ne sont pas affichés ici. Le fichier enregistré contiendra toute la session.';
  }

  @override
  String get bugReportSave => 'Enregistrer dans un fichier';

  @override
  String get bugReportSaveShort => 'Enregistrer';

  @override
  String get bugReportSaved => 'Journal enregistré dans le fichier';

  @override
  String get bugReportSaveFailed => 'Le journal n\'a pas pu être enregistré.';

  @override
  String get bugReportDiscard => 'Abandonner';

  @override
  String get bugReportDiscardQuestion => 'Abandonner cet enregistrement ?';

  @override
  String get bugReportDiscardBody => 'Le journal sera supprimé du téléphone.';

  @override
  String get bugReportDiscardBodyQueued =>
      'Le journal sera supprimé du téléphone et le signalement en attente sera annulé.';

  @override
  String bugReportLimit(int minutes) {
    return 'Un enregistrement s\'arrête automatiquement au bout de $minutes minutes.';
  }

  @override
  String bugReportLimitReached(int minutes) {
    return 'Enregistrement terminé — la limite de $minutes minutes a été atteinte.';
  }

  @override
  String bugReportSizeLimitReached(int megabytes) {
    return 'Enregistrement terminé — le journal a atteint sa limite de $megabytes Mo.';
  }

  @override
  String get bugReportShow => 'Afficher';

  @override
  String get bugReportRecoveredHeader =>
      'Un enregistrement a survécu à un plantage';

  @override
  String get bugReportRecoveredBody =>
      'L\'application s\'est fermée pendant l\'enregistrement. Ce qui a été enregistré est toujours sur le téléphone — examinez-le ou supprimez-le.';

  @override
  String get bugReportDestinationFile => 'Enregistrer dans un fichier';

  @override
  String get bugReportDestinationIssue => 'Signaler sur GitHub';

  @override
  String get bugReportDestinationFileBody =>
      'Le journal est enregistré à l\'emplacement choisi et reste sur votre téléphone. Vous décidez de le partager ou non.';

  @override
  String get bugReportDestinationIssueBody =>
      'Le journal et votre description sont publiés sous la forme d\'un ticket public sur GitHub, où tout le monde peut les lire et où ils resteront définitivement. Consultez d\'abord le journal ci-dessous.';

  @override
  String get bugReportDescriptionLabel => 'Quel est le problème ?';

  @override
  String get bugReportDescriptionHint =>
      'Ce que vous faisiez, ce que vous attendiez et ce qui s\'est passé à la place.';

  @override
  String get bugReportDescriptionRequired =>
      'Décrivez le problème — un journal sans description est presque inutilisable.';

  @override
  String get bugReportSend => 'Signaler';

  @override
  String get bugReportSending => 'Envoi en cours…';

  @override
  String bugReportSendWaiting(String clock) {
    return 'Envoi dans $clock';
  }

  @override
  String get bugReportSendWaitingBody =>
      'Le relais espace les signalements. Vous pouvez quitter cet écran — l\'envoi se fera automatiquement.';

  @override
  String get bugReportSent => 'Signalement envoyé';

  @override
  String get bugReportSentBody =>
      'Merci. Le ticket est ouvert et le journal y est joint.';

  @override
  String get bugReportOpenIssue => 'Ouvrir le ticket';

  @override
  String get bugReportDone => 'Terminé';

  @override
  String get bugReportSendFailedNotYet =>
      'Le relais n\'accepte pas de signalements pour le moment. Réessayez plus tard ou enregistrez le journal dans un fichier.';

  @override
  String get bugReportSendFailedRefused =>
      'Le relais a refusé ce signalement. Enregistrez le journal dans un fichier et joignez-le vous-même.';

  @override
  String get bugReportSendFailedDuplicate => 'Ce problème a déjà été signalé.';

  @override
  String get bugReportSendFailedUnreachable =>
      'Impossible de joindre le relais. Vérifiez votre connexion ou enregistrez le journal dans un fichier.';

  @override
  String get bugReportSendFailedRejected =>
      'Le relais a rejeté ce signalement. Enregistrez le journal dans un fichier et joignez-le vous-même.';

  @override
  String get bugReportSendFailedDemo =>
      'Le mode démo ne publie pas de signalements. Enregistrez plutôt le journal dans un fichier.';

  @override
  String get bugReportKindQuestion => 'Que souhaitez-vous signaler ?';

  @override
  String get bugReportKindBug => 'Bug';

  @override
  String get bugReportKindChange => 'Modification';

  @override
  String get bugReportKindFeature => 'Nouvelle fonctionnalité';

  @override
  String get bugReportChangeHeader => 'Demander une modification';

  @override
  String get bugReportChangeBody =>
      'Quelque chose fonctionne, mais pas comme il le devrait.';

  @override
  String get bugReportChangeLabel => 'Que faudrait-il modifier ?';

  @override
  String get bugReportChangeHint =>
      'Ce que l\'application fait actuellement, et ce qu\'elle devrait faire à la place.';

  @override
  String get bugReportFeatureHeader => 'Proposer une fonctionnalité';

  @override
  String get bugReportFeatureBody =>
      'Quelque chose que l\'application ne sait pas encore faire.';

  @override
  String get bugReportFeatureLabel => 'Que manque-t-il ?';

  @override
  String get bugReportFeatureHint =>
      'Ce que vous souhaitez faire, et pourquoi l\'application ne vous le permet pas.';

  @override
  String get bugReportRequestPrivacyHeader => 'Ce qui est envoyé';

  @override
  String get bugReportRequestWhatYouWrite => 'Ce que vous écrivez';

  @override
  String get bugReportRequestVersions =>
      'Version de l\'application et du serveur';

  @override
  String get bugReportRequestNoLog => 'Aucun journal, aucun enregistrement';

  @override
  String get bugReportRequestPublic =>
      'La demande devient un ticket public sur GitHub — tout le monde peut la lire, et elle restera définitivement.';

  @override
  String get bugReportRequestRequired =>
      'Précisez votre demande — une requête vide ne peut pas être traitée.';

  @override
  String get bugReportRequestSentBody => 'Merci. Le ticket est ouvert.';

  @override
  String get bugReportCancelSend => 'Annuler l\'envoi';

  @override
  String get bugReportRequestFailedNotYet =>
      'Le relais n\'accepte pas de demandes pour l\'instant. Réessayez plus tard.';

  @override
  String get bugReportRequestFailedRefused =>
      'Le relais a refusé cette demande. Vous pouvez ouvrir le ticket vous-même sur GitHub.';

  @override
  String get bugReportRequestFailedUnreachable =>
      'Impossible de joindre le relais. Vérifiez votre connexion et réessayez.';

  @override
  String get bugReportRequestFailedDemo =>
      'Le mode démo ne publie pas de signalements.';

  @override
  String get bugReportRequestNotPrepared =>
      'L\'application n\'a pas pu préparer le signalement. Rien n\'a été envoyé — réessayez.';

  @override
  String get bugReportQueuedBug =>
      'Ce compte à rebours concerne le rapport de bug que vous avez déjà envoyé.';

  @override
  String get bugReportQueuedChange =>
      'Ce compte à rebours concerne la demande de modification que vous avez déjà envoyée.';

  @override
  String get bugReportQueuedFeature =>
      'Ce compte à rebours concerne la demande de fonctionnalité que vous avez déjà envoyée.';
}
