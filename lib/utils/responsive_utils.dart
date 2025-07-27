import 'package:flutter/material.dart';

/// Helper function to get responsive max width based on screen constraints
double getResponsiveMaxWidth(BoxConstraints constraints) {
  if (constraints.maxWidth < 600) {
    return double.infinity; // Mobile: full width
  } else if (constraints.maxWidth < 1200) {
    return 700; // Tablet
  } else {
    return 800; // Desktop
  }
}

/// Helper function to get responsive max width for auth forms
double getAuthFormMaxWidth(BoxConstraints constraints) {
  return constraints.maxWidth < 600 ? double.infinity : 500;
}

/// Wrapper widget for responsive layout using native Flutter widgets
Widget buildResponsiveLayout({
  required Widget child,
  required BoxConstraints constraints,
  bool isAuthForm = false,
  EdgeInsets padding = const EdgeInsets.all(16.0),
}) {
  final maxWidth = isAuthForm 
    ? getAuthFormMaxWidth(constraints)
    : getResponsiveMaxWidth(constraints);

  return Center(
    child: ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: Padding(
        padding: padding,
        child: child,
      ),
    ),
  );
}
