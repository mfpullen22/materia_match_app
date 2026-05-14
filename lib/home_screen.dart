import "package:flutter/material.dart";
import "package:forui/forui.dart";
import "package:materia_match_app/widgets/custom_button.dart";
import "package:flutter_neumorphic_plus/flutter_neumorphic.dart";

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.sizeOf(context);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Image.asset(
            "assets/img/logo_bgless.png",
            height: 360,
            fit: BoxFit.contain,
          ),
        ),
        CustomButton(
          label: "Report a Match",
          onPress: () {},
          color: Colors.indigoAccent,
        ),
        SizedBox(height: 10),
        SizedBox(
          width: screenSize.width * 0.8,
          height: (screenSize.height * 0.065).clamp(48.0, 60.0),
          child: FButton(onPress: () {}, child: const Text("View Event Data")),
        ),
        SizedBox(height: 10),
        SizedBox(
          width: screenSize.width * 0.8,
          height: (screenSize.height * 0.065).clamp(48.0, 60.0),
          child: FButton(onPress: () {}, child: const Text("Team Reports")),
        ),
        SizedBox(height: 10),
        SizedBox(
          width: screenSize.width * 0.8,
          height: (screenSize.height * 0.065).clamp(48.0, 60.0),
          child: FButton(
            onPress: () {},
            child: const Text("Join or Switch Team"),
          ),
        ),
        SizedBox(height: 10),
        SizedBox(
          width: screenSize.width * 0.8,
          height: (screenSize.height * 0.065).clamp(48.0, 60.0),
          child: FButton(onPress: () {}, child: const Text("My Profile")),
        ),
        SizedBox(height: 10),
        SizedBox(
          width: screenSize.width * 0.8,
          height: (screenSize.height * 0.065).clamp(48.0, 60.0),
          child: NeumorphicButton(
            onPressed: () {},
            style: NeumorphicStyle(
              color: Colors.lightBlueAccent,
              depth: 4,
              intensity: 0.8,
              shape: NeumorphicShape.flat,
              boxShape: NeumorphicBoxShape.roundRect(BorderRadius.circular(24)),
            ),
            child: const Center(
              child: Text("Logout", style: TextStyle(color: Colors.black)),
            ),
          ),
        ),
      ],
    );
  }
}
