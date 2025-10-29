// main.dart
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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
      image: 'https://picsum.photos/seed/shirt1/600/600',
      category: 'Shirts',
    ),
    Product(
      id: 2,
      name: 'Denim Jeans',
      description: 'Blue denim. Regular fit.',
      price: 1299.0,
      image: 'https://picsum.photos/seed/pants1/600/600',
      category: 'Pants',
    ),
    Product(
      id: 3,
      name: 'Summer Dress',
      description: 'Light & breezy summer dress.',
      price: 1499.0,
      image: 'https://picsum.photos/seed/dress1/600/600',
      category: 'Dresses',
    ),
    Product(
      id: 4,
      name: 'Cozy Hoodie',
      description: 'Warm hoodie, perfect for winters.',
      price: 999.0,
      image: 'https://picsum.photos/seed/hoodie1/600/600',
      category: 'Winterwear',
    ),
    Product(
      id: 5,
      name: 'Sports T-Shirt',
      description: 'Breathable sports tee.',
      price: 499.0,
      image: 'https://picsum.photos/seed/tshirt1/600/600',
      category: 'Sports',
    ),
    Product(
      id: 6,
      name: 'Ankle Boots',
      description: 'Comfortable ankle boots for casual looks.',
      price: 2199.0,
      image: 'https://picsum.photos/seed/boots1/600/600',
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
}

/// Main app with routing
class MyApp extends StatelessWidget {
  MyApp({Key? key}) : super(key: key);

