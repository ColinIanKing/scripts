#!/bin/bash
password=$(echo $(date +%s)$RANDOM | md5sum | cut -c-32)
sig=$(echo $password | ecryptfs-add-passphrase | grep "\[" | cut -d[ -f2 | cut -c1-16)
mount -it ecryptfs /lower /upper -o passwd=$password,ecryptfs_unlink_sigs,ecryptfs_key_bytes=16,ecryptfs_cipher=aes,ecryptfs_sig=$sig,ecryptfs_fnek_sig=$sig
