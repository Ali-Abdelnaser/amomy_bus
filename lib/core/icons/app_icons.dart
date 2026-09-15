import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Centralized Lucide icon mapping for Amomy Bus.
///
/// Uses `lucide_icons` to establish a clean, modern, and unified visual language.
/// All icons are wrapped in constants/helpers so third-party library references are never
/// scattered across feature widgets.
abstract final class AppIcons {
  // Navigation & Core
  static const IconData home = LucideIcons.house;
  static const IconData user = LucideIcons.user;
  static const IconData wallet = LucideIcons.wallet;
  static const IconData bus = LucideIcons.bus;
  static const IconData calendar = LucideIcons.calendar;
  static const IconData clock = LucideIcons.clock;
  static const IconData location = LucideIcons.mapPin;
  static const IconData map = LucideIcons.map;
  static const IconData notification = LucideIcons.bell;
  static const IconData settings = LucideIcons.settings;

  // Actions & Controls
  static const IconData arrowBack = LucideIcons.arrowLeft;
  static const IconData arrowRight = LucideIcons.arrowRight;
  static const IconData arrowForward = LucideIcons.arrowRight;
  static const IconData close = LucideIcons.x;
  static const IconData check = LucideIcons.check;
  static const IconData checkCircle = LucideIcons.circleCheck;
  static const IconData add = LucideIcons.plus;
  static const IconData minus = LucideIcons.minus;
  static const IconData edit = LucideIcons.pencil;
  static const IconData search = LucideIcons.search;
  static const IconData filter = LucideIcons.funnel;
  static const IconData refresh = LucideIcons.refreshCw;

  // Feedback & Status
  static const IconData warning = LucideIcons.triangleAlert;
  static const IconData warningCircle = LucideIcons.circleAlert;
  static const IconData error = LucideIcons.circleX;
  static const IconData info = LucideIcons.info;

  // Inputs & Auth
  static const IconData email = LucideIcons.mail;
  static const IconData lock = LucideIcons.lock;
  static const IconData eye = LucideIcons.eye;
  static const IconData eyeOff = LucideIcons.eyeOff;
  static const IconData phone = LucideIcons.phone;
  static const IconData gender = LucideIcons.users;
  static const IconData birthday = LucideIcons.cake;
  static const IconData camera = LucideIcons.camera;
  static const IconData gallery = LucideIcons.image;
  static const IconData qrCode = LucideIcons.qrCode;
  static const IconData card = LucideIcons.creditCard;

  // Transportation & Seating
  static const IconData seat = LucideIcons.armchair;
  static const IconData steeringWheel = LucideIcons.compass;
  static const IconData ticket = LucideIcons.ticket;
  static const IconData receipt = LucideIcons.receipt;

  // Profile, Support & Settings
  static const IconData userRound = LucideIcons.userRound;
  static const IconData chevronRight = LucideIcons.chevronRight;
  static const IconData chevronLeft = LucideIcons.chevronLeft;
  static const IconData chevronDown = LucideIcons.chevronDown;
  static const IconData headphones = LucideIcons.headphones;
  static const IconData globe = LucideIcons.globe;
  static const IconData languages = LucideIcons.languages;
  static const IconData shield = LucideIcons.shieldCheck;
  static const IconData fileText = LucideIcons.fileText;
  static const IconData logOut = LucideIcons.logOut;
  static const IconData repeat = LucideIcons.repeat;
  static const IconData trash = LucideIcons.trash;
  static const IconData copy = LucideIcons.copy;
  static const IconData messageCircle = LucideIcons.messageCircle;
  static const IconData externalLink = LucideIcons.externalLink;
}
