import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pet_health_ai/main.dart';
import 'package:provider/provider.dart';
import 'package:pet_health_ai/models/pet.dart';
import 'package:pet_health_ai/models/app_state.dart';

void _showOfflineMsg(BuildContext ctx) =>
  ScaffoldMessenger.of(ctx).showSnackBar(
    const SnackBar(
      content: Text('Connect to the internet to make changes.'),
    ),
  );


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
    final online = context.read<ConnectivityService>().isOnline;
    final theme = Theme.of(context);
    var appState = context.watch<MyAppState>();

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(widget.pet.name, style: TextStyle(fontWeight: FontWeight.w500),),
        actions: [
          GestureDetector(
            onTap: () => _showPetSelectionDialog(context, appState),
            child: CircleAvatar(
              backgroundColor: Colors.grey[300],
              radius: 20,
              foregroundImage: (online && appState.selectedPet.imageUrl != null)
                ? NetworkImage(appState.selectedPet.imageUrl!)
                : null,
              child: (!online || appState.selectedPet.imageUrl == null)
                ? Image.asset("assets/images/sigmalogo.png", fit: BoxFit.contain)
                : null,
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
            child: Row(
              children: [
                SizedBox(height: 400, width:20),
                Column(
                  children: [
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(foregroundColor: theme.primaryColor, backgroundColor:theme.secondaryHeaderColor),
                      onPressed: () => appState.changeIndex(2), 
                      child: Text("Feed ${appState.selectedPet.name}", style:TextStyle(fontSize: 16)),
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

                            String formattedTime = log["time"];
                            try {
                              final dateTime = DateFormat("HH:mm").parse(log["time"]);
                              formattedTime = DateFormat("h:mm a").format(dateTime); // ➜ 3:57 PM
                            } catch (_) {
                              formattedTime = log["time"]; // fallback if parsing fails
                            }
                            return GestureDetector(
                              onTap: () => showProductDialog(context, 
                                                            log["barcode"],
                                                            log["amount"], 
                                                            appState,
                                                            productName : log['productName'],
                                                            nutrition : log["nutrition"] == null
                                                                ? null
                                                                : Map<String, double>.from(log["nutrition"])),
                              child: Card(
                                margin: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                elevation: 4,
                                child: Padding(
                                  padding: const EdgeInsets.all(10.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Center(
                                        child: Text(
                                          formattedTime,
                                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                      SizedBox(height: 6),
                                      RichText(
                                        text: TextSpan(
                                          children: [
                                            TextSpan(
                                              text: "Product: ",
                                              style: TextStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.black, // Label color
                                              ),
                                            ),
                                            TextSpan(
                                              text: "${log["productName"]}",
                                              style: TextStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.w500,
                                                color: theme.primaryColor, // Highlighted color
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      SizedBox(height: 4),
                                      RichText(
                                        text: TextSpan(
                                          children: [
                                            TextSpan(
                                              text: "Amount: ",
                                              style: TextStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.black,
                                              ),
                                            ),
                                            TextSpan(
                                              text: "${log["amount"]}",
                                              style: TextStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.w500,
                                                color: theme.colorScheme.secondary, // A distinct color for value
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
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
                      onPressed: online ? ()  {
                        if (!context.read<ConnectivityService>().isOnline) {
                          _showOfflineMsg(context);
                          return;
                        }
                        _showExerciseLogDialog(context, widget.pet, appState);
                        } : () => _showOfflineMsg(context), 
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

                            String formattedTime = log["time"];
                            try {
                              final dateTime = DateFormat("HH:mm").parse(log["time"]);
                              formattedTime = DateFormat("h:mm a").format(dateTime); // ➜ 3:57 PM
                            } catch (_) {
                              formattedTime = log["time"]; // fallback if parsing fails
                            }
                            return Card(
                              margin: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              elevation: 4,
                              child: Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Center(
                                      child: Text(
                                        formattedTime,
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                    SizedBox(height: 8),
                                    Center(
                                      child: Text(
                                        "${(log["minutes"] as num).toInt()} min ${log["exerciseType"]?.toLowerCase() ?? 'exercise'}",
                                        style: TextStyle(
                                          fontSize: 17,
                                          fontWeight: FontWeight.w600,
                                          color: theme.primaryColor,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                    SizedBox(height: 6),
                                    Text(
                                      "🔥 Calories Burned: N/A",
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.grey[600], // subtle tone to show it's pending
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
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
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 15,),
            )
          ),
          // SliverToBoxAdapter(
          //   child: Row(
          //     mainAxisAlignment: MainAxisAlignment.center,
          //     children: [
          //       ProgressPictureCard(date: '03-20-25', imageUrl: "assets/images/sigmalogo.png"),
          //       ProgressPictureCard(date: '03-20-25', imageUrl: "assets/images/sigmalogo.png"),
          //       ProgressPictureCard(date: '03-20-25', imageUrl: "assets/images/sigmalogo.png")
          //     ],
          //   ),
          // ),
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
                  backgroundColor: Colors.grey[300],
                  foregroundImage: pet.imageUrl != null 
                    ? NetworkImage(pet.imageUrl!)
                    : null,
                  child: pet.imageUrl == null
                    ? Image.asset("assets/images/sigmalogo.png", fit: BoxFit.contain)
                    : null
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
                if (!context.read<ConnectivityService>().isOnline) {
                  _showOfflineMsg(context);
                  return;
                }
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
  final online = context.read<ConnectivityService>().isOnline;
  if (!online) {
    _showOfflineMsg(context);  
    return Future.value();                   
  }
  var appState = context.read<MyAppState>();
  ScrollController scrollController = ScrollController();
  TextEditingController barcodeController = TextEditingController();
  List<String> unitOptions = ["Grams", "Cups", "Ounces"];
  TextEditingController amountController = TextEditingController();
  TextEditingController foodNameController = TextEditingController();
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
              controller: scrollController,
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
                            controller: barcodeController,
                            keyboardType: TextInputType.text,
                            decoration: InputDecoration(labelText: "Enter Barcode"),
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
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: TextField(
                            controller: amountController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(labelText: "Enter Amount"),
                          ),
                        ),
                        if (foodData == null && appState.barcodeNotFound)...[
                          Column(
                            children: [
                              SizedBox(height: 10),
                              ElevatedButton(
                                onPressed: online ? () {
                                  final barcode = barcodeController.text.trim(); 
                                  appState.startManualPhotoFlow(barcode);
                                  appState.barcodeNotFound = false;
                                  Navigator.pop(context);
                                } : () => _showOfflineMsg(context), 
                                child: Text("Take Pictures of Food Package")
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
                                    SizedBox(height: 10),
                                    Text("Food Found:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                    const SizedBox(height: 6),
                                    RichText(
                                      text: TextSpan(
                                        style: TextStyle(fontSize: 14, color: Colors.black),
                                        children: [
                                          TextSpan(text: 'Product Name: ', style: TextStyle(fontWeight: FontWeight.w600)),
                                          TextSpan(
                                            text: '${foodData!['productName']}',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: Colors.indigo[700], // ✅ More contrast than grey
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    RichText(
                                      text: TextSpan(
                                        style: TextStyle(fontSize: 14, color: Colors.black),
                                        children: [
                                          TextSpan(text: 'Brand: ', style: TextStyle(fontWeight: FontWeight.w600)),
                                          TextSpan(
                                            text: '${foodData!['brandName']}',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: Colors.indigo[700],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),


                                    const SizedBox(height: 10),
                                    Text("Nutritional Info:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                    const SizedBox(height: 4),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8),
                                      decoration: BoxDecoration(
                                        color: Colors.grey[100],
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          for (var entry in foodData!['nutritionalInfo'].entries)
                                            Padding(
                                              padding: const EdgeInsets.symmetric(vertical: 2),
                                              child: Text("${entry.key}: ${entry.value}g"),
                                            ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.blueAccent,
                                        foregroundColor: Colors.white,
                                      ),
                                      onPressed: online ? () {
                                        if (!context.read<ConnectivityService>().isOnline) {
                                          _showOfflineMsg(context);
                                          return;
                                        }
                                        if ((mode == 0) && foodData != null) {
                                          appState.updatePetIntake(pet, foodData!['nutritionalInfo'], foodData!['barcode'], foodData!['productName'], "${foodData!['amount']} $unitChosen");
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
                                          appState.updatePetIntake(pet, updatedValues, "No Barcode", "No Name", "$amount $unitChosen");
                                          appState.barcodeNotFound = false;
                                          setState(() {}); // Refresh UI
                                          Navigator.pop(context);
                                        }
                                      } : () => _showOfflineMsg(context),
                                      child: Text("Add Food"),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                        ],
                      ]
                    )
                  // ✅ Manual Entry UI (Fixed ListView inside AlertDialog)
                  else if (mode == 2)
                    Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: TextField(
                            controller: foodNameController,
                            decoration: const InputDecoration(labelText: "Food Name"),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: TextField(
                            controller: amountController,
                            keyboardType: TextInputType.text,
                            decoration: InputDecoration(labelText: "Enter Amount"),
                          ),
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
                onPressed: online ? () async {
                  if (!context.read<ConnectivityService>().isOnline) {
                    _showOfflineMsg(context);
                    return;
                  }
                  FocusScope.of(context).unfocus();
                  if (mode == 0){
                    String? barcode = barcodeController.text;
                    if (barcode.isEmpty) {
                      print("❌ Error: Barcode missing");
                      return;
                    }
                    final amount = double.tryParse(amountController.text);
                    if (amount == null || amount <= 0) {
                      print("❌ Error: Invalid amount entered");
                      return;
                    }
                    if (unitChosen == null || amountController.text.isEmpty) {
                      print("❌ Error: Unit or amount missing");
                      return;
                    }
                    appState.barcodeNotFound = false;
                    foodData = await appState.getFoodIntakeFromBarcode(barcode, unitChosen!, amount);
                    print("barcodeNotFound status: ${appState.barcodeNotFound}");
                    setState(() {});

                    await Future.delayed(Duration(milliseconds: 100)); // give UI a frame to build
                    scrollController.animateTo(
                      scrollController.position.maxScrollExtent,
                      duration: Duration(milliseconds: 400),
                      curve: Curves.easeOut,
                    );
                  }
                  else if (mode == 2){
                    final Map<String, double> manualNutrition = {};
                    manualControllers.forEach((key, ctrl) {
                      final val = double.tryParse(ctrl.text.trim());
                      if (val != null && val > 0) {
                        // convert to the nearest integer
                        manualNutrition[key] = val.round().toDouble();
                      }
                    });
                    final foodName = foodNameController.text.trim();
                    if (foodName.isEmpty) {
                      print("❌ Error: Please enter a food name");
                      return;
                    }
                    final amountText = amountController.text.trim();   // ← keep as text
                    if (amountText.isEmpty) {
                      print("❌ Error: Please enter an amount");
                      return;
                    }
                    appState.updatePetIntake(
                      pet,
                      manualNutrition,
                      "MANUAL_ENTRY",          // barcode placeholder
                      foodName,          // product name placeholder
                      amountText,
                    );
                    Navigator.pop(context);
                  }
                } : () => _showOfflineMsg(context),
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

Future<void> showProductDialog(BuildContext context, 
    String barcode, 
    String amount, 
    MyAppState appState,
    {String? productName, Map<String, double>? nutrition,}
  ) async {
    final online = context.read<ConnectivityService>().isOnline;
    final bool isManual = barcode == "MANUAL_ENTRY";

    if (!isManual) {
      await appState.fetchBarcodeData(barcode);
      if (!context.mounted) return;
    }

    if (!context.mounted) return;

    final scanned = appState.scannedFoodData;
    final String prodName  = isManual
      ? (productName ?? "Manual Entry")
      : (scanned["productName"] ?? "Unknown Product");
    final String brandName = isManual
      ? "Manual Entry"
      : (scanned["brandName"] ?? "Unknown Brand");
    final Map<String,double> nutritionalInfo = isManual
      ? (nutrition ?? <String,double>{})
      : (scanned["nutritionalInfo"] as Map<String,double>? ?? {});
    final guaranteedAnalysis = isManual
      ? <String,double>{}
      : ((scanned["guaranteedAnalysis"] as Map<String,dynamic>? ) ?? {})
          .map((k,v)=>MapEntry(k,(v as num?)?.toDouble() ?? 0.0));

    bool isFavorite = !isManual &&
      appState.selectedPet.favoriteFoods!
          .any((food) => food["barcode"] == barcode);
    final bool staticIsFavorite = isFavorite;
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
                        text: '$prodName\n', // First line with the product name
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
                  if (!isManual)
                    IconButton(
                      icon: Icon(
                        isFavorite ? Icons.star : Icons.star_border,
                        color: Colors.amber,
                        size: 50, // Gold color for the star
                      ),
                      onPressed: online ? ()  {
                        setDialogState(() {
                          isFavorite = !isFavorite; // Toggle UI state
                        });
                      } : () => _showOfflineMsg(context),
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
                    if (!online) {
                      Navigator.pop(context);
                      return;
                    }
                    setDialogState(() {
                      isProcessing = true; // Start processing
                    });

                    if (isFavorite!=staticIsFavorite && !isManual){
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