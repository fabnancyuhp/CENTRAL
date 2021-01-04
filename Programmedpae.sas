options mprint symbolgen notes;


%global RUN_REGLE;
/*
%include "&pgmpath./fmt/generation_formats.sas";
%let RUN_REGLE = Y ;
%let scenario_sk = 1 ;
%let scenario_weight_no= 1; 
%let FCM_RUNDATE = 27MARS2020:00:00:00;
%let moiscent = &FCM_RUNDATE;
*/

/*Création des variables de dates nécessaires dans le projet*/
/*%put %sysfunc(month(%sysfunc(datepart("&FCM_RUNDATE"dt))));*/
/* Conversion de l'invite au format date */
%let moicalcule = %sysfunc(datepart("&FCM_RUNDATE"dt));
/*%let moicalcule = %sysfunc(datepart("01DEC2018:00:00:00"dt));*/
%let moisrund = %sysfunc(month(&moicalcule));
%let annerund = %sysfunc(year(&moicalcule));

data pourdate;
mois=&moisrund;
annee=&annerund;
run;

/*aj out de programme : lorsque jenkins envoie mai, on doit faire  
le calcul sur les données de janvier (pour juin fevrier)*/

data pourdate;
set pourdate;
if mois<12 then do;mois=mois+1;end;
else if mois=12 then do;mois=1;annee=annee+1;end;
run;

data pourdate;
set pourdate;
format DtDeb ddmmyy10.;
if mois<6 then do; moism5 = 12-(5-mois);end;
if mois>5 then do; moism5 = mois-5;end;
anneem1 = annee-1;
if mois<6 then do; DtDeb = mdy(moism5,1,anneem1);end;
if mois>5 then do; DtDeb = mdy(moism5,1,annee);end;
run;

data _null_;
set pourdate;
call symput("DtDeb",DtDeb);
run;


/*%let DtDeb = %sysfunc(putn("&Date_Deb"D,ddmmyy10.));*/
/*%put Date_Deb : &Date_Deb;*/
%put DtDeb : &DtDeb;
%let mois = %sysfunc(month(&DtDeb));
%put mois : &mois;
%let annee = %sysfunc(year(&DtDeb));
%put annee : &annee;

/*Détermination des variables date relative à la période renseignée*/
/*date au format date*/
%let date_deb_M = %sysfunc(MDY(&mois,1,&annee));
%put date_deb_M : &date_deb_M;
/*date au format datetime*/
%let datetime_deb_M = %sysfunc(DHMS(&date_deb_M,0,0,0));
%put datetime_deb_M : &datetime_deb_M;

/*Détermination des variables fin du mois M d'observation*/
/*date au format date*/
%let date_fin_M = %sysfunc(intnx(month,&date_deb_M,0,end));
%put date_fin_M : &date_fin_M;
/*date au format datetime*/
%let datetime_fin_M = %sysfunc(DHMS(&date_fin_M,0,0,0));
%put datetime_fin_M : &datetime_fin_M;

/*Détermination des variables fin du mois M+1 d'observation*/
/*date au format date*/
%let date_fin_M1 = %sysfunc(intnx(month,&date_deb_M,1,end));
%put date_fin_M1 : &date_fin_M1;
/*date au format datetime*/
%let datetime_fin_M1 = %sysfunc(DHMS(&date_fin_M1,0,0,0));
%put datetime_fin_M1 : &datetime_fin_M1;

/*Détermination des variables fin du mois M+2 d'observation*/
/*date au format date*/
%let date_fin_M2 = %sysfunc(intnx(month,&date_deb_M,2,end));
%put date_fin_M2 : &date_fin_M2;
/*date au format datetime*/
%let datetime_fin_M2 = %sysfunc(DHMS(&date_fin_M2,0,0,0));
%put datetime_fin_M2 : &datetime_fin_M2;

/*Détermination des variables début du mois M+3 d'observation*/
/*date au format date*/
%let date_deb_M3 = %sysfunc(intnx(month,&date_deb_M,3,beginning));
%put date_deb_M3 : &date_deb_M3;
/*date au format datetime*/
%let datetime_deb_M3 = %sysfunc(DHMS(&date_deb_M3,0,0,0));
%put datetime_deb_M3 : &datetime_deb_M3;

/*Détermination des variables début du mois M+4 d'observation*/
/*date au format date*/
%let date_deb_M4 = %sysfunc(intnx(month,&date_deb_M,4,beginning));
%put date_deb_M4 : &date_deb_M4;
/*date au format datetime*/
%let datetime_deb_M4 = %sysfunc(DHMS(&date_deb_M4,0,0,0));
%put datetime_deb_M4 : &datetime_deb_M4;

/*Détermination des variables fin du mois M+4 d'observation*/
/*date au format date*/
%let date_fin_M4 = %sysfunc(intnx(month,&date_deb_M,4,end));
%put date_fin_M4 : &date_fin_M4;
/*date au format datetime*/
%let datetime_fin_M4 = %sysfunc(DHMS(&date_fin_M4,0,0,0));
%put datetime_fin_M4 : &datetime_fin_M4;

/*Accès librairie SISP
On a plus besoin dans l'incubateur
%dataware;*/


/*1- Détermination des DE inscrits en 123 entre le dernier jour de M et le dernier jours de M+2
sans interruption*/

%Macro ChargementEspaceEntreprise ;
		%if "&RUN_REGLE" = "Y" %then %do;

PROC SQL;
   CREATE TABLE USERLIB.DE_ENCOURS_1 AS 
   SELECT t1.TD_DTETRT, 
          t1.TN_IDTDE, 
          t1.DC_NUMPEC, 
          t1.DC_CAT, 
          t1.DD_DEFPEC, 
          t1.DD_DEFCSSPEC
      FROM NTZ_PRI.C_FHINS_INS_V t1
      WHERE t1.TD_DTEFINVAL = '1Jan2999:0:0:0'dt AND t1.DD_DEFPEC NOT = t1.DD_DEFCSSPEC
      AND t1.DD_DEFPEC <= &datetime_fin_M2
      AND t1.DD_DEFCSSPEC >= &datetime_fin_M;

       /*Récupération du dernier enregistrements par PEC (max date de traitement)*/

   CREATE TABLE USERLIB.DE_ENCOURS_2 AS 
   SELECT DISTINCT *
      FROM USERLIB.DE_ENCOURS_1 t1
      GROUP BY t1.TN_IDTDE, t1.DC_NUMPEC
      HAVING (MAX(t1.TD_DTETRT)) = t1.TD_DTETRT;
QUIT;

      /*Filtre catégorie 1,2,3 et calcul nombre de jours d'indemnisation*/
data USERLIB.DE_ENCOURS_3;
set USERLIB.DE_ENCOURS_2(where = (DC_CAT IN ('1','2','3')));
Jours = (min(datepart(DD_DEFCSSPEC),&date_deb_M3)-max(datepart(DD_DEFPEC),&date_fin_M));
run;
proc sort data=USERLIB.DE_ENCOURS_3;
by TN_IDTDE;
run;

      /*Récupération des identifiants nationaux et code ALE sur C_AMTRA_IDV_V, tri sur l'identifiant Opale*/
PROC SQL;
   CREATE TABLE USERLIB.IDV AS 
   SELECT DISTINCT 
          t1.TN_IDTFCT, 
          t1.DC_IDTIDVNAT,
		  t1.DC_CDEALEGEO
      FROM NTZ_PRI.C_AMTRA_IDV_V t1
      WHERE t1.TD_DTEFINVAL = '1Jan2999:0:0:0'dt
      ORDER BY t1.TN_IDTFCT;
 
    /* Fusion entre les DE en cours et le référentiel individu pour récupérer l'identifiant national*/

   CREATE TABLE USERLIB.DE_ENCOURS_4 AS 
   SELECT t1.TN_IDTDE, 
          t1.DC_NUMPEC, 
          t1.DC_CAT, 
          t1.DD_DEFPEC, 
          t1.DD_DEFCSSPEC, 
          t1.Jours, 
          t2.DC_IDTIDVNAT,
		  t2.DC_CDEALEGEO
      FROM USERLIB.DE_ENCOURS_3 t1 INNER JOIN USERLIB.IDV t2 ON (t1.TN_IDTDE = t2.TN_IDTFCT);
QUIT;
proc sort data=USERLIB.DE_ENCOURS_4;
by DC_IDTIDVNAT;
run;

    /*sélection du public avec 2 mois complets de 123*/
data USERLIB.DE_ENCOURS_M_Mplus2;
set USERLIB.DE_ENCOURS_4;
by DC_IDTIDVNAT;
retain jourstot;
if first.DC_IDTIDVNAT then jourstot=Jours;
else jourstot=jourstot+Jours;
if last.DC_IDTIDVNAT and Jourstot>= (&date_deb_M3 - &date_fin_M);
keep DC_IDTIDVNAT DC_CDEALEGEO jourstot;
run;

/*2- Sélection périodes activités réduites sur les mois M, M+1, M+2 et M+4*/
   
    /*On retient les périodes en heures (unité d'activité = 2) de travail :
- activités déclarées travail (type = 11),
- contrat de travail (type=9),
- Bulletin de salaire (type=7),
- Travail (type=4)*/

PROC SQL;
   CREATE TABLE USERLIB.DRV_PERIODEACTIVITEGAEC_1 AS 
   SELECT DISTINCT t1.DC_ASSEDIC_DE, 
          t1.KC_INDIVIDU_NATIONAL, 
          t1.DD_DATEDEBUTACTIVITE,  
          t1.DD_DATEFINACTIVITE, 
          t1.DC_TYPEPERIODEGAEC_ID, 
          t1.DN_QUANTITEACTIVITE, 
          t1.DC_UNITEACTIVITE_ID
      FROM NTZ_ECD.DRV_PERIODEACTIVITEGAEC_V t1
      WHERE ( t1.DC_TYPEPERIODEGAEC_ID in ('11','9','7','4') AND t1.DC_UNITEACTIVITE_ID = '2' AND t1.DN_QUANTITEACTIVITE NOT = 0 ) AND 
           (( t1.DD_DATEDEBUTACTIVITE >= &datetime_deb_M AND t1.DD_DATEFINACTIVITE <= &datetime_fin_M2) OR 
           (t1.DD_DATEDEBUTACTIVITE >= &datetime_deb_M4 AND t1.DD_DATEFINACTIVITE <= &datetime_fin_M4) );
QUIT;

    /*On retient que les périodes avec une date de début et une date de fin de périodes déclarées dans le même mois*/
data USERLIB.DRV_PERIODEACTIVITEGAEC_2;
set USERLIB.DRV_PERIODEACTIVITEGAEC_1;
MOISDEB = (year(datepart(DD_DATEDEBUTACTIVITE))*100+month(datepart(DD_DATEDEBUTACTIVITE)));
MOISFIN = (year(datepart(DD_DATEFINACTIVITE))*100+month(datepart(DD_DATEFINACTIVITE)));
run;
data USERLIB.DRV_PERIODEACTIVITEGAEC_2;
set USERLIB.DRV_PERIODEACTIVITEGAEC_2;
where MOISDEB = MOISFIN;
run;

    /* Calcul du nombre d'heures déclarées par identifiant national par type de période et par mois*/
