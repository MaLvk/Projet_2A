#include "compteur.h"

extern int compteur[9];
extern int compteurLigne[3];
extern int compteurColonne[3];

void IncrementeCompteurLigne(int i){
	if(compteurLigne[i]==100){
		compteurLigne[i]=0;
	}else if(compteurLigne[i]<100){
		compteurLigne[i]++;
	}
}

void IncrementeCompteurColonne(int j){
	if(compteurColonne[j]==100){
		compteurColonne[j]=0;
	}else if(compteurColonne[j]<100){
		compteurColonne[j]++;
	}
}

void IncrementeCompteur(int k){
	if(compteur[k]==100){
		compteur[k]=0;
	}else if(compteur[k]<100){
		compteur[k]++;
	}
}