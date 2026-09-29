import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:amomy_bus/app/router/app_router.dart';
import 'package:amomy_bus/app/router/route_paths.dart';
import 'package:amomy_bus/features/auth/domain/entities/app_user.dart';
import 'package:amomy_bus/features/auth/presentation/bloc/auth_state.dart';
import 'package:amomy_bus/core/error/failures.dart';
import 'package:amomy_bus/core/icons/app_icons.dart';
import 'package:amomy_bus/core/typedefs/typedefs.dart';
import 'package:amomy_bus/features/booking/presentation/widgets/app_qr_ticket_widget.dart';
import 'package:amomy_bus/features/notifications/domain/entities/app_notification.dart';
import 'package:amomy_bus/features/notifications/presentation/services/notification_router.dart';
import 'package:amomy_bus/features/referral/data/models/referral_models.dart';
import 'package:amomy_bus/features/referral/domain/entities/referral_entities.dart';
import 'package:amomy_bus/features/referral/domain/repositories/referral_repository.dart';
import 'package:amomy_bus/features/referral/domain/usecases/referral_usecases.dart';
import 'package:amomy_bus/features/referral/presentation/cubit/referral_cubit.dart';
import 'package:amomy_bus/features/referral/presentation/cubit/referral_state.dart';
import 'package:amomy_bus/features/referral/presentation/pages/invite_friends_page.dart';
import 'package:amomy_bus/features/referral/presentation/widgets/referral_qr_dialog.dart';
import 'package:amomy_bus/l10n/app_localizations.dart';

class MockReferralRepository implements ReferralRepository {
  ReferralDashboard? dashboardToReturn;
  Failure? dashboardFailure;
  ReferralCodePreview? previewToReturn;
  Failure? previewFailure;
  BindReferralResult? bindToReturn;
  Failure? bindFailure;

  String? lastPreviewedCode;
  String? lastBoundCode;
  String? lastBoundSource;
  int bindCallCount = 0;

  @override
  ResultFuture<ReferralDashboard> getMyReferralDashboard() async {
    if (dashboardFailure != null) {
      return Error(dashboardFailure!);
    }
    return Success(dashboardToReturn ?? _createSampleDashboard());
  }

  @override
  ResultFuture<ReferralCodePreview> previewReferralCode(String code) async {
    lastPreviewedCode = code;
    if (previewFailure != null) {
      return Error(previewFailure!);
    }
    return Success(
      previewToReturn ??
          ReferralCodePreview(
            valid: true,
            programEnabled: true,
            code: code,
            inviterUserId: 'user-123',
            inviterName: 'كابتن أحمد',
            inviterAvatarUrl: null,
            inviteeFirstRewardPoints: 5,
            inviterFirstRewardPoints: 20,
            milestoneTripCount: 3,
            inviterMilestoneRewardPoints: 30,
            reason: null,
          ),
    );
  }

  @override
  ResultFuture<BindReferralResult> bindReferralCode({
    required String code,
    required String source,
  }) async {
    lastBoundCode = code;
    lastBoundSource = source;
    bindCallCount++;
    if (bindFailure != null) {
      return Error(bindFailure!);
    }
    return Success(
      bindToReturn ??
          const BindReferralResult(
            success: true,
            referralId: 'ref-999',
            inviterUserId: 'user-123',
            inviterName: 'كابتن أحمد',
            inviteeFirstRewardPoints: 5,
            milestoneTripCount: 3,
          ),
    );
  }

  @override
  Stream<void> subscribeToReferralSettingsUpdates() => const Stream.empty();

  @override
  Stream<void> subscribeToReferralDashboardUpdates() => const Stream.empty();

