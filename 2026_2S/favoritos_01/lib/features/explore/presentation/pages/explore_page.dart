import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../app/widgets/common/status_message.dart';
import '../../../establishments/domain/entities/establishment.dart';
import '../../../establishments/presentation/pages/establishment_details_page.dart';
import '../../../establishments/presentation/widgets/establishment_card.dart';
import '../../../favorites/presentation/favorites_controller.dart';
import '../../../favorites/presentation/functions/toggle_favorite.dart';
import '../../domain/explore_query.dart';
import '../explore_controller.dart';
import '../widgets/explore_filter_chips.dart';
import '../widgets/explore_results_bar.dart';
import '../widgets/explore_search_field.dart';

class ExplorePage extends StatefulWidget {
  const ExplorePage({super.key});

  @override
  State<ExplorePage> createState() => _ExplorePageState();
}

class _ExplorePageState extends State<ExplorePage> {
  static const double _padding = 16;

  @override
  void initState() {
    super.initState();
    // read: é uma ação, não uma leitura que redesenha a tela.
    context.read<ExploreController>().load();
  }

  void _openDetails(Establishment establishment) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => EstablishmentDetailsPage(establishment: establishment),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // watch: qualquer fonte que notificar reconstrói a tela.
    final explore = context.watch<ExploreController>();
    final favorites = context.watch<FavoritesController>();

    return Scaffold(
      appBar: AppBar(title: const Text('Explorar')),
      // switch exaustivo: o compilador avisa se faltar um estado.
      body: switch (explore.status) {
        ExploreStatus.loading => const Center(
          child: CircularProgressIndicator(),
        ),
        ExploreStatus.failure => StatusMessage(
          icon: Icons.cloud_off_outlined,
          message: 'Não foi possível carregar os estabelecimentos.',
          actionLabel: 'Tentar novamente',
          onAction: explore.retry,
        ),
        ExploreStatus.ready => _buildReady(explore, favorites),
      },
    );
  }

  Widget _buildReady(ExploreController explore, FavoritesController favorites) {
    final filters = explore.filters;
    // Estado derivado: nada disto é guardado, tudo é recalculado a cada build
    // a partir de duas fontes (catálogo + filtros) e dos favoritos.
    final results = applyExploreFilters(
      explore.catalog,
      filters,
      favoriteIds: {for (final f in favorites.favorites) f.establishmentId},
    );

    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(_padding, 8, _padding, 8),
          sliver: SliverList.list(
            children: [
              ExploreSearchField(
                query: filters.query,
                onChanged: explore.setQuery,
              ),
              const SizedBox(height: 16),
              ExploreFilterChips(
                filters: filters,
                onCategoryToggle: explore.toggleCategory,
                onDietaryToggle: explore.toggleDietaryOption,
                onFavoritesChanged: explore.setOnlyFavorites,
              ),
              const SizedBox(height: 16),
              ExploreResultsBar(
                count: results.length,
                sort: filters.sort,
                onSortChanged: explore.setSort,
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
        if (results.isEmpty)
          SliverToBoxAdapter(
            child: StatusMessage(
              icon: Icons.search_off_outlined,
              message: 'Nenhum lugar combina com esses filtros.',
              // Só oferece a saída se houver algo para limpar.
              actionLabel: filters.hasActiveFilters ? 'Limpar filtros' : null,
              onAction: explore.clearFilters,
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.only(bottom: 24),
            sliver: SliverList.builder(
              itemCount: results.length,
              itemBuilder: (context, index) {
                final establishment = results[index];
                return EstablishmentCard(
                  establishment: establishment,
                  isFavorite: favorites.isFavorite(
                    establishment.establishmentId,
                  ),
                  onFavoriteToggle: () =>
                      toggleFavoriteWithFeedback(context, establishment),
                  onTap: () => _openDetails(establishment),
                );
              },
            ),
          ),
      ],
    );
  }
}