PROC SQL;
   CREATE TABLE USERLIB.DRV_PERIODEACTIVITEGAEC_3 AS 
   SELECT t1.KC_INDIVIDU_NATIONAL, 
          t1.MOISDEB, 
          t1.MOISFIN,
          t1.DC_TYPEPERIODEGAEC_ID, 
          /* NBHEURE */
            (SUM(t1.DN_QUANTITEACTIVITE)) FORMAT=12.2 AS NBHEURE, 
          /* AR : C si > 78 heures, B sinon */
            (Case when (SUM(t1.DN_QUANTITEACTIVITE)) > 78 then "C" else "B" end) AS AR
      FROM USERLIB.DRV_PERIODEACTIVITEGAEC_2 t1
      GROUP BY t1.KC_INDIVIDU_NATIONAL, t1.MOISDEB, t1.MOISFIN, t1.DC_TYPEPERIODEGAEC_ID;

    /*Lorsqu'il y a des déclarations pour un même mois de différents de type, on conserve le type de période pour lequel le nombre d'heures d'activité est le plus grand*/
   CREATE TABLE USERLIB.DRV_PERIODEACTIVITEGAEC_4 AS 
   SELECT t1.KC_INDIVIDU_NATIONAL, 
          t1.MOISDEB, 
          t1.MOISFIN, 
          t1.DC_TYPEPERIODEGAEC_ID, 
          t1.NBHEURE, 
          t1.AR
      FROM USERLIB.DRV_PERIODEACTIVITEGAEC_3 t1
      GROUP BY t1.KC_INDIVIDU_NATIONAL, t1.MOISDEB, t1.MOISFIN
      HAVING (MAX(t1.NBHEURE)) = t1.NBHEURE;
QUIT;

    /* Mise en forme et tri de la table activité réduite finale*/
data USERLIB.AR;
set USERLIB.DRV_PERIODEACTIVITEGAEC_4;
rename KC_INDIVIDU_NATIONAL = DC_IDTIDVNAT;
rename MOISDEB = MOIS;
run;
data USERLIB.AR;
set USERLIB.AR;
keep DC_IDTIDVNAT MOIS AR;
run;
proc sort data=USERLIB.AR;
by DC_IDTIDVNAT;
run;

/*3- Récupération de l'activité réduite pour les DE en cours sur M, M+1 et M+2*/

    /*Fusion table DE en cours et activité réduite*/
data USERLIB.de_ar;
merge USERLIB.DE_ENCOURS_M_Mplus2(in=x) USERLIB.ar;
by DC_IDTIDVNAT;
if x;
run;

    /*application du filtre : Pas d'activité réduite sur M, M+1,M+2 et info activité réduite sur m+4*/
data USERLIB.de_sans_ar;
set USERLIB.de_ar;
by DC_IDTIDVNAT;
retain ar_m_m2 ar_mplus4;
if first.DC_IDTIDVNAT then do;
ar_m_m2='x';
ar_mplus4='A';
end;
if mois ne . 
and mois>=month(&date_fin_M)+100*year(&date_fin_M)
and mois<=month(&date_fin_M2)+100*year(&date_fin_M2)
then ar_m_m2=ar;
if mois=month(&date_fin_M4)+100*year(&date_fin_M4) 
then ar_mplus4=ar;
if last.DC_IDTIDVNAT and ar_m_m2='x';
keep DC_IDTIDVNAT DC_CDEALEGEO ar_mplus4;
run;

/*4- DE en cours en fin de mois M+4, cat 1,2,3*/

PROC SQL;
   CREATE TABLE USERLIB.DE_ENCOURS_M4_1 AS 
   SELECT t1.TD_DTETRT, 
          t1.TN_IDTDE, 
          t1.DC_NUMPEC, 
          t1.DC_CAT
      FROM NTZ_PRI.C_FHINS_INS_V t1
      WHERE t1.TD_DTEFINVAL = '1Jan2999:0:0:0'dt
      AND t1.DD_DEFPEC <= &datetime_fin_M4
      AND t1.DD_DEFCSSPEC >= &datetime_fin_M4
      AND t1.DD_DEFPEC NOT = t1.DD_DEFCSSPEC;

       /*Récupération du dernier enregistrements par PEC (max date de traitement)*/

   CREATE TABLE USERLIB.DE_ENCOURS_M4_2 AS 
   SELECT DISTINCT *
      FROM USERLIB.DE_ENCOURS_M4_1 t1
      GROUP BY t1.TN_IDTDE, t1.DC_NUMPEC
      HAVING (MAX(t1.TD_DTETRT)) = t1.TD_DTETRT;

    /* Fusion entre les DE en cours et le référentiel individu pour récupérer l'identifiant national*/

   CREATE TABLE USERLIB.DE_ENCOURS_M4_3 AS 
   SELECT t1.TN_IDTDE, 
          t1.DC_NUMPEC, 
          t1.DC_CAT, 
          t2.DC_IDTIDVNAT
      FROM USERLIB.DE_ENCOURS_M4_2 t1 INNER JOIN USERLIB.IDV t2 ON (t1.TN_IDTDE = t2.TN_IDTFCT);

    /*Prendre la PEC la plus grande pour chaque indentifiant national*/

	CREATE TABLE USERLIB.DE_ENCOURS_M4_4 AS 
	SELECT DISTINCT t1.DC_IDTIDVNAT,
           t1.DC_NUMPEC, 
           t1.DC_CAT
      FROM USERLIB.DE_ENCOURS_M4_3 t1
      GROUP BY t1.DC_IDTIDVNAT
      HAVING (MAX(t1.DC_NUMPEC)) = t1.DC_NUMPEC;

    /*Sélection distincte des identifiants nationaux tel que la catégorie d'inscription est 1,2,3)*/

	CREATE TABLE USERLIB.DE_ENCOURS_M4 AS 
    SELECT DISTINCT t1.DC_IDTIDVNAT
      FROM USERLIB.DE_ENCOURS_M4_4 t1
      WHERE t1.DC_CAT IN ('1','2','3');
QUIT;

/*5- Fusion des DE en cours sans activité réduite en fin de mois M, M+1, M+2 avec les DE en cours en fin de mois M+4*/

proc sort data= USERLIB.DE_ENCOURS_M4;
by DC_IDTIDVNAT;
run;

data USERLIB.de_avec_sit4;
merge USERLIB.de_sans_ar(in=x) USERLIB.DE_ENCOURS_M4(in=y);
by DC_IDTIDVNAT;
if x;
sit_mplus4='Absent ou D ou E';
if y then sit_mplus4=ar_mplus4;
keep DC_IDTIDVNAT DC_CDEALEGEO sit_mplus4;
run;

proc sort data=USERLIB.de_avec_sit4;
by DC_IDTIDVNAT;
run;

/*6- Extraction des DPAE durables du mois M pour des DE*/

PROC SQL;
   CREATE TABLE USERLIB.LISTE_DPAE AS 
   SELECT t1.DC_INDIVIDU_LOCAL, 
          t1.DC_INDIVIDU_NATIONAL, 
          t1.DC_NOM, 
          t1.DC_PRENOM, 
          t1.DC_NOMEPOUX, 
          t1.DC_SEXE, 
          t1.KD_DATENAISSANCE, 
          t1.DC_TYPECONTRAT_ID, 
          t1.KD_DATEEMBAUCHE, 
          t1.KC_SIRET, 
          t1.DC_EMPLOYEUR, 
          t1.DN_EMPLOYEUR, 
          t1.DC_NOMRAISONSOCIALE, 
          t1.DC_ADRESSE, 
          t1.DC_CODEPOSTAL, 
          t1.DC_LBLCOMMUNE, 
          t1.DC_CODEPAYS, 
          t1.DC_TELEPHONE, 
          t1.DC_NAF_ID 
      FROM NTZ_ECD.XDP_DPAE_V t1
      WHERE t1.KD_DATEEMBAUCHE >= &datetime_deb_M AND t1.KD_DATEEMBAUCHE <= &datetime_fin_M 
      AND t1.DC_INDIVIDU_LOCAL NOT = 'XXXXXXXXXXX' 
      AND (t1.DC_TYPECONTRAT_ID ='2' or (t1.DC_TYPECONTRAT_ID ='1' and (datepart(DD_DATEFINCDD) - datepart(KD_DATEEMBAUCHE) + 1) ge 179));
QUIT;
proc sort data = USERLIB.LISTE_DPAE;
by DC_INDIVIDU_NATIONAL DC_TYPECONTRAT_ID KD_DATEEMBAUCHE;
run;

    /* On ne conserve qu'une ligne par individu*/
data USERLIB.DE_AVEC_DPAE;
set USERLIB.LISTE_DPAE;
by DC_INDIVIDU_NATIONAL DC_TYPECONTRAT_ID KD_DATEEMBAUCHE;
if first.DC_INDIVIDU_NATIONAL;
run;

/*7- Fusion DPAE avec DE en cours sans activité réduite*/

proc sort data =  USERLIB.DE_AVEC_DPAE;
by DC_INDIVIDU_NATIONAL;
run;

data USERLIB.DE_AVEC_DPAE;
set USERLIB.DE_AVEC_DPAE;
rename DC_INDIVIDU_NATIONAL = DC_IDTIDVNAT;
length TYPCONT $22;
if DC_TYPECONTRAT_ID = "1" then TYPCONT="CDD de 6 mois et plus";
if DC_TYPECONTRAT_ID = "2" then TYPCONT="CDI";
run;

data USERLIB.DE_DPAE_SIT4;
merge USERLIB.de_avec_dpae(in=x) USERLIB.de_avec_sit4(in=y);
by DC_IDTIDVNAT;
if x and y;
run;

/*8- Récupération des montants d'indemnisation grâce au PJC*/

    /*Récupération des codes allocations FNA et du régime d'indemnisation associé à partir du référentiel REF_ALLOCATION*/
