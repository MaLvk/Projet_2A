/*
 * ui.c
 *
 *  Created on: Nov 21, 2021
 *      Author: sydxrey
 *
 *
 *      LCD and touchscreen management for project User Interface.
 */

#include <ui.h>
#include <math.h>
#include <audio.h>
#include <stdio.h>
#include <stdlib.h>
#include "bsp/disco_lcd.h"
#include "bsp/disco_ts.h"
#include "bsp/disco_base.h"
#include "arm_math.h"
#include "magnet.h"

//extern

extern double inputLevelLavr;
extern double inputLevelRavr;
extern float FFTInput[];
extern float FFTOutput[];
extern float FFTOutputMag[];
extern int Figure;
extern int PreviousFigure;//indicate the previous figure executed
extern int StepFig; //indicates the current step of the figure depending the MaxStepFigX
extern int EnableChangeFig ; //indicate if the Figure can change

#define FFTLength 256
int delayMs = 0;
int delayFeed = 0;
int volume = 50;
int time = 0;

/**
 * Display basic UI information.
 */
void uiDisplayBasic(void) {

	LCD_Clear(LCD_COLOR_WHITE);

	LCD_SetStrokeColor(LCD_COLOR_BLACK);
	LCD_SetBackColor(LCD_COLOR_WHITE);
	LCD_SetFont(&Font16);
	LCD_DrawString(0, 0, (uint8_t*) "FLOW", CENTER_MODE, true);

	/* delay range */
	//LCD_DrawRect(60,20,360,30);
	LCD_DrawRect(60,20,40,30);
	LCD_DrawRect(110,20,40,30);
	LCD_DrawRect(160,20,40,30);
	LCD_DrawRect(210,20,40,30);
	LCD_DrawRect(260,20,40,30);
	LCD_DrawRect(310,20,40,30);
	LCD_DrawRect(360,20,40,30);

	/* Init Vol, Delay, Feed */
	LCD_SetFont(&Font12);

	//LCD_DrawString(LCD_SCREEN_WIDTH,60,(uint8_t *) "0  ", LEFT_MODE, true);
	//LCD_DrawString(200,60,(uint8_t *) "Figure", LEFT_MODE, true);
	switch(Figure){
	case 0 : LCD_DrawString(200,60,(uint8_t *) "Figure 0", LEFT_MODE, true);break;
	case 1 : LCD_DrawString(200,60,(uint8_t *) "Figure 1", LEFT_MODE, true);break;
	case 2 : LCD_DrawString(200,60,(uint8_t *) "Figure 2", LEFT_MODE, true);break;
	case 3 : LCD_DrawString(200,60,(uint8_t *) "Figure 3", LEFT_MODE, true);break;
	case 4 : LCD_DrawString(200,60,(uint8_t *) "Figure 4", LEFT_MODE, true);break;
	case 5 : LCD_DrawString(200,60,(uint8_t *) "Figure 5", LEFT_MODE, true);break;
	case 6 : LCD_DrawString(200,60,(uint8_t *) "Figure 6", LEFT_MODE, true);break;
	}
}

/*
 * Display All Params
 */
static void printDelay(uint32_t x){
	char delay_char[10];
	//sprintf(delay_char, "%lu ms  ",x);
	sprintf(delay_char, " numero %lu ", Figure);
	uint16_t X = LCD_SCREEN_WIDTH/2;
	uint16_t Y = 60;
	LCD_DrawString(X,Y,(uint8_t *)delay_char, LEFT_MODE, true);
}

/*
 * Range for delay value
 */
