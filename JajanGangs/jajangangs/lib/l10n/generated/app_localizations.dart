import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_id.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
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

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
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
    Locale('id'),
  ];

  /// No description provided for @tagline.
  ///
  /// In en, this message translates to:
  /// **'Good food. Better company.'**
  String get tagline;

  /// No description provided for @hungry.
  ///
  /// In en, this message translates to:
  /// **'I\'m Hungry!'**
  String get hungry;

  /// No description provided for @letsJajan.
  ///
  /// In en, this message translates to:
  /// **'Let\'s Jajan!'**
  String get letsJajan;

  /// No description provided for @login.
  ///
  /// In en, this message translates to:
  /// **'Log In'**
  String get login;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading'**
  String get loading;

  /// No description provided for @restoring.
  ///
  /// In en, this message translates to:
  /// **'Restoring your session'**
  String get restoring;

  /// No description provided for @adventureBadge.
  ///
  /// In en, this message translates to:
  /// **'YOUR FOOD ADVENTURE STARTS HERE'**
  String get adventureBadge;

  /// No description provided for @nameLabel.
  ///
  /// In en, this message translates to:
  /// **'Your name'**
  String get nameLabel;

  /// No description provided for @nameHint.
  ///
  /// In en, this message translates to:
  /// **'What should we call you?'**
  String get nameHint;

  /// No description provided for @emailLabel.
  ///
  /// In en, this message translates to:
  /// **'Email address'**
  String get emailLabel;

  /// No description provided for @emailHint.
  ///
  /// In en, this message translates to:
  /// **'you@example.com'**
  String get emailHint;

  /// No description provided for @passwordLabel.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get passwordLabel;

  /// No description provided for @passwordHint.
  ///
  /// In en, this message translates to:
  /// **'At least 8 characters'**
  String get passwordHint;

  /// No description provided for @showPassword.
  ///
  /// In en, this message translates to:
  /// **'Show password'**
  String get showPassword;

  /// No description provided for @hidePassword.
  ///
  /// In en, this message translates to:
  /// **'Hide password'**
  String get hidePassword;

  /// No description provided for @loginTitle.
  ///
  /// In en, this message translates to:
  /// **'Your gang is waiting.'**
  String get loginTitle;

  /// No description provided for @registerTitle.
  ///
  /// In en, this message translates to:
  /// **'Join the food adventure.'**
  String get registerTitle;

  /// No description provided for @resetTitle.
  ///
  /// In en, this message translates to:
  /// **'Forgot your password?'**
  String get resetTitle;

  /// No description provided for @verifyTitle.
  ///
  /// In en, this message translates to:
  /// **'Check your inbox.'**
  String get verifyTitle;

  /// No description provided for @profileTitle.
  ///
  /// In en, this message translates to:
  /// **'Hey, new gang member!'**
  String get profileTitle;

  /// No description provided for @loadingProfile.
  ///
  /// In en, this message translates to:
  /// **'Finding your place...'**
  String get loadingProfile;

  /// No description provided for @retryTitle.
  ///
  /// In en, this message translates to:
  /// **'Let\'s try that again.'**
  String get retryTitle;

  /// No description provided for @welcomeTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome to Jajan Gangs'**
  String get welcomeTitle;

  /// No description provided for @loginSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Log in and make your next meal an adventure.'**
  String get loginSubtitle;

  /// No description provided for @registerSubtitle.
  ///
  /// In en, this message translates to:
  /// **'One account. Plenty of good food and great company.'**
  String get registerSubtitle;

  /// No description provided for @resetSubtitle.
  ///
  /// In en, this message translates to:
  /// **'We\'ll send you a link to choose a new password.'**
  String get resetSubtitle;

  /// No description provided for @profileSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your name and a character. Make yourself at home.'**
  String get profileSubtitle;

  /// No description provided for @loadingProfileSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Getting your gang profile ready.'**
  String get loadingProfileSubtitle;

  /// No description provided for @profileErrorSubtitle.
  ///
  /// In en, this message translates to:
  /// **'You are signed in. We just need to load your profile.'**
  String get profileErrorSubtitle;

  /// No description provided for @completeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your account is ready. Food discovery is coming next.'**
  String get completeSubtitle;

  /// No description provided for @readyBadge.
  ///
  /// In en, this message translates to:
  /// **'READY FOR YOUR NEXT BITE'**
  String get readyBadge;

  /// No description provided for @companyBadge.
  ///
  /// In en, this message translates to:
  /// **'GOOD FOOD STARTS WITH GOOD COMPANY'**
  String get companyBadge;

  /// No description provided for @google.
  ///
  /// In en, this message translates to:
  /// **'Continue with Google'**
  String get google;

  /// No description provided for @emailDivider.
  ///
  /// In en, this message translates to:
  /// **'or with email'**
  String get emailDivider;

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot password?'**
  String get forgotPassword;

  /// No description provided for @createAccount.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get createAccount;

  /// No description provided for @continueLabel.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueLabel;

  /// No description provided for @sendReset.
  ///
  /// In en, this message translates to:
  /// **'Send reset link'**
  String get sendReset;

  /// No description provided for @newAccount.
  ///
  /// In en, this message translates to:
  /// **'New here? Create an account'**
  String get newAccount;

  /// No description provided for @existingAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account? Log in'**
  String get existingAccount;

  /// No description provided for @verifiedAction.
  ///
  /// In en, this message translates to:
  /// **'I\'ve verified my email'**
  String get verifiedAction;

  /// No description provided for @resendVerification.
  ///
  /// In en, this message translates to:
  /// **'Resend verification email'**
  String get resendVerification;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @profileSaved.
  ///
  /// In en, this message translates to:
  /// **'Profile saved. You are all set for the next chapter!'**
  String get profileSaved;

  /// No description provided for @signOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get signOut;

  /// No description provided for @foodie.
  ///
  /// In en, this message translates to:
  /// **'foodie'**
  String get foodie;

  /// No description provided for @yourEmail.
  ///
  /// In en, this message translates to:
  /// **'your email'**
  String get yourEmail;

  /// No description provided for @emailRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter your email address.'**
  String get emailRequired;

  /// No description provided for @emailInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email address.'**
  String get emailInvalid;

  /// No description provided for @passwordRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter your password.'**
  String get passwordRequired;

  /// No description provided for @passwordShort.
  ///
  /// In en, this message translates to:
  /// **'Use at least 8 characters.'**
  String get passwordShort;

  /// No description provided for @passwordLong.
  ///
  /// In en, this message translates to:
  /// **'This password is too long.'**
  String get passwordLong;

  /// No description provided for @nameRequired.
  ///
  /// In en, this message translates to:
  /// **'Tell us what to call you.'**
  String get nameRequired;

  /// No description provided for @nameLong.
  ///
  /// In en, this message translates to:
  /// **'Keep your name to 50 characters or fewer.'**
  String get nameLong;

  /// No description provided for @nameInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid name.'**
  String get nameInvalid;

  /// No description provided for @genericError.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get genericError;

  /// No description provided for @verificationSent.
  ///
  /// In en, this message translates to:
  /// **'Verification link sent. Check your inbox and spam folder.'**
  String get verificationSent;

  /// No description provided for @notVerified.
  ///
  /// In en, this message translates to:
  /// **'Not verified yet. Open the link in your email, then check again.'**
  String get notVerified;

  /// No description provided for @resetSent.
  ///
  /// In en, this message translates to:
  /// **'If an account exists for this email, a password reset link is on its way. Check your spam folder too.'**
  String get resetSent;

  /// No description provided for @timeoutError.
  ///
  /// In en, this message translates to:
  /// **'This is taking too long. Check your connection and try again.'**
  String get timeoutError;

  /// No description provided for @googleSetup.
  ///
  /// In en, this message translates to:
  /// **'Google sign-in setup is incomplete. Please use email for now.'**
  String get googleSetup;

  /// No description provided for @googleCancelled.
  ///
  /// In en, this message translates to:
  /// **'Google sign-in was cancelled.'**
  String get googleCancelled;

  /// No description provided for @googleUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Google sign-in is unavailable. Try again or use email.'**
  String get googleUnavailable;

  /// No description provided for @wrongCredentials.
  ///
  /// In en, this message translates to:
  /// **'The email or password is incorrect. Try again or reset your password.'**
  String get wrongCredentials;

  /// No description provided for @emailInUse.
  ///
  /// In en, this message translates to:
  /// **'This email already has an account. Log in or reset your password.'**
  String get emailInUse;

  /// No description provided for @weakPassword.
  ///
  /// In en, this message translates to:
  /// **'Choose a stronger password that meets the account password requirements.'**
  String get weakPassword;

  /// No description provided for @networkError.
  ///
  /// In en, this message translates to:
  /// **'Check your internet connection and try again.'**
  String get networkError;

  /// No description provided for @tooManyRequests.
  ///
  /// In en, this message translates to:
  /// **'Too many attempts. Please wait a little before trying again.'**
  String get tooManyRequests;

  /// No description provided for @accountDisabled.
  ///
  /// In en, this message translates to:
  /// **'This account is disabled. Contact support for help.'**
  String get accountDisabled;

  /// No description provided for @providerDisabled.
  ///
  /// In en, this message translates to:
  /// **'This sign-in method has not been enabled yet. Please contact support.'**
  String get providerDisabled;

  /// No description provided for @registrationNotConfigured.
  ///
  /// In en, this message translates to:
  /// **'Account registration is not configured yet. Please contact support.'**
  String get registrationNotConfigured;

  /// No description provided for @appUnauthorized.
  ///
  /// In en, this message translates to:
  /// **'This app is not authorized to sign in. Please contact support.'**
  String get appUnauthorized;

  /// No description provided for @credentialConflict.
  ///
  /// In en, this message translates to:
  /// **'An account already exists with another sign-in method. Use your original method.'**
  String get credentialConflict;

  /// No description provided for @profileDenied.
  ///
  /// In en, this message translates to:
  /// **'Your profile could not be accessed. Please try again later.'**
  String get profileDenied;

  /// No description provided for @popupBlocked.
  ///
  /// In en, this message translates to:
  /// **'Allow the Google sign-in popup in your browser, then try again.'**
  String get popupBlocked;

  /// No description provided for @domainUnauthorized.
  ///
  /// In en, this message translates to:
  /// **'Sign-in is not enabled for this browser address yet.'**
  String get domainUnauthorized;

  /// No description provided for @sessionExpired.
  ///
  /// In en, this message translates to:
  /// **'Your session has expired. Please sign out and sign in again.'**
  String get sessionExpired;

  /// No description provided for @signInConnection.
  ///
  /// In en, this message translates to:
  /// **'Sign-in could not connect. Please try again.'**
  String get signInConnection;

  /// No description provided for @webNotConfigured.
  ///
  /// In en, this message translates to:
  /// **'Browser sign-in is not configured yet. Please use the Android app.'**
  String get webNotConfigured;

  /// No description provided for @platformUnsupported.
  ///
  /// In en, this message translates to:
  /// **'Please use Android, iOS, or the configured browser app to sign in.'**
  String get platformUnsupported;

  /// No description provided for @googleTokenError.
  ///
  /// In en, this message translates to:
  /// **'Google could not verify this account. Please try again.'**
  String get googleTokenError;

  /// No description provided for @signInAgain.
  ///
  /// In en, this message translates to:
  /// **'Please sign in again.'**
  String get signInAgain;

  /// No description provided for @mapSlogan.
  ///
  /// In en, this message translates to:
  /// **'Hungry? Let\'s jajan together!'**
  String get mapSlogan;

  /// No description provided for @mapLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading map...'**
  String get mapLoading;

  /// No description provided for @mapError.
  ///
  /// In en, this message translates to:
  /// **'The map could not load. Check your connection and try again.'**
  String get mapError;

  /// No description provided for @preparingApp.
  ///
  /// In en, this message translates to:
  /// **'Getting Jajan Gangs ready...'**
  String get preparingApp;

  /// No description provided for @previewIntro.
  ///
  /// In en, this message translates to:
  /// **'Find your next food adventure with your gang.'**
  String get previewIntro;

  /// No description provided for @browserPreview.
  ///
  /// In en, this message translates to:
  /// **'Browser preview'**
  String get browserPreview;

  /// No description provided for @previewDetails.
  ///
  /// In en, this message translates to:
  /// **'The app foundation is ready for mobile testing. Firebase and the live Mapbox map are available in the Android/iOS build. This preview does not connect to either service.'**
  String get previewDetails;

  /// No description provided for @mobileOnly.
  ///
  /// In en, this message translates to:
  /// **'Run Jajan Gangs on Android or iOS.'**
  String get mobileOnly;

  /// No description provided for @mapTokenMissing.
  ///
  /// In en, this message translates to:
  /// **'Provide a public Mapbox token using --dart-define-from-file=config/local.json.'**
  String get mapTokenMissing;

  /// No description provided for @startupError.
  ///
  /// In en, this message translates to:
  /// **'Jajan Gangs could not start. Please try again.'**
  String get startupError;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @languageSaveError.
  ///
  /// In en, this message translates to:
  /// **'Language changed, but could not be saved. Please select it again to retry.'**
  String get languageSaveError;

  /// No description provided for @completeTitle.
  ///
  /// In en, this message translates to:
  /// **'You\'re in, {name}!'**
  String completeTitle(String name);

  /// No description provided for @verifySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Verify {email} before joining the gang.'**
  String verifySubtitle(String email);

  /// No description provided for @resendCountdown.
  ///
  /// In en, this message translates to:
  /// **'Resend in {seconds}s'**
  String resendCountdown(int seconds);

  /// No description provided for @signInFailed.
  ///
  /// In en, this message translates to:
  /// **'Sign-in failed ({code}). Please try again.'**
  String signInFailed(String code);

  /// No description provided for @homeTagline.
  ///
  /// In en, this message translates to:
  /// **'Your next bite starts here.'**
  String get homeTagline;

  /// No description provided for @homeProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get homeProfile;

  /// No description provided for @homeGang.
  ///
  /// In en, this message translates to:
  /// **'Gang'**
  String get homeGang;

  /// No description provided for @homeCreate.
  ///
  /// In en, this message translates to:
  /// **'Create Jajan'**
  String get homeCreate;

  /// No description provided for @homeNearby.
  ///
  /// In en, this message translates to:
  /// **'Who\'s hungry nearby?'**
  String get homeNearby;

  /// No description provided for @homeDemo.
  ///
  /// In en, this message translates to:
  /// **'DEMO EVENTS'**
  String get homeDemo;

  /// No description provided for @homeDemoDetails.
  ///
  /// In en, this message translates to:
  /// **'Local examples only. No real people or live events are shown.'**
  String get homeDemoDetails;

  /// No description provided for @homeComingSoon.
  ///
  /// In en, this message translates to:
  /// **'This page is coming next. For now, explore the map and sample Jajan events.'**
  String get homeComingSoon;

  /// No description provided for @homeBackMap.
  ///
  /// In en, this message translates to:
  /// **'Back to the map'**
  String get homeBackMap;

  /// No description provided for @homePrivacy.
  ///
  /// In en, this message translates to:
  /// **'Your area, not your address.'**
  String get homePrivacy;

  /// No description provided for @homePrivacyDetails.
  ///
  /// In en, this message translates to:
  /// **'We use rounded areas to find nearby Jajans. Exact coordinates stay on your device. Events share only a broad area.'**
  String get homePrivacyDetails;

  /// No description provided for @homeLocate.
  ///
  /// In en, this message translates to:
  /// **'Find my area'**
  String get homeLocate;

  /// No description provided for @homeSettings.
  ///
  /// In en, this message translates to:
  /// **'Open device settings'**
  String get homeSettings;

  /// No description provided for @homeRecenter.
  ///
  /// In en, this message translates to:
  /// **'Recenter map'**
  String get homeRecenter;

  /// No description provided for @homeJakarta.
  ///
  /// In en, this message translates to:
  /// **'Map preview · location unavailable'**
  String get homeJakarta;

  /// No description provided for @homeApproximate.
  ///
  /// In en, this message translates to:
  /// **'Your approximate area'**
  String get homeApproximate;

  /// No description provided for @homeMapSetup.
  ///
  /// In en, this message translates to:
  /// **'The map needs a Mapbox token. Start the app with --dart-define-from-file=config/local.json.'**
  String get homeMapSetup;

  /// No description provided for @locationFinding.
  ///
  /// In en, this message translates to:
  /// **'Finding your area…'**
  String get locationFinding;

  /// No description provided for @locationOff.
  ///
  /// In en, this message translates to:
  /// **'Location services are off. Turn on Location in device settings, then retry.'**
  String get locationOff;

  /// No description provided for @locationBlocked.
  ///
  /// In en, this message translates to:
  /// **'Location permission is blocked. Allow location for Jajan Gangs in app settings. Approximate location is enough.'**
  String get locationBlocked;

  /// No description provided for @locationDenied.
  ///
  /// In en, this message translates to:
  /// **'Location permission was declined. Tap Find my area to try again, or allow it in app settings.'**
  String get locationDenied;

  /// No description provided for @locationUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Your device could not provide a location. Check location access and connectivity, then retry.'**
  String get locationUnavailable;

  /// No description provided for @locationApproximate.
  ///
  /// In en, this message translates to:
  /// **'Only your approximate area is displayed. Your exact position stays private.'**
  String get locationApproximate;

  /// No description provided for @demoNoodles.
  ///
  /// In en, this message translates to:
  /// **'Noodle squad'**
  String get demoNoodles;

  /// No description provided for @demoCoffee.
  ///
  /// In en, this message translates to:
  /// **'Coffee break'**
  String get demoCoffee;

  /// No description provided for @demoSatay.
  ///
  /// In en, this message translates to:
  /// **'Satay tonight'**
  String get demoSatay;

  /// No description provided for @demoBurger.
  ///
  /// In en, this message translates to:
  /// **'Burger buddies'**
  String get demoBurger;

  /// No description provided for @homeDistance.
  ///
  /// In en, this message translates to:
  /// **'About {distance} km from area center'**
  String homeDistance(String distance);

  /// No description provided for @homeMembers.
  ///
  /// In en, this message translates to:
  /// **'Demo · {members}/{capacity} members'**
  String homeMembers(int members, int capacity);

  /// No description provided for @avatarChoose.
  ///
  /// In en, this message translates to:
  /// **'Pick your character'**
  String get avatarChoose;

  /// No description provided for @avatarHint.
  ///
  /// In en, this message translates to:
  /// **'Choose your character for the next food adventure.'**
  String get avatarHint;

  /// No description provided for @avatarRequired.
  ///
  /// In en, this message translates to:
  /// **'Choose a character to continue.'**
  String get avatarRequired;

  /// No description provided for @avatarCat.
  ///
  /// In en, this message translates to:
  /// **'Wink Cat'**
  String get avatarCat;

  /// No description provided for @avatarFrog.
  ///
  /// In en, this message translates to:
  /// **'Snack Frog'**
  String get avatarFrog;

  /// No description provided for @avatarRobot.
  ///
  /// In en, this message translates to:
  /// **'Beep Bot'**
  String get avatarRobot;

  /// No description provided for @avatarPanda.
  ///
  /// In en, this message translates to:
  /// **'Panda Pal'**
  String get avatarPanda;

  /// No description provided for @avatarFox.
  ///
  /// In en, this message translates to:
  /// **'Cheeky Fox'**
  String get avatarFox;

  /// No description provided for @avatarBunny.
  ///
  /// In en, this message translates to:
  /// **'Bouncy Bunny'**
  String get avatarBunny;

  /// No description provided for @avatarBear.
  ///
  /// In en, this message translates to:
  /// **'Honey Bear'**
  String get avatarBear;

  /// No description provided for @avatarAlien.
  ///
  /// In en, this message translates to:
  /// **'Little Alien'**
  String get avatarAlien;

  /// No description provided for @avatarPenguin.
  ///
  /// In en, this message translates to:
  /// **'Chilly Penguin'**
  String get avatarPenguin;

  /// No description provided for @avatarMonster.
  ///
  /// In en, this message translates to:
  /// **'Munch Monster'**
  String get avatarMonster;

  /// No description provided for @cravingAnything.
  ///
  /// In en, this message translates to:
  /// **'Anything'**
  String get cravingAnything;

  /// No description provided for @cravingFastFood.
  ///
  /// In en, this message translates to:
  /// **'Fast Food'**
  String get cravingFastFood;

  /// No description provided for @cravingChicken.
  ///
  /// In en, this message translates to:
  /// **'Chicken'**
  String get cravingChicken;

  /// No description provided for @cravingPizza.
  ///
  /// In en, this message translates to:
  /// **'Pizza'**
  String get cravingPizza;

  /// No description provided for @cravingCafe.
  ///
  /// In en, this message translates to:
  /// **'Cafe'**
  String get cravingCafe;

  /// No description provided for @cravingStreetFood.
  ///
  /// In en, this message translates to:
  /// **'Street Food'**
  String get cravingStreetFood;

  /// No description provided for @jajanCreateIntro.
  ///
  /// In en, this message translates to:
  /// **'A craving, a few friends, and a little adventure.'**
  String get jajanCreateIntro;

  /// No description provided for @jajanCravingQuestion.
  ///
  /// In en, this message translates to:
  /// **'What are you craving?'**
  String get jajanCravingQuestion;

  /// No description provided for @jajanPeopleQuestion.
  ///
  /// In en, this message translates to:
  /// **'How many people?'**
  String get jajanPeopleQuestion;

  /// No description provided for @jajanIncludesCreator.
  ///
  /// In en, this message translates to:
  /// **'Total gang size, including you.'**
  String get jajanIncludesCreator;

  /// No description provided for @jajanFivePlus.
  ///
  /// In en, this message translates to:
  /// **'5+'**
  String get jajanFivePlus;

  /// No description provided for @jajanFewer.
  ///
  /// In en, this message translates to:
  /// **'Fewer people'**
  String get jajanFewer;

  /// No description provided for @jajanMore.
  ///
  /// In en, this message translates to:
  /// **'More people'**
  String get jajanMore;

  /// No description provided for @jajanExpiryHint.
  ///
  /// In en, this message translates to:
  /// **'Starts OPEN and expires 45 minutes after the chosen start time.'**
  String get jajanExpiryHint;

  /// No description provided for @jajanLocationRequired.
  ///
  /// In en, this message translates to:
  /// **'Get your approximate area before creating a Jajan. We will not publish an event at the Jakarta preview location.'**
  String get jajanLocationRequired;

  /// No description provided for @jajanApproximateShare.
  ///
  /// In en, this message translates to:
  /// **'Only your rounded area is saved with this event. Your exact position is never shared.'**
  String get jajanApproximateShare;

  /// No description provided for @jajanCapacityInvalid.
  ///
  /// In en, this message translates to:
  /// **'Choose a gang size between 2 and 12 people.'**
  String get jajanCapacityInvalid;

  /// No description provided for @jajanPending.
  ///
  /// In en, this message translates to:
  /// **'A creation request is pending. Retry to confirm the same event without creating a duplicate. Your original choices are kept.'**
  String get jajanPending;

  /// No description provided for @jajanRetryCreate.
  ///
  /// In en, this message translates to:
  /// **'Confirm / retry creation'**
  String get jajanRetryCreate;

  /// No description provided for @jajanDraftError.
  ///
  /// In en, this message translates to:
  /// **'We could not restore or save your creation request. Please retry before continuing.'**
  String get jajanDraftError;

  /// No description provided for @jajanSaveError.
  ///
  /// In en, this message translates to:
  /// **'Your Jajan could not be confirmed. Please retry; the same request will be reused.'**
  String get jajanSaveError;

  /// No description provided for @jajanPermission.
  ///
  /// In en, this message translates to:
  /// **'Event creation is not available yet. Please contact support or try again after setup is completed.'**
  String get jajanPermission;

  /// No description provided for @jajanRetrySafe.
  ///
  /// In en, this message translates to:
  /// **'The connection was interrupted. Retry to check the same event; you will not create a duplicate.'**
  String get jajanRetrySafe;

  /// No description provided for @jajanLoadError.
  ///
  /// In en, this message translates to:
  /// **'Your saved events could not load. Tap to retry.'**
  String get jajanLoadError;

  /// No description provided for @jajanCreated.
  ///
  /// In en, this message translates to:
  /// **'Jajan created! Your gang is OPEN.'**
  String get jajanCreated;

  /// No description provided for @jajanRecoveredExpired.
  ///
  /// In en, this message translates to:
  /// **'This earlier Jajan was saved, but has already expired. You can create a new one.'**
  String get jajanRecoveredExpired;

  /// No description provided for @jajanOpen.
  ///
  /// In en, this message translates to:
  /// **'OPEN · YOUR JAJAN'**
  String get jajanOpen;

  /// No description provided for @jajanOwnEvent.
  ///
  /// In en, this message translates to:
  /// **'Your saved Jajan. Expires after 45 minutes. Joining and public discovery are coming next.'**
  String get jajanOwnEvent;

  /// No description provided for @jajanExactCapacity.
  ///
  /// In en, this message translates to:
  /// **'Total: {count} people (up to 12)'**
  String jajanExactCapacity(int count);

  /// No description provided for @jajanMemberCount.
  ///
  /// In en, this message translates to:
  /// **'{members}/{capacity} members'**
  String jajanMemberCount(int members, int capacity);

  /// No description provided for @locationTimeout.
  ///
  /// In en, this message translates to:
  /// **'Your device did not return a location in time. Check Location and Wi-Fi or mobile data, then retry.'**
  String get locationTimeout;

  /// No description provided for @jajanLocationOff.
  ///
  /// In en, this message translates to:
  /// **'Turn on location services in device settings, then tap Create Jajan again. Your choices are saved on this form.'**
  String get jajanLocationOff;

  /// No description provided for @jajanLocationBlocked.
  ///
  /// In en, this message translates to:
  /// **'Allow location access for Jajan Gangs in device settings, then tap Create Jajan again. Approximate location is enough.'**
  String get jajanLocationBlocked;

  /// No description provided for @jajanLocationDenied.
  ///
  /// In en, this message translates to:
  /// **'We need your approximate area to create a Jajan. Tap Create Jajan again and allow location access when asked.'**
  String get jajanLocationDenied;

  /// No description provided for @jajanLocationTimeout.
  ///
  /// In en, this message translates to:
  /// **'Your phone could not find a recent area. Check Location and Wi-Fi or mobile data, then tap Create Jajan to retry. Your form is kept.'**
  String get jajanLocationTimeout;

  /// No description provided for @jajanLocationUnavailable.
  ///
  /// In en, this message translates to:
  /// **'We could not find your area. Check location access and your connection, then tap Create Jajan again.'**
  String get jajanLocationUnavailable;

  /// No description provided for @jajanCreating.
  ///
  /// In en, this message translates to:
  /// **'Creating your Jajan…'**
  String get jajanCreating;

  /// No description provided for @jajanSettingsUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Open your device settings manually and check location services and location permission for Jajan Gangs. Then return and tap Create Jajan again.'**
  String get jajanSettingsUnavailable;

  /// No description provided for @eventDetails.
  ///
  /// In en, this message translates to:
  /// **'Jajan Details'**
  String get eventDetails;

  /// No description provided for @eventYourJajan.
  ///
  /// In en, this message translates to:
  /// **'Your Jajan'**
  String get eventYourJajan;

  /// No description provided for @eventIntro.
  ///
  /// In en, this message translates to:
  /// **'Good food tastes better with a gang.'**
  String get eventIntro;

  /// No description provided for @eventHost.
  ///
  /// In en, this message translates to:
  /// **'Gang host'**
  String get eventHost;

  /// No description provided for @eventJoin.
  ///
  /// In en, this message translates to:
  /// **'JOIN JAJAN'**
  String get eventJoin;

  /// No description provided for @eventRequestSent.
  ///
  /// In en, this message translates to:
  /// **'Request sent'**
  String get eventRequestSent;

  /// No description provided for @eventRequestExplanation.
  ///
  /// In en, this message translates to:
  /// **'Your request is pending. You will join the gang once the host accepts it.'**
  String get eventRequestExplanation;

  /// No description provided for @eventRequestPending.
  ///
  /// In en, this message translates to:
  /// **'Waiting for the host'**
  String get eventRequestPending;

  /// No description provided for @eventViewRequests.
  ///
  /// In en, this message translates to:
  /// **'View Requests'**
  String get eventViewRequests;

  /// No description provided for @eventRequestsNote.
  ///
  /// In en, this message translates to:
  /// **'People who asked to join your gang. Refresh to see new requests.'**
  String get eventRequestsNote;

  /// No description provided for @eventNoRequests.
  ///
  /// In en, this message translates to:
  /// **'No requests yet. Your next foodie friend could arrive soon!'**
  String get eventNoRequests;

  /// No description provided for @eventLoadMore.
  ///
  /// In en, this message translates to:
  /// **'Load more'**
  String get eventLoadMore;

  /// No description provided for @eventRefresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get eventRefresh;

  /// No description provided for @eventExpired.
  ///
  /// In en, this message translates to:
  /// **'This Jajan has expired'**
  String get eventExpired;

  /// No description provided for @eventClosed.
  ///
  /// In en, this message translates to:
  /// **'This Jajan is no longer accepting requests.'**
  String get eventClosed;

  /// No description provided for @eventFull.
  ///
  /// In en, this message translates to:
  /// **'This gang is full'**
  String get eventFull;

  /// No description provided for @eventAlreadyMember.
  ///
  /// In en, this message translates to:
  /// **'You are in this gang'**
  String get eventAlreadyMember;

  /// No description provided for @eventAreaPrivacy.
  ///
  /// In en, this message translates to:
  /// **'Distance is estimated between rounded areas. Exact locations are never shared.'**
  String get eventAreaPrivacy;

  /// No description provided for @eventSameArea.
  ///
  /// In en, this message translates to:
  /// **'In your approximate area'**
  String get eventSameArea;

  /// No description provided for @eventDistanceUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Your approximate area is not available yet.'**
  String get eventDistanceUnavailable;

  /// No description provided for @eventOffline.
  ///
  /// In en, this message translates to:
  /// **'Waiting for a connection to confirm this event. Joining is available once it is confirmed.'**
  String get eventOffline;

  /// No description provided for @eventUnavailable.
  ///
  /// In en, this message translates to:
  /// **'This Jajan is no longer available. It may have been cancelled.'**
  String get eventUnavailable;

  /// No description provided for @eventLoadError.
  ///
  /// In en, this message translates to:
  /// **'We could not load the event or your request. Check your connection and try again.'**
  String get eventLoadError;

  /// No description provided for @eventRequestsError.
  ///
  /// In en, this message translates to:
  /// **'We could not load the requests. Refresh to try again.'**
  String get eventRequestsError;

  /// No description provided for @eventJoinError.
  ///
  /// In en, this message translates to:
  /// **'We could not confirm your request. Check your connection and retry. If the event is full or expired, joining is no longer available. Retrying will not create a duplicate request.'**
  String get eventJoinError;

  /// No description provided for @eventTapDetails.
  ///
  /// In en, this message translates to:
  /// **'Open details to see the host and join this Jajan.'**
  String get eventTapDetails;

  /// No description provided for @jajanDiscoveryError.
  ///
  /// In en, this message translates to:
  /// **'Nearby events could not be loaded. Tap to retry.'**
  String get jajanDiscoveryError;

  /// No description provided for @eventPublicHint.
  ///
  /// In en, this message translates to:
  /// **'Your name, character and approximate area will be visible to signed-in foodies.'**
  String get eventPublicHint;

  /// No description provided for @eventOwnerHungry.
  ///
  /// In en, this message translates to:
  /// **'{name} is hungry!'**
  String eventOwnerHungry(String name);

  /// No description provided for @eventTimeLeft.
  ///
  /// In en, this message translates to:
  /// **'Expires in {minutes}:{seconds}'**
  String eventTimeLeft(String minutes, String seconds);

  /// No description provided for @eventRequestCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No pending requests} =1{1 pending request} other{{count} pending requests}}'**
  String eventRequestCount(int count);

  /// No description provided for @locationNeeded.
  ///
  /// In en, this message translates to:
  /// **'Allow approximate location to find nearby Jajans and show distance.'**
  String get locationNeeded;

  /// No description provided for @locationSettingsUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Open device settings manually and check Location and the location permission for Jajan Gangs. Return here and tap Find my area.'**
  String get locationSettingsUnavailable;

  /// No description provided for @locationFixOnMap.
  ///
  /// In en, this message translates to:
  /// **'Back to map to find my area'**
  String get locationFixOnMap;

  /// No description provided for @homeFindingEvents.
  ///
  /// In en, this message translates to:
  /// **'Looking for your next gang…'**
  String get homeFindingEvents;

  /// No description provided for @homeNoEvents.
  ///
  /// In en, this message translates to:
  /// **'No active Jajans nearby yet'**
  String get homeNoEvents;

  /// No description provided for @homeNoEventsHint.
  ///
  /// In en, this message translates to:
  /// **'Start a Jajan and invite others to join, or refresh to look again.'**
  String get homeNoEventsHint;

  /// No description provided for @homeAreaNeeded.
  ///
  /// In en, this message translates to:
  /// **'Find your area to discover Jajans'**
  String get homeAreaNeeded;

  /// No description provided for @homeAreaNeededHint.
  ///
  /// In en, this message translates to:
  /// **'You can still create a Jajan. We will ask for location when you submit.'**
  String get homeAreaNeededHint;

  /// No description provided for @homeEventsUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Could not load Jajans'**
  String get homeEventsUnavailable;

  /// No description provided for @homeEventsUnavailableHint.
  ///
  /// In en, this message translates to:
  /// **'Check your connection and refresh. You can still start your own Jajan.'**
  String get homeEventsUnavailableHint;

  /// No description provided for @jajanAlreadyActive.
  ///
  /// In en, this message translates to:
  /// **'You already have an active or scheduled Jajan. Complete or cancel it, or wait for it to expire before creating another.'**
  String get jajanAlreadyActive;

  /// No description provided for @jajanActiveCheckFailed.
  ///
  /// In en, this message translates to:
  /// **'We could not check whether you have an active Jajan. Check your connection and try again.'**
  String get jajanActiveCheckFailed;

  /// No description provided for @jajanCheckingActive.
  ///
  /// In en, this message translates to:
  /// **'Checking your Jajan…'**
  String get jajanCheckingActive;

  /// No description provided for @gotIt.
  ///
  /// In en, this message translates to:
  /// **'Got it'**
  String get gotIt;

  /// No description provided for @requestsTitle.
  ///
  /// In en, this message translates to:
  /// **'People want to jajan with you'**
  String get requestsTitle;

  /// No description provided for @requestsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose who joins your gang. The host counts toward the group size.'**
  String get requestsSubtitle;

  /// No description provided for @requestAccept.
  ///
  /// In en, this message translates to:
  /// **'Accept'**
  String get requestAccept;

  /// No description provided for @requestReject.
  ///
  /// In en, this message translates to:
  /// **'Reject'**
  String get requestReject;

  /// No description provided for @requestAccepted.
  ///
  /// In en, this message translates to:
  /// **'Accepted'**
  String get requestAccepted;

  /// No description provided for @requestRejected.
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get requestRejected;

  /// No description provided for @requestAcceptedMessage.
  ///
  /// In en, this message translates to:
  /// **'You’re in! The host accepted your request.'**
  String get requestAcceptedMessage;

  /// No description provided for @requestRejectedMessage.
  ///
  /// In en, this message translates to:
  /// **'The host declined your request. You can find another Jajan on the map.'**
  String get requestRejectedMessage;

  /// No description provided for @requestAlreadyDecided.
  ///
  /// In en, this message translates to:
  /// **'This request has already been handled. Refresh to see the latest requests.'**
  String get requestAlreadyDecided;

  /// No description provided for @requestDecisionFailed.
  ///
  /// In en, this message translates to:
  /// **'We could not confirm your decision. Check your connection and retry. Repeating the same decision will not add the member twice.'**
  String get requestDecisionFailed;

  /// No description provided for @eventCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel Jajan'**
  String get eventCancel;

  /// No description provided for @eventCancelTitle.
  ///
  /// In en, this message translates to:
  /// **'Cancel this Jajan?'**
  String get eventCancelTitle;

  /// No description provided for @eventCancelWarning.
  ///
  /// In en, this message translates to:
  /// **'This will permanently delete this Jajan, all join requests and its membership data, even if people have already joined. This cannot be undone.'**
  String get eventCancelWarning;

  /// No description provided for @eventKeep.
  ///
  /// In en, this message translates to:
  /// **'Keep Jajan'**
  String get eventKeep;

  /// No description provided for @eventCancelled.
  ///
  /// In en, this message translates to:
  /// **'This Jajan has been cancelled'**
  String get eventCancelled;

  /// No description provided for @eventCleaningUp.
  ///
  /// In en, this message translates to:
  /// **'Finishing cancellation…'**
  String get eventCleaningUp;

  /// No description provided for @eventFinishCancellation.
  ///
  /// In en, this message translates to:
  /// **'Finish cancellation'**
  String get eventFinishCancellation;

  /// No description provided for @eventCancelFailed.
  ///
  /// In en, this message translates to:
  /// **'We could not confirm deletion. Tap Retry to continue cancellation.'**
  String get eventCancelFailed;

  /// No description provided for @eventCleanupPending.
  ///
  /// In en, this message translates to:
  /// **'A cancellation still needs to finish. Tap to retry cleanup.'**
  String get eventCleanupPending;

  /// No description provided for @eventCancellationDetails.
  ///
  /// In en, this message translates to:
  /// **'Cancelling removes this Jajan, its messages, join requests and membership data.'**
  String get eventCancellationDetails;

  /// No description provided for @eventCancellationPending.
  ///
  /// In en, this message translates to:
  /// **'Cancellation pending'**
  String get eventCancellationPending;

  /// No description provided for @eventCancellationNotice.
  ///
  /// In en, this message translates to:
  /// **'Deletion is not finished yet. This Jajan is no longer accepting requests.'**
  String get eventCancellationNotice;

  /// No description provided for @eventCancelConnection.
  ///
  /// In en, this message translates to:
  /// **'We could not confirm deletion after retrying. Check your connection, then tap Retry to continue.'**
  String get eventCancelConnection;

  /// No description provided for @eventCancelPermission.
  ///
  /// In en, this message translates to:
  /// **'Cancellation was not permitted. Please try again later or contact support if this continues.'**
  String get eventCancelPermission;

  /// No description provided for @chatTitle.
  ///
  /// In en, this message translates to:
  /// **'Jajan Gang'**
  String get chatTitle;

  /// No description provided for @chatSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Good food. Great company.'**
  String get chatSubtitle;

  /// No description provided for @chatTemporary.
  ///
  /// In en, this message translates to:
  /// **'YOUR TEMPORARY GANG • ONE FOOD ADVENTURE'**
  String get chatTemporary;

  /// No description provided for @chatMembers.
  ///
  /// In en, this message translates to:
  /// **'Meet your gang'**
  String get chatMembers;

  /// No description provided for @chatOpen.
  ///
  /// In en, this message translates to:
  /// **'Open Gang Chat'**
  String get chatOpen;

  /// No description provided for @chatMyGangs.
  ///
  /// In en, this message translates to:
  /// **'Your temporary gangs'**
  String get chatMyGangs;

  /// No description provided for @chatNoGangs.
  ///
  /// In en, this message translates to:
  /// **'Your gang starts here. Create a Jajan or join one to unlock a chat!'**
  String get chatNoGangs;

  /// No description provided for @chatHint.
  ///
  /// In en, this message translates to:
  /// **'Type a message…'**
  String get chatHint;

  /// No description provided for @chatSend.
  ///
  /// In en, this message translates to:
  /// **'Send message'**
  String get chatSend;

  /// No description provided for @chatYou.
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get chatYou;

  /// No description provided for @chatOlder.
  ///
  /// In en, this message translates to:
  /// **'Load older messages'**
  String get chatOlder;

  /// No description provided for @chatEmpty.
  ///
  /// In en, this message translates to:
  /// **'The gang is here!'**
  String get chatEmpty;

  /// No description provided for @chatEmptyHint.
  ///
  /// In en, this message translates to:
  /// **'Break the ice. What are we eating?'**
  String get chatEmptyHint;

  /// No description provided for @chatClosed.
  ///
  /// In en, this message translates to:
  /// **'This chat is closed or you no longer have access.'**
  String get chatClosed;

  /// No description provided for @chatLoadError.
  ///
  /// In en, this message translates to:
  /// **'We could not load the chat. Check your connection and retry.'**
  String get chatLoadError;

  /// No description provided for @chatMembersError.
  ///
  /// In en, this message translates to:
  /// **'We could not load the member list. Reopen the chat to retry.'**
  String get chatMembersError;

  /// No description provided for @chatSendError.
  ///
  /// In en, this message translates to:
  /// **'Message not confirmed. Tap Send again to retry; your text is still here.'**
  String get chatSendError;

  /// No description provided for @chatInvalid.
  ///
  /// In en, this message translates to:
  /// **'Write a message of 1–1,000 characters.'**
  String get chatInvalid;

  /// No description provided for @chatNotifications.
  ///
  /// In en, this message translates to:
  /// **'Enable chat notifications'**
  String get chatNotifications;

  /// No description provided for @chatNotificationsOn.
  ///
  /// In en, this message translates to:
  /// **'Gang notifications are enabled on this device.'**
  String get chatNotificationsOn;

  /// No description provided for @chatNotificationsError.
  ///
  /// In en, this message translates to:
  /// **'Notifications could not be enabled. Check app permissions in Settings and try again.'**
  String get chatNotificationsError;

  /// No description provided for @chatNewMessage.
  ///
  /// In en, this message translates to:
  /// **'Your gang has a new message!'**
  String get chatNewMessage;

  /// No description provided for @chatFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to send. Tap to retry.'**
  String get chatFailed;

  /// No description provided for @chatPending.
  ///
  /// In en, this message translates to:
  /// **'Sending message'**
  String get chatPending;

  /// No description provided for @chatSent.
  ///
  /// In en, this message translates to:
  /// **'Message sent'**
  String get chatSent;

  /// No description provided for @eventViewMembers.
  ///
  /// In en, this message translates to:
  /// **'View Members'**
  String get eventViewMembers;

  /// No description provided for @chatInbox.
  ///
  /// In en, this message translates to:
  /// **'Chats'**
  String get chatInbox;

  /// No description provided for @chatMoreRooms.
  ///
  /// In en, this message translates to:
  /// **'Load more chats'**
  String get chatMoreRooms;

  /// No description provided for @chatUnread.
  ///
  /// In en, this message translates to:
  /// **'Unread messages'**
  String get chatUnread;

  /// No description provided for @activityTitle.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get activityTitle;

  /// No description provided for @activityLimit.
  ///
  /// In en, this message translates to:
  /// **'Your 10 most recent notifications. Message alerts are grouped by chat.'**
  String get activityLimit;

  /// No description provided for @activityEmpty.
  ///
  /// In en, this message translates to:
  /// **'All quiet for now. Your gang updates will appear here.'**
  String get activityEmpty;

  /// No description provided for @activityAccepted.
  ///
  /// In en, this message translates to:
  /// **'Your request to join a Jajan has been accepted!'**
  String get activityAccepted;

  /// No description provided for @activityRejected.
  ///
  /// In en, this message translates to:
  /// **'Your request to join a Jajan was declined.'**
  String get activityRejected;

  /// No description provided for @activityError.
  ///
  /// In en, this message translates to:
  /// **'We could not load this update. Check your connection and try again.'**
  String get activityError;

  /// No description provided for @activityUnread.
  ///
  /// In en, this message translates to:
  /// **'Unread notification'**
  String get activityUnread;

  /// No description provided for @chatPreview.
  ///
  /// In en, this message translates to:
  /// **'{name}: {text}'**
  String chatPreview(String name, String text);

  /// No description provided for @pollTitle.
  ///
  /// In en, this message translates to:
  /// **'Where should we go?'**
  String get pollTitle;

  /// No description provided for @pollSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Pick the gang’s next food stop'**
  String get pollSubtitle;

  /// No description provided for @pollCreate.
  ///
  /// In en, this message translates to:
  /// **'Create a vote'**
  String get pollCreate;

  /// No description provided for @pollCreateHint.
  ///
  /// In en, this message translates to:
  /// **'Add 2–5 destinations. Starting the vote closes new join requests and freezes the member list.'**
  String get pollCreateHint;

  /// No description provided for @pollWaiting.
  ///
  /// In en, this message translates to:
  /// **'Any gang member can start a destination vote here.'**
  String get pollWaiting;

  /// No description provided for @pollAdd.
  ///
  /// In en, this message translates to:
  /// **'Add destination'**
  String get pollAdd;

  /// No description provided for @pollRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove last destination'**
  String get pollRemove;

  /// No description provided for @pollInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter 2–5 different destination names, up to 60 characters each.'**
  String get pollInvalid;

  /// No description provided for @pollTap.
  ///
  /// In en, this message translates to:
  /// **'Tap a destination to vote. You can change your vote until the host finishes.'**
  String get pollTap;

  /// No description provided for @pollYourVote.
  ///
  /// In en, this message translates to:
  /// **'Your vote'**
  String get pollYourVote;

  /// No description provided for @pollFinish.
  ///
  /// In en, this message translates to:
  /// **'Finish voting'**
  String get pollFinish;

  /// No description provided for @pollFinishHint.
  ///
  /// In en, this message translates to:
  /// **'Confirm the destination below. Voting will close for everyone.'**
  String get pollFinishHint;

  /// No description provided for @pollTie.
  ///
  /// In en, this message translates to:
  /// **'It’s a tie! Choose the destination'**
  String get pollTie;

  /// No description provided for @pollNoVotes.
  ///
  /// In en, this message translates to:
  /// **'At least one vote is needed to finish.'**
  String get pollNoVotes;

  /// No description provided for @pollDestination.
  ///
  /// In en, this message translates to:
  /// **'Destination Selected 🎉'**
  String get pollDestination;

  /// No description provided for @pollClosed.
  ///
  /// In en, this message translates to:
  /// **'Voting is closed or this Jajan has expired.'**
  String get pollClosed;

  /// No description provided for @pollError.
  ///
  /// In en, this message translates to:
  /// **'Could not update voting. Check your connection and retry.'**
  String get pollError;

  /// No description provided for @pollChanged.
  ///
  /// In en, this message translates to:
  /// **'Votes changed. Review the latest results and finish again.'**
  String get pollChanged;

  /// No description provided for @pollExists.
  ///
  /// In en, this message translates to:
  /// **'This gang already has a vote. Open the current poll.'**
  String get pollExists;

  /// No description provided for @pollOption.
  ///
  /// In en, this message translates to:
  /// **'Destination {number}'**
  String pollOption(int number);

  /// No description provided for @pollVotes.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No votes yet} =1{1 vote} other{{count} votes}}'**
  String pollVotes(int count);

  /// No description provided for @activityJoinRequest.
  ///
  /// In en, this message translates to:
  /// **'{name} requested to join your Jajan.'**
  String activityJoinRequest(String name);

  /// No description provided for @descriptionLabel.
  ///
  /// In en, this message translates to:
  /// **'Short description (optional)'**
  String get descriptionLabel;

  /// No description provided for @descriptionHint.
  ///
  /// In en, this message translates to:
  /// **'Suggest a place or share your plan…'**
  String get descriptionHint;

  /// No description provided for @descriptionTooLong.
  ///
  /// In en, this message translates to:
  /// **'Keep the description within 150 characters.'**
  String get descriptionTooLong;

  /// No description provided for @eventGoing.
  ///
  /// In en, this message translates to:
  /// **'Going There'**
  String get eventGoing;

  /// No description provided for @eventStartTrip.
  ///
  /// In en, this message translates to:
  /// **'We’re on the way!'**
  String get eventStartTrip;

  /// No description provided for @eventCompleteAction.
  ///
  /// In en, this message translates to:
  /// **'Complete Jajan'**
  String get eventCompleteAction;

  /// No description provided for @eventCompleteTitle.
  ///
  /// In en, this message translates to:
  /// **'🎉 JAJAN COMPLETE!'**
  String get eventCompleteTitle;

  /// No description provided for @eventCompleteWith.
  ///
  /// In en, this message translates to:
  /// **'You jajanned with:'**
  String get eventCompleteWith;

  /// No description provided for @eventDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get eventDone;

  /// No description provided for @eventStatusFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not update the Jajan status. Check your connection and retry.'**
  String get eventStatusFailed;

  /// No description provided for @eventStatusChanged.
  ///
  /// In en, this message translates to:
  /// **'This Jajan has changed or expired. Check its latest status.'**
  String get eventStatusChanged;

  /// No description provided for @eventDescription.
  ///
  /// In en, this message translates to:
  /// **'The plan'**
  String get eventDescription;

  /// No description provided for @friendsTitle.
  ///
  /// In en, this message translates to:
  /// **'My Friends'**
  String get friendsTitle;

  /// No description provided for @friendProfile.
  ///
  /// In en, this message translates to:
  /// **'Foodie profile'**
  String get friendProfile;

  /// No description provided for @friendAdd.
  ///
  /// In en, this message translates to:
  /// **'Add Friend'**
  String get friendAdd;

  /// No description provided for @friendAccept.
  ///
  /// In en, this message translates to:
  /// **'Accept'**
  String get friendAccept;

  /// No description provided for @friendDecline.
  ///
  /// In en, this message translates to:
  /// **'Decline'**
  String get friendDecline;

  /// No description provided for @friendCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel request'**
  String get friendCancel;

  /// No description provided for @friendRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove friend'**
  String get friendRemove;

  /// No description provided for @friendRemoveHint.
  ///
  /// In en, this message translates to:
  /// **'Remove this person from your friends? You can still meet in Jajan events.'**
  String get friendRemoveHint;

  /// No description provided for @friendIncoming.
  ///
  /// In en, this message translates to:
  /// **'Incoming'**
  String get friendIncoming;

  /// No description provided for @friendOutgoing.
  ///
  /// In en, this message translates to:
  /// **'Sent'**
  String get friendOutgoing;

  /// No description provided for @friendIncomingHint.
  ///
  /// In en, this message translates to:
  /// **'Wants to be your friend'**
  String get friendIncomingHint;

  /// No description provided for @friendPending.
  ///
  /// In en, this message translates to:
  /// **'Friend request sent'**
  String get friendPending;

  /// No description provided for @friendConnected.
  ///
  /// In en, this message translates to:
  /// **'You’re friends!'**
  String get friendConnected;

  /// No description provided for @friendNotConnected.
  ///
  /// In en, this message translates to:
  /// **'You’re not connected as friends.'**
  String get friendNotConnected;

  /// No description provided for @friendsEmpty.
  ///
  /// In en, this message translates to:
  /// **'Meet your next food buddy! Open an event’s member list and tap someone to add a friend.'**
  String get friendsEmpty;

  /// No description provided for @friendRequestsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No friend requests here yet.'**
  String get friendRequestsEmpty;

  /// No description provided for @friendError.
  ///
  /// In en, this message translates to:
  /// **'Could not load or update friends. Check your connection and retry.'**
  String get friendError;

  /// No description provided for @friendUnavailable.
  ///
  /// In en, this message translates to:
  /// **'This profile is unavailable. Open an existing event’s member list and try again.'**
  String get friendUnavailable;

  /// No description provided for @friendChanged.
  ///
  /// In en, this message translates to:
  /// **'This request has changed. Check its latest status.'**
  String get friendChanged;

  /// No description provided for @friendPrivacy.
  ///
  /// In en, this message translates to:
  /// **'Only your name and avatar are shared. Your email and location stay private.'**
  String get friendPrivacy;

  /// No description provided for @friendNotification.
  ///
  /// In en, this message translates to:
  /// **'{name} sent you a friend request.'**
  String friendNotification(String name);

  /// No description provided for @passportTitle.
  ///
  /// In en, this message translates to:
  /// **'Food Passport'**
  String get passportTitle;

  /// No description provided for @passportAdd.
  ///
  /// In en, this message translates to:
  /// **'Add a food memory'**
  String get passportAdd;

  /// No description provided for @passportRestaurant.
  ///
  /// In en, this message translates to:
  /// **'Restaurant / place'**
  String get passportRestaurant;

  /// No description provided for @passportDish.
  ///
  /// In en, this message translates to:
  /// **'What did you eat?'**
  String get passportDish;

  /// No description provided for @passportReview.
  ///
  /// In en, this message translates to:
  /// **'Your short review (optional)'**
  String get passportReview;

  /// No description provided for @passportAgain.
  ///
  /// In en, this message translates to:
  /// **'Would eat again'**
  String get passportAgain;

  /// No description provided for @passportPrivate.
  ///
  /// In en, this message translates to:
  /// **'Only me'**
  String get passportPrivate;

  /// No description provided for @passportFriends.
  ///
  /// In en, this message translates to:
  /// **'My friends'**
  String get passportFriends;

  /// No description provided for @passportVisibility.
  ///
  /// In en, this message translates to:
  /// **'Who can see this memory?'**
  String get passportVisibility;

  /// No description provided for @passportDate.
  ///
  /// In en, this message translates to:
  /// **'Visit date'**
  String get passportDate;

  /// No description provided for @passportSave.
  ///
  /// In en, this message translates to:
  /// **'Save memory'**
  String get passportSave;

  /// No description provided for @passportEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit memory'**
  String get passportEdit;

  /// No description provided for @passportDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete memory'**
  String get passportDelete;

  /// No description provided for @passportDeleteHint.
  ///
  /// In en, this message translates to:
  /// **'Delete this food memory permanently?'**
  String get passportDeleteHint;

  /// No description provided for @passportEmpty.
  ///
  /// In en, this message translates to:
  /// **'Your next delicious discovery belongs here.'**
  String get passportEmpty;

  /// No description provided for @passportFriendEmpty.
  ///
  /// In en, this message translates to:
  /// **'No shared food memories yet.'**
  String get passportFriendEmpty;

  /// No description provided for @passportError.
  ///
  /// In en, this message translates to:
  /// **'Could not load or save your food memories. Check your connection and retry.'**
  String get passportError;

  /// No description provided for @passportInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a restaurant, a dish, and a rating from 1 to 5.'**
  String get passportInvalid;

  /// No description provided for @passportSummary.
  ///
  /// In en, this message translates to:
  /// **'{dishes} memories · {places} places · {favorites} favorites shown'**
  String passportSummary(int dishes, int places, int favorites);

  /// No description provided for @dumplingRating.
  ///
  /// In en, this message translates to:
  /// **'{rating}/5 dumplings'**
  String dumplingRating(int rating);

  /// No description provided for @rating1.
  ///
  /// In en, this message translates to:
  /// **'Not for me'**
  String get rating1;

  /// No description provided for @rating2.
  ///
  /// In en, this message translates to:
  /// **'Just okay'**
  String get rating2;

  /// No description provided for @rating3.
  ///
  /// In en, this message translates to:
  /// **'Pretty good'**
  String get rating3;

  /// No description provided for @rating4.
  ///
  /// In en, this message translates to:
  /// **'Delicious!'**
  String get rating4;

  /// No description provided for @rating5.
  ///
  /// In en, this message translates to:
  /// **'Legendary bite!'**
  String get rating5;

  /// No description provided for @wheelTitle.
  ///
  /// In en, this message translates to:
  /// **'Food roulette'**
  String get wheelTitle;

  /// No description provided for @wheelCreate.
  ///
  /// In en, this message translates to:
  /// **'Drop a food wheel'**
  String get wheelCreate;

  /// No description provided for @wheelHint.
  ///
  /// In en, this message translates to:
  /// **'One food per member. Any two members can get the wheel rolling!'**
  String get wheelHint;

  /// No description provided for @wheelSuggestion.
  ///
  /// In en, this message translates to:
  /// **'Just a suggestion — your host still chooses the destination.'**
  String get wheelSuggestion;

  /// No description provided for @wheelOption.
  ///
  /// In en, this message translates to:
  /// **'Your food pick'**
  String get wheelOption;

  /// No description provided for @wheelAdd.
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get wheelAdd;

  /// No description provided for @wheelSpin.
  ///
  /// In en, this message translates to:
  /// **'Spin the wheel!'**
  String get wheelSpin;

  /// No description provided for @wheelSpinning.
  ///
  /// In en, this message translates to:
  /// **'Let the wheel decide…'**
  String get wheelSpinning;

  /// No description provided for @wheelWinner.
  ///
  /// In en, this message translates to:
  /// **'The wheel picked: {food}!'**
  String wheelWinner(String food);

  /// No description provided for @wheelNew.
  ///
  /// In en, this message translates to:
  /// **'Start a new round'**
  String get wheelNew;

  /// No description provided for @wheelWait.
  ///
  /// In en, this message translates to:
  /// **'Waiting for the wheel creator to spin.'**
  String get wheelWait;

  /// No description provided for @wheelMinimum.
  ///
  /// In en, this message translates to:
  /// **'At least two members must add a food.'**
  String get wheelMinimum;

  /// No description provided for @wheelError.
  ///
  /// In en, this message translates to:
  /// **'The wheel could not be updated. Check your connection and retry.'**
  String get wheelError;

  /// No description provided for @wheelChanged.
  ///
  /// In en, this message translates to:
  /// **'This round changed or the Jajan is no longer active. Refresh and try again.'**
  String get wheelChanged;

  /// No description provided for @wheelInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a food name (1–40 characters).'**
  String get wheelInvalid;

  /// No description provided for @wheelCreator.
  ///
  /// In en, this message translates to:
  /// **'Started by {name}'**
  String wheelCreator(String name);

  /// No description provided for @wheelHistory.
  ///
  /// In en, this message translates to:
  /// **'Latest 10 rounds'**
  String get wheelHistory;

  /// No description provided for @wheelEmpty.
  ///
  /// In en, this message translates to:
  /// **'No previous rounds yet.'**
  String get wheelEmpty;

  /// No description provided for @wheelHaptics.
  ///
  /// In en, this message translates to:
  /// **'Wheel vibration'**
  String get wheelHaptics;

  /// No description provided for @wheelSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Submitted'**
  String get wheelSubmitted;

  /// No description provided for @wheelLocked.
  ///
  /// In en, this message translates to:
  /// **'Your pick is already submitted and cannot be edited.'**
  String get wheelLocked;

  /// No description provided for @chatActivities.
  ///
  /// In en, this message translates to:
  /// **'Chat activities'**
  String get chatActivities;

  /// No description provided for @chatVoting.
  ///
  /// In en, this message translates to:
  /// **'Voting'**
  String get chatVoting;

  /// No description provided for @friendSent.
  ///
  /// In en, this message translates to:
  /// **'Request sent'**
  String get friendSent;

  /// No description provided for @friendSendFailed.
  ///
  /// In en, this message translates to:
  /// **'Your friend request was not sent. Check your connection and tap Add friend to try again.'**
  String get friendSendFailed;

  /// No description provided for @passportArea.
  ///
  /// In en, this message translates to:
  /// **'Area / neighborhood (optional)'**
  String get passportArea;

  /// No description provided for @dropVoteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Drop a vote in this chat?'**
  String get dropVoteConfirm;

  /// No description provided for @dropWheelConfirm.
  ///
  /// In en, this message translates to:
  /// **'Drop a food wheel in this chat?'**
  String get dropWheelConfirm;

  /// No description provided for @dropActivity.
  ///
  /// In en, this message translates to:
  /// **'Yes, let’s do it'**
  String get dropActivity;

  /// No description provided for @pollHostOnly.
  ///
  /// In en, this message translates to:
  /// **'Any gang member can create a vote. The host selects the final destination.'**
  String get pollHostOnly;

  /// No description provided for @jajanAccess.
  ///
  /// In en, this message translates to:
  /// **'Who can join?'**
  String get jajanAccess;

  /// No description provided for @jajanPublic.
  ///
  /// In en, this message translates to:
  /// **'Public'**
  String get jajanPublic;

  /// No description provided for @jajanPrivate.
  ///
  /// In en, this message translates to:
  /// **'Private'**
  String get jajanPrivate;

  /// No description provided for @jajanPublicHint.
  ///
  /// In en, this message translates to:
  /// **'Public · Join instantly when there is space.'**
  String get jajanPublicHint;

  /// No description provided for @jajanPrivateHint.
  ///
  /// In en, this message translates to:
  /// **'Private · Visible nearby, with host approval required to join.'**
  String get jajanPrivateHint;

  /// No description provided for @jajanRequestJoin.
  ///
  /// In en, this message translates to:
  /// **'Request to join'**
  String get jajanRequestJoin;

  /// No description provided for @jajanJoined.
  ///
  /// In en, this message translates to:
  /// **'You joined this Jajan!'**
  String get jajanJoined;

  /// No description provided for @memberJoinedNotification.
  ///
  /// In en, this message translates to:
  /// **'{name} joined your Jajan!'**
  String memberJoinedNotification(String name);

  /// No description provided for @notificationSound.
  ///
  /// In en, this message translates to:
  /// **'Notification sound'**
  String get notificationSound;

  /// No description provided for @notificationSoundHint.
  ///
  /// In en, this message translates to:
  /// **'A gentle chime while the app is open'**
  String get notificationSoundHint;

  /// No description provided for @notificationSoundSaveError.
  ///
  /// In en, this message translates to:
  /// **'Could not save your sound preference. Please try again.'**
  String get notificationSoundSaveError;

  /// No description provided for @announcementPermissionTitle.
  ///
  /// In en, this message translates to:
  /// **'Stay in the Jajan loop!'**
  String get announcementPermissionTitle;

  /// No description provided for @announcementPermissionBody.
  ///
  /// In en, this message translates to:
  /// **'Allow notifications for news and announcements from Jajan Gangs. You can change this anytime in your device settings.'**
  String get announcementPermissionBody;

  /// No description provided for @announcementLater.
  ///
  /// In en, this message translates to:
  /// **'Not now'**
  String get announcementLater;

  /// No description provided for @announcementEnable.
  ///
  /// In en, this message translates to:
  /// **'Enable notifications'**
  String get announcementEnable;

  /// No description provided for @inviteFriends.
  ///
  /// In en, this message translates to:
  /// **'Invite friends'**
  String get inviteFriends;

  /// No description provided for @inviteAction.
  ///
  /// In en, this message translates to:
  /// **'Invite'**
  String get inviteAction;

  /// No description provided for @inviteSent.
  ///
  /// In en, this message translates to:
  /// **'Invited'**
  String get inviteSent;

  /// No description provided for @inviteHint.
  ///
  /// In en, this message translates to:
  /// **'Invite a friend to this Jajan. Public events allow joining directly; private events still need host approval. One invitation per friend per event.'**
  String get inviteHint;

  /// No description provided for @inviteEmpty.
  ///
  /// In en, this message translates to:
  /// **'Add some friends first, then invite them to jajan!'**
  String get inviteEmpty;

  /// No description provided for @inviteNotification.
  ///
  /// In en, this message translates to:
  /// **'Your friend invited you to a Jajan. Tap to view and join!'**
  String get inviteNotification;

  /// No description provided for @leaveJajan.
  ///
  /// In en, this message translates to:
  /// **'Leave Jajan'**
  String get leaveJajan;

  /// No description provided for @leaveHint.
  ///
  /// In en, this message translates to:
  /// **'Your spot will become available and you will lose access to this chat. Your previous messages and activity submissions will remain. Leave this Jajan?'**
  String get leaveHint;

  /// No description provided for @leaveSuccess.
  ///
  /// In en, this message translates to:
  /// **'You left this Jajan.'**
  String get leaveSuccess;

  /// No description provided for @leaveHost.
  ///
  /// In en, this message translates to:
  /// **'Hosts must cancel their event instead of leaving.'**
  String get leaveHost;

  /// No description provided for @socialFailed.
  ///
  /// In en, this message translates to:
  /// **'We could not complete this action. Check your connection and try again.'**
  String get socialFailed;

  /// No description provided for @socialBlocked.
  ///
  /// In en, this message translates to:
  /// **'Friend requests and invitations are unavailable between these accounts.'**
  String get socialBlocked;

  /// No description provided for @socialLoadMore.
  ///
  /// In en, this message translates to:
  /// **'Load more'**
  String get socialLoadMore;

  /// No description provided for @blockUser.
  ///
  /// In en, this message translates to:
  /// **'Block user'**
  String get blockUser;

  /// No description provided for @unblockUser.
  ///
  /// In en, this message translates to:
  /// **'Unblock'**
  String get unblockUser;

  /// No description provided for @blockHint.
  ///
  /// In en, this message translates to:
  /// **'Blocking removes your friendship and prevents new friend requests and invitations between you. You may still see each other in shared Jajans and their group chats. Block this person?'**
  String get blockHint;

  /// No description provided for @unblockHint.
  ///
  /// In en, this message translates to:
  /// **'Unblocking allows friend requests again. Your previous friendship will not be restored automatically.'**
  String get unblockHint;

  /// No description provided for @blockedUsers.
  ///
  /// In en, this message translates to:
  /// **'Blocked users'**
  String get blockedUsers;

  /// No description provided for @blockedEmpty.
  ///
  /// In en, this message translates to:
  /// **'You have not blocked anyone.'**
  String get blockedEmpty;

  /// No description provided for @reportUser.
  ///
  /// In en, this message translates to:
  /// **'Report user'**
  String get reportUser;

  /// No description provided for @reportHint.
  ///
  /// In en, this message translates to:
  /// **'Tell us what happened. Your report is private and will be available to the Jajan Gangs team for review. Reporting does not automatically block or penalize this person.'**
  String get reportHint;

  /// No description provided for @reportDetails.
  ///
  /// In en, this message translates to:
  /// **'What happened? (optional)'**
  String get reportDetails;

  /// No description provided for @reportSubmit.
  ///
  /// In en, this message translates to:
  /// **'Submit report'**
  String get reportSubmit;

  /// No description provided for @reportSent.
  ///
  /// In en, this message translates to:
  /// **'Your report has been submitted. Thank you.'**
  String get reportSent;

  /// No description provided for @reportReason_spam.
  ///
  /// In en, this message translates to:
  /// **'Spam or scams'**
  String get reportReason_spam;

  /// No description provided for @reportReason_harassment.
  ///
  /// In en, this message translates to:
  /// **'Harassment or bullying'**
  String get reportReason_harassment;

  /// No description provided for @reportReason_unsafe.
  ///
  /// In en, this message translates to:
  /// **'Unsafe behavior'**
  String get reportReason_unsafe;

  /// No description provided for @reportReason_other.
  ///
  /// In en, this message translates to:
  /// **'Something else'**
  String get reportReason_other;

  /// No description provided for @inviteFailed.
  ///
  /// In en, this message translates to:
  /// **'The invitation could not be confirmed. Check your connection and tap Invite to retry.'**
  String get inviteFailed;

  /// No description provided for @profileTagline.
  ///
  /// In en, this message translates to:
  /// **'Your next delicious adventure starts here.'**
  String get profileTagline;

  /// No description provided for @passportEditorHint.
  ///
  /// In en, this message translates to:
  /// **'A little memory. A great bite. Make it yours.'**
  String get passportEditorHint;

  /// No description provided for @chatInboxHint.
  ///
  /// In en, this message translates to:
  /// **'Your gangs, good food and great conversations.'**
  String get chatInboxHint;

  /// No description provided for @chatDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete from my chats'**
  String get chatDelete;

  /// No description provided for @chatDeleteHint.
  ///
  /// In en, this message translates to:
  /// **'This hides the chat for you until a new message arrives. You remain a member and everyone keeps their messages.'**
  String get chatDeleteHint;

  /// No description provided for @chatDeleteFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not hide this chat. Check your connection and try again.'**
  String get chatDeleteFailed;

  /// No description provided for @chatHiddenEmpty.
  ///
  /// In en, this message translates to:
  /// **'No visible chats. Hidden chats return when a new message arrives.'**
  String get chatHiddenEmpty;

  /// No description provided for @bioLabel.
  ///
  /// In en, this message translates to:
  /// **'Bio (optional)'**
  String get bioLabel;

  /// No description provided for @bioHint.
  ///
  /// In en, this message translates to:
  /// **'A little about you and the food you love…'**
  String get bioHint;

  /// No description provided for @bioLong.
  ///
  /// In en, this message translates to:
  /// **'Keep your bio to 150 characters or fewer.'**
  String get bioLong;

  /// No description provided for @profileEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit profile'**
  String get profileEdit;

  /// No description provided for @profileSave.
  ///
  /// In en, this message translates to:
  /// **'Save profile'**
  String get profileSave;

  /// No description provided for @pgTitle.
  ///
  /// In en, this message translates to:
  /// **'My Gangs'**
  String get pgTitle;

  /// No description provided for @pgCreate.
  ///
  /// In en, this message translates to:
  /// **'Create Gang'**
  String get pgCreate;

  /// No description provided for @pgTemporary.
  ///
  /// In en, this message translates to:
  /// **'Jajan chats'**
  String get pgTemporary;

  /// No description provided for @pgIntro.
  ///
  /// In en, this message translates to:
  /// **'Your people. Your food adventures. A gang that stays.'**
  String get pgIntro;

  /// No description provided for @pgName.
  ///
  /// In en, this message translates to:
  /// **'Gang name'**
  String get pgName;

  /// No description provided for @pgManage.
  ///
  /// In en, this message translates to:
  /// **'Manage gang'**
  String get pgManage;

  /// No description provided for @pgInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a gang name of 1–40 characters and check your input.'**
  String get pgInvalid;

  /// No description provided for @pgError.
  ///
  /// In en, this message translates to:
  /// **'We could not finish that. Check your connection and try again.'**
  String get pgError;

  /// No description provided for @pgFull.
  ///
  /// In en, this message translates to:
  /// **'This gang is full. Ask the owner to increase its member limit.'**
  String get pgFull;

  /// No description provided for @pgFriendsOnly.
  ///
  /// In en, this message translates to:
  /// **'You must still be friends with the inviter, and they must still belong to this gang.'**
  String get pgFriendsOnly;

  /// No description provided for @pgUnavailable.
  ///
  /// In en, this message translates to:
  /// **'This gang is unavailable or you are no longer a member.'**
  String get pgUnavailable;

  /// No description provided for @pgTransferFirst.
  ///
  /// In en, this message translates to:
  /// **'Transfer ownership to another member before leaving.'**
  String get pgTransferFirst;

  /// No description provided for @pgCapacity.
  ///
  /// In en, this message translates to:
  /// **'The limit cannot be lower than the current number of members.'**
  String get pgCapacity;

  /// No description provided for @pgEmpty.
  ///
  /// In en, this message translates to:
  /// **'Your permanent gangs will appear here. Create one and invite your friends!'**
  String get pgEmpty;

  /// No description provided for @pgInvite.
  ///
  /// In en, this message translates to:
  /// **'Gang invitation'**
  String get pgInvite;

  /// No description provided for @pgInviteHint.
  ///
  /// In en, this message translates to:
  /// **'Accept to join this permanent gang and start chatting. Pending invitations do not reserve a place.'**
  String get pgInviteHint;

  /// No description provided for @pgInviteHandled.
  ///
  /// In en, this message translates to:
  /// **'This invitation has already been answered. Accepted gangs are in My Gangs.'**
  String get pgInviteHandled;

  /// No description provided for @pgInviteNotification.
  ///
  /// In en, this message translates to:
  /// **'You have been invited to a permanent gang.'**
  String get pgInviteNotification;

  /// No description provided for @pgMessageNotification.
  ///
  /// In en, this message translates to:
  /// **'New message in your permanent gang.'**
  String get pgMessageNotification;

  /// No description provided for @pgInviteFriendsHint.
  ///
  /// In en, this message translates to:
  /// **'Invite your friends to this gang. They choose whether to accept.'**
  String get pgInviteFriendsHint;

  /// No description provided for @pgOwner.
  ///
  /// In en, this message translates to:
  /// **'Owner'**
  String get pgOwner;

  /// No description provided for @pgMembersTitle.
  ///
  /// In en, this message translates to:
  /// **'Members & invitations'**
  String get pgMembersTitle;

  /// No description provided for @pgTransfer.
  ///
  /// In en, this message translates to:
  /// **'Transfer ownership'**
  String get pgTransfer;

  /// No description provided for @pgRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove member'**
  String get pgRemove;

  /// No description provided for @pgMemberConfirm.
  ///
  /// In en, this message translates to:
  /// **'This changes the member’s role or access to the gang. Continue?'**
  String get pgMemberConfirm;

  /// No description provided for @pgDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete gang'**
  String get pgDelete;

  /// No description provided for @pgDeleteHint.
  ///
  /// In en, this message translates to:
  /// **'Delete this gang, its messages and invitations for everyone? This cannot be undone.'**
  String get pgDeleteHint;

  /// No description provided for @pgLeave.
  ///
  /// In en, this message translates to:
  /// **'Leave gang'**
  String get pgLeave;

  /// No description provided for @pgLeaveHint.
  ///
  /// In en, this message translates to:
  /// **'You will lose access to this chat. A friend in the gang must invite you again to rejoin.'**
  String get pgLeaveHint;

  /// No description provided for @pgDeleteRetry.
  ///
  /// In en, this message translates to:
  /// **'Finish deleting gang'**
  String get pgDeleteRetry;

  /// No description provided for @pgMessage.
  ///
  /// In en, this message translates to:
  /// **'Type a message…'**
  String get pgMessage;

  /// No description provided for @pgSend.
  ///
  /// In en, this message translates to:
  /// **'Send message'**
  String get pgSend;

  /// No description provided for @pgHiddenHint.
  ///
  /// In en, this message translates to:
  /// **'Hidden gangs return when a new message arrives.'**
  String get pgHiddenHint;

  /// No description provided for @pgMembers.
  ///
  /// In en, this message translates to:
  /// **'{count}/{limit} members'**
  String pgMembers(int count, int limit);

  /// No description provided for @pgAlreadyMember.
  ///
  /// In en, this message translates to:
  /// **'Already a member'**
  String get pgAlreadyMember;

  /// No description provided for @pgInvitedBy.
  ///
  /// In en, this message translates to:
  /// **'Invited you'**
  String get pgInvitedBy;

  /// No description provided for @avatarAnime01.
  ///
  /// In en, this message translates to:
  /// **'Noodle Adventurer'**
  String get avatarAnime01;

  /// No description provided for @avatarAnime02.
  ///
  /// In en, this message translates to:
  /// **'Sunny Foodie'**
  String get avatarAnime02;

  /// No description provided for @avatarAnime03.
  ///
  /// In en, this message translates to:
  /// **'Cafe Explorer'**
  String get avatarAnime03;

  /// No description provided for @avatarAnime04.
  ///
  /// In en, this message translates to:
  /// **'Midnight Gamer'**
  String get avatarAnime04;

  /// No description provided for @avatarAnime05.
  ///
  /// In en, this message translates to:
  /// **'Street Food Scout'**
  String get avatarAnime05;

  /// No description provided for @avatarAnime06.
  ///
  /// In en, this message translates to:
  /// **'Spicy Sidekick'**
  String get avatarAnime06;

  /// No description provided for @avatarAnime07.
  ///
  /// In en, this message translates to:
  /// **'Weekend Wanderer'**
  String get avatarAnime07;

  /// No description provided for @avatarAnime08.
  ///
  /// In en, this message translates to:
  /// **'Sweet Treat Hunter'**
  String get avatarAnime08;

  /// No description provided for @avatarAnime09.
  ///
  /// In en, this message translates to:
  /// **'Chill Challenger'**
  String get avatarAnime09;

  /// No description provided for @avatarAnime10.
  ///
  /// In en, this message translates to:
  /// **'Golden Foodie'**
  String get avatarAnime10;

  /// No description provided for @avatarPreviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Meet your character'**
  String get avatarPreviewTitle;

  /// No description provided for @avatarPreviewHint.
  ///
  /// In en, this message translates to:
  /// **'A little personality for your next food adventure.'**
  String get avatarPreviewHint;

  /// No description provided for @avatarUseCharacter.
  ///
  /// In en, this message translates to:
  /// **'Choose this character'**
  String get avatarUseCharacter;

  /// No description provided for @jajanWhen.
  ///
  /// In en, this message translates to:
  /// **'When shall we Jajan?'**
  String get jajanWhen;

  /// No description provided for @jajanNow.
  ///
  /// In en, this message translates to:
  /// **'Now'**
  String get jajanNow;

  /// No description provided for @jajanLater.
  ///
  /// In en, this message translates to:
  /// **'Later'**
  String get jajanLater;

  /// No description provided for @jajanChooseTime.
  ///
  /// In en, this message translates to:
  /// **'Choose date & time'**
  String get jajanChooseTime;

  /// No description provided for @jajanScheduleHint.
  ///
  /// In en, this message translates to:
  /// **'Plan 15 minutes to 7 days ahead. Members can join and chat right away.'**
  String get jajanScheduleHint;

  /// No description provided for @jajanScheduleInvalid.
  ///
  /// In en, this message translates to:
  /// **'Choose a start time at least 15 minutes and no more than 7 days from now.'**
  String get jajanScheduleInvalid;

  /// No description provided for @jajanScheduledLabel.
  ///
  /// In en, this message translates to:
  /// **'Scheduled'**
  String get jajanScheduledLabel;

  /// No description provided for @jajanScheduledFor.
  ///
  /// In en, this message translates to:
  /// **'Scheduled · {time}'**
  String jajanScheduledFor(String time);

  /// No description provided for @jajanExpiresOn.
  ///
  /// In en, this message translates to:
  /// **'Expires {time}'**
  String jajanExpiresOn(String time);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'id'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'id':
      return AppLocalizationsId();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
