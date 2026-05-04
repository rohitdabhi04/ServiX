import 'package:flutter/material.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text("Privacy Policy"),
        elevation: 0,
        backgroundColor: theme.scaffoldBackgroundColor,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    theme.colorScheme.primary.withOpacity(0.12),
                    theme.colorScheme.secondary.withOpacity(0.08),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: theme.colorScheme.primary.withOpacity(0.2),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.shield_rounded,
                          color: theme.colorScheme.primary, size: 24),
                      const SizedBox(width: 10),
                      Text(
                        "Privacy Policy",
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Last updated: May 2026",
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            _sectionTitle(theme, "1. Information We Collect"),
            _sectionBody(theme, isDark,
                "We collect the following information when you use Servix:\n\n"
                "• **Account Information**: Name, email address, phone number, and profile photo.\n\n"
                "• **Authentication Data**: Login credentials via email/password, Google Sign-In, or phone number (OTP verification).\n\n"
                "• **Location Data**: Your city and area to show relevant services near you. GPS coordinates are only collected with your explicit permission.\n\n"
                "• **Service Data**: Services you list (for providers), bookings you make (for users), reviews, ratings, and chat messages.\n\n"
                "• **Device Information**: Device type, operating system, and Firebase Cloud Messaging token for push notifications."),

            _sectionTitle(theme, "2. How We Use Your Information"),
            _sectionBody(theme, isDark,
                "We use your information to:\n\n"
                "• Provide and improve our services\n"
                "• Connect users with service providers\n"
                "• Send booking confirmations, updates, and notifications\n"
                "• Display relevant services based on your location\n"
                "• Enable in-app messaging between users and providers\n"
                "• Calculate and display ratings and reviews"),

            _sectionTitle(theme, "3. Data Storage & Security"),
            _sectionBody(theme, isDark,
                "Your data is stored securely using Google Firebase infrastructure. We implement industry-standard security measures including:\n\n"
                "• Encrypted data transmission (HTTPS/TLS)\n"
                "• Firebase Authentication for secure sign-in\n"
                "• Firestore security rules to protect data access\n"
                "• Cloudinary for secure image storage\n\n"
                "We do not sell, trade, or transfer your personal information to third parties."),

            _sectionTitle(theme, "4. Third-Party Services"),
            _sectionBody(theme, isDark,
                "Servix uses the following third-party services:\n\n"
                "• **Google Firebase** — Authentication (email, phone OTP, Google), database, cloud messaging\n"
                "• **Google Sign-In** — Optional social login\n"
                "• **Firebase Phone Auth** — Phone number verification via OTP\n"
                "• **Cloudinary** — Profile and portfolio image hosting\n"
                "• **Google Maps/Geocoding** — Location services\n\n"
                "Each service has its own privacy policy governing the use of your data."),

            _sectionTitle(theme, "5. Your Rights"),
            _sectionBody(theme, isDark,
                "You have the right to:\n\n"
                "• Access and update your personal information via the app's profile settings\n"
                "• Delete your account and all associated data\n"
                "• Opt out of push notifications via device settings\n"
                "• Revoke location permission at any time\n"
                "• Request a copy of your data by contacting us"),

            _sectionTitle(theme, "6. Data Retention"),
            _sectionBody(theme, isDark,
                "We retain your data as long as your account is active. Upon account deletion:\n\n"
                "• Your profile and personal information are deleted\n"
                "• Your bookings and reviews may be anonymized and retained for record-keeping\n"
                "• Chat messages are deleted from your side"),

            _sectionTitle(theme, "7. Children's Privacy"),
            _sectionBody(theme, isDark,
                "Servix is not intended for users under the age of 13. We do not knowingly collect personal information from children under 13. If we learn that we have collected such data, it will be promptly deleted."),

            _sectionTitle(theme, "8. Changes to This Policy"),
            _sectionBody(theme, isDark,
                "We may update this Privacy Policy from time to time. Changes will be reflected on this page with an updated date. Continued use of the app after any changes constitutes acceptance of the new policy."),

            _sectionTitle(theme, "9. Contact Us"),
            _sectionBody(theme, isDark,
                "If you have any questions or concerns about this Privacy Policy, please contact us at:\n\n"
                "📧 support@servix.app\n"
                "📱 Through the in-app chat feature"),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(ThemeData theme, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, top: 8),
      child: Text(
        title,
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _sectionBody(ThemeData theme, bool isDark, String body) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1D2E) : const Color(0xFFF5F6FF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? const Color(0xFF252638) : const Color(0xFFE5E7EB),
        ),
      ),
      child: Text(
        body,
        style: TextStyle(
          fontSize: 14,
          height: 1.6,
          color: isDark ? const Color(0xFFCCCCDD) : const Color(0xFF374151),
        ),
      ),
    );
  }
}


