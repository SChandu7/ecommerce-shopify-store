// main.dart
import 'dart:async';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:animate_do/animate_do.dart';

void main() {
  runApp(ChangeNotifierProvider(create: (_) => AppState(), child: MyApp()));
}

/// Simple product model
class Product {
  final int id;
  String name;
  String description;
  double price;
  String image;
  bool available;
  String category;

  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.image,
    this.available = true,
    this.category = 'All',
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'price': price,
    'image': image,
    'available': available,
    'category': category,
  };
}

/// Cart item
class CartItem {
  final Product product;
  int quantity;
  CartItem({required this.product, this.quantity = 1});
}

/// App-wide state (products + cart)
class AppState extends ChangeNotifier {
  final List<Product> _products = [
    // Dummy initial products (images use picsum with seeds so each image is stable)
    Product(
      id: 1,
      name: 'Classic White Shirt',
      description: 'Cotton, slim fit. Comfortable for daily use.',
      price: 799.0,
      image:
          'https://images.unsplash.com/photo-1512436991641-6745cdb1723f?auto=format&fit=crop&w=600&q=80', // White shirt
      category: 'Shirts',
    ),
    Product(
      id: 2,
      name: 'Denim Jeans',
      description: 'Blue denim. Regular fit.',
      price: 1299.0,
      image:
          'https://images.unsplash.com/photo-1517841905240-472988babdf9?auto=format&fit=crop&w=600&q=80', // Jeans
      category: 'Pants',
    ),
    Product(
      id: 3,
      name: 'Summer Dress',
      description: 'Light & breezy summer dress.',
      price: 1499.0,
      image:
          'https://images.unsplash.com/photo-1469398715555-76331e92713f?auto=format&fit=crop&w=600&q=80', // Dress
      category: 'Dresses',
    ),
    Product(
      id: 4,
      name: 'Cozy Hoodie',
      description: 'Warm hoodie, perfect for winters.',
      price: 999.0,
      image:
          'https://images.unsplash.com/photo-1512436991641-6745cdb1723f?auto=format&fit=crop&w=600&q=80', // Hoodie
      category: 'Winterwear',
    ),
    Product(
      id: 5,
      name: 'Sports T-Shirt',
      description: 'Breathable sports tee.',
      price: 499.0,
      image:
          'https://images.unsplash.com/photo-1513628253939-010e64ac66cd?auto=format&fit=crop&w=600&q=80', // Sports t-shirt
      category: 'Sports',
    ),
    Product(
      id: 6,
      name: 'Ankle Boots',
      description: 'Comfortable ankle boots for casual looks.',
      price: 2199.0,
      image:
          'https://images.unsplash.com/photo-1526178613658-3b642bdbef23?auto=format&fit=crop&w=600&q=80', // Boots
      category: 'Shoes',
    ),
  ];

  // Expose copy of products
  List<Product> get products => List.unmodifiable(_products);

  // Cart: product.id -> CartItem
  final Map<int, CartItem> _cart = {};

  List<CartItem> get cartItems => _cart.values.toList();

  int get cartCount => _cart.values.fold(0, (sum, it) => sum + it.quantity);

  double get cartTotal =>
      _cart.values.fold(0.0, (sum, it) => sum + it.product.price * it.quantity);

  // Add product (used by admin)
  void addProduct(Product p) {
    // ensure id uniqueness
    final exists = _products.any((x) => x.id == p.id);
    if (exists) {
      // replace
      final idx = _products.indexWhere((x) => x.id == p.id);
      _products[idx] = p;
    } else {
      _products.add(p);
    }
    notifyListeners();
  }

  // Add to cart
  void addToCart(Product p, {int qty = 1}) {
    if (_cart.containsKey(p.id)) {
      _cart[p.id]!.quantity += qty;
    } else {
      _cart[p.id] = CartItem(product: p, quantity: qty);
    }
    notifyListeners();
  }

  // Remove from cart or decrease
  void removeFromCart(int productId, {int qty = 1}) {
    if (!_cart.containsKey(productId)) return;
    final item = _cart[productId]!;
    item.quantity -= qty;
    if (item.quantity <= 0) {
      _cart.remove(productId);
    }
    notifyListeners();
  }

  void deleteCartItem(int productId) {
    _cart.remove(productId);
    notifyListeners();
  }

  void clearCart() {
    _cart.clear();
    notifyListeners();
  }

  Product? getProductById(int id) {
    try {
      return _products.firstWhere((p) => p.id == id);
    } catch (e) {
      return null;
    }
  }

  // For demo: generate new product id
  int nextProductId() {
    if (_products.isEmpty) return 1;
    return _products.map((p) => p.id).reduce((a, b) => a > b ? a : b) + 1;
  }

