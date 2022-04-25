#include <magnet.h>

extern TIM_HandleTypeDef htim1;
extern TIM_HandleTypeDef htim2;
extern TIM_HandleTypeDef htim3;
extern TIM_HandleTypeDef htim5;
extern TIM_HandleTypeDef htim12;
//value of the frequencies detected
extern int Magnet1;
extern int Magnet2;
extern int Magnet3;
extern int Magnet4;
extern int Magnet5;
extern int Magnet6;
extern int Magnet7;
extern int Magnet8;
extern int Magnet9;
//value of the current pulse of the magnets
extern int PulseMagnet1;
extern int PulseMagnet2;
extern int PulseMagnet3;
extern int PulseMagnet4;
extern int PulseMagnet5;
extern int PulseMagnet6;
extern int PulseMagnet7;
extern int PulseMagnet8;
extern int PulseMagnet9;
extern int PulseTime;

extern int Figure; //the figure that has to be executed
/*
Arrangement 1 :
 0 = the ferroF is concentrated on the magnet 2 (D9) only
 1 = the ferroF goes up
 2 = the ferroF goes down
 3 = the ferroF goes to the right
 4 = the ferroF goes to the left
 Arrangement 2 :
 5 = the ferroF does a square
 Free Arrangement :
 6 = react to the dB detected by the mic
 */

extern int PreviousFigure;//indicate the previous figure executed
extern int StepFig; //indicates the current step of the figure depending the MaxStepFigX
extern int EnableChangeFig ; //indicate if the Figure can change

void SetPulse(int indice_aimant, int rapport_cyclique){ //rapport_cyclique en pourcentage
	if(PulseTime==0){
		switch(indice_aimant){
		case 1 : htim1.Instance->CCR1=rapport_cyclique;PulseMagnet1=rapport_cyclique;break;
		case 2 : htim2.Instance->CCR1=rapport_cyclique;PulseMagnet2=rapport_cyclique;break;
		case 3 : htim3.Instance->CCR1=rapport_cyclique;PulseMagnet3=rapport_cyclique;break;
		case 4 : htim5.Instance->CCR4=rapport_cyclique;PulseMagnet4=rapport_cyclique;break;
		default : htim12.Instance->CCR1=rapport_cyclique;PulseMagnet5=rapport_cyclique;break;
		}
	}
}

void ChangePulseTime(){ //allow to change the pulse only if equal to 0
	if(PulseTime==MaxPulseTime){
		PulseTime=0;
	}else{
		PulseTime++;
	}
}

void ChangeFigure(int x){
	if(EnableChangeFig){
		StepFig=0;
		PreviousFigure=Figure;
		Figure=x;
	}
}

void ChangeEnable(){
	int MaxStepFig;
	switch(Figure){
	case 0 : MaxStepFig = MaxStepFig0; break;
	case 1 : MaxStepFig = MaxStepFig1; break;
	case 2 : MaxStepFig = MaxStepFig2; break;
	case 3 : MaxStepFig = MaxStepFig3; break;
	case 4 : MaxStepFig = MaxStepFig4; break;
	case 6 : MaxStepFig = MaxStepFig6; break;
	default : MaxStepFig = MaxStepFig5; break; //on met 5 en default car c'est le MaxStepFig le plus grand
	}
	if(StepFig>MaxStepFig){
		EnableChangeFig=1;
		StepFig=0;
	}else{
		EnableChangeFig=0;
	}
}

void Figure0(){ //the ferroF is concentrated on the magnet 2 (D9) only
	if(StepFig==0){ //all the magnets are at 100%
		SetPulse(1,100);
		SetPulse(2,100);
		SetPulse(3,100);
		SetPulse(4,100);
		SetPulse(5,100);
		StepFig++;
	}else if(StepFig != MaxStepFig0){
		SetPulse(2,100);
		SetPulse(1,PulseMagnet1-25);
		SetPulse(3,PulseMagnet3-25);
		SetPulse(4,PulseMagnet4-25);
		SetPulse(5,PulseMagnet5-25);
		StepFig++;
	}else{ //only Magnet2 (D9) is magnetic
		SetPulse(2,100);
		SetPulse(1,0);
		SetPulse(3,0);
		SetPulse(4,0);
		SetPulse(5,0);
		StepFig++;
	}
}

void Figure1(){
	switch(StepFig){ //only Magnet3 (D3) is magnetic
	case 0 :
		SetPulse(3,100);
		SetPulse(1,0);
		SetPulse(2,0);
		SetPulse(4,0);
		SetPulse(5,0);
		StepFig++;
		break;
	case 1 :
		SetPulse(1,100);
		SetPulse(2,100);
		SetPulse(3,75);
		StepFig++;
		break;
	case 2 :
		SetPulse(1,100);
		SetPulse(2,75);
		SetPulse(3,50);
		StepFig++;
		break;
	case 3 :
		SetPulse(1,100);
		SetPulse(2,50);
		SetPulse(3,25);
		StepFig++;
		break;
	case 4 :
		SetPulse(1,100);
		SetPulse(2,25);
		SetPulse(3,0);
		StepFig++;
		break;
	default : //only Magnet1 (D10) is magnetic
		SetPulse(1,100);
		SetPulse(2,0);
		SetPulse(3,0);
		StepFig++;
		break;
	}
}


