// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'preference_service.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$preferenceServiceHash() => r'8441f05207b031aa4018f810349c09f256d22b9d';

/// Riverpod provider for the PreferenceService.
/// Uses FutureProvider since SharedPreferences.getInstance() is async.
///
/// Copied from [preferenceService].
@ProviderFor(preferenceService)
final preferenceServiceProvider =
    AutoDisposeFutureProvider<PreferenceService>.internal(
  preferenceService,
  name: r'preferenceServiceProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$preferenceServiceHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef PreferenceServiceRef = AutoDisposeFutureProviderRef<PreferenceService>;
String _$biometricsEnabledHash() => r'd3bb6721fed0ae88b93bd00cfa734cc05dcc8527';

/// Simple provider for the current state of the biometrics preference.
/// Reads from PreferenceService and handles the async nature.
///
/// Copied from [biometricsEnabled].
@ProviderFor(biometricsEnabled)
final biometricsEnabledProvider = AutoDisposeProvider<bool>.internal(
  biometricsEnabled,
  name: r'biometricsEnabledProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$biometricsEnabledHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef BiometricsEnabledRef = AutoDisposeProviderRef<bool>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
