class User {
  String _displayName;
  String _photoUrl;
  String _uid;

  User(this._displayName, this._photoUrl, this._uid);

  String get uid => _uid;

  String get photoUrl => _photoUrl;

  String get displayName => _displayName;
}
