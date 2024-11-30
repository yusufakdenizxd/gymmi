import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:gymmi/core/theme/app_theme.dart';
import 'package:gymmi/core/widgets/app_button.dart';
import 'package:gymmi/features/exercise/exercise_model.dart';
import 'package:gymmi/features/exercise/exercise_service.dart';
import 'package:pedometer/pedometer.dart';

class ExercisePage extends StatefulWidget {
  const ExercisePage({super.key});

  @override
  State<ExercisePage> createState() => _ExercisePageState();
}

class _ExercisePageState extends State<ExercisePage> {
  final _exerciseService = ExerciseService();
  final _user = FirebaseAuth.instance.currentUser;
  final _firestore = FirebaseFirestore.instance;
  String? _userName;
  late Stream<StepCount> _stepCountStream;
  late Stream<PedestrianStatus> _pedestrianStatusStream;
  String _status = '?', _steps = '?';
  bool _isTracking = false;
  int _startSteps = 0;
  DateTime? _startTime;
  double _distance = 0.0;
  int _duration = 0;
  Timer? _timer;

  ExerciseType selectedType = ExerciseType.walk;

  final List<String> months = [
    "Ocak",
    "Şubat",
    "Mart",
    "Nisan",
    "Mayıs",
    "Haziran",
    "Temmuz",
    "Ağustos",
    "Eylül",
    "Ekim",
    "Kasım",
    "Aralık",
  ];

  late String currentMonth;
  late int currentDay;
  late List<int> days;
  late ScrollController _monthScrollController;
  late ScrollController _dayScrollController;
  late List<Exercise> selectedDateExercises;

  int _dailySteps = 0;
  int _lastTotalSteps = 0;
  int _dailyTarget = 0;
  double get _progressToTarget => _dailyTarget > 0 ? _dailySteps / _dailyTarget : 0;

  @override
  void initState() {
    super.initState();
    _loadUserName();
    _loadDailyTarget();
    final now = DateTime.now();
    currentMonth = months[now.month - 1];
    currentDay = now.day;
    days = _getDaysInMonth(now.month);
    selectedDateExercises = [];

    _monthScrollController = ScrollController();
    _dayScrollController = ScrollController();

    initPlatformState();
    _loadExercisesForSelectedDate();

    Timer.periodic(const Duration(minutes: 1), (Timer t) => _checkDayChange());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_monthScrollController.hasClients) {
        _monthScrollController.animateTo(
          (months.indexOf(currentMonth) * 80.0) - (MediaQuery.of(context).size.width / 2) + 40.0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
      if (_dayScrollController.hasClients) {
        _dayScrollController.animateTo(
          ((currentDay - 1) * 80.0) - (MediaQuery.of(context).size.width / 2) + 40.0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  List<int> _getDaysInMonth(int month) {
    final year = DateTime.now().year;
    final daysInMonth = DateTime(year, month + 1, 0).day;
    return List<int>.generate(daysInMonth, (i) => i + 1);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _monthScrollController.dispose();
    _dayScrollController.dispose();
    super.dispose();
  }

  Future<void> _loadExercisesForSelectedDate() async {
    final selectedDate = DateTime(
      DateTime.now().year,
      months.indexOf(currentMonth) + 1,
      currentDay,
    );

    // Load exercises for the selected date
    final exercises = await _exerciseService.getExercisesForDate(
      'current_user_id', // Replace with actual user ID
      selectedDate,
    );

    setState(() {
      selectedDateExercises = exercises;
    });
  }

  void initPlatformState() {
    _exerciseService.initPlatformState();
    _stepCountStream = _exerciseService.stepCountStream;
    _pedestrianStatusStream = _exerciseService.pedestrianStatusStream;

    _stepCountStream.listen(onStepCount).onError(onStepCountError);
    _pedestrianStatusStream.listen(onPedestrianStatusChanged).onError(onPedestrianStatusError);
  }

  void onStepCount(StepCount event) {
    setState(() {
      _steps = event.steps.toString();

      if (_lastTotalSteps == 0) {
        _lastTotalSteps = event.steps;
      }

      _dailySteps = event.steps - _lastTotalSteps;
    });
  }

  void onPedestrianStatusChanged(PedestrianStatus event) {
    setState(() {
      _status = event.status;
    });
  }

  void onStepCountError(error) {
    setState(() {
      _steps = 'Step Count not available';
    });
  }

  void onPedestrianStatusError(error) {
    setState(() {
      _status = 'Pedestrian Status not available';
    });
  }

  void _startTracking() {
    setState(() {
      _isTracking = true;
      _startSteps = int.parse(_steps);
      _startTime = DateTime.now();
      _distance = 0.0;
      _duration = 0;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _duration = DateTime.now().difference(_startTime!).inSeconds;
        final currentSteps = int.parse(_steps) - _startSteps;
        _distance = currentSteps * 0.762 / 1000;
      });
    });
  }

  void _stopTracking() async {
    _timer?.cancel();

    if (_startTime != null) {
      final steps = int.parse(_steps) - _startSteps;

      // Validate exercise data
      if (steps <= 0 || _duration <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.error_outline, color: Colors.white),
                SizedBox(width: 8),
                Text('Geçersiz egzersiz! Adım veya süre 0 olamaz.'),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
      } else {
        // Save valid exercise
        await _exerciseService.saveExercise(
          userId: 'current_user_id',
          userName: _userName!,
          type: selectedType,
          steps: steps,
          duration: _duration,
          distance: _distance,
        );

        await _loadExercisesForSelectedDate();

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle_outline, color: Colors.white),
                SizedBox(width: 8),
                Text('Egzersiz başarıyla kaydedildi!'),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
      }

      await _loadDailyTarget();
    }

    setState(() {
      _isTracking = false;
      _startTime = null;
      _distance = 0.0;
      _duration = 0;
    });
  }

