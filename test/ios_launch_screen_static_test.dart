import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('iOS launch screen', () {
    test('uses a white launch canvas and no dark appearance background', () {
      final infoPlist = File('ios/Runner/Info.plist').readAsStringSync();
      final launchStoryboard = File(
        'ios/Runner/Base.lproj/LaunchScreen.storyboard',
      ).readAsStringSync();
      final launchBackgroundContents =
          jsonDecode(
                File(
                  'ios/Runner/Assets.xcassets/LaunchBackground.imageset/Contents.json',
                ).readAsStringSync(),
              )
              as Map<String, dynamic>;

      expect(infoPlist, contains('<string>LaunchScreen</string>'));
      expect(
        launchStoryboard,
        contains(
          '<color key="backgroundColor" red="1" green="1" blue="1" alpha="1"',
        ),
      );
      expect(launchStoryboard, contains('image="LaunchBackground"'));
      expect(launchStoryboard, contains('image="LaunchImage"'));
      expect(launchStoryboard, contains('multiplier="0.78"'));

      final images = launchBackgroundContents['images'] as List<dynamic>;
      expect(images, hasLength(1));
      expect(images.single, isA<Map<String, dynamic>>());
      expect(
        (images.single as Map<String, dynamic>)['filename'],
        'background.png',
      );
      expect(launchBackgroundContents.toString(), isNot(contains('dark')));
      expect(
        File(
          'ios/Runner/Assets.xcassets/LaunchBackground.imageset/darkbackground.png',
        ).existsSync(),
        isFalse,
      );
    });
  });
}
