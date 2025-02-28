import 'package:flutter/material.dart';

Container buildStatContainter(
  Size size, {
  required String title,
  required String value,
  required IconData icon,
  required Color color,
  required double widthFactor,
  EdgeInsets? margin, // Optional Margin for the container
  double topSpacing = 15, // Optional top spacing
  double bottomSpacing = 15, // Optional bottom spacing
}) {
  return Container(
    width: size.width,
    margin: margin ?? EdgeInsets.only(top: 50),
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(10),
      boxShadow: [
        BoxShadow(
          color: Colors.black12,
          blurRadius: 10,
          offset: Offset(1, 1),
          spreadRadius: 1,
        ),
      ],
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(height: topSpacing),
        Icon(
          icon,
          size: 60,
          color: Colors.blue,
        ),
        SizedBox(height: 10),
        Text(
          title,
          style: TextStyle(
            fontSize: 25,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 10),
        Text(
          value,
          style: TextStyle(
            fontSize: 32,
            color: Colors.black54,
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: bottomSpacing),
      ],
    ),
  );
}
