
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

import '../theme/app_theme.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // ✅ ФОН
        Positioned.fill(
          child: Image.asset(
            'assets/back.jpg',
            fit: BoxFit.cover,
          ),
        ),
        // ✅ затемнение
        Positioned.fill(
          child: Container(color: Colors.black.withOpacity(0.58)),
        ),

        Scaffold(
          backgroundColor: Colors.transparent,
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
              children: [
                // ====== TOP BRAND (маленький логотип + REGION21) ======
                _BrandHeader(
                  onJoinTap: () => _showJoinSheet(context),
                ),

                const SizedBox(height: 14),

                // ====== CARD: ТЕКСТ ПРО НАС ======
                _GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Про турнір',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 10),
                      Text(
                        '«Region 21» — аматорський футбольний турнір, який об’єднує команди з різних районів та міст. '
                        'Ми створюємо якісну організацію матчів, чесну статистику, LIVE-події та атмосферу справжнього футболу.',
                        style: TextStyle(
                          height: 1.35,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Colors.white70,
                        ),
                      ),
                      SizedBox(height: 10),
                      Text(
                        'Мета — зробити лігу максимально прозорою: результати, таблиця, склади, дисципліна та новини — все в одному місці.',
                        style: TextStyle(
                          height: 1.35,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // ====== CONTACTS ======
                _GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Контакти',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 10),

                      _ContactRow(
                        icon: Icons.phone_rounded,
                        title: '+38 (0XX) XXX-XX-XX',
                        subtitle: 'Організатор',
                        onTap: () => _openUrl(context, 'tel:+380XXXXXXXXX'),
                      ),
                      const SizedBox(height: 8),
                      _ContactRow(
                        icon: Icons.phone_rounded,
                        title: '+38 (0XX) XXX-XX-XX',
                        subtitle: 'Адміністратор',
                        onTap: () => _openUrl(context, 'tel:+380XXXXXXXXX'),
                      ),

const SizedBox(height: 14),
                      const Divider(color: Colors.white10, height: 1),
                      const SizedBox(height: 14),

                      const Text(
                        'Соцмережі',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          color: Colors.white70,
                        ),
                      ),
                      const SizedBox(height: 10),

                      Row(
                        children: [
                          _SocialIcon(
                            assetPath: 'assets/inst.png',
                            onTap: () => _openUrl(context, 'https://instagram.com/region21.official'),
                          ),
                          const SizedBox(width: 10),
                          _SocialIcon(
                            assetPath: 'assets/yt.png',
                            onTap: () => _openUrl(context, 'https://youtube.com/@region21.football'),
                          ),
                          const SizedBox(width: 10),
                          _SocialIcon(
                            assetPath: 'assets/tt.png',
                            onTap: () => _openUrl(context, 'https://www.tiktok.com/@region.21kh'),
                          ),
                          const SizedBox(width: 10),
                          _SocialIcon(
                            assetPath: 'assets/tg.png',
                            onTap: () => _openUrl(context, 'https://t.me/region21official'),
                          ),
                          const SizedBox(width: 10),
                          _SocialIcon(
                            assetPath: 'assets/www.png',
                            onTap: () => _openUrl(context, 'https://region-21.org/'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),
                const Text(
                  '© Region 21',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white38, fontWeight: FontWeight.w800),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ====== JOIN SHEET ======
  void _showJoinSheet(BuildContext context) {
    final nameC = TextEditingController();
    final phoneC = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool sending = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 14,
              ),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF0E0F12).withOpacity(0.92),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: Colors.white10),
                ),
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Заявка на участь',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.of(ctx).pop(),
                            icon: const Icon(Icons.close_rounded, color: Colors.white70),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

TextFormField(
                        controller: nameC,
                        style: const TextStyle(color: Colors.white),
                        decoration: _inputDeco('Ім’я', Icons.person_rounded),
                        validator: (v) {
                          final x = (v ?? '').trim();
                          if (x.isEmpty) return 'Вкажи ім’я';
                          if (x.length < 2) return 'Занадто коротко';
                          return null;
                        },
                      ),
                      const SizedBox(height: 10),

                      TextFormField(
                        controller: phoneC,
                        keyboardType: TextInputType.phone,
                        style: const TextStyle(color: Colors.white),
                        decoration: _inputDeco('Номер телефону', Icons.phone_rounded),
                        validator: (v) {
                          final x = (v ?? '').trim();
                          if (x.isEmpty) return 'Вкажи номер';
                          if (x.length < 8) return 'Перевір номер';
                          return null;
                        },
                      ),

                      const SizedBox(height: 14),

                      InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: sending
                            ? null
                            : () async {
                                if (!(formKey.currentState?.validate() ?? false)) return;

                                setState(() => sending = true);
                                try {
                                  await FirebaseFirestore.instance.collection('join_requests').add({
                                    'name': nameC.text.trim(),
                                    'phone': phoneC.text.trim(),
                                    'createdAt': FieldValue.serverTimestamp(),
                                    'status': 'new',
                                  });

                                  if (ctx.mounted) {
                                    Navigator.of(ctx).pop();
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Заявку відправлено ✅')),
                                    );
                                  }
                                } catch (e) {
                                  if (ctx.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Помилка: $e')),
                                    );
                                  }
                                } finally {
                                  if (ctx.mounted) setState(() => sending = false);
                                }
                              },
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: AppTheme.orange.withOpacity(0.18),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppTheme.orange.withOpacity(0.55)),
                          ),
                          child: Center(
                            child: sending
                                ? const SizedBox(
                                    height: 18,
                                    width: 18,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : const Text(
'Відправити',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w900,
                                      color: Colors.white,
                                    ),
                                  ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 6),
                      const Text(
                        'Після відправки ми зв’яжемось з тобою.',
                        style: TextStyle(color: Colors.white54, fontWeight: FontWeight.w700, fontSize: 12),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  static InputDecoration _inputDeco(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.white38, fontWeight: FontWeight.w700),
      prefixIcon: Icon(icon, color: Colors.white54),
      filled: true,
      fillColor: Colors.black.withOpacity(0.28),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.white10),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.white10),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: AppTheme.orange.withOpacity(0.6)),
      ),
    );
  }

  static Future<void> _openUrl(BuildContext context, String url) async {
    final uri = Uri.tryParse(url.trim());
    if (uri == null) return;

    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Не вдалося відкрити посилання')),
      );
    }
  }
}

