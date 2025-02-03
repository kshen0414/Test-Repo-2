// screens/bank/connect_bank_button.dart

import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:basic_ui_2/services/finverse_service.dart';

class ConnectBankButton extends StatefulWidget {
  final Function(Map<String, dynamic>) onAccountsFetched;
  final Function(String) onError;

  const ConnectBankButton({
    Key? key,
    required this.onAccountsFetched,
    required this.onError,
  }) : super(key: key);

  @override
  _ConnectBankButtonState createState() => _ConnectBankButtonState();
}

class _ConnectBankButtonState extends State<ConnectBankButton> {
  final FinverseService _finverseService = FinverseService();
  String? _linkUrl;
  bool _isLoading = false;
  WebViewController? _webViewController;
  bool _showWebView = false;
  String? _webViewError;

Future<void> _initializeFinverseLink() async {
  print("Starting _initializeFinverseLink");
  setState(() {
    _isLoading = true;
    _webViewError = null;
  });

  try {
    final linkUrl = await _finverseService.generateLinkToken(
      'someUserId',
      'someUniqueState',
    );
    print("Received link URL: $linkUrl");
    print("Link URL length: ${linkUrl.length}");

    if (linkUrl.length < 100) {
      print("Warning: Link URL seems shorter than expected");
    }

    setState(() {
      _linkUrl = linkUrl;
    });

    // Initialize WebView first
    _initWebView();

    // Then navigate to full screen with initialized WebView
    // Show WebView in a new route with proper constraints
      await Navigator.of(context).push(
        MaterialPageRoute(
          fullscreenDialog: true,
          builder: (context) => Scaffold(
            appBar: AppBar(
              title: const Text('Connect Bank Account'),
              leading: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            body: SafeArea(
              child: Container(
                width: double.infinity,
                height: double.infinity,
                child: WebViewWidget(controller: _webViewController!),
              ),
            ),
          ),
        ),
      );

    setState(() {
      _showWebView = false;
      _isLoading = false;
    });

  } catch (e) {
    print("Error in _initializeFinverseLink: $e");
    widget.onError('Failed to initialize Finverse Link: ${e.toString()}');
    setState(() {
      _isLoading = false;
    });
  }
}

void _initWebView() {
    if (_linkUrl != null) {
      _webViewController = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..addJavaScriptChannel(
          'Flutter',
          onMessageReceived: (JavaScriptMessage message) {
            _handleJavaScriptMessage(message.message);
          },
        )
        ..setNavigationDelegate(
          NavigationDelegate(
            onPageStarted: (String url) {
              print('Page started loading: $url');
            },
            onPageFinished: (String url) {
              print('Page finished loading: $url');
              _injectJavaScript();
            },
            onUrlChange: (UrlChange change) {
              final url = change.url;
              if (url != null) {
                _checkForSuccessPage(url);
              }
            },
            onWebResourceError: (WebResourceError error) {
              setState(() {
                _webViewError = "Failed to load page: ${error.description}";
              });
            },
          ),
        )
        ..loadRequest(Uri.parse(_linkUrl!));
    }
  }

  void _injectJavaScript() {
    const script = '''
      (function() {
        window.addEventListener('message', function(event) {
          Flutter.postMessage(JSON.stringify(event.data));
        });
      })();
    ''';
    _webViewController?.runJavaScript(script);
  }

  void _handleJavaScriptMessage(String message) {
    print("Received message from WebView: $message");
    try {
      if (message == '"success"') {
        _onSuccess();
      } else {
        final data = json.decode(message);
        if (data is Map<String, dynamic> && data['login_identity'] != null) {
          _onSuccess(data['login_identity']);
        } else if (data == "close") {
          _onClose();
        }
      }
    } catch (e) {
      print("Error parsing message: $e");
    }
  }

  void _checkForSuccessPage(String url) {
    if (url.contains('type=success')) {
      print("Detected success page: $url");
      _handleSuccess(url);
    }
  }

  void _handleSuccess(String url) {
    print("Handling success. URL: $url");

    Uri uri = Uri.parse(url);
    String? linkStatusId = uri.queryParameters['linkStatusId'];
    String? institutionId = uri.queryParameters['institutionId'];
    String? code = uri.queryParameters['code'];

    print("Extracted linkStatusId: $linkStatusId");
    print("Extracted institutionId: $institutionId");
    print("Extracted code: $code");

    if (code != null) {
      _exchangeCodeForToken(code);
    } else {
      print("Error: No code found in success URL");
      widget.onError("No authorization code found");
    }

    setState(() {
      _showWebView = false;
    });
  }

  void _exchangeCodeForToken(String code) async {
    print("Exchanging code for token: $code");
    setState(() {
      _isLoading = true;
    });

    try {
      final loginIdentityToken = await _finverseService.linkCode(code);
      _onSuccess(loginIdentityToken);
    } catch (e) {
      print("Error exchanging code for token: $e");
      widget.onError("Failed to exchange code for token: $e");
    }
  }

  void _onSuccess([String? loginIdentityToken]) async {
    print("Finverse Link successful");
    setState(() {
      _isLoading = true;
    });

    try {
      if (loginIdentityToken != null) {
        _finverseService.setLoginIdentityToken(loginIdentityToken);
      }
      await _finverseService.handleWebViewSuccess();
      print("Fetching accounts data");
      final accounts = await _finverseService.getAccounts();
      widget.onAccountsFetched(accounts);
    } catch (e) {
      print("Error in _onSuccess: $e");
      widget.onError('Error processing success: ${e.toString()}');
    } finally {
      setState(() {
        _isLoading = false;
        _showWebView = false;
      });
    }
  }

  void _onClose() {
    print("Finverse Link closed");
    widget.onError('Finverse Link process was closed');
    setState(() {
      _showWebView = false;
    });
  }

@override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (_showWebView && _webViewController != null) {
          return Container(
            width: constraints.maxWidth,
            height: constraints.maxHeight,
            child: WebViewWidget(controller: _webViewController!),
          );
        }

        return Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: _isLoading ? null : _initializeFinverseLink,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(color: Colors.white),
                      )
                    : const Text('Connect Bank Account'),
              ),
            ),
          ),
        );
      },
    );
  }

}
