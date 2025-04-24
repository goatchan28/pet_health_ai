import 'package:flutter/material.dart';
import 'package:pet_health_ai/widgets/progress_pic.dart';
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
              backgroundImage: AssetImage("assets/images/sigmalogo.png"),
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
                    onPressed: () =>showFeedDialog(context, widget.pet),
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
                Column(
                  children: [
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(foregroundColor: theme.primaryColor, backgroundColor:theme.secondaryHeaderColor),
                      onPressed: () {showMealLogDialog(context, appState.selectedPet, appState);}, 
                      child: Text("Meal Log", style:TextStyle(fontSize: 16))
                    ),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        height:400,
                        width: (MediaQuery.of(context).size.width-50)/2,
                        color: theme.colorScheme.onPrimary,
                        child: widget.pet.mealLog!.isNotEmpty 
                        ? ListView.builder(
                          itemCount: widget.pet.mealLog!.length,
                          itemBuilder: (context, index){
                            List<Map<String, dynamic>> sortedLogs = List.from(widget.pet.mealLog!);
                            sortedLogs = sortedLogs.reversed.toList();
                            final log = sortedLogs[index];
                            return GestureDetector(
                              onTap: () => showProductDialog(context, log["barcode"],log["amount"], appState),
                              child: Card(
                                margin: EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                                elevation: 3,
                                child: Padding(
                                  padding: const EdgeInsets.all(10.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "🕒 Time: ${log["date_time"]}",
                                        style: TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                      Text("🏃 Barcode: ${log["barcode"]}"),
                                      Text("Amount: ${log["amount"]}")
                                    ],
                                  ),
                                ),
                                
                              ),
                            );
                          }
                        ) : Center(child: Text("No meals logged yet")),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 400, width:10),
                Column(
                  children: [
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(foregroundColor: theme.primaryColor, backgroundColor: theme.secondaryHeaderColor),
                      onPressed: ()  => _showExerciseLogDialog(context, widget.pet, appState), 
                      child: Text("Log Exercise", style:TextStyle(fontSize: 16))
                    ),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        height:400,
                        width: (MediaQuery.of(context).size.width-50)/2,
                        color: theme.colorScheme.onPrimary,
                        child: widget.pet.exerciseLog!.isNotEmpty 
                        ? ListView.builder(
                          itemCount: widget.pet.exerciseLog!.length,
                          itemBuilder: (context, index){
                            List<Map<String, dynamic>> sortedLogs = List.from(widget.pet.exerciseLog!);
                            sortedLogs = sortedLogs.reversed.toList();
                            final log = sortedLogs[index];
                            return Card(
                              margin: EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                              elevation: 3,
                              child: Padding(
                                padding: const EdgeInsets.all(10.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "🕒 Time: ${log["date_time"]}",
                                      style: TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                    Text("🏃 Exercise: ${log["exerciseType"]}"),
                                    Text("⏳ Minutes: ${log["minutes"]} min"),
                                    Text("🔥 Calories Burned: ${log["caloriesBurnt"]} kcal"),
                                  ],
                                ),
                              ),
                            );
                          }
                        ) : Center(child: Text("No exercise logged yet")),
                      ),
                    ),
                  ],
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
                    child: Text('Buddy\'s Progress'),
                  ),
                ),
                SizedBox(height:20),
              ],
            ),
          ),
          SliverToBoxAdapter(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ProgressPictureCard(date: '03-20-25', imageUrl: "assets/images/sigmalogo.png"),
                ProgressPictureCard(date: '03-20-25', imageUrl: "assets/images/sigmalogo.png"),
                ProgressPictureCard(date: '03-20-25', imageUrl: "assets/images/sigmalogo.png")
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
                  backgroundImage: AssetImage("assets/images/sigmalogo.png"),
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

  void _showExerciseLogDialog(BuildContext context, Pet pet, MyAppState appState){
    TextEditingController minutes = TextEditingController(text: "0");
    String? selectedExerciseType;
    List<String> exerciseOptions = ["Walk", "Run", "Fetch"];
    
    showDialog(context: context, builder: (context){
      return AlertDialog(
        title: Text("Log Exercise"),
        content: SizedBox(
          width: double.maxFinite,
          height:160,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("Record ${pet.name}'s Workout", style: TextStyle(fontSize: 16,fontWeight: FontWeight.bold)),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: DropdownButtonFormField<String>(
                  value: selectedExerciseType,
                  decoration: InputDecoration(
                    labelText: "Exercise Type",
                    border: OutlineInputBorder(),
                  ),
                  items: exerciseOptions.map((exercise) {
                    return DropdownMenuItem<String>(
                      value: exercise,
                      child: Text(exercise),
                  );
                  }).toList(),
                  onChanged: (String? newValue){
                    selectedExerciseType = newValue;
                  }
                )
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: TextField(
                  controller: minutes,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: "Minutes",
                  ),
                )
              )
            ],
          )
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); 
            },
            child: Text("Cancel"),
          ),
          ElevatedButton(
             onPressed: ()
              {
              double minutesVal = double.tryParse(minutes.text) ?? 0;
              if (selectedExerciseType == null || selectedExerciseType!.isEmpty) {
                print("❌ Please select an exercise type!");
                return;
              }
               pet.logExercise(exerciseType: selectedExerciseType!, minutes: minutesVal, appState: appState);
              Navigator.pop(context);
            },
            child: Text("Enter"),
          )  
        ],
      );
    });
  }
}

