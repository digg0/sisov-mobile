import 'package:flutter/material.dart';
import 'package:google_sign_in_web/web_only.dart' as web;

Widget buildGoogleSignInButton({
  required VoidCallback onPressed,
  required bool enabled,
}) {
  if (!enabled) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: OutlinedButton(
        onPressed: null,
        child: const Text('Continuar com Google'),
      ),
    );
  }

  return SizedBox(
    width: double.infinity,
    height: 54,
    child: Center(
      child: web.renderButton(
        configuration: web.GSIButtonConfiguration(
          type: web.GSIButtonType.standard,
          theme: web.GSIButtonTheme.outline,
          size: web.GSIButtonSize.large,
          text: web.GSIButtonText.continueWith,
          shape: web.GSIButtonShape.rectangular,
          logoAlignment: web.GSIButtonLogoAlignment.left,
          minimumWidth: 300,
          locale: 'pt-BR',
        ),
      ),
    ),
  );
}
