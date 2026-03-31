// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'booking.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$BookingImpl _$$BookingImplFromJson(Map<String, dynamic> json) =>
    _$BookingImpl(
      id: json['id'] as String,
      listingId: json['listingId'] as String,
      guestUserId: json['guestUserId'] as String,
      hostUserId: json['hostUserId'] as String,
      checkInDate: DateTime.parse(json['checkInDate'] as String),
      checkOutDate: DateTime.parse(json['checkOutDate'] as String),
      status: $enumDecode(_$BookingStatusEnumMap, json['status']),
      paymentRequired: json['paymentRequired'] as bool,
      isPaid: json['isPaid'] as bool,
      paymentStatus: $enumDecodeNullable(
        _$PaymentStatusEnumMap,
        json['paymentStatus'],
      ),
      totalPriceUzs: (json['totalPriceUzs'] as num).toInt(),
      guestsCount: (json['guestsCount'] as num).toInt(),
      isReviewAllowed: json['isReviewAllowed'] as bool,
    );

Map<String, dynamic> _$$BookingImplToJson(_$BookingImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'listingId': instance.listingId,
      'guestUserId': instance.guestUserId,
      'hostUserId': instance.hostUserId,
      'checkInDate': instance.checkInDate.toIso8601String(),
      'checkOutDate': instance.checkOutDate.toIso8601String(),
      'status': _$BookingStatusEnumMap[instance.status]!,
      'paymentRequired': instance.paymentRequired,
      'isPaid': instance.isPaid,
      'paymentStatus': _$PaymentStatusEnumMap[instance.paymentStatus],
      'totalPriceUzs': instance.totalPriceUzs,
      'guestsCount': instance.guestsCount,
      'isReviewAllowed': instance.isReviewAllowed,
    };

const _$BookingStatusEnumMap = {
  BookingStatus.pendingHostApproval: 'pendingHostApproval',
  BookingStatus.confirmed: 'confirmed',
  BookingStatus.cancelledByGuest: 'cancelledByGuest',
  BookingStatus.cancelledByHost: 'cancelledByHost',
  BookingStatus.completed: 'completed',
};

const _$PaymentStatusEnumMap = {
  PaymentStatus.pending: 'pending',
  PaymentStatus.processing: 'processing',
  PaymentStatus.succeeded: 'succeeded',
  PaymentStatus.failed: 'failed',
  PaymentStatus.cancelled: 'cancelled',
};