  static ReferralDashboard _createSampleDashboard({
    bool enabled = true,
    bool isLinked = false,
  }) {
    return ReferralDashboard(
      program: ReferralProgramSettings(
        enabled: enabled,
        monthlyInviteLimit: 5,
        milestoneTripCount: 3,
        inviterFirstRewardPoints: 20,
        inviteeFirstRewardPoints: 5,
        inviterMilestoneRewardPoints: 30,
      ),
      myCode: 'AMOMY777',
      inviterStats: const InviterStats(
        acceptedThisMonth: 2,
        remainingThisMonth: 3,
        totalInvited: 2,
        totalRewardPointsEarned: 60,
      ),
      invitedBy: isLinked
          ? InvitedByInfo(
              referralId: 'ref-111',
              inviterUserId: 'inviter-111',
              inviterName: 'كريم محمود',
              inviterAvatarUrl: null,
              acceptedAt: DateTime(2026, 3, 1),
              source: 'manual_code',
            )
          : null,
      inviteeProgress: isLinked
          ? const InviteeProgress(
              referralId: 'ref-111',
              qualifiedTripCount: 2,
              milestoneTripCount: 3,
              firstTripRewardPoints: 5,
              firstTripRewardGranted: true,
              status: 'active',
            )
          : null,
      inviteesThisMonth: [
        InvitedFriendItem(
          referralId: 'ref-f1',
          inviteeUserId: 'u1',
          inviteeName: 'محمد علي',
          inviteeAvatarUrl: null,
          acceptedAt: DateTime(2026, 3, 10),
          source: 'share_link',
          status: 'rewarded',
          qualifiedTripCount: 3,
          milestoneTripCount: 3,
          firstRewardPoints: 20,
          firstRewardGranted: true,
          milestoneRewardPoints: 30,
          milestoneRewardGranted: true,
        ),
        InvitedFriendItem(
          referralId: 'ref-f2',
          inviteeUserId: 'u2',
          inviteeName: 'سارة طارق',
          inviteeAvatarUrl: null,
          acceptedAt: DateTime(2026, 3, 12),
          source: 'qr',
          status: 'active',
          qualifiedTripCount: 1,
          milestoneTripCount: 3,
          firstRewardPoints: 20,
          firstRewardGranted: false,
          milestoneRewardPoints: 30,
          milestoneRewardGranted: false,
        ),
      ],
    );
  }
}

