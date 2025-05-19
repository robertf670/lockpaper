// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'preference_service.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$preferenceServiceHash() => r'370eb3cc2cdab5f77d85468c9e8ac5abf462a669';

/// Provider for the PreferenceService itself.
///
/// Copied from [preferenceService].
@ProviderFor(preferenceService)
final preferenceServiceProvider = FutureProvider<PreferenceService>.internal(
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
typedef PreferenceServiceRef = FutureProviderRef<PreferenceService>;
String _$biometricsEnabledHash() => r'ce8ed87eadf07d0fe388421dcce8cd1176b81140';

/// Simple boolean provider for easy access to the biometrics setting.
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
