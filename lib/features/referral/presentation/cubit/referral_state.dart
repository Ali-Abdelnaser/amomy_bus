import 'package:equatable/equatable.dart';
import '../../domain/entities/referral_entities.dart';

enum ReferralStatus { initial, loading, loaded, error }

enum ReferralPreviewStatus { initial, loading, success, error }

enum ReferralBindStatus { initial, loading, success, error }

class ReferralState extends Equatable {
  final ReferralStatus status;
  final ReferralDashboard? dashboard;
  final String? errorMessage;

  final ReferralPreviewStatus previewStatus;
  final ReferralCodePreview? preview;
  final String? previewError;

  final ReferralBindStatus bindStatus;
  final BindReferralResult? bindResult;
  final String? bindError;

  const ReferralState({
    this.status = ReferralStatus.initial,
    this.dashboard,
    this.errorMessage,
    this.previewStatus = ReferralPreviewStatus.initial,
    this.preview,
    this.previewError,
    this.bindStatus = ReferralBindStatus.initial,
    this.bindResult,
    this.bindError,
  });

  bool get isLoading => status == ReferralStatus.loading;
  bool get isPreviewLoading => previewStatus == ReferralPreviewStatus.loading;
  bool get isBindLoading => bindStatus == ReferralBindStatus.loading;
  bool get isProgramDisabled =>
      dashboard != null && !dashboard!.program.enabled;

  ReferralState copyWith({
    ReferralStatus? status,
    ReferralDashboard? dashboard,
    String? errorMessage,
    ReferralPreviewStatus? previewStatus,
    ReferralCodePreview? preview,
    String? previewError,
    ReferralBindStatus? bindStatus,
    BindReferralResult? bindResult,
    String? bindError,
    bool clearPreview = false,
    bool clearBind = false,
  }) {
    return ReferralState(
      status: status ?? this.status,
      dashboard: dashboard ?? this.dashboard,
      errorMessage: errorMessage ?? this.errorMessage,
      previewStatus: clearPreview
          ? ReferralPreviewStatus.initial
          : (previewStatus ?? this.previewStatus),
      preview: clearPreview ? null : (preview ?? this.preview),
      previewError: clearPreview ? null : (previewError ?? this.previewError),
      bindStatus: clearBind
          ? ReferralBindStatus.initial
          : (bindStatus ?? this.bindStatus),
      bindResult: clearBind ? null : (bindResult ?? this.bindResult),
      bindError: clearBind ? null : (bindError ?? this.bindError),
    );
  }

  @override
  List<Object?> get props => [
    status,
    dashboard,
    errorMessage,
    previewStatus,
    preview,
    previewError,
    bindStatus,
    bindResult,
    bindError,
  ];
}
