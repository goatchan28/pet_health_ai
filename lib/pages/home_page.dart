import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pet_health_ai/models/pet.dart';
import 'package:pet_health_ai/models/app_state.dart';

class HomePage extends StatefulWidget {
  final Pet pet;

  const HomePage({super.key, required this.pet}); 
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late PageController _pageController;
  int currentPageHome = 0; // ✅ Move currentPageHome to state

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: currentPageHome);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

@override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    var appState = context.watch<MyAppState>();

    return Scaffold(
      appBar: AppBar(
        title: Center(
          child: Text(widget.pet.name),
        ),
        actions: [
          GestureDetector(
            onTap: () => _showPetSelectionDialog(context, appState),
            child: CircleAvatar(
              backgroundImage: AssetImage("assets/sigmalogo.png"),
              radius: 20,
            ),
          ),
          SizedBox(height: 10),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  height: 400,
                  color: theme.colorScheme.primaryFixedDim,
                  child: Stack(
                    children: [
                      PageView(
                        key: ValueKey(appState.selectedPet.name),
                        controller: _pageController,
                        onPageChanged: (index) {
                          setState(() {
                            currentPageHome = index; // ✅ Update state when page changes
                          });
                        },
                        children: [
                          MacrosView(pet: widget.pet),
                          BoneHealthView(pet: widget.pet),
                          VitaminsMineralsView(pet: widget.pet),
                        ],
                      ),
                      Positioned(
                        bottom: 10,
                        left: 0,
                        right: 0,
                        child: Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(3, (index) {
                              return Container(
                                margin: EdgeInsets.symmetric(horizontal: 5),
                                width: currentPageHome == index ? 12 : 8,
                                height: currentPageHome == index ? 12 : 8,
                                decoration: BoxDecoration(
                                  color: currentPageHome == index ? Colors.black : Colors.grey,
                                  shape: BoxShape.circle,
                                ),
                              );
                            }),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Column(
              children: [
                Center(
                  child: ElevatedButton(
                    onPressed: () =>_showFeedDialog(context, widget.pet),
                    child: Text("Feed ${widget.pet.name}"),
                  ),
                ),
                SizedBox(height: 20),
              ],
            ),
          ),
          SliverToBoxAdapter(
            child: Row(
              children: [
                SizedBox(height: 400, width:20),
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    height:400,
                    width: (MediaQuery.of(context).size.width-50)/2,
                    color: theme.colorScheme.onPrimary,
                  ),
                ),
                SizedBox(height: 400, width:10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    height:400,
                    width: (MediaQuery.of(context).size.width-50)/2,
                    color: theme.colorScheme.onPrimary,
                  ),
                ),
                SizedBox(height: 400, width:20),
              ],
            ),
          ),
          SliverToBoxAdapter(
            child: Column(
              children: [
                SizedBox(height:20),
                Center(
                  child: ElevatedButton(
                    onPressed: () {
                      appState.changeIndex(1);
                    },
                    child: Text('Progress Tracking'),
                  ),
                ),
                SizedBox(height:20),
              ],
            ),
          ),
          SliverToBoxAdapter(
            child: Row(
              children: [
                SizedBox(height: 160, width:8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    height:160,
                    width: (MediaQuery.of(context).size.width)/2-10.5,
                    color: theme.colorScheme.primary,
                  ),
                ),
                SizedBox(height: 160, width:5),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    height:160,
                    width: (MediaQuery.of(context).size.width)/2-10.5,
                    color: theme.colorScheme.primary,
                  ),
                ),
                SizedBox(height: 160, width:8),
              ],
            ),
          ),
          SliverToBoxAdapter(
            child: Center(
              child: Column(
                children: [
                  SizedBox(height: 20,),
                  Text("Buddy's Progress"),
                  SizedBox(height: 10,)
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Row(
              children: [
                SizedBox(height: 200, width:16),
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    height:200,
                    width: (MediaQuery.of(context).size.width)/3-20,
                    color: Colors.orange,
                  ),
                ),
                SizedBox(height: 200, width:14),
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    height:200,
                    width: (MediaQuery.of(context).size.width)/3-20,
                    color: Colors.orange,
                  ),
                ),
                SizedBox(height: 200, width:14),
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    height:200,
                    width: (MediaQuery.of(context).size.width)/3-20,
                    color: Colors.orange,
                  ),
                ),
                SizedBox(height: 200, width:16),
              ],
            ),
          ),
        ],
      )
    );
  }

  void _showPetSelectionDialog(BuildContext context, MyAppState appState) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Select a Pet"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: appState.pets.asMap().entries.map((entry) {
              int index = entry.key;
              Pet pet = entry.value;
              return ListTile(
                leading: CircleAvatar(
                  backgroundImage: AssetImage("assets/sigmalogo.png"),
                ),
                title: Text(pet.name),
                onTap: () {
                  if (index == appState.petIndex){
                    Navigator.pop(context);
                    return;
                  }
                  appState.selectPet(index);
                  setState(() {
                    currentPageHome = 0; // ✅ Reset page index when selecting a new pet
                  });
                  Navigator.pop(context);
                },
              );
            }).toList(),
          ),
        );
      },
    );
  }
}

