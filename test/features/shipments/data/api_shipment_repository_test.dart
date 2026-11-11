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
      if (options.path.endsWith('/bids')) return _json(<Map<String, dynamic>>[]);
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
        final shipmentId = options.queryParameters['shipmentId'];
        return _json(
          bids.where((bid) => bid['shipmentId'] == shipmentId).toList(),
        );
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
        final shipmentId = options.queryParameters['shipmentId'];
        return _json(
          bids.where((bid) => bid['shipmentId'] == shipmentId).toList(),
        );
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
}
