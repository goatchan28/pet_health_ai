import 'package:flutter/material.dart';
import 'package:pet_health_ai/main.dart';
import 'package:pet_health_ai/models/app_state.dart';
import 'package:pet_health_ai/pages/home_page.dart';
import 'package:provider/provider.dart';

void _showOfflineMsg(BuildContext ctx) =>
  ScaffoldMessenger.of(ctx).showSnackBar(
    const SnackBar(
      content: Text('Connect to the internet to make changes.'),
    ),
  );

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
    return Consumer<MyAppState>(
      builder: (context, appState, child){
        List<Map<String, dynamic>>? foodList = appState.selectedPet.favoriteFoods;
        return Scaffold(
          body: foodList!.isEmpty
          ? const Center(child: Text("No favorite foods yet."))
          : ListView.builder(
              itemCount: foodList.length,
              itemBuilder: (context, index) {
                final food = foodList[index];
                return FavoriteItem(
                  food: food,
                  appState: appState,
                );
              },
            ),
          );
        }
      );
    }
  }

class FavoriteItem extends StatelessWidget {
  final Map<String, dynamic> food;
  final MyAppState appState;

  const FavoriteItem({
    super.key, required this.food, required this.appState,
  });

  @override
  Widget build(BuildContext context) {
    final online = context.read<ConnectivityService>().isOnline;

    final double thumbW = (MediaQuery.sizeOf(context).width * 0.15)
        .clamp(48.0, 90.0);
    final double thumbH = thumbW * 1.9;
    
    String productName = food["productName"] ?? "Unknown Product";
    String brandName = food["brandName"] ?? "Unknown Brand";
    String barcode = food["barcode"] ?? "N/A";
    String imageUrl = food["frontImage"] ?? ""; // If you plan to store images\

    return GestureDetector(
      onTap: online ? (){
        showFeedDialog(context, appState.selectedPet, selectedProductName: productName);
      } : () => _showOfflineMsg(context),
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        child: ListTile(
          leading: imageUrl.isNotEmpty && online
              ? Image.network(imageUrl, width: thumbW, height: thumbH, fit: BoxFit.cover)
              : Icon(Icons.rice_bowl, size: thumbW, color: Colors.grey), // Placeholder image,
          isThreeLine: true,
          dense: true,
          title: Text(productName, style: TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(brandName, style: const TextStyle(color: Colors.grey)),
              const SizedBox(height: 5),
              Text("Barcode: $barcode", style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic)),
              const SizedBox(height: 5),
            ],
          ),
          trailing: IconButton(
            icon: Icon(Icons.star, color: Colors.amber),
            onPressed: () async {
              if (!context.read<ConnectivityService>().isOnline) {
                _showOfflineMsg(context);
                return;
              }
              await appState.selectedPet.changeFavorites(barcode, appState);
            },
          ),
        )
      ),
    );
  }
}

class RecommendedFoodView extends StatelessWidget {
  const RecommendedFoodView({super.key});

  @override
  Widget build(BuildContext context) {
    final textScaler = MediaQuery.maybeOf(context)?.textScaler 
                        ?? TextScaler.noScaling; // returns a TextScaler
    final double fontSize = textScaler
        .scale(26)               // scales 26 logical pixels
        .clamp(18.0, 32.0);      // keep within bounds
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: Text(
            "Recommended Foods Section in Progress", 
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w500
            ),
            textAlign: TextAlign.center,
          )
        ),
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
    final width   = MediaQuery.sizeOf(context).width;
    final double cardW = (width * 0.38).clamp(120.0, 180.0);
    final double cardH = cardW * 1.25;          // preserve feel of 140 × 180
    final double imgH  = cardH * 0.45;          // ≈ 80 px of the original

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
            height: cardH, // Adjust the height as needed
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Container(
                    width: cardW, // Adjust width as needed
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
                            width: cardW,
                            height: imgH,
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
