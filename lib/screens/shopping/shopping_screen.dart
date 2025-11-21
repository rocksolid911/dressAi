import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../bloc/wardrobe/wardrobe_bloc.dart';
import '../../bloc/wardrobe/wardrobe_state.dart';
import '../../bloc/recommendation/recommendation_bloc.dart';
import '../../bloc/recommendation/recommendation_event.dart';
import '../../bloc/recommendation/recommendation_state.dart';

class ShoppingScreen extends StatefulWidget {
  const ShoppingScreen({super.key});

  @override
  State<ShoppingScreen> createState() => _ShoppingScreenState();
}

class _ShoppingScreenState extends State<ShoppingScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedOccasion = 'casual';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadWardrobeGapRecommendations();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _loadWardrobeGapRecommendations() {
    final wardrobeState = context.read<WardrobeBloc>().state;
    if (wardrobeState is WardrobeLoaded) {
      context.read<RecommendationBloc>().add(
            GetWardrobeGapRecommendations(wardrobeState.items),
          );
    }
  }

  void _loadOccasionRecommendations() {
    final wardrobeState = context.read<WardrobeBloc>().state;
    if (wardrobeState is WardrobeLoaded) {
      context.read<RecommendationBloc>().add(
            GetOccasionShoppingRecommendations(
              occasion: _selectedOccasion,
              wardrobe: wardrobeState.items,
            ),
          );
    }
  }

  Future<void> _openAffiliateLink(String url, String productId) async {
    // Track affiliate click
    context.read<RecommendationBloc>().add(
          TrackAffiliateClick(
            productId: productId,
            provider: 'affiliate',
          ),
        );

    // Open link
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open link')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Shopping Recommendations'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Wardrobe Gaps', icon: Icon(Icons.add_shopping_cart)),
            Tab(text: 'By Occasion', icon: Icon(Icons.event)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildWardrobeGapsTab(),
          _buildOccasionTab(),
        ],
      ),
    );
  }

  Widget _buildWardrobeGapsTab() {
    return BlocBuilder<RecommendationBloc, RecommendationState>(
      builder: (context, state) {
        if (state is RecommendationLoading) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Analyzing your wardrobe...'),
              ],
            ),
          );
        }

        if (state is RecommendationError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline,
                      size: 64, color: Colors.red.shade400),
                  const SizedBox(height: 16),
                  Text(
                    'Error',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    state.message,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _loadWardrobeGapRecommendations,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Try Again'),
                  ),
                ],
              ),
            ),
          );
        }

        if (state is RecommendationLoaded &&
            state.shoppingRecommendations.isNotEmpty) {
          return RefreshIndicator(
            onRefresh: () async {
              _loadWardrobeGapRecommendations();
              await Future.delayed(const Duration(seconds: 1));
            },
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  color: Colors.blue.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        Icon(Icons.lightbulb,
                            color: Colors.blue.shade700, size: 32),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Based on your wardrobe, we recommend these items to complete your collection',
                            style: TextStyle(
                              color: Colors.blue.shade900,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                ...state.shoppingRecommendations.map(
                  (item) => _buildShoppingCard(item),
                ),
              ],
            ),
          );
        }

        return Center(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.shopping_bag_outlined,
                    size: 64, color: Colors.grey.shade400),
                const SizedBox(height: 16),
                Text(
                  'No Recommendations Yet',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Add some items to your wardrobe to get personalized shopping recommendations',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _loadWardrobeGapRecommendations,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Refresh'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildOccasionTab() {
    return BlocBuilder<RecommendationBloc, RecommendationState>(
      builder: (context, state) {
        return Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.grey.shade100,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Select Occasion',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      'casual',
                      'formal',
                      'work',
                      'party',
                      'sport',
                      'wedding',
                      'beach',
                      'date',
                    ].map((occasion) {
                      final isSelected = _selectedOccasion == occasion;
                      return ChoiceChip(
                        label: Text(occasion.toUpperCase()),
                        selected: isSelected,
                        onSelected: (selected) {
                          if (selected) {
                            setState(() => _selectedOccasion = occasion);
                            _loadOccasionRecommendations();
                          }
                        },
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _buildOccasionContent(state),
            ),
          ],
        );
      },
    );
  }

  Widget _buildOccasionContent(RecommendationState state) {
    if (state is RecommendationLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Finding perfect items...'),
          ],
        ),
      );
    }

    if (state is RecommendationError) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline,
                  size: 64, color: Colors.red.shade400),
              const SizedBox(height: 16),
              Text(
                'Error',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                state.message,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _loadOccasionRecommendations,
                icon: const Icon(Icons.refresh),
                label: const Text('Try Again'),
              ),
            ],
          ),
        ),
      );
    }

    if (state is RecommendationLoaded &&
        state.shoppingRecommendations.isNotEmpty) {
      return RefreshIndicator(
        onRefresh: () async {
          _loadOccasionRecommendations();
          await Future.delayed(const Duration(seconds: 1));
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              color: Colors.green.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Icon(Icons.celebration,
                        color: Colors.green.shade700, size: 32),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Perfect items for ${_selectedOccasion} occasions',
                        style: TextStyle(
                          color: Colors.green.shade900,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            ...state.shoppingRecommendations.map(
              (item) => _buildShoppingCard(item),
            ),
          ],
        ),
      );
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.shopping_bag_outlined,
                size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'Select an Occasion',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            const Text(
              'Choose an occasion above to get shopping recommendations',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShoppingCard(item) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 16 / 9,
            child: item.imageUrl.isNotEmpty
                ? Image.network(
                    item.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey.shade200,
                        child: Center(
                          child: Icon(Icons.image_not_supported,
                              size: 48, color: Colors.grey.shade400),
                        ),
                      );
                    },
                  )
                : Container(
                    color: Colors.grey.shade200,
                    child: Center(
                      child: Icon(Icons.checkroom,
                          size: 48, color: Colors.grey.shade400),
                    ),
                  ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                if (item.description.isNotEmpty)
                  Text(
                    item.description,
                    style: TextStyle(
                      color: Colors.grey.shade700,
                      fontSize: 14,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (item.price > 0)
                      Text(
                        '\$${item.price.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.green.shade700,
                        ),
                      ),
                    ElevatedButton.icon(
                      onPressed: () => _openAffiliateLink(
                        item.affiliateLink,
                        item.id,
                      ),
                      icon: const Icon(Icons.shopping_cart, size: 20),
                      label: const Text('Shop Now'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (item.provider.isNotEmpty)
                  Row(
                    children: [
                      Icon(Icons.store,
                          size: 16, color: Colors.grey.shade600),
                      const SizedBox(width: 4),
                      Text(
                        item.provider,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
