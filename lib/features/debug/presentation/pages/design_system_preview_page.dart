import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../../../core/animations/app_animations.dart';
import '../../../../core/assets/app_assets.dart';
import '../../../../core/icons/app_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_bottom_sheet.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_date_picker_field.dart';
import '../../../../core/widgets/app_dialog.dart';
import '../../../../core/widgets/app_dropdown.dart';
import '../../../../core/widgets/app_empty_view.dart';
import '../../../../core/widgets/app_loading.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/app_skeleton.dart';
import '../../../../core/widgets/app_snack_bar.dart';
import '../../../../core/widgets/app_text_field.dart';

/// Comprehensive Development-Only Design System Showcase Screen.
///
/// Demonstrates tokens, colors, duotone icons, typography, buttons, text inputs,
/// dialogs, snackbars, cards, badges, chips, loaders, and animations.
class DesignSystemPreviewPage extends StatefulWidget {
  const DesignSystemPreviewPage({super.key});

  @override
  State<DesignSystemPreviewPage> createState() => _DesignSystemPreviewPageState();
}

class _DesignSystemPreviewPageState extends State<DesignSystemPreviewPage> {
  DateTime? _selectedDate;
  String? _selectedCity = 'Cairo';
  bool _isLoadingOverlay = false;
  bool _chipSelected = true;

