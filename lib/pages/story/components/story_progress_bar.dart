import 'package:flutter/material.dart';

class StoryProgressBar extends StatelessWidget {
  final int storyCount;
  final int currentIndex;
  final AnimationController animController;

  const StoryProgressBar({
    Key? key,
    required this.storyCount,
    required this.currentIndex,
    required this.animController,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 40), // Căn chỉnh top
      child: Row(
        children: List.generate(storyCount, (index) {
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: AnimatedBuilder(
                animation: animController,
                builder: (context, child) {
                  return LinearProgressIndicator(
                    // Logic:
                    // - Nếu index < current: đã chạy xong (value = 1)
                    // - Nếu index == current: đang chạy (value = controller.value)
                    // - Nếu index > current: chưa chạy (value = 0)
                    value: index < currentIndex
                        ? 1.0
                        : (index == currentIndex ? animController.value : 0.0),
                    backgroundColor: Colors.white.withOpacity(0.3),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      index <= currentIndex ? Colors.white : Colors.transparent,
                    ),
                    minHeight: 3, // Độ dày thanh
                  );
                },
              ),
            ),
          );
        }),
      ),
    );
  }
}