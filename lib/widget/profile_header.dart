import 'package:agronet/models/login_user_model.dart';
import 'package:agronet/widget/info_item.dart';
import 'package:agronet/widget/mesaid_card.dart';
import 'package:flutter/material.dart';

class ProfileCard extends StatelessWidget {
  final LoginUserModel user;
  final String role;

  const ProfileCard({super.key, required this.user, required this.role});

  static const accent = Color(0xFF1E6F5C);

  String _initial() {
    final name = (user.kullaniciadi ?? "").trim();
    if (name.isEmpty) return "A";
    return name.characters.first.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final name = (user.kullaniciadi ?? "Kullanıcı").trim();
    final tip = (user.tip ?? "").trim();
    final personel = (user.prosiskodu ?? "").trim();
    final bileklik = (user.bileklikid ?? "").trim();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.black.withOpacity(.06)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.06),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          // ÜST: avatar + isim/tip + rol chip
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [accent.withOpacity(.22), accent.withOpacity(.06)],
                  ),
                ),
                child: Center(
                  child: Text(
                    _initial(),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: accent.withOpacity(.95),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: Colors.black.withOpacity(.88),
                        height: 1.05,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (tip.isNotEmpty)
                      Text(
                        tip,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: Colors.black.withOpacity(.55),
                        ),
                      ),
                  ],
                ),
              ),
         
            ],
          ),

          const SizedBox(height: 12),

          // ALT BLOK: personel/bileklik + prim widget
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFF7F7F9),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.black.withOpacity(.06)),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: InfoItem(
                        icon: Icons.badge_outlined,
                        label: "Personel",
                        value: personel.isEmpty ? "-" : personel,
                      ),
                    ),
                    Container(width: 1, height: 20, color: Colors.black.withOpacity(.08)),
                    Expanded(
                      child: InfoItem(
                        icon: Icons.watch_outlined,
                        label: "Bileklik",
                        value: bileklik.isEmpty ? "-" : bileklik,
                      ),
                    ),
                  ],
                ),

                if (bileklik.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  MesaiPrimPuanWidget(bileklikId: bileklik),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}