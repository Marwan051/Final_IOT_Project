import 'package:flutter/material.dart';

class HomeScreenWidget extends StatelessWidget {
  const HomeScreenWidget({
    super.key,
    required this.location,
    required this.title,
    required this.icon,
  });

  final String location;
  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(context, location);
      },
      child: Container(
        width: 100, // Adjust the size as needed
        height: 100, // Adjust the size as needed
        decoration: BoxDecoration(
          color: Colors.blue, // Adjust the color as needed
          borderRadius:
              BorderRadius.circular(8), // Adjust the border radius as needed
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 48, // Adjust the icon size as needed
              color: Colors.white, // Adjust the icon color as needed
            ),
            const SizedBox(height: 8), // Space between icon and text
            Text(
              title,
              style: const TextStyle(
                color: Colors.white, // Adjust the text color as needed
                fontSize: 16, // Adjust the text size as needed
              ),
            ),
          ],
        ),
      ),
    );
  }
}
