/// Stub для dart:io на Web платформі.
/// Надає порожні класи File/Directory щоб код компілювався,
/// але вони ніколи не викликаються (захищені kIsWeb перевіркою).

class File {
  final String path;
  File(this.path);
  Future<File> writeAsString(String contents) async => this;
}

class Directory {
  final String path;
  Directory(this.path);
}
