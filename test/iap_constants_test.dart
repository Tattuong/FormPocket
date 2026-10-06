import 'package:flutter_test/flutter_test.dart';
import 'package:formpocket/core/constants/iap_constants.dart';
import 'package:formpocket/core/services/iap_config_service.dart';
import 'package:formpocket/models/shop_item.dart';

void main() {
  test('FormPocket IAP ids and N295 endpoint', () {
    expect(IapConstants.productPrefix, 'fp');
    expect(IapConstants.remoteConfigUrl,
        'https://api2.blwsmartware.net/N295.json');
    expect(IapConstants.coinPackIds.first, 'fp_pack_1');
    expect(IapConstants.coinPackIds.last, 'fp_pack_10');
    expect(IapConstants.coinPackIds, hasLength(10));
    expect(IapConstants.removeAdsProductId, 'fp_remove_ads');
    expect(IapConstants.proProductId, 'fp_pro');
    expect(IapConstants.allProductIds,
        containsAll([...IapConstants.coinPackIds, 'fp_remove_ads', 'fp_pro']));
    expect(IapConstants.coinsForProduct('fp_pack_5'), 500);
    expect(IapConstants.freeArchiveLimit, 8);
    expect(IapConstants.proArchiveLimit, 99);
  });

  test('disable=1 hides billing only', () {
    final off = IapRemoteConfig.fromJson({'disable': 1, 'name': 'FormPocket'});
    expect(off.billingDisabled, isTrue);
    final on = IapRemoteConfig.fromJson(
        {'disable': 0, 'name': 'FormPocket', 'code': 'FULL_IAP'});
    expect(on.billingDisabled, isFalse);
    expect(on.name, 'FormPocket');
  });

  test('shop catalog extras can be applied and reverted', () {
    expect(
        ShopCatalog.items.where((e) => e.id.startsWith('theme_')), isNotEmpty);
    expect(ShopCatalog.find(ShopCatalog.featPro), isNotNull);
    expect(ShopCatalog.find('remove_ads'), isNotNull);
    expect(ShopCatalog.find(ShopCatalog.featHint), isNotNull);
    expect(ShopCatalog.find(ShopCatalog.featSound), isNotNull);
    expect(ShopCatalog.isDefaultId(ShopCatalog.defaultThemeId), isTrue);
  });
}