void uiSliderDelay(){
	TS_StateTypeDef  TS_State;

	TS_GetState(&TS_State);

	/* detect touch event */
	if(TS_State.touchDetected){

				/* Get X and Y position of the touch post calibrated */
				uint16_t xt = TS_State.touchX[0];
				uint16_t yt = TS_State.touchY[0];
				/* Init position and size of elements */
				int xSquare0 = 60;
				int xSquare1 = 110;
				int xSquare2 = 160;
				int xSquare3 = 210;
				int xSquare4 = 260;
				int xSquare5 =310;
				int xSquare6 = 360;
				int y = 20;
				int w = 40;
				int h = 30;

				/* If touch is in the delay bar */
//				if(xt>x && xt<x+w && yt>y && yt<y+h){
					/* Position x into delay value in ms */
//					delayMs=((xt-x)*10)/2;
					/* Display new delay value */
//					printDelay((uint32_t) delayMs);

					/* RED Bar for level */
// 					LCD_SetFillColor(LCD_COLOR_RED);
//					LCD_FillRect(x+1,y+1,xt-x,h-1);
					/* WHITE Bar for update */
//					LCD_SetFillColor(LCD_COLOR_WHITE);
//					LCD_FillRect(xt,y+1,w+x-xt,h-1);
//				}
				ChangeEnable();
				if(EnableChangeFig){
					if(xt>xSquare0 && xt<xSquare0+w && yt>y && yt<y+h){
						ChangeFigure(0);
						if(Figure==0){
							LCD_SetFillColor(LCD_COLOR_RED);
							LCD_FillRect(xSquare0+1,y+1,w-1,h-1);
							LCD_SetFillColor(LCD_COLOR_WHITE);
							LCD_FillRect(xSquare1+1,y+1,w-1,h-1);
							LCD_FillRect(xSquare2+1,y+1,w-1,h-1);
							LCD_FillRect(xSquare3+1,y+1,w-1,h-1);
							LCD_FillRect(xSquare4+1,y+1,w-1,h-1);
							LCD_FillRect(xSquare5+1,y+1,w-1,h-1);
							LCD_FillRect(xSquare6+1,y+1,w-1,h-1);
						}

					}else if(xt>xSquare1 && xt<xSquare1+w && yt>y && yt<y+h){
						ChangeFigure(1);
						if(Figure==1){
							LCD_SetFillColor(LCD_COLOR_RED);
							LCD_FillRect(xSquare1+1,y+1,w-1,h-1);
							LCD_SetFillColor(LCD_COLOR_WHITE);
							LCD_FillRect(xSquare0+1,y+1,w-1,h-1);
							LCD_FillRect(xSquare2+1,y+1,w-1,h-1);
							LCD_FillRect(xSquare3+1,y+1,w-1,h-1);
							LCD_FillRect(xSquare4+1,y+1,w-1,h-1);
							LCD_FillRect(xSquare5+1,y+1,w-1,h-1);
							LCD_FillRect(xSquare6+1,y+1,w-1,h-1);
						}

					}else if(xt>xSquare2 && xt<xSquare2+w && yt>y && yt<y+h){
						ChangeFigure(2);
						if(Figure==2){
							LCD_SetFillColor(LCD_COLOR_RED);
							LCD_FillRect(xSquare2+1,y+1,w-1,h-1);
							LCD_SetFillColor(LCD_COLOR_WHITE);
							LCD_FillRect(xSquare0+1,y+1,w-1,h-1);
							LCD_FillRect(xSquare1+1,y+1,w-1,h-1);
							LCD_FillRect(xSquare3+1,y+1,w-1,h-1);
							LCD_FillRect(xSquare4+1,y+1,w-1,h-1);
							LCD_FillRect(xSquare5+1,y+1,w-1,h-1);
							LCD_FillRect(xSquare6+1,y+1,w-1,h-1);
						}

					}else if(xt>xSquare3 && xt<xSquare3+w && yt>y && yt<y+h){
						ChangeFigure(3);
						if(Figure==3){
							LCD_SetFillColor(LCD_COLOR_RED);
							LCD_FillRect(xSquare3+1,y+1,w-1,h-1);
							LCD_SetFillColor(LCD_COLOR_WHITE);
							LCD_FillRect(xSquare0+1,y+1,w-1,h-1);
							LCD_FillRect(xSquare2+1,y+1,w-1,h-1);
							LCD_FillRect(xSquare1+1,y+1,w-1,h-1);
							LCD_FillRect(xSquare4+1,y+1,w-1,h-1);
							LCD_FillRect(xSquare5+1,y+1,w-1,h-1);
							LCD_FillRect(xSquare6+1,y+1,w-1,h-1);
						}

					}else if(xt>xSquare4 && xt<xSquare4+w && yt>y && yt<y+h){
						ChangeFigure(4);
						if(Figure==4){
							LCD_SetFillColor(LCD_COLOR_RED);
							LCD_FillRect(xSquare4+1,y+1,w-1,h-1);
							LCD_SetFillColor(LCD_COLOR_WHITE);
							LCD_FillRect(xSquare0+1,y+1,w-1,h-1);
							LCD_FillRect(xSquare2+1,y+1,w-1,h-1);
							LCD_FillRect(xSquare3+1,y+1,w-1,h-1);
							LCD_FillRect(xSquare1+1,y+1,w-1,h-1);
							LCD_FillRect(xSquare5+1,y+1,w-1,h-1);
							LCD_FillRect(xSquare6+1,y+1,w-1,h-1);
						}

					}else if(xt>xSquare5 && xt<xSquare5+w && yt>y && yt<y+h){
						ChangeFigure(5);
						if(Figure==5){
							LCD_SetFillColor(LCD_COLOR_RED);
							LCD_FillRect(xSquare5+1,y+1,w-1,h-1);
							LCD_SetFillColor(LCD_COLOR_WHITE);
							LCD_FillRect(xSquare0+1,y+1,w-1,h-1);
							LCD_FillRect(xSquare2+1,y+1,w-1,h-1);
							LCD_FillRect(xSquare3+1,y+1,w-1,h-1);
							LCD_FillRect(xSquare4+1,y+1,w-1,h-1);
							LCD_FillRect(xSquare1+1,y+1,w-1,h-1);
							LCD_FillRect(xSquare6+1,y+1,w-1,h-1);
						}

					}else if(xt>xSquare6 && xt<xSquare6+w && yt>y && yt<y+h){
						ChangeFigure(6);
						if(Figure==6){
							LCD_SetFillColor(LCD_COLOR_RED);
							LCD_FillRect(xSquare6+1,y+1,w-1,h-1);
							LCD_SetFillColor(LCD_COLOR_WHITE);
							LCD_FillRect(xSquare0+1,y+1,w-1,h-1);
							LCD_FillRect(xSquare2+1,y+1,w-1,h-1);
							LCD_FillRect(xSquare3+1,y+1,w-1,h-1);
							LCD_FillRect(xSquare4+1,y+1,w-1,h-1);
							LCD_FillRect(xSquare5+1,y+1,w-1,h-1);
							LCD_FillRect(xSquare1+1,y+1,w-1,h-1);
						}

					}
				}
				switch(Figure){
				case 0 : LCD_DrawString(200,60,(uint8_t *) "Figure 0", LEFT_MODE, true);break;
				case 1 : LCD_DrawString(200,60,(uint8_t *) "Figure 1", LEFT_MODE, true);break;
				case 2 : LCD_DrawString(200,60,(uint8_t *) "Figure 2", LEFT_MODE, true);break;
				case 3 : LCD_DrawString(200,60,(uint8_t *) "Figure 3", LEFT_MODE, true);break;
				case 4 : LCD_DrawString(200,60,(uint8_t *) "Figure 4", LEFT_MODE, true);break;
				case 5 : LCD_DrawString(200,60,(uint8_t *) "Figure 5", LEFT_MODE, true);break;
				case 6 : LCD_DrawString(200,60,(uint8_t *) "Figure 6", LEFT_MODE, true);break;
				}


	}
}





uint32_t VAL;
void uiDisplaySpectrum() {
	/* sweep reset */
	if(time>360){
		time=0;
	}
	/* sweep init position */
	uint16_t x=time+60;
	uint16_t y=270;
	uint32_t color;

	/* run through mag values */
	for(int i=0;i<(256/2);i++){
		/* Amplitude of frequency "i" */
		VAL = (uint32_t) (FFTOutputMag[i]*255);
		color=(uint32_t) 4278190080+(VAL);

		/* shade of blue */
		LCD_DrawPixelColor(x,y-(i),(uint32_t) color);
		/* tracking bar */
		LCD_DrawPixelColor(x+1,y-(i),(uint32_t) (4278190080+16753920));
	}
	/* new sweep position */
	time=time+1;
}

/**
 * Displays Master VU level.
 */
