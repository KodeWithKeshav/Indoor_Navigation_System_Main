import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/signup_provider.dart';
import '../../domain/usecases/signup_usecase.dart';
import '../../../admin_map/domain/entities/organization.dart';

class SignUpScreen extends ConsumerStatefulWidget {
  const SignUpScreen({super.key});

  @override
  ConsumerState<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends ConsumerState<SignUpScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  String? _selectedOrganizationId;
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  // Animation Controllers
  late AnimationController
  _gridScrollController; // Renamed from _backgroundController to match Login
  late AnimationController _sonarController;
  late AnimationController _entranceController;

  // Animations
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    // 1. Grid/Background Animation
    _gridScrollController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();

    // 2. Sonar Pulse Loop
    _sonarController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();

    // 3. One-shot Entrance Sequence
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

    // Slide Up Content
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
    _confirmPasswordController.dispose();
    _gridScrollController.dispose();
    _sonarController.dispose();
    _entranceController.dispose();
    super.dispose();
  }

  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedOrganizationId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('ORGANIZATION_REQUIRED')));
      return;
    }
    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('PASSWORDS_DO_NOT_MATCH')));
      return;
    }

    setState(() => _isLoading = true);

    final signUpUseCase = ref.read(signUpUseCaseProvider);
    final result = await signUpUseCase(
      SignUpParams(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        organizationId: _selectedOrganizationId!,
      ),
    );

    if (mounted) {
      setState(() => _isLoading = false);
      result.fold(
        (failure) => ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(failure.message))),
        (user) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('REGISTRATION_COMPLETE')),
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // --- COLORS (Matching LoginScreen) ---
    // Deep Void Blue (Bottom/Edges)
    const deepVoidBlue = Color(0xFF020617);
    // Lighter Royal Blue (Top/Center Light source)
    const topLightBlue = Color(0xFF1E3A8A);

    // Dark Charcoal Blue for the Card
    const darkCardColor = Color(0xFF1A1F2C);

    const activeCardBlue = Color(0xFF172554); // For Logo Circle
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

          // 1. Moving Grid Background (Reusing BlueprintGridPainter)
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
                            width: 100, // Matched Login Size
                            height: 100,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: paperWhite, width: 3),
                              color: activeCardBlue,
                            ),
                            child: const Icon(
                              Icons.person_add_alt_1_rounded,
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
                        constraints: const BoxConstraints(maxWidth: 450),
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          color: darkCardColor.withOpacity(
                            0.95,
                          ), // Matched dark card color
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
                                // --- HEADER ---
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
                                  "SYSTEM REGISTRATION",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: paperWhite,
                                    fontSize: 22,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1,
                                  ),
                                ),
                                const SizedBox(height: 32),

                                // --- INPUTS ---
                                _buildBlueprintInput(
                                  controller: _emailController,
                                  label: "USER EMAIL",
                                  icon: Icons.email_outlined,
                                  accentColor: electricGrid,
                                ),
                                const SizedBox(height: 24),

                                // Organization Dropdown (Custom Styled)
                                Consumer(
                                  builder: (context, ref, _) {
                                    final orgsAsync = ref.watch(
                                      organizationListProvider,
                                    );
                                    return _buildBlueprintDropdown(
                                      orgsAsync: orgsAsync,
                                      label: "ORGANIZATION UNIT",
                                      icon: Icons.domain,
                                      accentColor: electricGrid,
                                    );
                                  },
                                ),
                                const SizedBox(height: 24),

                                _buildBlueprintInput(
                                  controller: _passwordController,
                                  label: "PASSWORD",
                                  icon: Icons.lock_outline,
                                  isPassword: true,
                                  obscureText: _obscurePassword,
                                  onToggle: () => setState(
                                    () => _obscurePassword = !_obscurePassword,
                                  ),
                                  accentColor: electricGrid,
                                ),
                                const SizedBox(height: 24),
                                _buildBlueprintInput(
                                  controller: _confirmPasswordController,
                                  label: "CONFIRM PASSWORD",
                                  icon: Icons.verified_user_outlined,
                                  isPassword: true,
                                  obscureText: _obscureConfirmPassword,
                                  onToggle: () => setState(
                                    () => _obscureConfirmPassword =
                                        !_obscureConfirmPassword,
                                  ),
                                  accentColor: electricGrid,
                                ),

                                const SizedBox(height: 40),

                                // --- BUTTON ---
                                SizedBox(
                                  width: double.infinity,
                                  height: 56,
                                  child: ElevatedButton(
                                    onPressed: _isLoading ? null : _signUp,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: electricGrid,
                                      foregroundColor: deepVoidBlue,
                                      shape: const RoundedRectangleBorder(),
                                      elevation: 0,
                                    ),
                                    child: _isLoading
                                        ? CircularProgressIndicator(
                                            color: deepVoidBlue,
                                          )
                                        : const Text(
                                            "INITIATE SEQUENCE",
                                            style: TextStyle(
                                              fontWeight: FontWeight.w900,
                                              fontSize: 16,
                                              letterSpacing: 1,
                                            ),
                                          ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Footer
                  const SizedBox(height: 24),
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          "ALREADY AUTHENTICATED? ",
                          style: TextStyle(
                            color: Colors.white60,
                            fontFamily: 'Courier',
                            fontSize: 12,
                          ),
                        ),
                        InkWell(
                          onTap: () => context.go('/login'),
                          child: Text(
                            "[ LOGIN ]",
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

  // --- Widgets ---

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
            if (isPassword && val.length < 6) return 'MIN 6 CHARS REQUIRED';
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildBlueprintDropdown({
    required AsyncValue<List<Organization>> orgsAsync,
    required String label,
    required IconData icon,
    required Color accentColor,
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
        orgsAsync.when(
          data: (orgs) => DropdownButtonFormField<String>(
            dropdownColor: const Color(0xFF0F172A), // Matches background
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
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
            ),
            value: _selectedOrganizationId,
            items: orgs
                .map(
                  (org) =>
                      DropdownMenuItem(value: org.id, child: Text(org.name)),
                )
                .toList(),
            onChanged: (val) => setState(() => _selectedOrganizationId = val),
            validator: (val) => val == null ? 'REQUIRED' : null,
          ),
          loading: () => Container(
            height: 60,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.white54),
            ),
            child: const Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),
          ),
          error: (e, _) => Text(
            'ERR: $e',
            style: const TextStyle(color: Colors.orangeAccent),
          ),
        ),
      ],
    );
  }
}

// --- PAINTERS (Reused from LoginScreen to match style) ---

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
