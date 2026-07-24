import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:image_picker/image_picker.dart';
import '../../providers/app_provider.dart';
import '../../core/app_exception.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late TextEditingController _nameController;
  late TextEditingController _bioController;
  final ImagePicker _picker = ImagePicker();
  bool _isEditing = false;
  String _selectedAvatar = 'avatar1';

  static const List<Map<String, dynamic>> _avatarPresets = [
    {'id': 'avatar1', 'color': Colors.deepOrange, 'icon': LucideIcons.user},
    {'id': 'avatar2', 'color': Colors.indigo, 'icon': LucideIcons.smile},
    {'id': 'avatar3', 'color': Colors.teal, 'icon': LucideIcons.sparkles},
    {'id': 'avatar4', 'color': Colors.amber, 'icon': LucideIcons.zap},
    {'id': 'avatar5', 'color': Colors.purple, 'icon': LucideIcons.compass},
    {'id': 'avatar6', 'color': Colors.pink, 'icon': LucideIcons.heart},
  ];

  @override
  void initState() {
    super.initState();
    final profile = context.read<AppProvider>().userProfile;
    _nameController = TextEditingController(text: profile?.name ?? '');
    _bioController = TextEditingController(text: profile?.bio ?? '');
    _selectedAvatar = profile?.avatar ?? 'avatar1';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  static Map<String, dynamic> _getAvatarPreset(String avatarId) {
    return _avatarPresets.firstWhere(
      (a) => a['id'] == avatarId,
      orElse: () => _avatarPresets.first,
    );
  }

  Widget _buildAvatarCircle(String avatarPath,
      {double radius = 48, double iconSize = 48}) {
    final file = File(avatarPath);
    if (file.existsSync()) {
      return CircleAvatar(
        radius: radius,
        backgroundImage: FileImage(file),
      );
    }
    final preset = _getAvatarPreset(avatarPath);
    return CircleAvatar(
      radius: radius,
      backgroundColor: preset['color'] as Color,
      child: Icon(
        preset['icon'] as IconData,
        size: iconSize,
        color: Colors.white,
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 600,
        maxHeight: 600,
        imageQuality: 85,
      );
      if (image != null) {
        setState(() {
          _selectedAvatar = image.path;
        });
        if (mounted) {
          context.read<AppProvider>().updateUserProfile(
                name: _nameController.text.trim(),
                avatar: image.path,
                bio: _bioController.text.trim(),
              );
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Foto profil berhasil diperbarui!')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Gagal memilih foto: ${e is AppException ? e.message : e}')),
        );
      }
    }
  }

  void _showAvatarPicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Pilih Foto Profil / Avatar',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  OutlinedButton.icon(
                    onPressed: () => _pickImage(ImageSource.gallery),
                    icon: const Icon(LucideIcons.image),
                    label: const Text('Galeri Perangkat'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => _pickImage(ImageSource.camera),
                    icon: const Icon(LucideIcons.camera),
                    label: const Text('Kamera'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Row(
                children: [
                  Expanded(child: Divider()),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8.0),
                    child: Text('Atau Pilih Preset',
                        style: TextStyle(color: Colors.grey, fontSize: 12)),
                  ),
                  Expanded(child: Divider()),
                ],
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 16,
                runSpacing: 16,
                children: _avatarPresets.map((preset) {
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedAvatar = preset['id'] as String;
                      });
                      context.read<AppProvider>().updateUserProfile(
                            name: _nameController.text.trim(),
                            avatar: preset['id'] as String,
                            bio: _bioController.text.trim(),
                          );
                      Navigator.pop(context);
                    },
                    child: CircleAvatar(
                      radius: 28,
                      backgroundColor: preset['color'] as Color,
                      child: Icon(
                        preset['icon'] as IconData,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  void _showLinkEmailDialog(BuildContext context, AppProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) {
        final emailController = TextEditingController();
        final passwordController = TextEditingController();

        return AlertDialog(
          title: const Row(
            children: [
              Icon(LucideIcons.mail, color: Colors.orange),
              SizedBox(width: 8),
              Text('Hubungkan Email'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                  'Daftarkan Email & Kata Sandi agar Anda dapat login dengan email di perangkat ini.'),
              const SizedBox(height: 16),
              TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Alamat Email',
                  prefixIcon: Icon(LucideIcons.mail),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Kata Sandi (Minimal 6 karakter)',
                  prefixIcon: Icon(LucideIcons.lock),
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                emailController.dispose();
                passwordController.dispose();
                Navigator.pop(ctx);
              },
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () async {
                final email = emailController.text.trim();
                final password = passwordController.text.trim();
                if (email.isEmpty || password.isEmpty) return;
                final nav = Navigator.of(ctx);
                final messenger = ScaffoldMessenger.of(context);
                try {
                  await provider.linkAccountWithEmail(email, password);
                  emailController.dispose();
                  passwordController.dispose();
                  nav.pop();
                  messenger.showSnackBar(
                    SnackBar(
                        content: Text(
                            'Akun berhasil dihubungkan ke email $email!')),
                  );
                } catch (e) {
                  messenger.showSnackBar(
                    SnackBar(
                        content: Text(e is AppException
                            ? e.message
                            : 'Gagal menghubungkan email.')),
                  );
                }
              },
              child: const Text('Hubungkan'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);
    final profile = provider.userProfile;

    if (profile == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final bool hasEmail = profile.email != null && profile.email!.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil Pengguna'),
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(_isEditing ? LucideIcons.check : LucideIcons.edit2),
            onPressed: () {
              if (_isEditing) {
                provider.updateUserProfile(
                  name: _nameController.text.trim(),
                  avatar: _selectedAvatar,
                  bio: _bioController.text.trim(),
                );
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Profil berhasil diperbarui!')),
                );
              }
              setState(() {
                _isEditing = !_isEditing;
              });
            },
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Center(
              child: Stack(
                children: [
                  _buildAvatarCircle(_selectedAvatar,
                      radius: 54, iconSize: 54),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: _showAvatarPicker,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Theme.of(context).primaryColor,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          LucideIcons.camera,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              color: Theme.of(context)
                  .primaryColor
                  .withValues(alpha: 0.08),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(LucideIcons.qrCode, color: Colors.orange),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('ID Unik Pengguna',
                                style: TextStyle(
                                    fontSize: 12, color: Colors.grey)),
                            Text(
                              profile.uniqueId,
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ],
                    ),
                    ElevatedButton.icon(
                      onPressed: () {
                        Clipboard.setData(
                            ClipboardData(text: profile.uniqueId));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('ID Unik berhasil disalin!')),
                        );
                      },
                      icon: const Icon(LucideIcons.copy, size: 16),
                      label: const Text('Salin'),
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20)),
                      ),
                    )
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            Card(
              elevation: 1,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                leading: const Icon(LucideIcons.mail, color: Colors.orange),
                title: const Text('Email Terhubung'),
                subtitle: Text(
                  hasEmail
                      ? profile.email!
                      : 'Belum terhubung ke email (Akun Tamu)',
                  style: TextStyle(
                    color: hasEmail ? Colors.green : Colors.grey,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                trailing: hasEmail
                    ? const Icon(LucideIcons.checkCircle2, color: Colors.green)
                    : ElevatedButton(
                        onPressed: () =>
                            _showLinkEmailDialog(context, provider),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20)),
                        ),
                        child: const Text('Hubungkan'),
                      ),
              ),
            ),
            const SizedBox(height: 16),

            Card(
              elevation: 1,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Informasi Diri',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16)),
                    const Divider(),
                    const SizedBox(height: 8),
                    _isEditing
                        ? TextField(
                            controller: _nameController,
                            decoration: const InputDecoration(
                              labelText: 'Nama Lengkap / Panggilan',
                              prefixIcon: Icon(LucideIcons.user),
                              border: OutlineInputBorder(),
                            ),
                          )
                        : ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: const Icon(LucideIcons.user,
                                color: Colors.orange),
                            title: const Text('Nama'),
                            subtitle: Text(profile.name,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15)),
                          ),
                    const SizedBox(height: 12),
                    _isEditing
                        ? TextField(
                            controller: _bioController,
                            maxLines: 2,
                            decoration: const InputDecoration(
                              labelText: 'Bio Singkat (Opsional)',
                              prefixIcon: Icon(LucideIcons.fileText),
                              border: OutlineInputBorder(),
                            ),
                          )
                        : ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: const Icon(LucideIcons.fileText,
                                color: Colors.orange),
                            title: const Text('Bio'),
                            subtitle: Text(
                              profile.bio.isNotEmpty
                                  ? profile.bio
                                  : 'Belum ada bio.',
                              style: const TextStyle(
                                  fontStyle: FontStyle.italic),
                            ),
                          ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            Card(
              elevation: 1,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: SwitchListTile(
                secondary: Icon(
                  profile.isPrivate ? LucideIcons.lock : LucideIcons.globe,
                  color: profile.isPrivate ? Colors.red : Colors.green,
                ),
                title: const Text('Profil Privat',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(
                  profile.isPrivate
                      ? 'Profil Anda disembunyikan.'
                      : 'Profil Publik: Informasi profil Anda dapat dilihat.',
                ),
                value: profile.isPrivate,
                onChanged: (val) {
                  provider.togglePrivacy(val);
                },
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
