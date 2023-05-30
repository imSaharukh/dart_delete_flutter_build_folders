import 'dart:io';
import 'dart:async';

void main() {
  final rootDirectory =
      Directory('/'); // Set the root directory where the search should begin

  print('Searching for paths with pubspec.yaml...');

  final pubspecFiles = _findPubspecFiles(rootDirectory);

  print('Deleting build folders...');

  final deletionFutures = <Future>[];

  for (final file in pubspecFiles) {
    final buildDirectory = Directory('${file.parent.path}/build');
    if (buildDirectory.existsSync()) {
      final deletionFuture = buildDirectory.delete(recursive: true);
      deletionFutures.add(deletionFuture.then((_) {
        print('Deleted build folder at ${buildDirectory.path}');
      }));
    } else {
      print('Build folder not found at ${buildDirectory.path}');
    }
  }

  Future.wait(deletionFutures).then((_) {
    print('Finished deleting build folders.');
  });
}

List<File> _findPubspecFiles(Directory directory) {
  final pubspecFiles = <File>[];

  try {
    final pubspecYaml = File('${directory.path}/pubspec.yaml');
    if (pubspecYaml.existsSync()) {
      pubspecFiles.add(pubspecYaml);
    }

    final entries = directory.listSync();

    for (final entry in entries) {
      if (entry is Directory) {
        try {
          final skipDirectory = _shouldSkipDirectory(entry);
          if (!skipDirectory) {
            pubspecFiles.addAll(_findPubspecFiles(entry));
          } else {
            print('Skipping directory: ${entry.path}');
          }
        } catch (e) {
          print('Error accessing directory: ${entry.path}');
        }
      }
    }
  } catch (e) {
    print('Error accessing directory: ${directory.path}');
  }

  return pubspecFiles;
}

bool _shouldSkipDirectory(Directory directory) {
  final pathComponents = directory.path.split(Platform.pathSeparator);

  // Skip hidden directories
  for (var element in pathComponents) {
    if (element.startsWith('.')) {
      return true;
    }
  }

  if (Platform.isWindows) {
    // On Windows, skip directories like 'C:\Windows', 'C:\Program Files', etc.
    return pathComponents.length >= 2 &&
        pathComponents[1].toLowerCase() == 'windows';
  } else if (Platform.isMacOS) {
    // On macOS, skip directories like '/Library', '/System', '/private', etc.
    return pathComponents.length >= 1 &&
        (pathComponents[0] == 'Library' ||
            pathComponents[0] == 'System' ||
            pathComponents[0] == 'private' ||
            pathComponents.contains('System') ||
            pathComponents.contains('Library') ||
            pathComponents.contains('Applications'));
  } else {
    // On Unix-based systems, skip directories like '/var', '/usr', etc.
    return pathComponents.length >= 1 &&
        (pathComponents[0] == 'var' || pathComponents[0] == 'usr');
  }
}
