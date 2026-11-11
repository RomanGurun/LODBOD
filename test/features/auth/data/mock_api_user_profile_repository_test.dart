import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lodbod/features/auth/data/datasources/mock_api_user_profile_data_source.dart';
import 'package:lodbod/features/auth/data/models/user_profile_model.dart';
import 'package:lodbod/features/auth/data/remote/mock_api_user_profile_repository.dart';

/// In-memory stand-in for the Dio-backed MockAPI datasource.
class _FakeProfileDataSource extends MockApiUserProfileDataSource {
  _FakeProfileDataSource() : super(dio: Dio());

  final Map<String, UserProfileModel> records = <String, UserProfileModel>{};
  int createCalls = 0;
  int updateCalls = 0;
  final List<String> updatedRecordIds = <String>[];

  @override
  Future<UserProfileModel?> fetchByFirebaseUid(String uid) async {
    return records[uid];
  }

  @override
  Future<UserProfileModel> create(UserProfileModel model) async {
    createCalls += 1;
    final stored = UserProfileModel.fromJson(
      <String, dynamic>{...model.toJson(), 'id': 'record-$createCalls'},
    );
    records[model.firebaseUid] = stored;
    return stored;
  }

  @override
  Future<UserProfileModel> update(
    String recordId,
    UserProfileModel model,
  ) async {
    updateCalls += 1;
    updatedRecordIds.add(recordId);
    final stored = UserProfileModel.fromJson(
      <String, dynamic>{...model.toJson(), 'id': recordId},
    );
    records[model.firebaseUid] = stored;
    return stored;
  }
}

void main() {
  late _FakeProfileDataSource dataSource;
  late MockApiUserProfileRepository repository;

  setUp(() {
    dataSource = _FakeProfileDataSource();
    repository = MockApiUserProfileRepository(remote: dataSource);
  });

  test('returns null when the user has no profile record', () async {
    expect(await repository.getProfile('uid-1'), isNull);
  });

  test('ensureProfile creates one record and reuses it afterwards', () async {
    final first = await repository.ensureProfile(
      uid: 'uid-1',
      phoneNumber: '+9779812345678',
    );
    final second = await repository.ensureProfile(
      uid: 'uid-1',
      phoneNumber: '+9779812345678',
    );

    expect(first.uid, 'uid-1');
    expect(first.phone, '+9779812345678');
    expect(first.isPhoneVerified, isTrue);
    expect(second.uid, 'uid-1');
    expect(dataSource.createCalls, 1);
    expect(dataSource.records, hasLength(1));
  });

  test('saveProfile patches the existing MockAPI record instead of creating',
      () async {
    final created = await repository.ensureProfile(
      uid: 'uid-1',
      phoneNumber: '+9779812345678',
    );

    await repository.saveProfile(
      created.copyWith(name: 'Sushil Thapa', role: 'carrier'),
    );

    expect(dataSource.createCalls, 1);
    expect(dataSource.updateCalls, 1);
    expect(dataSource.updatedRecordIds.single, 'record-1');
    expect(dataSource.records['uid-1']?.fullName, 'Sushil Thapa');
    expect(dataSource.records['uid-1']?.role, 'carrier');
  });

  test('saveProfile discovers the record id when the cache is cold', () async {
    dataSource.records['uid-1'] = UserProfileModel.fromJson(
      <String, dynamic>{
        'id': 'remote-9',
        'firebaseUid': 'uid-1',
        'phoneNumber': '+9779812345678',
        'fullName': '',
        'email': '',
        'role': 'shipper',
        'isPhoneVerified': true,
        'createdAt': '2026-01-01T00:00:00.000Z',
        'updatedAt': '2026-01-01T00:00:00.000Z',
      },
    );

    final profile = (await repository.getProfile('uid-1'))!;
    await repository.saveProfile(profile.copyWith(name: 'Aarav Shrestha'));

    expect(dataSource.createCalls, 0);
    expect(dataSource.updateCalls, 1);
    expect(dataSource.updatedRecordIds.single, 'remote-9');
  });

  test('saveProfile creates a record when none exists yet', () async {
    final now = DateTime.utc(2026, 1, 1);
    await repository.saveProfile(
      UserProfileModel.fromJson(<String, dynamic>{
        'firebaseUid': 'uid-2',
        'phoneNumber': '+9779800000000',
        'fullName': 'New Shipper',
        'email': '',
        'role': 'shipper',
        'isPhoneVerified': true,
        'createdAt': now.toIso8601String(),
        'updatedAt': now.toIso8601String(),
      }).toEntity(),
    );

    expect(dataSource.createCalls, 1);
    expect(dataSource.records['uid-2']?.fullName, 'New Shipper');
  });
}
