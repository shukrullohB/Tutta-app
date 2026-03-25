import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class CreateListingScreen extends StatefulWidget {
  const CreateListingScreen({super.key});

  @override
  State<CreateListingScreen> createState() => _CreateListingScreenState();
}

class _CreateListingScreenState extends State<CreateListingScreen> {
  final _titleController = TextEditingController();
  final _cityController = TextEditingController(text: 'Tashkent');
  final _districtController = TextEditingController();

  @override
  void dispose() {
    _titleController.dispose();
    _cityController.dispose();
    _districtController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add listing')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 110),
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF14141E),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0x33FFFFFF)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Publish your space',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Quick draft flow for hosts. Full media upload and moderation can be connected next.',
                    style: TextStyle(color: Color(0xFFB9BBC9), height: 1.3),
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 220.ms).slideY(begin: 0.08, end: 0),
            const SizedBox(height: 12),
            _FieldBlock(
              label: 'Title',
              hint: 'Cozy room near metro',
              controller: _titleController,
            ).animate(delay: 60.ms).fadeIn(duration: 220.ms),
            const SizedBox(height: 10),
            _FieldBlock(
              label: 'City',
              hint: 'Tashkent',
              controller: _cityController,
            ).animate(delay: 100.ms).fadeIn(duration: 220.ms),
            const SizedBox(height: 10),
            _FieldBlock(
              label: 'District',
              hint: 'Yunusabad',
              controller: _districtController,
            ).animate(delay: 140.ms).fadeIn(duration: 220.ms),
            const SizedBox(height: 12),
            Container(
              height: 130,
              decoration: BoxDecoration(
                color: const Color(0xFF1C1C28),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0x33FFFFFF)),
              ),
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add_photo_alternate_outlined, size: 28),
                    SizedBox(height: 8),
                    Text(
                      'Photo upload slot',
                      style: TextStyle(color: Color(0xFFB9BBC9)),
                    ),
                  ],
                ),
              ),
            ).animate(delay: 180.ms).fadeIn(duration: 220.ms),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: FilledButton.icon(
            onPressed: _publishDraft,
            icon: const Icon(Icons.publish_outlined),
            label: const Text('Publish draft'),
          ),
        ),
      ),
    );
  }

  void _publishDraft() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Draft created. Backend create-listing endpoint can be connected next.',
        ),
      ),
    );
  }
}

class _FieldBlock extends StatelessWidget {
  const _FieldBlock({
    required this.label,
    required this.hint,
    required this.controller,
  });

  final String label;
  final String hint;
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF14141E),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0x33FFFFFF)),
      ),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(labelText: label, hintText: hint),
      ),
    );
  }
}
