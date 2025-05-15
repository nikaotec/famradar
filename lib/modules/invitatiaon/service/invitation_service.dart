// lib/services/invitation_service.dart
import 'package:famradar/providers/app_provider.dart';
import 'package:flutter/services.dart';
import '../interfaces/invitation_service_interface.dart';

class InvitationService implements InvitationServiceInterface {
  static const _invitationChannel = MethodChannel(
    'avs.com.famradar/invitations',
  );
  final AppProvider _appProvider;

  InvitationService({required AppProvider appProvider})
    : _appProvider = appProvider {
    _invitationChannel.setMethodCallHandler(_handleMethodCall);
  }

  Future<void> _handleMethodCall(MethodCall call) async {
    try {
      switch (call.method) {
        case 'onInvitationEvent':
          final args = call.arguments as Map?;
          if (args != null) {
            _appProvider.handleInvitationEvent(
              args.cast<String, dynamic>(),
            ); // Line 20
          } else {
            _appProvider.showError('Invalid invitation event arguments');
          }
          break;
        case 'onError':
          final args = call.arguments as Map?;
          final errorMessage = args?['errorMessage'] as String?;
          if (errorMessage != null) {
            _appProvider.showError(errorMessage);
          } else {
            _appProvider.showError('Unknown invitation error');
          }
          break;
        default:
          _appProvider.showError('Unhandled invitation event: ${call.method}');
      }
    } catch (e) {
      _appProvider.showError('Error processing invitation event: $e');
    }
  }

  @override
  Future<void> sendInvitation(
    String fromUserId,
    String toEmail,
    String familyId,
  ) async {
    try {
      await _invitationChannel.invokeMethod('sendInvitation', {
        'fromUserId': fromUserId,
        'toEmail': toEmail,
        'familyId': familyId,
      });
    } catch (e) {
      _appProvider.showError('Error sending invitation: $e');
      rethrow;
    }
  }

  @override
  Future<void> acceptInvitation(
    String invitationId,
    String userId,
    String familyId,
  ) async {
    try {
      await _invitationChannel.invokeMethod('acceptInvitation', {
        'invitationId': invitationId,
        'userId': userId,
        'familyId': familyId,
      });
    } catch (e) {
      _appProvider.showError('Error accepting invitation: $e');
      rethrow;
    }
  }

  @override
  Future<void> rejectInvitation(String invitationId, String userId) async {
    try {
      await _invitationChannel.invokeMethod('rejectInvitation', {
        'invitationId': invitationId,
        'userId': userId,
      });
    } catch (e) {
      _appProvider.showError('Error rejecting invitation: $e');
      rethrow;
    }
  }
}