PROC SQL;
   CREATE TABLE USERLIB.REF_ALLOCATION_1 AS 
   SELECT DISTINCT 
		t1.DC_ALLOCATIONFNA, 
		t1.DC_REGIMEINDEMNISATION
      FROM NTZ_ECD.REF_ALLOCATION_V t1
      ORDER BY t1.DC_ALLOCATIONFNA;quit;

    
   proc sql;
   CREATE TABLE USERLIB.PJC_1 AS 
   SELECT t1.KC_INDIVIDU_LOCAL, 
          t1.KC_OUVERTUREDROIT_ID, 
          t1.KD_DATEDEBUTPJC, 
          t1.DD_DATEFINPJC, 
          t1.DD_DATEDERNIEREMODIFICATION, 
          t1.DC_TYPEDEPERIODEPJC_ID, 
          t1.DN_MNTJOURNALIERALLOCATION, 
          t1.DC_TYPEALLOCATIONFNA_ID
      FROM NTZ_ECD.DRV_PERIODEJUSTIFCONST_V t1
      WHERE t1.DD_DATEFINPJC >= &datetime_deb_M AND t1.DC_TYPEDEPERIODEPJC_ID = '1' AND t1.DN_MNTJOURNALIERALLOCATION 
           > 0;quit;

    
   proc sql;
   CREATE TABLE USERLIB._PJC_2 AS 
   SELECT t1.KC_INDIVIDU_LOCAL, 
          t1.KC_OUVERTUREDROIT_ID, 
          t1.KD_DATEDEBUTPJC,
          t1.DD_DATEFINPJC, 
          t1.DD_DATEDERNIEREMODIFICATION, 
          t1.DC_TYPEDEPERIODEPJC_ID, 
          t1.DN_MNTJOURNALIERALLOCATION, 
          t1.DC_TYPEALLOCATIONFNA_ID, 
          t2.DC_ALLOCATIONFNA, 
          t2.DC_REGIMEINDEMNISATION
      FROM USERLIB.PJC_1 t1 INNER JOIN USERLIB.REF_ALLOCATION_1 t2 
      ON (t1.DC_TYPEALLOCATIONFNA_ID = t2.DC_ALLOCATIONFNA);
      QUIT;
    
   proc sql;
   CREATE TABLE USERLIB.PJC_3 AS 
   SELECT t1.KC_INDIVIDU_LOCAL, 
          t1.KD_DATEDEBUTPJC, 
          t1.DD_DATEFINPJC, 
          t1.DC_TYPEDEPERIODEPJC_ID, 
          t1.DN_MNTJOURNALIERALLOCATION, 
          t1.DC_TYPEALLOCATIONFNA_ID, 
          t1.DC_ALLOCATIONFNA, 
          t1.DC_REGIMEINDEMNISATION, 
            (case when t1.DC_REGIMEINDEMNISATION = "Régime de solidarité" then "SOLIDARITE" else 
            t1.DC_REGIMEINDEMNISATION end) AS Alloc
      FROM USERLIB._PJC_2 t1
      WHERE t1.DC_REGIMEINDEMNISATION NOT IS MISSING;
      QUIT;
proc sort data=USERLIB.pjc_3;
by KC_INDIVIDU_LOCAL KD_DATEDEBUTPJC;
run;

    /* Calcul des montants Rac, Solidarité, Etat et Pôle emploi versés en M m+1 et m+2, 
    ainsi que du taux moyen et de la dernière date d'indemnisation précédent m+4*/
data USERLIB.recap_pjc;
set USERLIB.pjc_3;
by KC_INDIVIDU_LOCAL;

date0=&date_deb_M; /*1er jour du mois d'observation*/
deb=datepart(KD_DATEDEBUTPJC);
fin=datepart(DD_DATEFINPJC);
format derj_mp4 ddmmyy10.;

retain montant_rac_M montant_rac_mp1 montant_rac_mp2 montant_ass_M montant_ass_mp1 montant_ass_mp2
montant_pe_M montant_pe_mp1 montant_pe_mp2 montant_etat_M montant_etat_mp1 montant_etat_mp2
jours_m jours_mp1 jours_mp2 derj_mp4;

if first.KC_INDIVIDU_LOCAL then do;
montant_rac_M=0;montant_rac_mp1=0;montant_rac_mp2=0;montant_ass_M=0;montant_ass_mp1=0;montant_ass_mp2=0;
montant_pe_M=0; montant_pe_mp1=0; montant_pe_mp2=0; montant_etat_M=0; montant_etat_mp1=0; montant_etat_mp2=0;
jours_m=0;jours_mp1=0;jours_mp2=0;derj_mp4=fin;end;

/* calcul des jours payés et montants en M*/
if deb<=intnx("month",date0,0,"end") and fin>=intnx("month",date0,0,"beginning") then do;
j=min(intnx("month",date0,0,"end"),fin)-max(deb,intnx("month",date0,0,"beginning"))+1;
m=j*DN_MNTJOURNALIERALLOCATION;
if Alloc="RAC" then montant_rac_m=montant_rac_m+m;
else if Alloc="SOLIDARITE" then montant_ass_m=montant_ass_m+m;
else if Alloc="ETAT" then montant_etat_m=montant_etat_m+m;
else if Alloc="POLE EMPLOI" then montant_pe_m=montant_pe_m+m;
jours_m=jours_m+j;
end;

/* calcul des jours payés et montants en M+1*/
if deb<=intnx("month",date0,1,"end") and fin>=intnx("month",date0,1,"beginning") then do;
j=min(intnx("month",date0,1,"end"),fin)-max(deb,intnx("month",date0,1,"beginning"))+1;
m=j*DN_MNTJOURNALIERALLOCATION;
if Alloc="RAC" then montant_rac_mp1=montant_rac_mp1+m;
else if Alloc="SOLIDARITE" then montant_ass_mp1=montant_ass_mp1+m;
else if Alloc="ETAT" then montant_etat_mp1=montant_etat_mp1+m;
else if Alloc="POLE EMPLOI" then montant_pe_mp1=montant_pe_mp1+m;
jours_mp1=jours_mp1+j;
end;

/* calcul des jours payés et montants en M+2*/
if deb<=intnx("month",date0,2,"end") and fin>=intnx("month",date0,2,"beginning") then do;
j=min(intnx("month",date0,2,"end"),fin)-max(deb,intnx("month",date0,2,"beginning"))+1;
m=j*DN_MNTJOURNALIERALLOCATION;
if Alloc="RAC" then montant_rac_mp2=montant_rac_mp2+m;
else if Alloc="SOLIDARITE" then montant_ass_mp2=montant_ass_mp2+m;
else if Alloc="ETAT" then montant_etat_mp2=montant_etat_mp2+m;
else if Alloc="POLE EMPLOI" then montant_pe_mp2=montant_pe_mp2+m;
jours_mp2=jours_mp2+j;
end;

if deb<=intnx("month",date0,4,"end") then derj_mp4=min(fin,intnx("month",date0,4,"end"));

if last.KC_INDIVIDU_LOCAL then do;
jourstot=jours_m+jours_mp1+jours_mp2;
montant_ass_tot=montant_ass_m+montant_ass_mp1+montant_ass_mp2;
montant_rac_tot=montant_rac_m+montant_rac_mp1+montant_rac_mp2;
montant_pe_tot=montant_pe_m+montant_pe_mp1+montant_pe_mp2;
montant_etat_tot=montant_etat_m+montant_etat_mp1+montant_etat_mp2;
montant_tot=montant_ass_tot+montant_rac_tot+montant_pe_tot+montant_etat_tot;
if jourstot>0 then do;
taux=montant_tot/jourstot;
part_rac=montant_rac_tot/montant_tot;
end;
if jours_m>0 and jours_mp1>0 and jours_mp2>0 then output;
end;

keep KC_INDIVIDU_LOCAL montant_tot taux part_rac derj_mp4;
run;

/*9- Récupération des informations concernant les montants d'indemnisation  : Fusion DE_DPAE_SIT4 et Recap_PJC*/
data USERLIB.DE_DPAE_SIT4;
set USERLIB.DE_DPAE_SIT4;
rename DC_INDIVIDU_LOCAL = KC_INDIVIDU_LOCAL;
run;
proc sort data=USERLIB.DE_DPAE_SIT4;
by KC_INDIVIDU_LOCAL;
run;

proc sort data=USERLIB.RECAP_PJC;
by KC_INDIVIDU_LOCAL;
run;

data USERLIB.de_dpae_ind;
merge USERLIB.DE_DPAE_SIT4(in=x) USERLIB.recap_pjc(in=y);
by KC_INDIVIDU_LOCAL;
if x and y;
run;

/*On remonte les données NTZ_ECDDCO_INDIVIDU_V et NTZ_REF.INDIVIDUE */

PROC SQL;
   CREATE TABLE USERLIB.DE_DPAE AS 
   SELECT t1.KC_INDIVIDU_LOCAL, 
          t1.DC_IDTIDVNAT, 
          t1.DC_TYPECONTRAT_ID, 
          t1.KD_DATEEMBAUCHE, 
          t1.KC_SIRET, 
          t1.DC_EMPLOYEUR, 
          t1.DN_EMPLOYEUR, 
          t1.TYPCONT, 
          t1.DC_CDEALEGEO, 
          t1.sit_mplus4, 
          t1.derj_mp4, 
          t1.montant_tot, 
          t1.taux, 
          t1.part_rac
      FROM USERLIB.DE_DPAE_IND t1;
QUIT;



PROC SQL;
   CREATE TABLE USERLIB.REF_INDIVIDU_V AS 
   SELECT t1.TN_UNIK_KEY, 
          t1.TD_DATEFONCTIONNELLE, 
          t1.KC_INDIVIDU_NATIONAL, 
          t1.KN_INDIVIDU_NATIONAL, 
          t1.DC_INDIVIDU_LOCAL, 
          t1.DC_CDEALE_ID, 
          t1.DD_DATENAISSANCE, 
          t1.DD_DATEDECES, 
          t1.DC_CIVILITE_ID, 
          t1.DC_TYPENOMUSUEL_ID, 
          t1.DC_NOMPATRONYMIQUE, 
          t1.DC_PRENOM, 
          t1.DC_NOMCORRESPONDANCE, 
          t1.DC_PRENOMCORRESPONDANCE, 
          t1.DC_NIR, 
          t1.DC_CERTIFICATIONNIR_ID, 
          t1.DC_ORIGINENIR_ID, 
          t1.DC_SEXE_ID, 
          t1.DC_REGIMESECURITESOCIALE, 
          t1.DC_NATIONALITE_ID, 
          t1.DC_VOIE, 
          t1.DC_COMPLEMENTADRESSEDEST, 
          t1.DC_COMPLEMENTDISTRIBUTION, 
          t1.DC_CODEPOSTALLOCALITE, 
          t1.DC_COMMUNE_ID, 
          t1.DC_CODEPOSTAL, 
          t1.DC_PAYS_ID, 
          t1.DC_TELEPHONE1, 
          t1.DC_TELEPHONE2, 
          t1.DC_ADRESSEEMAIL, 
          t1.DC_CONSENTEMENT_MAIL_ID, 
          t1.DC_CONSENTEMENT_MAILINFO_ID, 
          t1.DC_CONSENTEMENT_SMS_ID, 
          t1.DC_ZUS_ID, 
          t1.DC_REFERENCEZUS_ID, 
          t1.DC_CUCS_ID, 
          t1.DC_REFERENCECUCS_ID, 
          t1.DC_IDCROLENONDE, 
          t1.DC_ETATDEMANDEURPRESTA, 
          t1.DC_VALIDITEMAIL_ID, 
          t1.DC_MOTIFPRESENCESI, 
          t1.DC_SITEINDIVIDU_ID, 
          t1.DC_STATUTNIR_ID, 
          t1.DC_CODEQPV_ID, 
          t1.DC_CODECONTRATVILLE_ID, 
          t1.DC_IDCRESIDENCEQPV_ID
      FROM NTZ_REFS.REF_INDIVIDU_V t1
	  group by t1.KC_INDIVIDU_NATIONAL
	  having max(t1.TD_DATEFONCTIONNELLE)=t1.TD_DATEFONCTIONNELLE;
QUIT;

