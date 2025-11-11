# BMC E-Commerce (Flutter + Firebase)

A modern, multi-role e-commerce starter (User, Seller, Admin) built with Flutter 3 (Material 3) and Firebase.

## Tech Stack
- Flutter 3.24+
- Riverpod 3
- GoRouter 17
- Firebase (Auth, Firestore, Storage, Messaging, Cloud Functions)

## Quick start

1) Install Flutter and Dart (3.24+). Verify:

```bash
flutter --version
```

2) Get packages:

```bash
cd bmc_ecommerce
flutter pub get
```

3) Configure Firebase with FlutterFire (creates `lib/firebase_options.dart`).

```bash
# Requires: dart pub global activate flutterfire_cli
flutterfire configure \
	--project=<your-firebase-project-id> \
	--platforms=android,ios,web,macos,windows
```

If prompted, accept defaults. This will generate `lib/firebase_options.dart`. Delete the placeholder file if needed.

4) Run the app:

```bash
flutter run
```

## Implemented (Milestone 1)
- Global Material 3 theme using the provided palette
- Firebase initialization (via `DefaultFirebaseOptions.currentPlatform`)
- Riverpod setup and GoRouter with role-based role redirects (User, Seller, Admin)
- Auth flow (email/password create + sign in)
- Core data models: `AppUser`, `Product`, `AppOrder`, `OrderItem`, `CartItem`, `ChatMessage`
- Services: product, cart, order, chat
- Providers: products, cart items, user orders, seller orders
- User experience:
	- Product grid with add-to-cart
	- Product detail page
	- Cart page with quantity adjust + checkout (simplified payment)
	- Orders list
	- Profile page with seller access request
- Seller experience:
	- Dashboard stats (static placeholders)
	- Manage products list
	- Create / edit product form (basic URL image field)
- Admin experience: dashboard stubs

## Data Model (Firestore Collections)
```
users/{userId} {
	email: string,
	displayName: string?,
	role: 'user' | 'seller' | 'admin',
	sellerRequested: bool,
	sellerApproved: bool,
	createdAt: timestamp
}
products/{productId} {
	sellerId: string,
	title: string,
	description: string,
	price: number,
	stock: number,
	imageUrls: string[],
	ratingAvg: number,
	ratingCount: number,
	active: bool,
	createdAt: timestamp
}
carts/{userId} {
	items: [{ productId, title, price, qty, imageUrl }]
}
orders/{orderId} {
	userId: string,
	sellerId: string,
	items: [{ productId, title, price, qty, imageUrl }],
	total: number,
	status: string,
	shippingAddress: string,
	createdAt: timestamp
}
messages/{messageId} {
	chatId: string, // sorted userId_sellerId composite
	fromId: string,
	toId: string,
	text: string,
	sentAt: timestamp
}
```

## Role-Based Routing
Upon authentication the router redirects:
- `user` -> `/user`
- `seller` -> `/seller`
- `admin` -> `/admin`

Additional nested routes enable product detail (`/product/:id`) and seller product management (`/seller/products/...`).

## Checkout (Simplified)
Checkout currently:
1. Reads cart items
2. Calculates total
3. Creates an `orders` document with status `paid`
4. Clears cart

This will later integrate payment gateways + multi-seller order splitting.

## Seller Access Workflow
- Users press "Request Seller Access" on profile; sets `sellerRequested=true`
- Admin tool (future) lists pending requests; approving sets `role='seller'` & `sellerApproved=true`

## Next Milestones
1. Image upload via Firebase Storage in Add/Edit product
2. Chat UI (user ↔ seller) with real-time updates
3. Admin: seller approvals & user management screens
4. Analytics: aggregate sales (Cloud Functions + charts)
5. Notifications: FCM topic/user-targeted messages (order status, chat)
6. Google & Phone auth providers
7. Robust error handling & empty states
8. Multi-seller cart splitting at checkout
9. Pagination & infinite scroll for products
10. Unit/widget tests for services & UI flows

## Seeding Dummy Data
You can manually add documents in Firestore or create a temporary seeding function calling `ProductService.create(...)`. (Future: a guarded admin-only seeding action.)

## Development Tips
- Run `flutter analyze` regularly
- Use hot reload for UI tweaks
- Keep logic in services/providers; keep widgets lean
- For complex mutations consider Cloud Functions (e.g., inventory decrement, order status transitions)

## Testing (Coming Soon)
Basic widget tests will be added under `test/` for product grid, cart operations, and checkout flow.

## Next steps
- Implement product models and listing with Firestore queries
- Cart and checkout flows
- Seller product CRUD and inventory
- Admin approvals and analytics
- Push notifications (FCM) and basic chat
- Firebase Functions for admin/analytics logic

## Notes
- The repository uses modern Flutter APIs. If you see deprecation messages, ensure your Flutter SDK is up to date.
- Authentication currently covers email/password. Google/phone sign-in can be added next.
