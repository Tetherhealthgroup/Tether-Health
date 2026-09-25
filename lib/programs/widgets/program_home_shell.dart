// Shared home-screen shell for Tether Health program modules.
//
// Guarantees every program home includes:
// - a loading state,
// - an error state with retry,
// - an offline notice (modules are local-first),
// - Semantics labels on interactive elements,
// - the privacy footer and the Tether disclaimer.

import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../program.dart';

class ProgramHomeShell extends StatelessWidget {
  const ProgramHomeShell({
    required this.spec,
    required this.title,
    required this.isLoading,
    required this.errorMessage,
    required this.onRetry,
    required this.children,
    super.key,
  });

  final ProgramSpec spec;
  final String title;
  final bool isLoading;
  final String? errorMessage;
  final VoidCallback onRetry;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        backgroundColor: AppColors.cream,
        foregroundColor: AppColors.deepTeal,
        title: Semantics(
          header: true,
          child: Text(title),
        ),
      ),
      body: SafeArea(
        child: Builder(
          builder: (context) {
            if (isLoading) {
              return Center(
                child: Semantics(
                  label: 'Loading',
                  excludeSemantics: true,
                  child: const CircularProgressIndicator(),
                ),
              );
            }
            final error = errorMessage;
            if (error != null) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.error_outline_rounded,
                        color: AppColors.tealSecondary,
                        size: 40,
                      ),
                      const SizedBox(height: 12),
                      Semantics(
                        label: 'Something went wrong. $error',
                        excludeSemantics: true,
                        child: Text(
                          error,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: AppColors.deepTeal,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Semantics(
                        label: 'Try again',
                        button: true,
                        excludeSemantics: true,
                        child: FilledButton(
                          onPressed: onRetry,
                          child: const Text('Try again'),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }
            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              children: [
                const _OfflineNotice(),
                const SizedBox(height: 12),
                ...children,
                const SizedBox(height: 24),
                const _ProgramFooter(),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _OfflineNotice extends StatelessWidget {
  const _OfflineNotice();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: ProgramCopy.offlineNotice,
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.mint,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border),
        ),
        child: const Row(
          children: [
            Icon(
              Icons.wifi_off_rounded,
              color: AppColors.tealSecondary,
              size: 18,
            ),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                ProgramCopy.offlineNotice,
                style: TextStyle(
                  color: AppColors.tealSecondary,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProgramFooter extends StatelessWidget {
  const _ProgramFooter();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Semantics(
          label: 'Privacy. ${ProgramCopy.privacyFooter}',
          excludeSemantics: true,
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.lock_outline_rounded,
                color: AppColors.mutedTeal,
                size: 14,
              ),
              SizedBox(width: 6),
              Flexible(
                child: Text(
                  ProgramCopy.privacyFooter,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.mutedTeal,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Semantics(
          label: 'Medical disclaimer. ${ProgramCopy.disclaimer}',
          excludeSemantics: true,
          child: const Text(
            ProgramCopy.disclaimer,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.mutedTeal,
              fontSize: 11,
            ),
          ),
        ),
      ],
    );
  }
}
