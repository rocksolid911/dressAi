import 'package:dressai/models/clothing_item_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../bloc/auth/auth_cubit.dart';
import '../../bloc/auth/auth_state.dart';
import '../../bloc/wardrobe/wardrobe_bloc.dart';
import '../../bloc/wardrobe/wardrobe_event.dart';
import '../../bloc/wardrobe/wardrobe_state.dart';
import '../../bloc/recommendation/recommendation_bloc.dart';
import '../../bloc/recommendation/recommendation_event.dart';
import '../../bloc/recommendation/recommendation_state.dart';
import '../../core/theme/app_theme.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final authCubit = context.read<AuthCubit>();
    final wardrobeBloc = context.read<WardrobeBloc>();
    final recommendationBloc = context.read<RecommendationBloc>();

    final user = authCubit.currentUser;
    if (user != null) {
      wardrobeBloc.add(LoadWardrobeItems(user.id));

      // Wait for wardrobe to load before generating recommendations
      await Future.delayed(const Duration(milliseconds: 500));

      if (user.city != null) {
        final wardrobeState = wardrobeBloc.state;
        final List<ClothingItemModel> items = wardrobeState is WardrobeLoaded ? wardrobeState.items : [];

        recommendationBloc.add(GenerateDailyRecommendations(
          userId: user.id,
          wardrobe: items,
          cityName: user.city,
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, authState) {
        final user = authState is AuthAuthenticated ? authState.user : null;

        return Scaffold(
          appBar: AppBar(
            title: Text('Hello, ${user?.name ?? 'User'}!'),
            actions: [
              IconButton(
                icon: const Icon(Icons.person),
                onPressed: () {
                  Navigator.of(context).pushNamed('/profile');
                },
              ),
            ],
          ),
          body: BlocBuilder<RecommendationBloc, RecommendationState>(
            builder: (context, recommendationState) {
              final weather = recommendationState is RecommendationLoaded
                  ? recommendationState.currentWeather
                  : null;
              final recommendations = recommendationState is RecommendationLoaded
                  ? recommendationState.recommendations
                  : [];
              final isLoading = recommendationState is RecommendationLoading;

              return SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Weather Widget
                    if (weather != null)
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Icon(Icons.wb_sunny, size: 48, color: AppTheme.accentColor),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${weather.temperature.round()}°C',
                                      style: Theme.of(context).textTheme.headlineMedium,
                                    ),
                                    Text(
                                      weather.description,
                                      style: Theme.of(context).textTheme.bodyMedium,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    const SizedBox(height: 24),

                    // Daily Recommendations
                    Text(
                      'Today\'s Outfit Suggestions',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 16),

                    if (isLoading)
                      const Center(child: CircularProgressIndicator())
                    else if (recommendations.isEmpty)
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            children: [
                              Icon(Icons.checkroom, size: 64, color: AppTheme.textSecondaryColor),
                              const SizedBox(height: 16),
                              Text(
                                'Add items to your wardrobe to get recommendations!',
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.bodyLarge,
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: () {
                                  Navigator.of(context).pushNamed('/add-item');
                                },
                                child: const Text('Add Your First Item'),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      SizedBox(
                        height: 300,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: recommendations.length,
                          itemBuilder: (context, index) {
                            final recommendation = recommendations[index];
                            return Card(
                              margin: const EdgeInsets.only(right: 16),
                              child: Container(
                                width: 250,
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Outfit ${index + 1}',
                                      style: Theme.of(context).textTheme.titleLarge,
                                    ),
                                    const SizedBox(height: 8),
                                    Expanded(
                                      child: Text(
                                        recommendation.explanation,
                                        style: Theme.of(context).textTheme.bodyMedium,
                                      ),
                                    ),
                                    ElevatedButton(
                                      onPressed: () {},
                                      child: const Text('View Details'),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),

                    const SizedBox(height: 24),

                    // Quick Actions
                    Text(
                      'Quick Actions',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 16),

                    Row(
                      children: [
                        Expanded(
                          child: _QuickActionCard(
                            icon: Icons.add_photo_alternate,
                            label: 'Add Item',
                            onTap: () {
                              Navigator.of(context).pushNamed('/add-item');
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _QuickActionCard(
                            icon: Icons.calendar_today,
                            label: 'Plan Outfit',
                            onTap: () {
                              Navigator.of(context).pushNamed('/outfit-planner');
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: _selectedIndex,
            onTap: (index) {
              setState(() {
                _selectedIndex = index;
              });

              switch (index) {
                case 0:
                  break;
                case 1:
                  Navigator.of(context).pushNamed('/wardrobe');
                  break;
                case 2:
                  Navigator.of(context).pushNamed('/recommendations');
                  break;
                case 3:
                  Navigator.of(context).pushNamed('/shopping');
                  break;
              }
            },
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.home),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.checkroom),
                label: 'Wardrobe',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.lightbulb),
                label: 'Suggestions',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.shopping_bag),
                label: 'Shop',
              ),
            ],
          ),
        );
      },
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Icon(icon, size: 48, color: AppTheme.primaryColor),
              const SizedBox(height: 8),
              Text(
                label,
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
