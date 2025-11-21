import 'package:flutter/material.dart';

class OutfitCalendarScreen extends StatelessWidget {
  const OutfitCalendarScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Outfit Calendar')),
      body: const Center(child: Text('Calendar view for scheduling outfits')),
    );
  }
}