  // In AppState class
  void removeProduct(int id) {
    _products.removeWhere((p) => p.id == id);
    notifyListeners();
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(debugShowCheckedModeBanner: false, home: AdminPage());
  }
}

/// Home wrapper that contains bottom nav and multiple pages
class HomeWrapper extends StatefulWidget {
  @override
  State<HomeWrapper> createState() => _HomeWrapperState();
}

class _HomeWrapperState extends State<HomeWrapper> {
  int _selectedIndex = 0;

  static const List<String> routeNames = [
    '/', // home
    '/products',
    '/cart',
    '/admin',
  ];

  void _onTap(int idx) {
    setState(() {
      _selectedIndex = idx;
    });
    // navigate without rebuilding wrapper by pushing named routes except home
    if (idx == 0) {
      // stay on HomeWrapper main home page
      // do nothing (we will show HomePage)
    } else {
      Navigator.pushNamed(context, routeNames[idx]);
    }
  }

  @override
  Widget build(BuildContext context) {
    final appBar = AppBar(
      title: Text('  Shopping  Store'),
      actions: [
        IconButton(
          icon: Icon(Icons.search),
          onPressed: () {
            // simple search dialog
            showSearch(context: context, delegate: SimpleProductSearch());
          },
        ),
        Consumer<AppState>(
          builder: (_, state, __) => Stack(
            children: [
              IconButton(
                icon: Icon(Icons.shopping_cart),
                onPressed: () => Navigator.pushNamed(context, '/cart'),
              ),
              if (state.cartCount > 0)
                Positioned(
                  right: 6,
                  top: 6,
                  child: CircleAvatar(
                    radius: 9,
                    backgroundColor: Colors.red,
                    child: Text(
                      '${state.cartCount}',
                      style: TextStyle(fontSize: 11, color: Colors.white),
                    ),
                  ),
                ),
            ],
          ),
        ),
        IconButton(
          icon: Icon(Icons.person),
          onPressed: () => Navigator.pushNamed(context, '/login'),
        ),
      ],
    );

    return Scaffold(
      appBar: appBar,
      body: HomePageContent(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onTap,
        type: BottomNavigationBarType.fixed,
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
            icon: Icon(Icons.grid_view),
            label: 'Products',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart),
            label: 'Cart',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.admin_panel_settings),
            label: 'Admin',
          ),
        ],
      ),
    );
  }
}

/// Home page content (carousel + categories + product list)
class HomePageContent extends StatefulWidget {
  @override
  State<HomePageContent> createState() => _HomePageContentState();
}

class _HomePageContentState extends State<HomePageContent> {
  final PageController _pageController = PageController(viewportFraction: 0.95);
  int _currentPage = 0;
  Timer? _timer;

  final List<String> carouselSeeds = [
    'clothes1',
    'clothes2',
    'clothes3',
    'clothes4',
    'clothes5',
  ];

