import 'package:flutter/material.dart';

/// Animation and Motion constants for Ezze Break (v2.0)
class EzzeMotion {
  // Easing curves
  static const Curve standard = Curves.easeOutCubic;
  static const Curve enter = Curves.easeOutBack; // Slight overshoot
  static const Curve exit = Curves.easeInCubic;
  static const Curve bounce = Curves.elasticOut;
  static const Curve progress = Curves.easeInOutCubic;

  // Duration scale
  static const Duration instant = Duration(milliseconds: 100);
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration normal = Duration(milliseconds: 250);
  static const Duration slow = Duration(milliseconds: 400);
  static const Duration dramatic = Duration(milliseconds: 600);
  static const Duration glacial = Duration(milliseconds: 1000);

  // Specific animation durations
  static const Duration tabSwitch = Duration(milliseconds: 300);
  static const Duration cardEntrance = Duration(milliseconds: 250);
  static const Duration progressBarFill = Duration(milliseconds: 500);
  static const Duration gaugeArc = Duration(milliseconds: 600);
  static const Duration buttonPress = Duration(milliseconds: 100);
  static const Duration pinDigitEntry = Duration(milliseconds: 150);
  static const Duration pinErrorShake = Duration(milliseconds: 400);
  static const Duration timerPulse = Duration(milliseconds: 2000);
  static const Duration confettiBurst = Duration(milliseconds: 1500);
  static const Duration pageTransition = Duration(milliseconds: 300);
  static const Duration bottomSheet = Duration(milliseconds: 350);
  static const Duration dialog = Duration(milliseconds: 200);
  static const Duration chipPress = Duration(milliseconds: 100);
  static const Duration fabPress = Duration(milliseconds: 150);
  static const Duration staggeredOffset = Duration(milliseconds: 50);
}
