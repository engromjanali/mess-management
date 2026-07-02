import 'package:equatable/equatable.dart';

class ConfigEntity extends Equatable {
  final String version;

  const ConfigEntity({
    required this.version,
  });

  @override
  List<Object?> get props => [version,];
}