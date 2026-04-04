// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hindi (`hi`).
class AppLocalizationsHi extends AppLocalizations {
  AppLocalizationsHi([String locale = 'hi']) : super(locale);

  @override
  String get appTitle => 'एग्रीसेंटिनल';

  @override
  String get cancel => 'रद्द करें';

  @override
  String get delete => 'हटाएं';

  @override
  String get update => 'अपडेट करें';

  @override
  String get signOut => 'साइन आउट';

  @override
  String get settingsTitle => 'सेटिंग्स';

  @override
  String get changePasswordTitle => 'पासवर्ड बदलें';

  @override
  String get currentPassword => 'वर्तमान पासवर्ड';

  @override
  String get currentPasswordRequired => 'वर्तमान पासवर्ड आवश्यक है';

  @override
  String get newPassword => 'नया पासवर्ड';

  @override
  String get newPasswordMinLength =>
      'नया पासवर्ड कम से कम 6 अक्षरों का होना चाहिए';

  @override
  String get passwordUpdated => 'पासवर्ड अपडेट हो गया';

  @override
  String get deleteAccountTitle => 'खाता हटाएं';

  @override
  String get deleteAccountConfirmation =>
      'इससे आपका खाता स्थायी रूप से हट जाएगा और आप लॉग आउट हो जाएंगे।';

  @override
  String get pushNotifications => 'पुश नोटिफिकेशन';

  @override
  String get pushNotificationsSubtitle =>
      'नए हॉटस्पॉट के लिए ऐप अलर्ट प्राप्त करें';

  @override
  String get emailAlerts => 'ईमेल अलर्ट';

  @override
  String get emailAlertsSubtitle =>
      'ईमेल द्वारा दावा और सलाह अपडेट प्राप्त करें';

  @override
  String get offlineSync => 'ऑफलाइन सिंक';

  @override
  String get offlineSyncSubtitle => 'कम कनेक्टिविटी के लिए फील्ड डेटा कैश करें';

  @override
  String get changePassword => 'पासवर्ड बदलें';

  @override
  String get changePasswordSubtitle => 'अपनी खाता जानकारी अपडेट करें';

  @override
  String get deleteAccount => 'खाता हटाएं';

  @override
  String get deleteAccountSubtitle => 'अपना खाता स्थायी रूप से हटाएं';

  @override
  String get language => 'भाषा';

  @override
  String get selectLanguage => 'अपनी पसंदीदा भाषा चुनें';

  @override
  String hello(String name) {
    return 'नमस्ते, $name';
  }

  @override
  String get myFarms => 'मेरे खेत';

  @override
  String get add => 'जोड़ें';

  @override
  String get quickActions => 'त्वरित कार्य';

  @override
  String get reportDisaster => 'आपदा रिपोर्ट करें';

  @override
  String get reportDisasterSubtitle => 'खेत के लिए नई क्षति रिपोर्ट शुरू करें';

  @override
  String get addNewFarm => 'नया खेत जोड़ें';

  @override
  String get addNewFarmSubtitle => 'सीमा के साथ नई कृषि भूखंड दर्ज करें';

  @override
  String get disasterEvents => 'आपदा घटनाएं';

  @override
  String get selectFarmToReport => 'रिपोर्ट करने के लिए खेत चुनें';

  @override
  String get pleaseAddFarmFirst => 'कृपया पहले एक खेत जोड़ें।';

  @override
  String get couldNotLoadFarms => 'खेत लोड नहीं हो सके।';

  @override
  String get loadingFarms => 'खेत लोड हो रहे हैं…';

  @override
  String get noDisasterReportsYet => 'अभी तक कोई आपदा रिपोर्ट नहीं';

  @override
  String get noFarmsAdded => 'अभी तक कोई खेत नहीं जोड़ा गया';

  @override
  String get addFirstFarmDescription =>
      'ट्रैकिंग और रिपोर्टिंग शुरू करने के लिए अपना पहला खेत जोड़ें।';

  @override
  String get addFirstFarm => 'पहला खेत जोड़ें';

  @override
  String get loadingEvents => 'घटनाएं लोड हो रही हैं…';

  @override
  String get couldNotLoadEvents => 'घटनाएं लोड नहीं हो सकीं।';

  @override
  String get addFarm => 'खेत जोड़ें';

  @override
  String get statusSubmitted => 'सबमिट किया';

  @override
  String get statusVerified => 'सत्यापित';

  @override
  String get statusDraft => 'मसौदा';

  @override
  String get navHome => 'होम';

  @override
  String get navClaims => 'दावे';

  @override
  String get navProfile => 'प्रोफ़ाइल';

  @override
  String get navMore => 'अधिक';

  @override
  String get walkingToHotspot => 'हॉटस्पॉट की ओर चल रहे हैं...';

  @override
  String get simulateApproach => 'दृष्टिकोण अनुकरण (डेमो)';

  @override
  String get captureEvidence => 'साक्ष्य कैप्चर करें';

  @override
  String get getWithin10m => 'अनलॉक करने के लिए 10 मीटर के भीतर आएं';

  @override
  String get damageAssessment => 'क्षति आकलन';

  @override
  String get satelliteNdviData => 'उपग्रह NDVI डेटा';

  @override
  String get gpsNavigation => 'GPS नेविगेशन';

  @override
  String get proximityToDamageZone => 'क्षति क्षेत्र से निकटता';

  @override
  String get captureUnlocked => 'कैप्चर अनलॉक';

  @override
  String get unlockAt10m => '10 मीटर पर अनलॉक';

  @override
  String get needlePoints => 'सुई उपग्रह-पता लगाए हॉटस्पॉट की ओर इशारा करती है';

  @override
  String get healthy => 'स्वस्थ';

  @override
  String get damaged => 'क्षतिग्रस्त';

  @override
  String get downloadDamageReport => 'Download damage report';

  @override
  String get damageReportPdfReady =>
      'PDF ready — use Save or Share from the preview.';

  @override
  String couldNotBuildPdf(String error) {
    return 'Could not build PDF: $error';
  }

  @override
  String get farmNotFoundForReport => 'Could not find farm for this report.';

  @override
  String get editDraftReport => 'Edit draft';

  @override
  String get deleteDraftReport => 'Delete draft';

  @override
  String get editDraftReportTitle => 'Edit draft report';

  @override
  String get confirmDeleteDraftTitle => 'Delete this draft?';

  @override
  String get confirmDeleteDraftMessage =>
      'This will permanently remove this draft report. This cannot be undone.';

  @override
  String get reportDeleted => 'Report deleted';

  @override
  String get confirmDeleteSubmittedTitle => 'Delete this submitted report?';

  @override
  String get confirmDeleteSubmittedMessage =>
      'This will permanently remove this report and its stored data. This cannot be undone.';

  @override
  String get deleteSubmittedReport => 'Delete report';

  @override
  String couldNotDeleteDraft(String error) {
    return 'Could not delete: $error';
  }
}
