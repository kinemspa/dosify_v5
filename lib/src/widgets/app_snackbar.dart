import 'dart:async';

import 'package:dosifi_v5/src/core/design_system.dart';
import 'package:flutter/material.dart';

OverlayEntry? _activeSnackBarEntry;
Timer? _activeSnackBarTimer;

void clearAppSnackBars() {
  _activeSnackBarTimer?.cancel();
  _activeSnackBarTimer = null;

  _activeSnackBarEntry?.remove();
  _activeSnackBarEntry = null;
}

void showAppSnackBar(
  BuildContext context,
  String message, {
  Duration duration = kAppSnackBarDuration,
  String? actionLabel,
  VoidCallback? onAction,
}) {
  final overlay =
      Overlay.maybeOf(context, rootOverlay: true) ??
      Navigator.maybeOf(context, rootNavigator: true)?.overlay;
  if (overlay == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: appSnackBarTextStyle(context)),
        backgroundColor: kAppSnackBarBackgroundColor,
        behavior: SnackBarBehavior.fixed,
      ),
    );
    return;
  }

  clearAppSnackBars();

  final entry = OverlayEntry(
    builder: (context) {
      return Positioned(
        bottom: 0,
        left: 0,
        right: 0,
        child: SafeArea(
          top: false,
          child: Padding(
            padding: kAppSnackBarOuterPadding,
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Material(
                color: kAppSnackBarBackgroundColor,
                borderRadius: BorderRadius.circular(kBorderRadiusMedium),
                child: Padding(
                  padding: kAppSnackBarInnerPadding,
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          message,
                          style: appSnackBarTextStyle(context),
                        ),
                      ),
                      if (actionLabel != null && onAction != null) ...[
                        const SizedBox(width: kSpacingS),
                        TextButton(
                          style: TextButton.styleFrom(
                            padding: kTightTextButtonPadding,
                            foregroundColor: kAppSnackBarForegroundColor,
                          ),
                          onPressed: () {
                            clearAppSnackBars();
                            onAction();
                          },
                          child: Text(actionLabel),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    },
  );

  overlay.insert(entry);
  _activeSnackBarEntry = entry;
  _activeSnackBarTimer = Timer(duration, () {
    if (_activeSnackBarEntry == entry) {
      clearAppSnackBars();
    } else {
      entry.remove();
    }
  });
}
