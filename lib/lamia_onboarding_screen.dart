import 'dart:ui';
import 'package:flutter/material.dart';
import 'login_screen.dart';

// ===== Colors =====
const Color brandPurple = Color(0xFFC77BBA);
const Color brandOrange = Color(0xFFF05D42);

// ===== Data Model =====
class OnboardingStepData {
  final String title;
  final String description;
  final Color accent;
  final List<IconData> iconsTop;
  final IconData iconBottom;

  const OnboardingStepData({
    required this.title,
    required this.description,
    required this.accent,
    required this.iconsTop,
    required this.iconBottom,
  });
}

// ===== Steps =====
const List<OnboardingStepData> steps = [
  OnboardingStepData(
    title: 'مواعيدك أذكى مع مرسال',
    description:
        'يقوم مرسال بحساب أفضل وقت للمغادرة بناءً على حالة المرور والطقس والمسافة لتصل في الوقت المحدد دائمًا.',
    accent: brandPurple,
    iconsTop: [Icons.cloud_outlined, Icons.access_time_rounded],
    iconBottom: Icons.directions_car_rounded,
  ),
  OnboardingStepData(
    title: 'تنبيهات قبل لا تفوتك',
    description:
        'نذكّرك قبل الموعد بوقت كافي مع اقتراح وقت الخروج المناسب حسب الازدحام.',
    accent: brandOrange,
    iconsTop: [Icons.notifications_none_rounded, Icons.calendar_month_outlined],
    iconBottom: Icons.alarm_rounded,
  ),
  OnboardingStepData(
    title: 'خطّط لجلساتك بسهولة',
    description:
        'اجمع مواعيدك ولقاءاتك في مكان واحد وخلّ مرسال يرتّبها لك بشكل واضح.',
    accent: Color(0xFF8A7CF6),
    iconsTop: [Icons.event_available_outlined, Icons.map_outlined],
    iconBottom: Icons.group_outlined,
  ),
];

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  late final PageController _controller;
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _controller = PageController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get isLast => _index == steps.length - 1;

  void _goLogin() {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  void _next() {
    if (!isLast) {
      _controller.nextPage(
        duration: const Duration(milliseconds: 420),
        curve: Curves.easeOutCubic,
      );
      return;
    }
    _goLogin();
  }

  void _skip() => _goLogin();

  @override
  Widget build(BuildContext context) {
    final current = steps[_index];

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // ===== Header =====
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const GradientText(
                    'مرسال',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.6,
                    ),
                  ),

                  // Skip (كبرنا مساحة الضغط)
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: _skip,
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                      child: Text(
                        'تخطي',
                        style: TextStyle(
                          color: brandOrange,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ===== Content =====
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: steps.length,
                onPageChanged: (i) => setState(() => _index = i),
                physics: const BouncingScrollPhysics(),
                itemBuilder: (context, i) => _OnboardingSlide(step: steps[i]),
              ),
            ),

            // ===== Indicators =====
            Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 18),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(steps.length, (i) {
                  final active = i == _index;
                  final color = active ? steps[i].accent : const Color(0xFFD5D5D5);

                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 350),
                    curve: Curves.easeOutCubic,
                    margin: const EdgeInsets.symmetric(horizontal: 5),
                    width: active ? 30 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: active ? color : color.withOpacity(0.55),
                      borderRadius: BorderRadius.circular(999),
                      boxShadow: active
                          ? [
                              BoxShadow(
                                color: steps[_index].accent.withOpacity(0.25),
                                blurRadius: 14,
                                offset: const Offset(0, 6),
                              ),
                            ]
                          : [],
                    ),
                  );
                }),
              ),
            ),

            // ===== Button =====
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 22),
              child: MersalGradientButton(
                text: isLast ? 'ابدأ' : 'التالي',
                onTap: _next,
                shadowColor: current.accent,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardingSlide extends StatelessWidget {
  const _OnboardingSlide({required this.step});

  final OnboardingStepData step;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          const SizedBox(height: 10),
          Expanded(
            child: Center(
              child: SizedBox(
                width: 330,
                height: 330,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SoftGlow(color: step.accent),

                    Container(
                      width: 235,
                      height: 235,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: step.accent.withOpacity(0.06),
                        boxShadow: [
                          BoxShadow(
                            color: step.accent.withOpacity(0.10),
                            blurRadius: 32,
                            offset: const Offset(0, 14),
                          )
                        ],
                      ),
                    ),

                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            GlassIconCard(
                              glowColor: step.accent,
                              child: Icon(
                                step.iconsTop[0],
                                size: 42,
                                color: step.accent.withOpacity(0.95),
                              ),
                            ),
                            const SizedBox(width: 20),
                            GlassIconCard(
                              glowColor: step.accent,
                              child: Icon(
                                step.iconsTop[1],
                                size: 42,
                                color: step.accent.withOpacity(0.90),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 22),
                        GlassIconCard(
                          glowColor: step.accent,
                          child: Icon(
                            step.iconBottom,
                            size: 42,
                            color: step.accent.withOpacity(0.95),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Text(
              step.title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 26,
                height: 1.25,
                fontWeight: FontWeight.w800,
                color: Color(0xFF2B2B2B),
                letterSpacing: -0.3,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 28),
            child: Text(
              step.description,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 15,
                height: 1.75,
                color: Color(0xFF6B6B6B),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ===== Widgets =====

class GradientText extends StatelessWidget {
  const GradientText(this.text, {super.key, required this.style});
  final String text;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback: (bounds) => const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [brandPurple, brandOrange],
      ).createShader(bounds),
      child: Text(text, style: style.copyWith(color: Colors.white)),
    );
  }
}

class SoftGlow extends StatelessWidget {
  const SoftGlow({super.key, required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) {
    return ImageFiltered(
      imageFilter: ImageFilter.blur(sigmaX: 44, sigmaY: 44),
      child: Container(
        width: 280,
        height: 280,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              color.withOpacity(0.26),
              color.withOpacity(0.10),
              Colors.transparent,
            ],
            stops: const [0.0, 0.55, 1.0],
          ),
        ),
      ),
    );
  }
}

class GlassIconCard extends StatelessWidget {
  const GlassIconCard({
    super.key,
    required this.child,
    required this.glowColor,
  });

  final Widget child;
  final Color glowColor;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: ImageFiltered(
            imageFilter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: glowColor.withOpacity(0.16),
                borderRadius: BorderRadius.circular(22),
              ),
            ),
          ),
        ),
        ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.78),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: Colors.white.withOpacity(0.42)),
                boxShadow: [
                  BoxShadow(
                    color: glowColor.withOpacity(0.12),
                    blurRadius: 24,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: child,
            ),
          ),
        ),
      ],
    );
  }
}

class MersalGradientButton extends StatelessWidget {
  const MersalGradientButton({
    super.key,
    required this.text,
    required this.onTap,
    required this.shadowColor,
  });

  final String text;
  final VoidCallback onTap;
  final Color shadowColor;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        height: 58,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [brandPurple, brandOrange],
          ),
          boxShadow: [
            BoxShadow(
              color: shadowColor.withOpacity(0.24),
              blurRadius: 26,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.2,
          ),
        ),
      ),
    );
  }
}