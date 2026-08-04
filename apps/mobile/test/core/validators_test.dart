import 'package:flutter_test/flutter_test.dart';
import 'package:titanfit/core/utils/validators.dart';

void main() {
  group('Validators.email', () {
    test('accepts valid email addresses', () {
      expect(Validators.email('user@example.com'), isNull);
      expect(Validators.email('first.last@sub.example.co'), isNull);
      expect(Validators.email('  padded@example.com '), isNull);
    });

    test('rejects empty or missing input', () {
      expect(Validators.email(null), 'Email is required');
      expect(Validators.email(''), 'Email is required');
      expect(Validators.email('   '), 'Email is required');
    });

    test('rejects malformed emails', () {
      expect(Validators.email('not-an-email'), 'Enter a valid email');
      expect(Validators.email('missing@tld'), 'Enter a valid email');
      expect(Validators.email('@nodomain.com'), 'Enter a valid email');
      expect(Validators.email('has space@example.com'), 'Enter a valid email');
    });
  });

  group('Validators.password', () {
    test('accepts passwords of length 6 or more', () {
      expect(Validators.password('abc123'), isNull);
      expect(Validators.password('a very long passphrase'), isNull);
    });

    test('rejects empty passwords', () {
      expect(Validators.password(null), 'Password is required');
      expect(Validators.password(''), 'Password is required');
    });

    test('rejects short passwords', () {
      expect(Validators.password('abc12'), 'Password must be at least 6 characters');
    });
  });

  group('Validators.name', () {
    test('accepts names of 2+ characters', () {
      expect(Validators.name('Alex'), isNull);
      expect(Validators.name('  Bruce Wayne  '), isNull);
    });

    test('rejects empty or single-character names', () {
      expect(Validators.name(null), 'Name is required');
      expect(Validators.name('   '), 'Name is required');
      expect(Validators.name('A'), 'Name must be at least 2 characters');
    });
  });

  group('Validators.required', () {
    test('uses a custom field label in the message', () {
      expect(Validators.required('', 'Weight'), 'Weight is required');
      expect(Validators.required('value'), isNull);
    });
  });
}