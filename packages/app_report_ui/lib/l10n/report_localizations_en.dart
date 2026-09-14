// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'report_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class ReportLocalizationsEn extends ReportLocalizations {
  ReportLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get bugReportTitle => 'Report a bug or an idea';

  @override
  String get bugReportIntroHeader => 'How it works';

  @override
  String get bugReportStepRecord => 'Start recording';

  @override
  String get bugReportStepReproduce => 'Reproduce the problem';

  @override
  String get bugReportStepFinish => 'Come back and finish';

  @override
  String get bugReportReviewFirst =>
      'You read all of it before it leaves the phone.';

  @override
  String get bugReportPrivacyHeader => 'What ends up in the log';

  @override
  String get bugReportStart => 'Start recording';

  @override
  String get bugReportRecordingHeader => 'Recording';

  @override
  String get bugReportRecordingBody =>
      'Go back to the app and reproduce the problem. The recording bar stays with you — drag it aside or collapse it if it gets in the way, and use it to mark the moment it breaks and to finish.';

  @override
  String get bugReportMark => 'Mark the moment';

  @override
  String get bugReportMarked => 'Moment marked';

  @override
  String get bugReportStop => 'Finish recording';

  @override
  String get bugReportStopShort => 'Finish';

  @override
  String get bugReportBannerLabel => 'Recording';

  @override
  String get bugReportBarMove => 'Move the recording bar';

  @override
  String get bugReportBarCollapse => 'Collapse the recording bar';

  @override
  String get bugReportBarExpand => 'Expand the recording bar';

  @override
  String get bugReportReviewHeader => 'Review before sending';

  @override
  String get bugReportReviewBody =>
      'This is everything that was recorded. Read it through — below you choose whether it stays on the phone or goes out as a public issue.';

  @override
  String bugReportSummary(int records, int errors, int warnings) {
    return '$records records · $errors errors · $warnings warnings';
  }

  @override
  String bugReportMarkers(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count marked moments',
      one: '1 marked moment',
    );
    return '$_temp0';
  }

  @override
  String get bugReportTruncated =>
      'The session was long — the oldest records were dropped.';

  @override
  String get bugReportEmpty => 'Nothing was recorded.';

  @override
  String get bugReportShowRaw => 'Show raw log';

  @override
  String get bugReportHideRaw => 'Hide raw log';

  @override
  String bugReportRawClipped(int kb) {
    return 'The first $kb kB are not shown here. The file you save holds the whole session.';
  }

  @override
  String get bugReportSave => 'Save to a file';

  @override
  String get bugReportSaveShort => 'Save';

  @override
  String get bugReportSaved => 'Log saved to the file';

  @override
  String get bugReportSaveFailed => 'The log could not be saved.';

  @override
  String get bugReportDiscard => 'Discard';

  @override
  String get bugReportDiscardQuestion => 'Discard this recording?';

  @override
  String get bugReportDiscardBody => 'The log will be deleted from the phone.';

  @override
  String get bugReportDiscardBodyQueued =>
      'The log will be deleted from the phone and the queued report cancelled.';

  @override
  String bugReportLimit(int minutes) {
    return 'A recording stops by itself after $minutes minutes.';
  }

  @override
  String bugReportLimitReached(int minutes) {
    return 'Recording finished — the $minutes minute limit was reached.';
  }

  @override
  String bugReportSizeLimitReached(int megabytes) {
    return 'Recording finished — the log reached its $megabytes MB limit.';
  }

  @override
  String get bugReportShow => 'Show';

  @override
  String get bugReportRecoveredHeader => 'A recording survived a crash';

  @override
  String get bugReportRecoveredBody =>
      'The app closed while it was recording. What it had written down is still on the phone — look at it, or throw it away.';

  @override
  String get bugReportDestinationFile => 'Save to a file';

  @override
  String get bugReportDestinationIssue => 'Report on GitHub';

  @override
  String get bugReportDestinationFileBody =>
      'The log is saved where you choose and stays on your phone. You decide whether to send it anywhere.';

  @override
  String get bugReportDestinationIssueBody =>
      'The log and your description are posted as a public issue on GitHub, where anyone can read them and they stay for good. Go through the log below first.';

  @override
  String get bugReportDescriptionLabel => 'What went wrong?';

  @override
  String get bugReportDescriptionHint =>
      'What were you doing, what did you expect, what happened instead.';

  @override
  String get bugReportDescriptionRequired =>
      'Say what went wrong — a log with no description is nearly unusable.';

  @override
  String get bugReportSend => 'Report';

  @override
  String get bugReportSending => 'Sending…';

  @override
  String bugReportSendWaiting(String clock) {
    return 'Sending in $clock';
  }

  @override
  String get bugReportSendWaitingBody =>
      'The relay spaces reports out. You can leave this screen — it goes on its own.';

  @override
  String get bugReportSent => 'Report sent';

  @override
  String get bugReportSentBody =>
      'Thank you. The issue is open and the log is attached to it.';

  @override
  String get bugReportOpenIssue => 'Open the issue';

  @override
  String get bugReportDone => 'Done';

  @override
  String get bugReportSendFailedNotYet =>
      'The relay is not accepting reports right now. Try again later, or save the log to a file.';

  @override
  String get bugReportSendFailedRefused =>
      'The relay refused this report. Save the log to a file and attach it yourself.';

  @override
  String get bugReportSendFailedDuplicate =>
      'This one has already been reported.';

  @override
  String get bugReportSendFailedUnreachable =>
      'Could not reach the relay. Check the connection, or save the log to a file.';

  @override
  String get bugReportSendFailedRejected =>
      'The relay rejected this report. Save the log to a file and attach it yourself.';

  @override
  String get bugReportSendFailedDemo =>
      'Demo mode does not publish reports. Save the log to a file instead.';

  @override
  String get bugReportKindQuestion => 'What are you reporting?';

  @override
  String get bugReportKindBug => 'Bug';

  @override
  String get bugReportKindChange => 'Change';

  @override
  String get bugReportKindFeature => 'Feature';

  @override
  String get bugReportChangeHeader => 'Request a change';

  @override
  String get bugReportChangeBody =>
      'Something works, but not the way it should.';

  @override
  String get bugReportChangeLabel => 'What should change?';

  @override
  String get bugReportChangeHint =>
      'What it does now, and what it should do instead.';

  @override
  String get bugReportFeatureHeader => 'Request a feature';

  @override
  String get bugReportFeatureBody => 'Something the app cannot do yet.';

  @override
  String get bugReportFeatureLabel => 'What is missing?';

  @override
  String get bugReportFeatureHint =>
      'What you want to do, and why the app does not let you.';

  @override
  String get bugReportRequestPrivacyHeader => 'What gets sent';

  @override
  String get bugReportRequestWhatYouWrite => 'What you write';

  @override
  String get bugReportRequestVersions => 'App and server version';

  @override
  String get bugReportRequestNoLog => 'No log, no recording';

  @override
  String get bugReportRequestPublic =>
      'It becomes a public issue on GitHub — anyone can read it, and it stays.';

  @override
  String get bugReportRequestRequired =>
      'Write what you are asking for — an empty request cannot be acted on.';

  @override
  String get bugReportRequestSentBody => 'Thank you. The issue is open.';

  @override
  String get bugReportCancelSend => 'Cancel sending';

  @override
  String get bugReportRequestFailedNotYet =>
      'The relay is not accepting reports right now. Try again later.';

  @override
  String get bugReportRequestFailedRefused =>
      'The relay refused this request. You can open the issue yourself on GitHub.';

  @override
  String get bugReportRequestFailedUnreachable =>
      'Could not reach the relay. Check the connection and try again.';

  @override
  String get bugReportRequestFailedDemo =>
      'Demo mode does not publish reports.';

  @override
  String get bugReportRequestNotPrepared =>
      'The app could not put the report together. Nothing was sent — try again.';

  @override
  String get bugReportQueuedBug =>
      'This countdown is for the bug report you already sent.';

  @override
  String get bugReportQueuedChange =>
      'This countdown is for the change request you already sent.';

  @override
  String get bugReportQueuedFeature =>
      'This countdown is for the feature request you already sent.';
}
