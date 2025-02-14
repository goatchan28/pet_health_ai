import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pet_health_ai/models/app_state.dart';

class FoodPage extends StatelessWidget {
  const FoodPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2, // Two tabs: Favorites & Recommended
      child: Scaffold(
        appBar: AppBar(
          title: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.favorite), text: "Favorites"),
              Tab(icon: Icon(Icons.recommend), text: "Recommended"),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            FavoritesFoodView(),
            RecommendedFoodView(),
          ],
        ),
      ),
    );
  }
}

// These are separate widgets for each tab
class FavoritesFoodView extends StatelessWidget {
  const FavoritesFoodView({super.key});

  @override
  Widget build(BuildContext context) {
    var appState = context.watch<MyAppState>();
    
    return Scaffold(
      body: ListView.builder(
        itemCount: appState.favorites.length,
        itemBuilder: (context, index){
          final item = appState.favorites[index];
          return FavoriteItem(
            imageUrl: item["imageUrl"],
            name: item["name"],
            brand: item["brand"],
            rating: item["rating"],
            ratingColor: item["ratingColor"],
          );
        }
      )
    );
  }
}

class FavoriteItem extends StatelessWidget {
  final String imageUrl;
  final String name;
  final String brand;
  final String rating;
  final Color ratingColor;

  const FavoriteItem({
    required this.imageUrl,
    required this.name,
    required this.brand,
    required this.rating,
    required this.ratingColor,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: ListTile(
        leading: Image.network(imageUrl, width: 55, height: 105, fit: BoxFit.cover),
        isThreeLine: true,
        dense: true,
        title: Text(name, style: TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(brand, style: const TextStyle(color: Colors.grey)),
            Row(
              children: [
                Icon(Icons.circle, color: ratingColor, size: 12),
                const SizedBox(width: 5),
                Text(rating, style: const TextStyle(fontSize: 12)),
              ],
            ),
          ],
        ),
        trailing: Icon(Icons.arrow_circle_right),
      )
    );
  }
}

class RecommendedFoodView extends StatelessWidget {
  const RecommendedFoodView({super.key});

  static const List<Map<String, dynamic>> featured = [
    {
      "imageUrl": "https://image.chewy.com/is/image/catalog/48856_MAIN._AC_SL1200_V1723228820_.jpg",
      "title": "Beef Frozen Raw Dog Food",
      "subtitle": "Blue Ridge",
    },
    {
      "imageUrl": "https://image.chewy.com/is/image/catalog/48856_MAIN._AC_SL1200_V1723228820_.jpg",
      "title": "Chicken Raw Dog Food",
      "subtitle": "Farm Fresh",
    },
    {
      "imageUrl": "https://image.chewy.com/is/image/catalog/48856_MAIN._AC_SL1200_V1723228820_.jpg",
      "title": "Salmon Raw Dog Food",
      "subtitle": "Sea Treats",
    },
  ];

  static const List<Map<String, dynamic>> freshFood = [
    {
      "imageUrl": "https://image.chewy.com/is/image/catalog/48856_MAIN._AC_SL1200_V1723228820_.jpg",
      "title": "Fresh Turkey Dog Food",
      "subtitle": "Nature's Variety",
    },
    {
      "imageUrl": "https://image.chewy.com/is/image/catalog/48856_MAIN._AC_SL1200_V1723228820_.jpg",
      "title": "Fresh Beef Dog Food",
      "subtitle": "Farm to Bowl",
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView(
        children: [
          RecommendedSection(title: "Featured", items: featured),
          RecommendedSection(title: 'Fresh Food', items: freshFood)
        ],
      )
    );
  }
}

class RecommendedSection extends StatelessWidget {
  final String title;
  final List<Map<String, dynamic>> items;

  const RecommendedSection({
    required this.title,
    required this.items,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          child: Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.grey.shade200, // Light grey background
            borderRadius: BorderRadius.circular(10),
          ),
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: SizedBox(
            height: 180, // Adjust the height as needed
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Container(
                    width: 140, // Adjust width as needed
                    decoration: BoxDecoration(
                      color: Colors.white, // White background for individual cards
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 4,
                          spreadRadius: 1,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
                          child: Image.network(
                            item["imageUrl"],
                            width: 140,
                            height: 80,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            children: [
                              Text(
                                item["title"],
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                item["subtitle"],
                                style: const TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
