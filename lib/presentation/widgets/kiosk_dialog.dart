import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_radius.dart';
import '../../core/utils/responsive.dart';
import 'code_avatar.dart';

/// Dialog standar kiosk: ikon dalam kotak warna tipis + judul tebal, isi
/// abu, tombol di kanan bawah. Dipakai semua konfirmasi (Reset Antrian,
/// Keluar Aplikasi, Tetap Buka Layanan) supaya bentuknya seragam.
///
/// Ukuran lewat [Responsive], jadi ditaruh di widget ini — bukan di
/// `DialogTheme`, yang dibuat sebelum Responsive siap.
class KioskDialog extends StatelessWidget {
  final String title;
  final IconData? icon;
  final Color iconColor;
  final Widget content;
  final List<Widget> actions;

  const KioskDialog({
    super.key,
    required this.title,
    required this.content,
    this.icon,
    this.iconColor = AppColors.navy,
    this.actions = const [],
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.cardLarge),
      ),
      constraints: BoxConstraints(maxWidth: Responsive.w(560)),
      titlePadding: EdgeInsets.fromLTRB(
        Responsive.w(24),
        Responsive.w(22),
        Responsive.w(24),
        0,
      ),
      contentPadding: EdgeInsets.fromLTRB(
        Responsive.w(24),
        Responsive.w(14),
        Responsive.w(24),
        Responsive.w(8),
      ),
      actionsPadding: EdgeInsets.fromLTRB(
        Responsive.w(24),
        Responsive.w(8),
        Responsive.w(24),
        Responsive.w(20),
      ),
      title: Row(
        children: [
          if (icon != null) ...[
            CodeAvatar(icon: icon, size: Responsive.w(40), color: iconColor),
            SizedBox(width: Responsive.w(12)),
          ],
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: Responsive.sp(19),
                fontWeight: FontWeight.w700,
                color: AppColors.textDark,
              ),
            ),
          ),
        ],
      ),
      content: DefaultTextStyle.merge(
        style: TextStyle(
          fontSize: Responsive.sp(14.5),
          color: AppColors.textMuted,
          height: 1.5,
        ),
        child: content,
      ),
      actions: actions,
    );
  }
}
