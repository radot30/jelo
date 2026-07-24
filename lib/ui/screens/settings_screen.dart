import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../providers/app_provider.dart';
import '../../services/auth_service.dart';
import 'login_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pengaturan'),
      ),
      body: ListView(
        children: [
          SwitchListTile(
            title: const Text('Mode Gelap'),
            secondary: const Icon(LucideIcons.moon),
            value: provider.isDarkMode,
            onChanged: (_) {
              context.read<AppProvider>().toggleTheme();
            },
            activeThumbColor: Colors.orange,
          ),
          SwitchListTile(
            title: const Text('Pengingat Jelajah'),
            subtitle: const Text('Notifikasi mingguan untuk explore kota'),
            secondary: const Icon(LucideIcons.bell),
            value: provider.isNotificationsEnabled,
            onChanged: (val) {
              context.read<AppProvider>().toggleNotifications(val);
            },
            activeThumbColor: Colors.orange,
          ),
          if (provider.isNotificationsEnabled)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Atur Jadwal Pengingat:',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Hari:'),
                        DropdownButton<int>(
                          value: provider.reminderDay,
                          underline: const SizedBox(),
                          items: const [
                            DropdownMenuItem(value: DateTime.monday, child: Text('Senin')),
                            DropdownMenuItem(value: DateTime.tuesday, child: Text('Selasa')),
                            DropdownMenuItem(value: DateTime.wednesday, child: Text('Rabu')),
                            DropdownMenuItem(value: DateTime.thursday, child: Text('Kamis')),
                            DropdownMenuItem(value: DateTime.friday, child: Text('Jumat')),
                            DropdownMenuItem(value: DateTime.saturday, child: Text('Sabtu')),
                            DropdownMenuItem(value: DateTime.sunday, child: Text('Minggu')),
                          ],
                          onChanged: (val) {
                            if (val != null) {
                              context
                                  .read<AppProvider>()
                                  .setAlarmSchedule(val, provider.reminderTime);
                            }
                          },
                        ),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Jam:'),
                        TextButton(
                          onPressed: () async {
                            final TimeOfDay? time = await showTimePicker(
                              context: context,
                              initialTime: provider.reminderTime,
                            );
                            if (time != null && context.mounted) {
                              context
                                  .read<AppProvider>()
                                  .setAlarmSchedule(provider.reminderDay, time);
                            }
                          },
                          child: Text(
                            '${provider.reminderTime.hour.toString().padLeft(2, '0')}:${provider.reminderTime.minute.toString().padLeft(2, '0')}',
                            style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.orange),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          const Divider(height: 32),
          ListTile(
            leading: const Icon(LucideIcons.logOut, color: Colors.red),
            title: const Text('Keluar Akun', style: TextStyle(color: Colors.red)),
            onTap: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Keluar Akun'),
                  content: const Text('Apakah Anda yakin ingin keluar dari akun?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('Batal'),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Keluar'),
                    ),
                  ],
                ),
              );

              if (confirm == true && context.mounted) {
                await AuthService().logout();
                if (context.mounted) {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (route) => false,
                  );
                }
              }
            },
          ),
        ],
      ),
    );
  }
}