void Figure2(){
	switch(StepFig){ //only Magnet1 (D10) is magnetic
	case 0 :
		SetPulse(1,100);
		SetPulse(2,0);
		SetPulse(3,0);
		SetPulse(4,0);
		SetPulse(5,0);
		StepFig++;
		break;
	case 1 :
		SetPulse(1,75);
		SetPulse(2,100);
		SetPulse(3,100);
		StepFig++;
		break;
	case 2 :
		SetPulse(1,50);
		SetPulse(2,75);
		SetPulse(3,100);
		StepFig++;
		break;
	case 3 :
		SetPulse(1,25);
		SetPulse(2,50);
		SetPulse(3,100);
		StepFig++;
		break;
	case 4 :
		SetPulse(1,0);
		SetPulse(2,25);
		SetPulse(3,100);
		StepFig++;
		break;
	default : //only Magnet3 (D3) is magnetic
		SetPulse(1,0);
		SetPulse(2,0);
		SetPulse(3,100);
		StepFig++;
		break;
	}
}

void Figure3(){
	switch(StepFig){ //only Magnet5 (D5) is magnetic
	case 0 :
		SetPulse(5,100);
		SetPulse(2,0);
		SetPulse(3,0);
		SetPulse(4,0);
		SetPulse(1,0);
		StepFig++;
		break;
	case 1 :
		SetPulse(5,75);
		SetPulse(2,100);
		SetPulse(4,100);
		StepFig++;
		break;
	case 2 :
		SetPulse(5,50);
		SetPulse(2,75);
		SetPulse(4,100);
		StepFig++;
		break;
	case 3 :
		SetPulse(5,25);
		SetPulse(2,50);
		SetPulse(4,100);
		StepFig++;
		break;
	case 4 :
		SetPulse(5,0);
		SetPulse(2,25);
		SetPulse(4,100);
		StepFig++;
		break;
	default : //only Magnet4 (D6) is magnetic
		SetPulse(5,0);
		SetPulse(2,0);
		SetPulse(4,100);
		StepFig++;
		break;
	}
}

void Figure4(){
	switch(StepFig){ //only Magnet4 (D6) is magnetic
	case 0 :
		SetPulse(4,100);
		SetPulse(2,0);
		SetPulse(3,0);
		SetPulse(5,0);
		SetPulse(1,0);
		StepFig++;
		break;
	case 1 :
		SetPulse(4,75);
		SetPulse(2,100);
		SetPulse(5,100);
		StepFig++;
		break;
	case 2 :
		SetPulse(4,50);
		SetPulse(2,75);
		SetPulse(5,100);
		StepFig++;
		break;
	case 3 :
		SetPulse(4,25);
		SetPulse(2,50);
		SetPulse(5,100);
		StepFig++;
		break;
	case 4 :
		SetPulse(4,0);
		SetPulse(2,25);
		SetPulse(5,100);
		StepFig++;
		break;
	default : //only Magnet5 (D5) is magnetic
		SetPulse(4,0);
		SetPulse(2,0);
		SetPulse(5,100);
		StepFig++;
		break;
	}
}

void Figure5(){ //do a square between Magnet3 > Magnet 4 > Magnet1> Magnet5
	switch(StepFig){
	case 1 :
		SetPulse(3,75);
		SetPulse(4,100);
		StepFig++;
		break;
	case 2 :
		SetPulse(3,50);
		SetPulse(4,100);
		StepFig++;
		break;
	case 3 :
		SetPulse(3,25);
		SetPulse(4,100);
		StepFig++;
		break;
	case 4 :
		SetPulse(3,0);
		SetPulse(4,75);
		SetPulse(1,100);
		StepFig++;
		break;
	case 5 :
		SetPulse(4,50);
		SetPulse(1,100);
		StepFig++;
		break;
	case 6 :
		SetPulse(4,25);
		SetPulse(1,100);
		StepFig++;
		break;
	case 7 :
		SetPulse(4,0);
		SetPulse(1,75);
		SetPulse(5,100);
		StepFig++;
		break;
	case 8 :
		SetPulse(1,50);
		SetPulse(5,100);
		StepFig++;
		break;
	case 9 :
		SetPulse(1,25);
		SetPulse(5,100);
		StepFig++;
		break;
	case 10 :
		SetPulse(1,0);
		SetPulse(5,75);
		SetPulse(3,100);
		StepFig++;
		break;
	case 11 :
		SetPulse(5,50);
		SetPulse(3,100);
		StepFig++;
		break;
	case 12 :
		SetPulse(5,25);
		SetPulse(3,100);
		StepFig++;
		break;
	default : //only Magnet3 (D3) is magnetic
		SetPulse(3,100);
		SetPulse(4,0);
		SetPulse(1,0);
		SetPulse(5,0);
		StepFig++;
		break;
	}
}

void Figure6(){
	int move=0; //make the ferroF move if it is equal to 1. It is equal to 1 if MagnetX is above A.
	if(Magnet1>30){move=1;}
	else if(Magnet2>20){move=1;}
	else if(Magnet3>20){move=1;}
	else if(Magnet4>10){move=1;}
	else if(Magnet5>10){move=1;}
	else if(Magnet6>5){move=1;}
	else if(Magnet7>5){move=1;}
	else if(Magnet8>5){move=1;}
	else if(Magnet9>5){move=1;}
	else{move=0;}
	if(move==1){
		if(StepFig==0){
				SetPulse(1,100);
				SetPulse(2,100);
				SetPulse(3,100);
				SetPulse(4,100);
				SetPulse(5,100);
				StepFig++;
			}else{
				SetPulse(1,10);
				SetPulse(2,10);
				SetPulse(3,10);
				SetPulse(4,10);
				SetPulse(5,10);
				StepFig=0;
			}
	}else{
		SetPulse(1,10);
		SetPulse(2,10);
		SetPulse(3,10);
		SetPulse(4,10);
		SetPulse(5,10);
		StepFig++;
	}
}