Future<void> showFeedDialog(BuildContext context, Pet pet, {String? selectedProductName, String? selectedProductBarcode}) {
  var appState = context.read<MyAppState>();
  TextEditingController barcodeController = TextEditingController();
  List<String> unitOptions = ["Grams", "Cups", "Ounces"];
  TextEditingController amountController = TextEditingController();
  String? unitChosen;
  String? favoriteChosen = selectedProductName;
  Map<String, TextEditingController> manualControllers = {};
  int mode = 0;
  Map<String, dynamic>? foodData;
  List favoriteProductNames = pet.favoriteFoods!.map((food) => food["productName"] ?? "Unknown Product").toList();
  favoriteProductNames.add("None");
  manualControllers["Calories"] = TextEditingController(text: "0");

  pet.nutritionalRequirements.forEach((key, value) {
    manualControllers[key] = TextEditingController(text: "0"); // Initialize to 0
  });

  if (selectedProductName != null) {
    var selectedFood = pet.favoriteFoods!.firstWhere(
      (food) => food["productName"] == selectedProductName,
      orElse: () => {},
    );
    barcodeController.text = selectedFood["barcode"] ?? "";
  }
  else if (selectedProductBarcode != null){
    barcodeController.text = selectedProductBarcode;
  }

  return showDialog(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text("Feed ${pet.name}"),
            content: SingleChildScrollView( // ✅ Prevents Overflow Errors
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
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 5),
                          child: DropdownButtonFormField<String>(
                            value: unitChosen,
                            decoration: InputDecoration(
                              labelText: "Choose Unit",
                              border: OutlineInputBorder(),
                            ),
                            items: unitOptions.map((unit) {
                              return DropdownMenuItem<String>(
                                value: unit,
                                child: Text(unit),
                            );
                            }).toList(),
                            onChanged: (String? newValue){
                              unitChosen = newValue;
                            }
                          )
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 5),
                          child: DropdownButtonFormField<String>(
                            value: favoriteChosen,
                            decoration: InputDecoration(
                              labelText: "Choose Favorite Food",
                              border: OutlineInputBorder(),
                            ),
                            items: favoriteProductNames.map((productName) {
                              return DropdownMenuItem<String>(
                                value: productName,
                                child: SizedBox(
                                  width: 225,
                                  child: Text(productName, overflow: TextOverflow.ellipsis,)
                                ),
                            );
                            }).toList(),
                            onChanged: (String? newValue){
                              setState(() {
                                favoriteChosen = newValue;
                                // ✅ Find the barcode corresponding to the selected favorite food
                                var selectedFood = pet.favoriteFoods!.firstWhere(
                                  (food) => food["productName"] == newValue,
                                  orElse: () => {},
                                );
                                barcodeController.text = selectedFood["barcode"] ?? "";
                              });
                            }
                          )
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: TextField(
                            controller: amountController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(labelText: "Enter Amount"),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: TextField(
                            controller: barcodeController,
                            keyboardType: TextInputType.text,
                            decoration: InputDecoration(labelText: "Enter Barcode"),
                          ),
                        ),
                        if (foodData == null && appState.barcodeNotFound)...[
                          Column(
                            children: [
                              SizedBox(height: 10),
                              ElevatedButton(
                                onPressed: () => setState(() => mode = 1), 
                                child: Text("Scan Nutrition Label")
                              )
                            ],
                          ),
                        ]
                        else if (foodData != null && !appState.barcodeNotFound) ...[
                          Column(
                            children: [
                              SizedBox(height: 10),
                                Column(
                                  children: [
                                    Text("Food Found:", style: TextStyle(fontWeight: FontWeight.bold)),
                                    Text("Product Name: ${foodData!['productName']}"),
                                    Text("Brand: ${foodData!['brandName']}"),
                                    for (var entry in foodData!['nutritionalInfo'].entries)
                                      Text("${entry.key}: ${entry.value}g"),
                                    ElevatedButton(
                                      onPressed: () {
                                        if ((mode == 0) && foodData != null) {
                                          appState.updatePetIntake(pet, foodData!['nutritionalInfo'], foodData!['barcode'], "${foodData!['amount']} $unitChosen");
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
                                          double? amount = double.tryParse(amountController.text);
                                          if (amount == null || amount <= 0) {
                                            print("❌ Error: Invalid amount entered");
                                            return;
                                          }
                                          else if (unitChosen == null){
                                            print("❌ Error: No unit chosen");
                                            return;
                                          }
                                          appState.updatePetIntake(pet, updatedValues, "No Barcode", "$amount $unitChosen");
                                          appState.barcodeNotFound = false;
                                          setState(() {}); // Refresh UI
                                          Navigator.pop(context);
                                        }
                                      },
                                      child: Text("Add Food"),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                        ],
                      ]
                      )
                  // ✅ Nutrition Label Scan UI    
                  else if (mode == 1)
                    Column(
                      children: [
                        ElevatedButton(
                          onPressed: () {appState.changeIndex(2); appState.barcodeNotFound = false; Navigator.pop(context);}, 
                          child: Text("Go To Camera")
                        ),
                      ],
                    )
                  // ✅ Manual Entry UI (Fixed ListView inside AlertDialog)
                  else if (mode == 2)
                    Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: TextField(
                            controller: amountController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(labelText: "Enter Amount"),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 5),
                          child: DropdownButtonFormField<String>(
                            value: unitChosen,
                            decoration: InputDecoration(
                              labelText: "Choose Unit",
                              border: OutlineInputBorder(),
                            ),
                            items: unitOptions.map((unit) {
                              return DropdownMenuItem<String>(
                                value: unit,
                                child: Text(unit),
                            );
                            }).toList(),
                            onChanged: (String? newValue){
                              unitChosen = newValue;
                            }
                          )
                        ),
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
                onPressed: () async {
                  FocusScope.of(context).unfocus();
                  String? barcode = barcodeController.text;
                  double? amount = double.tryParse(amountController.text);
                  if (unitChosen == null || amountController.text.isEmpty) {
                    print("❌ Error: Unit or amount missing");
                    return;
                  }
                  if (amount == null || amount <= 0) {
                    print("❌ Error: Invalid amount entered");
                    return;
                  }
                  if (unitChosen == null || barcode.isEmpty) {
                    print("❌ Error: Unit or barcode missing");
                    return;
                  }
                  appState.barcodeNotFound = false;
                  foodData = await appState.getFoodIntakeFromBarcode(barcode, unitChosen!, amount);
                  print("barcodeNotFound status: ${appState.barcodeNotFound}");
                  setState(() {});
                },
                child: Text("Submit"),
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

void showMealLogDialog(BuildContext context, Pet pet, MyAppState appState){
  List<Map<String, dynamic>>? mealLog = pet.mealLog;
  if (mealLog == null || mealLog.isEmpty) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Meal Log"),
        content: Text("No meals logged."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Close"),
          ),
        ],
      ),
    );
    return;
  }

  List<Map<String, dynamic>> reversedMealLog = List.from(mealLog.reversed);

  showDialog(
    context: context, 
    builder: (context){
      return AlertDialog(
        title: Text("Meal Log"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: reversedMealLog.map((meal) {
              return FutureBuilder<void>(
                future: () async {
                  appState.scannedFoodData = {};
                  appState.barcodeNotFound = false;

                  await appState.fetchBarcodeData(meal["barcode"]);

                  return appState.scannedFoodData.isNotEmpty
                      ? Map<String, dynamic>.from(appState.scannedFoodData)
                      : null;
                }(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Card(
                      margin: EdgeInsets.symmetric(vertical: 8),
                      child: ListTile(
                        title: Text("Fetching data..."),
                        subtitle: Text("Barcode: ${meal["barcode"]}"),
                      ),
                    );
                  }

                  if (appState.barcodeNotFound || appState.scannedFoodData.isEmpty) {
                    return Card(
                      margin: EdgeInsets.symmetric(vertical: 8),
                      child: ListTile(
                        title: Text("Product not found"),
                        subtitle: Text("Barcode: ${meal["barcode"]}"),
                      ),
                    );
                  }

                  final Map<String, dynamic> productData = snapshot.data as Map<String, dynamic>;

                  String productName = productData["productName"] as String? ?? "Unknown Product";
                  String brandName = productData["brandName"] as String? ?? "Unknown Brand";

                  return Card(
                    margin: EdgeInsets.symmetric(vertical: 8),
                    child: ListTile(
                      title: Text(productName, style: TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Brand: $brandName"),
                          Text("Time: ${meal["date_time"]}"),
                          Text("Amount: ${meal["amount"]}"),
                          Text("Barcode: ${meal["barcode"]}"),
                        ],
                      ),
                    ),
                  );
                },
              );
            }).toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Close"),
          ),
        ],
      );
    }
  );
}

