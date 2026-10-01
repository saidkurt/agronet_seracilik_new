import 'package:agronet/models/login_user_model.dart';
import 'package:agronet/widget/mesaid_card.dart';
import 'package:flutter/material.dart';

class ProfileCard extends StatelessWidget {
  final LoginUserModel user;
  final String role;

  const ProfileCard({
    super.key,
    required this.user,
    required this.role,
  });

  static const Color accent = Color(0xFF1E6F5C);

  String _initial() {
    final name = (user.kullaniciadi ?? '').trim();

    if (name.isEmpty) {
      return 'A';
    }

    return name.characters.first.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final name = (user.kullaniciadi ?? 'Kullanıcı').trim();
    final tip = (user.tip ?? '').trim();
    final bileklik = (user.bileklikid ?? '').trim();

    return LayoutBuilder(
      builder: (context, constraints) {
        // Çok dar telefonlarda avatarı da biraz küçült.
        final darEkran = constraints.maxWidth < 340;

        final avatarBoyut = darEkran ? 32.0 : 36.0;
        final avatarYazi = darEkran ? 13.0 : 14.0;

        return Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(
            horizontal: darEkran ? 7 : 9,
            vertical: 7,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(11),
            border: Border.all(
              color: Colors.black.withOpacity(.05),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(.025),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // =================================================
              // AVATAR
              // =================================================
              Container(
                width: avatarBoyut,
                height: avatarBoyut,
                decoration: BoxDecoration(
                  color: accent.withOpacity(.10),
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: Text(
                  _initial(),
                  style: TextStyle(
                    fontSize: avatarYazi,
                    fontWeight: FontWeight.w900,
                    color: accent,
                  ),
                ),
              ),

              SizedBox(width: darEkran ? 6 : 8),

              // =================================================
              // İSİM + PERSONEL TİPİ
              // =================================================
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: darEkran ? 11.5 : 12.5,
                        height: 1.05,
                        fontWeight: FontWeight.w900,
                        color: Colors.black.withOpacity(.88),
                      ),
                    ),

                    if (tip.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        tip,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: darEkran ? 8.5 : 9.2,
                          height: 1.1,
                          fontWeight: FontWeight.w600,
                          color: Colors.black.withOpacity(.48),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // =================================================
              // PRİM
              // =================================================
              if (bileklik.isNotEmpty) ...[
                const SizedBox(width: 5),

                ConstrainedBox(
                  constraints: BoxConstraints(
                    // Kartın en fazla yaklaşık %28'ini kullanabilir.
                    maxWidth: constraints.maxWidth * .28,
                  ),
                  child: MesaiPrimPuanWidget(
                    bileklikId: bileklik,
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}