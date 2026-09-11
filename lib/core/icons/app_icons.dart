import 'package:flutter/widgets.dart';
import 'package:phosphor_icons/phosphor_icons.dart';

/// Centralized Duotone icon mapping for Amomy Bus.
///
/// Uses `phosphor_flutter` duotone style to establish a cohesive, modern visual language.
/// All icons are wrapped in constants/helpers so third-party library references are never
/// scattered across feature widgets.
abstract final class AppIcons {
  // Navigation & Core
  static const IconData home = PhosphorIconsDuotone.house;
  static const IconData user = PhosphorIconsDuotone.user;
  static const IconData wallet = PhosphorIconsDuotone.wallet;
  static const IconData bus = PhosphorIconsDuotone.bus;
  static const IconData calendar = PhosphorIconsDuotone.calendar;
  static const IconData clock = PhosphorIconsDuotone.clock;
  static const IconData location = PhosphorIconsDuotone.mapPin;
  static const IconData map = PhosphorIconsDuotone.mapTrifold;
  static const IconData notification = PhosphorIconsDuotone.bell;
  static const IconData settings = PhosphorIconsDuotone.gear;

  // Actions & Controls
  static const IconData arrowBack = PhosphorIconsDuotone.arrowLeft;
  static const IconData arrowRight = PhosphorIconsDuotone.arrowRight;
  static const IconData arrowForward = PhosphorIconsDuotone.arrowRight;
  static const IconData close = PhosphorIconsDuotone.x;
  static const IconData check = PhosphorIconsDuotone.check;
  static const IconData checkCircle = PhosphorIconsDuotone.checkCircle;
  static const IconData add = PhosphorIconsDuotone.plus;
  static const IconData minus = PhosphorIconsDuotone.minus;
  static const IconData edit = PhosphorIconsDuotone.pencilSimple;
  static const IconData search = PhosphorIconsDuotone.magnifyingGlass;
  static const IconData filter = PhosphorIconsDuotone.funnel;
  static const IconData history = PhosphorIconsDuotone.clockCounterClockwise;
  static const IconData refresh = PhosphorIconsDuotone.arrowsClockwise;

  // Feedback & Status
  static const IconData warning = PhosphorIconsDuotone.warning;
  static const IconData warningCircle = PhosphorIconsDuotone.warningCircle;
  static const IconData error = PhosphorIconsDuotone.xCircle;
  static const IconData info = PhosphorIconsDuotone.info;

  // Inputs & Auth
  static const IconData email = PhosphorIconsDuotone.envelope;
  static const IconData lock = PhosphorIconsDuotone.lock;
  static const IconData eye = PhosphorIconsDuotone.eye;
  static const IconData eyeOff = PhosphorIconsDuotone.eyeSlash;
  static const IconData phone = PhosphorIconsDuotone.phone;
  static const IconData gender = PhosphorIconsDuotone.genderIntersex;
  static const IconData birthday = PhosphorIconsDuotone.cake;
  static const IconData camera = PhosphorIconsDuotone.camera;
  static const IconData gallery = PhosphorIconsDuotone.image;
  static const IconData qrCode = PhosphorIconsDuotone.qrCode;
  static const IconData card = PhosphorIconsDuotone.creditCard;

  // Transportation & Seating
  static const IconData seat = PhosphorIconsDuotone.armchair;
  static const IconData steeringWheel = PhosphorIconsDuotone.steeringWheel;
  static const IconData route = PhosphorIconsDuotone.path;
  static const IconData ticket = PhosphorIconsDuotone.ticket;
  static const IconData receipt = PhosphorIconsDuotone.receipt;
}
