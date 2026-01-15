enum OrderStatus {
  pending,
  preparing,
  ready,
  completed,
  cancelled;

  String get label {
    switch (this) {
      case OrderStatus.pending: return 'Pending';
      case OrderStatus.preparing: return 'Preparing';
      case OrderStatus.ready: return 'Ready';
      case OrderStatus.completed: return 'Completed';
      case OrderStatus.cancelled: return 'Cancelled';
    }
  }
}