void _showFeedDialog(BuildContext context, Pet pet) {
  var appState = context.read<MyAppState>();
  TextEditingController barcodeController = TextEditingController();
  Map<String, TextEditingController> manualControllers = {};
  int mode = 0;

  manualControllers["Calories"] = TextEditingController(text: "0");

  pet.nutritionalRequirements.forEach((key, value) {
    manualControllers[key] = TextEditingController(text: "0"); // Initialize to 0
  });

  showDialog(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text("Feed ${pet.name}"),
            content: SingleChildScrollView( // ✅ Prevents Overflow Errors
              child: ConstrainedBox( // ✅ Ensures proper layout constraints
                constraints: BoxConstraints(maxHeight: 600), // ✅ Limits overall height
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // ✅ Toggle Barcode vs Manual Input
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        TextButton(
                          onPressed: () => setState(() => mode = 0),
                          child: Text(
                            "Barcode Scan",
                            style: TextStyle(
                              fontWeight: mode == 0 ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () => setState(() => mode = 2),
                          child: Text(
                            "Manual Entry",
                            style: TextStyle(
                              fontWeight: mode == 2 ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ),
                      ],
                    ),
                    
                    Divider(),

                    // ✅ Barcode Entry UI
                    if (mode == 0)
                      Column(
                        children: [
                          TextField(
                            controller: barcodeController,
                            keyboardType: TextInputType.text,
                            decoration: InputDecoration(labelText: "Enter Barcode"),
                            onSubmitted: (barcode) async {
                              await appState.fetchBarcodeData(barcode);
                              print("barcodeNotFound status: ${appState.barcodeNotFound}");
                              setState(() {});
                            },
                          ),
                          if (appState.scannedFoodData.isNotEmpty)
                            Column(
                              children: [
                                SizedBox(height: 10),
                                  Column(
                                    children: [
                                      Text("Food Found:", style: TextStyle(fontWeight: FontWeight.bold)),
                                      for (var entry in appState.scannedFoodData.entries)
                                        Text("${entry.key}: ${entry.value}g"),
                                    ],
                                  ),
                                ],
                              ),
                          if (appState.barcodeNotFound)
                            Column(
                              children: [
                                SizedBox(height: 10),
                                ElevatedButton(
                                  onPressed: () => setState(() => mode = 1), 
                                  child: Text("Scan Nutrition Label")
                                )
                              ],
                            ),
                          ],
                        )
                    // ✅ Nutrition Label Scan UI    
                    else if (mode == 1)
                      Column(
                        children: [
                          ElevatedButton(
                            onPressed: () {appState.changeIndex(2); appState.barcodeNotFound = false; Navigator.pop(context);}, 
                            child: Text("Go To Camera")
                          )
                        ],
                      )
                    // ✅ Manual Entry UI (Fixed ListView inside AlertDialog)
                    else if (mode == 2)
                      Column(
                        children: [
                          Text(
                            "Enter Nutrients and Calories",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          SizedBox(
                            height: 500, // ✅ FIXED: Defined height to prevent errors
                            child: SingleChildScrollView(
                              child: Column(
                                children: manualControllers.keys.map((key) {
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 5),
                                    child: TextField(
                                      controller: manualControllers[key],
                                      keyboardType: TextInputType.number,
                                      decoration: InputDecoration(labelText: key),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  appState.scannedFoodData = {}; // ✅ Reset scanned food data
                  appState.barcodeNotFound = false;
                  Navigator.pop(context);
                },
                child: Text("Cancel"),
              ),
              ElevatedButton(
                onPressed: () {
                  if ((mode == 0) && appState.scannedFoodData.isNotEmpty) {
                    appState.updatePetIntake(pet, appState.scannedFoodData);
                    appState.barcodeNotFound = false;
                    setState(() {}); // Refresh UI
                    Navigator.pop(context);
                  } 
                  else if (mode == 2) {
                    Map<String, double> updatedValues = {};
                    manualControllers.forEach((key, controller) {
                      double? value = double.tryParse(controller.text);
                      if (value != null) {
                        updatedValues[key] = value;
                      }
                    });
                    appState.updatePetIntake(pet, updatedValues);
                    appState.barcodeNotFound = false;
                    setState(() {}); // Refresh UI
                    Navigator.pop(context);
                  }
                },
                child: Text("Add Food"),
              ),
            ],
          );
        },
      );
    },
  );
}

class MacrosView extends StatelessWidget {
  final Pet pet;

  const MacrosView({super.key, required this.pet});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text("Calories Progress", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          SizedBox(height: 10),
          Text("Calories Required: ${pet.calorieRequirement.toInt()}"),
          Text("Calories Eaten: ${pet.calorieIntake.toInt()}"),
          SizedBox(height: 30),
          SizedBox(
            width: 313,
            height: 55,
            child: LinearProgressIndicator(value: pet.calorieIntake / pet.calorieRequirement),
          ),
          SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildNutrientProgress("Protein", pet.nutritionalIntake["Crude Protein"]?.toDouble() ?? 0, pet.nutritionalRequirements["Crude Protein"]?.toDouble() ?? 1, Colors.purple),
              _buildNutrientProgress("Carbs", pet.nutritionalIntake["Carbohydrates"]?.toDouble() ?? 0, pet.nutritionalRequirements["Carbohydrates"]?.toDouble() ?? 1, Colors.red),
              _buildNutrientProgress("Fat", pet.nutritionalIntake["Crude Fat"]?.toDouble() ?? 0, pet.nutritionalRequirements["Crude Fat"]?.toDouble() ?? 1, Colors.yellow),
            ],
          ),
        ],
      ),
    );
  }
}


