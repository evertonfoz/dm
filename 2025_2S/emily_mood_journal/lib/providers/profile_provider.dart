import '../services/profile_repository.dart';

// Provider for easy access to profile state
final profileProvider = profileRepositoryProvider;

// Provider for profile repository (for actions)
final profileRepositoryNotifierProvider = profileRepositoryProvider.notifier;
