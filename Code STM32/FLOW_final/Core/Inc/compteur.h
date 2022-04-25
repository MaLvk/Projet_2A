#include "main.h"
#include "bsp/mpu.h"
#include "test.h"
#include "ui.h"
#include "bsp/disco_lcd.h"
#include "bsp/disco_base.h"
#include "bsp/disco_qspi.h"
#include "bsp/disco_sdram.h"
#include "bsp/disco_ts.h"
#include "bsp/disco_sai.h"
#include "stdio.h"
#include <audio.h>
#include "cmsis_os.h"
#include "fatfs.h"
#include "libjpeg.h"
#include "usb_host.h"

#define CompteurMAX = 100;

void IncrementeCompteurLigne(int i);
void IncrementeCompteurColonne(int j);
void IncrementeCompteur(int k);
