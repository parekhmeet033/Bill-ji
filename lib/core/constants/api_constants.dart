class ApiConstants {
  // --- Active Production Server Configuration ---
  static const String liveBaseUrl = 'https://lineless.goalscripture.in/api/';
  static const String liveWebBaseUrl = 'https://lineless.goalscripture.in';
  static const String liveImageBaseUrl = 'https://lineless.goalscripture.in/storage/products/';
  static const String liveCategoryImageBaseUrl = 'https://lineless.goalscripture.in/uploads/categories/';
  static const String liveWebSocketUrl = 'wss://lineless.goalscripture.in';

  // --- Dynamic Active Base URLs ---
  static String get baseUrl => liveBaseUrl;
  static String get webBaseUrl => liveWebBaseUrl;
  static String get imageBaseUrl => liveImageBaseUrl;
  static String get categoryImageBaseUrl => liveCategoryImageBaseUrl;
  static String get webSocketUrl => liveWebSocketUrl;

  static const int connectTimeout = 30000; // 30 seconds
  static const int receiveTimeout = 30000; // 30 seconds

  // --- Endpoints ---
  static const String login = 'login';
  static const String logout = 'logout';
  static const String dashboard = 'dashboard';
  static const String menuList = 'menu-list';
  static const String menuAdd = 'menu-add';
  static const String menuUpdate = 'menu-update';
  static const String menuDestroy = 'menu-destroy';
  static const String menuStatus = 'menu-status';
  static const String ordersList = 'orders-list';
  static const String reportsAnalytics = 'reports-analytics';
  static const String ordersStatus = 'orders-status';
  static const String settings = 'settings';
  static const String categoryList = 'category-list';
  static const String categoryAdd = 'category-add';
  static const String categoryUpdate = 'category-update';
  static const String categoryDestroy = 'category-destroy';
  static const String categoryReorder = 'category-reorder';
  static const String menuReorder = 'menu-reorder';
  static const String tableProductList = 'table-product-list';
  static const String saveTableOrder = 'save-table-order';
  static const String posOrder = 'pos-order';
  static const String posDraft = 'pos-draft';
  static const String posDraftSave = 'pos-draft-save';
  static const String posDraftClear = 'pos-draft-clear';
  static const String pendingTables = 'pending-tables';
  static const String forgotPin = 'forgot-pin';
}

class CacheConstants {
  static const String tokenBox = 'tokenBox';
  static const String authToken = 'authToken';
  static const String userId = 'userId';
}
