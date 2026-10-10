import 'package:equatable/equatable.dart';

class SupportChannelEntity extends Equatable {
  const SupportChannelEntity({required this.name, required this.kind, required this.destination, required this.url, this.logoUrl = ''});

  final String name;
  final String kind;
  final String destination;
  final String url;
  final String logoUrl;

  Uri? get contactUri {
    final uri = Uri.tryParse(url);
    if (uri == null || uri.userInfo.isNotEmpty) return null;
    if (uri.scheme == 'mailto' || uri.scheme == 'tel') return uri.path.isEmpty ? null : uri;
    if ((uri.scheme == 'https' || uri.scheme == 'http') && uri.host.isNotEmpty) return uri;
    return null;
  }

  @override
  List<Object?> get props => [name, kind, destination, url, logoUrl];
}
