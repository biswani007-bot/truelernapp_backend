/// Response model for GET /api/parent/security/password-prompt-status.
class PasswordPromptStatus {
  const PasswordPromptStatus({
    required this.showPrompt,
    required this.hasPassword,
    this.dismissedAt,
    required this.dontAskAgain,
    required this.cooldownActive,
    this.eligible,
    this.reason,
  });

  final bool showPrompt;
  final bool hasPassword;
  final String? dismissedAt;
  final bool dontAskAgain;
  final bool cooldownActive;
  final bool? eligible;
  final String? reason;

  factory PasswordPromptStatus.fromJson(Map<String, dynamic> json) {
    final payload = (json['data'] is Map<String, dynamic>)
        ? json['data'] as Map<String, dynamic>
        : json;

    final isEligible = payload['eligible'] == true;
    final hasPass = payload['hasPassword'] == true;
    final showPromptDirect = payload['showPrompt'] == true;

    return PasswordPromptStatus(
      showPrompt: showPromptDirect || (isEligible && !hasPass),
      hasPassword: hasPass,
      dismissedAt: payload['dismissedAt']?.toString(),
      dontAskAgain: payload['dontAskAgain'] == true,
      cooldownActive: payload['cooldownActive'] == true,
      eligible: payload['eligible'] as bool?,
      reason: payload['reason']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'showPrompt': showPrompt,
    'hasPassword': hasPassword,
    'dismissedAt': dismissedAt,
    'dontAskAgain': dontAskAgain,
    'cooldownActive': cooldownActive,
    if (eligible != null) 'eligible': eligible,
    if (reason != null) 'reason': reason,
  };
}
