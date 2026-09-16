import 'package:go_router/go_router.dart';
import 'package:wardrobe/app/shell.dart';
import 'package:wardrobe/features/calendar/calendar_page.dart';
import 'package:wardrobe/features/outfits/outfit_category_page.dart';
import 'package:wardrobe/features/outfits/outfit_detail_page.dart';
import 'package:wardrobe/features/outfits/outfit_edit_page.dart';
import 'package:wardrobe/features/outfits/outfits_page.dart';
import 'package:wardrobe/features/wardrobe/category_items_page.dart';
import 'package:wardrobe/features/wardrobe/category_manage_page.dart';
import 'package:wardrobe/features/wardrobe/item_detail_page.dart';
import 'package:wardrobe/features/wardrobe/item_edit_page.dart';
import 'package:wardrobe/features/wardrobe/wardrobe_page.dart';

final appRouter = GoRouter(
  initialLocation: '/wardrobe',
  routes: [
    ShellRoute(
      builder: (context, state, child) => AppShell(child: child),
      routes: [
        GoRoute(
          path: '/wardrobe',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: WardrobePage(),
          ),
        ),
        GoRoute(
          path: '/wardrobe/categories',
          builder: (context, state) => const CategoryManagePage(),
        ),
        GoRoute(
          path: '/wardrobe/c/:categoryId',
          builder: (context, state) => CategoryItemsPage(
            categoryId: state.pathParameters['categoryId']!,
          ),
        ),
        GoRoute(
          path: '/wardrobe/item/new',
          builder: (context, state) => ItemEditPage(
            categoryId: state.uri.queryParameters['category'],
          ),
        ),
        GoRoute(
          path: '/wardrobe/item/:id/edit',
          builder: (context, state) => ItemEditPage(
            itemId: state.pathParameters['id'],
          ),
        ),
        GoRoute(
          path: '/wardrobe/item/:id',
          builder: (context, state) => ItemDetailPage(
            itemId: state.pathParameters['id']!,
          ),
        ),
        GoRoute(
          path: '/outfits',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: OutfitsPage(),
          ),
        ),
        GoRoute(
          path: '/outfits/c/:categoryId',
          builder: (context, state) => OutfitCategoryPage(
            categoryId: state.pathParameters['categoryId']!,
          ),
        ),
        GoRoute(
          path: '/outfits/item/new',
          builder: (context, state) => OutfitEditPage(
            categoryId: state.uri.queryParameters['category'],
          ),
        ),
        GoRoute(
          path: '/outfits/item/:id/edit',
          builder: (context, state) => OutfitEditPage(
            outfitId: state.pathParameters['id'],
          ),
        ),
        GoRoute(
          path: '/outfits/item/:id',
          builder: (context, state) => OutfitDetailPage(
            outfitId: state.pathParameters['id']!,
          ),
        ),
        GoRoute(
          path: '/calendar',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: CalendarPage(),
          ),
        ),
      ],
    ),
  ],
);
