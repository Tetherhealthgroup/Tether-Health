import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

const _manifestPath = 'android/app/src/main/AndroidManifest.xml';
const _internet = 'android.permission.INTERNET';

/// True when [manifestXml] declares INTERNET as a direct child of
/// `<manifest>`. XML comments are stripped first so a commented-out line does
/// not count, and the match is anchored to the manifest's top level (depth 1),
/// so a tag nested inside `<application>` does not count either.
bool declaresInternetPermission(String manifestXml) {
  final withoutComments = manifestXml.replaceAll(
    RegExp(r'<!--.*?-->', dotAll: true),
    '',
  );
  final tag = RegExp(r'<(/?)([A-Za-z][\w:.-]*)((?:"[^"]*"|[^">])*?)(/?)>');
  var depth = 0;
  for (final m in tag.allMatches(withoutComments)) {
    final isClose = m.group(1) == '/';
    final name = m.group(2)!;
    final attrs = m.group(3)!;
    final selfClosing = m.group(4) == '/';
    if (isClose) {
      depth--;
      continue;
    }
    if (name == 'uses-permission' &&
        depth == 1 &&
        RegExp('android:name\\s*=\\s*"${RegExp.escape(_internet)}"')
            .hasMatch(attrs)) {
      return true;
    }
    if (!selfClosing) depth++;
  }
  return false;
}

void main() {
  test('main Android manifest declares INTERNET for release builds', () {
    final androidManifest = File(_manifestPath).readAsStringSync();

    expect(declaresInternetPermission(androidManifest), isTrue);
  });

  test('detector rejects a temp copy of the manifest without the line', () {
    final original = File(_manifestPath).readAsStringSync();
    final stripped = original
        .split('\n')
        .where((line) => !line.contains(_internet))
        .join('\n');
    expect(stripped, isNot(equals(original)), reason: 'line was removed');

    final dir = Directory.systemTemp.createTempSync('manifest_check_');
    addTearDown(() => dir.deleteSync(recursive: true));
    final copy = File('${dir.path}/AndroidManifest.xml')
      ..writeAsStringSync(stripped);

    expect(declaresInternetPermission(copy.readAsStringSync()), isFalse);
  });

  test('detector is not fooled by comments or nested placement', () {
    const commented = '<manifest xmlns:android="x">\n'
        '  <!-- <uses-permission android:name="android.permission.INTERNET"/> -->\n'
        '  <application android:label="a"/>\n</manifest>';
    const nested = '<manifest xmlns:android="x">\n'
        '  <application android:label="a">\n'
        '    <uses-permission android:name="android.permission.INTERNET"/>\n'
        '  </application>\n</manifest>';
    const good = '<manifest xmlns:android="x">\n'
        '  <uses-permission android:name="android.permission.INTERNET"/>\n'
        '  <application android:label="a"/>\n</manifest>';

    expect(declaresInternetPermission(commented), isFalse);
    expect(declaresInternetPermission(nested), isFalse);
    expect(declaresInternetPermission(good), isTrue);
  });
}
