import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../app/common/widgets/status_message.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_layout.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../establishments/data/fake_establishment_repository.dart';
import '../../../establishments/domain/entities/establishment.dart';
import '../../../establishments/domain/repositories/establishment_repository.dart';
import '../../../establishments/presentation/pages/establishment_details_page.dart';
import '../../../establishments/presentation/widgets/establishment_card.dart';
import '../../../profile/domain/profile_match.dart';
import '../../../profile/presentation/profile_controller.dart';
import '../favorites_controller.dart';
import '../toggle_favorite.dart';

class FavoritesPage extends StatelessWidget {
  const FavoritesPage({
    super.key,
    this.repository = const FakeEstablishmentRepository(),
    this.onExploreTap,
  });

  final EstablishmentRepository repository;
  final VoidCallback? onExploreTap;

  void _openDetails(BuildContext context, Establishment establishment) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => EstablishmentDetailsPage(
          establishment: establishment,
          repository: repository,
          heroOrigin: 'favorites',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final favoritesController = context.watch<FavoritesController>();
    final profile = context.watch<ProfileController>().profile;
    final favorites = favoritesController.favorites;
    final horizontalPadding = AppLayout.horizontalPadding(
      MediaQuery.sizeOf(context).width,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Favoritos')),
      body: !favoritesController.isLoaded
          ? const Center(child: CircularProgressIndicator())
          : favorites.isEmpty
          ? SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                AppSpacing.sm,
                horizontalPadding,
                AppSpacing.xl,
              ),
              child: StatusMessage(
                icon: Icons.favorite_border,
                message:
                    'Você ainda não salvou nenhum estabelecimento. '
                    'Toque no coração em um lugar para encontrá-lo rápido aqui.',
                actionLabel: onExploreTap != null
                    ? 'Ver estabelecimentos'
                    : null,
                onAction: onExploreTap,
              ),
            )
          : ListView(
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                AppSpacing.sm,
                horizontalPadding,
                AppSpacing.xl,
              ),
              children: [
                Text(
                  favorites.length == 1
                      ? '1 lugar salvo'
                      : '${favorites.length} lugares salvos',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.navy,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                for (var i = 0; i < favorites.length; i++) ...[
                  if (i > 0) const SizedBox(height: AppSpacing.md),
                  EstablishmentCard(
                    establishment: favorites[i],
                    matchesProfile: meetsProfile(favorites[i], profile),
                    isFavorite: true,
                    heroOrigin: 'favorites',
                    onFavoriteToggle: () =>
                        toggleFavoriteWithFeedback(context, favorites[i]),
                    onTap: () => _openDetails(context, favorites[i]),
                  ),
                ],
              ],
            ),
    );
  }
}