  final _appTitle = 'Mini Flipkart Clone (v0)';

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: _appTitle,
      debugShowCheckedModeBanner: false,
      // Basic named routes + dynamic product route parsing
      initialRoute: '/',
      onGenerateRoute: (settings) {
        // handle /product/<id>
        final uri = Uri.parse(settings.name ?? '/');
        if (uri.pathSegments.isNotEmpty && uri.pathSegments[0] == 'product') {
          if (uri.pathSegments.length >= 2) {
            final idStr = uri.pathSegments[1];
            final id = int.tryParse(idStr);
            if (id != null) {
              return MaterialPageRoute(
                settings: settings,
                builder: (_) => ProductDetailPage(productId: id),
              );
            }
          }
        }

        switch (settings.name) {
          case '/':
            return MaterialPageRoute(builder: (_) => HomeWrapper());
          case '/products':
            return MaterialPageRoute(builder: (_) => ProductsPage());
          case '/cart':
            return MaterialPageRoute(builder: (_) => CartPage());
          case '/admin':
            return MaterialPageRoute(builder: (_) => AdminPage());
          case '/login':
            return MaterialPageRoute(builder: (_) => LoginPage());
          default:
            return MaterialPageRoute(builder: (_) => NotFoundPage());
        }
      },
    );
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
      title: Text('Mini Flipkart Clone'),
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

  Widget buildCarousel() {
    return SizedBox(
      height: 220,
      child: PageView.builder(
        controller: _pageController,
        itemCount: carouselSeeds.length,
        itemBuilder: (context, idx) {
          final seed = carouselSeeds[idx];
          final imageUrl = 'https://picsum.photos/seed/$seed/1200/800';
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6.0),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    loadingBuilder: (c, w, s) {
                      if (s == null) return w;
                      return Container(color: Colors.grey[200]);
                    },
                  ),
                  Positioned(
                    left: 16,
                    bottom: 16,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Trend ${idx + 1}',
                        style: TextStyle(color: Colors.white, fontSize: 16),
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

  Widget buildCategoryRow() {
    return SizedBox(
      height: 100,
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
                  // navigate to products page filtered by category
                  Navigator.pushNamed(
                    context,
                    '/products',
                    arguments: cat['label'],
                  );
                },
                child: CircleAvatar(
                  radius: 30,
                  backgroundImage: NetworkImage(img),
                ),
              ),
              SizedBox(height: 8),
              Text(cat['label']!, style: TextStyle(fontSize: 12)),
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
    final products = context.watch<AppState>().products;
    final popular = products.take(6).toList();

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 8),
          buildCarousel(),
          SizedBox(height: 12),
          buildCategoryRow(),
          buildSectionHeader(
            'Popular for you',
            onMore: () => Navigator.pushNamed(context, '/products'),
          ),
          // horizontal popular list
          SizedBox(
            height: 260,
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
                if (constraints.maxWidth > 1200)
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
                    childAspectRatio: 0.68,
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
    return SizedBox(
      width: 220,
      child: Card(
        clipBehavior: Clip.hardEdge,
        child: InkWell(
          onTap: () => Navigator.pushNamed(context, '/product/${product.id}'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Image.network(
                product.image,
                height: 140,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  product.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Text(
                  '₹${product.price.toStringAsFixed(0)}',
                  style: TextStyle(fontWeight: FontWeight.bold),
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
    return Card(
      clipBehavior: Clip.hardEdge,
      child: InkWell(
        onTap: () => Navigator.pushNamed(context, '/product/${product.id}'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 1,
              child: Image.network(product.image, fit: BoxFit.cover),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                product.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Text(
                '₹${product.price.toStringAsFixed(0)}',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Text(
                product.available ? 'In stock' : 'Out of stock',
                style: TextStyle(
                  fontSize: 12,
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
            if (constraints.maxWidth > 1200)
              cross = 5;
            else if (constraints.maxWidth > 800)
              cross = 4;
            else if (constraints.maxWidth > 600)
              cross = 3;
            return GridView.builder(
              itemCount: products.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: cross,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.68,
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
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AspectRatio(
                aspectRatio: 1.2,
                child: Image.network(p.image, fit: BoxFit.cover),
              ),
              SizedBox(height: 12),
              Text(
                p.name,
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                '₹${p.price.toStringAsFixed(0)}',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.deepOrange,
                ),
              ),
              SizedBox(height: 8),
              Text('Category: ${p.category}'),
              SizedBox(height: 12),
              Text(p.description),
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
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(Icons.remove),
                              onPressed: () => context
                                  .read<AppState>()
                                  .removeFromCart(item.product.id),
                            ),
                            IconButton(
                              icon: Icon(Icons.add),
                              onPressed: () => context
                                  .read<AppState>()
                                  .addToCart(item.product),
                            ),
                            IconButton(
                              icon: Icon(Icons.delete_outline),
                              onPressed: () => context
                                  .read<AppState>()
                                  .deleteCartItem(item.product.id),
                            ),
                          ],
                        ),
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
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                // Demo checkout: clears cart and shows success
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
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                'Payment successful (demo)',
                                              ),
                                            ),
                                          );
                                        },
                                        child: Text('Pay'),
                                      ),
                                    ],
                                  ),
                                );
                              },
                              child: Text('Checkout'),
                            ),
                          ),
                          SizedBox(width: 12),
                          OutlinedButton(
                            onPressed: () =>
                                context.read<AppState>().clearCart(),
                            child: Text('Clear'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}

/// Admin page to add products
class AdminPage extends StatefulWidget {
  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtl = TextEditingController();
  final _descCtl = TextEditingController();
  final _priceCtl = TextEditingController();
  final _imageCtl = TextEditingController();
  String _category = 'Shirts';
  bool _available = true;

  @override
  void dispose() {
    _nameCtl.dispose();
    _descCtl.dispose();
    _priceCtl.dispose();
    _imageCtl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.read<AppState>();
    return Scaffold(
      appBar: AppBar(title: Text('Admin Dashboard')),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: SingleChildScrollView(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          Text(
                            'Add New Product',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 12),
                          TextFormField(
                            controller: _nameCtl,
                            decoration: InputDecoration(labelText: 'Name'),
                            validator: (v) =>
                                v == null || v.isEmpty ? 'Required' : null,
                          ),
                          SizedBox(height: 8),
                          TextFormField(
                            controller: _descCtl,
                            decoration: InputDecoration(
                              labelText: 'Description',
                            ),
                            maxLines: 3,
                          ),
                          SizedBox(height: 8),
                          TextFormField(
                            controller: _priceCtl,
                            decoration: InputDecoration(labelText: 'Price (₹)'),
                            keyboardType: TextInputType.number,
                            validator: (v) =>
                                v == null || double.tryParse(v) == null
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
                            value: _category,
                            items:
                                [
                                      'Shirts',
                                      'Pants',
                                      'Dresses',
                                      'Shoes',
                                      'Sports',
                                      'Winter',
                                      'All',
                                    ]
                                    .map(
                                      (c) => DropdownMenuItem(
                                        child: Text(c),
                                        value: c,
                                      ),
                                    )
                                    .toList(),
                            onChanged: (v) =>
                                setState(() => _category = v ?? 'Shirts'),
                          ),
                          SizedBox(height: 8),
                          SwitchListTile(
                            value: _available,
                            onChanged: (v) => setState(() => _available = v),
                            title: Text('Available'),
                          ),
                          SizedBox(height: 12),
                          ElevatedButton(
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
                                  available: _available,
                                  category: _category,
                                );
                                state.addProduct(p);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Product added')),
                                );
                                _nameCtl.clear();
                                _descCtl.clear();
                                _priceCtl.clear();
                                _imageCtl.clear();
                              }
                            },
                            child: Text('Add Product'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              flex: 3,
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    children: [
                      Text(
                        'Products (live)',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 12),
                      Expanded(
                        child: Consumer<AppState>(
                          builder: (_, state, __) => ListView.separated(
                            itemCount: state.products.length,
                            separatorBuilder: (_, __) => Divider(),
                            itemBuilder: (context, idx) {
                              final p = state.products[idx];
                              return ListTile(
                                leading: Image.network(
                                  p.image,
                                  width: 56,
                                  height: 56,
                                  fit: BoxFit.cover,
                                ),
                                title: Text(p.name),
                                subtitle: Text(
                                  '₹${p.price.toStringAsFixed(0)} • ${p.category}',
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: Icon(Icons.edit),
                                      onPressed: () {},
                                    ),
                                    IconButton(
                                      icon: Icon(Icons.delete),
                                      onPressed: () {
                                        // demo: mark unavailable instead of deleting
                                        p.available = false;
                                        state.addProduct(p);
                                      },
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
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
    );
  }
}

/// Simple login page (stub)
class LoginPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Login (Demo)')),
      body: Center(
        child: Card(
          margin: EdgeInsets.all(24),
          child: Padding(
            padding: const EdgeInsets.all(18.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Login (demo)', style: TextStyle(fontSize: 18)),
                SizedBox(height: 12),
                TextField(decoration: InputDecoration(labelText: 'Email')),
                SizedBox(height: 8),
                TextField(
                  decoration: InputDecoration(labelText: 'Password'),
                  obscureText: true,
                ),
                SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text('Logged in (demo)')));
                    Navigator.pop(context);
                  },
                  child: Text('Login'),
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