Widget _buildTestApp({
  required Widget child,
  Locale locale = const Locale('ar'),
}) {
  return MaterialApp(
    locale: locale,
    supportedLocales: const [Locale('ar'), Locale('en')],
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    home: child,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Referral Notifications & Routing', () {
    test('NotificationType.referralReward parsing and db string', () {
      expect(
        NotificationType.fromString('referral_reward'),
        NotificationType.referralReward,
      );
      expect(
        NotificationType.fromString('referral'),
        NotificationType.referralReward,
      );
      expect(
        NotificationType.fromString('referrals'),
        NotificationType.referralReward,
      );
      expect(
        NotificationType.referralReward.toDbString(),
        'referral_reward',
      );
    });

    test('NotificationRouter routes referral_reward to inviteFriends path', () {
      expect(
        NotificationRouter.resolveRoute({'type': 'referral_reward'}),
        RoutePaths.inviteFriends,
      );
      expect(
        NotificationRouter.resolveRoute({'screen': 'referral_reward'}),
        RoutePaths.inviteFriends,
      );
      expect(
        NotificationRouter.resolveRoute({'screen': 'invite'}),
        RoutePaths.inviteFriends,
      );
      expect(
        NotificationRouter.resolveRoute({'screen': 'invite_friends'}),
        RoutePaths.inviteFriends,
      );
    });
  });

  group('Referral Models JSON Serialization', () {
    test('deserializes get_my_referral_dashboard payload accurately', () {
      final json = {
        'program': {
          'enabled': true,
          'monthly_invite_limit': 5,
          'milestone_trip_count': 3,
          'inviter_first_reward_points': 20,
          'invitee_first_reward_points': 5,
          'inviter_milestone_reward_points': 30,
        },
        'my_code': 'SAVE100',
        'inviter_stats': {
          'accepted_this_month': 3,
          'remaining_this_month': 2,
          'total_invited': 3,
          'total_reward_points_earned': 60,
        },
        'invited_by': {
          'referral_id': 'ref-001',
          'inviter_user_id': 'user-001',
          'inviter_name': 'خالد سامي',
          'inviter_avatar_url': null,
          'accepted_at': '2026-03-01T10:00:00Z',
          'source': 'manual_code',
        },
        'invitee_progress': {
          'referral_id': 'ref-001',
          'qualified_trip_count': 1,
          'milestone_trip_count': 3,
          'first_trip_reward_points': 5,
          'first_trip_reward_granted': false,
          'status': 'active',
        },
        'invitees_this_month': [
          {
            'referral_id': 'ref-002',
            'invitee_user_id': 'user-002',
            'invitee_name': 'عمرو دياب',
            'invitee_avatar_url': null,
            'accepted_at': '2026-03-05T12:00:00Z',
            'source': 'share_link',
            'status': 'active',
            'qualified_trip_count': 2,
            'milestone_trip_count': 3,
            'first_reward_points': 20,
            'first_reward_granted': false,
            'milestone_reward_points': 30,
            'milestone_reward_granted': false,
          }
        ],
      };

      final model = ReferralDashboardModel.fromJson(json);
      expect(model.program.enabled, isTrue);
      expect(model.myCode, 'SAVE100');
      expect(model.inviterStats.acceptedThisMonth, 3);
      expect(model.isLinked, isTrue);
      expect(model.invitedBy?.inviterName, 'خالد سامي');
      expect(model.inviteeProgress?.qualifiedTripCount, 1);
      expect(model.inviteesThisMonth.length, 1);
      expect(model.inviteesThisMonth.first.inviteeName, 'عمرو دياب');
    });

    test('handles preview code and bind result models', () {
      final previewValidJson = {
        'valid': true,
        'program_enabled': true,
        'code': 'AMOMY50',
        'inviter_name': 'ماجد كمال',
      };
      final previewValid = ReferralCodePreviewModel.fromJson(previewValidJson);
      expect(previewValid.valid, isTrue);
      expect(previewValid.inviterName, 'ماجد كمال');

      final previewInvalidJson = {
        'valid': false,
        'program_enabled': true,
        'code': 'EXPIRED',
        'reason': 'ALREADY_REFERRED',
      };
      final previewInvalid =
          ReferralCodePreviewModel.fromJson(previewInvalidJson);
      expect(previewInvalid.valid, isFalse);
      expect(
        previewInvalid.localizedError(isArabic: true),
        contains('مربوط بالفعل بكود دعوة'),
      );

      final bindJson = {
        'success': true,
        'referral_id': 'ref-555',
        'inviter_user_id': 'u-555',
        'inviter_name': 'ماجد كمال',
        'milestone_trip_count': 3,
        'invitee_first_reward_points': 5,
      };
      final bindResult = BindReferralResultModel.fromJson(bindJson);
      expect(bindResult.success, isTrue);
      expect(bindResult.inviteeFirstRewardPoints, 5);
    });
  });

  group('ReferralCubit', () {
    late MockReferralRepository repo;
    late ReferralCubit cubit;

    setUp(() {
      repo = MockReferralRepository();
      cubit = ReferralCubit(
        getDashboardUseCase: GetMyReferralDashboardUseCase(repo),
        previewCodeUseCase: PreviewReferralCodeUseCase(repo),
        bindCodeUseCase: BindReferralCodeUseCase(repo),
      );
    });

    tearDown(() {
      cubit.close();
    });

    test('loadDashboard emits loaded on success', () async {
      final dashboard = MockReferralRepository._createSampleDashboard();
      repo.dashboardToReturn = dashboard;

      await cubit.loadDashboard();

      expect(cubit.state.status, ReferralStatus.loaded);
      expect(cubit.state.dashboard?.myCode, 'AMOMY777');
    });

    test('previewCode emits success for valid code', () async {
      await cubit.previewCode('AMOMY777');

      expect(cubit.state.previewStatus, ReferralPreviewStatus.success);
      expect(cubit.state.preview?.inviterName, 'كابتن أحمد');
    });

    test('bindCode successfully calls repository and reloads dashboard',
        () async {
      final success = await cubit.bindCode(
        code: 'AMOMY777',
        source: 'manual_code',
      );

      expect(success, isTrue);
      expect(repo.lastBoundCode, 'AMOMY777');
      expect(repo.lastBoundSource, 'manual_code');
      expect(cubit.state.bindStatus, ReferralBindStatus.success);
    });
  });

  group('Invite Friends UI Widgets', () {
    late MockReferralRepository repo;
    late ReferralCubit cubit;

    setUp(() {
      repo = MockReferralRepository();
      cubit = ReferralCubit(
        getDashboardUseCase: GetMyReferralDashboardUseCase(repo),
        previewCodeUseCase: PreviewReferralCodeUseCase(repo),
        bindCodeUseCase: BindReferralCodeUseCase(repo),
      );
    });

    tearDown(() {
      cubit.close();
    });

    testWidgets(
        'Tab 1 (دعواتي) renders referral code, monthly progress, and friends list',
        (tester) async {
      final dashboard = MockReferralRepository._createSampleDashboard();
      repo.dashboardToReturn = dashboard;

      await tester.pumpWidget(
        _buildTestApp(
          child: InviteFriendsPage(referralCubit: cubit),
        ),
      );
      await tester.pumpAndSettle();

      // Check code AMOMY777 displayed
      expect(find.text('AMOMY777'), findsOneWidget);

      // Check monthly progress 2 and / 5
      expect(find.text('2'), findsWidgets);
      expect(find.text(' / 5'), findsOneWidget);

      // Check total reward points 60
      expect(find.text('60'), findsOneWidget);

      // Check invited friend
      expect(find.text('محمد علي'), findsOneWidget);

      // Check action buttons: Copy, Share, QR
      expect(find.text('نسخ'), findsOneWidget);
      expect(find.text('مشاركة'), findsOneWidget);
      expect(find.byIcon(AppIcons.qrCode), findsOneWidget);
    });

    testWidgets('QR button opens QR dialog encoding amomy://invite?code=CODE',
        (tester) async {
      final dashboard = MockReferralRepository._createSampleDashboard();
      repo.dashboardToReturn = dashboard;

      await tester.pumpWidget(
        _buildTestApp(
          child: InviteFriendsPage(referralCubit: cubit),
        ),
      );
      await tester.pumpAndSettle();

      // Tap QR icon button
      await tester.tap(find.byIcon(AppIcons.qrCode));
      await tester.pumpAndSettle();

      // Verify QR Dialog is visible and encodes the deep link
      expect(find.byType(ReferralQrDialog), findsOneWidget);
      expect(find.text('رمز QR للدعوة'), findsOneWidget);
      final qrWidget =
          tester.widget<AppQrTicketWidget>(find.byType(AppQrTicketWidget));
      expect(qrWidget.data, 'amomy://invite?code=AMOMY777');
    });

    testWidgets('Share button exists and is tappable (native share sheet)',
        (tester) async {
      final dashboard = MockReferralRepository._createSampleDashboard();
      repo.dashboardToReturn = dashboard;

      await tester.pumpWidget(
        _buildTestApp(
          child: InviteFriendsPage(referralCubit: cubit),
        ),
      );
      await tester.pumpAndSettle();

      // Verify Share button is rendered
      expect(find.text('مشاركة'), findsOneWidget);

      // Tap Share button — triggers native share sheet (no dialog shown in test)
      // This verifies the button is tappable and doesn't crash
      await tester.tap(find.text('مشاركة'));
      await tester.pump();

      // No ReferralShareDialog expected — replaced with native share_plus
    });

    testWidgets(
        'Tab 2 (من دعاني) when unlinked: requires preview and user confirmation, never auto-binds',
        (tester) async {
      final dashboard =
          MockReferralRepository._createSampleDashboard(isLinked: false);
      repo.dashboardToReturn = dashboard;

      await tester.pumpWidget(
        _buildTestApp(
          child: InviteFriendsPage(referralCubit: cubit),
        ),
      );
      await tester.pumpAndSettle();

      // Switch to Tab 2 "من دعاني"
      await tester.tap(find.text('من دعاني'));
      await tester.pumpAndSettle();

      // Should see referral code input field and preview button
      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('معاينة كود الدعوة'), findsOneWidget);

      // Verify repository has NOT been called for binding (never auto-bind)
      expect(repo.bindCallCount, 0);

      // Enter code and tap preview
      await tester.enterText(find.byType(TextField), 'AMOMY999');
      await tester.pump();
      await tester.tap(find.text('معاينة كود الدعوة'));
      await tester.pumpAndSettle();

      // Verify preview code was checked
      expect(repo.lastPreviewedCode, 'AMOMY999');

      // Verify Inviter preview card appeared with inviter name
      expect(find.text('كابتن أحمد'), findsOneWidget);
      expect(find.text('تأكيد واستخدام الكود'), findsOneWidget);

      // User must explicitly click confirm before binding
      expect(repo.bindCallCount, 0);
      await tester.tap(find.text('تأكيد واستخدام الكود'));
      await tester.pumpAndSettle();

      // Verify binding occurred only after explicit confirmation
      expect(repo.bindCallCount, 1);
      expect(repo.lastBoundCode, 'AMOMY999');
      expect(repo.lastBoundSource, 'manual_code');
    });

    testWidgets(
        'Tab 2 (من دعاني) when already linked: permanently locks input, shows inviter & progress',
        (tester) async {
      final dashboard =
          MockReferralRepository._createSampleDashboard(isLinked: true);
      repo.dashboardToReturn = dashboard;

      await tester.pumpWidget(
        _buildTestApp(
          child: InviteFriendsPage(referralCubit: cubit),
        ),
      );
      await tester.pumpAndSettle();

      // Switch to Tab 2 "من دعاني"
      await tester.tap(find.text('من دعاني'));
      await tester.pumpAndSettle();

      // Code input field must NOT exist for linked user
      expect(find.byType(TextField), findsNothing);

      // Shows inviter name
      expect(find.text('كريم محمود'), findsOneWidget);
      expect(find.text('تمت دعوتك بواسطة'), findsOneWidget);

      // Shows my 3-trip progress (2 من 3 رحلات)
      expect(find.text('2 من 3 رحلات'), findsOneWidget);

      // Shows 5-point reward status
      expect(find.textContaining('5'), findsWidgets);
    });

    testWidgets('Deep link initialCode opens Tab 2, previews code, and asks for confirmation',
        (tester) async {
      final dashboard =
          MockReferralRepository._createSampleDashboard(isLinked: false);
      repo.dashboardToReturn = dashboard;

      await tester.pumpWidget(
        _buildTestApp(
          child: InviteFriendsPage(
            initialCode: 'DEEPLINK123',
            referralCubit: cubit,
          ),
        ),
      );
      await tester.pump();
      await tester.pumpAndSettle();

      // Should automatically select Tab 2 and run preview
      expect(repo.lastPreviewedCode, 'DEEPLINK123');
      // Should show inviter name
      expect(find.text('كابتن أحمد'), findsOneWidget);
      // Never auto-bind! User must confirm
      expect(repo.bindCallCount, 0);
      expect(find.text('تأكيد واستخدام الكود'), findsOneWidget);
    });

    testWidgets('Program disabled state does not show disabled referral page',
        (tester) async {
      final dashboard =
          MockReferralRepository._createSampleDashboard(enabled: false);
      repo.dashboardToReturn = dashboard;

      await tester.pumpWidget(
        _buildTestApp(
          child: InviteFriendsPage(referralCubit: cubit),
        ),
      );
      await tester.pumpAndSettle();

      // Disabled / paused page is NOT shown
      expect(find.textContaining('برنامج الدعوات متوقف حالياً'), findsNothing);
      expect(find.text('دعواتي'), findsNothing);
      expect(find.text('من دعاني'), findsNothing);
    });
  });

  group('Referral Router Redirection Guards', () {
    final authUser = AppUser(
      id: 'test-user-id',
      phone: '+201000000000',
      fullName: 'Test User',
      email: 'test@example.com',
      gender: 'male',
      dateOfBirth: DateTime(1995, 1, 1),
      isEmailVerified: true,
    );
    final authState = Authenticated(user: authUser);

    test('redirectLogic redirects /invite-friends to /home when isReferralDisabled is true', () {
      final redirect = AppRouter.redirectLogic(
        authState,
        RoutePaths.inviteFriends,
        isReferralDisabled: true,
      );
      expect(redirect, RoutePaths.home);
    });

    test('redirectLogic redirects /invite to /home when isReferralDisabled is true', () {
      final redirect = AppRouter.redirectLogic(
        authState,
        RoutePaths.inviteAlias,
        isReferralDisabled: true,
      );
      expect(redirect, RoutePaths.home);
    });

    test('redirectLogic allows /invite-friends when isReferralDisabled is false', () {
      final redirect = AppRouter.redirectLogic(
        authState,
        RoutePaths.inviteFriends,
        isReferralDisabled: false,
      );
      expect(redirect, isNull);
    });
  });
}
