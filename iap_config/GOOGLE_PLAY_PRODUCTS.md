# Google Play IAP — FormPocket

Package: `com.FormPocketMNG.FormPocket`

Remote config: `https://api2.blwsmartware.net/N295.json`  
If JSON field `disable` is `1`, hide Google Play purchase popups. Shop stays open for coin unlocks.

## Consumable coin packs (buy many times)

| Product ID | Coins |
| --- | --- |
| `fp_pack_1` | 50 |
| `fp_pack_2` | 100 |
| `fp_pack_3` | 200 |
| `fp_pack_4` | 350 |
| `fp_pack_5` | 500 |
| `fp_pack_6` | 750 |
| `fp_pack_7` | 1000 |
| `fp_pack_8` | 1500 |
| `fp_pack_9` | 2200 |
| `fp_pack_10` | 3000 |

## One-time

| Product ID | Unlock |
| --- | --- |
| `fp_remove_ads` | Hide the banner |
| `fp_pro` | More profiles and templates |

Create these IDs in Play Console → Monetize → In-app products. Coin packs must be **consumable**. Remove ads and Pro must be **non-consumable**.
