import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'resource_screen_widgets.dart';

class SettingsPrivacyScreen extends StatelessWidget {
  const SettingsPrivacyScreen({
    required this.isSpanish,
    required this.remindersEnabled,
    required this.sensitiveDetailsEnabled,
    required this.diagnosticsEnabled,
    required this.reduceMotionEnabled,
    this.onRemindersChanged,
    this.onSensitiveDetailsChanged,
    this.onDiagnosticsChanged,
    this.onReduceMotionChanged,
    required this.onBack,
    this.signedIn = false,
    this.accountEmail,
    this.displayName,
    this.onReviewConsent,
    this.onInformation,
    this.onDownloadData,
    this.onDeleteAccount,
    this.hasDevicePlan = false,
    this.devicePlanNeedsRecovery = false,
    this.canBackupDevicePlan = false,
    this.onBackupDevicePlan,
    this.onDeleteDevicePlan,
    this.onSignOut,
    super.key,
  });

  final bool isSpanish;
  final bool remindersEnabled;
  final bool sensitiveDetailsEnabled;
  final bool diagnosticsEnabled;
  final bool reduceMotionEnabled;
  final ValueChanged<bool>? onRemindersChanged;
  final ValueChanged<bool>? onSensitiveDetailsChanged;
  final ValueChanged<bool>? onDiagnosticsChanged;
  final ValueChanged<bool>? onReduceMotionChanged;
  final VoidCallback onBack;
  final bool signedIn;
  final String? accountEmail;
  final String? displayName;
  final VoidCallback? onReviewConsent;
  final ValueChanged<String>? onInformation;
  final VoidCallback? onDownloadData;
  final VoidCallback? onDeleteAccount;
  final bool hasDevicePlan;
  final bool devicePlanNeedsRecovery;
  final bool canBackupDevicePlan;
  final VoidCallback? onBackupDevicePlan;
  final VoidCallback? onDeleteDevicePlan;
  final VoidCallback? onSignOut;

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

  void _handleInformation(BuildContext context, String title, {String? body}) {
    if (onInformation != null) {
      onInformation!(title);
      return;
    }
    _showInfo(
      context,
      title,
      body ??
          t(
            'This setting is available as a preview. A connected account service can be added later without changing this screen.',
            'Esta configuración está disponible como vista previa. Se puede agregar un servicio de cuenta conectado más adelante sin cambiar esta pantalla.',
          ),
    );
  }

  void _handleReviewConsent(BuildContext context) {
    if (onReviewConsent != null) {
      onReviewConsent!();
      return;
    }
    _handleInformation(
      context,
      t('Consent and permissions', 'Consentimiento y permisos'),
      body: t(
        'Review consent, research and communication choices here. Changes should require confirmation before being saved.',
        'Revisa aquí las opciones de consentimiento, investigación y comunicación. Los cambios deben requerir confirmación antes de guardarse.',
      ),
    );
  }

  void _handleDownloadData(BuildContext context) {
    if (onDownloadData != null) {
      onDownloadData!();
      return;
    }
    _handleInformation(
      context,
      t('Download a copy', 'Descargar una copia'),
      body: t(
        'A data export can be prepared here for your entries, plan and progress in PDF and JSON formats.',
        'Aquí se puede preparar una exportación de tus registros, plan y progreso en formatos PDF y JSON.',
      ),
    );
  }

  void _handleDeleteAccount(BuildContext context) {
    if (onDeleteAccount != null) {
      onDeleteAccount!();
      return;
    }
    _handleInformation(
      context,
      t('Delete account and data', 'Eliminar cuenta y datos'),
      body: t(
        'Permanent deletion must use a separate review and confirmation step before any account or health data is removed.',
        'La eliminación permanente debe incluir una revisión y confirmación separadas antes de eliminar cualquier cuenta o dato de salud.',
      ),
    );
  }

