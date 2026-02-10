import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_inappwebview_macos/flutter_inappwebview_macos.dart';
import 'package:flutter_inappwebview_windows/flutter_inappwebview_windows.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'services/auth_service.dart';
import 'services/device_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.macOS) {
    MacOSInAppWebViewPlatform.registerWith();
  } else if (!kIsWeb && defaultTargetPlatform == TargetPlatform.windows) {
    WindowsInAppWebViewPlatform.registerWith();
  }

  // Supabase configuration
  await Supabase.initialize(
    url: 'https://egilsbngmqlbdcgxqrdg.supabase.co',
    anonKey: 'sb_publishable_ogIpM4nfJ0DnYkzHpJm7pA_TpHze361',
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Jenta',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6C63FF),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.grey.shade100,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFF6C63FF), width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 18,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF6C63FF),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 18),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 0,
          ),
        ),
      ),
      home: const AuthScreen(),
    );
  }
}

// ─────────────────────────────────────────────
// LICENSE KEY AUTH SCREEN
// ─────────────────────────────────────────────

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _licenseKeyController = TextEditingController();
  bool _isLoading = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: const Interval(0.2, 1.0, curve: Curves.easeOutCubic),
          ),
        );
    _animationController.forward();
  }

  @override
  void dispose() {
    _licenseKeyController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _activate() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      final deviceId = await DeviceService.getDeviceId();
      debugPrint('Device ID: $deviceId');

      final authResponse = await AuthService.validateLicenseKey(
        licenseKey: _licenseKeyController.text.trim(),
        deviceId: deviceId,
      );

      if (!mounted) return;

      if (authResponse.result == AuthResult.success) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) =>
                WebViewScreen(licenseData: authResponse.licenseData!),
          ),
        );
      } else {
        setState(() => _isLoading = false);

        final message = AuthService.getErrorMessage(authResponse.result);
        final isDeviceError = authResponse.result == AuthResult.wrongDevice;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(
                  isDeviceError ? Icons.devices_other : Icons.error_outline,
                  color: Colors.white,
                ),
                const SizedBox(width: 12),
                Expanded(child: Text(message)),
              ],
            ),
            backgroundColor: isDeviceError
                ? Colors.orange.shade700
                : Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 5),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color.fromARGB(255, 255, 4, 4),
              Color.fromARGB(255, 187, 126, 126),
              Color.fromARGB(255, 255, 4, 62),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 400),
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(38),
                          blurRadius: 30,
                          offset: const Offset(0, 15),
                        ),
                      ],
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Color.fromARGB(255, 188, 186, 236),
                                  Color.fromARGB(255, 255, 255, 255),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Image.asset(
                              "assets/icon.png",
                              width: 60,
                              height: 60,
                            ),
                          ),
                          const SizedBox(height: 24),
                          const Text(
                            'Activate Jenta',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1F2937),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Enter your license key to continue',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 32),
                          TextFormField(
                            controller: _licenseKeyController,
                            textCapitalization: TextCapitalization.characters,
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 16,
                              letterSpacing: 2,
                            ),
                            decoration: const InputDecoration(
                              hintText: 'XXXX-XXXX-XXXX-XXXX',
                              prefixIcon: Icon(
                                Icons.vpn_key_outlined,
                                color: Color(0xFF6C63FF),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Please enter your license key';
                              }
                              if (value.trim().length < 8) {
                                return 'License key is too short';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 32),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _activate,
                              child: _isLoading
                                  ? const SizedBox(
                                      height: 24,
                                      width: 24,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.5,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              Colors.white,
                                            ),
                                      ),
                                    )
                                  : const Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.lock_open, size: 20),
                                        SizedBox(width: 8),
                                        Text(
                                          'Activate',
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.info_outline,
                                size: 14,
                                color: Colors.grey.shade500,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Key is bound to this device only',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// WEBVIEW SCREEN WITH PROFILE
// ─────────────────────────────────────────────

class WebViewScreen extends StatefulWidget {
  final LicenseData licenseData;

  const WebViewScreen({super.key, required this.licenseData});

  @override
  State<WebViewScreen> createState() => _WebViewScreenState();
}

class _WebViewScreenState extends State<WebViewScreen> {
  double _progress = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  void _signOut() {
    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (_) => const AuthScreen()));
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final license = widget.licenseData;
    final daysLeft = license.expiresAt.difference(DateTime.now()).inDays;

    return Scaffold(
      key: _scaffoldKey,

      // ── Profile Drawer ──
      endDrawer: Drawer(
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 20),

              // Avatar
              CircleAvatar(
                radius: 40,
                backgroundColor: const Color(0xFF6C63FF),
                child: Text(
                  license.name.isNotEmpty ? license.name[0].toUpperCase() : 'U',
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Name
              Text(
                license.name,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),

              // License Info
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    _infoRow(Icons.vpn_key, 'License Key', license.licenseKey),
                    const Divider(height: 24),
                    _infoRow(
                      Icons.timer,
                      'Duration',
                      '${license.durationMonths} month${license.durationMonths != 1 ? 's' : ''}',
                    ),
                    const Divider(height: 24),
                    _infoRow(
                      Icons.calendar_today,
                      'Expires',
                      _formatDate(license.expiresAt),
                    ),
                    const Divider(height: 24),
                    _infoRow(
                      Icons.hourglass_bottom,
                      'Days Left',
                      '$daysLeft day${daysLeft != 1 ? 's' : ''}',
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // Sign Out Button
              Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _signOut,
                    icon: const Icon(Icons.logout),
                    label: const Text(
                      'Sign Out',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade600,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),

      body: Column(
        children: [
          if (_progress < 1.0)
            LinearProgressIndicator(
              value: _progress,
              backgroundColor: Colors.grey.shade200,
              valueColor: const AlwaysStoppedAnimation<Color>(
                Color(0xFF6C63FF),
              ),
              minHeight: 3,
            ),
          Expanded(
            child: Stack(
              children: [
                InAppWebView(
                  initialUrlRequest: URLRequest(
                    url: WebUri('https://www.jenta.pro'),
                    headers: {
                      'Referer': 'https://www.jenta.pro/',
                      'Origin': 'https://www.jenta.pro',
                    },
                  ),
                  initialSettings: InAppWebViewSettings(
                    javaScriptEnabled: true,
                    useShouldOverrideUrlLoading: true,
                    mediaPlaybackRequiresUserGesture: false,
                    allowsInlineMediaPlayback: true,
                    javaScriptCanOpenWindowsAutomatically: true,
                    supportMultipleWindows: false,
                    allowUniversalAccessFromFileURLs: true,
                    allowFileAccessFromFileURLs: true,
                    disableDefaultErrorPage: true,
                    userAgent: defaultTargetPlatform == TargetPlatform.macOS
                        ? 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36'
                        : 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36',
                  ),
                  onWebViewCreated: (controller) {},
                  onProgressChanged: (controller, progress) {
                    setState(() {
                      _progress = progress / 100;
                    });
                  },
                  shouldOverrideUrlLoading:
                      (controller, navigationAction) async {
                        return NavigationActionPolicy.ALLOW;
                      },
                  onReceivedServerTrustAuthRequest:
                      (controller, challenge) async {
                        return ServerTrustAuthResponse(
                          action: ServerTrustAuthResponseAction.PROCEED,
                        );
                      },
                  onLoadStop: (controller, url) async {
                    setState(() {
                      _progress = 1.0;
                    });
                    await controller.evaluateJavascript(
                      source: '''
                  (function() {
                    // ── Intercept fetch() calls ──
                    const originalFetch = window.fetch;
                    window.fetch = function(url, options) {
                      options = options || {};
                      const method = (options.method || 'GET').toUpperCase();
                      console.log('[API →] ' + method + ' ' + url);
                      if (options.body) {
                        try {
                          console.log('[API → BODY] ' + (typeof options.body === 'string' ? options.body.substring(0, 500) : JSON.stringify(options.body).substring(0, 500)));
                        } catch(e) {}
                      }
                      
                      options.headers = options.headers || {};
                      if (options.headers instanceof Headers) {
                        const headerObj = {};
                        options.headers.forEach((value, key) => {
                          headerObj[key] = value;
                        });
                        options.headers = headerObj;
                      }
                      
                      if (url && url.toString().includes('generativelanguage.googleapis.com')) {
                        options.mode = 'cors';
                        options.credentials = 'omit';
                      }
                      
                      return originalFetch.call(this, url, options).then(function(response) {
                        console.log('[API ←] ' + response.status + ' ' + method + ' ' + url);
                        // Clone to read body without consuming the stream
                        const cloned = response.clone();
                        cloned.text().then(function(body) {
                          console.log('[API ← BODY] ' + url.toString().split('?')[0] + ' → ' + body.substring(0, 300));
                        }).catch(function() {});
                        return response;
                      }).catch(function(err) {
                        console.log('[API ✗] FAILED ' + method + ' ' + url + ' → ' + err.message);
                        throw err;
                      });
                    };

                    // ── Intercept XMLHttpRequest calls ──
                    const originalXHROpen = XMLHttpRequest.prototype.open;
                    const originalXHRSend = XMLHttpRequest.prototype.send;
                    
                    XMLHttpRequest.prototype.open = function(method, url) {
                      this._apiMethod = method;
                      this._apiUrl = url;
                      return originalXHROpen.apply(this, arguments);
                    };
                    
                    XMLHttpRequest.prototype.send = function(body) {
                      console.log('[XHR →] ' + (this._apiMethod || 'GET').toUpperCase() + ' ' + this._apiUrl);
                      if (body) {
                        try {
                          console.log('[XHR → BODY] ' + (typeof body === 'string' ? body.substring(0, 500) : '(binary)'));
                        } catch(e) {}
                      }
                      
                      this.addEventListener('load', function() {
                        console.log('[XHR ←] ' + this.status + ' ' + (this._apiMethod || 'GET').toUpperCase() + ' ' + this._apiUrl);
                        try {
                          console.log('[XHR ← BODY] ' + (this.responseText || '').substring(0, 300));
                        } catch(e) {}
                      });
                      
                      this.addEventListener('error', function() {
                        console.log('[XHR ✗] FAILED ' + (this._apiMethod || 'GET').toUpperCase() + ' ' + this._apiUrl);
                      });
                      
                      return originalXHRSend.apply(this, arguments);
                    };
                    
                    // ── Hide header/navbar elements ──
                    var selectors = [
                      'header',
                      'nav',
                      '.navbar',
                      '.header',
                      '[class*="navbar"]',
                      '[class*="header"]',
                      '[class*="nav-bar"]'
                    ];
                    selectors.forEach(function(sel) {
                      var elements = document.querySelectorAll(sel);
                      elements.forEach(function(el) {
                        el.style.display = 'none';
                      });
                    });
                    
                    console.log('[API Monitor] Active - all fetch/XHR calls will be logged');
                  })();
                ''',
                    );
                  },
                  onReceivedError: (controller, request, error) {
                    debugPrint(
                      'WebView error: ${error.type} - ${error.description}',
                    );
                  },
                  onReceivedHttpError: (controller, request, response) {
                    debugPrint(
                      'HTTP error: ${response.statusCode} - ${response.reasonPhrase}',
                    );
                  },
                  onConsoleMessage: (controller, consoleMessage) {
                    debugPrint('Console: ${consoleMessage.message}');
                  },
                ),
                // Overlay header bar with profile button
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: 25,
                  child: Container(
                    color: const Color(0xFF0D0D0D),
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 4),
                    child: GestureDetector(
                      onTap: () => _scaffoldKey.currentState?.openEndDrawer(),
                      child: const Icon(
                        Icons.account_circle,
                        color: Colors.white70,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: const Color(0xFF6C63FF)),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ],
    );
  }
}
