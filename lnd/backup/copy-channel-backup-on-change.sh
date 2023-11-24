#!/bin/bash
while true; do
  inotifywait /home/lightning/.lnd/data/chain/bitcoin/mainnet/channel.backup
  cp /home/lightning/.lnd/data/chain/bitcoin/mainnet/channel.backup /mnt/backups/channel.backup
done