Future<void> showProductDialog(BuildContext context, String barcode, String amount, MyAppState appState) async {
  await appState.fetchBarcodeData(barcode);

  if (!context.mounted) return;

  final scannedFoodData = appState.scannedFoodData;
  final productName = scannedFoodData["productName"] ?? "Unknown Product";
  final brandName = scannedFoodData["brandName"] ?? "Unknown Brand";
  final nutritionalInfo = scannedFoodData["nutritionalInfo"] as Map<String, double>? ?? {};
  final Map<String, double> guaranteedAnalysis =
      ((scannedFoodData['guaranteedAnalysis'] as Map<String, dynamic>?) ?? {})
          .map((k, v) => MapEntry(k, (v as num?)?.toDouble() ?? 0.0));



  bool isFavorite = appState.selectedPet.favoriteFoods!
      .any((food) => food["barcode"] == barcode);

  bool staticIsFavorite = appState.selectedPet.favoriteFoods!
      .any((food) => food["barcode"] == barcode);
      
  bool isProcessing = false;

  await showDialog(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setDialogState)
        {
          return AlertDialog(
            title: Row(
              children: [
                Flexible(
                  child: Text.rich(
                    TextSpan(
                      text: '$productName\n', // First line with the product name
                      style: TextStyle(fontWeight: FontWeight.bold),
                      children: [
                        TextSpan(
                          text: '($brandName)', // Second line with the brand name
                          style: TextStyle(fontWeight: FontWeight.normal),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(width: 8), // Space between the product name/brand and the star
                IconButton(
                  icon: Icon(
                    isFavorite ? Icons.star : Icons.star_border,
                    color: Colors.amber,
                    size: 50, // Gold color for the star
                  ),
                  onPressed: ()  {
                    setDialogState(() {
                      isFavorite = !isFavorite; // Toggle UI state
                    });
                  },
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Display barcode
                  Text("Barcode: $barcode", style: TextStyle(fontWeight: FontWeight.bold)),
                  SizedBox(height: 8), // Add some space before nutritional info
                  Text("Amount: $amount", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  SizedBox(height: 8),
                  if (nutritionalInfo.isNotEmpty) ...[
                    Text("Nutritional Information (per 100g):", style: TextStyle(fontWeight: FontWeight.bold)),
                    ...nutritionalInfo.entries.map(
                      (e) => Text("${e.key}: ${e.value.toStringAsFixed(2)} g"),
                    ),
                  ] else if (guaranteedAnalysis.isNotEmpty) ...[
                    Text("Guaranteed Analysis:", style: TextStyle(fontWeight: FontWeight.bold)),
                    ...guaranteedAnalysis.entries.map(
                      (e) => Text("${e.key}: ${e.value.toStringAsFixed(2)} %"),
                    ),
                  ] else ...[
                    const Text("No nutritional information available."),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: isProcessing ? null : () async {
                  setDialogState(() {
                    isProcessing = true; // Start processing
                  });

                  if (isFavorite!=staticIsFavorite){
                    await appState.selectedPet.changeFavorites(barcode, appState);
                  }
                  setDialogState(() {
                    isProcessing = false; // Done processing
                  });
                  appState.scannedFoodData = {}; // ✅ Reset scanned food data
                  appState.barcodeNotFound = false;
                  if (!context.mounted) return;
                  Navigator.pop(context);
                },
                child: Text('Close'),
              ),
            ],
          );
        }
      );
    },
  );
}



