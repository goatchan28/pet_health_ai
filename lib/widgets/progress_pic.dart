import 'package:flutter/material.dart';

class ProgressPictureCard extends StatelessWidget{
  final String date;
  final String imageUrl;

  const ProgressPictureCard({super.key, required this.date, required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(15))),
      child: Container(
        height:200,
        width: (MediaQuery.of(context).size.width)/3-20,
        color: Colors.orange,
        child: Column(
          children: [
            SizedBox(
              height: 40,
              width: double.infinity,
              child: Center(
                child: Text(
                  date, 
                  style: TextStyle(fontSize: 14, color: Colors.white, fontWeight:FontWeight.bold)
                ),
              ),
            ),
            SizedBox(height: 10,),
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
                child: Image.asset(
                  imageUrl,
                  fit: BoxFit.cover,
                  width: double.infinity,
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}