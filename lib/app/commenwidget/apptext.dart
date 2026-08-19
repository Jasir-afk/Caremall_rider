import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppText extends StatelessWidget {
  final String text;
  final double fontSize;
  final TextAlign textAlign;
  final FontWeight fontWeight;
  final String? fontFamily;
  final Color color;
  final int? maxLines;
  final double? letterspace;
  final TextOverflow? overflow;
  final TextDecoration? textDecoration;

  const AppText({
    super.key,
    required this.text,
    this.fontSize = 14,
    this.textAlign = TextAlign.start,
    this.fontWeight = FontWeight.normal,
    this.color = Colors.black,
    this.fontFamily,
    this.letterspace,
    this.overflow,
    this.textDecoration,
    this.maxLines,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      maxLines: maxLines,
      overflow: overflow ?? TextOverflow.visible,
      textAlign: textAlign,
      style: GoogleFonts.dmSans(
        fontSize: fontSize,
        decoration: textDecoration,
        color: color,
        fontWeight: fontWeight,
        // fontFamily: fontFamily,
        letterSpacing: letterspace,
      ),
    );

    //  TextStyle(fontSize: fontSize, color: color, fontWeight: fontWeight, fontFamily: fontFamily,letterSpacing: letterspace));
  }
}
