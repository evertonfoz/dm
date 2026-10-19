import 'package:flutter/material.dart';

import '../../../../app/common/external_links.dart';
import '../../../../app/common/widgets/status_message.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_layout.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../domain/entities/establishment.dart';
import '../../domain/entities/establishment_details.dart';
import '../../domain/repositories/establishment_repository.dart';
import '../establishment_hero_tag.dart';
import '../widgets/contact_actions.dart';
import '../widgets/details_loading.dart';
import '../widgets/details_section.dart';
import '../widgets/establishment_logo.dart';
import '../widgets/establishment_summary.dart';
import '../widgets/open_status.dart';
import '../widgets/opening_hours_table.dart';
import '../widgets/photo_carousel.dart';
import '../widgets/safety_practices_list.dart';

class EstablishmentDetailsPage extends StatefulWidget {
  const EstablishmentDetailsPage({
    super.key,
    required this.establishment,
    required this.repository,
  });

  final Establishment establishment;
  final EstablishmentRepository repository;

  @override
  State<EstablishmentDetailsPage> createState() =>
      _EstablishmentDetailsPageState();
}

class _EstablishmentDetailsPageState extends State<EstablishmentDetailsPage> {
  late Future<EstablishmentDetails?> _detailsFuture;

  @override
  void initState() {
    super.initState();
    _detailsFuture = widget.repository.fetchDetails(widget.establishment.id);
  }

  void _reload() {
    setState(() {
      _detailsFuture = widget.repository.fetchDetails(widget.establishment.id);
    });
  }

  Future<void> _open(Uri uri, String failureMessage) async {
    final opened = await openExternal(uri);
    if (!opened && mounted) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(failureMessage)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final horizontalPadding = AppLayout.horizontalPadding(
      MediaQuery.sizeOf(context).width,
    );

    return Scaffold(
      appBar: AppBar(
        actions: [
          Padding(
            padding: EdgeInsets.only(right: horizontalPadding),
            child: Hero(
              tag: establishmentHeroTag(widget.establishment.id),
              child: EstablishmentLogo(
                establishment: widget.establishment,
                size: 40,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          horizontalPadding,
          AppSpacing.sm,
          horizontalPadding,
          AppSpacing.xl,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            EstablishmentSummary(establishment: widget.establishment),
            const SizedBox(height: AppSpacing.lg),
            _buildDetails(),
          ],
        ),
      ),
    );
  }

  Widget _buildDetails() {
    return FutureBuilder<EstablishmentDetails?>(
      future: _detailsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const DetailsLoading();
        }

        if (snapshot.hasError) {
          return StatusMessage(
            icon: Icons.cloud_off_outlined,
            message: 'Não foi possível carregar as informações deste lugar.',
            actionLabel: 'Tentar novamente',
            onAction: _reload,
          );
        }

        final details = snapshot.data;

        if (details == null) {
          return StatusMessage(
            icon: Icons.storefront_outlined,
            message: 'As informações deste lugar não estão mais disponíveis.',
            actionLabel: 'Voltar',
            onAction: () => Navigator.of(context).pop(),
          );
        }

        return _buildContent(details);
      },
    );
  }

  Widget _buildContent(EstablishmentDetails details) {
    final now = DateTime.now();
    final phone = details.phone;
    final textStyle = Theme.of(context).textTheme.bodyMedium
        ?.copyWith(color: AppColors.navy, height: 1.4);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (details.photos.isNotEmpty) ...[
          PhotoCarousel(photos: details.photos),
          const SizedBox(height: AppSpacing.lg),
        ],
        OpenStatus(details: details, now: now),
        const SizedBox(height: AppSpacing.md),
        ContactActions(
          onDirections: () =>
              _open(mapsUri(details.address), 'Não foi possível abrir o mapa.'),
          onCall: phone == null
              ? null
              : () => _open(
                  phoneUri(phone),
                  'Não foi possível iniciar a ligação.',
                ),
        ),
        const SizedBox(height: AppSpacing.xl),
        DetailsSection(
          title: 'Cuidados com contaminação cruzada',
          child: SafetyPracticesList(practices: details.safetyPractices),
        ),
        const SizedBox(height: AppSpacing.lg),
        DetailsSection(
          title: 'Sobre',
          child: Text(details.description, style: textStyle),
        ),
        const SizedBox(height: AppSpacing.lg),
        DetailsSection(
          title: 'Horários',
          child: OpeningHoursTable(details: details, today: now.weekday),
        ),
        const SizedBox(height: AppSpacing.lg),
        DetailsSection(
          title: 'Endereço e telefone',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _InfoLine(icon: Icons.place_outlined, text: details.address),
              if (phone != null) ...[
                const SizedBox(height: AppSpacing.sm),
                _InfoLine(icon: Icons.call_outlined, text: phone),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _InfoLine extends StatelessWidget {
  const _InfoLine({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: AppColors.navy),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodyMedium
                ?.copyWith(color: AppColors.navy),
          ),
        ),
      ],
    );
  }
}
