import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../widgets/profile_avatar.dart';
import 'resource_screen_widgets.dart';

class SupportHubScreen extends StatelessWidget {
  const SupportHubScreen({
    required this.isSpanish,
    required this.onBack,
    required this.onOpenSettings,
    this.profileIdentity = const ProfileIdentity(),
    this.onCallQuitline,
    this.onRequestCallback,
    this.onInformation,
    required this.onOpenHome,
    required this.onOpenPlan,
    required this.onOpenProgress,
    required this.onOpenLearn,
    super.key,
  });

  final bool isSpanish;
  final VoidCallback onBack;
  final VoidCallback onOpenSettings;
  final ProfileIdentity profileIdentity;
  final VoidCallback? onCallQuitline;
  final VoidCallback? onRequestCallback;
  final ValueChanged<String>? onInformation;
  final VoidCallback onOpenHome;
  final VoidCallback onOpenPlan;
  final VoidCallback onOpenProgress;
  final VoidCallback onOpenLearn;

  String t(String english, String spanish) =>
      localized(isSpanish, english, spanish);

  void _showInfo(BuildContext context, String title, String body) {
    showResourceInformation(
      context,
      title: title,
      body: body,
      closeLabel: t('Done', 'Listo'),
    );
  }

  void _handleInformation(
    BuildContext context,
    String title, {
    String? body,
  }) {
    if (onInformation != null) {
      onInformation!(title);
      return;
    }

    _showInfo(
      context,
      title,
      body ??
          t(
            'This action is available here as a preview. A connected service can be added later without changing this screen.',
            'Esta acción está disponible aquí como vista previa. Se puede conectar un servicio más adelante sin cambiar esta pantalla.',
          ),
    );
  }

  void _handleCallQuitline(BuildContext context) {
    if (onCallQuitline != null) {
      onCallQuitline!();
      return;
    }

    _showInfo(
      context,
      t('Call the quitline', 'Llamar a la línea para dejar de fumar'),
      t(
        'Quitline number: 1-800-784-8669. Phone calling can be connected to the device dialer when the native calling integration is added.',
        'Número de la línea: 1-800-784-8669. La llamada puede conectarse al marcador del dispositivo cuando se agregue la integración nativa.',
      ),
    );
  }

