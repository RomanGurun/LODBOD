import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lodbod/core/errors/app_exception.dart';
import 'package:lodbod/features/shipments/data/remote/api_shipment_repository.dart';
import 'package:lodbod/features/shipments/domain/entities/create_shipment_draft.dart';
import 'package:lodbod/features/shipments/domain/enums/bid_status.dart';
import 'package:lodbod/features/shipments/domain/enums/shipment_status.dart';

typedef _Handler = ResponseBody Function(RequestOptions options);

class _FakeAdapter implements HttpClientAdapter {
  _FakeAdapter(this.handler);

  final _Handler handler;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    return handler(options);
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody _json(Object data, {int statusCode = 200}) {
  return ResponseBody.fromString(
    jsonEncode(data),
    statusCode,
    headers: <String, List<String>>{
      Headers.contentTypeHeader: <String>[Headers.jsonContentType],
    },
  );
}

ApiShipmentRepository _repository(_Handler handler) {
  final dio = Dio(BaseOptions(baseUrl: 'https://mock.test'))
    ..httpClientAdapter = _FakeAdapter(handler);
  return ApiShipmentRepository(baseUrl: 'https://mock.test', dio: dio);
}

Map<String, dynamic> _shipment({
  required String id,
  required String reference,
  required String status,
  required String createdAt,
  String pickupCity = 'Kathmandu',
  String destinationCity = 'Pokhara',
  String shipperId = '',
}) {
  return <String, dynamic>{
    'id': id,
    'reference': reference,
    'shipperName': 'Demo Shipper',
    'shipperId': shipperId,
    'pickupCity': pickupCity,
    'pickupAddress': 'Pickup address',
    'destinationCity': destinationCity,
    'destinationAddress': 'Destination address',
    'cargoDescription': 'Cargo',
    'cargoCategory': 'construction',
    'weight': 10,
    'weightUnit': 'tonnes',
    'vehicleType': 'truck_10w',
    'pickupAt': '2027-01-20T08:00:00.000Z',
    'expectedFare': 18000,
    'currency': 'NPR',
    'status': status,
    'acceptedBidId': '',
    'assignedCarrier': '',
    'notes': '',
    'createdAt': createdAt,
    'updatedAt': createdAt,
  };
}

Map<String, dynamic> _bid({
  required String id,
  required String carrierName,
  required double fare,
  String status = 'pending',
  String createdAt = '2026-11-04T12:00:00.000Z',
}) {
  return <String, dynamic>{
    'id': id,
    'shipmentId': '2',
    'carrierName': carrierName,
    'carrierRating': 4.5,
    'carrierVerified': true,
    'fare': fare,
    'currency': 'NPR',
    'etaDays': 2,
    'estimatedDeliveryAt': '2027-01-23T18:00:00.000Z',
    'message': '',
    'status': status,
    'createdAt': createdAt,
  };
}

List<Map<String, dynamic>> _shipmentRows() {
  return <Map<String, dynamic>>[
    _shipment(
      id: '1',
      reference: 'LOD-1001',
      status: 'in_transit',
      createdAt: '2026-11-02T10:00:00.000Z',
    ),
    _shipment(
      id: '2',
      reference: 'LOD-1002',
      status: 'awaiting_bids',
      createdAt: '2026-11-03T10:00:00.000Z',
      pickupCity: 'Birgunj',
      destinationCity: 'Kathmandu',
    ),
    _shipment(
      id: '3',
      reference: 'LOD-1003',
      status: 'delivered',
      createdAt: '2026-10-21T10:00:00.000Z',
      pickupCity: 'Butwal',
      destinationCity: 'Narayanghat',
    ),
    _shipment(
      id: '4',
      reference: 'LOD-1004',
      status: 'cancelled',
      createdAt: '2026-11-05T10:00:00.000Z',
      pickupCity: 'Kathmandu',
      destinationCity: 'Biratnagar',
    ),
  ];
}

void main() {
  test('fetches, sorts, groups bids and filters client-side', () async {
    final shipments = _shipmentRows();
    final bids = <Map<String, dynamic>>[
      _bid(id: '1', carrierName: 'Himalayan Cargo', fare: 32000),
      _bid(
        id: '2',
        carrierName: 'Swift Transport',
        fare: 29500,
        createdAt: '2026-11-04T13:00:00.000Z',
      ),
    ];

    final repo = _repository((options) {
      if (options.path == '/shipments') return _json(shipments);
      if (options.path == '/bids') return _json(bids);
      throw StateError('Unexpected path ${options.path}');
    });

    final all = await repo.getShipments();
    expect(
      all.map((shipment) => shipment.reference).toList(),
      <String>['LOD-1004', 'LOD-1002', 'LOD-1001', 'LOD-1003'],
    );

    final lod1002 =
        all.firstWhere((shipment) => shipment.reference == 'LOD-1002');
    expect(lod1002.status, ShipmentStatus.awaitingBids);
    expect(lod1002.bidCount, 2);
    expect(
      lod1002.bids.map((bid) => bid.carrierName),
      containsAll(<String>['Himalayan Cargo', 'Swift Transport']),
    );

    final search = await repo.getShipments(search: 'birgunj');
    expect(search.map((shipment) => shipment.reference), <String>['LOD-1002']);

    final cancelled = await repo.getShipments(status: ShipmentStatus.cancelled);
    expect(
        cancelled.map((shipment) => shipment.reference), <String>['LOD-1004']);
  });

  test('creates a shipment with the next reference and open status', () async {
    final shipments = _shipmentRows();
    RequestOptions? posted;

    final repo = _repository((options) {
      if (options.path == '/shipments' && options.method == 'GET') {
        return _json(shipments);
      }
      if (options.path == '/shipments' && options.method == 'POST') {
        posted = options;
        final body = Map<String, dynamic>.from(options.data as Map);
        return _json(<String, dynamic>{...body, 'id': '5'}, statusCode: 201);
      }
      throw StateError('Unexpected ${options.method} ${options.path}');
    });

    final draft = CreateShipmentDraft(
      pickupCity: 'Kathmandu',
      pickupAddress: 'Balaju',
      destinationCity: 'Pokhara',
      destinationAddress: 'Lakeside',
      cargoDescription: 'Bricks',
      cargoCategory: 'construction',
      weight: 6,
      weightUnit: 'tonnes',
      vehicleType: 'truck_6w',
      pickupAt: DateTime.now().add(const Duration(days: 2)),
      expectedFare: 15000,
      shipperId: 'uid-123',
      shipperName: 'Aarav Shrestha',
    );

    final created = await repo.createShipment(draft);

    expect(posted, isNotNull);
    expect(posted!.data, isA<Map<String, dynamic>>());
    final body = posted!.data as Map<String, dynamic>;
    expect(body['reference'], 'LOD-1005');
    expect(body['status'], 'open');
    expect(body['pickupCity'], 'Kathmandu');
    expect(body['shipperId'], 'uid-123');
    expect(body['shipperName'], 'Aarav Shrestha');
    expect(created.reference, 'LOD-1005');
    expect(created.status, ShipmentStatus.open);
    expect(created.shipperId, 'uid-123');
  });

  test('parses shipperId and treats blank values as absent', () async {
    final shipments = <Map<String, dynamic>>[
      _shipment(
        id: '1',
        reference: 'LOD-1001',
        status: 'in_transit',
        createdAt: '2026-11-02T10:00:00.000Z',
        shipperId: 'uid-owner',
      ),
      _shipment(
        id: '2',
        reference: 'LOD-1002',
        status: 'awaiting_bids',
        createdAt: '2026-11-03T10:00:00.000Z',
      ),
    ];

    // The repository also fetches /bids for the shipments; answer that path
    // with an empty list so only shipment rows are parsed.
    final repo = _repository((options) {
      if (options.path.endsWith('/bids')) {
        return _json(<Map<String, dynamic>>[]);
      }
      return _json(shipments);
    });

    final all = await repo.getShipments();

    final owned =
        all.firstWhere((shipment) => shipment.reference == 'LOD-1001');
    final legacy =
        all.firstWhere((shipment) => shipment.reference == 'LOD-1002');
    expect(owned.shipperId, 'uid-owner');
    // Legacy seed rows come back with a null owner, never an empty string.
    expect(legacy.shipperId, isNull);
  });

  test('accepts one bid, rejects the others and confirms the shipment',
      () async {
    var shipments = _shipmentRows();
    var bids = <Map<String, dynamic>>[
      _bid(id: '1', carrierName: 'Himalayan Cargo', fare: 32000),
      _bid(
        id: '2',
        carrierName: 'Swift Transport',
        fare: 29500,
        createdAt: '2026-11-04T13:00:00.000Z',
      ),
    ];

    final repo = _repository((options) {
      final path = options.path;
      if (path == '/shipments/2' && options.method == 'GET') {
        return _json(shipments.firstWhere((row) => row['id'] == '2'));
      }
      if (path == '/bids' && options.method == 'GET') {
        // The repository fetches the collection and filters client-side.
        return _json(bids);
      }
      if (path == '/shipments/2' && options.method == 'PATCH') {
        final body = Map<String, dynamic>.from(options.data as Map);
        shipments = shipments
            .map((row) => row['id'] == '2' ? {...row, ...body} : row)
            .toList();
        return _json(shipments.firstWhere((row) => row['id'] == '2'));
      }
      if (path.startsWith('/bids/') && options.method == 'PATCH') {
        final id = path.split('/').last;
        final body = Map<String, dynamic>.from(options.data as Map);
        bids = bids
            .map((row) => row['id'] == id ? {...row, ...body} : row)
            .toList();
        return _json(bids.firstWhere((row) => row['id'] == id));
      }
      throw StateError('Unexpected ${options.method} $path');
    });

    final updated = await repo.acceptBid(shipmentId: '2', bidId: '2');

    expect(updated.status, ShipmentStatus.confirmed);
    expect(updated.acceptedBidId, '2');
    expect(updated.assignedCarrier, 'Swift Transport');

    final accepted = updated.bids.firstWhere((bid) => bid.id == '2');
    final rejected = updated.bids.firstWhere((bid) => bid.id == '1');
    expect(accepted.status, BidStatus.accepted);
    expect(rejected.status, BidStatus.rejected);
  });

  test('rolls back a partial acceptance when a bid update fails', () async {
    var shipments = _shipmentRows();
    var bids = <Map<String, dynamic>>[
      _bid(id: '1', carrierName: 'Himalayan Cargo', fare: 32000),
      _bid(
        id: '2',
        carrierName: 'Swift Transport',
        fare: 29500,
        createdAt: '2026-11-04T13:00:00.000Z',
      ),
    ];
    var failFirstRejection = true;

    final repo = _repository((options) {
      final path = options.path;
      if (path == '/shipments/2' && options.method == 'GET') {
        return _json(shipments.firstWhere((row) => row['id'] == '2'));
      }
      if (path == '/bids' && options.method == 'GET') {
        // The repository fetches the collection and filters client-side.
        return _json(bids);
      }
      if (path == '/shipments/2' && options.method == 'PATCH') {
        final body = Map<String, dynamic>.from(options.data as Map);
        shipments = shipments
            .map((row) => row['id'] == '2' ? {...row, ...body} : row)
            .toList();
        return _json(shipments.firstWhere((row) => row['id'] == '2'));
      }
      if (path.startsWith('/bids/') && options.method == 'PATCH') {
        final id = path.split('/').last;
        final body = Map<String, dynamic>.from(options.data as Map);
        if (id == '1' && body['status'] == 'rejected' && failFirstRejection) {
          failFirstRejection = false;
          return _json(
            <String, dynamic>{'message': 'boom'},
            statusCode: 500,
          );
        }
        bids = bids
            .map((row) => row['id'] == id ? {...row, ...body} : row)
            .toList();
        return _json(bids.firstWhere((row) => row['id'] == id));
      }
      throw StateError('Unexpected ${options.method} $path');
    });

    await expectLater(
      repo.acceptBid(shipmentId: '2', bidId: '2'),
      throwsA(isA<ServerException>()),
    );

    final shipment = shipments.firstWhere((row) => row['id'] == '2');
    expect(shipment['status'], 'awaiting_bids');
    expect(shipment['acceptedBidId'], '');
    expect(shipment['assignedCarrier'], '');
    expect(
      bids.map((bid) => bid['status']).toList(),
      <String>['pending', 'pending'],
    );
  });

  test('maps not found and server errors to app exceptions', () async {
    final notFound = _repository(
      (options) =>
          _json(<String, dynamic>{'message': 'not found'}, statusCode: 404),
    );
    await expectLater(
      notFound.getShipmentById('999'),
      throwsA(isA<NotFoundException>()),
    );

    final serverError = _repository(
      (options) => _json(<String, dynamic>{'message': 'boom'}, statusCode: 500),
    );
    await expectLater(
      serverError.getShipments(),
      throwsA(isA<ServerException>()),
    );
  });

  test('treats a 404 on the bids collection as no bids', () async {
    // MockAPI answers collection reads that match zero rows with 404
    // instead of an empty list, so a bid collection with no rows arrives
    // looking like a missing resource.
    final repo = _repository((options) {
      if (options.path == '/bids' && options.method == 'GET') {
        return _json(
          <String, dynamic>{'message': 'Not found'},
          statusCode: 404,
        );
      }
      throw StateError('Unexpected ${options.method} ${options.path}');
    });

    expect(await repo.getBids('5'), isEmpty);
  });

  test('returns a shipment with no bids when its bids query 404s', () async {
    final repo = _repository((options) {
      if (options.path == '/shipments/5' && options.method == 'GET') {
        return _json(
          _shipment(
            id: '5',
            reference: 'LOD-1005',
            status: 'open',
            createdAt: '2026-11-08T10:00:00.000Z',
          ),
        );
      }
      if (options.path == '/bids' && options.method == 'GET') {
        return _json(
          <String, dynamic>{'message': 'Not found'},
          statusCode: 404,
        );
      }
      throw StateError('Unexpected ${options.method} ${options.path}');
    });

    final shipment = await repo.getShipmentById('5');

    expect(shipment.reference, 'LOD-1005');
    expect(shipment.bids, isEmpty);
  });

  test('loads shipments when the bids collection read is a 404', () async {
    final repo = _repository((options) {
      if (options.path == '/shipments') {
        return _json(_shipmentRows());
      }
      if (options.path == '/bids') {
        return _json(
          <String, dynamic>{'message': 'Not found'},
          statusCode: 404,
        );
      }
      throw StateError('Unexpected ${options.method} ${options.path}');
    });

    final all = await repo.getShipments();

    expect(all, hasLength(4));
    expect(all.every((shipment) => shipment.bids.isEmpty), isTrue);
  });

  test(
      'simulates a carrier bid on an open load and flips it to awaiting '
      'bids', () async {
    var shipments = <Map<String, dynamic>>[
      _shipment(
        id: '5',
        reference: 'LOD-1005',
        status: 'open',
        createdAt: '2026-11-08T10:00:00.000Z',
      ),
    ];
    var bids = <Map<String, dynamic>>[];
    RequestOptions? postedBid;
    RequestOptions? patchedShipment;

    final repo = _repository((options) {
      final path = options.path;
      if (path == '/shipments/5' && options.method == 'GET') {
        return _json(shipments.first);
      }
      if (path == '/bids' && options.method == 'GET') {
        return _json(bids);
      }
      if (path == '/bids' && options.method == 'POST') {
        postedBid = options;
        final body = Map<String, dynamic>.from(options.data as Map);
        final created = <String, dynamic>{...body, 'id': '10'};
        bids = <Map<String, dynamic>>[created];
        return _json(created, statusCode: 201);
      }
      if (path == '/shipments/5' && options.method == 'PATCH') {
        patchedShipment = options;
        final body = Map<String, dynamic>.from(options.data as Map);
        shipments = shipments
            .map((row) => row['id'] == '5' ? {...row, ...body} : row)
            .toList();
        return _json(shipments.first);
      }
      throw StateError('Unexpected ${options.method} $path');
    });

    final updated = await repo.simulateCarrierBid('5');

    // The bid is posted as a pending quote for that shipment.
    expect(postedBid, isNotNull);
    final body = postedBid!.data as Map<String, dynamic>;
    expect(body['shipmentId'], '5');
    expect(body['status'], 'pending');
    expect(body['carrierName'], isNotEmpty);
    expect(body['fare'], greaterThan(0));

    // The open load flips to awaiting bids so the quote can be accepted.
    expect(patchedShipment, isNotNull);
    final patchBody = patchedShipment!.data as Map<String, dynamic>;
    expect(patchBody['status'], 'awaiting_bids');

    expect(updated.status, ShipmentStatus.awaitingBids);
    expect(updated.bidCount, 1);
    expect(updated.bids.single.status, BidStatus.pending);
    expect(updated.bids.single.id, '10');
  });

  test(
      'simulates a carrier bid when the zero-bids query is answered with '
      '404', () async {
    // Reproduces the live MockAPI behaviour on freshly posted loads: the
    // shipment exists, but /bids?shipmentId=x matches no rows yet and the
    // service answers 404 instead of []. Simulating a bid must still work
    // instead of failing with a missing-resource error.
    var shipments = <Map<String, dynamic>>[
      _shipment(
        id: '5',
        reference: 'LOD-1005',
        status: 'open',
        createdAt: '2026-11-08T10:00:00.000Z',
      ),
    ];
    var bids = <Map<String, dynamic>>[];

    final repo = _repository((options) {
      final path = options.path;
      if (path == '/shipments/5' && options.method == 'GET') {
        return _json(shipments.first);
      }
      if (path == '/bids' && options.method == 'GET') {
        return _json(
          <String, dynamic>{'message': 'Not found'},
          statusCode: 404,
        );
      }
      if (path == '/bids' && options.method == 'POST') {
        final body = Map<String, dynamic>.from(options.data as Map);
        final created = <String, dynamic>{...body, 'id': '10'};
        bids = <Map<String, dynamic>>[created];
        return _json(created, statusCode: 201);
      }
      if (path == '/shipments/5' && options.method == 'PATCH') {
        final body = Map<String, dynamic>.from(options.data as Map);
        shipments = shipments
            .map((row) => row['id'] == '5' ? {...row, ...body} : row)
            .toList();
        return _json(shipments.first);
      }
      throw StateError('Unexpected ${options.method} $path');
    });

    final updated = await repo.simulateCarrierBid('5');

    // The bid really reached the server and the load flipped to awaiting
    // bids so it can be accepted.
    expect(bids, hasLength(1));
    expect(bids.single['shipmentId'], '5');
    expect(updated.status, ShipmentStatus.awaitingBids);
    expect(updated.bidCount, 1);
  });

  test('simulating a bid on an awaiting-bids shipment needs no status patch',
      () async {
    var shipments = _shipmentRows();
    var bids = <Map<String, dynamic>>[
      _bid(id: '1', carrierName: 'Himalayan Cargo', fare: 32000),
      _bid(
        id: '2',
        carrierName: 'Swift Transport',
        fare: 29500,
        createdAt: '2026-11-04T13:00:00.000Z',
      ),
    ];
    var patchedShipment = false;

    final repo = _repository((options) {
      final path = options.path;
      if (path == '/shipments/2' && options.method == 'GET') {
        return _json(shipments.firstWhere((row) => row['id'] == '2'));
      }
      if (path == '/bids' && options.method == 'GET') {
        return _json(bids);
      }
      if (path == '/bids' && options.method == 'POST') {
        final body = Map<String, dynamic>.from(options.data as Map);
        final created = <String, dynamic>{...body, 'id': '3'};
        bids = [...bids, created];
        return _json(created, statusCode: 201);
      }
      if (path == '/shipments/2' && options.method == 'PATCH') {
        patchedShipment = true;
        return _json(shipments.firstWhere((row) => row['id'] == '2'));
      }
      throw StateError('Unexpected ${options.method} $path');
    });

    final updated = await repo.simulateCarrierBid('2');

    expect(patchedShipment, isFalse);
    expect(updated.status, ShipmentStatus.awaitingBids);
    expect(updated.bidCount, 3);
    expect(updated.bids.first.status, BidStatus.pending);
  });

  test('rolls the posted bid back when the status patch fails', () async {
    final shipments = <Map<String, dynamic>>[
      _shipment(
        id: '5',
        reference: 'LOD-1005',
        status: 'open',
        createdAt: '2026-11-08T10:00:00.000Z',
      ),
    ];
    final bids = <Map<String, dynamic>>[];
    var deletedBidId = '';

    final repo = _repository((options) {
      final path = options.path;
      if (path == '/shipments/5' && options.method == 'GET') {
        return _json(shipments.first);
      }
      if (path == '/bids' && options.method == 'GET') {
        return _json(bids);
      }
      if (path == '/bids' && options.method == 'POST') {
        final body = Map<String, dynamic>.from(options.data as Map);
        final created = <String, dynamic>{...body, 'id': '10'};
        bids.add(created);
        return _json(created, statusCode: 201);
      }
      if (path == '/shipments/5' && options.method == 'PATCH') {
        return _json(<String, dynamic>{'message': 'boom'}, statusCode: 500);
      }
      if (path == '/bids/10' && options.method == 'DELETE') {
        deletedBidId = path.split('/').last;
        bids.clear();
        return _json(<String, dynamic>{});
      }
      throw StateError('Unexpected ${options.method} $path');
    });

    await expectLater(
      repo.simulateCarrierBid('5'),
      throwsA(isA<ServerException>()),
    );

    // The just-created bid was removed again — no orphaned quote.
    expect(deletedBidId, '10');
    expect(bids, isEmpty);
  });

  test('refuses to simulate a bid on a delivered shipment', () async {
    var postedBid = false;
    final repo = _repository((options) {
      final path = options.path;
      if (path == '/shipments/3' && options.method == 'GET') {
        return _json(
          _shipmentRows().firstWhere((row) => row['id'] == '3'),
        );
      }
      if (path == '/bids' && options.method == 'GET') {
        return _json(<Map<String, dynamic>>[]);
      }
      if (path == '/bids' && options.method == 'POST') {
        postedBid = true;
        throw StateError('POST should never happen');
      }
      throw StateError('Unexpected ${options.method} $path');
    });

    await expectLater(
      repo.simulateCarrierBid('3'),
      throwsA(isA<ConflictException>()),
    );
    expect(postedBid, isFalse);
  });

  test('advances an in-transit shipment to delivered', () async {
    var shipments = _shipmentRows();
    RequestOptions? patchBody;
    final bids = <Map<String, dynamic>>[
      <String, dynamic>{
        ..._bid(id: '1', carrierName: 'Everest Freight', fare: 20000),
        'shipmentId': '1',
      },
    ];

    final repo = _repository((options) {
      final path = options.path;
      if (path == '/shipments/1' && options.method == 'GET') {
        return _json(shipments.firstWhere((row) => row['id'] == '1'));
      }
      if (path == '/bids' && options.method == 'GET') {
        return _json(bids);
      }
      if (path == '/shipments/1' && options.method == 'PATCH') {
        patchBody = options;
        final body = Map<String, dynamic>.from(options.data as Map);
        shipments = shipments
            .map((row) => row['id'] == '1' ? {...row, ...body} : row)
            .toList();
        return _json(shipments.firstWhere((row) => row['id'] == '1'));
      }
      throw StateError('Unexpected ${options.method} $path');
    });

    final updated = await repo.advanceShipmentStatus('1');

    expect(patchBody, isNotNull);
    expect((patchBody!.data as Map<String, dynamic>)['status'], 'delivered');
    expect(updated.status, ShipmentStatus.delivered);
    // Bids stay attached so the detail screen keeps showing the booking.
    expect(updated.bidCount, 1);
  });

  test('advances an in-transit shipment that has no bids yet', () async {
    // In-transit loads without bid rows hit the same zero-match 404 when
    // their bids are fetched; the status advance must still work.
    var shipments = <Map<String, dynamic>>[
      _shipment(
        id: '1',
        reference: 'LOD-1001',
        status: 'in_transit',
        createdAt: '2026-11-02T10:00:00.000Z',
      ),
    ];

    final repo = _repository((options) {
      final path = options.path;
      if (path == '/shipments/1' && options.method == 'GET') {
        return _json(shipments.first);
      }
      if (path == '/bids' && options.method == 'GET') {
        return _json(
          <String, dynamic>{'message': 'Not found'},
          statusCode: 404,
        );
      }
      if (path == '/shipments/1' && options.method == 'PATCH') {
        final body = Map<String, dynamic>.from(options.data as Map);
        shipments = shipments
            .map((row) => row['id'] == '1' ? {...row, ...body} : row)
            .toList();
        return _json(shipments.first);
      }
      throw StateError('Unexpected ${options.method} $path');
    });

    final updated = await repo.advanceShipmentStatus('1');

    expect(updated.status, ShipmentStatus.delivered);
    expect(updated.bids, isEmpty);
  });

  test('advancing a delivered shipment is refused before any write', () async {
    var patched = false;
    final repo = _repository((options) {
      final path = options.path;
      if (path == '/shipments/3' && options.method == 'GET') {
        return _json(_shipmentRows().firstWhere((row) => row['id'] == '3'));
      }
      if (path == '/shipments/3' && options.method == 'PATCH') {
        patched = true;
        throw StateError('PATCH should never happen');
      }
      throw StateError('Unexpected ${options.method} $path');
    });

    await expectLater(
      repo.advanceShipmentStatus('3'),
      throwsA(isA<ConflictException>()),
    );
    expect(patched, isFalse);
  });
}
