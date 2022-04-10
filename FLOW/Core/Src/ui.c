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

//extern

extern double inputLevelLavr;
extern double inputLevelRavr;
extern float FFTInput[];
extern float FFTOutput[];
extern float FFTOutputMag[];

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
	LCD_DrawString(0, 0, (uint8_t*) "SIA 2021 - RT AUDIO FX", CENTER_MODE, true);

	/* delay range */
	LCD_DrawRect(60,20,360,30);
	/* Init Vol, Delay, Feed */
	LCD_SetFont(&Font12);
	LCD_DrawString(428,15,(uint8_t *) "Volume", LEFT_MODE, true);
	LCD_DrawString(440,245,(uint8_t *) "50 ", LEFT_MODE, true);
	LCD_SetFillColor(LCD_COLOR_RED);
	LCD_FillRect(436,100+36,29,200-100);

	LCD_DrawString(LCD_SCREEN_WIDTH/2,60,(uint8_t *) "0 ms  ", LEFT_MODE, true);
	LCD_DrawString(200,60,(uint8_t *) "Delay", LEFT_MODE, true);
}

/*
 * Display All Params
 */
static void printDelay(uint32_t x){
	char delay_char[10];
	sprintf(delay_char, "%lu ms  ",x);
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
				int x = 60;
				int y = 20;
				int w = 360;
				int h = 30;

				/* If touch is in the delay bar */
				if(xt>x && xt<x+w && yt>y && yt<y+h){
					/* Position x into delay value in ms */
					delayMs=((xt-x)*10)/2;
					/* Display new delay value */
					printDelay((uint32_t) delayMs);

					/* RED Bar for level */
 					LCD_SetFillColor(LCD_COLOR_RED);
					LCD_FillRect(x+1,y+1,xt-x,h-1);
					/* WHITE Bar for update */
					LCD_SetFillColor(LCD_COLOR_WHITE);
					LCD_FillRect(xt,y+1,w+x-xt,h-1);
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
