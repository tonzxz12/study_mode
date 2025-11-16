import 'package:flutter/material.dart';
import '../../core/theme/styles.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppStyles.primary.withOpacity(0.05),
            AppStyles.background,
          ],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(AppStyles.spaceXL),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(AppStyles.spaceXS),
                      decoration: BoxDecoration(
                        color: AppStyles.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(AppStyles.radiusMD),
                      ),
                      child: Image.asset(
                        'assets/images/sigma.png',
                        width: 40,
                        height: 40,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return Icon(
                            Icons.psychology_rounded,
                            size: 32,
                            color: AppStyles.primary,
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: AppStyles.spaceMD),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'SIGMA',
                            style: AppStyles.screenTitle.copyWith(
                              color: AppStyles.primary,
                              fontWeight: FontWeight.w900,
                              height: 1.1,
                            ),
                          ),
                          Text(
                            'Your Study Mate',
                            style: TextStyle(
                              color: AppStyles.foreground,
                              fontWeight: FontWeight.w600,
                              fontSize: 18,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: AppStyles.spaceXXL),
                
                // Welcome message
                Text(
                  'Welcome Back!',
                  style: AppStyles.sectionHeader.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                
                const SizedBox(height: AppStyles.spaceMD),
                
                Text(
                  'Ready to boost your productivity?',
                  style: AppStyles.bodyLarge.copyWith(
                    color: AppStyles.mutedForeground,
                  ),
                ),
                
                const SizedBox(height: AppStyles.spaceXXL),
                
                // Quick stats or placeholder content
                Container(
                  padding: const EdgeInsets.all(AppStyles.spaceLG),
                  decoration: BoxDecoration(
                    color: AppStyles.card,
                    borderRadius: BorderRadius.circular(AppStyles.radiusMD),
                    border: Border.all(
                      color: AppStyles.border,
                      width: 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.access_time_rounded,
                        size: 48,
                        color: AppStyles.primary,
                      ),
                      const SizedBox(height: AppStyles.spaceMD),
                      Text(
                        'Start Your Study Session',
                        style: AppStyles.bodyLarge.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: AppStyles.spaceXS),
                      Text(
                        'Use the timer button to begin',
                        style: AppStyles.bodyMedium.copyWith(
                          color: AppStyles.mutedForeground,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
