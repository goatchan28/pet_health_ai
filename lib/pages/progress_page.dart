import 'package:flutter/material.dart';

class ProgressTrackerPage extends StatelessWidget {
  const ProgressTrackerPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
              child: SizedBox(height: 60),
            ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Container(
                   height:273,
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
              child: SizedBox(height: 21),
            ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Container(
                   height:273,
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
              child: SizedBox(height: 20),
            ),
          SliverToBoxAdapter(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      height:200,
                      width: (MediaQuery.of(context).size.width)/3-20,
                      color: Colors.orange,
                    ),
                  ),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      height:200,
                      width: (MediaQuery.of(context).size.width)/3-20,
                      color: Colors.orange,
                    ),
                  ),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      height:200,
                      width: (MediaQuery.of(context).size.width)/3-20,
                      color: Colors.orange,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}