#!/bin/sh

PATH_TO_SCRIPT=`dirname $0`;
POFOMD_PERL_LIB="$PATH_TO_SCRIPT/../../lib";
TMP_DIR="$PATH_TO_SCRIPT/../../tmp";
FILE="$TMP_DIR/DespesasDownload.zip";
[[ $1 ]] && YEAR=$1 || YEAR=`date +%Y`;

if [ -e $FILE ]; then
    rm $FILE
fi

wget -q --no-check-certificate -O $FILE \
     "https://www.fazenda.sp.gov.br/SigeoLei131/Paginas/DownloadReceitas.aspx?flag=2&ano=$YEAR";

# if it downloaded successfully
if [ $? -eq 0 ]; then
    unzip -d $TMP_DIR $FILE;
    DATASET=`ls $TMP_DIR/despesa*csv`;
    perl -I$POFOMD_PERL_LIB script/import/sp.pl --year $YEAR --dataset $DATASET > /dev/null 2>&1;
    rm $FILE;
    rm $DATASET;
fi
