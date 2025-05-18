import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; 
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:device_preview/device_preview.dart';
import 'l10n/app_localizations.dart';
import 'screens/splash_screen.dart';

class LanguageProvider extends ChangeNotifier {
  Locale _locale = const Locale('fr', '');

  Locale get locale => _locale;

  void setLocale(Locale locale) {
    if (!AppLocalizations.supportedLocales.contains(locale)) return;
    _locale = locale;
    notifyListeners();
  }
}

final languageProvider = ChangeNotifierProvider((ref) => LanguageProvider());

void main() {
  runApp(
    DevicePreview(
      enabled: !kReleaseMode,
      builder: (context) => const ProviderScope(child: MyApp()),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(languageProvider).locale;
    final devicePreviewLocale = DevicePreview.locale(context);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      useInheritedMediaQuery: true, // Important pour DevicePreview
      locale: devicePreviewLocale ?? locale, // Priorité à DevicePreview
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      title: 'HMS App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      builder: (context, child) {
        // Combinez les builders de DevicePreview et votre Directionality
        final builtChild = DevicePreview.appBuilder(context, child);
        
        // Gère la direction du texte (RTL pour l'arabe)
        final l10n = AppLocalizations.of(context);
        return Directionality(
          textDirection: l10n.isRtl ? TextDirection.rtl : TextDirection.ltr,
          child: builtChild,
        );
      },
      home: const SplashScreen(),
    );
  }
}