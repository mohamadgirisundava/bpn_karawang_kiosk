import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/responsive.dart';

/// Footer tipis di bagian bawah layar alur ambil nomor — putih bergaris,
/// sejalan dengan header, supaya bingkai layar tidak berat di bawah.
class AppFooter extends StatelessWidget {
  const AppFooter({super.key});

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      fontSize: Responsive.sp(12.5),
      color: AppColors.textMuted,
      fontWeight: FontWeight.w600,
    );
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.white,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: Responsive.w(20),
          vertical: Responsive.sp(9),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                '© ${DateTime.now().year} Badan Pertanahan Nasional Kabupaten Karawang',
                style: style,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            SizedBox(width: Responsive.w(12)),
            Icon(
              Icons.support_agent_rounded,
              size: Responsive.sp(16),
              color: AppColors.navy,
            ),
            SizedBox(width: Responsive.w(6)),
            Text(
              'Hubungi petugas jika membutuhkan bantuan',
              style: style.copyWith(color: AppColors.navy),
            ),
          ],
        ),
      ),
    );
  }
}
