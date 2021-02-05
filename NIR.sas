%deltab(libdel=NTZNEW ,tabdel=OD_NIR_6M_A);
%deltab(libdel=NTZNEW ,tabdel=OD_NIR_6M_B);
%deltab(libdel=NTZNEW ,tabdel=OD_NIR_6M_C);
%deltab(libdel=NTZNEW ,tabdel=OD_NIR_6M);

PROC SQL;
CONNECT TO NETEZZA (&pass_to_ntz_work_db.);
EXECUTE (CREATE TABLE OD_NIR_6M_A AS 
   				SELECT DISTINCT 
					KN_INDIVIDU_NATIONAL, 
          			DC_INDIVIDU_NATIONAL, 
          			DC_INDIVIDU_LOCAL, 
          			TC_TRAITEMENTDAL, 
          			DC_NIR, 
          			DC_CERTIFICATIONNIR, 
          			DC_LBLCERTIFICATIONNIR, 
          			DC_NUMPEC, 
          			KN_DOSSIERDAL, 
          			DD_DATEINITIALISATIONDAL, 
          			KD_DATEVALIDATION, 
          			DC_TYPEDECISION, 
          			DC_LBLTYPEDECISION, 
          			DC_LBLDERNIERETATACTIONDAL, 
          			DC_PREMIERTYPELIQUIDATION, 
          			DC_LBLPREMIERTYPELIQUIDATION, 
          			DC_TYPELIQUIDATION, 
          			DC_LBLTYPELIQUIDATION, 
          			DD_DATEVALI_PREMIEREDECISION, 
          			DD_DATEFCT, 
          			DC_REGLTAPPLICABLE_RETENU, 
          			DC_LBLREGLTAPPLICABLE_RETENU, 
          			DC_PRODUIT_RETENU, 
          			DC_LBLPRODUIT_RETENU, 
          			DC_SOUSPRODUIT_RETENU, 
          			DC_LBLSOUSPRODUIT_RETENU, 
          			DD_DATEEFFETATTRIBUTION, 
          			DD_DATE1ERPAIEMENT, 
          			KD_DATEEVENEMENT
				FROM POPALE_MET..DRV_X_DMRIDCDROIT_V t1
				WHERE DD_DATEVALI_PREMIEREDECISION >= '1Jun2020'
				AND DC_LBLTYPEDECISION IN ('Admission (Attribution Formation)','Attribution effective',
'Novation CSP (Identique à admission)','Ouverture de droit suite à " Rechargement " (AC 2014)',
'Réad. Droit courant','Réad. droit précédent','Réad. Produit résultant','Reprise','Reprise auto',
'Reprise droit commun','Reprise simplifiée','Reprise systématique','Reprises Secteur Public',
'Sortie CSP (Identique à admission)');
           )BY NETEZZA;
DISCONNECT FROM NETEZZA;
QUIT;

PROC SQL NOPRINT;
CONNECT TO NETEZZA (&pass_to_ntz_work_db.);
EXECUTE (CREATE TABLE OD_NIR_6M_B AS 
          		SELECT * 
                FROM (SELECT *,ROW_NUMBER() OVER (PARTITION BY TC_TRAITEMENTDAL ORDER BY KD_DATEEVENEMENT DESC) AS IDSQL
                FROM OD_NIR_6M_A) a
                WHERE IDSQL=1;
				) BY NETEZZA;
DISCONNECT FROM NETEZZA;
QUIT;

PROC SQL;
CONNECT TO NETEZZA (&pass_to_ntz_work_db.);
EXECUTE (CREATE TABLE OD_NIR_6M_C AS 
   				SELECT DISTINCT 
					a.*,
          			b.DC_CERTIFICATIONNIR_ID, 
          			b.DC_NATIONALITE,
					b.KD_DATEMODIFICATION,
					c.DC_LBLCERTIFICATIONNIR AS DC_LBLCERTIFICATIONNIR1,
					d.DC_LBLNATIONALITE,
					e.DC_LBLPAYS, 
          			e.DC_INDICPAYSEUROPEEN
      			FROM OD_NIR_6M_A a
           		LEFT JOIN POPALE_ECD..DCO_INDIVIDU_V b ON (a.KN_INDIVIDU_NATIONAL = b.KN_INDIVIDU_NATIONAL)
				LEFT JOIN POPALE_ECD..REF_CERTIFICATIONNIR_V c ON (b.DC_CERTIFICATIONNIR_ID = c.KC_CERTIFICATIONNIR)
           		LEFT JOIN POPALE_ECD..REF_NATIONALITE_V d ON (b.DC_NATIONALITE = d.KC_NATIONALITE)
           		LEFT JOIN POPALE_ECD..REF_PAYS_V e ON (b.DC_PAYS_NAISSANCE_ID = e.KC_PAYS)
      			WHERE a.DC_CERTIFICATIONNIR <> 'VC';
				) BY NETEZZA;
DISCONNECT FROM NETEZZA;
QUIT;

PROC SQL NOPRINT;
CONNECT TO NETEZZA (&pass_to_ntz_work_db.);
EXECUTE (CREATE TABLE OD_NIR_6M AS 
          		SELECT * 
                FROM (SELECT *,ROW_NUMBER() OVER (PARTITION BY KN_INDIVIDU_NATIONAL ORDER BY KN_INDIVIDU_NATIONAL DESC) AS IDSQL
                FROM OD_NIR_6M_C) a
                WHERE IDSQL=1;
				) BY NETEZZA;
DISCONNECT FROM NETEZZA;
QUIT;
