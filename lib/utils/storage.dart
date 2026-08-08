import 'dart:io';
import 'package:path_provider/path_provider.dart';

Future<Directory> appDataDirectory() async {
  if (Platform.isWindows) {
    final storage = Directory(
      '${File(Platform.resolvedExecutable).parent.path}'
      '${Platform.pathSeparator}storage',
    );
    await storage.create(recursive: true);
    return storage;
  }
  return getApplicationDocumentsDirectory();
}
