/// Stub IO for web: minimal wrappers that avoid using dart:io APIs.
class FileWrapper {
  // ignore: unused_field
  final String _path;
  FileWrapper._(this._path);

  factory FileWrapper.fromPath(String p) => FileWrapper._(p);

  String get path => _path;

  Future<int> length() async => 0;

  bool existsSync() => false;

  Future<void> delete() async {}

  Future<FileWrapper> copy(String dest) async => FileWrapper._(dest);
}

class DirectoryWrapper {
  // ignore: unused_field
  final String _path;
  DirectoryWrapper._(this._path);

  factory DirectoryWrapper.fromPath(String p) => DirectoryWrapper._(p);

  String get path => _path;

  Future<bool> exists() async => false;

  Future<void> create({bool recursive = false}) async {}
}

bool get isAndroid => false;

bool get isIOS => false;

bool get isMacOS => false;

bool get isWindows => false;

bool get isLinux => false;

bool get isDesktop => false;
