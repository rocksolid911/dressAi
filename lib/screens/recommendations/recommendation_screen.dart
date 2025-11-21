import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../bloc/auth/auth_cubit.dart';
import '../../bloc/auth/auth_state.dart';
import '../../bloc/wardrobe/wardrobe_bloc.dart';
import '../../bloc/wardrobe/wardrobe_state.dart';
import '../../bloc/recommendation/recommendation_bloc.dart';
import '../../bloc/recommendation/recommendation_event.dart';
import '../../bloc/recommendation/recommendation_state.dart';
import '../../services/ai_stylist_service.dart';

class RecommendationScreen extends StatefulWidget {
  const RecommendationScreen({super.key});

  @override
  State<RecommendationScreen> createState() => _RecommendationScreenState();
}

class _RecommendationScreenState extends State<RecommendationScreen> {
  final _promptController = TextEditingController();
  String _selectedOccasion = 'casual';
  String? _selectedMood;

  @override
  void dispose() {
    _promptController.dispose();
    super.dispose();
  }

  void _generateDailyRecommendations() {
    final authState = context.read<AuthCubit>().state;
    final wardrobeState = context.read<WardrobeBloc>().state;

    if (authState is AuthAuthenticated && wardrobeState is WardrobeLoaded) {
      context.read<RecommendationBloc>().add(
            GenerateDailyRecommendations(
              userId: authState.user.id,
              wardrobe: wardrobeState.items,
              cityName: authState.user.city,
            ),
          );
    }
  }

  void _generateOccasionRecommendations() {
    final authState = context.read<AuthCubit>().state;
    final wardrobeState = context.read<WardrobeBloc>().state;

    if (authState is AuthAuthenticated && wardrobeState is WardrobeLoaded) {
      context.read<RecommendationBloc>().add(
            GenerateOccasionRecommendations(
              userId: authState.user.id,
              wardrobe: wardrobeState.items,
              occasion: _selectedOccasion,
              mood: _selectedMood,
              cityName: authState.user.city,
            ),
          );
    }
  }

  void _generateFromPrompt() {
    final authState = context.read<AuthCubit>().state;
    final wardrobeState = context.read<WardrobeBloc>().state;

    if (authState is AuthAuthenticated &&
        wardrobeState is WardrobeLoaded &&
        _promptController.text.isNotEmpty) {
      context.read<RecommendationBloc>().add(
            GenerateFromPrompt(
              userId: authState.user.id,
              wardrobe: wardrobeState.items,
              prompt: _promptController.text,
              cityName: authState.user.city,
            ),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Outfit Recommendations'),
        elevation: 0,
      ),
      body: BlocBuilder<RecommendationBloc, RecommendationState>(
        builder: (context, state) {
          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Weather Card
                if (state is RecommendationLoaded && state.currentWeather != null)
                  _buildWeatherCard(state.currentWeather!),

                const SizedBox(height: 16),

                // Quick Actions
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Quick Actions',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: state is RecommendationLoading
                                  ? null
                                  : _generateDailyRecommendations,
                              icon: const Icon(Icons.wb_sunny),
                              label: const Text('Daily Outfit'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: state is RecommendationLoading
                                  ? null
                                  : _generateOccasionRecommendations,
                              icon: const Icon(Icons.event),
                              label: const Text('By Occasion'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Occasion Selector
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Occasion',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: [
                          'casual',
                          'formal',
                          'work',
                          'party',
                          'sport',
                          'date',
                        ].map((occasion) {
                          final isSelected = _selectedOccasion == occasion;
                          return ChoiceChip(
                            label: Text(occasion.toUpperCase()),
                            selected: isSelected,
                            onSelected: (selected) {
                              if (selected) {
                                setState(() => _selectedOccasion = occasion);
                              }
                            },
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Custom Prompt
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Describe What You Need',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _promptController,
                        maxLines: 3,
                        decoration: InputDecoration(
                          hintText:
                              'e.g., "I need a comfortable outfit for a coffee date"',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.send),
                            onPressed: state is RecommendationLoading
                                ? null
                                : _generateFromPrompt,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Loading State
                if (state is RecommendationLoading)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32.0),
                      child: Column(
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 16),
                          Text('Generating recommendations...'),
                        ],
                      ),
                    ),
                  ),

                // Error State
                if (state is RecommendationError)
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Card(
                      color: Colors.red.shade50,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            Icon(Icons.error_outline,
                                size: 48, color: Colors.red.shade700),
                            const SizedBox(height: 8),
                            Text(
                              'Error',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.red.shade700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              state.message,
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                // Recommendations List
                if (state is RecommendationLoaded &&
                    state.recommendations.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Recommended Outfits',
                          style:
                              Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                        const SizedBox(height: 12),
                        ...state.recommendations.map(
                          (recommendation) =>
                              _buildRecommendationCard(recommendation),
                        ),
                      ],
                    ),
                  ),

                // Empty State
                if (state is RecommendationInitial ||
                    (state is RecommendationLoaded &&
                        state.recommendations.isEmpty))
                  Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(Icons.lightbulb_outline,
                              size: 64, color: Colors.grey.shade400),
                          const SizedBox(height: 16),
                          Text(
                            'No Recommendations Yet',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Click on "Daily Outfit" or describe what you need',
                            style: Theme.of(context).textTheme.bodyMedium,
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildWeatherCard(weather) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.blue.shade400,
            Colors.blue.shade600,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Text(
            weather.iconUrl,
            style: const TextStyle(fontSize: 48),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  weather.cityName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${weather.temperature.toStringAsFixed(1)}°C - ${weather.description}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  weather.clothingRecommendation,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendationCard(OutfitRecommendation recommendation) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade100,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.star, size: 16, color: Colors.blue.shade700),
                      const SizedBox(width: 4),
                      Text(
                        '${(recommendation.score * 100).toInt()}%',
                        style: TextStyle(
                          color: Colors.blue.shade700,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Items in this Outfit:',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: recommendation.items.map((item) {
                return Container(
                  height: 100,
                  width: 100,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                    image: item.imageUrl.isNotEmpty
                        ? DecorationImage(
                            image: NetworkImage(item.imageUrl),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: item.imageUrl.isEmpty
                      ? Center(
                          child: Icon(Icons.checkroom,
                              size: 32, color: Colors.grey.shade400),
                        )
                      : null,
                );
              }).toList(),
            ),
            if (recommendation.explanation.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.lightbulb_outline,
                        size: 20, color: Colors.orange.shade700),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        recommendation.explanation,
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
