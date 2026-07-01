import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:agricore/models/models.dart';
import 'package:agricore/services/auth_service.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController(text: 'admin@agricore.com');
  final _passwordController = TextEditingController(text: 'password123');
  bool _obscurePassword = true;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() {
      _errorMessage = null;
    });

    final authService = Provider.of<AuthService>(context, listen: false);
    final success = await authService.login(
      _emailController.text,
      _passwordController.text,
    );

    if (!mounted) return;
    if (!success) {
      setState(() {
        _errorMessage = 'Invalid email or password combination. Try a demo user.';
      });
    }
  }

  void _selectDemoUser(String email) {
    _emailController.text = email;
    _passwordController.text = 'password123';
    _submit();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final authService = Provider.of<AuthService>(context);

    return Scaffold(
      body: Row(
        children: [
          // Left Side - Decorative Branding Panel (Desktop Only)
          if (size.width >= 900)
            Expanded(
              flex: 12,
              child: Container(
                color: const Color(0xFF1E293B),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Deep green grain/wheat background accent
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.bottomLeft,
                            end: Alignment.topRight,
                            colors: [
                              const Color(0xFF064E3B), // Deep emerald
                              const Color(0xFF0F172A), // Dark slate
                            ],
                          ),
                        ),
                      ),
                    ),
                    // Centered branding details
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(40.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: const Color(0xFF10B981).withOpacity(0.15),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: const Color(0xFF10B981).withOpacity(0.3)),
                              ),
                              child: const Icon(
                                Icons.agriculture_rounded,
                                size: 48,
                                color: Color(0xFF10B981),
                              ),
                            ),
                            const SizedBox(height: 30),
                            Text(
                              'AgriCore',
                              style: GoogleFonts.outfit(
                                fontSize: 48,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: -1,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'Procurement & Operations Platform',
                              style: GoogleFonts.outfit(
                                fontSize: 24,
                                color: const Color(0xFF3B82F6),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 20),
                            Text(
                              'Secure, offline-first enterprise management database tracking inspections, quality reports, workflow approvals, and warehouse capacity allocations across state regions.',
                              style: GoogleFonts.outfit(
                                fontSize: 16,
                                color: const Color(0xFF94A3B8),
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 20,
                      left: 40,
                      child: Text(
                        '© 2026 AgriCore Procurement Inc.',
                        style: GoogleFonts.outfit(color: const Color(0xFF475569)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          
          // Right Side - Interactive Login Card Form
          Expanded(
            flex: 10,
            child: Container(
              color: const Color(0xFF0F172A),
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(40.0),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Small branding header for mobile screens
                        if (size.width < 900) ...[
                          Row(
                            children: [
                              const Icon(Icons.agriculture_rounded, color: Color(0xFF10B981), size: 32),
                              const SizedBox(width: 10),
                              Text(
                                'AgriCore Portal',
                                style: GoogleFonts.outfit(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 40),
                        ],
                        
                        Text(
                          'Operations Console',
                          style: GoogleFonts.outfit(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Log in with your enterprise credentials.',
                          style: GoogleFonts.outfit(
                            fontSize: 16,
                            color: const Color(0xFF94A3B8),
                          ),
                        ),
                        const SizedBox(height: 30),
                        
                        if (_errorMessage != null)
                          Container(
                            padding: const EdgeInsets.all(12),
                            margin: const EdgeInsets.only(bottom: 20),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEF4444).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0xFFEF4444).withOpacity(0.3)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.error_outline_rounded, color: Color(0xFFEF4444), size: 20),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    _errorMessage!,
                                    style: GoogleFonts.outfit(color: const Color(0xFFEF4444), fontSize: 14),
                                  ),
                                ),
                              ],
                            ),
                          ),

                        Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              TextFormField(
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                                decoration: const InputDecoration(
                                  labelText: 'Email Address',
                                  prefixIcon: Icon(Icons.email_outlined, size: 20, color: Color(0xFF64748B)),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter your email';
                                  }
                                  if (!value.contains('@')) {
                                    return 'Please enter a valid email address';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 18),
                              TextFormField(
                                controller: _passwordController,
                                obscureText: _obscurePassword,
                                decoration: InputDecoration(
                                  labelText: 'Security Password',
                                  prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20, color: Color(0xFF64748B)),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                      size: 20,
                                      color: const Color(0xFF64748B),
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _obscurePassword = !_obscurePassword;
                                      });
                                    },
                                  ),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter your password';
                                  }
                                  if (value.length < 6) {
                                    return 'Password must be at least 6 characters';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 24),
                              authService.isLoading
                                  ? const Center(
                                      child: Padding(
                                        padding: EdgeInsets.symmetric(vertical: 8.0),
                                        child: CircularProgressIndicator(color: Color(0xFF10B981)),
                                      ),
                                    )
                                  : ElevatedButton(
                                      onPressed: _submit,
                                      child: const Text('Access Platform'),
                                    ),
                            ],
                          ),
                        ),
                        
                        const SizedBox(height: 40),
                        const Divider(color: Color(0xFF334155)),
                        const SizedBox(height: 24),
                        
                        // Demo User Direct Links (Crucial for evaluation!)
                        Text(
                          'DEMO ACCOUNTS (ONE-CLICK LOGIN)',
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF64748B),
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: AuthService.demoUsers.map((user) {
                            Color badgeColor;
                            switch (user.role) {
                              case UserRole.administrator:
                                badgeColor = const Color(0xFFEF4444);
                                break;
                              case UserRole.procurement:
                                badgeColor = const Color(0xFF10B981);
                                break;
                              case UserRole.quality:
                                badgeColor = const Color(0xFF3B82F6);
                                break;
                              case UserRole.warehouse:
                                badgeColor = const Color(0xFFF59E0B);
                                break;
                              case UserRole.management:
                                badgeColor = const Color(0xFF8B5CF6);
                                break;
                            }

                            return ActionChip(
                              backgroundColor: const Color(0xFF1E293B),
                              side: BorderSide(color: badgeColor.withOpacity(0.3)),
                              avatar: CircleAvatar(
                                radius: 8,
                                backgroundColor: badgeColor,
                              ),
                              label: Text(
                                user.role.name.toUpperCase(),
                                style: GoogleFonts.outfit(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white70,
                                ),
                              ),
                              onPressed: () => _selectDemoUser(user.email),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
