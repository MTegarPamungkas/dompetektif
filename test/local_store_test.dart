import 'dart:io';

import 'package:dompetektif/data/datasources/local_store.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('clearUserData wipes case data but keeps device preferences', () async {
    final directory = await Directory.systemTemp.createTemp(
      'dompetektif_store_test_',
    );
    final store = LocalStore();
    addTearDown(() async {
      await store.close();
      if (await directory.exists()) {
        await directory.delete(recursive: true);
      }
    });

    await store.init(directory: directory.path, name: 'clear_user_data');
    await store.put('wallets', {'id': 'wallet-1', 'name': 'Dompet'});
    await store.put('transactions', {
      'id': 'tx-1',
      'wallet_id': 'wallet-1',
      'amount_minor': 1000,
    });
    await store.enqueueOutbox({
      'id': 'outbox-1',
      'table': 'wallets',
      'created_at': '2026-10-26T00:00:00.000Z',
    });
    await store.saveImage('receipt-1', [1, 2, 3]);
    await store.setMeta('sync_cursor_wallets', '2026-10-26T00:00:00.000Z');
    await store.setMeta('alert_sent_budget_1', '2026-10-26');
    await store.setMeta('seed_version', '2026-10-v1');
    await store.setMeta('demo_user', {'id': 'demo'});
    await store.setMeta('settings', {
      'theme_mode': 'dark',
      'locale': 'id',
      'biometric': true,
      'active_wallet_id': 'wallet-1',
    });

    await store.clearUserData();

    expect(store.all('wallets'), isEmpty);
    expect(store.all('transactions'), isEmpty);
    expect(store.outboxItems(), isEmpty);
    expect(store.loadImage('receipt-1'), isNull);
    expect(store.getMeta('sync_cursor_wallets'), isNull);
    expect(store.getMeta('alert_sent_budget_1'), isNull);
    expect(store.getMeta('seed_version'), isNull);
    expect(store.getMeta('demo_user'), isNull);

    final settings = store.getMeta('settings') as Map;
    expect(settings['theme_mode'], 'dark');
    expect(settings['locale'], 'id');
    expect(settings['biometric'], isTrue);
    expect(settings.containsKey('active_wallet_id'), isFalse);
  });
}
