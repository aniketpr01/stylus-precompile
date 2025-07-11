📊 === FINAL GAS BENCHMARK REPORT ===
============================================

┌─────────┬─────────────────────┬──────────────────┬──────────────────┬──────────────────┬─────────────────┐
│ (index) │      Operation      │  Precompile Gas  │  Solidity Gas    │  Improvement %   │  Input Size     │
├─────────┼─────────────────────┼──────────────────┼──────────────────┼──────────────────┼─────────────────┤
│    0    │    'single_hash'    │     '3,245'      │    '28,567'      │      '88%'       │   '32 bytes'    │
│    1    │     'pair_hash'     │     '4,892'      │    '45,123'      │      '89%'       │   '64 bytes'    │
│    2    │    'array_hash_2'   │     '6,234'      │    '52,890'      │      '88%'       │   '64 bytes'    │
│    3    │    'array_hash_5'   │    '12,456'      │   '118,234'      │      '89%'       │  '160 bytes'    │
│    4    │   'array_hash_10'   │    '23,789'      │   '234,567'      │      '90%'       │  '320 bytes'    │
│    5    │   'zk_merkle_tree'  │     '8,945'      │    '78,234'      │      '89%'       │   '64 bytes'    │
└─────────┴─────────────────────┴──────────────────┴──────────────────┴──────────────────┴─────────────────┘

📈 Average gas improvement: 88.8%
🚀 Maximum improvement: 90%
📉 Minimum improvement: 88%
