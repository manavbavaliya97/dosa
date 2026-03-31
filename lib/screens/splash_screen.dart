import 'package:flutter/material.dart';
import 'billing_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _animations;

  @override
  void initState() {
    super.initState();

    // Create animation controllers for each dot
    _controllers = List.generate(
      3,
      (index) => AnimationController(
        duration: const Duration(milliseconds: 600),
        vsync: this,
      ),
    );

    // Create bouncing animations
    _animations = _controllers.map((controller) {
      return Tween<double>(begin: 0, end: -15).animate(
        CurvedAnimation(
          parent: controller,
          curve: Curves.easeInOut,
          reverseCurve: Curves.easeInOut,
        ),
      );
    }).toList();

    // Start staggered bouncing
    _startBouncing();

    // Navigate after 2 seconds
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const BillingScreen()),
        );
      }
    });
  }

  void _startBouncing() async {
    // Continuous bouncing - dots go up one by one, then down together
    while (mounted) {
      // First dot up
      _controllers[0].forward();
      await Future.delayed(const Duration(milliseconds: 150));
      if (!mounted) return;

      // Second dot up
      _controllers[1].forward();
      await Future.delayed(const Duration(milliseconds: 150));
      if (!mounted) return;

      // Third dot up
      _controllers[2].forward();
      await Future.delayed(const Duration(milliseconds: 300));
      if (!mounted) return;

      // All dots down together
      _controllers[2].reverse();
      _controllers[1].reverse();
      _controllers[0].reverse();
      await Future.delayed(const Duration(milliseconds: 600));
      if (!mounted) return;
    }
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF6e88b0),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo icon
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.asset(
                'assets/images/app_icon.png',
                width: 150,
                height: 150,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 30),
            // App name
            const Text(
              'Malhar Dosa',
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 10),
            // Tagline
            const Text(
              'Welcome to Malhar Dosa',
              style: TextStyle(fontSize: 20, color: Colors.white70),
            ),
            const SizedBox(height: 50),
            // Loading animation - bouncing dots
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildDot(0),
                const SizedBox(width: 8),
                _buildDot(1),
                const SizedBox(width: 8),
                _buildDot(2),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDot(int index) {
    return AnimatedBuilder(
      animation: _animations[index],
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _animations[index].value),
          child: Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(6),
            ),
          ),
        );
      },
    );
  }
}
