import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../widgets/profile_avatar.dart';
import 'resource_screen_widgets.dart';

enum LearnLibraryFilter { forYou, short, audio, offline, saved }

class LearnLibraryScreen extends StatefulWidget {
  const LearnLibraryScreen({
    required this.isSpanish,
    this.filter = LearnLibraryFilter.forYou,
    this.heroSaved = false,
    this.onFilterChanged,
    this.onHeroSavedChanged,
    this.onBack,
    this.onOpenSettings,
    this.profileIdentity = const ProfileIdentity(),
    required this.onOpenHome,
    required this.onOpenPlan,
    required this.onOpenProgress,
    required this.onOpenSupport,
    super.key,
  });

  final bool isSpanish;
  final LearnLibraryFilter filter;
  final bool heroSaved;
  final ValueChanged<LearnLibraryFilter>? onFilterChanged;
  final ValueChanged<bool>? onHeroSavedChanged;
  final VoidCallback? onBack;
  final VoidCallback? onOpenSettings;
  final ProfileIdentity profileIdentity;
  final VoidCallback onOpenHome;
  final VoidCallback onOpenPlan;
  final VoidCallback onOpenProgress;
  final VoidCallback onOpenSupport;

  @override
  State<LearnLibraryScreen> createState() => _LearnLibraryScreenState();
}

class _LearnLibraryScreenState extends State<LearnLibraryScreen> {
  final _searchController = TextEditingController();

  late LearnLibraryFilter _activeFilter;
  late bool _heroSaved;

  String t(String english, String spanish) =>
      localized(widget.isSpanish, english, spanish);

  @override
  void initState() {
    super.initState();
    _activeFilter = widget.filter;
    _heroSaved = widget.heroSaved;
  }

  @override
  void didUpdateWidget(covariant LearnLibraryScreen oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.filter != oldWidget.filter) {
      _activeFilter = widget.filter;
    }

