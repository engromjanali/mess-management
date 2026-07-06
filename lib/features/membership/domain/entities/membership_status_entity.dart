class MembershipStatusEntity {
  const MembershipStatusEntity({required this.current, required this.history, required this.pendingRequests, required this.invites, required this.availableMesses});

  final MembershipSummaryEntity? current;
  final List<MembershipSummaryEntity> history;
  final List<JoinRequestSummaryEntity> pendingRequests;
  final List<InviteSummaryEntity> invites;
  final List<MessSummaryEntity> availableMesses;
}

class MembershipSummaryEntity {
  const MembershipSummaryEntity({required this.membershipId, required this.messId, required this.messName, required this.seasonName, required this.role, this.status, this.totalDeposit = 0, this.totalMeal = 0});

  final int membershipId;
  final int messId;
  final String messName;
  final String seasonName;
  final String role;
  final String? status;
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
