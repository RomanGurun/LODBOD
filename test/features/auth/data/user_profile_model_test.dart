import 'package:flutter_test/flutter_test.dart';
import 'package:lodbod/features/auth/data/models/user_profile_model.dart';
import 'package:lodbod/features/auth/domain/entities/user_profile.dart';

void main() {
  group('UserProfileModel', () {
    test('maps the MockAPI /users wire format', () {
      final model = UserProfileModel.fromJson(<String, dynamic>{
        'id': '17',
        'firebaseUid': 'uid-1',
        'phoneNumber': '+9779812345678',
        'fullName': 'Sushil Thapa',
        'email': 'sushil@example.com',
        'role': 'carrier',
        'isPhoneVerified': true,
        'createdAt': '2026-01-01T00:00:00.000Z',
        'updatedAt': '2026-01-02T00:00:00.000Z',
      });

      expect(model.recordId, '17');
      expect(model.firebaseUid, 'uid-1');
      expect(model.phoneNumber, '+9779812345678');
      expect(model.fullName, 'Sushil Thapa');
      expect(model.role, UserProfile.roleCarrier);
      expect(model.isPhoneVerified, isTrue);

      final entity = model.toEntity();
      expect(entity.uid, 'uid-1');
      expect(entity.name, 'Sushil Thapa');
      expect(entity.phone, '+9779812345678');
      expect(entity.isCarrier, isTrue);
      expect(entity.isComplete, isTrue);
    });

    test('never sends the MockAPI record id in a payload', () {
      final model = UserProfileModel.fromJson(<String, dynamic>{
        'id': '17',
        'firebaseUid': 'uid-1',
        'phoneNumber': '+9779812345678',
        'fullName': 'Sushil Thapa',
        'email': '',
        'role': 'shipper',
        'isPhoneVerified': true,
        'createdAt': '2026-01-01T00:00:00.000Z',
        'updatedAt': '2026-01-01T00:00:00.000Z',
      });

      expect(model.toJson().containsKey('id'), isFalse);
      expect(model.toJson()['firebaseUid'], 'uid-1');
    });

    test('falls back to shipper for an unknown role and tolerates strings', () {
      final model = UserProfileModel.fromJson(<String, dynamic>{
        'firebaseUid': 'uid-2',
        'role': 'admin',
        'isPhoneVerified': 'true',
        'createdAt': 'not-a-date',
        'updatedAt': '2026-01-01T00:00:00.000Z',
      });

      expect(model.role, UserProfile.roleShipper);
      expect(model.isPhoneVerified, isTrue);
      expect(model.toEntity().isShipper, isTrue);
    });
  });

  group('UserProfile', () {
    test('a name is all that is needed to complete the profile', () {
      final now = DateTime.utc(2026, 1, 1);
      final incomplete = UserProfile(
        uid: 'uid-1',
        name: '  ',
        email: '',
        phone: '+9779812345678',
        createdAt: now,
        updatedAt: now,
      );

      expect(incomplete.isComplete, isFalse);
      expect(incomplete.copyWith(name: 'Sushil').isComplete, isTrue);
    });

    test('role is normalised to shipper or carrier', () {
      expect(UserProfile.normalizeRole('CARRIER'), UserProfile.roleCarrier);
      expect(UserProfile.normalizeRole(null), UserProfile.roleShipper);
      expect(UserProfile.normalizeRole('unknown'), UserProfile.roleShipper);
    });
  });
}
