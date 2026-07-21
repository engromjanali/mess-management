import 'package:googleapis_auth/auth_io.dart';

class FmcServerKey {
  Future<String> getServerTockenFCM() async {
    final scopes = [
      "https://www.googleapis.com/auth/userinfo.email",
      "https://www.googleapis.com/auth/firebase.database",
      "https://www.googleapis.com/auth/firebase.messaging",
      "https://www.googleapis.com/auth/cloud-platform",
    ];

    var client;

    try {
      client = await clientViaServiceAccount(
        ServiceAccountCredentials.fromJson({
          "type": "service_account",
          "project_id": "...",
          "private_key_id": "...",
          "private_key": "...",
          "client_email": "...",
          "client_id": "...",
          "auth_uri": "https://accounts.google.com/o/oauth2/auth",
          "token_uri": "https://oauth2.googleapis.com/token",
          "auth_provider_x509_cert_url":
              "https://www.googleapis.com/oauth2/v1/certs",
          "client_x509_cert_url": "...",
          "universe_domain": "googleapis.com"
        }),
        scopes,
      );
    } catch (e) {
      e.toString();
      print(e.toString() + "xyx");
    }

    final accessServerKey = client?.credentials.accessToken.data;
    return accessServerKey ?? "";
  }
}