PROC SQL;
CREATE TABLE USERLIB.DE_DPAE as select A.*,B.*
from 
USERLIB.DE_DPAE A left join USERLIB.REF_INDIVIDU_V B
ON A.DC_IDTIDVNAT = B.KC_INDIVIDU_NATIONAL;
quit;

PROC SQL;
   CREATE TABLE USERLIB.DCO_INDIVIDU_V AS 
   SELECT 
          t1.DATMAJ, 
          t1.OPRID, 
          t1.KN_INDIVIDU_NATIONAL, 
          t1.KC_INDIVIDU_NATIONAL, 
          t1.KD_DATEMODIFICATION, 
          t1.DC_CIVILITE_ID, 
          t1.DC_TYPENOMUSUEL_ID, 
          t1.DC_NOMPATRONYMIQUE, 
          t1.DC_NOMMARITAL, 
          t1.DC_NOMPSEUDONYMIQUE, 
          t1.DC_PRENOM, 
          t1.DC_SEXE_ID, 
          t1.DD_DATENAISSANCE, 
          t1.DD_DATEDECES, 
          t1.DC_NIR, 
          t1.DC_ORIGINENIR_ID, 
          t1.DC_NATIONALITE, 
          t1.DD_DATECREATION, 
          t1.DC_STATUTNIR_ID, 
          t1.DC_CERTIFICATIONNIR_ID, 
          t1.DD_DATEDECESCNAV, 
          t1.DC_REGIMESECURITESOCIALE, 
          t1.DC_NOMNAISSANCECNAV, 
          t1.DC_PRENOMNAISSANCECNAV, 
          t1.DC_NOMCORRESPONDANCE, 
          t1.DC_PRENOMCORRESPONDANCE
      FROM NTZ_ECD.DCO_INDIVIDU_V t1
	  where t1.KC_INDIVIDU_NATIONAL in (select DC_IDTIDVNAT from USERLIB.DE_DPAE)
	  group by t1.KC_INDIVIDU_NATIONAL
	  having max(t1.DATMAJ)=t1.DATMAJ;
QUIT;


PROC SQL;
CREATE TABLE USERLIB.DE_DPAE as select A.*,B.*
from 
USERLIB.DE_DPAE A left join USERLIB.DCO_INDIVIDU_V B
ON A.DC_IDTIDVNAT = B.KC_INDIVIDU_NATIONAL;
quit;

/*
data USERLIB.DE_DPAE;
set DE_DPAE;
run;
*/
data USERLIB.DE_DPAE;
set USERLIB.DE_DPAE;
run;
proc sql;
create table USERLIB.DE_DPAE as select t2.*,t1.DC_LBLNATIONALITE
from USERLIB.DE_DPAE t2 left join NTZ_ECD.REF_NATIONALITE_V t1
on t2.DC_NATIONALITE=t1.KC_NATIONALITE;
quit; 


	/*pour le compte en banque*/
PROC SQL;
	   CREATE TABLE USERLIB.DRV_COMPTEBENEF_V AS 
	   SELECT t1.NUMLOT, 
	          t1.NUMEVT, 
	          t1.DATMAJ, 
	          t1.OPRID, 
	          t1.DC_TYPEDOMICILIATION_ID, 
	          t1.DC_ASSEDIC_DE, 
	          t1.KC_INDIVIDU_LOCAL, 
	          t1.KD_DATEMODIFICATION, 
	          t1.DD_DATEDEBUTDOMICILIATION, 
	          t1.DD_DATEFINDOMICILIATION, 
	          t1.DC_BIC, 
	          t1.DC_IBAN, 
	          t1.DC_ETABLISSEMENTFINANCIER, 
	          t1.DC_GUICHET, 
	          t1.DC_NUMEROCOMPTE, 
	          t1.DC_CLERIB, 
	          t1.DC_NUMEROCOMPTEETRANGER, 
	          t1.DC_PAYSBANQUEETRANGER, 
	          t1.DC_NUMEROTIERSBENEFICIAIRE, 
	          t1.DD_DATEDERNIEREMODIF, 
	          t1.DC_AGENTSAISIE, 
	          t1.KC_IDTCOMPTEBENEFICIAIRE, 
	          t1.DC_PROCURATIONSIMPLE, 
	          t1.DD_DATESIGNATUREPROCSIMPLE
	      FROM NTZ_ECD.DRV_COMPTEBENEF_V t1
		  WHERE t1.KC_INDIVIDU_LOCAL IN (select KC_INDIVIDU_LOCAL from USERLIB.DE_DPAE)
		  group by t1.KC_INDIVIDU_LOCAL
		  having max(t1.DATMAJ)=t1.DATMAJ;
	QUIT;

proc sql;
	create table USERLIB.DRV_COMPTEBENEF_V as select t1.*
	from USERLIB.DRV_COMPTEBENEF_V t1
	group by t1.KC_INDIVIDU_LOCAL
	having max(t1.DD_DATEDEBUTDOMICILIATION)=t1.DD_DATEDEBUTDOMICILIATION;
	quit;

proc sql;
	create table USERLIB.DE_DPAE as select t2.*,t1.*
	from USERLIB.DE_DPAE t2 left join USERLIB.DRV_COMPTEBENEF_V t1
	on t2.KC_INDIVIDU_LOCAL=t1.KC_INDIVIDU_LOCAL;
	quit; 
/*
data USERLIB.DE_DPAE;
set DE_DPAE;
run;*/
/*pays de naissance*/

Proc sql;
	create table USERLIB.DCO_ECHANGESCNAV_V as select t1.*
	from NTZ_ECD.DCO_ECHANGESCNAV_V t1
	where t1.KC_INDIVIDU_NATIONAL in (select DC_IDTIDVNAT from USERLIB.DE_DPAE)
	group by t1.KC_INDIVIDU_NATIONAL
	having max(t1.DATMAJ)=t1.DATMAJ;
	quit;

	proc sql;
	create table USERLIB.DE_DPAE as select t2.*,
	t1.DC_DEPARTEMENT_NAISSENVOYE_ID,  t1.DC_COMMUNE_NAISSANCEENVOYE_ID,
	t1.DC_LBLCOMMUNENAISSANCEENVOYE, t1.DC_PAYS_NAISSANCEENVOYE_ID,
	t1.DC_NOMNAISSANCERECU, t1.DC_PRENOMRECU, t1.DC_NOMMARITALRECU,
	t1.DC_DEPARTEMENT_NAISSRECU_ID, t1.DC_COMMUNE_NAISSANCERECU_ID,
	t1.DC_LBLCOMMUNENAISSANCERECU, t1.DC_PAYS_NAISSANCERECU_ID
	from USERLIB.DE_DPAE t2 left join USERLIB.DCO_ECHANGESCNAV_V t1
	on t2.DC_IDTIDVNAT=t1.KC_INDIVIDU_NATIONAL;
	quit;

	proc sql;
	create table USERLIB.DE_DPAE as select t2.*,t1.DC_LBLPAYS
	from USERLIB.DE_DPAE t2 left join NTZ_ECD.REF_PAYS_V t1
	on t2.DC_PAYS_NAISSANCEENVOYE_ID = t1.KC_PAYS;
	quit;

	proc sql;
	create table USERLIB.DE_DPAE as select t2.*,t1.DC_LBLPAYS as DC_LBLPAYSBIS
	from USERLIB.DE_DPAE t2 left join NTZ_ECD.REF_PAYS_V t1
	on t2.DC_PAYS_NAISSANCERECU_ID = t1.KC_PAYS;
	quit;


/*etablissement*/











%Let netezza_srv=netezza.sip91.pole-emploi.intra;
LIBNAME MALIB netezza server="&netezza_srv." port=5480 user=POPALE00_SAS_FRAUDE password=VHkL2Hx9
	db=POPALE_SAS_SASUSER bulkunload=yes;
Libname ntz_ecd netezza server="&netezza_srv." port=5480 user=POPALE00_SAS_FRAUDE password=VHkL2Hx9 db=POPALE_ECD bulkunload=YES;

PROC SQL;
	connect to netezza (&connection_to_ntz. db=POPALE_SAS_SASUSER);
	create table USERLIB.EGC_ETABLISSEMENT_V  as select *  from connection to netezza (
		SELECT t1.*
		FROM
			POPALE_ECD..EGC_ETABLISSEMENT_V t1
		WHERE EXTRACT(YEAR FROM t1.DATMAJ)>=2017);
	disconnect from netezza; 
Quit;



PROC SQL;
	   CREATE TABLE USERLIB.EGC_ETABLISSEMENT_V AS 
	   SELECT t1.NUMLOT, 
	          t1.NUMEVT, 
	          t1.DATMAJ, 
	          t1.OPRID, 
	          t1.DC_CODEFLUX, 
	          t1.KC_ETABLISSEMENT, 
	          t1.KN_ETABLISSEMENT, 
	          t1.KC_ENTREPRISE, 
	          t1.KN_ENTREPRISE, 
	          t1.DC_SIRETETABLISSEMENT, 
	          t1.DC_ENSEIGNE, 
	          t1.DD_DATECREATION, 
	          t1.DD_DATECESSATION, 
	          t1.DC_ORIGINECREATIONETAB, 
	          t1.DD_DATEDERNIEREMAJ, 
	          t1.DC_NAFREV2_ID, 
	          t1.DC_LIBACHEMINEMENTPOSTAL, 
	          t1.DC_COMPLEMENTADRESSE, 
	          t1.DC_NUMERODANSVOIE, 
	          t1.DC_TYPEVOIE, 
	          t1.DC_LIBNOMRUE, 
	          t1.DC_LIBDISTRIBSPECIFIQUE, 
	          t1.DC_CODEPOSTAL as DC_CODEPOSTALENT, 
	          t1.DC_COMMUNE_ETABLISSEMENT_ID, 
	          t1.DC_LIBCOMMUNE as DC_LIBCOMMUNEENT, 
	          t1.DC_COMPLEMENTADRESSE2, 
	          t1.DC_PAYS_ID, 
	          t1.DC_ADRESSEMAILETABLISSEMENT, 
	          t1.DC_REGION_ID as DC_REGION_IDENT, 
	          t1.DN_STATUTETABLISSEMENT, 
	          t1.DC_TRANCHEEFFECTIF_ID, 
	          t1.DN_EFFECTIFREELENTREPRISE, 
	          t1.DC_SAISONNALITE, 
	          t1.DC_ETABLISSEMENTZFU, 
	          t1.DC_INSERTIONECONOMIQUE_ID, 
	          t1.DC_SITEWEBETABLISSEMENT, 
	          t1.DC_IDCDIFFICULTEECONOMIQUE_ID, 
	          t1.DD_DATEDERNIEREMAJIDCDIFFECO, 
	          t1.DC_NUMEROTELEPHONE1, 
	          t1.DC_NUMEROTELEPHONE2, 
	          t1.DC_NUMEROFAX, 
	          t1.DC_CEDEX, 
	          t1.DC_NUMEROMSA, 
	          t1.DC_NUMEROURSSAF, 
	          t1.DC_MOTIFCESSATIONACTIVITE_ID, 
	          t1.DC_SSMOTIFCESSATIONACTIVITE_ID, 
	          t1.DC_IDCSIEGESOCIALFISSO, 
	          t1.DC_TYPEETABLISSEMENT_ID, 
	          t1.DC_ACTIVITESECONDAIRENIVEAU2, 
	          t1.DC_ACTIVITEARTISANALENIVEAU2, 
	          t1.DC_CODENPAI, 
	          t1.DC_IDCCONSENTEMENTMAIL, 
	          t1.DC_TYPEETABLISSEMENTRCE_ID, 
	          t1.DC_ROLEETABLISSEMENTORGFOR, 
	          t1.DC_ROLEETABLISSEMENTPART, 
	          t1.DC_ROLEETABLISSEMENTSIAE, 
	          t1.DC_ROLEPMSMP, 
	          t1.DC_ROLEDEMANDEURDAFFILIATION, 
	          t1.DC_ROLEREPRESENTANTDAFFILIE, 
	          t1.DC_ROLETIERSDECORRESPONDANCE, 
	          t1.DC_ROLEDEMANDEURPRESTATION, 
	          t1.DC_ROLESALARIEEXPATRIE, 
	          t1.DC_ROLECAISSEDERETRAITE, 
	          t1.DC_ROLESALARIE, 
	          t1.DC_ROLEETT, 
	          t1.DC_ROLEMANDATAIRESOCIAL, 
	          t1.DC_ROLEMANDATAIREDEJUSTICE, 
	          t1.DC_ROLEADMINISTRATEURRECRUTEUR, 
	          t1.KD_DATEMODIFICATION
	      FROM USERLIB.EGC_ETABLISSEMENT_V t1
		  where t1.KC_ETABLISSEMENT in (select DC_EMPLOYEUR from USERLIB.DE_DPAE)
		  /*or t1.DC_SIRETETABLISSEMENT in (select KC_SIRET from DE_DPAE)*/
		  group by t1.KC_ETABLISSEMENT
		  having(t1.DATMAJ) = max(t1.DATMAJ);
	QUIT;
