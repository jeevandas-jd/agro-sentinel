import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_gu.dart';
import 'app_localizations_hi.dart';
import 'app_localizations_kn.dart';
import 'app_localizations_ml.dart';
import 'app_localizations_mr.dart';
import 'app_localizations_or.dart';
import 'app_localizations_pa.dart';
import 'app_localizations_ta.dart';
import 'app_localizations_te.dart';
import 'app_localizations_ur.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
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
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

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
    Locale('en'),
    Locale('gu'),
    Locale('hi'),
    Locale('kn'),
    Locale('ml'),
    Locale('mr'),
    Locale('or'),
    Locale('pa'),
    Locale('ta'),
    Locale('te'),
    Locale('ur'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'AgriSentinel'**
  String get appTitle;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @update.
  ///
  /// In en, this message translates to:
  /// **'Update'**
  String get update;

  /// No description provided for @signOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get signOut;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @changePasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'Change Password'**
  String get changePasswordTitle;

  /// No description provided for @currentPassword.
  ///
  /// In en, this message translates to:
  /// **'Current password'**
  String get currentPassword;

  /// No description provided for @currentPasswordRequired.
  ///
  /// In en, this message translates to:
  /// **'Current password is required'**
  String get currentPasswordRequired;

  /// No description provided for @newPassword.
  ///
  /// In en, this message translates to:
  /// **'New password'**
  String get newPassword;

  /// No description provided for @newPasswordMinLength.
  ///
  /// In en, this message translates to:
  /// **'New password must be at least 6 characters'**
  String get newPasswordMinLength;

  /// No description provided for @passwordUpdated.
  ///
  /// In en, this message translates to:
  /// **'Password updated'**
  String get passwordUpdated;

  /// No description provided for @deleteAccountTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Account'**
  String get deleteAccountTitle;

  /// No description provided for @deleteAccountConfirmation.
  ///
  /// In en, this message translates to:
  /// **'This will permanently remove your account and log you out.'**
  String get deleteAccountConfirmation;

  /// No description provided for @pushNotifications.
  ///
  /// In en, this message translates to:
  /// **'Push notifications'**
  String get pushNotifications;

  /// No description provided for @pushNotificationsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Receive app alerts for new hotspots'**
  String get pushNotificationsSubtitle;

  /// No description provided for @emailAlerts.
  ///
  /// In en, this message translates to:
  /// **'Email alerts'**
  String get emailAlerts;

  /// No description provided for @emailAlertsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Get claim and advisory updates by email'**
  String get emailAlertsSubtitle;

  /// No description provided for @offlineSync.
  ///
  /// In en, this message translates to:
  /// **'Offline sync'**
  String get offlineSync;

  /// No description provided for @offlineSyncSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Cache field data for low connectivity'**
  String get offlineSyncSubtitle;

  /// No description provided for @changePassword.
  ///
  /// In en, this message translates to:
  /// **'Change password'**
  String get changePassword;

  /// No description provided for @changePasswordSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Update your account credentials'**
  String get changePasswordSubtitle;

  /// No description provided for @deleteAccount.
  ///
  /// In en, this message translates to:
  /// **'Delete account'**
  String get deleteAccount;

  /// No description provided for @deleteAccountSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Permanently remove your account'**
  String get deleteAccountSubtitle;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @selectLanguage.
  ///
  /// In en, this message translates to:
  /// **'Select your preferred language'**
  String get selectLanguage;

  /// No description provided for @hello.
  ///
  /// In en, this message translates to:
  /// **'Hello, {name}'**
  String hello(String name);

  /// No description provided for @myFarms.
  ///
  /// In en, this message translates to:
  /// **'My Farms'**
  String get myFarms;

  /// No description provided for @add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// No description provided for @quickActions.
  ///
  /// In en, this message translates to:
  /// **'Quick Actions'**
  String get quickActions;

  /// No description provided for @reportDisaster.
  ///
  /// In en, this message translates to:
  /// **'Report Disaster'**
  String get reportDisaster;

  /// No description provided for @reportDisasterSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Start a new damage report for a farm'**
  String get reportDisasterSubtitle;

  /// No description provided for @addNewFarm.
  ///
  /// In en, this message translates to:
  /// **'Add New Farm'**
  String get addNewFarm;

  /// No description provided for @addNewFarmSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Register a new farm plot with boundary'**
  String get addNewFarmSubtitle;

  /// No description provided for @disasterEvents.
  ///
  /// In en, this message translates to:
  /// **'Disaster Events'**
  String get disasterEvents;

  /// No description provided for @selectFarmToReport.
  ///
  /// In en, this message translates to:
  /// **'Select Farm to Report'**
  String get selectFarmToReport;

  /// No description provided for @pleaseAddFarmFirst.
  ///
  /// In en, this message translates to:
  /// **'Please add a farm first.'**
  String get pleaseAddFarmFirst;

  /// No description provided for @couldNotLoadFarms.
  ///
  /// In en, this message translates to:
  /// **'Could not load farms.'**
  String get couldNotLoadFarms;

  /// No description provided for @loadingFarms.
  ///
  /// In en, this message translates to:
  /// **'Loading farms…'**
  String get loadingFarms;

  /// No description provided for @noDisasterReportsYet.
  ///
  /// In en, this message translates to:
  /// **'No disaster reports yet'**
  String get noDisasterReportsYet;

  /// No description provided for @noFarmsAdded.
  ///
  /// In en, this message translates to:
  /// **'No farms added yet'**
  String get noFarmsAdded;

  /// No description provided for @addFirstFarmDescription.
  ///
  /// In en, this message translates to:
  /// **'Add your first farm to start tracking and reporting.'**
  String get addFirstFarmDescription;

  /// No description provided for @addFirstFarm.
  ///
  /// In en, this message translates to:
  /// **'Add First Farm'**
  String get addFirstFarm;

  /// No description provided for @loadingEvents.
  ///
  /// In en, this message translates to:
  /// **'Loading events…'**
  String get loadingEvents;

  /// No description provided for @couldNotLoadEvents.
  ///
  /// In en, this message translates to:
  /// **'Could not load events.'**
  String get couldNotLoadEvents;

  /// No description provided for @addFarm.
  ///
  /// In en, this message translates to:
  /// **'Add Farm'**
  String get addFarm;

  /// No description provided for @statusSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Submitted'**
  String get statusSubmitted;

  /// No description provided for @statusVerified.
  ///
  /// In en, this message translates to:
  /// **'Verified'**
  String get statusVerified;

  /// No description provided for @statusDraft.
  ///
  /// In en, this message translates to:
  /// **'Draft'**
  String get statusDraft;

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @navClaims.
  ///
  /// In en, this message translates to:
  /// **'Claims'**
  String get navClaims;

  /// No description provided for @navProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get navProfile;

  /// No description provided for @navMore.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get navMore;

  /// No description provided for @walkingToHotspot.
  ///
  /// In en, this message translates to:
  /// **'Walking to hotspot...'**
  String get walkingToHotspot;

  /// No description provided for @simulateApproach.
  ///
  /// In en, this message translates to:
  /// **'Simulate Approach (Demo)'**
  String get simulateApproach;

  /// No description provided for @captureEvidence.
  ///
  /// In en, this message translates to:
  /// **'Capture Evidence'**
  String get captureEvidence;

  /// No description provided for @getWithin10m.
  ///
  /// In en, this message translates to:
  /// **'Get within 10 m to unlock'**
  String get getWithin10m;

  /// No description provided for @damageAssessment.
  ///
  /// In en, this message translates to:
  /// **'Damage Assessment'**
  String get damageAssessment;

  /// No description provided for @satelliteNdviData.
  ///
  /// In en, this message translates to:
  /// **'Satellite NDVI Data'**
  String get satelliteNdviData;

  /// No description provided for @gpsNavigation.
  ///
  /// In en, this message translates to:
  /// **'GPS Navigation'**
  String get gpsNavigation;

  /// No description provided for @proximityToDamageZone.
  ///
  /// In en, this message translates to:
  /// **'PROXIMITY TO DAMAGE ZONE'**
  String get proximityToDamageZone;

  /// No description provided for @captureUnlocked.
  ///
  /// In en, this message translates to:
  /// **'CAPTURE UNLOCKED'**
  String get captureUnlocked;

  /// No description provided for @unlockAt10m.
  ///
  /// In en, this message translates to:
  /// **'UNLOCK AT 10 m'**
  String get unlockAt10m;

  /// No description provided for @needlePoints.
  ///
  /// In en, this message translates to:
  /// **'Needle points toward satellite-detected hotspot'**
  String get needlePoints;

  /// No description provided for @healthy.
  ///
  /// In en, this message translates to:
  /// **'Healthy'**
  String get healthy;

  /// No description provided for @damaged.
  ///
  /// In en, this message translates to:
  /// **'Damaged'**
  String get damaged;

  /// No description provided for @downloadDamageReport.
  ///
  /// In en, this message translates to:
  /// **'Download damage report'**
  String get downloadDamageReport;

  /// No description provided for @damageReportPdfReady.
  ///
  /// In en, this message translates to:
  /// **'PDF ready — use Save or Share from the preview.'**
  String get damageReportPdfReady;

  /// No description provided for @couldNotBuildPdf.
  ///
  /// In en, this message translates to:
  /// **'Could not build PDF: {error}'**
  String couldNotBuildPdf(String error);

  /// No description provided for @farmNotFoundForReport.
  ///
  /// In en, this message translates to:
  /// **'Could not find farm for this report.'**
  String get farmNotFoundForReport;

  /// No description provided for @editDraftReport.
  ///
  /// In en, this message translates to:
  /// **'Edit draft'**
  String get editDraftReport;

  /// No description provided for @deleteDraftReport.
  ///
  /// In en, this message translates to:
  /// **'Delete draft'**
  String get deleteDraftReport;

  /// No description provided for @editDraftReportTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit draft report'**
  String get editDraftReportTitle;

  /// No description provided for @confirmDeleteDraftTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete this draft?'**
  String get confirmDeleteDraftTitle;

  /// No description provided for @confirmDeleteDraftMessage.
  ///
  /// In en, this message translates to:
  /// **'This will permanently remove this draft report. This cannot be undone.'**
  String get confirmDeleteDraftMessage;

  /// No description provided for @reportDeleted.
  ///
  /// In en, this message translates to:
  /// **'Report deleted'**
  String get reportDeleted;

  /// No description provided for @confirmDeleteSubmittedTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete this submitted report?'**
  String get confirmDeleteSubmittedTitle;

  /// No description provided for @confirmDeleteSubmittedMessage.
  ///
  /// In en, this message translates to:
  /// **'This will permanently remove this report and its stored data. This cannot be undone.'**
  String get confirmDeleteSubmittedMessage;

  /// No description provided for @deleteSubmittedReport.
  ///
  /// In en, this message translates to:
  /// **'Delete report'**
  String get deleteSubmittedReport;

  /// No description provided for @couldNotDeleteDraft.
  ///
  /// In en, this message translates to:
  /// **'Could not delete: {error}'**
  String couldNotDeleteDraft(String error);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>[
    'en',
    'gu',
    'hi',
    'kn',
    'ml',
    'mr',
    'or',
    'pa',
    'ta',
    'te',
    'ur',
  ].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'gu':
      return AppLocalizationsGu();
    case 'hi':
      return AppLocalizationsHi();
    case 'kn':
      return AppLocalizationsKn();
    case 'ml':
      return AppLocalizationsMl();
    case 'mr':
      return AppLocalizationsMr();
    case 'or':
      return AppLocalizationsOr();
    case 'pa':
      return AppLocalizationsPa();
    case 'ta':
      return AppLocalizationsTa();
    case 'te':
      return AppLocalizationsTe();
    case 'ur':
      return AppLocalizationsUr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
