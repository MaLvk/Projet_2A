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

#define MaxPulseTime 10
#define MaxStepFig0 4 //Number of steps to complete figure 0
#define MaxStepFig1 5 //Number of steps to complete figure 1
#define MaxStepFig2 5 //Number of steps to complete figure 2
#define MaxStepFig3 5 //Number of steps to complete figure 3
#define MaxStepFig4 5 //Number of steps to complete figure 4
#define MaxStepFig5 14 //Number of steps to complete figure 5
#define MaxStepFig6 2 //Number of steps to complete figure 6

void SetPulse(int indice_aimant, int rapport_cyclique);
void ChangePulseTime();
void ChangeFigure(int x);
void ChangeEnable();

void Figure0();
void Figure1();
void Figure2();
void Figure3();
void Figure4();
void Figure5();
void Figure6();
