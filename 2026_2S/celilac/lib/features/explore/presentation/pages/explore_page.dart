import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../app/common/widgets/status_message.dart';
import '../../../../app/theme/app_layout.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../establishments/domain/entities/establishment.dart';
import '../../../establishments/domain/repositories/establishment_repository.dart';
import '../../../establishments/presentation/pages/establishment_details_page.dart';
import '../../../establishments/presentation/widgets/establishment_card.dart';
import '../../../favorites/presentation/favorites_controller.dart';
import '../../../favorites/presentation/toggle_favorite.dart';
import '../../../profile/domain/entities/dietary_profile.dart';
import '../../../profile/domain/profile_match.dart';
import '../../../profile/presentation/profile_controller.dart';
import '../../domain/explore_query.dart';
import '../explore_controller.dart';
import '../widgets/explore_filter_chips.dart';
import '../widgets/explore_results_bar.dart';
import '../widgets/explore_search_field.dart';

class ExplorePage extends StatefulWidget {
  const ExplorePage({super.key, required this.repository});

  /// Usado só para abrir o detalhe; o catálogo vem do [ExploreController].
  final EstablishmentRepository repository;

  @override
  State<ExplorePage> createState() => _ExplorePageState();
}

class _ExplorePageState extends State<ExplorePage> {
  @override
  void initState() {
    super.initState();
    // read: é uma ação, não uma leitura que redesenha a tela.
    context.read<ExploreController>().load();
  }

  void _openDetails(Establishment establishment) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => EstablishmentDetailsPage(
          establishment: establishment,
          repository: widget.repository,
          heroOrigin: 'explore',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final explore = context.watch<ExploreController>();
    final profile = context.watch<ProfileController>().profile;
    final favorites = context.watch<FavoritesController>();
    final horizontalPadding = AppLayout.horizontalPadding(
      MediaQuery.sizeOf(context).width,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Explorar')),
      body: switch (explore.status) {
        ExploreStatus.loading => const Center(
          child: CircularProgressIndicator(),
        ),
        ExploreStatus.failure => Padding(
          padding: EdgeInsets.all(horizontalPadding),
          child: StatusMessage(
            icon: Icons.cloud_off_outlined,
            message: 'Não foi possível carregar os estabelecimentos.',
            actionLabel: 'Tentar novamente',
            onAction: explore.retry,
          ),
        ),
        ExploreStatus.ready => _buildReady(
          explore,
          profile,
          favorites,
          horizontalPadding,
        ),
      },
    );
  }

  Widget _buildReady(
    ExploreController explore,
    DietaryProfile profile,
    FavoritesController favorites,
    double horizontalPadding,
  ) {
    final filters = explore.filters;
    // Estado derivado: nada disto é guardado, tudo é recalculado a cada build
    // a partir de três fontes (catálogo, perfil e favoritos).
    final results = applyExploreFilters(
      explore.catalog,
      filters,
      profile: profile,
      favoriteIds: {for (final f in favorites.favorites) f.id},
    );

    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: EdgeInsets.fromLTRB(
            horizontalPadding,
            AppSpacing.sm,
            horizontalPadding,
            AppSpacing.sm,
          ),
          sliver: SliverList.list(
            children: [
              ExploreSearchField(
                query: filters.query,
                onChanged: explore.setQuery,
              ),
              const SizedBox(height: AppSpacing.md),
              ExploreFilterChips(
                filters: filters,
                showProfileFilter: profile.isComplete,
                onCategoryToggle: explore.toggleCategory,
                onDietaryToggle: explore.toggleDietaryOption,
                onProfileChanged: explore.setOnlyMatchingProfile,
                onFavoritesChanged: explore.setOnlyFavorites,
              ),
              const SizedBox(height: AppSpacing.md),
              ExploreResultsBar(
                count: results.length,
                sort: filters.sort,
                onSortChanged: explore.setSort,
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
          ),
        ),
        if (results.isEmpty)
          SliverPadding(
            padding: EdgeInsets.fromLTRB(
              horizontalPadding,
              0,
              horizontalPadding,
              AppSpacing.xl,
            ),
            sliver: SliverToBoxAdapter(
              child: StatusMessage(
                icon: Icons.search_off_outlined,
                message: 'Nenhum lugar combina com esses filtros.',
                actionLabel: filters.hasActiveFilters ? 'Limpar filtros' : null,
                onAction: explore.clearFilters,
              ),
            ),
          )
        else
          SliverPadding(
            padding: EdgeInsets.fromLTRB(
              horizontalPadding,
              0,
              horizontalPadding,
              AppSpacing.xl,
            ),
            sliver: SliverList.separated(
              itemCount: results.length,
              itemBuilder: (context, index) {
                final establishment = results[index];
                return EstablishmentCard(
                  establishment: establishment,
                  matchesProfile: meetsProfile(establishment, profile),
                  isFavorite: favorites.isFavorite(establishment.id),
                  heroOrigin: 'explore',
                  onFavoriteToggle: () =>
                      toggleFavoriteWithFeedback(context, establishment),
                  onTap: () => _openDetails(establishment),
                );
              },
              separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
            ),
          ),
      ],
    );
  }
}