  @override
  Widget build(BuildContext context) {
    // Safety check: only accessible in debug or profile mode
    if (kReleaseMode) {
      return const Scaffold(
        body: Center(child: Text('Debug preview not available in release.')),
      );
    }

    return AppScaffold(
      title: 'Design System Preview',
      body: Stack(
        children: [
          ListView(
            padding: AppSpacing.p16,
            children: [
              _buildSectionHeader('1. Brand Identity & Colors'),
              _buildColorGrid(),
              AppSpacing.gapH24,

              _buildSectionHeader('2. Brand Assets'),
              _buildAssetsShowcase(),
              AppSpacing.gapH24,

              _buildSectionHeader('3. Typography Scale'),
              _buildTypographyScale(),
              AppSpacing.gapH24,

              _buildSectionHeader('4. Duotone Icon Language'),
              _buildIconLanguage(),
              AppSpacing.gapH24,

              _buildSectionHeader('5. Buttons & Actions'),
              _buildButtonsShowcase(context),
              AppSpacing.gapH24,

              _buildSectionHeader('6. Text Fields & Forms'),
              _buildInputsShowcase(),
              AppSpacing.gapH24,

              _buildSectionHeader('7. Cards, Badges & Chips'),
              _buildCardsAndBadges(),
              AppSpacing.gapH24,

              _buildSectionHeader('8. Dialogs & Modals'),
              _buildModalsShowcase(context),
              AppSpacing.gapH24,

              _buildSectionHeader('9. SnackBars & Feedback'),
              _buildSnackBarsShowcase(context),
              AppSpacing.gapH24,

              _buildSectionHeader('10. Loading, Skeleton & States'),
              _buildStatesShowcase(),
              AppSpacing.gapH24,

              _buildSectionHeader('11. Subtle Micro-Animations'),
              _buildAnimationsShowcase(),
              AppSpacing.gapH40,
            ],
          ),
          if (_isLoadingOverlay)
            const AppLoadingOverlay(message: 'Processing operation...'),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.s12),
      child: Text(
        title,
        style: AppTextStyles.headlineSmall.copyWith(color: AppColors.primary),
      ),
    );
  }

  Widget _buildColorGrid() {
    final colors = [
      ('Primary #01589F', AppColors.primary, Colors.white),
      ('Primary Dark #01467F', AppColors.primaryDark, Colors.white),
      ('Primary Darker #00355F', AppColors.primaryDarker, Colors.white),
      ('Primary Light #E7F2FA', AppColors.primaryLight, AppColors.primary),
      ('Accent Yellow #FFC928', AppColors.accentYellow, AppColors.textPrimary),
      ('Surface Soft #F6F9FC', AppColors.surfaceSoft, AppColors.textPrimary),
      ('Border #E4E7EC', AppColors.border, AppColors.textPrimary),
      ('Success #12B76A', AppColors.success, Colors.white),
      ('Warning #F79009', AppColors.warning, Colors.white),
      ('Error #D92D20', AppColors.error, Colors.white),
      ('Seat Avail #01589F', AppColors.seatAvailable, Colors.white),
      ('Seat Confirmed', AppColors.seatConfirmed, Colors.white),
    ];

    return Wrap(
      spacing: AppSpacing.s8,
      runSpacing: AppSpacing.s8,
      children: colors.map((c) {
        return Container(
          width: 165,
          padding: const EdgeInsets.all(AppSpacing.s12),
          decoration: BoxDecoration(
            color: c.$2,
            borderRadius: AppRadius.radiusMd,
            border: Border.all(color: AppColors.border),
          ),
          child: Text(
            c.$1,
            style: AppTextStyles.labelSmall.copyWith(
              color: c.$3,
              fontWeight: FontWeight.w600,
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildAssetsShowcase() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        Column(
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: AppRadius.radiusMd,
                border: Border.all(color: AppColors.border),
              ),
              padding: const EdgeInsets.all(8),
              child: Image.asset(AppAssets.logoTransparent, fit: BoxFit.contain),
            ),
            AppSpacing.gapH8,
            const Text('Transparent Logo', style: AppTextStyles.labelSmall),
          ],
        ),
        Column(
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: AppRadius.radiusMd,
                border: Border.all(color: AppColors.border),
              ),
              padding: const EdgeInsets.all(8),
              child: Image.asset(AppAssets.logoWhiteBg, fit: BoxFit.contain),
            ),
            AppSpacing.gapH8,
            const Text('WhiteBg Logo', style: AppTextStyles.labelSmall),
          ],
        ),
        Column(
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: AppRadius.radiusMd,
                border: Border.all(color: AppColors.border),
              ),
              padding: const EdgeInsets.all(8),
              child: Image.asset(AppAssets.splash, fit: BoxFit.cover),
            ),
            AppSpacing.gapH8,
            const Text('Splash Asset', style: AppTextStyles.labelSmall),
          ],
        ),
      ],
    );
  }

  Widget _buildTypographyScale() {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text('Display Large 32pt', style: AppTextStyles.displayLarge),
          AppSpacing.gapH8,
          Text('Headline Large 24pt', style: AppTextStyles.headlineLarge),
          AppSpacing.gapH8,
          Text('Headline Medium 20pt', style: AppTextStyles.headlineMedium),
          AppSpacing.gapH8,
          Text('Title Large 16pt Bold', style: AppTextStyles.titleLarge),
          AppSpacing.gapH8,
          Text('Body Large 16pt - English & العربية متوافقة', style: AppTextStyles.bodyLarge),
          AppSpacing.gapH8,
          Text('Body Medium 14pt - English & العربية واضحة وسلسة', style: AppTextStyles.bodyMedium),
          AppSpacing.gapH8,
          Text('Body Small 12pt caption text', style: AppTextStyles.bodySmall),
        ],
      ),
    );
  }

  Widget _buildIconLanguage() {
    final icons = [
      (AppIcons.home, 'Home'),
      (AppIcons.bus, 'Bus'),
      (AppIcons.wallet, 'Wallet'),
      (AppIcons.user, 'Profile'),
      (AppIcons.calendar, 'Calendar'),
      (AppIcons.location, 'Location'),
      (AppIcons.seat, 'Seat'),
      (AppIcons.qrCode, 'QR Card'),
      (AppIcons.notification, 'Alert'),
      (AppIcons.receipt, 'Receipt'),
    ];

    return Wrap(
      spacing: AppSpacing.s16,
      runSpacing: AppSpacing.s12,
      children: icons.map((item) {
        return Column(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: AppRadius.radiusMd,
              ),
              child: Icon(item.$1, color: AppColors.primary, size: 24),
            ),
            AppSpacing.gapH4,
            Text(item.$2, style: AppTextStyles.labelSmall),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildButtonsShowcase(BuildContext context) {
    return Column(
      children: [
        AppButton(
          text: 'Primary Button',
          isFullWidth: true,
          icon: const Icon(AppIcons.bus, color: Colors.white, size: 18),
          onPressed: () {},
        ),
        AppSpacing.gapH12,
        AppButton(
          text: 'Secondary Button',
          variant: ButtonVariant.secondary,
          isFullWidth: true,
          onPressed: () {},
        ),
        AppSpacing.gapH12,
        AppButton(
          text: 'Outline Button',
          variant: ButtonVariant.outline,
          isFullWidth: true,
          onPressed: () {},
        ),
        AppSpacing.gapH12,
        AppButton(
          text: 'Danger Button',
          variant: ButtonVariant.danger,
          isFullWidth: true,
          onPressed: () {},
        ),
        AppSpacing.gapH12,
        Row(
          children: [
            Expanded(
              child: AppButton(
                text: 'Loading State',
                isLoading: true,
                onPressed: () {},
              ),
            ),
            AppSpacing.gapW12,
            Expanded(
              child: AppButton(
                text: 'Disabled State',
                onPressed: null,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInputsShowcase() {
    return Column(
      children: [
        const AppTextField(
          label: 'Full Name',
          hint: 'Enter your name',
          prefixIcon: Icon(AppIcons.user, color: AppColors.textSecondary, size: 20),
        ),
        AppSpacing.gapH16,
        const AppPasswordField(
          label: 'Password',
          hint: 'Enter secure password',
        ),
        AppSpacing.gapH16,
        const AppSearchField(
          hint: 'Search bus routes or stations...',
        ),
        AppSpacing.gapH16,
        AppDropdown<String>(
          label: 'City of Residence',
          value: _selectedCity,
          items: const [
            DropdownMenuItem(value: 'Cairo', child: Text('Cairo')),
            DropdownMenuItem(value: 'Giza', child: Text('Giza')),
            DropdownMenuItem(value: 'Alexandria', child: Text('Alexandria')),
          ],
          onChanged: (val) => setState(() => _selectedCity = val),
        ),
        AppSpacing.gapH16,
        AppDatePickerField(
          label: 'Date of Birth',
          selectedDate: _selectedDate,
          onDateSelected: (date) => setState(() => _selectedDate = date),
        ),
        AppSpacing.gapH16,
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text('OTP Digit Inputs (Foundation)', style: AppTextStyles.labelLarge),
            AppSpacing.gapH8,
            AppOtpField(),
          ],
        ),
      ],
    );
  }

  Widget _buildCardsAndBadges() {
    return Column(
      children: [
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Cairo -> Alexandria Express', style: AppTextStyles.titleMedium),
                  AppBadge.success(label: 'Confirmed', icon: AppIcons.checkCircle),
                ],
              ),
              AppSpacing.gapH8,
              Text('Departure: 08:30 AM | Seat 14A', style: AppTextStyles.bodySmall),
              AppSpacing.gapH12,
              Wrap(
                spacing: AppSpacing.s8,
                children: [
                  AppBadge.info(label: 'WiFi Included'),
                  AppBadge.warning(label: '5 Seats Left'),
                ],
              ),
            ],
          ),
        ),
        AppSpacing.gapH16,
        Row(
          children: [
            AppChip(
              label: 'Morning Trips',
              isSelected: _chipSelected,
              onSelected: (val) => setState(() => _chipSelected = val),
            ),
            AppSpacing.gapW8,
            AppChip(
              label: 'Evening Trips',
              isSelected: !_chipSelected,
              onSelected: (val) => setState(() => _chipSelected = !val),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildModalsShowcase(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: AppButton(
            text: 'Test Dialog',
            variant: ButtonVariant.outline,
            onPressed: () {
              showConfirmDialog(
                context: context,
                title: 'Cancel Booking?',
                message: 'Are you sure you want to release seat hold 14A?',
                isDestructive: true,
                onConfirm: () {
                  AppSnackBar.showSuccess(context, 'Hold released successfully');
                },
              );
            },
          ),
        ),
        AppSpacing.gapW12,
        Expanded(
          child: AppButton(
            text: 'Test Sheet',
            variant: ButtonVariant.outline,
            onPressed: () {
              showAppBottomSheet(
                context: context,
                title: 'Select Payment Method',
                content: Column(
                  children: [
                    ListTile(
                      leading: const Icon(AppIcons.card, color: AppColors.primary),
                      title: const Text('Vodafone Cash'),
                      subtitle: const Text('Instant manual transfer'),
                      onTap: () => Navigator.pop(context),
                    ),
                    ListTile(
                      leading: const Icon(AppIcons.card, color: AppColors.primary),
                      title: const Text('Orange Cash'),
                      subtitle: const Text('Instant manual transfer'),
                      onTap: () => Navigator.pop(context),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSnackBarsShowcase(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.s8,
      runSpacing: AppSpacing.s8,
      children: [
        AppButton(
          text: 'Success SnackBar',
          variant: ButtonVariant.text,
          onPressed: () => AppSnackBar.showSuccess(context, 'Operation completed successfully!'),
        ),
        AppButton(
          text: 'Error SnackBar',
          variant: ButtonVariant.text,
          onPressed: () => AppSnackBar.showError(context, 'Network connection timed out.'),
        ),
        AppButton(
          text: 'Warning SnackBar',
          variant: ButtonVariant.text,
          onPressed: () => AppSnackBar.showWarning(context, 'Your seat hold expires in 1 minute.'),
        ),
        AppButton(
          text: 'Loading Overlay',
          variant: ButtonVariant.text,
          onPressed: () async {
            setState(() => _isLoadingOverlay = true);
            await Future.delayed(const Duration(seconds: 2));
            if (mounted) setState(() => _isLoadingOverlay = false);
          },
        ),
      ],
    );
  }

  Widget _buildStatesShowcase() {
    return Column(
      children: [
        AppCard(
          child: Column(
            children: const [
              Text('Skeleton Loading Pattern', style: AppTextStyles.labelLarge),
              AppSpacing.gapH12,
              AppSkeletonBone(width: double.infinity, height: 16),
              AppSpacing.gapH8,
              AppSkeletonBone(width: 200, height: 14),
            ],
          ),
        ),
        AppSpacing.gapH16,
        const AppEmptyView(
          message: 'No trips scheduled for this date.',
        ),
      ],
    );
  }

  Widget _buildAnimationsShowcase() {
    return AppCard(
      child: Column(
        children: [
          const Text('Fade In & Slide Up Animation', style: AppTextStyles.labelLarge),
          AppSpacing.gapH12,
          Container(
            padding: AppSpacing.p12,
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: AppRadius.radiusMd,
            ),
            child: const Text('Subtle micro-interaction card entrance'),
          ).animateSlideUp(),
        ],
      ),
    );
  }
}
