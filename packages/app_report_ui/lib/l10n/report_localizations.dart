import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'report_localizations_de.dart';
import 'report_localizations_en.dart';
import 'report_localizations_es.dart';
import 'report_localizations_fr.dart';
import 'report_localizations_pl.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of ReportLocalizations
/// returned by `ReportLocalizations.of(context)`.
///
/// Applications need to include `ReportLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/report_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: ReportLocalizations.localizationsDelegates,
///   supportedLocales: ReportLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the ReportLocalizations.supportedLocales
/// property.
abstract class ReportLocalizations {
  ReportLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static ReportLocalizations of(BuildContext context) {
    return Localizations.of<ReportLocalizations>(context, ReportLocalizations)!;
  }

  static const LocalizationsDelegate<ReportLocalizations> delegate =
      _ReportLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('de'),
    Locale('en'),
    Locale('es'),
    Locale('fr'),
    Locale('pl'),
  ];

  /// No description provided for @bugReportTitle.
  ///
  /// In en, this message translates to:
  /// **'Report a bug or an idea'**
  String get bugReportTitle;

  /// No description provided for @bugReportIntroHeader.
  ///
  /// In en, this message translates to:
  /// **'How it works'**
  String get bugReportIntroHeader;

  /// No description provided for @bugReportStepRecord.
  ///
  /// In en, this message translates to:
  /// **'Start recording'**
  String get bugReportStepRecord;

  /// No description provided for @bugReportStepReproduce.
  ///
  /// In en, this message translates to:
  /// **'Reproduce the problem'**
  String get bugReportStepReproduce;

  /// No description provided for @bugReportStepFinish.
  ///
  /// In en, this message translates to:
  /// **'Come back and finish'**
  String get bugReportStepFinish;

  /// No description provided for @bugReportReviewFirst.
  ///
  /// In en, this message translates to:
  /// **'You read all of it before it leaves the phone.'**
  String get bugReportReviewFirst;

  /// No description provided for @bugReportPrivacyHeader.
  ///
  /// In en, this message translates to:
  /// **'What ends up in the log'**
  String get bugReportPrivacyHeader;

  /// No description provided for @bugReportStart.
  ///
  /// In en, this message translates to:
  /// **'Start recording'**
  String get bugReportStart;

  /// No description provided for @bugReportRecordingHeader.
  ///
  /// In en, this message translates to:
  /// **'Recording'**
  String get bugReportRecordingHeader;

  /// No description provided for @bugReportRecordingBody.
  ///
  /// In en, this message translates to:
  /// **'Go back to the app and reproduce the problem. The recording bar stays with you — drag it aside or collapse it if it gets in the way, and use it to mark the moment it breaks and to finish.'**
  String get bugReportRecordingBody;

  /// No description provided for @bugReportMark.
  ///
  /// In en, this message translates to:
  /// **'Mark the moment'**
  String get bugReportMark;

  /// No description provided for @bugReportMarked.
  ///
  /// In en, this message translates to:
  /// **'Moment marked'**
  String get bugReportMarked;

  /// No description provided for @bugReportStop.
  ///
  /// In en, this message translates to:
  /// **'Finish recording'**
  String get bugReportStop;

  /// No description provided for @bugReportStopShort.
  ///
  /// In en, this message translates to:
  /// **'Finish'**
  String get bugReportStopShort;

  /// No description provided for @bugReportBannerLabel.
  ///
  /// In en, this message translates to:
  /// **'Recording'**
  String get bugReportBannerLabel;

  /// No description provided for @bugReportBarMove.
  ///
  /// In en, this message translates to:
  /// **'Move the recording bar'**
  String get bugReportBarMove;

  /// No description provided for @bugReportBarCollapse.
  ///
  /// In en, this message translates to:
  /// **'Collapse the recording bar'**
  String get bugReportBarCollapse;

  /// No description provided for @bugReportBarExpand.
  ///
  /// In en, this message translates to:
  /// **'Expand the recording bar'**
  String get bugReportBarExpand;

  /// No description provided for @bugReportReviewHeader.
  ///
  /// In en, this message translates to:
  /// **'Review before sending'**
  String get bugReportReviewHeader;

  /// No description provided for @bugReportReviewBody.
  ///
  /// In en, this message translates to:
  /// **'This is everything that was recorded. Read it through — below you choose whether it stays on the phone or goes out as a public issue.'**
  String get bugReportReviewBody;

  /// No description provided for @bugReportSummary.
  ///
  /// In en, this message translates to:
  /// **'{records} records · {errors} errors · {warnings} warnings'**
  String bugReportSummary(int records, int errors, int warnings);

  /// No description provided for @bugReportMarkers.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 marked moment} other{{count} marked moments}}'**
  String bugReportMarkers(int count);

  /// No description provided for @bugReportTruncated.
  ///
  /// In en, this message translates to:
  /// **'The session was long — the oldest records were dropped.'**
  String get bugReportTruncated;

  /// No description provided for @bugReportEmpty.
  ///
  /// In en, this message translates to:
  /// **'Nothing was recorded.'**
  String get bugReportEmpty;

  /// No description provided for @bugReportShowRaw.
  ///
  /// In en, this message translates to:
  /// **'Show raw log'**
  String get bugReportShowRaw;

  /// No description provided for @bugReportHideRaw.
  ///
  /// In en, this message translates to:
  /// **'Hide raw log'**
  String get bugReportHideRaw;

  /// No description provided for @bugReportRawClipped.
  ///
  /// In en, this message translates to:
  /// **'The first {kb} kB are not shown here. The file you save holds the whole session.'**
  String bugReportRawClipped(int kb);

  /// No description provided for @bugReportSave.
  ///
  /// In en, this message translates to:
  /// **'Save to a file'**
  String get bugReportSave;

  /// No description provided for @bugReportSaveShort.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get bugReportSaveShort;

  /// No description provided for @bugReportSaved.
  ///
  /// In en, this message translates to:
  /// **'Log saved to the file'**
  String get bugReportSaved;

  /// No description provided for @bugReportSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'The log could not be saved.'**
  String get bugReportSaveFailed;

  /// No description provided for @bugReportDiscard.
  ///
  /// In en, this message translates to:
  /// **'Discard'**
  String get bugReportDiscard;

  /// No description provided for @bugReportDiscardQuestion.
  ///
  /// In en, this message translates to:
  /// **'Discard this recording?'**
  String get bugReportDiscardQuestion;

  /// No description provided for @bugReportDiscardBody.
  ///
  /// In en, this message translates to:
  /// **'The log will be deleted from the phone.'**
  String get bugReportDiscardBody;

  /// No description provided for @bugReportDiscardBodyQueued.
  ///
  /// In en, this message translates to:
  /// **'The log will be deleted from the phone and the queued report cancelled.'**
  String get bugReportDiscardBodyQueued;

  /// No description provided for @bugReportLimit.
  ///
  /// In en, this message translates to:
  /// **'A recording stops by itself after {minutes} minutes.'**
  String bugReportLimit(int minutes);

  /// No description provided for @bugReportLimitReached.
  ///
  /// In en, this message translates to:
  /// **'Recording finished — the {minutes} minute limit was reached.'**
  String bugReportLimitReached(int minutes);

  /// No description provided for @bugReportSizeLimitReached.
  ///
  /// In en, this message translates to:
  /// **'Recording finished — the log reached its {megabytes} MB limit.'**
  String bugReportSizeLimitReached(int megabytes);

  /// No description provided for @bugReportShow.
  ///
  /// In en, this message translates to:
  /// **'Show'**
  String get bugReportShow;

  /// No description provided for @bugReportRecoveredHeader.
  ///
  /// In en, this message translates to:
  /// **'A recording survived a crash'**
  String get bugReportRecoveredHeader;

  /// No description provided for @bugReportRecoveredBody.
  ///
  /// In en, this message translates to:
  /// **'The app closed while it was recording. What it had written down is still on the phone — look at it, or throw it away.'**
  String get bugReportRecoveredBody;

  /// No description provided for @bugReportDestinationFile.
  ///
  /// In en, this message translates to:
  /// **'Save to a file'**
  String get bugReportDestinationFile;

  /// No description provided for @bugReportDestinationIssue.
  ///
  /// In en, this message translates to:
  /// **'Report on GitHub'**
  String get bugReportDestinationIssue;

  /// No description provided for @bugReportDestinationFileBody.
  ///
  /// In en, this message translates to:
  /// **'The log is saved where you choose and stays on your phone. You decide whether to send it anywhere.'**
  String get bugReportDestinationFileBody;

  /// No description provided for @bugReportDestinationIssueBody.
  ///
  /// In en, this message translates to:
  /// **'The log and your description are posted as a public issue on GitHub, where anyone can read them and they stay for good. Go through the log below first.'**
  String get bugReportDestinationIssueBody;

  /// No description provided for @bugReportDescriptionLabel.
  ///
  /// In en, this message translates to:
  /// **'What went wrong?'**
  String get bugReportDescriptionLabel;

  /// No description provided for @bugReportDescriptionHint.
  ///
  /// In en, this message translates to:
  /// **'What were you doing, what did you expect, what happened instead.'**
  String get bugReportDescriptionHint;

  /// No description provided for @bugReportDescriptionRequired.
  ///
  /// In en, this message translates to:
  /// **'Say what went wrong — a log with no description is nearly unusable.'**
  String get bugReportDescriptionRequired;

  /// No description provided for @bugReportSend.
  ///
  /// In en, this message translates to:
  /// **'Report'**
  String get bugReportSend;

  /// No description provided for @bugReportSending.
  ///
  /// In en, this message translates to:
  /// **'Sending…'**
  String get bugReportSending;

  /// No description provided for @bugReportSendWaiting.
  ///
  /// In en, this message translates to:
  /// **'Sending in {clock}'**
  String bugReportSendWaiting(String clock);

  /// No description provided for @bugReportSendWaitingBody.
  ///
  /// In en, this message translates to:
  /// **'The relay spaces reports out. You can leave this screen — it goes on its own.'**
  String get bugReportSendWaitingBody;

  /// No description provided for @bugReportSent.
  ///
  /// In en, this message translates to:
  /// **'Report sent'**
  String get bugReportSent;

  /// No description provided for @bugReportSentBody.
  ///
  /// In en, this message translates to:
  /// **'Thank you. The issue is open and the log is attached to it.'**
  String get bugReportSentBody;

  /// No description provided for @bugReportOpenIssue.
  ///
  /// In en, this message translates to:
  /// **'Open the issue'**
  String get bugReportOpenIssue;

  /// No description provided for @bugReportDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get bugReportDone;

  /// No description provided for @bugReportSendFailedNotYet.
  ///
  /// In en, this message translates to:
  /// **'The relay is not accepting reports right now. Try again later, or save the log to a file.'**
  String get bugReportSendFailedNotYet;

  /// No description provided for @bugReportSendFailedRefused.
  ///
  /// In en, this message translates to:
  /// **'The relay refused this report. Save the log to a file and attach it yourself.'**
  String get bugReportSendFailedRefused;

  /// No description provided for @bugReportSendFailedDuplicate.
  ///
  /// In en, this message translates to:
  /// **'This one has already been reported.'**
  String get bugReportSendFailedDuplicate;

  /// No description provided for @bugReportSendFailedUnreachable.
  ///
  /// In en, this message translates to:
  /// **'Could not reach the relay. Check the connection, or save the log to a file.'**
  String get bugReportSendFailedUnreachable;

  /// No description provided for @bugReportSendFailedRejected.
  ///
  /// In en, this message translates to:
  /// **'The relay rejected this report. Save the log to a file and attach it yourself.'**
  String get bugReportSendFailedRejected;

  /// No description provided for @bugReportSendFailedDemo.
  ///
  /// In en, this message translates to:
  /// **'Demo mode does not publish reports. Save the log to a file instead.'**
  String get bugReportSendFailedDemo;

  /// No description provided for @bugReportKindQuestion.
  ///
  /// In en, this message translates to:
  /// **'What are you reporting?'**
  String get bugReportKindQuestion;

  /// No description provided for @bugReportKindBug.
  ///
  /// In en, this message translates to:
  /// **'Bug'**
  String get bugReportKindBug;

  /// No description provided for @bugReportKindChange.
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get bugReportKindChange;

  /// No description provided for @bugReportKindFeature.
  ///
  /// In en, this message translates to:
  /// **'Feature'**
  String get bugReportKindFeature;

  /// No description provided for @bugReportChangeHeader.
  ///
  /// In en, this message translates to:
  /// **'Request a change'**
  String get bugReportChangeHeader;

  /// No description provided for @bugReportChangeBody.
  ///
  /// In en, this message translates to:
  /// **'Something works, but not the way it should.'**
  String get bugReportChangeBody;

  /// No description provided for @bugReportChangeLabel.
  ///
  /// In en, this message translates to:
  /// **'What should change?'**
  String get bugReportChangeLabel;

  /// No description provided for @bugReportChangeHint.
  ///
  /// In en, this message translates to:
  /// **'What it does now, and what it should do instead.'**
  String get bugReportChangeHint;

  /// No description provided for @bugReportFeatureHeader.
  ///
  /// In en, this message translates to:
  /// **'Request a feature'**
  String get bugReportFeatureHeader;

  /// No description provided for @bugReportFeatureBody.
  ///
  /// In en, this message translates to:
  /// **'Something the app cannot do yet.'**
  String get bugReportFeatureBody;

  /// No description provided for @bugReportFeatureLabel.
  ///
  /// In en, this message translates to:
  /// **'What is missing?'**
  String get bugReportFeatureLabel;

  /// No description provided for @bugReportFeatureHint.
  ///
  /// In en, this message translates to:
  /// **'What you want to do, and why the app does not let you.'**
  String get bugReportFeatureHint;

  /// No description provided for @bugReportRequestPrivacyHeader.
  ///
  /// In en, this message translates to:
  /// **'What gets sent'**
  String get bugReportRequestPrivacyHeader;

  /// No description provided for @bugReportRequestWhatYouWrite.
  ///
  /// In en, this message translates to:
  /// **'What you write'**
  String get bugReportRequestWhatYouWrite;

  /// No description provided for @bugReportRequestVersions.
  ///
  /// In en, this message translates to:
  /// **'App and server version'**
  String get bugReportRequestVersions;

  /// No description provided for @bugReportRequestNoLog.
  ///
  /// In en, this message translates to:
  /// **'No log, no recording'**
  String get bugReportRequestNoLog;

  /// No description provided for @bugReportRequestPublic.
  ///
  /// In en, this message translates to:
  /// **'It becomes a public issue on GitHub — anyone can read it, and it stays.'**
  String get bugReportRequestPublic;

  /// No description provided for @bugReportRequestRequired.
  ///
  /// In en, this message translates to:
  /// **'Write what you are asking for — an empty request cannot be acted on.'**
  String get bugReportRequestRequired;

  /// No description provided for @bugReportRequestSentBody.
  ///
  /// In en, this message translates to:
  /// **'Thank you. The issue is open.'**
  String get bugReportRequestSentBody;

  /// No description provided for @bugReportCancelSend.
  ///
  /// In en, this message translates to:
  /// **'Cancel sending'**
  String get bugReportCancelSend;

  /// No description provided for @bugReportRequestFailedNotYet.
  ///
  /// In en, this message translates to:
  /// **'The relay is not accepting reports right now. Try again later.'**
  String get bugReportRequestFailedNotYet;

  /// No description provided for @bugReportRequestFailedRefused.
  ///
  /// In en, this message translates to:
  /// **'The relay refused this request. You can open the issue yourself on GitHub.'**
  String get bugReportRequestFailedRefused;

  /// No description provided for @bugReportRequestFailedUnreachable.
  ///
  /// In en, this message translates to:
  /// **'Could not reach the relay. Check the connection and try again.'**
  String get bugReportRequestFailedUnreachable;

  /// No description provided for @bugReportRequestFailedDemo.
  ///
  /// In en, this message translates to:
  /// **'Demo mode does not publish reports.'**
  String get bugReportRequestFailedDemo;

  /// No description provided for @bugReportRequestNotPrepared.
  ///
  /// In en, this message translates to:
  /// **'The app could not put the report together. Nothing was sent — try again.'**
  String get bugReportRequestNotPrepared;

  /// No description provided for @bugReportQueuedBug.
  ///
  /// In en, this message translates to:
  /// **'This countdown is for the bug report you already sent.'**
  String get bugReportQueuedBug;

  /// No description provided for @bugReportQueuedChange.
  ///
  /// In en, this message translates to:
  /// **'This countdown is for the change request you already sent.'**
  String get bugReportQueuedChange;

  /// No description provided for @bugReportQueuedFeature.
  ///
  /// In en, this message translates to:
  /// **'This countdown is for the feature request you already sent.'**
  String get bugReportQueuedFeature;
}

class _ReportLocalizationsDelegate
    extends LocalizationsDelegate<ReportLocalizations> {
  const _ReportLocalizationsDelegate();

  @override
  Future<ReportLocalizations> load(Locale locale) {
    return SynchronousFuture<ReportLocalizations>(
      lookupReportLocalizations(locale),
    );
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['de', 'en', 'es', 'fr', 'pl'].contains(locale.languageCode);

  @override
  bool shouldReload(_ReportLocalizationsDelegate old) => false;
}

ReportLocalizations lookupReportLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de':
      return ReportLocalizationsDe();
    case 'en':
      return ReportLocalizationsEn();
    case 'es':
      return ReportLocalizationsEs();
    case 'fr':
      return ReportLocalizationsFr();
    case 'pl':
      return ReportLocalizationsPl();
  }

  throw FlutterError(
    'ReportLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
