import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/responsive.dart';

/// Footer bar tipis di bagian bawah tiap layar utama.
class AppFooter extends StatelessWidget {
  const AppFooter({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: Responsive.w(16),
        vertical: Responsive.h(6),
      ),
      color: AppColors.navy,
      child: Row(
        children: [
          Expanded(
            child: Text(
              '© ${DateTime.now().year} Badan Pertanahan Nasional Kabupaten Karawang',
              style: TextStyle(
                fontFamily: 'NunitoSans',
                fontSize: Responsive.sp(12),
                color: AppColors.white,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          SizedBox(width: Responsive.w(12)),
          Text(
            'Hubungi petugas jika membutuhkan bantuan',
            style: TextStyle(
              fontFamily: 'NunitoSans',
              fontSize: Responsive.sp(12),
              color: AppColors.goldLight,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
