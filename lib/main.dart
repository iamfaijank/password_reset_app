import 'package:flutter/material.dart';
import 'api_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final apiService = ApiService();
  await apiService.init();
  runApp(MyApp(apiService: apiService));
}

class MyApp extends StatefulWidget {
  final ApiService apiService;
  const MyApp({super.key, required this.apiService});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late Future<bool> _isLoggedInFuture;

  @override
  void initState() {
    super.initState();
    _isLoggedInFuture = widget.apiService.isLoggedIn();
  }

  void _onLoginSuccess() {
    setState(() {
      _isLoggedInFuture = Future.value(true);
    });
  }

  void _onLogout() {
    setState(() {
      _isLoggedInFuture = Future.value(false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Password Reset',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: FutureBuilder<bool>(
        future: _isLoggedInFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          } else if (snapshot.hasError) {
            return Scaffold(
              body: Center(child: Text('Error: ${snapshot.error}')),
            );
          } else {
            if (snapshot.data == true) {
              return PasswordResetScreen(apiService: widget.apiService, onLogout: _onLogout);
            } else {
              return LoginScreen(apiService: widget.apiService, onLoginSuccess: _onLoginSuccess);
            }
          }
        },
      ),
    );
  }
}

class LoginScreen extends StatefulWidget {
  final ApiService apiService;
  final VoidCallback onLoginSuccess;

  const LoginScreen({super.key, required this.apiService, required this.onLoginSuccess});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  String _statusMessage = '';
  bool _isLoading = false;

  Future<void> _login() async {
    setState(() {
      _isLoading = true;
      _statusMessage = '';
    });

    try {
      await widget.apiService.login(_usernameController.text, _passwordController.text);
      widget.onLoginSuccess();
    } catch (e) {
      setState(() {
        _statusMessage = 'Error: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Login'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Container(
              width: 15.0,
              height: 15.0,
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _usernameController,
              decoration: const InputDecoration(
                labelText: 'Username',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Password',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isLoading ? null : _login,
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Login'),
            ),
            if (_statusMessage.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: Text(
                  _statusMessage,
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class PasswordResetScreen extends StatefulWidget {
  final ApiService apiService;
  final VoidCallback onLogout;

  const PasswordResetScreen({super.key, required this.apiService, required this.onLogout});

  @override
  State<PasswordResetScreen> createState() => _PasswordResetScreenState();
}

class _PasswordResetScreenState extends State<PasswordResetScreen> {
  final _empIdController = TextEditingController();
  final _newPasswordController = TextEditingController();

  String _statusMessage = '';
  Map<String, dynamic>? _userDetails;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User is logged in now')),
      );
    });
  }

  Future<void> _getUserDetails() async {
    if (_empIdController.text.isEmpty) {
      setState(() {
        _statusMessage = 'Please enter an Employee ID.';
        _userDetails = null;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _statusMessage = '';
      _userDetails = null;
    });

    try {
      final details = await widget.apiService.getUserDetails(_empIdController.text);
      setState(() {
        _userDetails = details;
        _statusMessage = 'User details found.';
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Error: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _resetPassword() async {
    if (_newPasswordController.text.isEmpty) {
      setState(() {
        _statusMessage = 'Please enter a new password.';
      });
      return;
    }

    if (_userDetails == null || _userDetails!['email'] == null) {
      setState(() {
        _statusMessage = 'Could not find user email to reset password.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _statusMessage = '';
    });

    try {
      await widget.apiService.resetUserPassword(
        _userDetails!['email'],
        _newPasswordController.text,
      );
      setState(() {
        _statusMessage = 'Password has been reset successfully!';
        _userDetails = null; // Clear details after reset
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Error: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    String? userFullName = widget.apiService.loggedInUserFullName;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Password Reset'),
        actions: const [
          Center(child: BlinkingStatusDot(color: Colors.green, size: 15.0)),
          SizedBox(width: 8),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (userFullName != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Welcome, $userFullName!',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    TextButton.icon(
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.black, // Set color to black
                      ),
                      icon: const Icon(Icons.logout, color: Colors.black), // Icon also black
                      label: const Text('Logout', style: TextStyle(color: Colors.black)),
                      onPressed: () async {
                        await widget.apiService.logout();
                        widget.onLogout();
                      },
                    ),
                  ],
                ),
              ),
            TextField(
              controller: _empIdController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Employee ID',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isLoading ? null : _getUserDetails,
              child: _isLoading && _userDetails == null
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Get User Details'),
            ),
            const SizedBox(height: 24),
            if (_statusMessage.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: Text(
                  _statusMessage,
                  style: TextStyle(
                    color: _statusMessage.contains('Error') || _statusMessage.contains('Please')
                        ? Colors.red
                        : Colors.green,
                  ),
                ),
              ),
            if (_userDetails != null) ...[
              const Text(
                'User Details:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text('Name: ${_userDetails!['full_name'] ?? 'N/A'}'),
              Text('Email: ${_userDetails!['email'] ?? 'N/A'}'),
              const SizedBox(height: 24),
              TextField(
                controller: _newPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'New Password',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _isLoading ? null : _resetPassword,
                child: _isLoading && _userDetails != null
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Reset Password'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class BlinkingStatusDot extends StatefulWidget {
  final Color color;
  final double size;

  const BlinkingStatusDot({super.key, required this.color, this.size = 15.0});

  @override
  State<BlinkingStatusDot> createState() => _BlinkingStatusDotState();
}

class _BlinkingStatusDotState extends State<BlinkingStatusDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _controller,
      child: Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          color: widget.color,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}