class BoneHealthView extends StatelessWidget {
  final Pet pet;

  const BoneHealthView({super.key, required this.pet});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Stack(
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text("Bone, Muscle, and Joint Health", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              GridView.count(
                shrinkWrap: true,
                crossAxisCount: 3,
                children: [
                  _buildNutrientProgress("Calcium", pet.nutritionalIntake["Calcium"]?.toDouble() ?? 0, pet.nutritionalRequirements["Calcium"]?.toDouble() ?? 1, Colors.brown),
                  _buildNutrientProgress("Phosphorus", pet.nutritionalIntake["Phosphorus"]?.toDouble() ?? 0, pet.nutritionalRequirements["Phosphorus"]?.toDouble() ?? 1, Colors.blue),
                  _buildNutrientProgress("Magnesium", pet.nutritionalIntake["Magnesium"]?.toDouble() ?? 0, pet.nutritionalRequirements["Magnesium"]?.toDouble() ?? 1, Colors.orange),
                  _buildNutrientProgress("Potassium", pet.nutritionalIntake["Potassium"]?.toDouble() ?? 0, pet.nutritionalRequirements["Potassium"]?.toDouble() ?? 1, Colors.yellow),
                  _buildNutrientProgress("Sodium", pet.nutritionalIntake["Sodium"]?.toDouble() ?? 0, pet.nutritionalRequirements["Sodium"]?.toDouble() ?? 1, Colors.red),
                  _buildNutrientProgress("Chloride", pet.nutritionalIntake["Chloride"]?.toDouble() ?? 0, pet.nutritionalRequirements["Chloride"]?.toDouble() ?? 1, Colors.teal),
                ],
              ),
            ],
          ),
          Align(
            alignment: Alignment.bottomRight, 
            child: TextButton(
              onPressed: () => _showMoreNutrientsPage(context, pet), 
              child: Text("More Nutrients", style: TextStyle(color: Colors.blue))
            )
          )
        ]
      ),
    );
  }
}

class VitaminsMineralsView extends StatelessWidget {
  final Pet pet;

