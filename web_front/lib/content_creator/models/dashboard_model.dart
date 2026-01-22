import '../models/path_model.dart';
import '../models/path_model.dart';

class DashboardData {
  final int totalPaths;
  final int activePaths;
  final List<WeeklyStats> weeklyStats;
  final List<LearningPath> recentPaths;

  DashboardData({
    required this.totalPaths,
    required this.activePaths,
    required this.weeklyStats,
    required this.recentPaths,
  });
}

class WeeklyStats {
  final String day;
  final int courses;

  WeeklyStats({
    required this.day,
    required this.courses,
  });
}