  void _handleSignOut(BuildContext context) {
    if (onSignOut != null) {
      onSignOut!();
      return;
    }
    _handleInformation(
      context,
      t('Sign out', 'Cerrar sesión'),
      body: t(
        'Sign-out can be connected here when account authentication is enabled.',
        'El cierre de sesión se puede conectar aquí cuando se habilite la autenticación de la cuenta.',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const ValueKey('functional-settings-privacy-screen'),
      backgroundColor: AppColors.cream,
      body: SafeArea(
        child: Column(
          children: [
            ResourcePageHeader(
              title: t('Settings & privacy', 'Configuración y privacidad'),
              subtitle: t(
                'Your account, choices and data.',
                'Tu cuenta, tus decisiones y tus datos.',
              ),
              onBack: onBack,
              backSemanticLabel: t('Go back', 'Volver'),
              actions: const [
                CircleAvatar(
                  key: ValueKey('settings-profile-symbol'),
                  radius: 23,
                  backgroundColor: AppColors.mint,
                  foregroundColor: AppColors.deepTeal,
                  child: Text(
                    'A',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            Expanded(
              child: SingleChildScrollView(
                key: const ValueKey('settings-privacy-scroll'),
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ResourceCard(
                      key: const ValueKey('settings-privacy-summary'),
                      color: AppColors.deepTeal,
                      onTap: () => _handleInformation(
                        context,
                        t('Privacy summary', 'Resumen de privacidad'),
                        body: t(
                          'Review how privacy choices, sharing and data controls work in BreatheFree.',
                          'Revisa cómo funcionan las opciones de privacidad, el uso compartido y los controles de datos en BreatheFree.',
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            t(
                              'PRIVATE BY DEFAULT',
                              'PRIVADO DE FORMA PREDETERMINADA',
                            ),
                            style: const TextStyle(
                              color: AppColors.lime,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            t(
                              'Your choices stay in your hands',
                              'Tus decisiones permanecen en tus manos',
                            ),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            t(
                              'No ads. We never sell your health data.',
                              'Sin anuncios. Nunca vendemos tus datos de salud.',
                            ),
                            style: const TextStyle(
                              color: AppColors.mintStrong,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            t(
                              'Privacy choices last reviewed Aug 22, 2026',
                              'Opciones de privacidad revisadas el 22 ago 2026',
                            ),
                            style: const TextStyle(
                              color: AppColors.mintStrong,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    SectionTitle(t('Account', 'Cuenta')),
                    const SizedBox(height: 8),
                    ResourceCard(
                      key: const ValueKey('settings-account-summary'),
                      child: ListTile(
                        leading: const Icon(Icons.person_outline_rounded),
                        title: Text(
                          displayName?.trim().isNotEmpty == true
                              ? displayName!.trim()
                              : t(
                                  signedIn ? 'Your profile' : 'Not signed in',
                                  signedIn ? 'Tu perfil' : 'Sesión no iniciada',
                                ),
                        ),
                        subtitle: Text(
                          accountEmail ??
                              t(
                                'Sign in to sync your profile.',
                                'Inicia sesión para sincronizar tu perfil.',
                              ),
                        ),
                      ),
                    ),
                    if (hasDevicePlan) ...[
                      const SizedBox(height: 8),
                      ResourceCard(
                        child: ListTile(
                          key: const ValueKey('settings-device-plan'),
                          leading: const Icon(Icons.phone_iphone_rounded),
                          title: Text(t(
                            'Saved on this device',
                            'Guardado en este dispositivo',
                          )),
                          subtitle: Text(devicePlanNeedsRecovery
                              ? t(
                                  'This encrypted plan cannot be opened. Remove it to save a new device plan.',
                                  'Este plan cifrado no se puede abrir. Elimínalo para guardar un plan nuevo en el dispositivo.',
                                )
                              : t(
                                  'Encrypted guest plan; not synced to an account',
                                  'Plan de invitado cifrado; no sincronizado con una cuenta',
                                )),
                          trailing: PopupMenuButton<String>(
                            key: const ValueKey('settings-device-plan-actions'),
                            tooltip: t('Device plan actions',
                                'Acciones del plan del dispositivo'),
                            onSelected: (value) {
                              if (value == 'backup') {
                                onBackupDevicePlan?.call();
                              } else if (value == 'remove') {
                                onDeleteDevicePlan?.call();
                              }
                            },
                            itemBuilder: (context) => [
                              if (canBackupDevicePlan)
                                PopupMenuItem(
                                  key: const ValueKey(
                                    'settings-backup-device-plan',
                                  ),
                                  value: 'backup',
                                  child: Text(t('Back up', 'Respaldar')),
                                ),
                              PopupMenuItem(
                                key: const ValueKey(
                                  'settings-delete-device-plan',
                                ),
                                value: 'remove',
                                child: Text(t('Remove', 'Eliminar')),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 18),
                    SectionTitle(t('Notifications', 'Notificaciones')),
                    const SizedBox(height: 8),
                    ResourceCard(
                      child: Column(
                        children: [
                          _SettingsSwitch(
                            key: const ValueKey('settings-reminders'),
                            icon: Icons.notifications_none_rounded,
                            title: t(
                              'Check-ins and plan reminders',
                              'Registros y recordatorios del plan',
                            ),
                            subtitle: t(
                              'Helpful prompts based on your plan',
                              'Avisos útiles basados en tu plan',
                            ),
                            value: remindersEnabled,
                            onChanged: onRemindersChanged,
                          ),
                          const Divider(),
                          _SettingsSwitch(
                            key: const ValueKey('settings-sensitive-details'),
                            icon: Icons.visibility_off_outlined,
                            title: t(
                              'Show sensitive details',
                              'Mostrar detalles sensibles',
                            ),
                            subtitle: t(
                              'Quit status and medication stay hidden when off',
                              'El estado y medicamentos quedan ocultos al desactivar',
                            ),
                            value: sensitiveDetailsEnabled,
                            onChanged: onSensitiveDetailsChanged,
                          ),
                          const Divider(),
                          _SettingsLink(
                            key: const ValueKey('settings-quiet-hours'),
                            icon: Icons.dark_mode_outlined,
                            title: t('Quiet hours', 'Horario silencioso'),
                            subtitle: t(
                              '9:00 PM–7:00 AM · urgent safety alerts still appear',
                              '9:00 PM–7:00 AM · las alertas urgentes aún aparecen',
                            ),
                            action: t('Change', 'Cambiar'),
                            onTap: () => _handleInformation(
                              context,
                              t('Quiet hours', 'Horario silencioso'),
                              body: t(
                                'Quiet hours are currently shown as 9:00 PM–7:00 AM. Editing can be connected to notification preferences later.',
                                'El horario silencioso se muestra actualmente de 9:00 PM a 7:00 AM. La edición se puede conectar después a las preferencias de notificaciones.',
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              t(
                                'Lock-screen preview: “You have a BreatheFree reminder.”',
                                'Vista previa: “Tienes un recordatorio de BreatheFree”.',
                              ),
                              style: const TextStyle(
                                color: AppColors.mutedTeal,
                                fontSize: 10,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    SectionTitle(
                      t('Privacy & permissions', 'Privacidad y permisos'),
                    ),
                    const SizedBox(height: 8),
                    ResourceCard(
                      child: Column(
                        children: [
                          _SettingsLink(
                            key: const ValueKey('settings-consent'),
                            icon: Icons.assignment_outlined,
                            title: t(
                              'Consent and permissions',
                              'Consentimiento y permisos',
                            ),
                            subtitle: t(
                              'Review coaching, research and communication choices',
                              'Revisa las opciones de apoyo, investigación y comunicación',
                            ),
                            action: t('Review', 'Revisar'),
                            onTap: () => _handleReviewConsent(context),
                          ),
                          const Divider(),
                          _SettingsLink(
                            key: const ValueKey('settings-care-sharing'),
                            icon: Icons.group_outlined,
                            title: t(
                              'Care-team sharing',
                              'Compartir con el equipo',
                            ),
                            subtitle: t(
                              'Nothing sends until you preview and confirm it',
                              'Nada se envía sin tu vista previa y confirmación',
                            ),
                            action: t('Manual only', 'Solo manual'),
                            onTap: () => _handleInformation(
                              context,
                              t('Care-team sharing', 'Compartir con el equipo'),
                              body: t(
                                'Nothing is sent automatically. Sharing should require preview and confirmation before anything leaves the app.',
                                'Nada se envía automáticamente. Compartir debe requerir vista previa y confirmación antes de que algo salga de la aplicación.',
                              ),
                            ),
                          ),
                          const Divider(),
                          _SettingsLink(
                            key: const ValueKey('settings-connected-apps'),
                            icon: Icons.devices_other_outlined,
                            title: t(
                              'Connected apps and devices',
                              'Aplicaciones y dispositivos conectados',
                            ),
                            subtitle: t(
                              'No active connections',
                              'Sin conexiones activas',
                            ),
                            action: t('Manage', 'Administrar'),
                            onTap: () => _handleInformation(
                              context,
                              t(
                                'Connected apps and devices',
                                'Aplicaciones y dispositivos conectados',
                              ),
                              body: t(
                                'There are no active connections in this preview. Device management can be added when integrations are enabled.',
                                'No hay conexiones activas en esta vista previa. La administración de dispositivos se puede agregar cuando se habiliten las integraciones.',
                              ),
                            ),
                          ),
                          const Divider(),
                          _SettingsSwitch(
                            key: const ValueKey('settings-diagnostics'),
                            icon: Icons.monitor_heart_outlined,
                            title: t(
                              'Anonymous app diagnostics',
                              'Diagnóstico anónimo de la aplicación',
                            ),
                            subtitle: t(
                              'Optional technical data with no health entries',
                              'Datos técnicos opcionales sin registros de salud',
                            ),
                            value: diagnosticsEnabled,
                            onChanged: onDiagnosticsChanged,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    SectionTitle(t('Your data', 'Tus datos')),
                    const SizedBox(height: 8),
                    ResourceCard(
                      child: Column(
                        children: [
                          _SettingsLink(
                            key: const ValueKey('settings-download-data'),
                            icon: Icons.download_rounded,
                            title: t('Download a copy', 'Descargar una copia'),
                            subtitle: t(
                              'Your profile and saved plan · JSON',
                              'Tu perfil y plan guardado · JSON',
                            ),
                            action: t('Request', 'Solicitar'),
                            onTap: () => _handleDownloadData(context),
                          ),
                          const Divider(),
                          _SettingsLink(
                            key: const ValueKey('settings-export-summary'),
                            icon: Icons.ios_share_rounded,
                            title: t(
                              'Export a care summary',
                              'Exportar un resumen de atención',
                            ),
                            subtitle: t(
                              'Choose dates and preview every detail before sharing',
                              'Elige fechas y revisa cada detalle antes de compartir',
                            ),
                            action: t('Create', 'Crear'),
                            onTap: () => _handleInformation(
                              context,
                              t(
                                'Export a care summary',
                                'Exportar un resumen de atención',
                              ),
                              body: t(
                                'A care-summary export can let the user choose dates and preview the exact content before sharing.',
                                'La exportación de un resumen de atención puede permitir elegir fechas y revisar el contenido exacto antes de compartirlo.',
                              ),
                            ),
                          ),
                          const Divider(),
                          Material(
                            color: AppColors.coralLight,
                            borderRadius: BorderRadius.circular(16),
                            child: ListTile(
                              key: const ValueKey('settings-delete-account'),
                              onTap: () => _handleDeleteAccount(context),
                              leading: const CircleAvatar(
                                backgroundColor: AppColors.coral,
                                foregroundColor: Colors.white,
                                child: Icon(Icons.delete_outline_rounded),
                              ),
                              title: Text(
                                t(
                                  'Delete account and data',
                                  'Eliminar cuenta y datos',
                                ),
                                style: const TextStyle(
                                  color: AppColors.deepTeal,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              subtitle: Text(
                                t(
                                  'Permanent deletion requires review and confirmation',
                                  'La eliminación permanente requiere revisión y confirmación',
                                ),
                                style: const TextStyle(fontSize: 10),
                              ),
                              trailing: const Icon(
                                Icons.chevron_right_rounded,
                                color: AppColors.coral,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    SectionTitle(
                      t('Accessibility & app', 'Accesibilidad y aplicación'),
                    ),
                    const SizedBox(height: 8),
                    ResourceCard(
                      child: Column(
                        children: [
                          _SettingsLink(
                            key: const ValueKey('settings-text-size'),
                            icon: Icons.text_fields_rounded,
                            title: t(
                              'Text size and contrast',
                              'Tamaño y contraste del texto',
                            ),
                            subtitle: t(
                              'Follows your device settings',
                              'Sigue la configuración de tu dispositivo',
                            ),
                            action: t('System', 'Sistema'),
                            onTap: () => _handleInformation(
                              context,
                              t(
                                'Text size and contrast',
                                'Tamaño y contraste del texto',
                              ),
                              body: t(
                                'BreatheFree follows the device text-size and contrast settings.',
                                'BreatheFree sigue la configuración de tamaño de texto y contraste del dispositivo.',
                              ),
                            ),
                          ),
                          const Divider(),
                          _SettingsSwitch(
                            key: const ValueKey('settings-reduce-motion'),
                            icon: Icons.motion_photos_off_outlined,
                            title: t('Reduce motion', 'Reducir movimiento'),
                            subtitle: t(
                              'Uses gentle transitions without celebration effects',
                              'Usa transiciones suaves sin efectos de celebración',
                            ),
                            value: reduceMotionEnabled,
                            onChanged: onReduceMotionChanged,
                          ),
                          const Divider(),
                          _SettingsLink(
                            key: const ValueKey('settings-policy-help'),
                            icon: Icons.info_outline_rounded,
                            title: t(
                              'Privacy policy, terms and help',
                              'Política de privacidad, términos y ayuda',
                            ),
                            subtitle: 'BreatheFree version 1.0.0 (100)',
                            action: t('Open', 'Abrir'),
                            onTap: () => _handleInformation(
                              context,
                              t(
                                'Privacy policy, terms and help',
                                'Política de privacidad, términos y ayuda',
                              ),
                              body: t(
                                'Privacy policy, terms and help links can be connected here when the production URLs are available.',
                                'Los enlaces a la política de privacidad, los términos y la ayuda se pueden conectar aquí cuando estén disponibles las URL de producción.',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        key: const ValueKey('settings-sign-out'),
                        onPressed: () => _handleSignOut(context),
                        child: Text(
                          signedIn
                              ? t('Sign out', 'Cerrar sesión')
                              : t('Sign in', 'Iniciar sesión'),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Center(
                      child: Text(
                        t(
                          'Changes save automatically and sync securely.',
                          'Los cambios se guardan automáticamente y se sincronizan de forma segura.',
                        ),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: AppColors.mutedTeal,
                          fontSize: 10,
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
    );
  }
}

class _SettingsSwitch extends StatefulWidget {
  const _SettingsSwitch({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    this.onChanged,
    super.key,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  State<_SettingsSwitch> createState() => _SettingsSwitchState();
}

class _SettingsSwitchState extends State<_SettingsSwitch> {
  late bool _value;

  @override
  void initState() {
    super.initState();
    _value = widget.value;
  }

  @override
  void didUpdateWidget(covariant _SettingsSwitch oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != oldWidget.value) {
      _value = widget.value;
    }
  }

  @override
  Widget build(BuildContext context) => Semantics(
        toggled: _value,
        child: SwitchListTile(
          contentPadding: EdgeInsets.zero,
          secondary: CircleAvatar(
            backgroundColor: AppColors.mint,
            child: Icon(widget.icon, color: AppColors.deepTeal, size: 20),
          ),
          title: Text(
            widget.title,
            style: const TextStyle(
              color: AppColors.deepTeal,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          subtitle: Text(
            widget.subtitle,
            style: const TextStyle(color: AppColors.mutedTeal, fontSize: 10),
          ),
          value: _value,
          onChanged: (next) {
            setState(() => _value = next);
            widget.onChanged?.call(next);
          },
        ),
      );
}

class _SettingsLink extends StatelessWidget {
  const _SettingsLink({
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
  Widget build(BuildContext context) => Semantics(
        button: true,
        label: '$title. $subtitle. $action',
        excludeSemantics: true,
        child: ListTile(
          contentPadding: EdgeInsets.zero,
          onTap: onTap,
          leading: CircleAvatar(
            backgroundColor: AppColors.mint,
            child: Icon(icon, color: AppColors.deepTeal, size: 20),
          ),
          title: Text(
            title,
            style: const TextStyle(
              color: AppColors.deepTeal,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          subtitle: Text(
            subtitle,
            style: const TextStyle(color: AppColors.mutedTeal, fontSize: 10),
          ),
          trailing: Text(
            action,
            style: const TextStyle(
              color: AppColors.tealSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      );
}
