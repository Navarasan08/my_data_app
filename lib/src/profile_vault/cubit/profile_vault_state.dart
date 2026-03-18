import 'package:my_data_app/src/profile_vault/model/profile_vault_model.dart';

class ProfileVaultState {
  final List<VaultEntry> entries;

  const ProfileVaultState({required this.entries});

  ProfileVaultState copyWith({List<VaultEntry>? entries}) =>
      ProfileVaultState(entries: entries ?? this.entries);
}
