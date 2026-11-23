import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../core/theme/app_colors.dart';

class PosWebViewScreen extends StatefulWidget {
  final String url;
  const PosWebViewScreen({super.key, required this.url});

  @override
  State<PosWebViewScreen> createState() => _PosWebViewScreenState();
}

class _PosWebViewScreenState extends State<PosWebViewScreen> {
  late final WebViewController _controller;
  final ValueNotifier<bool> _isLoading = ValueNotifier<bool>(true);
  final ValueNotifier<String?> _loadError = ValueNotifier<String?>(null);

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            // Update loading bar.
          },
          onPageStarted: (String url) {
            _isLoading.value = true;
            _loadError.value = null;
          },
          onPageFinished: (String url) {
            _isLoading.value = false;
          },
          onWebResourceError: (WebResourceError error) {
            // Only surface main-frame failures (ignore sub-resource errors).
            if (error.isForMainFrame ?? true) {
              _isLoading.value = false;
              _loadError.value =
                  'Could not load the POS page.\n${error.description}\n\nURL: ${widget.url}';
            }
          },
          onNavigationRequest: (NavigationRequest request) {
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.url));
  }

  @override
  void dispose() {
    _isLoading.dispose();
    _loadError.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('POS System'),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _controller.reload(),
          ),
        ],
      ),
      body: SafeArea(
        child: Stack(
          children: [
            WebViewWidget(controller: _controller),
            ValueListenableBuilder<bool>(
              valueListenable: _isLoading,
              builder: (context, isLoading, child) {
                if (isLoading) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.primaryBlue,
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
            ValueListenableBuilder<String?>(
              valueListenable: _loadError,
              builder: (context, error, child) {
                if (error == null) return const SizedBox.shrink();
                return Container(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  padding: EdgeInsets.all(24.w),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.wifi_off_rounded, size: 48.sp, color: AppColors.errorRed),
                      SizedBox(height: 16.h),
                      Text(
                        error,
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 13.sp, color: AppColors.grey),
                      ),
                      SizedBox(height: 20.h),
                      ElevatedButton.icon(
                        onPressed: () {
                          _loadError.value = null;
                          _isLoading.value = true;
                          _controller.loadRequest(Uri.parse(widget.url));
                        },
                        icon: const Icon(Icons.refresh),
                        label: const Text('Retry'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryBlue,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
