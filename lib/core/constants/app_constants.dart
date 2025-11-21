class AppConstants {
  // App Info
  static const String appName = 'Digital Wardrobe';
  static const String appVersion = '1.0.0';

  // Collections
  static const String usersCollection = 'users';
  static const String clothingItemsCollection = 'clothing_items';
  static const String outfitsCollection = 'outfits';
  static const String recommendationLogsCollection = 'recommendation_logs';

  // Storage Paths
  static const String clothingImagesPath = 'clothing_images';
  static const String userAvatarsPath = 'user_avatars';

  // Categories
  static const List<String> clothingCategories = [
    'Tops',
    'Bottoms',
    'Dresses',
    'Outerwear',
    'Shoes',
    'Accessories',
    'Traditional',
  ];

  // Subcategories
  static const Map<String, List<String>> subcategoriesMap = {
    'Tops': ['T-Shirt', 'Shirt', 'Blouse', 'Tank Top', 'Sweater', 'Hoodie'],
    'Bottoms': ['Jeans', 'Trousers', 'Shorts', 'Skirt', 'Leggings'],
    'Dresses': ['Casual Dress', 'Formal Dress', 'Evening Gown', 'Sundress'],
    'Outerwear': ['Jacket', 'Coat', 'Blazer', 'Cardigan', 'Raincoat'],
    'Shoes': ['Sneakers', 'Loafers', 'Heels', 'Sandals', 'Boots'],
    'Accessories': ['Belt', 'Bag', 'Hat', 'Scarf', 'Jewelry', 'Watch'],
    'Traditional': ['Saree', 'Kurta', 'Salwar', 'Lehenga', 'Sherwani'],
  };

  // Colors
  static const List<String> clothingColors = [
    'Black',
    'White',
    'Red',
    'Blue',
    'Green',
    'Yellow',
    'Orange',
    'Pink',
    'Purple',
    'Brown',
    'Grey',
    'Beige',
    'Navy',
    'Maroon',
    'Multicolor',
  ];

  // Patterns
  static const List<String> patterns = [
    'Solid',
    'Striped',
    'Checkered',
    'Floral',
    'Polka Dots',
    'Abstract',
    'Printed',
  ];

  // Fabrics
  static const List<String> fabrics = [
    'Cotton',
    'Silk',
    'Polyester',
    'Denim',
    'Linen',
    'Wool',
    'Leather',
    'Chiffon',
    'Velvet',
  ];

  // Seasons
  static const List<String> seasons = [
    'All Season',
    'Summer',
    'Winter',
    'Monsoon',
    'Spring',
    'Autumn',
  ];

  // Occasions
  static const List<String> occasions = [
    'Casual',
    'Office',
    'Formal',
    'Party',
    'Wedding',
    'Date',
    'Sports',
    'Beach',
    'Festival',
    'Interview',
  ];

  // Moods
  static const List<String> moods = [
    'Confident',
    'Cozy',
    'Bold',
    'Minimal',
    'Playful',
    'Elegant',
    'Relaxed',
    'Professional',
    'Romantic',
    'Edgy',
  ];

  // Style Preferences
  static const List<String> stylePreferences = [
    'Casual',
    'Formal',
    'Streetwear',
    'Minimal',
    'Bohemian',
    'Classic',
    'Sporty',
    'Vintage',
    'Ethnic',
    'Trendy',
  ];

  // Gender Preferences
  static const List<String> genderPreferences = [
    'Men\'s Fashion',
    'Women\'s Fashion',
    'Unisex',
    'All Styles',
  ];

  // Sizes
  static const List<String> topSizes = ['XS', 'S', 'M', 'L', 'XL', 'XXL', '3XL'];
  static const List<String> bottomSizes = ['26', '28', '30', '32', '34', '36', '38', '40'];
  static const List<String> shoeSizes = ['5', '6', '7', '8', '9', '10', '11', '12'];

  // Weather Conditions
  static const String weatherSunny = 'Clear';
  static const String weatherCloudy = 'Clouds';
  static const String weatherRain = 'Rain';
  static const String weatherSnow = 'Snow';
  static const String weatherThunderstorm = 'Thunderstorm';

  // Recommendation Types
  static const String recommendationDaily = 'daily';
  static const String recommendationOccasion = 'occasion';
  static const String recommendationMood = 'mood';
  static const String recommendationWeather = 'weather';

  // Analytics Events
  static const String eventSignUp = 'sign_up';
  static const String eventLogin = 'login';
  static const String eventAddItem = 'add_clothing_item';
  static const String eventCreateOutfit = 'create_outfit';
  static const String eventViewRecommendation = 'view_recommendation';
  static const String eventLikeOutfit = 'like_outfit';
  static const String eventClickAffiliate = 'click_affiliate_link';
  static const String eventScreenView = 'screen_view';
}