class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text("Terms of Service"),
        elevation: 0,
        backgroundColor: theme.scaffoldBackgroundColor,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    theme.colorScheme.primary.withOpacity(0.12),
                    theme.colorScheme.secondary.withOpacity(0.08),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: theme.colorScheme.primary.withOpacity(0.2),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.description_rounded,
                          color: theme.colorScheme.primary, size: 24),
                      const SizedBox(width: 10),
                      Text(
                        "Terms of Service",
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Last updated: May 2026",
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            _sectionTitle(theme, "1. Acceptance of Terms"),
            _sectionBody(theme, isDark,
                "By downloading, installing, or using the Servix app, you agree to be bound by these Terms of Service. If you do not agree to these terms, please do not use the app."),

            _sectionTitle(theme, "2. Description of Service"),
            _sectionBody(theme, isDark,
                "Servix is a platform that connects service seekers (Users) with service providers (Providers). We facilitate the discovery, booking, and communication between both parties.\n\n"
                "Servix is NOT a service provider itself. We do not perform any services listed on the platform. We act solely as an intermediary."),

            _sectionTitle(theme, "3. User Accounts"),
            _sectionBody(theme, isDark,
                "• You must provide accurate and complete information during registration.\n"
                "• You are responsible for maintaining the security of your account.\n"
                "• You must not share your account credentials with others.\n"
                "• You must be at least 13 years old to create an account.\n"
                "• One person may only maintain one account."),

            _sectionTitle(theme, "4. For Service Providers"),
            _sectionBody(theme, isDark,
                "As a service provider on Servix:\n\n"
                "• You are responsible for the quality and accuracy of your service listings.\n"
                "• You must fulfill bookings in a professional and timely manner.\n"
                "• You are responsible for setting fair and accurate pricing.\n"
                "• You must have the necessary skills, licenses, and insurance (where applicable) to provide the services you list.\n"
                "• You agree that Servix may display your public profile, ratings, and reviews."),

            _sectionTitle(theme, "5. For Users"),
            _sectionBody(theme, isDark,
                "As a user booking services on Servix:\n\n"
                "• You agree to provide accurate booking information.\n"
                "• You must respect the service provider's time and schedule.\n"
                "• Cancellations should be made in a timely manner.\n"
                "• You agree to pay the agreed-upon price for the services rendered.\n"
                "• Reviews and ratings must be honest and based on your actual experience."),

            _sectionTitle(theme, "6. Prohibited Activities"),
            _sectionBody(theme, isDark,
                "You must NOT:\n\n"
                "• Use the app for any illegal or unauthorized purpose\n"
                "• Post false, misleading, or fraudulent information\n"
                "• Harass, abuse, or threaten other users or providers\n"
                "• Attempt to bypass, hack, or interfere with the app's systems\n"
                "• Scrape, copy, or misuse any content from the platform\n"
                "• Create fake reviews or manipulate ratings"),

            _sectionTitle(theme, "7. Payments & Disputes"),
            _sectionBody(theme, isDark,
                "• All payments for services are handled between the user and the provider.\n"
                "• Servix is not responsible for payment disputes between users and providers.\n"
                "• Any disputes should be resolved directly between the parties involved.\n"
                "• Servix may assist in mediation but is not obligated to do so."),

            _sectionTitle(theme, "8. Limitation of Liability"),
            _sectionBody(theme, isDark,
                "Servix is provided \"as is\" without any warranties. We are not liable for:\n\n"
                "• The quality, safety, or legality of services offered by providers\n"
                "• Any damages arising from the use of the platform\n"
                "• Service delays, cancellations, or disputes between parties\n"
                "• Data loss due to technical issues beyond our control"),

            _sectionTitle(theme, "9. Termination"),
            _sectionBody(theme, isDark,
                "We reserve the right to suspend or terminate your account at any time if you violate these terms, engage in fraudulent activity, or for any reason at our sole discretion."),

            _sectionTitle(theme, "10. Contact"),
            _sectionBody(theme, isDark,
                "For questions about these Terms of Service:\n\n"
                "📧 support@servix.app\n"
                "📱 Through the in-app chat feature"),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(ThemeData theme, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, top: 8),
      child: Text(
        title,
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _sectionBody(ThemeData theme, bool isDark, String body) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1D2E) : const Color(0xFFF5F6FF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? const Color(0xFF252638) : const Color(0xFFE5E7EB),
        ),
      ),
      child: Text(
        body,
        style: TextStyle(
          fontSize: 14,
          height: 1.6,
          color: isDark ? const Color(0xFFCCCCDD) : const Color(0xFF374151),
        ),
      ),
    );
  }
}
