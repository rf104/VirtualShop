// models/transaction_models.dart
class TransactionResponse {
  final String sellerAuthId;
  final int totalTransactions;
  final int returned;
  final List<Transaction> transactions;

  TransactionResponse({
    required this.sellerAuthId,
    required this.totalTransactions,
    required this.returned,
    required this.transactions,
  });

  factory TransactionResponse.fromJson(Map<String, dynamic> json) {
    return TransactionResponse(
      sellerAuthId: json['seller_auth_id'],
      totalTransactions: json['total_transactions'],
      returned: json['returned'],
      transactions: List<Transaction>.from(
        json['transactions'].map((x) => Transaction.fromJson(x)),
      ),
    );
  }
}

class Transaction {
  final Payment payment;
  final List<Item> items;
  final OrderMeta orderMeta;

  Transaction({
    required this.payment,
    required this.items,
    required this.orderMeta,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      payment: Payment.fromJson(json['payment']),
      items: List<Item>.from(json['items'].map((x) => Item.fromJson(x))),
      orderMeta: OrderMeta.fromJson(json['order_meta']),
    );
  }
}

class Payment {
  final String id;
  final String orderId;
  final String amount;
  final String paymentMethod;
  final String paymentStatus;
  final String? transactionId;
  final String? paidAt;
  final String createdAt;

  Payment({
    required this.id,
    required this.orderId,
    required this.amount,
    required this.paymentMethod,
    required this.paymentStatus,
    required this.transactionId,
    required this.paidAt,
    required this.createdAt,
  });

  factory Payment.fromJson(Map<String, dynamic> json) {
    return Payment(
      id: json['id'],
      orderId: json['order_id'],
      amount: json['amount'].toString(),
      paymentMethod: json['payment_method'],
      paymentStatus: json['payment_status'],
      transactionId: json['transaction_id'],
      paidAt: json['paid_at'],
      createdAt: json['created_at'],
    );
  }
}

class Item {
  final String orderItemId;
  final String productId;
  final String productName;
  final int quantity;
  final String unitPrice;

  Item({
    required this.orderItemId,
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.unitPrice,
  });

  factory Item.fromJson(Map<String, dynamic> json) {
    return Item(
      orderItemId: json['order_item_id'],
      productId: json['product_id'],
      productName: json['product_name'],
      quantity: json['quantity'],
      unitPrice: json['unit_price'].toString(),
    );
  }
}

class OrderMeta {
  final String id;
  final String createdAt;
  final String orderStatus;

  OrderMeta({
    required this.id,
    required this.createdAt,
    required this.orderStatus,
  });

  factory OrderMeta.fromJson(Map<String, dynamic> json) {
    return OrderMeta(
      id: json['id'],
      createdAt: json['created_at'],
      orderStatus: json['order_status'],
    );
  }
}
