// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'AgriSentinel';

  @override
  String get cancel => 'Cancel';

  @override
  String get delete => 'Delete';

  @override
  String get update => 'Update';

  @override
  String get signOut => 'Sign out';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get changePasswordTitle => 'Change Password';

  @override
  String get currentPassword => 'Current password';

  @override
  String get currentPasswordRequired => 'Current password is required';

  @override
  String get newPassword => 'New password';

  @override
  String get newPasswordMinLength =>
      'New password must be at least 6 characters';

  @override
  String get passwordUpdated => 'Password updated';

  @override
  String get deleteAccountTitle => 'Delete Account';

  @override
  String get deleteAccountConfirmation =>
      'This will permanently remove your account and log you out.';

  @override
  String get pushNotifications => 'Push notifications';

  @override
  String get pushNotificationsSubtitle => 'Receive app alerts for new hotspots';

  @override
  String get emailAlerts => 'Email alerts';

  @override
  String get emailAlertsSubtitle => 'Get claim and advisory updates by email';

  @override
  String get offlineSync => 'Offline sync';

  @override
  String get offlineSyncSubtitle => 'Cache field data for low connectivity';

  @override
  String get changePassword => 'Change password';

  @override
  String get changePasswordSubtitle => 'Update your account credentials';

  @override
  String get deleteAccount => 'Delete account';

  @override
  String get deleteAccountSubtitle => 'Permanently remove your account';

  @override
  String get language => 'Language';

  @override
  String get selectLanguage => 'Select your preferred language';

  @override
  String hello(String name) {
    return 'Hello, $name';
  }

  @override
  String get myFarms => 'My Farms';

  @override
  String get add => 'Add';

  @override
  String get quickActions => 'Quick Actions';

  @override
  String get reportDisaster => 'Report Disaster';

  @override
  String get reportDisasterSubtitle => 'Start a new damage report for a farm';

  @override
  String get addNewFarm => 'Add New Farm';

  @override
  String get addNewFarmSubtitle => 'Register a new farm plot with boundary';

  @override
  String get disasterEvents => 'Disaster Events';

  @override
  String get selectFarmToReport => 'Select Farm to Report';

  @override
  String get pleaseAddFarmFirst => 'Please add a farm first.';

  @override
  String get couldNotLoadFarms => 'Could not load farms.';

  @override
  String get loadingFarms => 'Loading farms…';

  @override
  String get noDisasterReportsYet => 'No disaster reports yet';

  @override
  String get noFarmsAdded => 'No farms added yet';

  @override
  String get addFirstFarmDescription =>
      'Add your first farm to start tracking and reporting.';

  @override
  String get addFirstFarm => 'Add First Farm';

  @override
  String get loadingEvents => 'Loading events…';

  @override
  String get couldNotLoadEvents => 'Could not load events.';

  @override
  String get addFarm => 'Add Farm';

  @override
  String get statusSubmitted => 'Submitted';

  @override
  String get statusVerified => 'Verified';

  @override
  String get statusDraft => 'Draft';

  @override
  String get navHome => 'Home';

  @override
  String get navClaims => 'Claims';

  @override
  String get navProfile => 'Profile';

  @override
  String get navMore => 'More';

  @override
  String get walkingToHotspot => 'Walking to hotspot...';

  @override
  String get simulateApproach => 'Simulate Approach (Demo)';

  @override
  String get captureEvidence => 'Capture Evidence';

  @override
  String get getWithin10m => 'Get within 10 m to unlock';

  @override
  String get damageAssessment => 'Damage Assessment';

  @override
  String get satelliteNdviData => 'Satellite NDVI Data';

  @override
  String get gpsNavigation => 'GPS Navigation';

  @override
  String get proximityToDamageZone => 'PROXIMITY TO DAMAGE ZONE';

  @override
  String get captureUnlocked => 'CAPTURE UNLOCKED';

  @override
  String get unlockAt10m => 'UNLOCK AT 10 m';

  @override
  String get needlePoints => 'Needle points toward satellite-detected hotspot';

  @override
  String get healthy => 'Healthy';

  @override
  String get damaged => 'Damaged';
}
