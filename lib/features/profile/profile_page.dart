import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:gymmi/core/theme/app_theme.dart';
import 'package:gymmi/core/widgets/app_button.dart';
import 'package:gymmi/features/faq/faq_page.dart';
import 'package:gymmi/features/profile/widgets/edit_profile_dialog.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final user = FirebaseAuth.instance.currentUser;
  final _firestore = FirebaseFirestore.instance;

  String? _name;
  String? _email;
  int _totalSteps = 0;
  int _totalCalories = 0;
  int _totalHours = 0;
  int _dailyTarget = 0;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final userData = await _firestore.collection('users').doc(user?.uid).get();

      if (userData.exists) {
        setState(() {
          _name = userData.data()?['name'] ?? 'No Name';
          _email = user?.email ?? 'No Email';
          _totalSteps = userData.data()?['totalSteps'] ?? 0;
          _totalCalories = userData.data()?['totalCalories'] ?? 0;
          _totalHours = userData.data()?['totalHours'] ?? 0;
          _dailyTarget = userData.data()?['dailyTarget'] ?? 0;
        });
      }
    } catch (e) {
      debugPrint('Error loading user data: $e');
    }
  }

  Future<void> _editProfile() async {
    final result = await showDialog(
      context: context,
      builder: (context) => EditProfileDialog(
        initialName: _name ?? '',
      ),
    );

    if (result != null) {
      try {
        await _firestore.collection('users').doc(user?.uid).update({'name': result});

        setState(() {
          _name = result;
        });

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile updated successfully')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to update profile')),
          );
        }
      }
    }
  }

  Future<void> _handleNotifications() async {
    // Implement notifications settings
  }

  Future<void> _handlePrivacy() async {
    // Implement privacy settings
  }
  Future<void> _handleFAQ() async {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const FAQPage()),
    );
  }

  Future<void> _handleHelp() async {
    // Implement help section
  }

  Future<void> _handleLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await FirebaseAuth.instance.signOut();
    }
  }

  Future<void> _updateDailyTarget() async {
    final controller = TextEditingController(text: _dailyTarget.toString());

    final result = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Günlük Hedef'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Hedef Adım Sayısı',
            border: OutlineInputBorder(),
          ),
          onChanged: (value) {
            if (value.isNotEmpty && !RegExp(r'^[0-9]+$').hasMatch(value)) {
              controller.text = value.replaceAll(RegExp(r'[^0-9]'), '');
              controller.selection = TextSelection.fromPosition(
                TextPosition(offset: controller.text.length),
              );
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () {
              final value = int.tryParse(controller.text);
              Navigator.pop(context, value);
            },
            child: const Text('Kaydet'),
          ),
        ],
      ),
    );

    if (result != null) {
      try {
        await _firestore.collection('users').doc(user?.uid).update({'dailyTarget': result});

        setState(() {
          _dailyTarget = result;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Günlük hedef güncellendi')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Hedef güncellenirken hata oluştu')),
          );
        }
      }
    }

    controller.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppTheme.primary,
              AppTheme.primary.withOpacity(0.8),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 60),
              _buildProfileHeader(),
              const SizedBox(height: 24),
              Container(
                decoration: const BoxDecoration(
                  color: AppTheme.background,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(32),
                    topRight: Radius.circular(32),
                  ),
                ),
                child: Column(
                  children: [
                    _buildStats(),
                    _buildMenuItems(),
                    const SizedBox(height: 32),
                    _buildLogoutButton(),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Column(
      children: [
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
            border: Border.all(
              color: Colors.white,
              width: 4,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: const Center(
            child: Icon(
              FontAwesomeIcons.user,
              size: 50,
              color: AppTheme.primary,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          _name ?? 'Loading...',
          style: AppTheme.textTheme.headlineMedium?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          _email ?? 'Loading...',
          style: AppTheme.textTheme.bodyLarge?.copyWith(
            color: Colors.white.withOpacity(0.8),
          ),
        ),
      ],
    );
  }

  Widget _buildStats() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem('Total Steps', _totalSteps.toString(), FontAwesomeIcons.shoePrints),
          _buildStatItem('Calories', _totalCalories.toString(), FontAwesomeIcons.fire),
          _buildStatItem('Hours', '$_totalHours Hours', FontAwesomeIcons.stopwatch),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(
            icon,
            color: AppTheme.primary,
            size: 24,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: AppTheme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: AppTheme.textTheme.bodyMedium?.copyWith(
            color: AppTheme.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildMenuItems() {
    return Column(
      children: [
        _buildMenuItem(
          'Günlük Hedef',
          FontAwesomeIcons.bullseye,
          () => _updateDailyTarget(),
          subtitle: '$_dailyTarget adım',
        ),
        _buildMenuItem('Edit Profile', FontAwesomeIcons.userPen, _editProfile),
        _buildMenuItem('Notifications', FontAwesomeIcons.bell, _handleNotifications),
        _buildMenuItem('Privacy', FontAwesomeIcons.lock, _handlePrivacy),
        _buildMenuItem('FAQ', FontAwesomeIcons.circleQuestion, _handleFAQ),
        // _buildMenuItem('Help', FontAwesomeIcons.circleQuestion, _handleHelp),
      ],
    );
  }

  Widget _buildMenuItem(String title, IconData icon, VoidCallback onTap, {String? subtitle}) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppTheme.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          icon,
          color: AppTheme.primary,
          size: 20,
        ),
      ),
      title: Text(
        title,
        style: AppTheme.textTheme.titleMedium,
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: AppTheme.textTheme.bodyMedium?.copyWith(
                color: AppTheme.textSecondary,
              ),
            )
          : null,
      trailing: const Icon(
        Icons.arrow_forward_ios,
        size: 16,
      ),
      onTap: onTap,
    );
  }

  Widget _buildLogoutButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: AppButton(
        text: 'Logout',
        onPressed: _handleLogout,
        icon: FontAwesomeIcons.rightFromBracket,
      ),
    );
  }
}
