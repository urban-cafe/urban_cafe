enum OrderType {
  dineIn,
  takeaway;

  String get label {
    switch (this) {
      case OrderType.dineIn: return 'Dine-in';
      case OrderType.takeaway: return 'Takeaway';
    }
  }
}
