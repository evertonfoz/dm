import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../app/theme/app_spacing.dart';
import '../../../establishments/domain/establishment.dart';
import '../../../establishments/domain/establishment_repository.dart';
import '../../../establishments/presentation/widgets/establishment_card.dart';
import '../greeting.dart';
import '../widgets/category_shortcuts.dart';
import '../widgets/home_header.dart';
import '../widgets/nearby_states.dart';
import '../widgets/profile_prompt_card.dart';
import '../widgets/search_entry.dart';
import '../widgets/section_header.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.repository});

  final EstablishmentRepository repository;

  static const double maxContentWidth = 600;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late Future<List<Establishment>> _nearbyFuture;

  @override
  void initState() {
    super.initState();
    _nearbyFuture = widget.repository.fetchNearby();
  }

  void _reload() {
    setState(() {
      _nearbyFuture = widget.repository.fetchNearby();
    });
  }

  Future<void> _refresh() async {
    _reload();
    try {
      await _nearbyFuture;
    } catch (_) {
      // O erro já é exibido pelo FutureBuilder.
    }
  }

  void _showComingSoon(String feature) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text('$feature estará disponível em breve.')),
      );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final horizontalPadding = math.max(
      AppSpacing.lg,
      (screenWidth - HomePage.maxContentWidth) / 2,
    );

    return RefreshIndicator(
      onRefresh: _refresh,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverAppBar(
            pinned: true,
            title: Row(
              children: [
                Image.asset(
                  'assets/images/brand/logo_celilac.png',
                  height: 32,
                  excludeFromSemantics: true,
                ),
                const SizedBox(width: AppSpacing.sm),
                const Text(
                  'CeliLac',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          SliverPadding(
            padding: EdgeInsets.fromLTRB(
              horizontalPadding,
              AppSpacing.sm,
              horizontalPadding,
              0,
            ),
            sliver: SliverList.list(
              children: [
                HomeHeader(greeting: greetingFor(DateTime.now())),
                const SizedBox(height: AppSpacing.lg),
                SearchEntry(onTap: () => _showComingSoon('A busca')),
                const SizedBox(height: AppSpacing.lg),
                ProfilePromptCard(
                  onPressed: () => _showComingSoon('O perfil alimentar'),
                ),
                const SizedBox(height: AppSpacing.xl),
                const SectionHeader(title: 'Categorias'),
                const SizedBox(height: AppSpacing.sm),
                CategoryShortcuts(
                  onSelected: (category) =>
                      _showComingSoon('A categoria ${category.label}'),
                ),
                const SizedBox(height: AppSpacing.lg),
                SectionHeader(
                  title: 'Perto de você',
                  actionLabel: 'Ver todos',
                  onAction: () => _showComingSoon('A lista completa'),
                ),
                const SizedBox(height: AppSpacing.sm),
              ],
            ),
          ),
          SliverPadding(
            padding: EdgeInsets.fromLTRB(
              horizontalPadding,
              0,
              horizontalPadding,
              AppSpacing.xl,
            ),
            sliver: _buildNearby(),
          ),
        ],
      ),
    );
  }

  Widget _buildNearby() {
    return FutureBuilder<List<Establishment>>(
      future: _nearbyFuture,
      builder: (context, snapshot) {
        final isLoading =
            snapshot.connectionState != ConnectionState.done &&
            !snapshot.hasData;

        if (isLoading) {
          return const SliverToBoxAdapter(child: NearbyLoading());
        }

        if (snapshot.hasError) {
          return SliverToBoxAdapter(
            child: NearbyMessage(
              icon: Icons.cloud_off_outlined,
              message: 'Não foi possível carregar os estabelecimentos.',
              actionLabel: 'Tentar novamente',
              onAction: _reload,
            ),
          );
        }

        final establishments = snapshot.data ?? const <Establishment>[];

        if (establishments.isEmpty) {
          return const SliverToBoxAdapter(
            child: NearbyMessage(
              icon: Icons.search_off_outlined,
              message: 'Ainda não encontramos opções perto de você.',
            ),
          );
        }

        return SliverList.separated(
          itemCount: establishments.length,
          itemBuilder: (context, index) {
            final establishment = establishments[index];
            return EstablishmentCard(
              establishment: establishment,
              onTap: () => _showComingSoon('O detalhe do estabelecimento'),
            );
          },
          separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
        );
      },
    );
  }
}
