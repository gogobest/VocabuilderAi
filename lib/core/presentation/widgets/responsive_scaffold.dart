import 'package:flutter/material.dart';
import 'package:universal_platform/universal_platform.dart';
import 'package:go_router/go_router.dart';
import 'package:visual_vocabularies/core/constants/app_constants.dart';

/// A responsive scaffold that adapts its layout based on the platform and screen size
class ResponsiveScaffold extends StatelessWidget {
  final Widget body;
  final PreferredSizeWidget? appBar;
  final Widget? drawer;
  final Widget? endDrawer;
  final Widget? bottomNavigationBar;
  final Color? backgroundColor;
  final bool extendBody;
  final bool extendBodyBehindAppBar;
  final Widget? floatingActionButton;
  final FloatingActionButtonLocation? floatingActionButtonLocation;
  final String? title;
  final bool showBackButton;
  final VoidCallback? onBackPressed;
  final Future<bool> Function()? onWillPop;

  const ResponsiveScaffold({
    super.key,
    required this.body,
    this.appBar,
    this.drawer,
    this.endDrawer,
    this.bottomNavigationBar,
    this.backgroundColor,
    this.extendBody = false,
    this.extendBodyBehindAppBar = false,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
    this.title,
    this.showBackButton = true,
    this.onBackPressed,
    this.onWillPop,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveAppBar = title != null 
        ? AppBar(
            title: Text(title!),
            leading: showBackButton ? IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: onBackPressed ?? () {
                if (context.canPop()) {
                  context.pop();
                }
              },
            ) : null,
          )
        : appBar;
    Future<bool> defaultOnWillPop() async {
      if (GoRouter.of(context).canPop()) {
        context.pop();
      } else {
        context.push(AppConstants.homeRoute);
      }
      return false;
    }
    if (UniversalPlatform.isWeb) {
      return WillPopScope(
        onWillPop: onWillPop ?? defaultOnWillPop,
        child: Scaffold(
          appBar: effectiveAppBar,
          body: body,
          drawer: drawer,
          endDrawer: endDrawer,
          bottomNavigationBar: bottomNavigationBar,
          backgroundColor: backgroundColor,
          extendBody: extendBody,
          extendBodyBehindAppBar: extendBodyBehindAppBar,
          floatingActionButton: floatingActionButton,
          floatingActionButtonLocation: floatingActionButtonLocation,
        ),
      );
    } else {
      return WillPopScope(
        onWillPop: onWillPop ?? defaultOnWillPop,
        child: Scaffold(
          appBar: effectiveAppBar,
          body: body,
          drawer: drawer,
          endDrawer: endDrawer,
          bottomNavigationBar: bottomNavigationBar,
          backgroundColor: backgroundColor,
          extendBody: extendBody,
          extendBodyBehindAppBar: extendBodyBehindAppBar,
          floatingActionButton: floatingActionButton,
          floatingActionButtonLocation: floatingActionButtonLocation,
        ),
      );
    }
  }
} 