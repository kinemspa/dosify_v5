import 'dart:async';

import 'package:skedux/src/core/design_system.dart';
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
  AppSnackBarTone? tone,
}) {
  final resolvedTone = tone ?? _inferSnackBarTone(message);
  final overlay =
      Overlay.maybeOf(context, rootOverlay: true) ??
      Navigator.maybeOf(context, rootNavigator: true)?.overlay;
  if (overlay == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: appSnackBarTextStyle(context, tone: resolvedTone),
        ),
        backgroundColor: snackBarBackgroundColor(context, tone: resolvedTone),
        behavior: SnackBarBehavior.fixed,
      ),
    );
    return;
  }

  clearAppSnackBars();

  final entry = OverlayEntry(
    builder: (context) {
      final mediaQuery = MediaQuery.maybeOf(context);
      final safeTop = mediaQuery?.padding.top ?? 0;
      final topOffset = safeTop + kAppSnackBarTopOffsetBelowHeader;

      return Positioned(
        top: topOffset,
        left: 0,
        right: 0,
        child: Padding(
          padding: kAppSnackBarOuterPadding,
          child: Align(
            alignment: Alignment.topCenter,
            child: Material(
              color: snackBarBackgroundColor(context, tone: resolvedTone),
              borderRadius: kAppSnackBarBorderRadius,
              child: Padding(
                padding: kAppSnackBarInnerPadding,
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        message,
                        style: appSnackBarTextStyle(
                          context,
                          tone: resolvedTone,
                        ),
                      ),
                    ),
                    if (actionLabel != null && onAction != null) ...[
                      const SizedBox(width: kSpacingS),
                      TextButton(
                        style: TextButton.styleFrom(
                          padding: kTightTextButtonPadding,
                          foregroundColor: snackBarForegroundColor(
                            context,
                            tone: resolvedTone,
                          ),
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

AppSnackBarTone _inferSnackBarTone(String message) {
  final normalized = message.trim().toLowerCase();

  const errorKeywords = <String>[
    'error',
    'failed',
    'failure',
    'denied',
    'invalid',
    'unable',
    'could not',
  ];
  const warningKeywords = <String>[
    'warning',
    'no ',
    'not found',
    'empty',
    'missing',
    'disabled',
    'snoozed',
    'skipped',
  ];
  const successKeywords = <String>[
    'saved',
    'added',
    'removed',
    'deleted',
    'updated',
    'recorded',
    'restored',
    'exported',
    'queued',
    'opened',
    'sent',
    'marked',
    'loaded',
    'granted',
  ];

  if (errorKeywords.any(normalized.contains)) {
    return AppSnackBarTone.error;
  }
  if (warningKeywords.any(normalized.contains)) {
    return AppSnackBarTone.warning;
  }
  if (successKeywords.any(normalized.contains)) {
    return AppSnackBarTone.success;
  }
  return AppSnackBarTone.neutral;
}