  final List<Map<String, String>> categories = [
    {'label': 'Shirts', 'seed': 'cat_shirt'},
    {'label': 'Pants', 'seed': 'cat_pants'},
    {'label': 'Dresses', 'seed': 'cat_dress'},
    {'label': 'Shoes', 'seed': 'cat_shoes'},
    {'label': 'Sports', 'seed': 'cat_sports'},
    {'label': 'Winter', 'seed': 'cat_winter'},
  ];

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(Duration(seconds: 3), (_) {
      if (_pageController.hasClients) {
        var next = _currentPage + 1;
        if (next >= carouselSeeds.length) next = 0;
        _pageController.animateToPage(
          next,
          duration: Duration(milliseconds: 400),
          curve: Curves.easeInOut,
        );
      }
    });
    _pageController.addListener(() {
      final page = _pageController.page?.round() ?? 0;
      if (page != _currentPage) {
        setState(() {
          _currentPage = page;
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  Widget buildCarousel(double width) {
    // List of local images
    final List<String> localImages = [
      'assets/img1.jpg',
      'assets/img2.jpg',
      'assets/img3.jpg',
      'assets/img4.jpg',
      'assets/img5.jpg',
    ];

    return SizedBox(
      height: width > 800 ? 350 : 220, // bigger carousel on web/tablet
      child: PageView.builder(
        controller: _pageController,
        itemCount: localImages.length,
        itemBuilder: (context, idx) {
          final imagePath = localImages[idx];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6.0),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(imagePath, fit: BoxFit.cover),
                  Positioned(
                    left: 16,
                    bottom: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Trend ${idx + 1}',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: width > 800 ? 22 : 16, // bigger text on web
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget buildCategoryRow(double width) {
    final isWeb = width > 800;
    return SizedBox(
      height: isWeb ? 140 : 100,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 12),
        itemCount: categories.length,
        separatorBuilder: (_, __) => SizedBox(width: 12),
        itemBuilder: (context, i) {
          final cat = categories[i];
          final img = 'https://picsum.photos/seed/${cat['seed']}/200/200';
          return Column(
            children: [
              GestureDetector(
                onTap: () {
                  Navigator.pushNamed(
                    context,
                    '/products',
                    arguments: cat['label'],
                  );
                },
                child: CircleAvatar(
                  radius: isWeb ? 45 : 30, // bigger icons on web
                  backgroundImage: NetworkImage(img),
                ),
              ),
              SizedBox(height: 8),
              Text(cat['label']!, style: TextStyle(fontSize: isWeb ? 16 : 12)),
            ],
          );
        },
      ),
    );
  }

  Widget buildSectionHeader(String title, {VoidCallback? onMore}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8),
      child: Row(
        children: [
          Text(
            title,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          Spacer(),
          if (onMore != null)
            TextButton(onPressed: onMore, child: Text('More')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width; // ✅ responsive width
    final products = context.watch<AppState>().products;
    final popular = products.take(6).toList();

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 8),
          buildCarousel(width),
          SizedBox(height: 12),
          buildCategoryRow(width),
          buildSectionHeader(
            'Popular for you',
            onMore: () => Navigator.pushNamed(context, '/products'),
          ),
          // horizontal popular list
          SizedBox(
            height: width > 800 ? 340 : 260, // bigger product cards on web
            child: ListView.separated(
              padding: EdgeInsets.symmetric(horizontal: 12),
              scrollDirection: Axis.horizontal,
              itemCount: popular.length,
              separatorBuilder: (_, __) => SizedBox(width: 12),
              itemBuilder: (context, idx) {
                final p = popular[idx];
                return ProductCardHorizontal(product: p);
              },
            ),
          ),
          buildSectionHeader(
            'All Products',
            onMore: () => Navigator.pushNamed(context, '/products'),
          ),
          // product grid
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: LayoutBuilder(
              builder: (context, constraints) {
                int cross = 2;
                if (constraints.maxWidth > 1400)
                  cross = 5;
                else if (constraints.maxWidth > 1200)
                  cross = 4;
                else if (constraints.maxWidth > 800)
                  cross = 3;
                return GridView.builder(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemCount: products.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: cross,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: width > 800 ? 0.75 : 0.68,
                  ),
                  itemBuilder: (context, idx) {
                    final p = products[idx];
                    return ProductTile(product: p);
                  },
                );
              },
            ),
          ),
          SizedBox(height: 40), // bottom padding to show nav
        ],
      ),
    );
  }
}

/// Horizontal product card (used in popular carousel)
class ProductCardHorizontal extends StatelessWidget {
  final Product product;
  const ProductCardHorizontal({Key? key, required this.product})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width; // ✅ responsive

    return SizedBox(
      width: width > 1000
          ? 280
          : width > 600
          ? 240
          : 220,
      child: Card(
        clipBehavior: Clip.hardEdge,
        child: InkWell(
          onTap: () => Navigator.pushNamed(context, '/product/${product.id}'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Image.network(
                product.image,
                height: width > 1000
                    ? 200
                    : width > 600
                    ? 160
                    : 140,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  product.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: width > 800 ? 16 : 14),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Text(
                  '₹${product.price.toStringAsFixed(0)}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: width > 800 ? 16 : 14,
                  ),
                ),
              ),
              Spacer(),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: ElevatedButton(
                  onPressed: () {
                    context.read<AppState>().addToCart(product);
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text('Added to cart')));
                  },
                  child: Text('Add'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Product tile for grid
class ProductTile extends StatelessWidget {
  final Product product;
  const ProductTile({Key? key, required this.product}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width; // ✅ responsive

    return Card(
      clipBehavior: Clip.hardEdge,
      child: InkWell(
        onTap: () => Navigator.pushNamed(context, '/product/${product.id}'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: width > 800 ? 1.3 : 1, // bigger aspect ratio on web
              child: Image.network(product.image, fit: BoxFit.cover),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                product.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: width > 800 ? 16 : 14),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Text(
                '₹${product.price.toStringAsFixed(0)}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: width > 800 ? 16 : 14,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Text(
                product.available ? 'In stock' : 'Out of stock',
                style: TextStyle(
                  fontSize: width > 800 ? 13 : 12,
                  color: product.available ? Colors.green : Colors.red,
                ),
              ),
            ),
            Spacer(),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: product.available
                          ? () {
                              context.read<AppState>().addToCart(product);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Added to cart')),
                              );
                            }
                          : null,
                      child: Text('Add to cart'),
                    ),
                  ),
                  SizedBox(width: 8),
                  IconButton(
                    icon: Icon(Icons.favorite_border),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Added to wishlist (demo)')),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Products page (optional category filter via args)
class ProductsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final arg = ModalRoute.of(context)?.settings.arguments;
    String? categoryFilter;
    if (arg != null && arg is String) categoryFilter = arg;

    final products = context
        .watch<AppState>()
        .products
        .where(
          (p) =>
              categoryFilter == null ||
              categoryFilter == 'All' ||
              p.category == categoryFilter,
        )
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          categoryFilter == null ? 'Products' : 'Products: $categoryFilter',
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: LayoutBuilder(
          builder: (context, constraints) {
            int cross = 2;
            if (constraints.maxWidth > 1400)
              cross = 5;
            else if (constraints.maxWidth > 1100)
              cross = 4;
            else if (constraints.maxWidth > 700)
              cross = 3;
            return GridView.builder(
              itemCount: products.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: cross,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: constraints.maxWidth > 800 ? 0.75 : 0.68,
              ),
              itemBuilder: (context, idx) =>
                  ProductTile(product: products[idx]),
            );
          },
        ),
      ),
    );
  }
}

/// Product detail page
class ProductDetailPage extends StatelessWidget {
  final int productId;
  const ProductDetailPage({Key? key, required this.productId})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width; // ✅ responsive
    final p = context.read<AppState>().getProductById(productId);
    if (p == null) {
      return Scaffold(
        appBar: AppBar(title: Text('Product')),
        body: Center(child: Text('Product not found')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(p.name)),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: width > 1000 ? 80 : 12, // more padding on web
            vertical: 20,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AspectRatio(
                aspectRatio: width > 800 ? 1.8 : 1.2, // wider on desktop
                child: Image.network(p.image, fit: BoxFit.cover),
              ),
              SizedBox(height: 12),
              Text(
                p.name,
                style: TextStyle(
                  fontSize: width > 800 ? 28 : 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              Text(
                '₹${p.price.toStringAsFixed(0)}',
                style: TextStyle(
                  fontSize: width > 800 ? 24 : 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.deepOrange,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Category: ${p.category}',
                style: TextStyle(fontSize: width > 800 ? 16 : 14),
              ),
              SizedBox(height: 12),
              Text(
                p.description,
                style: TextStyle(fontSize: width > 800 ? 16 : 14),
              ),
              SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: p.available
                          ? () {
                              context.read<AppState>().addToCart(p);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Added to cart')),
                              );
                            }
                          : null,
                      icon: Icon(Icons.add_shopping_cart),
                      label: Text('Add to cart'),
                    ),
                  ),
                  SizedBox(width: 12),
                  OutlinedButton.icon(
                    onPressed: () {},
                    icon: Icon(Icons.share),
                    label: Text('Share'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Cart page
class CartPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cart = context.watch<AppState>().cartItems;

    return Scaffold(
      appBar: AppBar(
        title: Text('Cart (${context.watch<AppState>().cartCount})'),
      ),
      body: cart.isEmpty
          ? Center(child: Text('Your cart is empty'))
          : Column(
              children: [
                Expanded(
                  child: ListView.separated(
                    itemCount: cart.length,
                    separatorBuilder: (_, __) => Divider(height: 1),
                    itemBuilder: (context, idx) {
                      final item = cart[idx];
                      return LayoutBuilder(
                        builder: (context, constraints) {
                          final isWide = constraints.maxWidth > 500;
                          return ListTile(
                            leading: Image.network(
                              item.product.image,
                              width: 56,
                              height: 56,
                              fit: BoxFit.cover,
                            ),
                            title: Text(item.product.name),
                            subtitle: Text(
                              '₹${item.product.price.toStringAsFixed(0)} x ${item.quantity}',
                            ),
                            trailing: isWide
                                ? Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: _buildCartActions(context, item),
                                  )
                                : Wrap(
                                    spacing: 4,
                                    children: _buildCartActions(context, item),
                                  ),
                          );
                        },
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Text('Total', style: TextStyle(fontSize: 18)),
                          Spacer(),
                          Text(
                            '₹${context.watch<AppState>().cartTotal.toStringAsFixed(0)}',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 12),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final isWide = constraints.maxWidth > 400;
                          return isWide
                              ? Row(
                                  children: [
                                    Expanded(child: _checkoutButton(context)),
                                    SizedBox(width: 12),
                                    OutlinedButton(
                                      onPressed: () =>
                                          context.read<AppState>().clearCart(),
                                      child: Text('Clear'),
                                    ),
                                  ],
                                )
                              : Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    _checkoutButton(context),
                                    SizedBox(height: 8),
                                    OutlinedButton(
                                      onPressed: () =>
                                          context.read<AppState>().clearCart(),
                                      child: Text('Clear'),
                                    ),
                                  ],
                                );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  List<Widget> _buildCartActions(BuildContext context, CartItem item) {
    return [
      IconButton(
        icon: Icon(Icons.remove),
        onPressed: () =>
            context.read<AppState>().removeFromCart(item.product.id),
      ),
      IconButton(
        icon: Icon(Icons.add),
        onPressed: () => context.read<AppState>().addToCart(item.product),
      ),
      IconButton(
        icon: Icon(Icons.delete_outline),
        onPressed: () =>
            context.read<AppState>().deleteCartItem(item.product.id),
      ),
    ];
  }

  Widget _checkoutButton(BuildContext context) {
    return ElevatedButton(
      onPressed: () {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: Text('Checkout'),
            content: Text(
              'Proceed to pay ₹${context.read<AppState>().cartTotal.toStringAsFixed(0)}?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  context.read<AppState>().clearCart();
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Payment successful (demo)')),
                  );
                },
                child: Text('Pay'),
              ),
            ],
          ),
        );
      },
      child: Text('Checkout'),
    );
  }
}

/// Admin page with dashboard + product management
class AdminPage extends StatefulWidget {
  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    return Scaffold(
      appBar: AppBar(
        title: Text('Admin Dashboard'),
        actions: [
          IconButton(icon: Icon(Icons.notifications), onPressed: () {}),
          IconButton(icon: Icon(Icons.settings), onPressed: () {}),
          IconButton(icon: Icon(Icons.logout), onPressed: () {}),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: Icon(Icons.add),
        label: Text("Add Product"),
        onPressed: () => _showAddProductDialog(context, state),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildAdminProfile(),
            SizedBox(height: 20),
            _buildQuickActions(),
            SizedBox(height: 20),
            _buildStatsRow(state),
            SizedBox(height: 24),
            _buildGraphsSection(),
            SizedBox(height: 24),
            _buildProductsList(state),
          ],
        ),
      ),
    );
  }

  /// --- Admin Profile Header ---
  Widget _buildAdminProfile() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 36,
              backgroundImage: AssetImage(
                "assets/imgicon1.png", // your local image
              ),
            ),

            SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Ray & Roy",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                Text(
                  "Super Admin",
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// --- Quick Actions Shortcuts ---
  Widget _buildQuickActions() {
    final actions = [
      {"icon": Icons.add_box, "label": "Add Product"},
      {"icon": Icons.category, "label": "Categories"},
      {"icon": Icons.receipt, "label": "Orders"},
      {"icon": Icons.bar_chart, "label": "Analytics"},
    ];

    return GridView.count(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 4.0,
      children: actions
          .map(
            (a) => ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () {},
              icon: Icon(a["icon"] as IconData, size: 20),
              label: Text(a["label"] as String, textAlign: TextAlign.center),
            ),
          )
          .toList(),
    );
  }

  /// --- Stats Cards Row ---
  Widget _buildStatsRow(AppState state) {
    final stats = [
      {
        "title": "Products",
        "value": state.products.length.toString(),
        "icon": Icons.inventory,
        "color": Colors.blue,
      },
      {
        "title": "Orders",
        "value": "328",
        "icon": Icons.shopping_bag,
        "color": Colors.green,
      },
      {
        "title": "Revenue",
        "value": "₹1.2L",
        "icon": Icons.attach_money,
        "color": Colors.orange,
      },
      {
        "title": "Customers",
        "value": "785",
        "icon": Icons.people,
        "color": Colors.purple,
      },
    ];

    return GridView.count(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      crossAxisCount: MediaQuery.of(context).size.width < 600 ? 2 : 4,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.3,
      children: stats
          .map(
            (s) => _buildStatCard(
              s["title"] as String,
              s["value"] as String,
              s["icon"] as IconData,
              s["color"] as Color,
            ),
          )
          .toList(),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: color),
            SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 4),
            Text(title, style: TextStyle(fontSize: 14, color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  /// --- Graphs Section ---
  Widget _buildGraphsSection() {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Column(
      children: [
        Card(
          elevation: 3,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: SizedBox(
              height: 220,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(show: true),
                  titlesData: FlTitlesData(show: true),
                  borderData: FlBorderData(show: true),
                  lineBarsData: [
                    LineChartBarData(
                      spots: [
                        FlSpot(1, 20),
                        FlSpot(2, 50),
                        FlSpot(3, 35),
                        FlSpot(4, 80),
                        FlSpot(5, 65),
                        FlSpot(6, 95),
                      ],
                      isCurved: true,
                      color: Colors.blue,
                      belowBarData: BarAreaData(
                        show: true,
                        color: Colors.blue.withOpacity(0.2),
                      ),
                      dotData: FlDotData(show: true),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        SizedBox(height: 16),
        Card(
          elevation: 3,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                Text(
                  "Order Distribution",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 12),
                SizedBox(
                  height: 180,
                  child: PieChart(
                    PieChartData(
                      sections: [
                        PieChartSectionData(
                          value: 40,
                          title: "Electronics",
                          color: Colors.blue,
                        ),
                        PieChartSectionData(
                          value: 25,
                          title: "Clothes",
                          color: Colors.green,
                        ),
                        PieChartSectionData(
                          value: 20,
                          title: "Shoes",
                          color: Colors.orange,
                        ),
                        PieChartSectionData(
                          value: 15,
                          title: "Others",
                          color: Colors.purple,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// --- Products List ---
  Widget _buildProductsList(AppState state) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Recent Products",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: [
                  DataColumn(label: Text("Image")),
                  DataColumn(label: Text("Name")),
                  DataColumn(label: Text("Category")),
                  DataColumn(label: Text("Price")),
                  DataColumn(label: Text("Actions")),
                ],
                rows: state.products.map((p) {
                  return DataRow(
                    cells: [
                      DataCell(Image.network(p.image, width: 40, height: 40)),
                      DataCell(Text(p.name)),
                      DataCell(Text(p.category)),
                      DataCell(Text("₹${p.price.toStringAsFixed(0)}")),
                      DataCell(
                        Row(
                          children: [
                            IconButton(
                              icon: Icon(Icons.edit),
                              onPressed: () {},
                            ),
                            IconButton(
                              icon: Icon(Icons.delete),
                              onPressed: () =>
                                  context.read<AppState>().removeProduct(p.id),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// --- Add Product Dialog ---
  void _showAddProductDialog(BuildContext context, AppState state) {
    final _formKey = GlobalKey<FormState>();
    final _nameCtl = TextEditingController();
    final _descCtl = TextEditingController();
    final _priceCtl = TextEditingController();
    final _imageCtl = TextEditingController();
    String category = 'Shirts';
    bool available = true;

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text("Add Product"),
          content: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: _nameCtl,
                    decoration: InputDecoration(labelText: 'Name'),
                    validator: (v) =>
                        v == null || v.isEmpty ? 'Required' : null,
                  ),
                  SizedBox(height: 8),
                  TextFormField(
                    controller: _descCtl,
                    decoration: InputDecoration(labelText: 'Description'),
                    maxLines: 2,
                  ),
                  SizedBox(height: 8),
                  TextFormField(
                    controller: _priceCtl,
                    decoration: InputDecoration(labelText: 'Price (₹)'),
                    keyboardType: TextInputType.number,
                    validator: (v) => v == null || double.tryParse(v) == null
                        ? 'Enter price'
                        : null,
                  ),
                  SizedBox(height: 8),
                  TextFormField(
                    controller: _imageCtl,
                    decoration: InputDecoration(
                      labelText: 'Image URL (optional)',
                    ),
                  ),
                  SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: category,
                    items:
                        [
                              'Shirts',
                              'Pants',
                              'Dresses',
                              'Shoes',
                              'Sports',
                              'Winter',
                            ]
                            .map(
                              (c) => DropdownMenuItem(value: c, child: Text(c)),
                            )
                            .toList(),
                    onChanged: (v) => category = v ?? 'Shirts',
                  ),
                  SwitchListTile(
                    value: available,
                    title: Text('Available'),
                    onChanged: (v) => available = v,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text("Cancel"),
            ),
            ElevatedButton(
              child: Text("Add"),
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  final id = state.nextProductId();
                  final img = _imageCtl.text.trim().isEmpty
                      ? 'https://picsum.photos/seed/admin$id/600/600'
                      : _imageCtl.text.trim();
                  final p = Product(
                    id: id,
                    name: _nameCtl.text.trim(),
                    description: _descCtl.text.trim(),
                    price: double.parse(_priceCtl.text.trim()),
                    image: img,
                    available: available,
                    category: category,
                  );
                  state.addProduct(p);
                  Navigator.pop(ctx);
                }
              },
            ),
          ],
        );
      },
    );
  }
}

class SensorHistoryScreen extends StatefulWidget {
  const SensorHistoryScreen({Key? key}) : super(key: key);

  @override
  State<SensorHistoryScreen> createState() => _SensorHistoryScreenState();
}

class _SensorHistoryScreenState extends State<SensorHistoryScreen> {
  bool isLoading = true;
  List<dynamic> sensorData = [];

  @override
  void initState() {
    super.initState();
    fetchSensorData();
  }

  Future<void> fetchSensorData() async {
    try {
      final response = await http.get(
        Uri.parse("http://13.203.219.206:8000/devathonsensordata/"),
      );

      if (response.statusCode == 200) {
        setState(() {
          sensorData = json.decode(response.body);
          sensorData.sort((a, b) =>
              DateTime.parse(b['timestamp']).compareTo(DateTime.parse(a['timestamp'])));
          isLoading = false;
        });
      } else {
        throw Exception('Failed to load data');
      }
    } catch (e) {
      print("Error fetching data: $e");
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (sensorData.isEmpty) {
      return const Scaffold(
        body: Center(child: Text("No data available")),
      );
    }

    final latest = sensorData.first;
    final history = sensorData.skip(1).toList();

    // Group history by date
    final Map<String, List<dynamic>> groupedHistory = {};
    for (var record in history) {
      final dateKey =
          DateFormat('yyyy-MM-dd').format(DateTime.parse(record['timestamp']));
      groupedHistory.putIfAbsent(dateKey, () => []).add(record);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Field Unit - Live & History",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF6A1B9A),
      ),
      body: RefreshIndicator(
        onRefresh: fetchSensorData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 🌿 Live Reading Card
              _buildLiveReadingCard(latest),

              const SizedBox(height: 20),

              const Text(
                "📜 History",
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87),
              ),
              const SizedBox(height: 10),

              // 📅 Expandable History Sections
              ...groupedHistory.entries.map(
                (entry) => _buildExpandableDateCard(entry.key, entry.value),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLiveReadingCard(Map<String, dynamic> latest) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeInOut,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF8E2DE2), Color(0xFF4A00E0)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.purple.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "🌿 Live Reading",
            style: TextStyle(
                fontSize: 22, color: Colors.white, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          _buildDataRow("Device", latest["device"]),
          _buildDataRow("Soil Moisture Level", latest["soil_moisture_level"]),
          _buildDataRow("Soil Value", latest["soil_value"].toString()),
          _buildDataRow("Turbidity Level", latest["turbidity_level"]),
          _buildDataRow("Turbidity Value", latest["turbidity_value"].toString()),
          _buildDataRow(
            "Timestamp",
            DateFormat('MMM d, yyyy hh:mm a')
                .format(DateTime.parse(latest["timestamp"])),
          ),
        ],
      ),
    );
  }

  Widget _buildExpandableDateCard(String date, List<dynamic> records) {
    return Card(
      elevation: 5,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: ExpansionTile(
        backgroundColor: Colors.white,
        collapsedBackgroundColor: const Color(0xFFF3E5F5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: Text(
          "📅 ${DateFormat('MMM d, yyyy').format(DateTime.parse(date))}",
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        children: records.map((record) {
          return ListTile(
            title: Text(
              "🌱 ${record['soil_moisture_level']} | 💧 ${record['turbidity_level']}",
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            subtitle: Text(
              "Soil: ${record['soil_value']} | Turbidity: ${record['turbidity_value']}",
              style: const TextStyle(color: Colors.black54),
            ),
            trailing: Text(
              DateFormat('hh:mm a')
                  .format(DateTime.parse(record['timestamp'])),
              style: const TextStyle(color: Colors.deepPurple),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildDataRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(color: Colors.white70, fontSize: 15)),
          Text(value,
              style:
                  const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}


/// Simple login page (stub)
class LoginPage2 extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Login (Demo)')),
      body: Center(
        child: LayoutBuilder(
          builder: (context, constraints) {
            double maxWidth = constraints.maxWidth > 600
                ? 400
                : constraints.maxWidth * 0.9;
            return ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxWidth),
              child: Card(
                margin: EdgeInsets.all(24),
                child: Padding(
                  padding: const EdgeInsets.all(18.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Login (demo)', style: TextStyle(fontSize: 18)),
                      SizedBox(height: 12),
                      TextField(
                        decoration: InputDecoration(labelText: 'Email'),
                      ),
                      SizedBox(height: 8),
                      TextField(
                        decoration: InputDecoration(labelText: 'Password'),
                        obscureText: true,
                      ),
                      SizedBox(height: 12),
                      SizedBox(
                        width:
                            double.infinity, // make button stretch full width
                        child: ElevatedButton(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Logged in (demo)')),
                            );
                            Navigator.pop(context);
                          },
                          child: Text('Login'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool eye = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: MediaQuery.of(context).size.height,
          ),
          child: IntrinsicHeight(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                // Header with gradient
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(45),
                      bottomRight: Radius.circular(45),
                    ),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      colors: [
                        Colors.orange.shade900,
                        Colors.orange.shade800,
                        Colors.orange.shade400,
                      ],
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      const SizedBox(height: 90),
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            FadeInUp(
                              duration: const Duration(milliseconds: 800),
                              child: const Text(
                                "Login",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 40,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            FadeInUp(
                              duration: const Duration(milliseconds: 1100),
                              child: const Text(
                                "Welcome Back",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Body with fields
                Expanded(
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(10),
                        topRight: Radius.circular(10),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(30),
                      child: Column(
                        children: <Widget>[
                          const SizedBox(height: 60),

                          // Username field
                          FadeInUp(
                            duration: const Duration(milliseconds: 1200),
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Color.fromRGBO(225, 95, 27, .3),
                                    blurRadius: 20,
                                    offset: Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: Column(
                                children: <Widget>[
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      border: Border(
                                        bottom: BorderSide(
                                          color: Colors.grey.shade200,
                                        ),
                                      ),
                                    ),
                                    child: const TextField(
                                      decoration: InputDecoration(
                                        hintText: "Email or Phone number",
                                        hintStyle: TextStyle(
                                          color: Colors.grey,
                                        ),
                                        border: InputBorder.none,
                                        prefixIcon: Icon(
                                          Icons.verified_user,
                                          color: Colors.orangeAccent,
                                        ),
                                      ),
                                    ),
                                  ),

                                  // Password field
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    child: TextField(
                                      obscureText: eye,
                                      decoration: InputDecoration(
                                        hintText: "Password",
                                        hintStyle: const TextStyle(
                                          color: Colors.grey,
                                        ),
                                        prefixIcon: const Icon(
                                          Icons.lock,
                                          color: Colors.orangeAccent,
                                        ),
                                        border: InputBorder.none,
                                        suffixIcon: InkWell(
                                          onTap: () {
                                            setState(() {
                                              eye = !eye;
                                            });
                                          },
                                          child: Icon(
                                            eye
                                                ? Icons.visibility_off
                                                : Icons.visibility,
                                            color: Colors.lightBlue,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 40),

                          // Login button
                          FadeInUp(
                            duration: const Duration(milliseconds: 1400),
                            child: MaterialButton(
                              onPressed: () {},
                              height: 50,
                              color: Colors.orange[900],
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(50),
                              ),
                              child: const Center(
                                child: Text(
                                  "Login",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 30),

                          FadeInUp(
                            child: Row(
                              children: <Widget>[
                                // Facebook Button
                                Expanded(
                                  child: FadeInUp(
                                    duration: const Duration(
                                      milliseconds: 1600,
                                    ),
                                    child: MaterialButton(
                                      onPressed: () {
                                        // TODO: Add Facebook login logic
                                      },
                                      height: 50,
                                      color: Colors.blue, // Facebook blue
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(50),
                                      ),
                                      child: const Center(
                                        child: Text(
                                          "Facebook",
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),

                                const SizedBox(width: 20),

                                // Google Button
                                Expanded(
                                  child: FadeInUp(
                                    duration: const Duration(
                                      milliseconds: 1700,
                                    ),
                                    child: MaterialButton(
                                      onPressed: () {
                                        // TODO: Add Google login logic
                                      },
                                      height: 50,
                                      color: Colors.black, // Google dark theme
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(50),
                                      ),
                                      child: const Center(
                                        child: Text(
                                          "Google",
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Not found
class NotFoundPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text('Not found')),
    body: Center(child: Text('Page not found')),
  );
}

/// Search delegate for quick product search
class SimpleProductSearch extends SearchDelegate<Product?> {
  @override
  List<Widget>? buildActions(BuildContext context) => [
    if (query.isNotEmpty)
      IconButton(icon: Icon(Icons.clear), onPressed: () => query = ''),
  ];

  @override
  Widget? buildLeading(BuildContext context) => IconButton(
    icon: Icon(Icons.arrow_back),
    onPressed: () => close(context, null),
  );

  @override
  Widget buildResults(BuildContext context) {
    final results = context
        .read<AppState>()
        .products
        .where((p) => p.name.toLowerCase().contains(query.toLowerCase()))
        .toList();
    if (results.isEmpty) return Center(child: Text('No results'));
    return ListView.builder(
      itemCount: results.length,
      itemBuilder: (_, i) {
        final p = results[i];
        return ListTile(
          leading: Image.network(
            p.image,
            width: 56,
            height: 56,
            fit: BoxFit.cover,
          ),
          title: Text(p.name),
          subtitle: Text('₹${p.price.toStringAsFixed(0)}'),
          onTap: () {
            close(context, p);
            Navigator.pushNamed(context, '/product/${p.id}');
          },
        );
      },
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    final suggestions = context
        .read<AppState>()
        .products
        .where((p) => p.name.toLowerCase().contains(query.toLowerCase()))
        .toList();
    return ListView.builder(
      itemCount: suggestions.length,
      itemBuilder: (_, i) {
        final p = suggestions[i];
        return ListTile(
          leading: Image.network(
            p.image,
            width: 56,
            height: 56,
            fit: BoxFit.cover,
          ),
          title: Text(p.name),
          onTap: () {
            query = p.name;
            showResults(context);
          },
        );
      },
    );
  }
}
