import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../settings/settings_store.dart';
import '../widgets/device_avatar.dart';
import '../widgets/confirm_sheet.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import 'device_edit_screen.dart';
import 'setup_wizard.dart';
import 'provisioning_screen.dart';

class DevicesScreen extends StatelessWidget {
  const DevicesScreen({
    super.key,
    required this.store,
    required this.devices,
    required this.activeId,
    required this.onSwitchDevice,
    required this.onDevicesChanged,
  });

  final SettingsStore store;
  final List<LockSettings> devices;
  final String activeId;
  final ValueChanged<LockSettings> onSwitchDevice;
  final VoidCallback onDevicesChanged;

  Future<void> _editDevice(BuildContext context, LockSettings device) async {
    final saved = await Navigator.of(context).push<LockSettings>(
      MaterialPageRoute(
        builder: (_) => DeviceEditScreen(store: store, device: device),
      ),
    );
    if (saved != null) {
      onDevicesChanged();
    }
  }

  Future<void> _deleteDevice(BuildContext context, LockSettings device) async {
    if (devices.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cannot delete the last device. Keep at least one.'),
        ),
      );
      return;
    }

    final confirmed = await ConfirmSheet.show(
      context,
      title: 'Delete Device',
      message: 'Are you sure you want to remove "${device.name}"? This action cannot be undone.',
      confirmLabel: 'Delete',
      isDestructive: true,
    );

    if (confirmed == true) {
      await store.deleteDevice(device.id);
      onDevicesChanged();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('"${device.name}" deleted.'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListView.builder(
      padding: AppSpacing.screenPadding,
      itemCount: devices.length + 1,
      itemBuilder: (context, index) {
        // Last element is the "Add Device" card
        if (index == devices.length) {
          return Padding(
            key: const ValueKey('add_device_card'),
            padding: const EdgeInsets.only(top: AppSpacing.sm),
            child: InkWell(
              onTap: () async {
                HapticFeedback.lightImpact();
                final saved = await Navigator.of(context).push<LockSettings>(
                  MaterialPageRoute(builder: (_) => const SetupWizard()),
                );
                if (saved != null) {
                  await store.save(saved);
                  onDevicesChanged();
                }
              },
              borderRadius: AppRadius.cardBorder,
              child: Container(
                height: 80,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: AppColors.primaryLight.withValues(alpha: 0.4),
                    style: BorderStyle.solid, // Simple clean solid border is reliable
                    width: 1.5,
                  ),
                  borderRadius: AppRadius.cardBorder,
                  color: AppColors.primary.withValues(alpha: 0.05),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.add_circle_outline_rounded,
                      color: AppColors.primaryLight,
                      size: AppIconSize.md,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      'Add New Device',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: AppColors.primaryLight,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        final device = devices[index];
        final isActive = device.id == activeId;

        return Padding(
          key: ValueKey(device.id),
          padding: const EdgeInsets.only(bottom: AppSpacing.md),
          child: Dismissible(
            key: Key('dismiss_${device.id}'),
            direction: DismissDirection.endToStart,
            confirmDismiss: (direction) async {
              if (isActive) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Cannot delete the active device. Switch to another device first.'),
                  ),
                );
                return false;
              }
              final confirmed = await ConfirmSheet.show(
                context,
                title: 'Delete Device',
                message: 'Are you sure you want to remove "${device.name}"?',
                confirmLabel: 'Delete',
                isDestructive: true,
              );
              return confirmed;
            },
            onDismissed: (direction) async {
              await store.deleteDevice(device.id);
              onDevicesChanged();
            },
            background: Container(
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
              decoration: BoxDecoration(
                color: AppColors.unlocked,
                borderRadius: AppRadius.cardBorder,
              ),
              child: const Icon(
                Icons.delete_sweep_rounded,
                color: Colors.white,
                size: AppIconSize.lg,
              ),
            ),
            child: Card(
              shape: RoundedRectangleBorder(
                borderRadius: AppRadius.cardBorder,
                side: BorderSide(
                  color: isActive
                      ? AppColors.primaryLight.withValues(alpha: 0.5)
                      : AppColors.outlineVariant,
                  width: isActive ? 2 : 1,
                ),
              ),
              child: InkWell(
                onTap: isActive ? null : () => onSwitchDevice(device),
                borderRadius: AppRadius.cardBorder,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: AppSpacing.md,
                    horizontal: AppSpacing.md,
                  ),
                  child: Row(
                    children: [
                      DeviceAvatar(
                        deviceType: device.deviceType,
                        isActive: isActive,
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    device.name,
                                    style: theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textPrimary,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (isActive) ...[
                                  const SizedBox(width: AppSpacing.sm),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: AppSpacing.sm,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary.withValues(alpha: 0.15),
                                      borderRadius: AppRadius.pillBorder,
                                      border: Border.all(
                                        color: AppColors.primaryLight.withValues(alpha: 0.3),
                                        width: 1,
                                      ),
                                    ),
                                    child: const Text(
                                      'Active',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.primaryLight,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${device.deviceType == 'lamp' ? 'Smart Lamp' : 'Smart Lock'} \u00b7 ${device.host}:${device.port}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Actions Menu
                      PopupMenuButton<String>(
                        icon: const Icon(
                          Icons.more_vert_rounded,
                          color: AppColors.textSecondary,
                        ),
                        onSelected: (value) {
                          switch (value) {
                            case 'edit':
                              _editDevice(context, device);
                              break;
                            case 'wifi_config':
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => ProvisioningScreen(
                                    store: store,
                                    initial: device,
                                  ),
                                ),
                              ).then((_) => onDevicesChanged());
                              break;
                            case 'delete':
                              _deleteDevice(context, device);
                              break;
                          }
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'edit',
                            child: Row(
                              children: [
                                Icon(Icons.edit_outlined, size: 20),
                                SizedBox(width: AppSpacing.sm),
                                Text('Edit Info'),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'wifi_config',
                            child: Row(
                              children: [
                                Icon(Icons.wifi_rounded, size: 20),
                                SizedBox(width: AppSpacing.sm),
                                Text('Wi-Fi & AP Setup'),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: 'delete',
                            enabled: !isActive,
                            child: Row(
                              children: [
                                Icon(
                                  Icons.delete_outline_rounded,
                                  size: 20,
                                  color: !isActive ? AppColors.error : null,
                                ),
                                const SizedBox(width: AppSpacing.sm),
                                Text(
                                  'Delete',
                                  style: TextStyle(
                                    color: !isActive ? AppColors.error : null,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
