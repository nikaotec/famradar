// lib/interfaces/invitation_service_interface.dart
abstract class InvitationServiceInterface {
  Future<void> sendInvitation(
    String fromUserId,
    String toEmail,
    String familyId,
  );
  Future<void> acceptInvitation(
    String invitationId,
    String userId,
    String familyId,
  );
  Future<void> rejectInvitation(String invitationId, String userId);
}
