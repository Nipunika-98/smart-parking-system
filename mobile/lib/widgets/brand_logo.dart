import 'package:flutter/material.dart';

class BrandLogo extends StatelessWidget {
  final double size;
  final bool withShadow;

  const BrandLogo({super.key, this.size = 80.0, this.withShadow = true});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: ClipOval(
        child: Transform.scale(
          scale: 1.8, // Zoom in to explicitly crop out the white square border baked into the image
          child: Image.asset(
            'assets/images/logo.png',
            width: size,
            height: size,
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }
}
