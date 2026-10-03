class MembershipStatusEntity {
  const MembershipStatusEntity({required this.current, required this.history, required this.pendingRequests, required this.invites, required this.availableMesses, this.memberships = const []});

  final MembershipSummaryEntity? current;

  /// Every membership of the user across all messes and seasons, newest first.
  final List<MembershipSummaryEntity> memberships;
  final List<MembershipSummaryEntity> history;
  final List<JoinRequestSummaryEntity> pendingRequests;
  final List<InviteSummaryEntity> invites;
  final List<MessSummaryEntity> availableMesses;
}

class MembershipSummaryEntity {
  const MembershipSummaryEntity({
    required this.membershipId,
    required this.messId,
    required this.messName,
    required this.seasonName,
    required this.role,
    this.status,
    this.totalDeposit = 0,
    this.totalMeal = 0,
    this.seasonStartDate,
    this.seasonEndDate,
    this.joinedAt,
    this.isCurrent = false,
    this.canSwitch = false,
  });

  final int membershipId;
  final int messId;
  final String messName;
  final String seasonName;
  final String role;

  /// `active`, `disabled` (by a manager) or `left`.
  final String? status;
  final DateTime? seasonStartDate;
  final DateTime? seasonEndDate;
  final DateTime? joinedAt;

  /// The membership every screen currently shows.
  final bool isCurrent;

  /// Whether it can be made current (not left, not disabled).
  final bool canSwitch;
  final double totalDeposit;
  final double totalMeal;
}

class JoinRequestSummaryEntity {
  const JoinRequestSummaryEntity({required this.id, required this.messId, required this.messName});

  final int id;
  final int messId;
  final String messName;
}

class InviteSummaryEntity {
  const InviteSummaryEntity({required this.id, required this.messId, required this.messName, required this.inviteCode, required this.status});

  final int id;
  final int messId;
  final String messName;
  final String inviteCode;
  final String status;
}

class MessSummaryEntity {
  const MessSummaryEntity({required this.id, required this.name, required this.address});

  final int id;
  final String name;
  final String address;
}

class MessPageEntity {
  const MessPageEntity({required this.messes, required this.currentPage, required this.lastPage, required this.total});

  final List<MessSummaryEntity> messes;
  final int currentPage;
  final int lastPage;
  final int total;
}
