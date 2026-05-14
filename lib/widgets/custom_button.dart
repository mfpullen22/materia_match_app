import "package:flutter/material.dart";
import "package:forui/forui.dart";

class CustomButton extends StatelessWidget {
  const CustomButton({
    required this.label,
    required this.onPress,
    required this.color,
    super.key,
  });

  final String label;
  final VoidCallback onPress;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.sizeOf(context);

    return SizedBox(
      width: screenSize.width * 0.8,
      height: (screenSize.height * 0.065).clamp(48.0, 60.0),
      child: FButton(
        style: context.theme.buttonStyles.primary.md.copyWith(
          decoration: FVariants.all(
            BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        onPress: onPress,
        child: Text(label),
      ),
    );
  }
}
