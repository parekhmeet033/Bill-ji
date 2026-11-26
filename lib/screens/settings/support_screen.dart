import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/custom_snackbar.dart';

class SupportScreen extends StatefulWidget {
  const SupportScreen({super.key});

  @override
  State<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends State<SupportScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _subjectController = TextEditingController();
  final _messageController = TextEditingController();

  final String _website = "https://bill-ji.com/";
  final String _phoneNumber = "+919974723326";
  final String _phoneNumberAlt = "+919409111116";
  final String _email = "billji.support@gmail.com";
  final String _address =
      "Hindva Pride, 104, Amar Jawan Cir, nr. Sankalp School Road, Nikol, Ahmedabad, Gujarat 382350";

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _subjectController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _launchUrl(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) CustomSnackbar.show(context, message: 'support.could_not_launch'.tr(namedArgs: {'url': url}));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildHeader(context),
            Padding(
              padding: EdgeInsets.all(16.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildContactInfoCard(),
                  SizedBox(height: 24.h),
                  _buildSectionTitle('support.quick_actions'.tr()),
                  SizedBox(height: 12.h),
                  _buildQuickActions(),
                  SizedBox(height: 24.h),
                  Row(
                    children: [
                      Expanded(
                        child: _buildInfoBox(
                          'support.support_hours'.tr(),
                          'Monday - Saturday\n10:00 AM - 7:00 PM',
                          Icons.access_time,
                          Colors.indigo,
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: _buildInfoBox(
                          'support.need_help'.tr(),
                          'support.responds'.tr(),
                          Icons.headset_mic_outlined,
                          Colors.deepPurple,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 24.h),
                  _buildMessageForm(),
                  SizedBox(height: 24.h),
                  _buildFollowUs(),
                  SizedBox(height: 24.h),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 180.h,
      decoration: BoxDecoration(
        color: AppColors.primaryBlue,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(30.r)),
      ),
      child: Stack(
        children: [
          Positioned(
            top: 40.h,
            left: 10.w,
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          Positioned(
            top: 60.h,
            left: 0,
            right: 0,
            child: Column(
              children: [
                Text(
                  'support.title'.tr(),
                  style: TextStyle(color: Colors.white, fontSize: 20.sp, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 4.h),
                Text(
                  "We're here to help you!",
                  style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 13.sp),
                ),
              ],
            ),
          ),
          Positioned(
            right: 20.w,
            bottom: 20.h,
            child: Opacity(
              opacity: 0.2,
              child: Icon(Icons.headset_mic, size: 80.sp, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactInfoCard() {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      color: theme.cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.r),
        side: BorderSide(color: theme.dividerColor.withValues(alpha: 0.1)),
      ),
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          children: [
            _buildContactRow(Icons.language, 'support.website'.tr(), _website, () => _launchUrl(_website)),
            const Divider(),
            _buildContactRow(Icons.phone_outlined, 'support.phone'.tr(), _phoneNumber, () => _launchUrl('tel:$_phoneNumber')),
            const Divider(),
            _buildContactRow(Icons.phone_outlined, 'support.phone'.tr(), _phoneNumberAlt, () => _launchUrl('tel:$_phoneNumberAlt')),
            const Divider(),
            _buildContactRow(Icons.email_outlined, 'support.email'.tr(), _email, () => _launchUrl('mailto:$_email')),
            const Divider(),
            _buildContactRow(
              Icons.location_on_outlined,
              'support.address'.tr(),
              _address,
              () => _launchUrl('https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(_address)}'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactRow(IconData icon, String title, String value, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 8.h),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8.w),
              decoration: BoxDecoration(color: AppColors.primaryBlue.withOpacity(0.1), borderRadius: BorderRadius.circular(8.r)),
              child: Icon(icon, color: AppColors.primaryBlue, size: 20.sp),
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color ?? Colors.grey, fontSize: 11.sp),
                  ),
                  Text(
                    value,
                    style: TextStyle(
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.grey.shade400, size: 20.sp),
          ],
        ),
      ),
    );
  }

  // There are two support numbers now, so "Call Now" lets the user choose.
  void _showCallChooser() {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20.r))),
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final number in [_phoneNumber, _phoneNumberAlt])
                ListTile(
                  leading: Container(
                    padding: EdgeInsets.all(8.w),
                    decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), shape: BoxShape.circle),
                    child: Icon(Icons.phone, color: Colors.green, size: 20.sp),
                  ),
                  title: Text(number, style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600)),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _launchUrl('tel:$number');
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildQuickActions() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final iconBg = isDark ? Colors.white.withValues(alpha: 0.1) : Colors.green.shade50;
    final wpBg = isDark ? Colors.white.withValues(alpha: 0.1) : Colors.green.shade50;
    final emailBg = isDark ? Colors.white.withValues(alpha: 0.1) : Colors.blue.shade50;
    final directionBg = isDark ? Colors.white.withValues(alpha: 0.1) : Colors.purple.shade50;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildActionItem('support.call_now'.tr(), Icons.phone, iconBg, Colors.green, _showCallChooser),
        _buildActionItemImage(
          'WhatsApp',
          'assets/images/wp.png',
          wpBg,
          () => _launchUrl('https://wa.me/${_phoneNumber.replaceAll('+', '')}'),
        ),
        _buildActionItem('support.send_email'.tr(), Icons.email, emailBg, Colors.blue, () => _launchUrl('mailto:$_email')),
        _buildActionItem(
          'Get Direction',
          Icons.location_on,
          directionBg,
          Colors.purple,
          () => _launchUrl('https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(_address)}'),
        ),
      ],
    );
  }

  Widget _buildActionItemImage(String label, String imagePath, Color bgColor, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(12.r)),
            child: Image.asset(imagePath, width: 24.sp, height: 24.sp),
          ),
          SizedBox(height: 8.h),
          Text(
            label,
            style: TextStyle(fontSize: 10.sp, fontWeight: FontWeight.w500, color: Theme.of(context).textTheme.bodyLarge?.color),
          ),
        ],
      ),
    );
  }

  Widget _buildActionItem(String label, IconData icon, Color bgColor, Color iconColor, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(12.r)),
            child: Icon(icon, color: iconColor, size: 24.sp),
          ),
          SizedBox(height: 8.h),
          Text(
            label,
            style: TextStyle(fontSize: 10.sp, fontWeight: FontWeight.w500, color: Theme.of(context).textTheme.bodyLarge?.color),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoBox(String title, String subtitle, IconData icon, Color color) {
    final theme = Theme.of(context);
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24.sp),
          SizedBox(height: 12.h),
          Text(
            title,
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.sp, color: theme.textTheme.bodyLarge?.color),
          ),
          SizedBox(height: 4.h),
          Text(
            subtitle,
            style: TextStyle(color: theme.textTheme.bodySmall?.color ?? Colors.grey, fontSize: 11.sp),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageForm() {
    final theme = Theme.of(context);
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.1)),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('support.send_message'.tr()),
            SizedBox(height: 16.h),
            Row(
              children: [
                Expanded(child: _buildTextField(_nameController, 'support.your_name'.tr(), Icons.person_outline)),
                SizedBox(width: 12.w),
                Expanded(
                  child: _buildTextField(
                    _phoneController,
                    'support.mobile_number'.tr(),
                    Icons.phone_android,
                    keyboardType: TextInputType.phone,
                  ),
                ),
              ],
            ),
            SizedBox(height: 12.h),
            _buildTextField(_emailController, 'support.email_address'.tr(), Icons.email_outlined, keyboardType: TextInputType.emailAddress),
            SizedBox(height: 12.h),
            _buildTextField(_subjectController, 'support.subject'.tr(), Icons.subject),
            SizedBox(height: 12.h),
            _buildTextField(_messageController, 'support.message_hint'.tr(), null, maxLines: 4),
            SizedBox(height: 20.h),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    CustomSnackbar.show(context, message: 'support.message_sent'.tr(), isError: false);
                    _formKey.currentState!.reset();
                  }
                },
                icon: Icon(Icons.send_outlined, size: 18.sp, color: Colors.white),
                label: Text(
                  'support.submit_message'.tr(),
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryBlue,
                  padding: EdgeInsets.symmetric(vertical: 14.h),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String hint,
    IconData? icon, {
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    final theme = Theme.of(context);
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      style: TextStyle(fontSize: 13.sp, color: theme.textTheme.bodyLarge?.color),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(fontSize: 12.sp, color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.5)),
        prefixIcon: icon != null
            ? Icon(icon, size: 18.sp, color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.6))
            : null,
        filled: true,
        fillColor: theme.scaffoldBackgroundColor,
        contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.r),
          borderSide: BorderSide(color: theme.dividerColor.withValues(alpha: 0.1)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.r),
          borderSide: BorderSide(color: theme.dividerColor.withValues(alpha: 0.1)),
        ),
      ),
      validator: (v) => v!.isEmpty ? 'common.required'.tr() : null,
    );
  }

  Widget _buildFollowUs() {
    return Row(
      children: [
        _buildSectionTitle('support.follow_us'.tr()),
        Spacer(),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildSocialImage(
              'assets/images/fb.png',
              () => _launchUrl(
                "https://www.facebook.com/profile.php?id=61596494626375",
              ),
            ),
            SizedBox(width: 20.w),
            _buildSocialImage('assets/images/instagram.png', () => _launchUrl("https://www.instagram.com/billji.official/?hl=en")),
            SizedBox(width: 20.w),
            _buildSocialImage(
              'assets/images/linkedin.png',
              () => _launchUrl("https://www.linkedin.com/company/goal-scripture/?viewAsMember=true"),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSocialImage(String assetPath, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Image.asset(assetPath, height: 24.w, fit: BoxFit.fill),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.titleMedium?.color),
    );
  }
}
