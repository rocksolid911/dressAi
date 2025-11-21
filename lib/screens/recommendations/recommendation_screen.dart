// dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../bloc/recommendation/recommendation_bloc.dart';
import '../../bloc/recommendation/recommendation_event.dart';
import '../../bloc/recommendation/recommendation_state.dart';

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
    final bloc = BlocProvider.of<RecommendationBloc>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Recommendations'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              // Clear error or refresh UI
              bloc.add(const ClearRecommendationError());
              bloc.add(const ClearRecommendations());
              bloc.add(const ClearShoppingRecommendations());
            },
            tooltip: 'Clear / refresh',
          ),
        ],
      ),
      body: BlocBuilder<RecommendationBloc, RecommendationState>(
        builder: (context, state) {
          if (state is RecommendationLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          String? error;
          List recommendations = [];
          var weather;
          List shopping = [];

          if (state is RecommendationError) {
            error = state.message;
          } else if (state is RecommendationLoaded) {
            recommendations = state.recommendations ?? [];
            weather = state.currentWeather;
            shopping = state.shoppingRecommendations ?? [];
          }

          return RefreshIndicator(
            onRefresh: () async {
              // Conservative: clear lists and errors
              bloc.add(const ClearRecommendations());
              bloc.add(const ClearShoppingRecommendations());
              bloc.add(const ClearRecommendationError());
            },
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (weather != null)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          const Icon(Icons.wb_sunny),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              '${weather.condition} · ${weather.temperature}°',
                              style: const TextStyle(fontSize: 16),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.info_outline),
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                    content: Text(
                                        'Weather: ${weather.condition}, ${weather.temperature}°')),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),

                if (error != null)
                  Card(
                    color: Colors.red.shade50,
                    child: ListTile(
                      leading: const Icon(Icons.error, color: Colors.red),
                      title: Text(error, style: const TextStyle(color: Colors.red)),
                      trailing: IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () => bloc.add(const ClearRecommendationError()),
                      ),
                    ),
                  ),

                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Outfit Recommendations (${recommendations.length})',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                      TextButton(
                        onPressed: () => bloc.add(const ClearRecommendations()),
                        child: const Text('Clear'),
                      ),
                    ],
                  ),
                ),

                if (recommendations.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(child: Text('No recommendations yet.')),
                  )
                else
                  ...List.generate(recommendations.length, (index) {
                    final rec = recommendations[index];
                    final explanation = (rec.explanation ?? 'No explanation available');

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: CircleAvatar(child: Text('${index + 1}')),
                        title: Text('Recommendation ${index + 1}',
                            style: const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Text(explanation),
                        isThreeLine: true,
                        trailing: PopupMenuButton<String>(
                          onSelected: (value) async {
                            if (value == 'copy') {
                              await Clipboard.setData(ClipboardData(text: explanation));
                              ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Copied')));
                            } else if (value == 'shopping') {
                              // Request shopping recs for a selected clothing item if available
                              if (rec.items != null && rec.items.isNotEmpty) {
                                // dispatch event for first item as example
                                bloc.add(GetShoppingRecommendationsForItem(rec.items.first));
                              }
                            } else if (value == 'saveLog') {
                              // Placeholder: liking requires a log id. Use UI affordance elsewhere.
                              ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Saved locally (demo)')));
                            }
                          },
                          itemBuilder: (_) => const [
                            PopupMenuItem(value: 'copy', child: Text('Copy')),
                            PopupMenuItem(value: 'shopping', child: Text('Get shopping recs')),
                            PopupMenuItem(value: 'saveLog', child: Text('Save (demo)')),
                          ],
                        ),
                      ),
                    );
                  }),

                const SizedBox(height: 8),

                Card(
                  child: ListTile(
                    leading: const Icon(Icons.shopping_bag),
                    title: Text('Shopping recommendations (${shopping.length})'),
                    trailing: TextButton(
                      child: const Text('View'),
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (_) {
                            return AlertDialog(
                              title: const Text('Shopping Recommendations'),
                              content: SizedBox(
                                width: double.maxFinite,
                                child: shopping.isEmpty
                                    ? const Text('No shopping recommendations')
                                    : ListView.separated(
                                  shrinkWrap: true,
                                  itemCount: shopping.length,
                                  separatorBuilder: (_, __) => const Divider(),
                                  itemBuilder: (_, i) {
                                    final item = shopping[i];
                                    return ListTile(
                                      title: Text(item.toString()),
                                      onTap: () {
                                        // Track affiliate click if item provides id/provider
                                        if (item.productId != null && item.provider != null) {
                                          bloc.add(TrackAffiliateClick(productId: item.productId, provider: item.provider));
                                        }
                                        Navigator.of(context).pop();
                                      },
                                    );
                                  },
                                ),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.of(context).pop(),
                                  child: const Text('Close'),
                                )
                              ],
                            );
                          },
                        );
                      },
                    ),
                  ),
                ),

                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }
}