// =================== UI PARTS ===================

class _BrandHeader extends StatelessWidget {
  const _BrandHeader({required this.onJoinTap});
  final VoidCallback onJoinTap;

  @override
  Widget build(BuildContext context) {
    return _GlassCard(
      child: Row(
        children: [
          // ✅ маленький логотип
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.black.withOpacity(0.25),
              border: Border.all(color: Colors.white10),
            ),
            child: ClipOval(
              child: Image.asset(
                'assets/logo.png', // <-- поставь свой путь
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(width: 12),

          // ✅ REGION21 как на главной
          Expanded(
            child: Row(
              children: const [
                Text(
                  'REGION',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 0.3,
                  ),
                ),
                Text(
                  '21',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.orange,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),

          // ✅ КНОПКА ПРИЄДНАТИСЯ (в начале)
          InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: onJoinTap,
            child: Container(

padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: AppTheme.orange.withOpacity(0.18),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppTheme.orange.withOpacity(0.55)),
              ),
              child: const Text(
                'Приєднатися',
                style: TextStyle(fontWeight: FontWeight.w900, color: Colors.white, fontSize: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GlassCard extends StatelessWidget {
  const _GlassCard({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.34),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white10),
      ),
      child: child,
    );
  }
}

class _ContactRow extends StatelessWidget {
  const _ContactRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.black.withOpacity(0.22),
                border: Border.all(color: Colors.white10),
              ),
              child: Icon(icon, color: AppTheme.orange),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Colors.white54,
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.open_in_new_rounded, color: Colors.white38, size: 18),
          ],
        ),
      ),
    );
  }
}

class _SocialIcon extends StatelessWidget {
  const _SocialIcon({required this.assetPath, required this.onTap});
  final String assetPath;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.22),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white10),
        ),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Image.asset(assetPath, fit: BoxFit.contain),
        ),
      ),
    );
  }
}