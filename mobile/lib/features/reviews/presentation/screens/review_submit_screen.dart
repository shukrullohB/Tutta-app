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
        const SnackBar(content: Text('Review submitted. Thank you!')),
      );
      context.pop();
    } on AppException catch (error) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    } catch (_) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Could not submit review.')));
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
        title: const Text('Leave review'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Rate your stay',
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
            decoration: const InputDecoration(
              labelText: 'Comment',
              hintText: 'How was cleanliness, communication, and comfort?',
            ),
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: loading ? null : _submit,
            child: Text(loading ? 'Submitting...' : 'Submit review'),
          ),
        ],
      ),
    );
  }
}
