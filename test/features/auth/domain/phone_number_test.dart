import 'package:flutter_test/flutter_test.dart';
import 'package:lodbod/core/utils/phone_number.dart';
import 'package:lodbod/core/utils/validators.dart';

void main() {
  group('PhoneNumber', () {
    test('accepts a valid Nepal mobile number', () {
      expect(PhoneNumber.isValidNepalMobile('9812345678'), isTrue);
      expect(PhoneNumber.isValidNepalMobile(' 981-234-5678 '), isTrue);
    });

    test('rejects numbers that are not ten digits starting with 9', () {
      expect(PhoneNumber.isValidNepalMobile('8812345678'), isFalse);
      expect(PhoneNumber.isValidNepalMobile('981234567'), isFalse);
      expect(PhoneNumber.isValidNepalMobile('98123456789'), isFalse);
      expect(PhoneNumber.isValidNepalMobile(''), isFalse);
    });

    test('normalises typed variants to E.164', () {
      expect(PhoneNumber.toE164('9812345678'), '+9779812345678');
      expect(PhoneNumber.toE164('09812345678'), '+9779812345678');
      expect(PhoneNumber.toE164('+977 981 234 5678'), '+9779812345678');
      expect(PhoneNumber.toE164('9779812345678'), '+9779812345678');
    });

    test('masks the middle digits for display', () {
      expect(PhoneNumber.mask('+9779812345678'), '+977 98******78');
    });

    test('derives a stable internal password-login alias', () {
      expect(
        PhoneNumber.accountEmail('+9779812345678'),
        'phone9779812345678@phone.lodbod.app',
      );
      expect(
        PhoneNumber.accountEmail('9812345678'),
        PhoneNumber.accountEmail('+9779812345678'),
      );
      expect(
        PhoneNumber.isAccountEmail('phone9779812345678@phone.lodbod.app'),
        isTrue,
      );
      expect(PhoneNumber.isAccountEmail('aarav@example.com'), isFalse);
    });
  });

  group('Validators.otpCode', () {
    test('requires exactly six digits', () {
      expect(Validators.otpCode('123456'), isNull);
      expect(Validators.otpCode('12345'), isNotNull);
      expect(Validators.otpCode('12345a'), isNotNull);
      expect(Validators.otpCode(''), isNotNull);
    });
  });

  group('Validators.nepalMobile', () {
    test('points users at the 10-digit Nepal format', () {
      expect(Validators.nepalMobile('9812345678'), isNull);
      expect(Validators.nepalMobile('12345'),
          'Enter a valid 10-digit Nepal mobile number');
    });
  });

  group('Validators.gmail', () {
    test('accepts valid Gmail addresses', () {
      expect(Validators.gmail('aarav.shrestha@gmail.com'), isNull);
      expect(Validators.gmail('user123@gmail.com'), isNull);
      expect(Validators.gmail('john.doe.123@GMAIL.COM'), isNull);
    });

    test('rejects non-gmail domains', () {
      expect(
        Validators.gmail('user@yahoo.com'),
        'Enter a valid Gmail address ending in @gmail.com',
      );
      expect(
        Validators.gmail('user@company.com'),
        'Enter a valid Gmail address ending in @gmail.com',
      );
    });

    test('rejects too short or too long usernames', () {
      expect(
        Validators.gmail('ab@gmail.com'),
        'Gmail username must be between 3 and 30 characters',
      );
    });

    test('rejects invalid characters and consecutive dots', () {
      expect(
        Validators.gmail('user..name@gmail.com'),
        'Enter a valid Gmail username (letters, numbers, dots)',
      );
      expect(
        Validators.gmail('.username@gmail.com'),
        'Enter a valid Gmail username (letters, numbers, dots)',
      );
      expect(
        Validators.gmail('username.@gmail.com'),
        'Enter a valid Gmail username (letters, numbers, dots)',
      );
      expect(
        Validators.gmail('user_name@gmail.com'),
        'Enter a valid Gmail username (letters, numbers, dots)',
      );
    });
  });
}
