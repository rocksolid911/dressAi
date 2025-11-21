import 'package:flutter/material.dart';

class OutfitPlannerScreen extends StatelessWidget {
  const OutfitPlannerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Plan Outfit')),
      body: const Center(child: Text('Outfit Planner - Select items to create outfit')),
    );
  }
}
