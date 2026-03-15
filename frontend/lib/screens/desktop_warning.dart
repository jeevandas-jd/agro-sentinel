import 'package:flutter/material.dart';

class DesktopWarning extends StatelessWidget {
  const DesktopWarning({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Container(
          padding: const EdgeInsets.all(24),
          margin: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(Icons.phone_android, size: 60),
              SizedBox(height: 20),
              Text(
                "Mobile Prototype",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 12),
              Text(
                "Hey! This is a PWA prototype.\n\n"
                "If you're opening it on a desktop browser, "
                "please resize the window to a mobile screen size "
                "to access the prototype.",
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
