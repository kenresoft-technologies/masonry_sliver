import 'package:flutter/material.dart';
import 'package:masonry_sliver/masonry_sliver.dart';

void main() => runApp(const MaterialApp(home: MasonryDemo()));

class MasonryDemo extends StatelessWidget {
  const MasonryDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('masonry_sliver')),
      body: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.all(12),
            sliver: SliverMasonry.builder(
              itemCount: 500,
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              itemBuilder: (context, i) => Card(
                color: Colors.primaries[i % Colors.primaries.length].shade200,
                child: SizedBox(
                  height: 80.0 + (i * 37 % 7) * 30,
                  child: Center(child: Text('Item $i')),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