proc sql;
create table USERLIB.DE_DPAE as select A.*,B.*
from USERLIB.DE_DPAE A left join USERLIB.EGC_ETABLISSEMENT_V B
ON A.DC_EMPLOYEUR=B.KC_ETABLISSEMENT;
quit;


proc sql;
CREATE TABLE USERLIB.PJC_1 AS 
   SELECT t1.KC_INDIVIDU_LOCAL, 
          t1.KC_OUVERTUREDROIT_ID, 
          t1.KD_DATEDEBUTPJC, 
          t1.DD_DATEFINPJC, 
          t1.DD_DATEDERNIEREMODIFICATION, 
          t1.DC_TYPEDEPERIODEPJC_ID, 
          t1.DN_MNTJOURNALIERALLOCATION, 
          t1.DC_TYPEALLOCATIONFNA_ID
      FROM NTZ_ECD.DRV_PERIODEJUSTIFCONST_V t1
      WHERE t1.DD_DATEFINPJC >= &datetime_deb_M AND t1.DC_TYPEDEPERIODEPJC_ID = '1' AND t1.DN_MNTJOURNALIERALLOCATION 
           > 0;
	  quit;


%Let netezza_srv=netezza.sip91.pole-emploi.intra;
LIBNAME MALIB netezza server="&netezza_srv." port=5480 user=POPALE00_SAS_FRAUDE password=VHkL2Hx9
	db=POPALE_SAS_SASUSER bulkunload=yes;
Libname ntz_ecd netezza server="&netezza_srv." port=5480 user=POPALE00_SAS_FRAUDE password=VHkL2Hx9 db=POPALE_ECD bulkunload=YES;

PROC SQL;
	connect to netezza (&connection_to_ntz. db=POPALE_SAS_SASUSER);
	create table USERLIB.EGC_CORRESPONDANTETAB_V  as select *  from connection to netezza (
		SELECT t1.DATMAJ,t1.KC_ETABLISSEMENT, t1.KN_ETABLISSEMENT, t1.KN_IDENTIFIANTCONTACT, 
               t1.DD_DATEFINCONTACT, t1.DC_CIVILITE_ID, t1.DC_NOMCONTACT,  
               t1.DC_PRENOMCONTACT, 
               t1.DC_TELEPHONECONTACT1, t1.DC_TELEPHONECONTACT2, 
               t1.DC_ADRESSEMAILCONTACT,
               t1.DD_DATECREATION,t1.KD_DATEMODIFICATION
		FROM
			POPALE_ECD..EGC_CORRESPONDANTETAB_V t1
		WHERE EXTRACT(YEAR FROM t1.DATMAJ)>=2015);
	disconnect from netezza; 
Quit;





PROC SQL;
	   CREATE TABLE USERLIB.EGC_CORRESPONDANTETAB_V AS 
	   SELECT t1.DATMAJ,
	          t1.KC_ETABLISSEMENT, 
	          t1.KN_ETABLISSEMENT, 
	          t1.KN_IDENTIFIANTCONTACT, 
	          t1.DD_DATEFINCONTACT, 
	          t1.DC_CIVILITE_ID, 
	          t1.DC_NOMCONTACT, 
	          t1.DC_PRENOMCONTACT, 
	          t1.DC_TELEPHONECONTACT1, 
	          t1.DC_TELEPHONECONTACT2, 
	          t1.DC_ADRESSEMAILCONTACT,
			  t1.DD_DATECREATION,
              t1.KD_DATEMODIFICATION 
	  FROM USERLIB.EGC_CORRESPONDANTETAB_V t1
	  where t1.KC_ETABLISSEMENT
	  and t1.KD_DATEMODIFICATION > '30AUG2014:0:0:0'dt
	  group by t1.KC_ETABLISSEMENT
	  having t1.DATMAJ = max(t1.DATMAJ)
	 ;
	quit;


PROC SQL;
	   CREATE TABLE USERLIB.EGC_CORRESPONDANTETAB_V AS 
	   SELECT t1.DATMAJ,
	          t1.KC_ETABLISSEMENT, 
	          t1.KN_ETABLISSEMENT, 
	          t1.KN_IDENTIFIANTCONTACT, 
	          t1.DD_DATEFINCONTACT, 
	          t1.DC_CIVILITE_ID, 
	          t1.DC_NOMCONTACT, 
	          t1.DC_PRENOMCONTACT, 
	          t1.DC_TELEPHONECONTACT1, 
	          t1.DC_TELEPHONECONTACT2, 
	          t1.DC_ADRESSEMAILCONTACT,
			  T1.DD_DATECREATION,
			  t1.KD_DATEMODIFICATION 
	  FROM USERLIB.EGC_CORRESPONDANTETAB_V t1
	  where t1.KC_ETABLISSEMENT in ( select DC_EMPLOYEUR from USERLIB.DE_DPAE)
	  and t1.KD_DATEMODIFICATION > '30AUG2014:0:0:0'dt
	  group by t1.KC_ETABLISSEMENT
	  having t1.KD_DATEMODIFICATION = max(t1.KD_DATEMODIFICATION)
	 ;
	quit;

PROC SQL;
	   CREATE TABLE USERLIB.EGC_CORRESPONDANTETAB_V AS 
	   SELECT t1.DATMAJ,
	          t1.KC_ETABLISSEMENT, 
	          t1.KN_ETABLISSEMENT, 
	          t1.KN_IDENTIFIANTCONTACT, 
	          t1.DD_DATEFINCONTACT, 
	          t1.DC_CIVILITE_ID, 
	          t1.DC_NOMCONTACT, 
	          t1.DC_PRENOMCONTACT, 
	          t1.DC_TELEPHONECONTACT1, 
	          t1.DC_TELEPHONECONTACT2, 
	          t1.DC_ADRESSEMAILCONTACT,
			  T1.DD_DATECREATION,
			  t1.KD_DATEMODIFICATION
	  FROM USERLIB.EGC_CORRESPONDANTETAB_V t1
	  where t1.KC_ETABLISSEMENT in ( select DC_EMPLOYEUR from USERLIB.DE_DPAE)
	  and t1.KD_DATEMODIFICATION > '30AUG2014:0:0:0'dt
	  group by t1.KC_ETABLISSEMENT
	  having T1.DD_DATECREATION = max(T1.DD_DATECREATION)
	 ;
	quit;



proc sql;
create table USERLIB.DE_DPAE as select A.*,B.*
from USERLIB.DE_DPAE A left join USERLIB.EGC_CORRESPONDANTETAB_V B
ON A.DC_EMPLOYEUR=B.KC_ETABLISSEMENT;
quit;
proc sql;
create table USERLIB.DE_DPAE as select unique A.*
from USERLIB.DE_DPAE A;
quit;

/*
data USERLIB.DE_DPAE;
set DE_DPAE;
run;
/*entreprise*/


%Let netezza_srv=netezza.sip91.pole-emploi.intra;
LIBNAME MALIB netezza server="&netezza_srv." port=5480 user=POPALE00_SAS_FRAUDE password=VHkL2Hx9
	db=POPALE_SAS_SASUSER bulkunload=yes;
Libname ntz_ecd netezza server="&netezza_srv." port=5480 user=POPALE00_SAS_FRAUDE password=VHkL2Hx9 db=POPALE_ECD bulkunload=YES;

PROC SQL;
	connect to netezza (&connection_to_ntz. db=POPALE_SAS_SASUSER);
	create table USERLIB.EGC_ENTREPRISE_V  as select *  from connection to netezza (
		SELECT KC_ENTREPRISE, 
              KN_ENTREPRISE, 
	          DC_SIRENENTREPRISE, 
	          DC_RAISONSOCIALEENTREPRISE, 
	          DC_CATEGORIEJURIDIQUE, 
			  DD_DATECREATIONENTREPRISE, 
	          DD_DATECESSATIONACTIVITE,
	          DATMAJ
		FROM
			POPALE_ECD..EGC_ENTREPRISE_V t1
		WHERE EXTRACT(YEAR FROM t1.DATMAJ)>=2014);
	disconnect from netezza; 
Quit;

Proc sql;
	create table USERLIB.EGC_ENTREPRISE_V as select t1.KC_ENTREPRISE,
	t1.KN_ENTREPRISE, 
	          t1.DC_SIRENENTREPRISE, 
	          t1.DC_RAISONSOCIALEENTREPRISE, 
	          t1.DC_CATEGORIEJURIDIQUE, 
			  t1.DD_DATECREATIONENTREPRISE, 
	          t1.DD_DATECESSATIONACTIVITE,
	          t1.DATMAJ
	from USERLIB.EGC_ENTREPRISE_V t1
	where t1.KC_ENTREPRISE IN (select KC_ENTREPRISE from USERLIB.DE_DPAE)
		group by t1.KN_ENTREPRISE
		having max(t1.DATMAJ)=t1.DATMAJ;
	quit;

proc sql;
create table USERLIB.DE_DPAE as select A.*,B.*
from USERLIB.DE_DPAE A left join USERLIB.EGC_ENTREPRISE_V B
ON A.KC_ENTREPRISE=B.KC_ENTREPRISE;
quit;

