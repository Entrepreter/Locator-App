class MyUser {

  String _profileImgUrl;
  String _name;
  String _sharingId;

  MyUser(this._profileImgUrl, this._name, this._sharingId);

  String get sharingId => _sharingId;

  String get name => _name;

  String get profileImgUrl => _profileImgUrl;
}