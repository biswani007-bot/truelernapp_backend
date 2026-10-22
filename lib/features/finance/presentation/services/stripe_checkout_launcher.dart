import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../domain/entities/stripe_checkout_entity.dart';
import '../screens/stripe_checkout_screen.dart';

/// Service coordinating the opening of Stripe Checkout sessions
/// via external browser or approved in-app payment presentation.
class StripeCheckoutLauncher {
  const StripeCheckoutLauncher();

  /// Opens the Stripe Checkout session in an external browser.
  ///
  /// Returns `true` if successfully launched.
  Future<bool> launchExternalBrowser(String checkoutUrl) async {
    if (!isValidStripeCheckoutUrl(checkoutUrl)) {
      throw ArgumentError(
        'Untrusted checkout destination URL. Must be an official HTTPS Stripe checkout URL.',
      );
    }

    final uri = Uri.parse(checkoutUrl.trim());
    if (await canLaunchUrl(uri)) {
      return await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
    }
    return false;
  }

  /// Opens the Stripe Checkout session in the approved in-app presentation screen.
  Future<CheckoutReturnResult> launchInAppPresentation(
    BuildContext context, {
    required String checkoutUrl,
    required String successUrlPrefix,
    required String cancelUrlPrefix,
  }) async {
    if (!isValidStripeCheckoutUrl(checkoutUrl)) {
      throw ArgumentError(
        'Untrusted checkout destination URL. Must be an official HTTPS Stripe checkout URL.',
      );
    }

    final result = await Navigator.of(context).push<CheckoutReturnResult>(
      MaterialPageRoute(
        builder: (ctx) => StripeCheckoutScreen(
          checkoutUrl: checkoutUrl,
          successUrlPrefix: successUrlPrefix,
          cancelUrlPrefix: cancelUrlPrefix,
        ),
      ),
    );

    return result ?? CheckoutReturnResult.closed;
  }
}