  const VitaminsMineralsView({super.key, required this.pet});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Stack(
        children: [Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("Vitamins and Minerals", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 10),
            GridView.count(
              shrinkWrap: true,
              crossAxisCount: 3,
              children: [
                _buildNutrientProgress("Iron", pet.nutritionalIntake["Iron"]?.toDouble() ?? 0, pet.nutritionalRequirements["Iron"]?.toDouble() ?? 1, Colors.blueGrey),
                _buildNutrientProgress("Zinc", pet.nutritionalIntake["Zinc"]?.toDouble() ?? 0, pet.nutritionalRequirements["Zinc"]?.toDouble() ?? 1, Colors.purple),
                _buildNutrientProgress("Vitamin A", pet.nutritionalIntake["Vitamin A"]?.toDouble() ?? 0, pet.nutritionalRequirements["Vitamin A"]?.toDouble() ?? 1, Colors.brown),
                _buildNutrientProgress("Vitamin D", pet.nutritionalIntake["Vitamin D"]?.toDouble() ?? 0, pet.nutritionalRequirements["Vitamin D"]?.toDouble() ?? 1, Colors.yellow),
                _buildNutrientProgress("Vitamin E", pet.nutritionalIntake["Vitamin E"]?.toDouble() ?? 0, pet.nutritionalRequirements["Vitamin E"]?.toDouble() ?? 1, Colors.pink),
                _buildNutrientProgress("Choline", pet.nutritionalIntake["Choline"]?.toDouble() ?? 0, pet.nutritionalRequirements["Choline"]?.toDouble() ?? 1, Colors.teal),
              ],
            ),
          ],
        ),
        Align(
            alignment: Alignment.bottomRight, 
            child: TextButton(
              onPressed: () => _showMoreNutrientsPage(context, pet), 
              child: Text("More Nutrients", style: TextStyle(color: Colors.blue))
            )
          )
        ]
      ),
    );
  }
}

Widget _buildNutrientProgress(String label, double current, double total, Color color) {
  // ✅ Prevent division by zero
  double progress = (total > 0) ? current / total : 0.0;

  // ✅ Ensure values display correctly
  String formattedCurrent;
  String formattedTotal;

  if (current > 1) {
    formattedCurrent = current.toStringAsFixed(0); // Show whole numbers
  } else if (current > 0.01) {
    formattedCurrent = current.toStringAsFixed(2); // Show two decimals
  } else if (current > 0) {
    formattedCurrent = current.toStringAsPrecision(2); // Show smallest nonzero value
  } else {
    formattedCurrent = "0"; // Show zero properly
  }

  if (total > 1) {
    formattedTotal = total.toStringAsFixed(0);
  } else {
    formattedTotal = total.toStringAsFixed(2);
  }

  return Column(
    children: [
      SizedBox(
        width: 80,
        height: 80,
        child: Stack(
          fit: StackFit.expand,
          children: [
            CircularProgressIndicator(
              value: progress.isFinite ? progress : 0.0, // ✅ Avoid NaN/Infinity
              strokeWidth: 6,
              backgroundColor: Colors.grey.shade300,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
            Center(
              child: Text("$formattedCurrent/$formattedTotal", 
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
      SizedBox(height: 5),
      Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
    ],
  );
}

void _showMoreNutrientsPage(BuildContext context, Pet pet){

  showDialog(
    context: context, 
    builder: (context){
      return AlertDialog(
        title: Text("All Nutrient Info"),
        content: SizedBox(
          width: double.maxFinite,
          height: 500,
          child: Column(
            children: [
              Expanded(
                child: ListView.builder(
                  itemCount: pet.nutritionalRequirements.length,
                  itemBuilder: (context, index){
                    String nutrient = pet.nutritionalRequirements.keys.elementAt(index);
                    double intake = pet.nutritionalIntake[nutrient] ?? 0;
                    double requirement = pet.nutritionalRequirements[nutrient] ?? 0;
                    
                    return Padding(
                      padding: EdgeInsets.symmetric(vertical: 4),
                      child: ListTile(
                        title: Text(
                          nutrient, 
                          style: TextStyle(fontWeight: FontWeight.bold)
                        ),
                        subtitle: Text(
                          "Intake: ${intake.toStringAsFixed(2)} / Requirement: ${requirement.toStringAsFixed(2)}"
                        ),
                      )
                    );
                  },
                )
              ),
              SizedBox(height:10),
              ElevatedButton(
                onPressed: () => Navigator.pop(context), 
                child: Text("Close"),
              )
            ],
          )
        )
      );
    }
  );
}