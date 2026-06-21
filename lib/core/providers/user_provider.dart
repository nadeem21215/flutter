import 'package:flutter/foundation.dart';

class UserProvider extends ChangeNotifier {
  String? _name;
  String? _firebaseUid;
  String? _role;
  String? _username;
  String? _studentCode;
  String? _level;
  double? _gpa;
  int?    _creditHours;
  int?    _warnings;
  bool    _hasRegistered = false;

  String? get name          => _name;
  String? get firebaseUid   => _firebaseUid;
  String? get role          => _role;
  String? get username      => _username;
  String? get studentCode   => _studentCode;
  String? get level         => _level;
  double? get gpa           => _gpa;
  int?    get creditHours   => _creditHours;
  int?    get warnings      => _warnings;
  bool    get hasRegistered => _hasRegistered;
  bool    get isLoggedIn    => _firebaseUid != null;

  void setUser({
    required String name,
    required String firebaseUid,
    required String role,
    String? username,
    String? studentCode,
    String? level,
    double? gpa,
    int?    creditHours,
    int?    warnings,
    bool    hasRegistered = false,
  }) {
    _name           = name;
    _firebaseUid    = firebaseUid;
    _role           = role;
    _username       = username;
    _studentCode    = studentCode;
    _level          = level;
    _gpa            = gpa;
    _creditHours    = creditHours;
    _warnings       = warnings;
    _hasRegistered  = hasRegistered;
    notifyListeners();
  }

  int _registrationVersion = 0;
  /// Increments each time a registration succeeds; screens watch this to
  /// know when to reload their course lists (Fix #2 – sync without re-login).
  int get registrationVersion => _registrationVersion;

  /// Call this immediately after a successful registration so the UI updates
  /// without needing a full reload.
  void markRegistered() {
    _hasRegistered = true;
    _registrationVersion++;
    notifyListeners();
  }

  void clearUser() {
    _name = _firebaseUid = _role = _username = _studentCode = _level = null;
    _gpa = null;
    _creditHours = _warnings = null;
    _hasRegistered = false;
    _registrationVersion = 0;
    notifyListeners();
  }
}
