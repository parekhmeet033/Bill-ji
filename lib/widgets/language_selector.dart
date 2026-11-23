import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:easy_localization/easy_localization.dart';
import '../core/localization/locale_service.dart';
import '../core/theme/app_colors.dart';

const List<Map<String, String>> _languages = [
  {'code': 'en', 'label': 'English', 'sub': 'English'},
  {'code': 'hi', 'label': 'हिन्दी', 'sub': 'Hindi'},
  {'code': 'gu', 'label': 'ગુજરાતી', 'sub': 'Gujarati'},
];

/// Opens the language selection bottom sheet. Used by both the login and
/// settings screens.
Future<void> showLanguageSelector(BuildContext context) {
  return showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) => const _LanguageSheet(),
  );
}

class _LanguageSheet extends StatelessWidget {
  const _LanguageSheet();

  @override
  Widget build(BuildContext context) {
    final current = context.locale.languageCode;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;

    return SafeArea(
      child: Container(
        padding: EdgeInsets.fromLTRB(20.w, 14.h, 20.w, 20.h),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: AppColors.lightGrey,
                  borderRadius: BorderRadius.circular(2.r),
                ),
              ),
            ),
            SizedBox(height: 16.h),
            Text(
              'language.title'.tr(),
              style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold, color: textColor),
            ),
            SizedBox(height: 4.h),
            Text(
              'language.subtitle'.tr(),
              style: TextStyle(fontSize: 13.sp, color: AppColors.grey),
            ),
            SizedBox(height: 16.h),
            ..._languages.map((lang) {
              final bool selected = current == lang['code'];
              return Padding(
                padding: EdgeInsets.only(bottom: 10.h),
                child: InkWell(
                  borderRadius: BorderRadius.circular(14.r),
                  onTap: () async {
                    await LocaleService.setLanguage(context, lang['code']!);
                    if (context.mounted) Navigator.pop(context);
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
                    decoration: BoxDecoration(
                      color: selected ? AppColors.primaryBlue.withValues(alpha: 0.08) : Colors.transparent,
                      borderRadius: BorderRadius.circular(14.r),
                      border: Border.all(
                        color: selected ? AppColors.primaryBlue : AppColors.lightGrey,
                        width: selected ? 1.5 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                lang['label']!,
                                style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.bold, color: textColor),
                              ),
                              Text(
                                lang['sub']!,
                                style: TextStyle(fontSize: 11.sp, color: AppColors.grey),
                              ),
                            ],
                          ),
                        ),
                        if (selected)
                          Icon(Icons.check_circle, color: AppColors.primaryBlue, size: 22.sp),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

/// Compact language pill (globe + current language) that opens the selector.
/// Used on the login screen.
class LanguagePill extends StatelessWidget {
  const LanguagePill({super.key});

  @override
  Widget build(BuildContext context) {
    final code = context.locale.languageCode;
    return InkWell(
      borderRadius: BorderRadius.circular(20.r),
      onTap: () => showLanguageSelector(context),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 7.h),
        decoration: BoxDecoration(
          color: AppColors.primaryBlue.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(color: AppColors.primaryBlue.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.language, size: 16.sp, color: AppColors.primaryBlue),
            SizedBox(width: 6.w),
            Text(
              LocaleService.nativeLabel(code),
              style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.bold, color: AppColors.primaryBlue),
            ),
            Icon(Icons.keyboard_arrow_down, size: 16.sp, color: AppColors.primaryBlue),
          ],
        ),
      ),
    );
  }
}
