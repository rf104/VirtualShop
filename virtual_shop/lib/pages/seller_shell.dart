import 'package:flutter/material.dart';
import 'package:virtual_shop/pages/add_product_page.dart';
import 'package:virtual_shop/pages/all_review_page.dart';
import 'package:virtual_shop/pages/all_transactions_page.dart';
import 'package:virtual_shop/pages/analytics_details_page.dart';
import 'package:virtual_shop/pages/seller_dashboard_page.dart';
import 'package:virtual_shop/pages/shop_profile_page.dart';

/// A nested Navigator shell for all Seller-related pages.
/// This keeps the HomePage navbar persistent while navigating within Seller.
class SellerShell extends StatefulWidget {
  const SellerShell({super.key});

  @override
  State<SellerShell> createState() => _SellerShellState();
}

class _SellerShellState extends State<SellerShell> {
  final GlobalKey<NavigatorState> _navKey = GlobalKey<NavigatorState>();

  Route<dynamic> _onGenerateRoute(RouteSettings settings) {
    Widget page;
    switch (settings.name) {
      case '/':
        page = const SellerDashboardPage();
        break;
      case 'shop_profile':
        page = const ShopProfilePage();
        break;
      case 'analytics_details':
        page = AnalyticsDetailsPage();
        break;
      case 'transactions':
        page = const AllTransactionsPage();
        break;
      case 'reviews':
        page = const AllReviewPage();
        break;
      case 'add_product':
        page = const AddProductPage();
        break;
      default:
        page = Scaffold(
          backgroundColor: Colors.black,
          body: Center(
            child: Text(
              'Unknown route: ${settings.name}',
              style: const TextStyle(color: Colors.white),
            ),
          ),
        );
    }
    return MaterialPageRoute(builder: (_) => page, settings: settings);
  }

  Future<bool> _onWillPop() async {
    final current = _navKey.currentState;
    if (current != null && current.canPop()) {
      current.pop();
      return false; // handled here
    }
    return true; // let system/back exit the shell
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Navigator(key: _navKey, onGenerateRoute: _onGenerateRoute),
    );
  }
}
