class AppConstants {
  static const String appName = 'SplitDumb';
  static const int inviteCodeLength = 6;

  // Firestore collections
  static const String usersCollection = 'users';
  static const String groupsCollection = 'groups';
  static const String expensesCollection = 'expenses';
  static const String settlementsCollection = 'settlements';
  static const String inviteCodesCollection = 'inviteCodes';

  // Error messages
  static const String genericError = 'Something went wrong. Please try again.';
  static const String networkError = 'Please check your internet connection.';
  static const String invalidEmail = 'Please enter a valid email address.';
  static const String weakPassword = 'Password must be at least 6 characters.';
  static const String emailInUse = 'An account already exists with this email.';
  static const String userNotFound = 'No account found with this email.';
  static const String wrongPassword = 'Incorrect password.';
}