    if (widget.heroSaved != oldWidget.heroSaved) {
      _heroSaved = widget.heroSaved;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openLesson(String title) {
    showResourceInformation(
      context,
      title: title,
      body: t(
        'This clinically reviewed lesson uses plain language and includes a transcript. Educational content supports—but does not replace—care from a qualified professional.',
        'Esta lección revisada clínicamente usa lenguaje claro e incluye una transcripción. El contenido educativo apoya, pero no reemplaza, la atención de un profesional calificado.',
      ),
      closeLabel: t('Done', 'Listo'),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textScale = MediaQuery.textScalerOf(context).scale(1).clamp(1, 2);
    final topicCardHeight = 154.0 + ((textScale - 1) * 32);
    final query = _searchController.text.trim().toLowerCase();
    final topics = <({String title, String subtitle, IconData icon})>[
      (
        title: t('Cravings', 'Antojos'),
        subtitle: t('8 short lessons', '8 lecciones cortas'),
        icon: Icons.waves_rounded,
      ),
      (
        title: t('Withdrawal', 'Abstinencia'),
        subtitle: t('What to expect', 'Qué esperar'),
        icon: Icons.air_rounded,
      ),
      (
        title: t('Medicines', 'Medicamentos'),
        subtitle: t('Education only', 'Solo educación'),
        icon: Icons.medication_outlined,
      ),
      (
        title: t('Slip recovery', 'Recuperación tras un desliz'),
        subtitle: t('Return without blame', 'Regresa sin culpa'),
        icon: Icons.replay_rounded,
      ),
      (
        title: t('Stress & mood', 'Estrés y ánimo'),
        subtitle: t('Coping skills', 'Habilidades para afrontarlo'),
        icon: Icons.favorite_outline_rounded,
      ),
      (
        title: t('Support', 'Apoyo'),
        subtitle: t('People & quitlines', 'Personas y líneas de ayuda'),
        icon: Icons.support_agent_rounded,
      ),
    ]
        .where(
          (topic) =>
              query.isEmpty ||
              '${topic.title} ${topic.subtitle}'.toLowerCase().contains(
                    query,
                  ),
        )
        .toList();

    return Scaffold(
      key: const ValueKey('learn-library-screen'),
      backgroundColor: AppColors.cream,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            ResourcePageHeader(
              title: t('Learn', 'Aprende'),
              subtitle: t(
                'Short, reviewed lessons for where you are today.',
                'Lecciones breves y revisadas para tu momento actual.',
              ),
              onBack: widget.onBack,
              backSemanticLabel: t('Go back', 'Volver'),
              actions: [
                IconButton(
                  key: const ValueKey('learn-save-hero'),
                  tooltip: t(
                    'Save featured lesson',
                    'Guardar lección destacada',
                  ),
                  onPressed: () {
                    final nextValue = !_heroSaved;
                    setState(() => _heroSaved = nextValue);
                    widget.onHeroSavedChanged?.call(nextValue);
                  },
                  icon: Icon(
                    _heroSaved
                        ? Icons.bookmark_rounded
                        : Icons.bookmark_border_rounded,
                  ),
                ),
                IconButton(
                  key: const ValueKey('learn-open-settings'),
                  tooltip: t(
                    'Settings and privacy',
                    'Configuración y privacidad',
                  ),
                  onPressed: widget.onOpenSettings,
                  icon: ProfileAvatar(identity: widget.profileIdentity),
                ),
              ],
            ),
            Expanded(
              child: SingleChildScrollView(
                key: const ValueKey('learn-library-scroll'),
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SearchBar(
                      key: const ValueKey('learn-search'),
                      controller: _searchController,
                      hintText: t(
                        'Search cravings, sleep, medicines, support…',
                        'Busca antojos, sueño, medicamentos, apoyo…',
                      ),
                      leading: const Icon(Icons.search_rounded),
                      trailing: [
                        Text(
                          'EN · ES',
                          style:
                              Theme.of(context).textTheme.labelMedium?.copyWith(
                                    color: AppColors.tealSecondary,
                                    fontWeight: FontWeight.w700,
                                  ),
                        ),
                        const SizedBox(width: 12),
                      ],
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 12),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: LearnLibraryFilter.values.map((filter) {
                          final labels = {
                            LearnLibraryFilter.forYou: t('For you', 'Para ti'),
                            LearnLibraryFilter.short: t('2–5 min', '2–5 min'),
                            LearnLibraryFilter.audio: t('Audio', 'Audio'),
                            LearnLibraryFilter.offline: t(
                              'Offline',
                              'Sin conexión',
                            ),
                            LearnLibraryFilter.saved: t('Saved', 'Guardado'),
                          };
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              key: ValueKey('learn-filter-${filter.name}'),
                              label: Text(labels[filter]!),
                              selected: _activeFilter == filter,
                              onSelected: (_) {
                                setState(() => _activeFilter = filter);
                                widget.onFilterChanged?.call(filter);
                              },
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 14),
                    ResourceCard(
                      key: const ValueKey('learn-featured-lesson'),
                      color: AppColors.deepTeal,
                      onTap: () => _openLesson(
                        t(
                          'Cravings: what to expect today',
                          'Antojos: qué esperar hoy',
                        ),
                      ),
                      semanticLabel: t(
                        'Start featured lesson',
                        'Iniciar lección destacada',
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            t('FOR YOUR QUIT DAY', 'PARA TU DÍA DE DEJARLO'),
                            style: const TextStyle(
                              color: AppColors.lime,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            t(
                              'Cravings: what to expect today',
                              'Antojos: qué esperar hoy',
                            ),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 27,
                              height: 1.05,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            t(
                              'Recognize common urges and choose a plan before they build.',
                              'Reconoce los impulsos comunes y elige un plan antes de que aumenten.',
                            ),
                            style: const TextStyle(
                              color: AppColors.mintStrong,
                              fontSize: 14,
                              height: 1.35,
                            ),
                          ),
                          const SizedBox(height: 14),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _HeroTag(t('4 min read', '4 min de lectura')),
                              _HeroTag(t('3:12 audio', 'audio 3:12')),
                              _HeroTag(t('Plain language', 'Lenguaje claro')),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.paper,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              children: [
                                const CircleAvatar(
                                  backgroundColor: AppColors.deepTeal,
                                  foregroundColor: AppColors.lime,
                                  child: Icon(Icons.play_arrow_rounded),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    t('Start lesson', 'Iniciar lección'),
                                    style: const TextStyle(
                                      color: AppColors.deepTeal,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                                Flexible(
                                  child: Text(
                                    t(
                                      'Transcript included',
                                      'Incluye transcripción',
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    textAlign: TextAlign.end,
                                    style: const TextStyle(
                                      color: AppColors.mutedTeal,
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    SectionTitle(t('Continue learning', 'Seguir aprendiendo')),
                    const SizedBox(height: 8),
                    ResourceCard(
                      key: const ValueKey('learn-resume-lesson'),
                      onTap: () => _openLesson(
                        t(
                          'Know your stress triggers',
                          'Conoce tus desencadenantes de estrés',
                        ),
                      ),
                      child: Row(
                        children: [
                          const CircleAvatar(
                            backgroundColor: AppColors.mint,
                            radius: 28,
                            child: Icon(
                              Icons.auto_awesome_rounded,
                              color: AppColors.deepTeal,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  t(
                                    'TRIGGERS · 2 OF 4',
                                    'DESENCADENANTES · 2 DE 4',
                                  ),
                                  style: const TextStyle(
                                    color: AppColors.mutedTeal,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 1,
                                  ),
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  t(
                                    'Know your stress triggers',
                                    'Conoce tus desencadenantes de estrés',
                                  ),
                                  style: const TextStyle(
                                    color: AppColors.deepTeal,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                const LinearProgressIndicator(
                                  value: .6,
                                  color: AppColors.coral,
                                  backgroundColor: Color(0xFFDCE6E0),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (textScale > 1.3)
                            const Icon(
                              Icons.chevron_right_rounded,
                              color: AppColors.deepTeal,
                            )
                          else
                            Text(
                              t('Resume', 'Continuar'),
                              style: const TextStyle(
                                color: AppColors.deepTeal,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    SectionTitle(t('Browse topics', 'Explorar temas')),
                    const SizedBox(height: 8),
                    if (topics.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        child: Center(
                          child: Text(
                            t(
                              'No lessons match that search.',
                              'Ninguna lección coincide con esa búsqueda.',
                            ),
                          ),
                        ),
                      )
                    else
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: topics.length,
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: textScale > 1.3 ? 1 : 2,
                          mainAxisExtent: topicCardHeight,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                        ),
                        itemBuilder: (context, index) {
                          final topic = topics[index];
                          return ResourceCard(
                            key: ValueKey('learn-topic-$index'),
                            padding: const EdgeInsets.all(13),
                            onTap: () => _openLesson(topic.title),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  topic.icon,
                                  color: index.isEven
                                      ? AppColors.coral
                                      : AppColors.deepTeal,
                                ),
                                const Spacer(),
                                Text(
                                  topic.title,
                                  maxLines: 2,
                                  style: const TextStyle(
                                    color: AppColors.deepTeal,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                Text(
                                  topic.subtitle,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: AppColors.mutedTeal,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    const SizedBox(height: 14),
                    ResourceCard(
                      color: AppColors.mint,
                      child: Row(
                        children: [
                          const Icon(
                            Icons.offline_pin_rounded,
                            color: AppColors.deepTeal,
                            size: 32,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              t(
                                '3 lessons saved offline\nAudio, text and transcripts remain available.',
                                '3 lecciones guardadas sin conexión\nAudio, texto y transcripciones disponibles.',
                              ),
                              style: const TextStyle(
                                color: AppColors.deepTeal,
                                height: 1.35,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: ResourceBottomNavigation(
        selectedIndex: 3,
        isSpanish: widget.isSpanish,
        onHome: widget.onOpenHome,
        onPlan: widget.onOpenPlan,
        onProgress: widget.onOpenProgress,
        onLearn: () {},
        onSupport: widget.onOpenSupport,
      ),
    );
  }
}

class _HeroTag extends StatelessWidget {
  const _HeroTag(this.label);
  final String label;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFF234E48),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF557D75)),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
}