PROC SQL;
	   CREATE TABLE USERLIB.REF_CATEGORIESJURIDIQU AS 
	   SELECT t1.OPRID, 
	          t1.DATMAJ, 
	          t1.NUMEVT, 
	          t1.NUMLOT, 
	          t1.KC_CATEGORIESJURIDIQUES, 
	          t1.DC_LBLCATEGORIESJURIDIQUES
	      FROM NTZ_ECD.REF_CATEGORIESJURIDIQUES t1
		  group by t1.KC_CATEGORIESJURIDIQUES
		  having max(t1.DATMAJ)=t1.DATMAJ;
	QUIT;

	/** Modif BSA pour top_en_cours **/
	proc sql;
	create table USERLIB.DE_DPAE as 
	select A.*
	,B.DC_LBLCATEGORIESJURIDIQUES
	, (case when (DC_MOTIFPRESENCESI like '%I%' and DC_MOTIFPRESENCESI not in ('IDE',''))
								then 'IDE en cours' 
							else 'radié' 
							end)
						as Top_EnCours
	from USERLIB.DE_DPAE A left join USERLIB.REF_CATEGORIESJURIDIQU B
	on A.DC_CATEGORIEJURIDIQUE=B.KC_CATEGORIESJURIDIQUES;
	quit;
data USERLIB.DE_DPAE;
set USERLIB.DE_DPAE;
run;


/*
data DE_DPAE;
set DE_DPAE;
if find(DC_MOTIFPRESENCESI,'I')>0   and DC_MOTIFPRESENCESI not in ('IDE','') then do;Top_EnCours='IDE en cours';end;
else do;Top_EnCours='radié';end;
run;
*/


PROC SQL;
   CREATE TABLE USERLIB.DRV_X_DMRIDCDROIT_V AS 
   SELECT t1.DATMAJ, 
          t1.TN_INDIVIDUADMIN_IDT, 
          t1.TN_DAL_IDT, 
          t1.TN_DECISIONDAL_IDT, 
          t1.TN_DROIT_IDT, 
		  t1.DC_NUMPEC,
		  t1.KC_DEMANDEALLOCATION,
		  t1.KN_DOSSIERDAL,
          t1.DN_MTBASEJUSTIFICATIF, 
          t1.DN_MTSJRIPLAFONNEDRTRETENU,
	      t1.KD_DATEEVENEMENT,
		  t1.KD_DATEVALIDATION,
	      t1.DC_INDIVIDU_NATIONAL,
	      t1.DC_INDIVIDU_LOCAL,
	      t1.DC_LBLPRODUIT_RETENU,
		  t1.KN_DOSSIERDAL,
		  t1.DC_LBLTYPEDECISION,
		  t1.DD_DATETHEORIQUEFINDROIT,
		  t1.DD_DATEMODIFICATION,
		  A.KD_DATEEMBAUCHE
           
      FROM NTZ_MET.DRV_X_DMRIDCDROIT_V t1 inner join USERLIB.DE_DPAE A
	  on t1.DC_INDIVIDU_NATIONAL=A.DC_IDTIDVNAT
	  /*WHERE t1.DC_INDIVIDU_NATIONAL IN (select DC_IDTIDVNAT from DE_DPAE)*/
	  where A.KD_DATEEMBAUCHE>=t1.DD_DATEMODIFICATION;
QUIT;



Proc sql;
CREATE TABLE USERLIB.DRV_X_DMRIDCDROIT_V AS 
SELECT A.*
FROM USERLIB.DRV_X_DMRIDCDROIT_V A
group by A.DC_INDIVIDU_NATIONAL /*, A.KN_DOSSIERDAL*/
having A.KN_DOSSIERDAL=min(A.KN_DOSSIERDAL);
quit;

/*
data USERLIB.DRV_X_DMRIDCDROIT_V;
set USERLIB.DRV_X_DMRIDCDROIT_V;
if DN_MTBASEJUSTIFICATIF= . then do;DN_MTBASEJUSTIFICATIF=0;end;
run;*/
/*
proc sql;
create table extracttaux as select 
DC_INDIVIDU_NATIONAL, KN_DOSSIERDAL,
max(DN_MTBASEJUSTIFICATIF) as DN_MTBASEJUSTIFICATIFBIS
from USERLIB.DRV_X_DMRIDCDROIT_V
group by DC_INDIVIDU_NATIONAL, KN_DOSSIERDAL;
quit;*/
/*
proc sql;
create table USERLIB.DRV_X_DMRIDCDROIT_V as select A.*,B.DN_MTBASEJUSTIFICATIFBIS
from USERLIB.DRV_X_DMRIDCDROIT_V A left join extracttaux B
on A.DC_INDIVIDU_NATIONAL=B.DC_INDIVIDU_NATIONAL and
A.KN_DOSSIERDAL=B.KN_DOSSIERDAL;
quit;*/



proc sql;
create table USERLIB.DRV_X_DMRIDCDROIT_V as select A.*
from USERLIB.DRV_X_DMRIDCDROIT_V A
group by A.DC_INDIVIDU_NATIONAL, A.KN_DOSSIERDAL
having A.DATMAJ=max(A.DATMAJ);
quit;

proc sql;
create table USERLIB.DRV_X_DMRIDCDROIT_V as select A.*
from USERLIB.DRV_X_DMRIDCDROIT_V A
group by A.DC_INDIVIDU_NATIONAL, A.KN_DOSSIERDAL
having A.DD_DATEMODIFICATION=max(A.DD_DATEMODIFICATION);
quit;

proc sql;
create table USERLIB.DRV_X_DMRIDCDROIT_V as select A.*
from USERLIB.DRV_X_DMRIDCDROIT_V A
group by A.DC_INDIVIDU_NATIONAL, A.KN_DOSSIERDAL
having A.KD_DATEVALIDATION=max(A.KD_DATEVALIDATION);
quit;

proc sql;
create table USERLIB.DRV_X_DMRIDCDROIT_V as select A.*
from USERLIB.DRV_X_DMRIDCDROIT_V A
group by A.DC_INDIVIDU_NATIONAL, A.KN_DOSSIERDAL
having A.KD_DATEEVENEMENT=max(A.KD_DATEEVENEMENT);
quit;

proc sql;
create table USERLIB.DRV_X_DMRIDCDROIT_V as select unique A.*
from USERLIB.DRV_X_DMRIDCDROIT_V A;
quit;




/*KD_DATEMODIFICATION,  KC_INDIVIDU_NATIONAL, KN_INDIVIDU_NATIONAL
DC_SOURCEINFORMATION='DROIT_NCP',  DC_DEMANDEALLOCATION_ID*/

/*
proc sql;
create table USERLIB.DRV_ELEMENTDROIT_V as
select A.*
from NTZ_ECD.DRV_ELEMENTDROIT_V A
where A.KC_INDIVIDU_NATIONAL IN (select DC_IDTIDVNAT from USERLIB.DE_DPAE);
quit;
*/
/*
proc sql;
create table ELEMENT as select A.*,B.KC_DEMANDEALLOCATION,B.DD_DATEMODIFICATION as DD_DATEMODIFICATIONBIS
from USERLIB.DRV_ELEMENTDROIT_V A left join USERLIB.DRV_X_DMRIDCDROIT_V B
on A.KC_INDIVIDU_NATIONAL=B.DC_INDIVIDU_NATIONAL and 
A.DC_DEMANDEALLOCATION_ID=B.KC_DEMANDEALLOCATION;
quit;*/
/*
data ELEMENT;
set ELEMENT;
where DC_DEMANDEALLOCATION_ID=KC_DEMANDEALLOCATION
and compress(DC_DEMANDEALLOCATION_ID) not in (""," ") and
DN_MONTANTBASEJUSTIFICATIF ne . ;
run;*/
/*
proc sql;
create table ELEMENT as select KC_INDIVIDU_NATIONAL, 
max(DN_MONTANTBASEJUSTIFICATIF) as DN_MONTANTBASEJUSTIFICATIF_ELE
from ELEMENT
group by KC_INDIVIDU_NATIONAL ;
quit;*/

/*
data USERLIB.DRV_X_DMRIDCDROIT_V;
set USERLIB.DRV_X_DMRIDCDROIT_V;
drop DN_MONTANTBASEJUSTIFICATIF_ELE;
run;*/
/*
proc sql;
create table USERLIB.DRV_X_DMRIDCDROIT_V as select A.*,B.DN_MONTANTBASEJUSTIFICATIF_ELE
from USERLIB.DRV_X_DMRIDCDROIT_V A left join ELEMENT B
on A.DC_INDIVIDU_NATIONAL=B.KC_INDIVIDU_NATIONAL;
quit;*/





/*

PROC SQL;
   CREATE TABLE WORK.DRV_PERIODEACTIVITEGAEC_1 AS 
   SELECT DISTINCT t1.DC_ASSEDIC_DE, 
          t1.KC_INDIVIDU_NATIONAL, 
          t1.DD_DATEDEBUTACTIVITE,  
          t1.DD_DATEFINACTIVITE, 
          t1.DC_TYPEPERIODEGAEC_ID, 
          t1.DN_QUANTITEACTIVITE, 
          t1.DC_UNITEACTIVITE_ID,
		  t1.DC_ORIGINEINFORMATIONGAEC_ID,
		  t1.DC_ETABLISSEMENT_ID,
		  t1.DN_ETABLISSEMENT_ID
      FROM NTZ_ECD.DRV_PERIODEACTIVITEGAEC_V t1
      WHERE t1.DC_ORIGINEINFORMATIONGAEC_ID in ('34','37','56','54','2','1','4','33','39')  AND 
           (( t1.DD_DATEDEBUTACTIVITE >= &datetime_deb_M AND t1.DD_DATEFINACTIVITE <= &datetime_fin_M2) OR 
           (t1.DD_DATEDEBUTACTIVITE >= &datetime_deb_M4 AND t1.DD_DATEFINACTIVITE <= &datetime_fin_M4) ) and
     t1.KC_INDIVIDU_NATIONAL in (select DC_IDTIDVNAT from DE_DPAE);
QUIT;
*/

PROC SQL;
   CREATE TABLE USERLIB.DRV_PERIODEACTIVITEGAEC_1 AS 
   SELECT DISTINCT t1.DC_ASSEDIC_DE, 
          t1.KC_INDIVIDU_NATIONAL, 
          t1.DD_DATEDEBUTACTIVITE,  
          t1.DD_DATEFINACTIVITE, 
          t1.DC_TYPEPERIODEGAEC_ID, 
          t1.DN_QUANTITEACTIVITE, 
          t1.DC_UNITEACTIVITE_ID,
		  t1.DC_ORIGINEINFORMATIONGAEC_ID,
		  t1.DC_ETABLISSEMENT_ID,
		  t1.DN_ETABLISSEMENT_ID
      FROM NTZ_ECD.DRV_PERIODEACTIVITEGAEC_V t1
      WHERE t1.DC_ORIGINEINFORMATIONGAEC_ID in ('34','37','56','54','2','1','4','33','39')  AND 
           ( t1.DD_DATEDEBUTACTIVITE >= &datetime_deb_M AND t1.DD_DATEFINACTIVITE <= &datetime_fin_M) 
      and
     t1.KC_INDIVIDU_NATIONAL in (select DC_IDTIDVNAT from USERLIB.DE_DPAE);
QUIT;