  void _handleRequestCallback(BuildContext context) {
    if (onRequestCallback != null) {
      onRequestCallback!();
      return;
    }

    _showInfo(
      context,
      t('Request a call-back', 'Pedir una llamada'),
      t(
        'This opens the call-back request preview. Submitting a real referral can be connected when the support-service backend is added.',
        'Esto abre la vista previa para solicitar una llamada. El envío real puede conectarse cuando se agregue el servicio de apoyo.',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final usesLargeText = MediaQuery.textScalerOf(context).scale(1) > 1.3;
    return Scaffold(
      key: const ValueKey('functional-support-hub-screen'),
      backgroundColor: AppColors.cream,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            ResourcePageHeader(
              title: t('Support', 'Apoyo'),
              subtitle: t(
                'Choose a person or service that feels right.',
                'Elige una persona o servicio que te parezca adecuado.',
              ),
              onBack: onBack,
              backSemanticLabel: t('Go back', 'Volver'),
              actions: [
                IconButton(
                  key: const ValueKey('support-open-settings'),
                  tooltip: t(
                    'Settings and privacy',
                    'Configuración y privacidad',
                  ),
                  onPressed: onOpenSettings,
                  icon: ProfileAvatar(identity: profileIdentity),
                ),
              ],
            ),
            Expanded(
              child: SingleChildScrollView(
                key: const ValueKey('support-hub-scroll'),
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        key: const ValueKey('support-change-location'),
                        onPressed: () => _handleInformation(
                          context,
                          t('Change location', 'Cambiar ubicación'),
                          body: t(
                            'Location selection can be connected here when regional quitline routing is enabled.',
                            'La selección de ubicación se puede conectar aquí cuando se habilite el enrutamiento regional de la línea de ayuda.',
                          ),
                        ),
                        icon: const Icon(Icons.location_on_outlined, size: 18),
                        label: Text(t('Change location', 'Cambiar ubicación')),
                      ),
                    ),
                    ResourceCard(
                      key: const ValueKey('support-quitline-card'),
                      color: AppColors.deepTeal,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            t('FREE & CONFIDENTIAL', 'GRATIS Y CONFIDENCIAL'),
                            style: const TextStyle(
                              color: AppColors.lime,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            t(
                              'Talk with a quitline counselor',
                              'Habla con un consejero de la línea para dejar de fumar',
                            ),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 25,
                              height: 1.08,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            t(
                              'Routes you to your state’s quitline. Services and hours may vary.',
                              'Te conecta con la línea de tu estado. Los servicios y horarios pueden variar.',
                            ),
                            style: const TextStyle(
                              color: AppColors.mintStrong,
                              fontSize: 13,
                              height: 1.35,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Semantics(
                            label: t(
                              'Quitline phone number 1-800-784-8669',
                              'Número de la línea 1-800-784-8669',
                            ),
                            child: const Text(
                              '1-800-784-8669',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              Expanded(
                                child: FilledButton.icon(
                                  key: const ValueKey('support-call-quitline'),
                                  onPressed: () => _handleCallQuitline(context),
                                  style: FilledButton.styleFrom(
                                    backgroundColor: AppColors.lime,
                                    foregroundColor: AppColors.deepTeal,
                                    minimumSize: const Size.fromHeight(50),
                                  ),
                                  icon: const Icon(Icons.call_rounded),
                                  label: Text(t('Call now', 'Llamar ahora')),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: OutlinedButton(
                                  key: const ValueKey(
                                    'support-request-callback',
                                  ),
                                  onPressed: () =>
                                      _handleRequestCallback(context),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.white,
                                    side: const BorderSide(
                                      color: AppColors.mintStrong,
                                    ),
                                    minimumSize: const Size.fromHeight(50),
                                  ),
                                  child: Text(
                                    t(
                                      'Request a call-back',
                                      'Pedir una llamada',
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            t(
                              'Consent preview before referral',
                              'Vista previa del consentimiento antes de referir',
                            ),
                            style: const TextStyle(
                              color: AppColors.mintStrong,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    SectionTitle(
                      t('Your people', 'Tus personas'),
                      trailing: Text(
                        t(
                          'Preview before sending',
                          'Vista previa antes de enviar',
                        ),
                        style: const TextStyle(
                          color: AppColors.mutedTeal,
                          fontSize: 11,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    ResourceCard(
                      key: const ValueKey('support-person-card'),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              const CircleAvatar(
                                radius: 26,
                                backgroundColor: AppColors.mint,
                                child: Text(
                                  'J',
                                  style: TextStyle(
                                    color: AppColors.deepTeal,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      t('Jordan · Friend', 'Jordan · Amistad'),
                                      style: const TextStyle(
                                        color: AppColors.deepTeal,
                                        fontSize: 17,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    Text(
                                      t(
                                        'Evening check-in by text',
                                        'Registro por mensaje en la tarde',
                                      ),
                                      style: const TextStyle(
                                        color: AppColors.mutedTeal,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              TextButton(
                                key: const ValueKey('support-person-message'),
                                onPressed: () => _handleInformation(
                                  context,
                                  t(
                                    'Preview message to Jordan',
                                    'Vista previa del mensaje para Jordan',
                                  ),
                                  body: t(
                                    'You can review a support message here before anything is sent.',
                                    'Puedes revisar un mensaje de apoyo aquí antes de que se envíe.',
                                  ),
                                ),
                                child: Text(t('Message', 'Mensaje')),
                              ),
                            ],
                          ),
                          const Divider(height: 22),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  key: const ValueKey('support-book-call'),
                                  onPressed: () => _handleInformation(
                                    context,
                                    t(
                                      'Book a support call',
                                      'Programar una llamada de apoyo',
                                    ),
                                    body: t(
                                      'Support-call scheduling can be connected here when scheduling services are available.',
                                      'La programación de llamadas de apoyo se puede conectar aquí cuando el servicio esté disponible.',
                                    ),
                                  ),
                                  icon: const Icon(
                                    Icons.calendar_month_outlined,
                                  ),
                                  label: Text(t('Book call', 'Programar')),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: TextButton(
                                  key: const ValueKey('support-manage-people'),
                                  onPressed: () => _handleInformation(
                                    context,
                                    t(
                                      'Manage support people',
                                      'Administrar personas de apoyo',
                                    ),
                                    body: t(
                                      'Support-person management can be connected here while keeping this same screen layout.',
                                      'La administración de personas de apoyo se puede conectar aquí manteniendo el mismo diseño.',
                                    ),
                                  ),
                                  child: Text(t('Manage', 'Administrar')),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    SectionTitle(
                      t(
                        'Care team and pharmacy',
                        'Equipo de atención y farmacia',
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: _SupportOption(
                            key: const ValueKey('support-care-team'),
                            icon: Icons.health_and_safety_outlined,
                            title: t('Clinician', 'Profesional clínico'),
                            subtitle: t(
                              'Plan or symptom questions',
                              'Preguntas sobre plan o síntomas',
                            ),
                            action: t(
                              'Contact care team',
                              'Contactar al equipo',
                            ),
                            onTap: () => _handleInformation(
                              context,
                              t('Contact care team', 'Contactar al equipo'),
                              body: t(
                                'Care-team contact options can be connected here when secure messaging is available.',
                                'Las opciones de contacto con el equipo de atención se pueden conectar aquí cuando esté disponible la mensajería segura.',
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _SupportOption(
                            key: const ValueKey('support-pharmacy'),
                            icon: Icons.medication_outlined,
                            title: t('Pharmacist', 'Farmacéutico'),
                            subtitle: t(
                              'Refill or use questions',
                              'Preguntas sobre resurtido o uso',
                            ),
                            action: t('Call pharmacy', 'Llamar a farmacia'),
                            onTap: () => _handleInformation(
                              context,
                              t('Call pharmacy', 'Llamar a farmacia'),
                              body: t(
                                'Pharmacy calling can be connected here when a pharmacy number is available for the user.',
                                'La llamada a la farmacia se puede conectar aquí cuando haya un número de farmacia disponible para el usuario.',
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ResourceCard(
                      key: const ValueKey('support-sharing-controls'),
                      color: const Color(0xFFEFF5F1),
                      onTap: onOpenSettings,
                      child: Row(
                        children: [
                          const CircleAvatar(
                            backgroundColor: AppColors.deepTeal,
                            foregroundColor: AppColors.lime,
                            child: Icon(Icons.add_rounded),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  t(
                                    'Nothing is shared by default',
                                    'Nada se comparte de forma predeterminada',
                                  ),
                                  style: const TextStyle(
                                    color: AppColors.deepTeal,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                Text(
                                  t(
                                    'Review the exact message or health summary before sending.',
                                    'Revisa el mensaje o resumen exacto antes de enviarlo.',
                                  ),
                                  style: const TextStyle(
                                    color: AppColors.mutedTeal,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.chevron_right_rounded),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Material(
                      color: AppColors.coralLight,
                      borderRadius: BorderRadius.circular(16),
                      child: ListTile(
                        key: const ValueKey('support-urgent-help'),
                        onTap: () => _handleInformation(
                          context,
                          t('Urgent help', 'Ayuda urgente'),
                          body: t(
                            'If there is immediate danger or a medical emergency, contact local emergency services. This screen can later route to configured urgent-support resources.',
                            'Si hay peligro inmediato o una emergencia médica, comunícate con los servicios de emergencia locales. Esta pantalla puede conectarse después con recursos de ayuda urgente configurados.',
                          ),
                        ),
                        leading: const CircleAvatar(
                          backgroundColor: AppColors.coral,
                          foregroundColor: Colors.white,
                          child: Text('!'),
                        ),
                        title: Text(
                          t(
                            'Immediate danger or severe symptoms?',
                            '¿Peligro inmediato o síntomas graves?',
                          ),
                          style: const TextStyle(fontSize: 13),
                        ),
                        subtitle: usesLargeText
                            ? Text(
                                t('Open urgent help', 'Abrir ayuda'),
                                style: const TextStyle(
                                  color: AppColors.coral,
                                  fontWeight: FontWeight.w700,
                                ),
                              )
                            : null,
                        trailing: usesLargeText
                            ? const Icon(
                                Icons.chevron_right_rounded,
                                color: AppColors.coral,
                              )
                            : Text(
                                t('Open urgent help', 'Abrir ayuda'),
                                style: const TextStyle(
                                  color: AppColors.coral,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
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
        selectedIndex: 4,
        isSpanish: isSpanish,
        onHome: onOpenHome,
        onPlan: onOpenPlan,
        onProgress: onOpenProgress,
        onLearn: onOpenLearn,
        onSupport: () {},
      ),
    );
  }
}

class _SupportOption extends StatelessWidget {
  const _SupportOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.action,
    required this.onTap,
    super.key,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final String action;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => ResourceCard(
        padding: const EdgeInsets.all(14),
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              backgroundColor: AppColors.mint,
              child: Icon(icon, color: AppColors.deepTeal),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                color: AppColors.deepTeal,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              subtitle,
              maxLines: 2,
              style: const TextStyle(
                color: AppColors.mutedTeal,
                fontSize: 11,
                height: 1.25,
              ),
            ),
            const Divider(height: 18),
            Text(
              action,
              maxLines: 2,
              style: const TextStyle(
                color: AppColors.tealSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      );
}
