import 'package:flutter/material.dart';

import '../../../../app/common/widgets/status_message.dart';
import '../../../../app/theme/app_layout.dart';
import '../../../../app/theme/app_spacing.dart';
import '../profile_scope.dart';
import '../widgets/profile_privacy_note.dart';
import '../widgets/profile_summary_card.dart';
import 'profile_form_page.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  void _openForm(BuildContext context) {
    Navigator.of(context).push(ProfileFormPage.route());
  }

  @override
  Widget build(BuildContext context) {
    // of: a aba é reconstruída sempre que o perfil muda.
    final controller = ProfileScope.of(context);
    final profile = controller.profile;
    final horizontalPadding = AppLayout.horizontalPadding(
      MediaQuery.sizeOf(context).width,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Perfil')),
      body: !controller.isLoaded
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                AppSpacing.sm,
                horizontalPadding,
                AppSpacing.xl,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (profile.isComplete)
                    ProfileSummaryCard(
                      profile: profile,
                      onEdit: () => _openForm(context),
                    )
                  else
                    StatusMessage(
                      icon: Icons.tune,
                      message:
                          'Conte o que você precisa evitar '
                          'para personalizar o CeliLac.',
                      actionLabel: 'Completar perfil',
                      onAction: () => _openForm(context),
                    ),
                  const SizedBox(height: AppSpacing.lg),
                  const ProfilePrivacyNote(),
                ],
              ),
            ),
    );
  }
}
