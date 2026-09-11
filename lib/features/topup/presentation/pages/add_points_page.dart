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
import '../cubit/topup_cubit.dart';
import '../cubit/topup_state.dart';
import '../widgets/amount_step_widget.dart';
import '../widgets/payment_method_step_widget.dart';
import '../widgets/pending_success_step_widget.dart';
import '../widgets/review_step_widget.dart';
import '../widgets/topup_step_indicator.dart';
import '../widgets/transfer_details_step_widget.dart';

class AddPointsPage extends StatelessWidget {
  final TopUpCubit? topUpCubit;

  const AddPointsPage({
    super.key,
    this.topUpCubit,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return BlocProvider(
      create: (context) => topUpCubit ?? (getIt<TopUpCubit>()..loadPaymentMethods()),
      child: BlocConsumer<TopUpCubit, TopUpState>(
        listener: (context, state) {
          if (state.errorMessage != null && state.errorMessage!.isNotEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.errorMessage!),
                backgroundColor: AppColors.error,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            );
          }
        },
        builder: (context, state) {
          final cubit = context.read<TopUpCubit>();

          return AppScaffold(
            appBar: AppBar(
              title: Text(l10n.addPoints),
              centerTitle: true,
              leading: state.currentStep == TopUpStep.pendingSuccess
                  ? const SizedBox.shrink()
                  : IconButton(
                      icon: const Icon(AppIcons.arrowBack),
                      onPressed: () {
                        if (state.currentStep == TopUpStep.amount) {
                          context.pop();
                        } else {
                          cubit.previousStep();
                        }
                      },
                    ),
            ),
            body: state.isLoadingMethods
                ? const Center(child: AppLoading())
                : SafeArea(
                    child: Padding(
                      padding: AppSpacing.edgeInsetsA16,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (state.currentStep != TopUpStep.pendingSuccess) ...[
                            TopUpStepIndicator(currentStep: state.currentStep),
                            AppSpacing.gapH20,
                          ],
                          Expanded(
                            child: switch (state.currentStep) {
                              TopUpStep.amount => AmountStepWidget(
                                  initialAmount: state.amount,
                                  onAmountChanged: cubit.setAmount,
                                  onNext: cubit.nextStep,
                                ),
                              TopUpStep.paymentMethod => PaymentMethodStepWidget(
                                  methods: state.paymentMethods,
                                  selectedMethod: state.selectedMethod,
                                  onMethodSelected: cubit.selectPaymentMethod,
                                  onNext: cubit.nextStep,
                                  onBack: cubit.previousStep,
                                ),
                              TopUpStep.transferDetails => TransferDetailsStepWidget(
                                  initialReference: state.paymentReference,
                                  proofBytes: state.proofBytes,
                                  proofFileName: state.proofFileName,
                                  onReferenceChanged: cubit.setPaymentReference,
                                  onProofSelected: cubit.setProofImage,
                                  onClearProof: cubit.clearProofImage,
                                  onNext: cubit.nextStep,
                                  onBack: cubit.previousStep,
                                ),
                              TopUpStep.review => ReviewStepWidget(
                                  amount: state.amount,
                                  method: state.selectedMethod!,
                                  reference: state.paymentReference,
                                  proofBytes: state.proofBytes!,
                                  isSubmitting: state.isSubmitting,
                                  onSubmit: cubit.submitTopUpRequest,
                                  onBack: cubit.previousStep,
                                ),
                              TopUpStep.pendingSuccess => PendingSuccessStepWidget(
                                  requestId: state.submittedRequestId,
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
