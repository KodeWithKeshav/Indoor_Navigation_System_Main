import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_controller.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with TickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  late AnimationController _sonarController;
  late AnimationController _gridScrollController;

  // Entrance Animation Controllers
  late AnimationController _entranceController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();

    // 1. Sonar Pulse Animation
    _sonarController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();

    // 2. Slow Grid Movement (Parallax effect)
    _gridScrollController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();

    // 3. Entrance "Boot Up" Animation
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    // Mechanical Pop Effect
    _scaleAnimation = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.0, 0.7, curve: Curves.easeOutBack),
    );

    // Fade In
    _fadeAnimation = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
    );

    // Slide Up Text
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _entranceController,
            curve: const Interval(0.2, 1.0, curve: Curves.easeOutCubic),
          ),
        );

    _entranceController.forward();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _sonarController.dispose();
    _gridScrollController.dispose();
    _entranceController.dispose();
    super.dispose();
  }

  void _login() {
    if (_formKey.currentState!.validate()) {
      FocusScope.of(context).unfocus();
      ref
          .read(authControllerProvider.notifier)
          .login(
            email: _emailController.text.trim(),
            password: _passwordController.text.trim(),
            context: context,
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    // --- COLORS ---
    // Deep Void Blue (Bottom/Edges)
    const deepVoidBlue = Color(0xFF020617);
    // Lighter Royal Blue (Top/Center Light source)
    const topLightBlue = Color(0xFF1E3A8A);

    // NEW: A very dark charcoal blue for the card box, matching the reference image style
    const darkCardColor = Color(0xFF1A1F2C);

    const activeCardBlue = Color(0xFF172554); // Kept for the logo circle
    const electricGrid = Color(0xFF38BDF8);
    const paperWhite = Colors.white;

    return Scaffold(
      backgroundColor: deepVoidBlue,
      body: Stack(
        children: [
          // 0. GRADIENT BACKGROUND
          Container(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.topCenter,
                radius: 1.5,
                colors: [topLightBlue, deepVoidBlue],
                stops: [0.0, 0.8],
              ),
            ),
          ),

          // 1. Moving Grid Background
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _gridScrollController,
              builder: (context, child) {
                return CustomPaint(
                  painter: BlueprintGridPainter(
                    scrollOffset: _gridScrollController.value,
                    lineColor: electricGrid.withOpacity(0.15),
                  ),
                );
              },
            ),
          ),

          // 2. Main Interface
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Sonar Logo
                  ScaleTransition(
                    scale: _scaleAnimation,
                    child: AnimatedBuilder(
                      animation: _sonarController,
                      builder: (context, child) {
                        return CustomPaint(
                          painter: SonarPainter(
                            animationValue: _sonarController.value,
                            color: paperWhite,
                          ),
                          child: Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: paperWhite, width: 3),
                              color: activeCardBlue,
                              boxShadow: [
                                BoxShadow(
                                  color: electricGrid.withOpacity(0.4),
                                  blurRadius: 20,
                                  spreadRadius: -5,
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.architecture_rounded,
                              color: paperWhite,
                              size: 48,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Technical Card
                  ScaleTransition(
                    scale: _scaleAnimation,
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: Container(
                        constraints: const BoxConstraints(maxWidth: 420),
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          // UPDATED COLOR HERE: Uses the new dark charcoal color
                          color: darkCardColor.withOpacity(0.95),
                          border: Border.all(
                            color: electricGrid.withOpacity(0.5),
                            width: 1.5,
                          ),
                          borderRadius: BorderRadius.circular(4),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.6),
                              blurRadius: 40,
                              offset: const Offset(0, 20),
                            ),
                            BoxShadow(
                              color: electricGrid.withOpacity(0.1),
                              blurRadius: 10,
                              spreadRadius: 0,
                            ),
                          ],
                        ),
                        child: Form(
                          key: _formKey,
                          child: SlideTransition(
                            position: _slideAnimation,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // --- CENTERED HEADER SECTION ---
                                Text(
                                  "CAMPUS WAYFINDER",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: electricGrid,
                                    fontFamily: 'Courier',
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                    letterSpacing: 2,
                                  ),
                                ),
                                const Padding(
                                  padding: EdgeInsets.symmetric(
                                    vertical: 24,
                                    horizontal: 40,
                                  ),
                                  child: Divider(
                                    color: Colors.white24,
                                    thickness: 1,
                                    height: 0,
                                  ),
                                ),
                                const Text(
                                  "SYSTEM LOGIN",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: paperWhite,
                                    fontSize: 24,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1,
                                  ),
                                ),
                                const SizedBox(height: 32),

                                // Inputs
                                _buildBlueprintInput(
                                  controller: _emailController,
                                  label: "USER ID",
                                  icon: Icons.person_pin_circle_outlined,
                                  accentColor: electricGrid,
                                ),
                                const SizedBox(height: 24),
                                _buildBlueprintInput(
                                  controller: _passwordController,
                                  label: "SECURITY CODE",
                                  icon: Icons.vpn_key_outlined,
                                  isPassword: true,
                                  obscureText: _obscurePassword,
                                  onToggle: () => setState(
                                    () => _obscurePassword = !_obscurePassword,
                                  ),
                                  accentColor: electricGrid,
                                ),

                                const SizedBox(height: 40),

                                // Action Button
                                Consumer(
                                  builder: (context, ref, _) {
                                    final isLoading = ref.watch(
                                      authControllerProvider,
                                    );
                                    return SizedBox(
                                      width: double.infinity,
                                      height: 56,
                                      child: ElevatedButton(
                                        onPressed: isLoading ? null : _login,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: electricGrid,
                                          foregroundColor: deepVoidBlue,
                                          shape: const RoundedRectangleBorder(),
                                          elevation: 0,
                                        ),
                                        child: isLoading
                                            ? const CircularProgressIndicator(
                                                color: deepVoidBlue,
                                              )
                                            : const Text(
                                                "ACCESS SYSTEM",
                                                style: TextStyle(
                                                  fontWeight: FontWeight.w900,
                                                  fontSize: 16,
                                                  letterSpacing: 1,
                                                ),
                                              ),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Footer technical text
                  const SizedBox(height: 24),
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          "NO CREDENTIALS? ",
                          style: TextStyle(
                            color: Colors.white60,
                            fontFamily: 'Courier',
                            fontSize: 12,
                          ),
                        ),
                        InkWell(
                          onTap: () => context.push('/signup'),
                          child: Text(
                            "[ REGISTER HERE ]",
                            style: TextStyle(
                              color: electricGrid,
                              fontFamily: 'Courier',
                              fontWeight: FontWeight.bold,
                              decoration: TextDecoration.underline,
                              decorationColor: electricGrid,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBlueprintInput({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required Color accentColor,
    bool isPassword = false,
    bool obscureText = false,
    VoidCallback? onToggle,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontFamily: 'Courier',
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
          cursorColor: accentColor,
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: Colors.white70),
            filled: true,
            fillColor: Colors.black.withOpacity(0.3),
            enabledBorder: const OutlineInputBorder(
              borderSide: BorderSide(color: Colors.white24, width: 1.0),
              borderRadius: BorderRadius.zero,
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: accentColor, width: 2.0),
              borderRadius: BorderRadius.zero,
            ),
            errorBorder: const OutlineInputBorder(
              borderSide: BorderSide(color: Colors.redAccent, width: 2),
              borderRadius: BorderRadius.zero,
            ),
            suffixIcon: isPassword
                ? IconButton(
                    icon: Icon(
                      obscureText ? Icons.visibility_off : Icons.visibility,
                      color: Colors.white54,
                    ),
                    onPressed: onToggle,
                  )
                : null,
          ),
          validator: (val) {
            if (val == null || val.isEmpty) return 'REQUIRED FIELD';
            return null;
          },
        ),
      ],
    );
  }
}

// --- Custom Painters ---

class BlueprintGridPainter extends CustomPainter {
  final double scrollOffset;
  final Color lineColor;

  BlueprintGridPainter({required this.scrollOffset, required this.lineColor});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = lineColor
      ..strokeWidth = 1;

    const gridSize = 40.0;
    final shift = (scrollOffset * gridSize);

    for (double x = -gridSize; x < size.width + gridSize; x += gridSize) {
      canvas.drawLine(
        Offset(x + shift % gridSize, 0),
        Offset(x + shift % gridSize, size.height),
        paint,
      );
    }
    for (double y = -gridSize; y < size.height + gridSize; y += gridSize) {
      canvas.drawLine(
        Offset(0, y + shift % gridSize),
        Offset(size.width, y + shift % gridSize),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant BlueprintGridPainter oldDelegate) => true;
}

class SonarPainter extends CustomPainter {
  final double animationValue;
  final Color color;

  SonarPainter({required this.animationValue, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withOpacity(1.0 - animationValue)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = size.width;

    for (int i = 0; i < 3; i++) {
      final offset = i * 0.3;
      double progress = (animationValue + offset) % 1.0;
      canvas.drawCircle(center, progress * maxRadius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant SonarPainter oldDelegate) => true;
}
