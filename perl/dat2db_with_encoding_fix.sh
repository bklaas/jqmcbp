#!/bin/bash
# XXX fix paths to make it more portable
IN_DIR=/data/jq_entries
FIX_DIR=${IN_DIR}/encoding_fixed
/usr/bin/env python /home/bklaas/jqmcbp/perl/badEncodingFixer.py $IN_DIR $FIX_DIR
/usr/bin/perl /home/bklaas/jqmcbp/perl/dat2db.pl $FIX_DIR man 2>> /data/dat2db.err 1>> /data/dat2db.out


