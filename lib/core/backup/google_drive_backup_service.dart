import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;

import 'package:finance_tracker/app/di/injection.dart';
import 'package:finance_tracker/features/settings/data/repository/data_repository.dart';
import 'package:finance_tracker/features/settings/data/repository/settings_repository.dart';

class DriveBackupMetadata {
  const DriveBackupMetadata({
    required this.fileId,
    required this.fileName,
    required this.modifiedTime,
    this.sizeBytes,
    this.accountEmail,
  });

  final String fileId;
  final String fileName;
  final DateTime modifiedTime;
  final int? sizeBytes;
  final String? accountEmail;
}

class DriveBackupResult {
  const DriveBackupResult({
    required this.success,
    this.fileName = backupFileName,
    this.accountEmail,
    this.timestamp,
    this.sizeBytes,
    this.errorMessage,
  });

  static const String backupFileName = 'hyprwise_backup.json';

  final bool success;
  final String fileName;
  final String? accountEmail;
  final DateTime? timestamp;
  final int? sizeBytes;
  final String? errorMessage;
}

class GoogleDriveBackupService {
  GoogleDriveBackupService._();
  static final GoogleDriveBackupService instance = GoogleDriveBackupService._();

  static const String _driveFileScope = 'https://www.googleapis.com/auth/drive.file';
  static const String _backupFileName = 'hyprwise_backup.json';

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: <String>[
      'email',
      'profile',
      _driveFileScope,
    ],
  );

  String? _connectedEmail;
  String? get connectedEmail => _connectedEmail;

  /// Silently checks if a Google account is already connected and fetches the latest Drive backup metadata.
  Future<DriveBackupMetadata?> checkExistingBackupSilently() async {
    try {
      final account = _googleSignIn.currentUser ?? await _googleSignIn.signInSilently();
      if (account == null) return null;
      _connectedEmail = account.email;

      final headers = await account.authHeaders;
      return await _findLatestBackupFile(headers, accountEmail: account.email);
    } catch (e) {
      debugPrint('[GoogleDriveBackup] Silent check notice: $e');
      return null;
    }
  }

  /// Signs in (if needed), requests Google Drive file scope, and returns auth headers + email.
  Future<({Map<String, String> headers, String email})?> _authenticateForDrive() async {
    try {
      GoogleSignInAccount? account = _googleSignIn.currentUser;
      account ??= await _googleSignIn.signInSilently();
      account ??= await _googleSignIn.signIn();

      if (account == null) {
        return null;
      }

      _connectedEmail = account.email;

      try {
        final hasScope = await _googleSignIn.canAccessScopes(<String>[_driveFileScope]);
        if (!hasScope) {
          final granted = await _googleSignIn.requestScopes(<String>[_driveFileScope]);
          if (!granted) {
            return null;
          }
        }
      } catch (e) {
        // On some platforms requestScopes is already covered by initial GoogleSignIn scopes
        debugPrint('[GoogleDriveBackup] Scope check notice: $e');
      }

      final headers = await account.authHeaders;
      return (headers: headers, email: account.email);
    } catch (e) {
      debugPrint('[GoogleDriveBackup] Auth error: $e');
      return null;
    }
  }

  /// Uploads or updates `hyprwise_backup.json` directly in the user's Google Drive.
  Future<DriveBackupResult> backupToGoogleDrive() async {
    try {
      final auth = await _authenticateForDrive();
      if (auth == null) {
        return const DriveBackupResult(
          success: false,
          errorMessage: 'Google Drive sign-in was cancelled or unavailable.',
        );
      }

      final dataRepo = getIt<DataRepository>();
      final jsonContent = await dataRepo.exportJson();
      final bytes = utf8.encode(jsonContent);

      // Check if an existing backup file already exists on Google Drive
      final existing = await _findLatestBackupFile(
        auth.headers,
        accountEmail: auth.email,
      );

      String? targetFileId = existing?.fileId;

      if (targetFileId == null) {
        // Create file metadata first
        final createUri = Uri.parse('https://www.googleapis.com/drive/v3/files');
        final createRes = await http.post(
          createUri,
          headers: <String, String>{
            ...auth.headers,
            'Content-Type': 'application/json; charset=utf-8',
          },
          body: jsonEncode(<String, dynamic>{
            'name': _backupFileName,
            'mimeType': 'application/json',
            'description': 'Hyprwise Personal Finance & Shift Backup',
          }),
        );

        if (createRes.statusCode < 200 || createRes.statusCode >= 300) {
          return DriveBackupResult(
            success: false,
            accountEmail: auth.email,
            errorMessage: 'Google Drive API error (${createRes.statusCode})',
          );
        }

        final createdJson = jsonDecode(createRes.body) as Map<String, dynamic>;
        targetFileId = createdJson['id'] as String?;
      }

      if (targetFileId == null) {
        return DriveBackupResult(
          success: false,
          accountEmail: auth.email,
          errorMessage: 'Could not allocate backup file on Google Drive.',
        );
      }

      // Upload JSON payload to the file
      final uploadUri = Uri.parse(
        'https://www.googleapis.com/upload/drive/v3/files/$targetFileId?uploadType=media',
      );
      final uploadRes = await http.patch(
        uploadUri,
        headers: <String, String>{
          ...auth.headers,
          'Content-Type': 'application/json; charset=utf-8',
          'Content-Length': '${bytes.length}',
        },
        body: bytes,
      );

      if (uploadRes.statusCode < 200 || uploadRes.statusCode >= 300) {
        return DriveBackupResult(
          success: false,
          accountEmail: auth.email,
          errorMessage: 'Failed to upload backup data (${uploadRes.statusCode}).',
        );
      }

      final now = DateTime.now();
      final settingsRepo = getIt<SettingsRepository>();
      await settingsRepo.setBackupEnabled(true);
      await settingsRepo.setLastBackupAt(now);

      return DriveBackupResult(
        success: true,
        fileName: _backupFileName,
        accountEmail: auth.email,
        timestamp: now,
        sizeBytes: bytes.length,
      );
    } catch (e) {
      debugPrint('[GoogleDriveBackup] Upload error: $e');
      return DriveBackupResult(
        success: false,
        errorMessage: e.toString(),
      );
    }
  }

  /// Finds the latest Hyprwise backup file in the user's Google Drive.
  Future<DriveBackupMetadata?> findBackupOnDrive() async {
    final auth = await _authenticateForDrive();
    if (auth == null) return null;
    return _findLatestBackupFile(auth.headers, accountEmail: auth.email);
  }

  Future<DriveBackupMetadata?> _findLatestBackupFile(
    Map<String, String> headers, {
    String? accountEmail,
  }) async {
    final query = "name contains 'hyprwise_backup' and mimeType = 'application/json' and trashed = false";
    final listUri = Uri.https(
      'www.googleapis.com',
      '/drive/v3/files',
      <String, String>{
        'q': query,
        'spaces': 'drive',
        'fields': 'files(id,name,modifiedTime,size)',
        'orderBy': 'modifiedTime desc',
        'pageSize': '5',
      },
    );

    final res = await http.get(listUri, headers: headers);
    if (res.statusCode < 200 || res.statusCode >= 300) {
      return null;
    }

    final body = jsonDecode(res.body) as Map<String, dynamic>;
    final files = body['files'] as List<dynamic>?;
    if (files == null || files.isEmpty) {
      return null;
    }

    final first = files.first as Map<String, dynamic>;
    final id = first['id'] as String?;
    final name = first['name'] as String? ?? _backupFileName;
    final modifiedStr = first['modifiedTime'] as String?;
    final sizeStr = first['size']?.toString();

    if (id == null) return null;

    return DriveBackupMetadata(
      fileId: id,
      fileName: name,
      modifiedTime: modifiedStr != null
          ? (DateTime.tryParse(modifiedStr)?.toLocal() ?? DateTime.now())
          : DateTime.now(),
      sizeBytes: sizeStr != null ? int.tryParse(sizeStr) : null,
      accountEmail: accountEmail,
    );
  }

  /// Downloads the specified backup file from Google Drive and restores it into local Drift DB.
  Future<bool> restoreFromDriveFile(String fileId) async {
    final auth = await _authenticateForDrive();
    if (auth == null) return false;

    final downloadUri = Uri.parse(
      'https://www.googleapis.com/drive/v3/files/$fileId?alt=media',
    );
    final res = await http.get(downloadUri, headers: auth.headers);
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('Google Drive download failed (${res.statusCode})');
    }

    final jsonContent = utf8.decode(res.bodyBytes);
    final dataRepo = getIt<DataRepository>();
    await dataRepo.importJson(jsonContent);
    return true;
  }
}