  void _checkDayChange() {
    final now = DateTime.now();
    final midnight = DateTime(now.year, now.month, now.day);

    if (_startTime != null && _startTime!.day != now.day) {
      _lastTotalSteps = int.parse(_steps);
      _dailySteps = 0;
    }
  }

  Future<void> _loadUserName() async {
    try {
      final userData = await _firestore.collection('users').doc(_user?.uid).get();
      if (userData.exists) {
        setState(() {
          _userName = userData.data()?['name'] ?? 'No Name';
        });
      }
    } catch (e) {
      debugPrint('Error loading user name: $e');
    }
  }

  Future<void> _loadDailyTarget() async {
    try {
      final userData = await _firestore.collection('users').doc(_user?.uid).get();
      if (userData.exists) {
        setState(() {
          _dailyTarget = userData.data()?['dailyTarget'] ?? 0;
        });
      }

      // Calculate today's steps
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final exercises = await _firestore.collection('exercises').where('userId', isEqualTo: _user?.uid).where('timestamp', isGreaterThanOrEqualTo: startOfDay.toIso8601String()).where('timestamp', isLessThan: endOfDay.toIso8601String()).get();

      int totalSteps = 0;
      for (var doc in exercises.docs) {
        totalSteps += (doc.data()['steps'] as int? ?? 0);
      }

      setState(() {
        _dailySteps = totalSteps;
      });
    } catch (e) {
      debugPrint('Error loading daily target: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildExerciseStats(),
            _buildExerciseType(),
            _buildStartButton(),
            _buildDateSelector(),
            const SizedBox(height: 16),
            _buildExerciseHistory(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Günlük Hedef',
                style: AppTheme.textTheme.bodyLarge?.copyWith(
                  color: AppTheme.textSecondary,
                ),
              ),
              Text(
                '$_dailyTarget Adım',
                style: AppTheme.textTheme.headlineMedium,
              ),
            ],
          ),
          const Spacer(),
          CircularProgressIndicator(
            value: _progressToTarget,
            backgroundColor: AppTheme.background,
            color: _progressToTarget >= 1 ? Colors.green : AppTheme.primary,
            strokeWidth: 8,
          ),
        ],
      ),
    );
  }

  Widget _buildExerciseStats() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStatItem(
                icon: FontAwesomeIcons.shoePrints,
                value: _isTracking ? (int.parse(_steps) - _startSteps).toString() : _dailySteps.toString(),
                label: 'Adım',
              ),
              _buildStatItem(
                icon: FontAwesomeIcons.stopwatch,
                value: _isTracking ? (_duration ~/ 60).toString() : '0',
                label: 'Dakika',
              ),
              _buildStatItem(
                icon: FontAwesomeIcons.ruler,
                value: _isTracking ? _distance.toStringAsFixed(2) : '0.00',
                label: 'KM',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: AppTheme.textTheme.headlineMedium?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: AppTheme.textTheme.bodyMedium?.copyWith(
            color: Colors.white.withOpacity(0.8),
          ),
        ),
      ],
    );
  }

  Widget _buildExerciseType() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primary.withOpacity(0.1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios),
            onPressed: () {
              setState(() {
                // If at first item, go to last item
                selectedType = selectedType.index == 0 ? ExerciseType.values[ExerciseType.values.length - 1] : ExerciseType.values[selectedType.index - 1];
              });
            },
          ),
          Column(
            children: [
              Icon(
                selectedType == ExerciseType.walk
                    ? FontAwesomeIcons.personWalking
                    : selectedType == ExerciseType.run
                        ? FontAwesomeIcons.personRunning
                        : FontAwesomeIcons.bicycle,
                size: 32,
                color: AppTheme.primary,
              ),
              const SizedBox(height: 8),
              Text(
                selectedType.name,
                style: AppTheme.textTheme.titleLarge,
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.arrow_forward_ios),
            onPressed: () {
              setState(() {
                // If at last item, go to first item
                selectedType = selectedType.index == ExerciseType.values.length - 1 ? ExerciseType.values[0] : ExerciseType.values[selectedType.index + 1];
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStartButton() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: AppButton(
        text: _isTracking ? 'Egzersizi Bitir' : 'Egzersizi Başlat',
        onPressed: _isTracking ? _showStopConfirmation : _startTracking,
        icon: _isTracking ? Icons.stop : Icons.play_arrow,
      ),
    );
  }

  void _showStopConfirmation() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Row(
            children: [
              Icon(
                Icons.warning_amber_rounded,
                color: AppTheme.primary,
                size: 28,
              ),
              SizedBox(width: 8),
              Text('Egzersizi Bitir'),
            ],
          ),
          content: const Text('Egzersizi bitirmek istediğinizden emin misiniz?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'İptal',
                style: TextStyle(color: AppTheme.textSecondary),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _stopTracking();
              },
              child: const Text(
                'Bitir',
                style: TextStyle(
                  color: AppTheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDateSelector() {
    return Column(
      children: [
        // Month Selector
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          controller: _monthScrollController,
          child: Row(
            children: months.map((month) {
              final isSelected = currentMonth == month;
              return GestureDetector(
                onTap: () {
                  setState(() {
                    currentMonth = month;
                    days = _getDaysInMonth(months.indexOf(month) + 1);
                  });
                  _loadExercisesForSelectedDate();
                },
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected ? AppTheme.primary : Colors.transparent,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected ? AppTheme.primary : AppTheme.textLight,
                    ),
                  ),
                  child: Text(
                    month,
                    style: AppTheme.textTheme.bodyMedium?.copyWith(
                      color: isSelected ? Colors.white : AppTheme.textSecondary,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 16),
        // Day Selector
        SizedBox(
          height: 80,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            controller: _dayScrollController,
            itemCount: days.length,
            itemBuilder: (context, index) {
              final day = days[index];
              final isSelected = currentDay == day;
              final date = DateTime(
                DateTime.now().year,
                months.indexOf(currentMonth) + 1,
                day,
              );
              final isToday = date.year == DateTime.now().year && date.month == DateTime.now().month && date.day == DateTime.now().day;

              return GestureDetector(
                onTap: () {
                  setState(() {
                    currentDay = day;
                  });
                  _loadExercisesForSelectedDate();
                },
                child: Container(
                  width: 60,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: isSelected ? AppTheme.primary.withOpacity(0.1) : Colors.transparent,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isToday
                          ? AppTheme.accent
                          : isSelected
                              ? AppTheme.primary
                              : AppTheme.textLight,
                      width: isToday ? 2 : 1,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        day.toString(),
                        style: AppTheme.textTheme.titleLarge?.copyWith(
                          color: isSelected ? Colors.white : AppTheme.textPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (isToday)
                        Text(
                          'Bugün',
                          style: AppTheme.textTheme.bodySmall?.copyWith(
                            color: isSelected ? Colors.white : AppTheme.accent,
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildExerciseHistory() {
    if (selectedDateExercises.isEmpty) {
      return Expanded(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                FontAwesomeIcons.personWalking,
                size: 48,
                color: AppTheme.textLight,
              ),
              const SizedBox(height: 16),
              Text(
                'Bu tarihte egzersiz kaydı yok',
                style: AppTheme.textTheme.bodyLarge?.copyWith(
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Expanded(
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: selectedDateExercises.length,
        itemBuilder: (context, index) {
          final exercise = selectedDateExercises[index];
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ListTile(
              leading: Icon(
                exercise.type == ExerciseType.walk
                    ? FontAwesomeIcons.personWalking
                    : exercise.type == ExerciseType.run
                        ? FontAwesomeIcons.personRunning
                        : FontAwesomeIcons.bicycle,
                color: AppTheme.primary,
              ),
              title: Text(
                exercise.type.name,
                style: AppTheme.textTheme.titleMedium,
              ),
              subtitle: Text(
                '${exercise.steps} adım • ${(exercise.duration / 60).round()} dk • ${exercise.distance.toStringAsFixed(2)} km',
                style: AppTheme.textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textSecondary,
                ),
              ),
              trailing: Text(
                '${exercise.timestamp.hour.toString().padLeft(2, '0')}:${exercise.timestamp.minute.toString().padLeft(2, '0')}',
                style: AppTheme.textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textSecondary,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
