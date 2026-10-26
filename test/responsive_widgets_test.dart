import 'package:dompetektif/core/localization/app_localizations.dart';
import 'package:dompetektif/core/theme/app_theme.dart';
import 'package:dompetektif/core/widgets/app_surfaces.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

Widget harness(Widget child, {Locale locale = const Locale('id')}) {
  return MaterialApp(
    theme: AppTheme.darkTheme,
    locale: locale,
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    home: Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: child,
      ),
    ),
  );
}

void main() {
  testWidgets('DossierHeader keeps actions visible on a phone width', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      harness(
        DossierHeader(
          eyebrow: 'Tim Investigasi',
          title: 'Berkas Kasus Bersama',
          subtitle: 'Undang rekan, bagi TKP, dan simpan catatan investigasi di satu tempat.',
          trailing: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.person_add_alt_1_rounded, size: 16),
                label: const Text('Undang'),
              ),
              OutlinedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.group_add_outlined, size: 16),
                label: const Text('Gabung'),
              ),
            ],
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Berkas Kasus Bersama'), findsOneWidget);
    expect(find.text('Undang'), findsOneWidget);
    expect(find.text('Gabung'), findsOneWidget);
  });

  testWidgets('MetricTile scales long money values at narrow widths', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      harness(
        const SizedBox(
          width: 260,
          child: MetricTile(
            label: 'Total saldo',
            value: 'Rp 9.999.999.999',
            footnote: 'Semua TKP',
            icon: Icons.account_balance_wallet_outlined,
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Rp 9.999.999.999'), findsOneWidget);
  });
}
