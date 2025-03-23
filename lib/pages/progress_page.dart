import 'package:flutter/material.dart';
import 'package:pet_health_ai/models/app_state.dart';
import 'package:pet_health_ai/models/pet.dart';
import 'package:pet_health_ai/widgets/charts.dart';
import 'package:pet_health_ai/widgets/progress_pic.dart';
import 'package:provider/provider.dart';

class ProgressTrackerPage extends StatefulWidget {
  final Pet pet;

  const ProgressTrackerPage({required this.pet, super.key});

  @override
  State<ProgressTrackerPage> createState() => _ProgressTrackerPageState();
}

class _ProgressTrackerPageState extends State<ProgressTrackerPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
              child: SizedBox(height: 60),
            ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: WeeklyNutrientGraph(width: double.infinity, height: 273, pet: widget.pet)
            ),
          ),
          SliverToBoxAdapter(
              child: SizedBox(height: 21),
            ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: LineChartSample1(width: double.infinity,height: 273, pet: widget.pet),
              // child: ClipRRect(
              //   borderRadius: BorderRadius.circular(10),
              //   child: Container(
              //      height:273,
              //     color: theme.colorScheme.primary,
              //   ),
              // ),
            ),
          ),
          SliverToBoxAdapter(
            child: Column(
              children: [
                SizedBox(height: 20,),
                Center(
                  child: ElevatedButton(
                    onPressed: () => showVetVisitDialog(context, widget.pet),
                    child: Text("Record Vet Visit")
                  ),
                ),
              ],
            )
          ),
          SliverToBoxAdapter(
              child: SizedBox(height: 20),
            ),
          SliverToBoxAdapter(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ProgressPictureCard(date: '03-20-25', imageUrl: "assets/sigmalogo.png"),
                  ProgressPictureCard(date: '03-20-25', imageUrl: "assets/sigmalogo.png"),
                  ProgressPictureCard(date: '03-20-25', imageUrl: "assets/sigmalogo.png")
                ],
              ),
            ),
        ],
      ),
    );
  }
}

Future<void> showVetVisitDialog(BuildContext context, Pet pet) async {
  var appState = context.read<MyAppState>();
  Map<String, TextEditingController> controllers = {
    "Date": TextEditingController(),
    "Weight": TextEditingController(),
    "Height": TextEditingController(),
    "BCS": TextEditingController(),
    "Age": TextEditingController(),
    "Notes": TextEditingController(text: "Enter Any Notes"),
  };

  Map<String, String?> errors = {
    "Date": null,
    "Weight": null,
    "Height": null,
    "BCS":null,
    "Age": null,
    "Notes": null,
  };

  void validateAndSubmit() {
    errors.updateAll((key, value) => null); // Reset errors

    String date = controllers["Date"]!.text.trim();
    double? weight = double.tryParse(controllers["Weight"]!.text); 
    double? height = double.tryParse(controllers["Height"]!.text); 
    double? bcs = double.tryParse(controllers["BCS"]!.text);  
    double? age = double.tryParse(controllers["Age"]!.text);  
    String notes = controllers["Notes"]!.text.trim();

    bool hasErrors = false;

    if (date.isEmpty) {
      errors["Date"] = "Enter a valid date.";
      hasErrors = true;
    }
    if (weight == null || weight <= 0) { // Ensure valid weight
      errors["Weight"] = "Enter a valid weight (kg).";
      hasErrors = true;
    }
    if (height == null || height <= 0) { // Ensure valid weight
      errors["Height"] = "Enter a valid height (in).";
      hasErrors = true;
    }
    if (bcs == null || bcs <= 0 || bcs > 9) { // Ensure valid weight
      errors["BCS"] = "Enter a valid BCS.";
      hasErrors = true;
    }
    if (age == null || age <= 0) { // Ensure valid age
      errors["Age"] = "Enter a valid age (months).";
      hasErrors = true;
    }

    if (hasErrors) {
      (context as Element).markNeedsBuild(); // Refresh UI to show errors
      return;
    }

    pet.recordVetVisit(date:date, weight: weight!, height: height!, bcs: bcs!, age: age!, notes: notes, appState: appState);
    Navigator.pop(context);
  }

  await showDialog(
    context: context, 
    builder: (context) {
      return AlertDialog(
        title: Text("Vet Visit"),
        content: SizedBox(
          width: double.maxFinite,
          height:500,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("Record ${pet.name} 's Vet Visit", style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(
                height: 480,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: controllers.length,
                  itemBuilder: (context, index) {
                    String key = controllers.keys.elementAt(index);
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 5),
                      child: TextField(
                        controller: controllers[key],
                        keyboardType: (key.contains("Date") || key.contains("Notes"))
                            ? TextInputType.text
                            : TextInputType.number,
                        decoration: InputDecoration(
                          labelText: key,
                          errorText: errors[key], // Shows error message if invalid
                        ),
                      )
                    );
                  }
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
            onPressed: () {
              validateAndSubmit();
            },
            child: Text("Enter"),
          )  
        ],
      );
    },
  );
} 