proc sql;
create table USERLIB.DRV_PERIODEACTIVITEGAEC_1 as select unique
t1.KC_INDIVIDU_NATIONAL,
t1.DC_ETABLISSEMENT_ID,
t1.DN_ETABLISSEMENT_ID
from USERLIB.DRV_PERIODEACTIVITEGAEC_1 t1;
quit;

proc sql;
create table USERLIB.DRV_PERIODEACTIVITEGAEC_1 as select unique
t1.KC_INDIVIDU_NATIONAL as KC_INDIVIDU_NATIONALGAEC,
t1.DC_ETABLISSEMENT_ID as DC_ETABLISSEMENT_IDGAEC,
t1.DN_ETABLISSEMENT_ID as DN_ETABLISSEMENT_IDGAEC,
"AE" as AEPRES
from USERLIB.DRV_PERIODEACTIVITEGAEC_1 t1;
quit;
proc sql;
create table USERLIB.DE_DPAE as select A.*,B.*
from USERLIB.DE_DPAE A left join USERLIB.DRV_PERIODEACTIVITEGAEC_1 B
on A.DC_IDTIDVNAT=B.KC_INDIVIDU_NATIONALGAEC and 
A.DC_EMPLOYEUR=B.DC_ETABLISSEMENT_IDGAEC;
quit;

data USERLIB.DE_DPAE;
set USERLIB.DE_DPAE;
where AEPRES ne 'AE';
run;

proc sql;
create table userlib.DE_DPAE as select A.*,B.DD_DATETHEORIQUEFINDROIT,
B.DC_LBLPRODUIT_RETENU,B.DN_MTBASEJUSTIFICATIF, B.DN_MTSJRIPLAFONNEDRTRETENU,
B.DC_LBLTYPEDECISION,B.KN_DOSSIERDAL, 
B.KD_DATEVALIDATION,B.KD_DATEEMBAUCHE
from userlib.DE_DPAE A left join USERLIB.DRV_X_DMRIDCDROIT_V B
on A.DC_IDTIDVNAT=B.DC_INDIVIDU_NATIONAL;
quit;

data userlib.DE_DPAE;
set userlib.DE_DPAE;
TYPALOC = substr(DC_LBLPRODUIT_RETENU,1,3);
run;

data userlib.DE_DPAE;
set userlib.DE_DPAE;
where substr(DC_LBLTYPEDECISION,1,5) ne 'Rejet';
run;

proc sql;
create table BNI_DAL as select unique
KC_INDIVIDU_LOCAL, KN_DOSSIERDAL, KD_DATEEMBAUCHE
from userlib.DE_DPAE;
quit;


proc sql;
create table userlib.DRV_PERIODEJUSTIFCONST_V as select t1.*,A.KN_DOSSIERDAL
FROM NTZ_ECD.DRV_PERIODEJUSTIFCONST_V t1 inner join BNI_DAL A
on t1.KC_INDIVIDU_LOCAL=A.KC_INDIVIDU_LOCAL
where t1.DC_TYPEDEPERIODEPJC_ID = '1' AND t1.DN_MNTJOURNALIERALLOCATION > 0;
/*and t1.DN_NUMERODOSSIERSUIVIDAL IN (select KN_DOSSIERDAL from userlib.DE_DPAE);*/
quit;

proc sql;
create table BNI_DAL as select A.*,B.*
from BNI_DAL A left join userlib.DRV_PERIODEJUSTIFCONST_V B
On A.KC_INDIVIDU_LOCAL=B.KC_INDIVIDU_LOCAL;
/*where A.KD_DATEEMBAUCHE<=B.KD_DATEDEBUTPJC;*/
quit;

data BNI_DAL;
set BNI_DAL;
diff = abs(KD_DATEDEBUTPJC-KD_DATEEMBAUCHE);
run;



proc sql;
create table BNI_DAL as select A.*
from BNI_DAL A
group by A.KC_INDIVIDU_LOCAL
having min(A.diff)=A.diff;
quit;

proc sql;
create table BNI_DAL as select 
KC_INDIVIDU_LOCAL, max(DN_MNTSJRREVALORISEPLAFONNE) 
as DN_MNTSJRREVALORISEPLAFONNE
from BNI_DAL
group by KC_INDIVIDU_LOCAL;
quit;

proc sql;
create table USERLIB.DE_DPAE as select A.*,
B.DN_MNTSJRREVALORISEPLAFONNE
from USERLIB.DE_DPAE A left join BNI_DAL B
on A.KC_INDIVIDU_LOCAL=B.KC_INDIVIDU_LOCAL;
quit;

data USERLIB.DE_DPAE;
set USERLIB.DE_DPAE;
if DN_MTSJRIPLAFONNEDRTRETENU=. then do;
DN_MTSJRIPLAFONNEDRTRETENU=DN_MNTSJRREVALORISEPLAFONNE;end;
run;

/*DC_LBLTYPEDECISION*/

/*
Si Situation DE en cours et SJR > 100 et CDI	100 %
Si Situation DE en cours et SJR 50 <>100 et CDI	99 %
Si Situation DE en cours et SJR < 50 et CDI	98 %
Si Situation DE en cours et SJR > 100 et CDD	97 %
Si Situation DE en cours et SJR 50 <>100 et CDD	96 %
Si Situation DE en cours et SJR < 50 et CDD	95 %
Si Situation DE radié et SJR > 100	94 %
Si Situation DE radié et SJR 50 <>100	93 %
Si Situation DE radié et SJR < 50	92 %
Si Situation DE en cours et ASS	91 %
Si Situation DE radié et ASS	90 %
*/

data USERLIB.DE_DPAE;
set USERLIB.DE_DPAE;
if Top_EnCours='IDE en cours' and DN_MTSJRIPLAFONNEDRTRETENU>100 and TYPCONT='CDI' then do;score1=100;end;
if Top_EnCours='IDE en cours' and DN_MTSJRIPLAFONNEDRTRETENU>=50 and DN_MTSJRIPLAFONNEDRTRETENU<=100 and TYPCONT='CDI' then do;score2=99;end;
if Top_EnCours='IDE en cours' and DN_MTSJRIPLAFONNEDRTRETENU<50 and TYPCONT='CDI' then do;score3=98;end;
if Top_EnCours='IDE en cours' and DN_MTSJRIPLAFONNEDRTRETENU>100 and TYPCONT='CDD de 6 mois et plus' then do;score4=97;end;
if Top_EnCours='IDE en cours' and DN_MTSJRIPLAFONNEDRTRETENU>=50 and DN_MTSJRIPLAFONNEDRTRETENU<=100 and TYPCONT='CDD de 6 mois et plus' then do;score5=96;end;
if Top_EnCours='IDE en cours' and DN_MTSJRIPLAFONNEDRTRETENU<50 and TYPCONT='CDD de 6 mois et plus' then do;score6=95;end;
if Top_EnCours='radié'  and DN_MTSJRIPLAFONNEDRTRETENU>100 then do;score7=94;end;
if Top_EnCours='radié'  and DN_MTSJRIPLAFONNEDRTRETENU>=50  and DN_MTSJRIPLAFONNEDRTRETENU<=100 then do;score8=93;end;
if Top_EnCours='radié'  and DN_MTSJRIPLAFONNEDRTRETENU<50 then do;score9=92;end;
if Top_EnCours='IDE en cours' and TYPALOC='ASS' then do;score10=91;end;
if Top_EnCours='radié' and TYPALOC='ASS' then do;score11=90;end;
run;
data USERLIB.DE_DPAE;
set USERLIB.DE_DPAE;
score=max(score1,score2,score3,score4,score5,score6,score7,score8,score9,score10,score11);
run;
/*Top_EnCours, DN_MTSJRIPLAFONNEDRTRETENU, TYPALOC, TYPCONT*/


/*KC_INDIVIDU_NATIONAL, KC_SIRET, DC_EMPLOYEUR*/
proc sql;
create table USERLIB.NB_BNI_BNE as select DC_EMPLOYEUR,count(distinct KC_INDIVIDU_NATIONAL) as NB_BNI_BNE
from USERLIB.DE_DPAE
group by DC_EMPLOYEUR;
quit; 
proc sql;
create table USERLIB.NB_BNI_BNEBIS as select KC_SIRET,count(distinct KC_INDIVIDU_NATIONAL) as NB_BNI_SIRET
from USERLIB.DE_DPAE
group by KC_SIRET;
quit; 

proc sql;
create table USERLIB.DE_DPAE as select A.*,B.NB_BNI_BNE
from USERLIB.DE_DPAE A left join USERLIB.NB_BNI_BNE B
on A.DC_EMPLOYEUR=B.DC_EMPLOYEUR;
quit;

proc sql;
create table USERLIB.DE_DPAE as select A.*,B.NB_BNI_SIRET
from USERLIB.DE_DPAE A left join USERLIB.NB_BNI_BNEBIS B
on A.KC_SIRET = B.KC_SIRET;
quit;

data USERLIB.DE_DPAE;
set USERLIB.DE_DPAE;
if NB_BNI_BNE=NB_BNI_SIRET then do;NB_BNI_BNEREF=NB_BNI_BNE;end;
else do;NB_BNI_BNEREF=NB_BNI_SIRET;end;
run;


data USERLIB.DE_DPAE;
	set USERLIB.DE_DPAE;
	format detail $600.;
	detail=KSTRCAT("Date d'embauche: ",put(datepart(KD_DATEEMBAUCHE),EURDFDD8.),"\n","Nature du contrat: ",TYPCONT,"\n",
	"Taux journalier: ",DN_MTBASEJUSTIFICATIF,"\n","Situation du DE: ", Top_EnCours , "\n","Correspondant entreprise: ",
	   DC_NOMCONTACT," ", DC_PRENOMCONTACT, " " , DC_TELEPHONECONTACT1, " ",  DC_ADRESSEMAILCONTACT
	);
	run;
data userlib.DE_DPAE;
set USERLIB.DE_DPAE;
run;

%end;
%mend;

%ChargementEspaceEntreprise;



/*
data DE_DPAE;
set USERLIB.DE_DPAE;
run;*/
/*
data userlib.DE_DPAE2;
set finrgl.DE_DPAE;
run;*/

data finrgl.DE_DPAE;
	/*format detail $1024.;*/
	set userlib.DE_DPAE;
run;

/*premiere partie*/
proc contents data=FCMATEMP.FCM_ALERT_SUMMARY out=col noprint; run;

	proc sql noprint;
		select name into :col_list separated by ' '
			from col;
	quit;
/*
data userlib.DE_DPAE;
set DE_DPAE;
run;
*/


