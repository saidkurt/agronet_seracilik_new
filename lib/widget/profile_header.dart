import 'package:agronet/models/login_user_model.dart';
import 'package:agronet/widget/info_item.dart';
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
    final name = (user.kullaniciadi ?? "").trim();

    if (name.isEmpty) {
      return "A";
    }

    return name.characters.first.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final name =
        (user.kullaniciadi ?? "Kullanıcı").trim();

    final tip =
        (user.tip ?? "").trim();

    final personel =
        (user.prosiskodu ?? "").trim();

    final bileklik =
        (user.bileklikid ?? "").trim();

    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.black.withOpacity(.05),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.035),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // =====================================================
          // ÜST - AVATAR / İSİM / PERSONEL TİPİ
          // =====================================================

          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  borderRadius:
                      BorderRadius.circular(10),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      accent.withOpacity(.22),
                      accent.withOpacity(.06),
                    ],
                  ),
                ),
                child: Center(
                  child: Text(
                    _initial(),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight:
                          FontWeight.w900,
                      color:
                          accent.withOpacity(.95),
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 7),

              Expanded(
                child: Column(
                  mainAxisSize:
                      MainAxisSize.min,
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow:
                          TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight:
                            FontWeight.w900,
                        height: 1.0,
                        color:
                            Colors.black.withOpacity(
                          .88,
                        ),
                      ),
                    ),

                    if (tip.isNotEmpty) ...[
                      const SizedBox(height: 2),

                      Text(
                        tip,
                        maxLines: 1,
                        overflow:
                            TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight:
                              FontWeight.w700,
                          height: 1.0,
                          color:
                              Colors.black.withOpacity(
                            .50,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 4),

          // =====================================================
          // PERSONEL / BİLEKLİK / MESAİ PRİM
          // =====================================================

          Container(
            width: double.infinity,
            padding:
                const EdgeInsets.symmetric(
              horizontal: 7,
              vertical: 4,
            ),
            decoration: BoxDecoration(
              color:
                  const Color(0xFFF7F7F9),
              borderRadius:
                  BorderRadius.circular(9),
              border: Border.all(
                color:
                    Colors.black.withOpacity(.045),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: InfoItem(
                        icon:
                            Icons.badge_outlined,
                        label: "Personel",
                        value:
                            personel.isEmpty
                                ? "-"
                                : personel,
                      ),
                    ),

                    Container(
                      width: 1,
                      height: 14,
                      margin:
                          const EdgeInsets.symmetric(
                        horizontal: 3,
                      ),
                      color:
                          Colors.black.withOpacity(
                        .07,
                      ),
                    ),

                    Expanded(
                      child: InfoItem(
                        icon:
                            Icons.watch_outlined,
                        label: "Bileklik",
                        value:
                            bileklik.isEmpty
                                ? "-"
                                : bileklik,
                      ),
                    ),
                  ],
                ),

                if (bileklik.isNotEmpty) ...[
                  const SizedBox(height: 3),

                  MesaiPrimPuanWidget(
                    bileklikId: bileklik,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}