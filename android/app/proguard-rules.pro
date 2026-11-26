# Hyprwise ProGuard / R8 Keep Rules

# Keep Android AppWidget Providers
-keep class com.hypr.hyprwise.ShiftWidgetProvider { *; }
-keep class com.hypr.hyprwise.QuickActionsWidgetProvider { *; }
-keep class com.hypr.hyprwise.HyprAiWidgetProvider { *; }

# Keep flutter_local_notifications receivers & models
-keep class com.dexterous.flutterlocalnotifications.** { *; }

# Keep home_widget plugin classes
-keep class es.antonborri.home_widget.** { *; }

# Keep Google Play Billing & RevenueCat classes
-keep class com.revenuecat.purchases.** { *; }
-keep class com.android.billingclient.** { *; }