data stage._alert_summary ;

		format X_PRIORITY $1. ;
		format X_SCORE2 8.5 ;
		format X_ETABLISSEMENT $80. ;
		format X_REGION_ETABLISSEMENT $50. ;	
		format X_DATE_NAISSANCE datetime. ;
		format X_DATE_CREATION_ENTREPRISE datetime. ;
		format X_DATE_CESSATION_ENTREPRISE datetime. ;
		format scenario_severity_score_no 5.2 ;
		format X_DATE_IDE datetime. ;
		format X_CAT_ETABLISSEMENT $100.;
		format X_ETAB_FINANCIER  $100. ;
		

	if 0 then set FCMATEMP.FCM_ALERT_SUMMARY(keep=entity_variable_sk X_:);

	set finrgl.DE_DPAE;

	entity_nm = 'BNI';
	entity_variable_sk = Strip(KN_INDIVIDU_NATIONAL);/*ok*/
	run_dt = "&FCM_RUNDATE"dt ;
    scenario_loss_amt=coalesce(DN_MNTJOURNALIERALLOCATION4);
	scenario_severity_score_no =  score  /*ecran1 SCORE */;/*score*/
	scenario_sk = &scenario_sk;
	scenario_weight_no=&scenario_weight_no; 
	X_ADRESS = DC_VOIE;  /* DE    */
	X_ADRESS2 = DC_COMPLEMENTADRESSEDEST; /*DE fait*/ 
	X_ADRESS3 = DC_COMPLEMENTDISTRIBUTION;/*DE fait*/
	/** **/
	X_ADRESSE_ETABLISSEMENT = Strip(DC_NUMERODANSVOIE || DC_LIBNOMRUE); /** OK fait**/ 
	X_ADRESSE2_ETABLISSEMENT = "";
	X_BIC = DC_BIC; /*DE fait*/
	/** Modif  BSA le 9 mars 2018 **/
	X_ENTREPRISE = KC_ENTREPRISE ; /*fait*/
	X_BNE = KC_ETABLISSEMENT ; /*fait*/

	X_BNI = Strip(KN_INDIVIDU_NATIONAL); /*fait*/
	X_CODE_AGENCE = put(DC_CDEALE_ID,$CODE_SAFIR_AURORE.)  ;/*agence DE fait*/ 
	/** ajout BSA le 9 mars 2018 **/
	X_SJR =  strip(DN_MTSJRIPLAFONNEDRTRETENU);/*DEfait*/
	X_CODE_SAFIR = DC_CDEALE_ID  ; /*agence DE fait*/
	X_CODE_AGENCE_SAPHIR = DC_CDEALE_ID;
	X_CODE_AURORE = put(DC_CDEALE_ID,$CODE_SAFIR_AURORE.)  ;
	X_DT_AGENCE =  put(compress(X_CODE_AURORE),$CODE_DT_AGENCE.) ; /*fait*/
	X_CODE_AGENT = "";
	X_CODE_POSTAL = DC_CODEPOSTALLOCALITE ;   /*DC_CODEPOSTALLOCALITE; entreprise à verifier*/
	X_CODE_POSTAL_ETABLISSEMENT = DC_CODEPOSTALENT; /*fait*/
	X_DATE_CESSATION_ENTREPRISE = DD_DATECESSATIONACTIVITE ; /** OK fait**/
	X_DATE_CREATION_ENTREPRISE = DD_DATECREATIONENTREPRISE ; /** OK fait**/
	X_DATE_NAISSANCE = DD_DATENAISSANCE; /*DE*/
	X_DEPT = cats('D',substr(dc_codepostallocalite,1,2)); /*entreprise à verifier*/
	X_DEPT_ETABLISSEMENT = substr(DC_CODEPOSTALENT,1,2) ; /** Ok A traduire en libelle fait**/
	X_EFFECTIF_EMPLOYEUR = "" ; /** OK  A supprimer **/
	X_EMAIL = " " ; /*ENTREPRISE DC_ADRESSEEMAIL(ne sait pas si c'est correspondant */
	X_EMAIL_EMPLOYEUR = DC_ADRESSEMAILETABLISSEMENT ; 
	X_ENTITE=Strip(CompBL(DC_NOMCORRESPONDANCE !! DC_PRENOM)); /*fait DE*/
	X_ETAB_FINANCIER = Put(DC_ETABLISSEMENTFINANCIER , $LIB_ETABFINANCIER.); /*fait DE*/
	X_CAT_ETABLISSEMENT = Put(DC_ETABLISSEMENTFINANCIER , $LIB_CATEGORIEFINANCIER.);/*fait DE*/
/*	X_ETABLISSEMENT = KC_ETABLISSEMENT ;*/
	X_ETABLISSEMENT = DC_ENSEIGNE ; /*fait*/
	X_IBAN = DC_IBAN; /*DE fait*/
	X_IDENTIFIANT_LOCAL = DC_INDIVIDU_LOCAL;
	X_NAF = DC_NAFREV2_ID; /** OK DC_NAFREV2_ID**/
	X_NATIONALITE = DC_LBLNATIONALITE ; /* DC_NATIONALITE Put(DC_NATIONALITE_ID, $NATIONALITE.);/*DE*/
	X_NIR = DC_NIR; /*DE fait*/
	X_NOM = DC_NOMPATRONYMIQUE;/*DE*/
	X_NOM_ENTREPRISE = DC_RAISONSOCIALEENTREPRISE; /**a faire Ok **/
	X_NOM_MARITAL = DC_NOMCORRESPONDANCE;/*DE*/
	
	X_NPAI_BNI =  " ";/*DC_LBLETATNPAIADRESSE ; /*DE fait*/
	X_NPAI_ETABLISSEMENT = "" ;
	X_NUM_PEC = " "; /*strip(DC_NUMPEC); /*La derniere PEC*/ 
	X_PAYS = DC_PAYS ;  /*DE*/
	X_PAYS_NAISSANCE = put(DC_PAYS_NAISSANCEENVOYE_ID,$PAYS.);
	X_PIECE_IBAN = "";
	X_PRENOM = DC_PRENOM; /*DE fait*/

*** Modif ASI (28-08-2018) : pour le color coding, Rouge pour les CDI et Orange pour les autres *****;
		if scenario_severity_score_no =100 then X_PRIORITY = 'R' ;
		else if scenario_severity_score_no =50 then X_PRIORITY = 'O' ;
	
	If substr(X_CODE_POSTAL,1,2) ne '97' then X_REGION =  put(strip(substr(X_CODE_POSTAL,1,2)),$DEP2REG.);
		else X_REGION =  put(strip(substr(X_CODE_POSTAL,1,3)),$DEP2REG.);/*DE*/
	If substr(X_DEPT_ETABLISSEMENT,1,2) ne '97' then Region_Entrep =  put(strip(substr(X_DEPT_ETABLISSEMENT,1,2)),$DEP2REG.);
		else Region_Entrep =  put(strip(substr(X_DEPT_ETABLISSEMENT,1,3)),$DEP2REG.);/*DE*/

	X_SCORE2 = score ;/*score*/
/*	X_SCORE2 = put(coalesce(Score_XGBOOST),8. ) ;*/
	X_SEXE = DC_SEXE_ID; /*DE*/
	/** ajout **/
    X_NOM_ETABLISSEMENT = DC_ENSEIGNE ; /** Ok **/
    X_REGION_ETABLISSEMENT = Region_Entrep ; /** Ok ENT**/
	/****                                       ****/
	X_SIRET=Strip(DC_SIRETETABLISSEMENT); /** OK **/
	X_STATUT_JURIDIQUE_ENTREPRISE = DC_LBLCATEGORIESJURIDIQUES ; /*  */
	X_IBAN_E = ""; /*jai pas*/
	X_TITULAIRE_IBAN = ""; /*jai pas*/
	X_TEL = DC_TELEPHONE1 ; /*ent*/
	X_TEL2 = DC_TELEPHONE2 ; /*ent*/
	X_TEL_EMPLOYEUR  = DC_TELEPHONECONTACT1 ; /** Ok A alimenter ETAB**/ 
	X_TEL2_EMPLOYEUR = ""; 	/** Ok A alimenter **/ 
	X_NOM_EMPLOYEUR = DC_NOMCONTACT;  			/** Ok A alimenter **/ 
	X_PRENOM_EMPLOYEUR = DC_PRENOMCONTACT; 		/** Ok A alimenter **/  
	X_RADIATION_ENTREPRISE = ""; 	/** Ok : A alimenter URSSAF **/
	/** modification BSA pour alimentation par code AURORE **/
	X_REGION_AGENCE = put(compress(X_CODE_AURORE),$CODE_DR_AGENCE.) ; 
	
	/*	X_REGION_AGENCE = Region_APE ;  */
	X_VILLE = TRIM(LEFT(TRANWRD(DC_CODEPOSTALLOCALITE,compress(DC_CODEPOSTAL),"")));/*entre*/
	X_VILLE_ETABLISSEMENT = DC_LIBCOMMUNEENT; /** Ok A alimenter **/  
	X_DATE_IDE = "";  			/** Ok A alimenter ne pas alimenter**/ 
	X_TYPCONT = TYPCONT;
	/*	X_CAT_ETABLISSEMENT = "";  */
	/** Ok A alimenter **/  

	
	/*ou "ce DE a les mêmes dates emploi, le même motif de rupture et le même SJR que [nbre] autres DE du même établissement" ;*/

    X_COMMENT=detail;

   X_KD_DATEEMBAUCHE = KD_DATEEMBAUCHE;	
   X_NOM_ENTREPRISE = DC_RAISONSOCIALEENTREPRISE;
   X_CODE_POSTAL_ETABLISSEMENT = DC_CODEPOSTALENT;
   X_DC_COMPLEMENTADRESSE=DC_COMPLEMENTADRESSE;
   X_DC_NUMERODANSVOIE=DC_NUMERODANSVOIE;
   X_DC_TYPEVOIE=DC_TYPEVOIE;
   X_DC_LIBNOMRUE=DC_LIBNOMRUE;
   X_DC_LIBDISTRIBSPECIFIQUE=DC_LIBDISTRIBSPECIFIQUE;
   X_DC_COMPLEMENTADRESSE2=DC_COMPLEMENTADRESSE2;
   X_TEL_EMPLOYEUR  = DC_TELEPHONECONTACT1 ; 
   X_TEL2_EMPLOYEUR = "";  
   X_NOM_EMPLOYEUR = DC_NOMCONTACT; 
   X_PRENOM_EMPLOYEUR = DC_PRENOMCONTACT;

   X_DC_PRENOMCORRESPONDANCE=DC_PRENOMCORRESPONDANCE;
   X_DC_NOMCORRESPONDANCE=DC_NOMCORRESPONDANCE;
   X_DC_CIVILITE_ID=DC_CIVILITE_ID;
   X_DC_VOIE=DC_VOIE;
   X_DC_COMPLEMENTADRESSEDEST=DC_COMPLEMENTADRESSEDEST ;
   X_DC_CODEPOSTALLOCALITE=DC_CODEPOSTALLOCALITE;
   X_DC_CODEPOSTAL=DC_CODEPOSTAL;
   X_DC_TELEPHONE1=DC_TELEPHONE1;
   X_DC_ADRESSEEMAIL=DC_ADRESSEEMAIL;
   X_NB_BNI_PAR_BNE=NB_BNI_BNEREF;
   X_TAUX=DN_MTBASEJUSTIFICATIF;
   X_DATE_THEORIQUEFINDROIT = DD_DATETHEORIQUEFINDROIT;
   X_Top_EnCours=Top_EnCours;
	keep &col_list ;
	/* interruption AGP après x lignes */
	if _N_ = 6000 then stop;       
	/*  */
run;












