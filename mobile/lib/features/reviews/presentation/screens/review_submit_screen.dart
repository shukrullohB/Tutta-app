import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_names.dart';
import '../../../../core/errors/app_exception.dart';
import '../../application/review_submit_controller.dart';

class ReviewSubmitScreen extends ConsumerStatefulWidget {
  const ReviewSubmitScreen({super.key, required this.bookingId});

  final String bookingId;

  @override
  ConsumerState<ReviewSubmitScreen> createState() => _ReviewSubmitScreenState();
}

class _ReviewSubmitScreenState extends ConsumerState<ReviewSubmitScreen> {
  final TextEditingController _commentController = TextEditingController();
  int _rating = 5;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    try {
      await ref
          .read(reviewSubmitControllerProvider.notifier)
          .submit(
            bookingId: widget.bookingId,
            rating: _rating,
            comment: _commentController.text,
          );
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _t(
              context,
              en: 'Review submitted. Thank you!',
              ru: 'Отзыв отправлен. Спасибо!',
              uz: 'Sharh yuborildi. Rahmat!',
            ),
          ),
        ),
      );
      context.pop();
    } on AppException catch (error) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _t(
              context,
              en: 'Could not submit review.',
              ru: 'Не удалось отправить отзыв.',
              uz: 'Sharhni yuborib bo\'lmadi.',
            ),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final loading = ref.watch(reviewSubmitControllerProvider).isLoading;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => context.canPop()
              ? context.pop()
              : context.go(RouteNames.bookings),
          icon: const Icon(Icons.arrow_back),
        ),
        title: Text(
          _t(
            context,
            en: 'Leave review',
            ru: 'Оставить отзыв',
            uz: 'Sharh qoldirish',
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            _t(
              context,
              en: 'Rate your stay',
              ru: 'Оцените проживание',
              uz: 'Yashashni baholang',
            ),
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: List.generate(5, (index) {
              final value = index + 1;
              return ChoiceChip(
                label: Text('$value'),
                selected: _rating == value,
                onSelected: loading
                    ? null
                    : (_) => setState(() => _rating = value),
              );
            }),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _commentController,
            enabled: !loading,
            maxLines: 4,
            decoration: InputDecoration(
              labelText: _t(
                context,
                en: 'Comment',
                ru: 'Комментарий',
                uz: 'Izoh',
              ),
              hintText: _t(
                context,
                en: 'How was cleanliness, communication, and comfort?',
                ru: 'Как прошли чистота, общение и комфорт?',
                uz: 'Tozalik, muloqot va qulaylik qanday bo\'ldi?',
              ),
            ),
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: loading ? null : _submit,
            child: Text(
              loading
                  ? _t(
                      context,
                      en: 'Submitting...',
                      ru: 'Отправка...',
                      uz: 'Yuborilmoqda...',
                    )
                  : _t(
                      context,
                      en: 'Submit review',
                      ru: 'Отправить отзыв',
                      uz: 'Sharh yuborish',
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

String _t(
  BuildContext context, {
  required String en,
  required String ru,
  required String uz,
}) {
  switch (Localizations.localeOf(context).languageCode) {
    case 'ru':
      return ru;
    case 'uz':
      return uz;
    default:
      return en;
  }
}
