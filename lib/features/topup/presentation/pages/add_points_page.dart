import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/di/injection.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/icons/app_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_loading.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../domain/entities/topup_entities.dart';
import '../cubit/topup_cubit.dart';
import '../cubit/topup_state.dart';
import '../widgets/amount_step_widget.dart';
import '../widgets/instructions_step_widget.dart';
import '../widgets/pending_success_step_widget.dart';
import '../widgets/topup_step_indicator.dart';
import '../widgets/transfer_details_step_widget.dart';

class AddPointsPage extends StatelessWidget {
  final TopUpCubit? topUpCubit;
  final int initialAvailablePoints;
  final TopUpRequest? resubmitRequest;

  const AddPointsPage({
    super.key,
    this.topUpCubit,
    this.initialAvailablePoints = 0,
    this.resubmitRequest,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return BlocProvider(
      create: (context) {
        final cubit = topUpCubit ?? getIt<TopUpCubit>();
        if (resubmitRequest != null) {
          cubit.initWithResubmit(resubmitRequest!);
        } else {
          cubit.init(availableBalance: initialAvailablePoints);
        }
        return cubit;
      },
      child: BlocConsumer<TopUpCubit, TopUpState>(
        listener: (context, state) {
          if (state.errorMessage != null && state.errorMessage!.isNotEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.errorMessage!),
                backgroundColor: AppColors.error,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            );
          }
        },
        builder: (context, state) {
          final cubit = context.read<TopUpCubit>();

          return AppScaffold(
            appBar: AppBar(
              scrolledUnderElevation: 0,
              title: Text(
                state.isResubmit
                    ? l10n.resubmitPaymentTitle
                    : l10n.actionAddPoints,
              ),
              centerTitle: true,
              leading: state.currentStep == TopUpStep.pendingReview
                  ? const SizedBox.shrink()
                  : IconButton(
                      icon: const Icon(AppIcons.arrowBack),
                      onPressed: () {
                        if (state.isResubmit ||
                            state.currentStep == TopUpStep.amount) {
                          context.pop();
                        } else {
                          cubit.previousStep();
                        }
                      },
                    ),
            ),
            body: state.isLoadingConfig
                ? const Center(child: AppLoading())
                : SafeArea(
                    bottom: false,
                    child: Padding(
                      padding: AppSpacing.edgeInsetsA16,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (!state.isResubmit &&
                              state.currentStep != TopUpStep.pendingReview) ...[
                            TopUpStepIndicator(currentStep: state.currentStep),
                            AppSpacing.gapH16,
                          ],
                          Expanded(
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 250),
                              transitionBuilder: (child, animation) {
                                return FadeTransition(
                                  opacity: animation,
                                  child: SlideTransition(
                                    position: Tween<Offset>(
                                      begin: const Offset(0, 0.02),
                                      end: Offset.zero,
                                    ).animate(animation),
                                    child: child,
                                  ),
                                );
                              },
                              child: switch (state.currentStep) {
                                TopUpStep.amount => AmountStepWidget(
                                  key: const ValueKey('amount_step'),
                                  initialAmount: state.amount,
                                  availableBalance: state.availableBalance,
                                  minimumPoints:
                                      state.paymentConfig.minimumTopupPoints,
                                  egpPerPoint: state.paymentConfig.egpPerPoint,
                                  onAmountChanged: cubit.setAmount,
                                  onNext: cubit.proceedToInstructions,
                                ),
                                TopUpStep.instructions =>
                                  InstructionsStepWidget(
                                    key: const ValueKey('instructions_step'),
                                    points: state.amount,
                                    amountEgp: state.expectedAmountEgp,
                                    receivingPhone:
                                        state.effectiveReceivingNumber,
                                    paymentMethods: state.paymentMethods,
                                    selectedMethod: state.selectedMethod,
                                    onMethodSelected: cubit.selectPaymentMethod,
                                    methodName: state.selectedMethod
                                        ?.localizedName(
                                          Localizations.localeOf(
                                                context,
                                              ).languageCode ==
                                              'ar',
                                        ),
                                    isSubmitting: state.isSubmitting,
                                    onTransferred:
                                        cubit.confirmTransferAndCreateRequest,
                                    onBack: cubit.previousStep,
                                  ),
                                TopUpStep.details => TransferDetailsStepWidget(
                                  key: const ValueKey('details_step'),
                                  points: state.amount,
                                  amountEgp: state.expectedAmountEgp,
                                  publicId: state.createdPublicId,
                                  initialSenderPhone: state.senderPhone,
                                  initialReference: state.paymentReference,
                                  initialTransferredAt: state.transferredAt,
                                  proofBytes: state.proofBytes,
                                  proofFileName: state.proofFileName,
                                  isSubmitting: state.isSubmitting,
                                  isResubmit: state.isResubmit,
                                  rejectionReason: state.rejectionReason,
                                  onSenderPhoneChanged: cubit.setSenderPhone,
                                  onReferenceChanged: cubit.setPaymentReference,
                                  onTransferredAtChanged:
                                      cubit.setTransferredAt,
                                  onProofSelected: cubit.setProofImage,
                                  onClearProof: cubit.clearProofImage,
                                  onSubmit: cubit.submitPaymentProof,
                                  onBack: () {
                                    if (state.isResubmit) {
                                      context.pop();
                                    } else {
                                      cubit.previousStep();
                                    }
                                  },
                                ),
                                TopUpStep.pendingReview =>
                                  PendingSuccessStepWidget(
                                    key: const ValueKey('pending_step'),
                                    points: state.amount,
                                    amountEgp: state.expectedAmountEgp,
                                    publicId:
                                        state.submittedPublicId ??
                                        state.createdPublicId,
                                    isResubmit: state.isResubmit,
                                    onReturnToWallet: () {
                                      if (context.canPop()) {
                                        context.pop(true);
                                      } else {
                                        context.go('/wallet');
                                      }
                                    },
                                  ),
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
          );
        },
      ),
    );
  }
}
