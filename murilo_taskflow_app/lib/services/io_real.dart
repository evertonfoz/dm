import 'dart:io';

/// Real IO implementation for mobile/desktop (dart:io available)
class FileWrapper {
  final File _file;

  FileWrapper._(this._file);

  factory FileWrapper.fromPath(String p) => FileWrapper._(File(p));

  String get path => _file.path;

  Future<int> length() => _file.length();

  bool existsSync() => _file.existsSync();

  Future<void> delete() => _file.delete();

  Future<FileWrapper> copy(String dest) async {
    final f = await _file.copy(dest);
    return FileWrapper._(f);
  }
}

class DirectoryWrapper {
  final Directory _dir;

  DirectoryWrapper._(this._dir);

  factory DirectoryWrapper.fromPath(String p) =>
      DirectoryWrapper._(Directory(p));

  String get path => _dir.path;

  Future<bool> exists() => _dir.exists();

  Future<void> create({bool recursive = false}) =>
      _dir.create(recursive: recursive);
}

bool get isAndroid => Platform.isAndroid;

bool get isIOS => Platform.isIOS;

bool get isMacOS => Platform.isMacOS;

bool get isWindows => Platform.isWindows;

bool get isLinux => Platform.isLinux;

bool get isDesktop => isMacOS || isWindows || isLinux;
