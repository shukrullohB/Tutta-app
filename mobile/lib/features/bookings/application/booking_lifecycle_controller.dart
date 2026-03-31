import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_exception.dart';
import '../../auth/application/auth_controller.dart';
import 'booking_request_controller.dart';

class BookingLifecycleController extends StateNotifier<AsyncValue<void>> {
  BookingLifecycleController(this._read) : super(const AsyncValue.data(null));

  final Ref _read;

  Future<void> confirm(String bookingId) async {
    state = const AsyncValue.loading();
    final hostId = _currentUserId();

    try {
      await _read
          .read(bookingRepositoryProvider)
          .confirmBooking(bookingId: bookingId, hostUserId: hostId);
      state = const AsyncValue.data(null);
    } on AppException catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      rethrow;
    } catch (error, stackTrace) {
      final appError = AppException(error.toString());
      state = AsyncValue.error(appError, stackTrace);
      throw appError;
    }
  }

  Future<void> reject(String bookingId) async {
    state = const AsyncValue.loading();
    final hostId = _currentUserId();

    try {
      await _read
          .read(bookingRepositoryProvider)
          .rejectBooking(bookingId: bookingId, hostUserId: hostId);
      state = const AsyncValue.data(null);
    } on AppException catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      rethrow;
    } catch (error, stackTrace) {
      final appError = AppException(error.toString());
      state = AsyncValue.error(appError, stackTrace);
      throw appError;
    }
  }

  Future<void> cancelByGuest(String bookingId) async {
    state = const AsyncValue.loading();
    final guestId = _currentUserId();

    try {
      await _read
          .read(bookingRepositoryProvider)
          .cancelByGuest(bookingId: bookingId, guestUserId: guestId);
      state = const AsyncValue.data(null);
    } on AppException catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      rethrow;
    } catch (error, stackTrace) {
      final appError = AppException(error.toString());
      state = AsyncValue.error(appError, stackTrace);
      throw appError;
    }
  }

  Future<void> complete(String bookingId) async {
    state = const AsyncValue.loading();
    final hostId = _currentUserId();

    try {
      await _read
          .read(bookingRepositoryProvider)
          .markCompleted(bookingId: bookingId, hostUserId: hostId);
      state = const AsyncValue.data(null);
    } on AppException catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      rethrow;
    } catch (error, stackTrace) {
      final appError = AppException(error.toString());
      state = AsyncValue.error(appError, stackTrace);
      throw appError;
    }
  }

  String _currentUserId() {
    final userId = _read.read(authControllerProvider).valueOrNull?.user?.id;
    if (userId == null) {
      throw const AppException('Please sign in again.');
    }
    return userId;
  }
}

final bookingLifecycleControllerProvider =
    StateNotifierProvider<BookingLifecycleController, AsyncValue<void>>((ref) {
      return BookingLifecycleController(ref);
    });
