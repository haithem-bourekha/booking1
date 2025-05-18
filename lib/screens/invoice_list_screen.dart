import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../l10n/app_localizations.dart';
import '../main.dart';
import '../models/invoice.dart';
import '../services/invoice_service.dart';
import '../services/api_service.dart';
import '../widgets/invoice_card.dart';

class InvoiceListScreen extends ConsumerWidget {
  const InvoiceListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final invoiceService = InvoiceService(ApiService());
    final l10n = AppLocalizations.of(context);
    final language = ref.watch(languageProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.translate('invoices')),
        actions: [
          DropdownButton<Locale>(
            value: language.locale,
            isExpanded: false,
            items: AppLocalizations.supportedLocales.map((locale) {
              return DropdownMenuItem<Locale>(
                value: locale,
                child: Text(l10n.translate('language_${locale.languageCode}')),
              );
            }).toList(),
            onChanged: (Locale? newLocale) {
              if (newLocale != null) {
                ref.read(languageProvider.notifier).setLocale(newLocale);
              }
            },
          ),
        ],
      ),
      body: FutureBuilder<List<Invoice>>(
        future: invoiceService.getInvoices(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text(l10n.translate('error', params: {'error': snapshot.error.toString()})));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text(l10n.translate('no_invoices_found')));
          }
          return ListView.builder(
            itemCount: snapshot.data!.length,
            itemBuilder: (context, index) {
              return InvoiceCard(invoice: snapshot.data![index]);
            },
          );
        },
      ),
    );
  }
}