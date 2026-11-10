import 'package:dio/dio.dart';

import '../../core/errors/app_exception.dart';
import '../../domain/entities/bid.dart';
import '../../domain/entities/create_shipment_draft.dart';
import '../../domain/entities/shipment.dart';
import '../../domain/enums/bid_status.dart';
import '../../domain/enums/shipment_status.dart';
import '../../domain/repositories/i_shipment_repository.dart';
import '../../domain/rules/bid_acceptance_rule.dart';
import '../../domain/rules/shipment_validation.dart';
import '../models/bid_model.dart';
import '../models/shipment_model.dart';

class ApiShipmentRepository implements IShipmentRepository {
  ApiShipmentRepository({required String baseUrl, Dio? dio})
      : _dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: baseUrl,
                connectTimeout: const Duration(seconds: 10),
                receiveTimeout: const Duration(seconds: 10),
                sendTimeout: const Duration(seconds: 10),
              ),
            );

  final Dio _dio;

  @override
  Future<List<Shipment>> getShipments({
    String? search,
    ShipmentStatus? status,
  }) async {
    try {
      final responses = await Future.wait<Response<dynamic>>(
        <Future<Response<dynamic>>>[
          _dio.get<dynamic>('/shipments'),
          _dio.get<dynamic>('/bids'),
        ],
      );

      final bids = _bidModels(responses[1].data);
      final grouped = <String, List<Bid>>{};
      for (final bid in bids) {
        grouped.putIfAbsent(bid.shipmentId, () => <Bid>[]).add(bid.toEntity());
      }

      final results = _shipmentModels(responses[0].data)
          .map(
            (model) => model.toEntity(
              bids: grouped[model.id] ?? const <Bid>[],
            ),
          )
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

      return _filter(results, search, status);
    } on DioException catch (error) {
      throw _mapDioError(error);
    } on FormatException {
      throw const ServerException('The mock API returned invalid date data.');
    } on TypeError {
      throw const ServerException(
        'The mock API returned an unexpected response.',
      );
    }
  }

  @override
  Future<Shipment> getShipmentById(String id) async {
    try {
      final response = await _dio.get<dynamic>('/shipments/$id');
      final model = ShipmentModel.fromJson(
        response.data as Map<String, dynamic>,
      );
      final bids = await _fetchBids(id);
      return model.toEntity(bids: bids);
    } on DioException catch (error) {
      throw _mapDioError(error);
    } on FormatException {
      throw const ServerException('The mock API returned invalid date data.');
    } on TypeError {
      throw const ServerException(
        'The mock API returned an unexpected response.',
      );
    }
  }

  @override
  Future<List<Bid>> getBids(String shipmentId) async {
    try {
      return await _fetchBids(shipmentId);
    } on DioException catch (error) {
      throw _mapDioError(error);
    } on FormatException {
      throw const ServerException('The mock API returned invalid date data.');
    } on TypeError {
      throw const ServerException(
        'The mock API returned an unexpected response.',
      );
    }
  }

  @override
  Future<Shipment> createShipment(CreateShipmentDraft draft) async {
    ShipmentValidation.validate(draft);

    try {
      final reference = await _nextReference();
      final now = DateTime.now();
      final response = await _dio.post<dynamic>(
        '/shipments',
        data: <String, dynamic>{
          'reference': reference,
          'shipperName': 'Demo Shipper',
          'pickupCity': draft.pickupCity.trim(),
          'pickupAddress': draft.pickupAddress.trim(),
          'destinationCity': draft.destinationCity.trim(),
          'destinationAddress': draft.destinationAddress.trim(),
          'cargoDescription': draft.cargoDescription.trim(),
          'cargoCategory': draft.cargoCategory,
          'weight': draft.weight,
          'weightUnit': draft.weightUnit,
          'vehicleType': draft.vehicleType,
          'pickupAt': draft.pickupAt.toIso8601String(),
          'expectedFare': draft.expectedFare,
          'currency': draft.currency,
          'status': ShipmentStatus.open.wire,
          'acceptedBidId': '',
          'assignedCarrier': '',
          'notes': draft.notes.trim(),
          'createdAt': now.toIso8601String(),
          'updatedAt': now.toIso8601String(),
        },
      );
      return ShipmentModel.fromJson(
        response.data as Map<String, dynamic>,
      ).toEntity();
    } on DioException catch (error) {
      throw _mapDioError(error);
    } on FormatException {
      throw const ServerException('The mock API returned invalid date data.');
    } on TypeError {
      throw const ServerException(
        'The mock API returned an unexpected response.',
      );
    }
  }

  @override
  Future<Shipment> acceptBid({
    required String shipmentId,
    required String bidId,
  }) async {
    try {
      final response = await _dio.get<dynamic>('/shipments/$shipmentId');
      final shipment = ShipmentModel.fromJson(
        response.data as Map<String, dynamic>,
      );
      final bids = await _fetchBidModels(shipmentId);

      final matches = bids.where((bid) => bid.id == bidId).toList();
      if (matches.isEmpty) {
        throw const NotFoundException('Bid not found.');
      }

      final acceptedBid = matches.first;
      BidAcceptanceRule.ensureCanAccept(
        shipment.toEntity(),
        acceptedBid.toEntity(),
      );

      final updatedAt = DateTime.now();
      var shipmentPatched = false;
      final patchedBidStatuses = <String, String>{};

      try {
        await _dio.patch<dynamic>(
          '/shipments/$shipmentId',
          data: <String, dynamic>{
            'status': ShipmentStatus.confirmed.wire,
            'acceptedBidId': acceptedBid.id,
            'assignedCarrier': acceptedBid.carrierName,
            'updatedAt': updatedAt.toIso8601String(),
          },
        );
        shipmentPatched = true;

        await _patchBidStatus(bidId, BidStatus.accepted.wire);
        patchedBidStatuses[bidId] = acceptedBid.status;

        for (final bid in bids) {
          if (bid.id == bidId) continue;
          if (bid.status != BidStatus.pending.wire) continue;
          await _patchBidStatus(bid.id, BidStatus.rejected.wire);
          patchedBidStatuses[bid.id] = bid.status;
        }
      } catch (_) {
        await _restoreAcceptance(
          shipment: shipment,
          patchedBidStatuses: patchedBidStatuses,
          shipmentPatched: shipmentPatched,
        );
        rethrow;
      }

      final updatedBids = bids.map((bid) {
        if (bid.id == bidId) {
          return bid.copyWith(status: BidStatus.accepted.wire);
        }
        if (bid.status == BidStatus.pending.wire) {
          return bid.copyWith(status: BidStatus.rejected.wire);
        }
        return bid;
      }).toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

      return shipment
          .copyWith(
            status: ShipmentStatus.confirmed.wire,
            acceptedBidId: acceptedBid.id,
            assignedCarrier: acceptedBid.carrierName,
            updatedAt: updatedAt,
          )
          .toEntity(
            bids: updatedBids.map((bid) => bid.toEntity()).toList(),
          );
    } on DioException catch (error) {
      throw _mapDioError(error);
    } on FormatException {
      throw const ServerException('The mock API returned invalid date data.');
    } on TypeError {
      throw const ServerException(
        'The mock API returned an unexpected response.',
      );
    }
  }

  Future<void> _patchBidStatus(String bidId, String status) async {
    await _dio.patch<dynamic>(
      '/bids/$bidId',
      data: <String, dynamic>{'status': status},
    );
  }

  Future<void> _restoreAcceptance({
    required ShipmentModel shipment,
    required Map<String, String> patchedBidStatuses,
    required bool shipmentPatched,
  }) async {
    var rollbackFailed = false;

    for (final entry in patchedBidStatuses.entries) {
      try {
        await _patchBidStatus(entry.key, entry.value);
      } catch (_) {
        rollbackFailed = true;
      }
    }

    if (shipmentPatched) {
      try {
        await _dio.patch<dynamic>(
          '/shipments/${shipment.id}',
          data: <String, dynamic>{
            'status': shipment.status,
            'acceptedBidId': shipment.acceptedBidId ?? '',
            'assignedCarrier': shipment.assignedCarrier ?? '',
            'updatedAt': shipment.updatedAt.toIso8601String(),
          },
        );
      } catch (_) {
        rollbackFailed = true;
      }
    }

    if (rollbackFailed) {
      throw const ServerException(
        'Bid acceptance failed and the server could not be restored.',
      );
    }
  }

  Future<List<Bid>> _fetchBids(String shipmentId) async {
    final models = await _fetchBidModels(shipmentId);
    return models.map((model) => model.toEntity()).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  Future<List<BidModel>> _fetchBidModels(String shipmentId) async {
    final response = await _dio.get<dynamic>(
      '/bids',
      queryParameters: <String, dynamic>{'shipmentId': shipmentId},
    );
    return _bidModels(response.data);
  }

  Future<String> _nextReference() async {
    final response = await _dio.get<dynamic>('/shipments');
    var max = 1000;
    for (final model in _shipmentModels(response.data)) {
      final match = RegExp(r'^LOD-(\d+)$').firstMatch(model.reference);
      if (match == null) continue;
      final number = int.tryParse(match.group(1) ?? '') ?? 0;
      if (number > max) max = number;
    }
    return 'LOD-${max + 1}';
  }

  List<Shipment> _filter(
    List<Shipment> shipments,
    String? search,
    ShipmentStatus? status,
  ) {
    Iterable<Shipment> results = shipments;
    if (status != null) {
      results = results.where((shipment) => shipment.status == status);
    }

    final query = search?.trim().toLowerCase() ?? '';
    if (query.isNotEmpty) {
      results = results.where((shipment) {
        return shipment.reference.toLowerCase().contains(query) ||
            shipment.pickupCity.toLowerCase().contains(query) ||
            shipment.destinationCity.toLowerCase().contains(query) ||
            shipment.routeLabel.toLowerCase().contains(query);
      });
    }

    return results.toList();
  }

  List<ShipmentModel> _shipmentModels(dynamic data) {
    final items = data as List<dynamic>;
    return items
        .map(
          (item) => ShipmentModel.fromJson(item as Map<String, dynamic>),
        )
        .toList();
  }

  List<BidModel> _bidModels(dynamic data) {
    final items = data as List<dynamic>;
    return items
        .map((item) => BidModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  AppException _mapDioError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.transformTimeout:
      case DioExceptionType.connectionError:
        return const NetworkException();
      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode ?? 0;
        if (statusCode == 404) return const NotFoundException();
        if (statusCode == 409) return const ConflictException();
        if (statusCode == 400 || statusCode == 422) {
          return ValidationException(
            'The server rejected the request ($statusCode).',
          );
        }
        return ServerException('Server error ($statusCode).', statusCode);
      case DioExceptionType.cancel:
        return const ServerException('The request was cancelled.');
      case DioExceptionType.badCertificate:
        return const NetworkException('The server certificate is invalid.');
      case DioExceptionType.unknown:
        return const NetworkException();
    }
  }
}
