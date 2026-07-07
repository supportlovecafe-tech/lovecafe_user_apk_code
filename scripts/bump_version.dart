import 'dart:io';

void main() {
  final file = File('pubspec.yaml');
  if (!file.existsSync()) {
    print('Error: pubspec.yaml not found.');
    return;
  }

  String content = file.readAsStringSync();
  
  // Find version: x.y.z+n
  final versionRegex = RegExp(r'version: (\d+)\.(\d+)\.(\d+)\+(\d+)');
  final match = versionRegex.firstMatch(content);
  
  if (match == null) {
    print('Error: Could not find version pattern in pubspec.yaml');
    return;
  }

  final major = match.group(1);
  final minor = match.group(2);
  final patch = int.parse(match.group(3)!);
  final build = int.parse(match.group(4)!);

  final newPatch = patch + 1;
  final newBuild = build + 1;
  
  final oldVersionString = 'version: ${match.group(1)}.${match.group(2)}.${match.group(3)}+${match.group(4)}';
  final newVersionString = 'version: $major.$minor.$newPatch+$newBuild';

  content = content.replaceFirst(oldVersionString, newVersionString);
  file.writeAsStringSync(content);

  print('Successfully bumped version!');
  print('Old: $oldVersionString');
  print('New: $newVersionString');
}
