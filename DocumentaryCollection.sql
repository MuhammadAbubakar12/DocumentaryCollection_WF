MERGE /*+NOPARALLEL*/ INTO DOCMNTRY_COLL_CNTRCT a USING (
/*************** STARTING QUERY TEXT ***************/
WITH LatestEvents AS (
                          SELECT MAX(dcce.coll_event_nb) coll_event_nb,
                                 dcce.doc_coll_cntrct_intrl_id
                            FROM docmntry_coll_cntrct_event dcce
                            GROUP BY doc_coll_cntrct_intrl_id
                                 ),
        BookEvents AS (
                        SELECT dcce.doc_coll_cntrct_intrl_id,
                               FIRST_VALUE(dcce.prdct_type_cd) IGNORE NULLS OVER
                               (PARTITION BY dcce.doc_coll_cntrct_intrl_id
                               ORDER BY dcce.doc_coll_cntrct_event_seq_id desc, dcce.coll_event_nb desc) AS prdct_type_cd,
                               FIRST_VALUE(dcce.prdct_sub_type_cd) IGNORE NULLS OVER
                               (PARTITION BY dcce.doc_coll_cntrct_intrl_id
                               ORDER BY dcce.doc_coll_cntrct_event_seq_id desc, dcce.coll_event_nb desc) AS prdct_sub_type_cd,
                               FIRST_VALUE(dcce.doc_fl) IGNORE NULLS OVER
                               (PARTITION BY dcce.doc_coll_cntrct_intrl_id
                               ORDER BY dcce.doc_coll_cntrct_event_seq_id desc, dcce.coll_event_nb desc) AS doc_fl,
                               FIRST_VALUE(dcce.trd_fin_cntrct_intrl_id) IGNORE NULLS OVER
                               (PARTITION BY dcce.doc_coll_cntrct_intrl_id
                               ORDER BY dcce.doc_coll_cntrct_event_seq_id desc, dcce.coll_event_nb desc) AS trd_fin_cntrct_intrl_id,
                               FIRST_VALUE(dcce.coll_event_dt) IGNORE NULLS OVER
                               (PARTITION BY dcce.doc_coll_cntrct_intrl_id
                               ORDER BY dcce.doc_coll_cntrct_event_seq_id desc, dcce.coll_event_nb desc) AS coll_event_dt,
                               FIRST_VALUE(dcce.coll_event_tm) IGNORE NULLS OVER
                               (PARTITION BY dcce.doc_coll_cntrct_intrl_id
                               ORDER BY dcce.doc_coll_cntrct_event_seq_id desc, dcce.coll_event_nb desc) AS coll_event_tm,
                               FIRST_VALUE(dcce.coll_event_utc_dt) IGNORE NULLS OVER
                               (PARTITION BY dcce.doc_coll_cntrct_intrl_id
                               ORDER BY dcce.doc_coll_cntrct_event_seq_id desc, dcce.coll_event_nb desc) AS coll_event_utc_dt,
                               FIRST_VALUE(dcce.coll_event_utc_tm) IGNORE NULLS OVER
                               (PARTITION BY dcce.doc_coll_cntrct_intrl_id
                               ORDER BY dcce.doc_coll_cntrct_event_seq_id desc, dcce.coll_event_nb desc) AS coll_event_utc_tm,
                               FIRST_VALUE(dcce.val_dt) IGNORE NULLS OVER
                               (PARTITION BY dcce.doc_coll_cntrct_intrl_id
                               ORDER BY dcce.doc_coll_cntrct_event_seq_id desc, dcce.coll_event_nb desc) AS val_dt,
                               FIRST_VALUE(dcce.base_dt) IGNORE NULLS OVER
                               (PARTITION BY dcce.doc_coll_cntrct_intrl_id
                               ORDER BY dcce.doc_coll_cntrct_event_seq_id desc, dcce.coll_event_nb desc) AS base_dt,
                               FIRST_VALUE(dcce.src_sys_cd) IGNORE NULLS OVER
                               (PARTITION BY dcce.doc_coll_cntrct_intrl_id
                               ORDER BY dcce.doc_coll_cntrct_event_seq_id desc, dcce.coll_event_nb desc) AS src_sys_cd
                         FROM docmntry_coll_cntrct_event dcce
                              INNER JOIN LatestEvents LES ON LES.doc_coll_cntrct_intrl_id = DCCE.doc_coll_cntrct_intrl_id
                        WHERE dcce.coll_event_type_cd in ('BOOK', 'AMND', 'INIT','BISS')
                       ),                                 
         ModiEvents AS (
                        SELECT dcce.doc_coll_cntrct_intrl_id,
                               FIRST_VALUE(dcce.coll_event_dt) IGNORE NULLS OVER
                               (PARTITION BY dcce.doc_coll_cntrct_intrl_id
                               ORDER BY dcce.doc_coll_cntrct_event_seq_id desc, dcce.coll_event_nb desc) AS coll_event_dt,
                               FIRST_VALUE(dcce.coll_event_tm) IGNORE NULLS OVER
                               (PARTITION BY dcce.doc_coll_cntrct_intrl_id
                               ORDER BY dcce.doc_coll_cntrct_event_seq_id desc, dcce.coll_event_nb desc) AS coll_event_tm,
                               FIRST_VALUE(dcce.coll_event_utc_dt) IGNORE NULLS OVER
                               (PARTITION BY dcce.doc_coll_cntrct_intrl_id
                               ORDER BY dcce.doc_coll_cntrct_event_seq_id desc, dcce.coll_event_nb desc) AS coll_event_utc_dt,
                               FIRST_VALUE(dcce.coll_event_utc_tm) IGNORE NULLS OVER
                               (PARTITION BY dcce.doc_coll_cntrct_intrl_id
                               ORDER BY dcce.doc_coll_cntrct_event_seq_id desc, dcce.coll_event_nb desc) AS coll_event_utc_tm
                         FROM docmntry_coll_cntrct_event dcce
                              INNER JOIN LatestEvents LES ON LES.doc_coll_cntrct_intrl_id = DCCE.doc_coll_cntrct_intrl_id
                        WHERE dcce.coll_event_type_cd = 'MODI' 
                       ),
        ClosEvents AS (
                        SELECT DCCE.doc_coll_cntrct_intrl_id,
                               FIRST_VALUE(dcce.coll_event_dt) IGNORE NULLS OVER
                               (PARTITION BY dcce.doc_coll_cntrct_intrl_id
                               ORDER BY dcce.doc_coll_cntrct_event_seq_id desc, dcce.coll_event_nb desc) AS coll_event_dt,
                               FIRST_VALUE(dcce.coll_event_utc_dt) IGNORE NULLS OVER
                               (PARTITION BY dcce.doc_coll_cntrct_intrl_id
                               ORDER BY dcce.doc_coll_cntrct_event_seq_id desc, dcce.coll_event_nb desc) AS coll_event_utc_dt,
                               FIRST_VALUE(dcce.coll_event_tm) IGNORE NULLS OVER
                               (PARTITION BY dcce.doc_coll_cntrct_intrl_id
                               ORDER BY dcce.doc_coll_cntrct_event_seq_id desc, dcce.coll_event_nb desc) AS coll_event_tm,
                               FIRST_VALUE(dcce.coll_event_utc_tm) IGNORE NULLS OVER
                               (PARTITION BY dcce.doc_coll_cntrct_intrl_id
                               ORDER BY dcce.doc_coll_cntrct_event_seq_id desc, dcce.coll_event_nb desc) AS coll_event_utc_tm
                         FROM docmntry_coll_cntrct_event dcce
                              INNER JOIN LatestEvents LES ON LES.doc_coll_cntrct_intrl_id = DCCE.doc_coll_cntrct_intrl_id
                        WHERE dcce.coll_event_type_cd = 'CLOS'
                       ),
        CancEvents AS (
                        SELECT DCCE.doc_coll_cntrct_intrl_id,
                               FIRST_VALUE(dcce.coll_event_dt) IGNORE NULLS OVER
                               (PARTITION BY dcce.doc_coll_cntrct_intrl_id
                               ORDER BY dcce.doc_coll_cntrct_event_seq_id desc, dcce.coll_event_nb desc) AS coll_event_dt,
                               FIRST_VALUE(dcce.coll_event_tm) IGNORE NULLS OVER
                               (PARTITION BY dcce.doc_coll_cntrct_intrl_id
                               ORDER BY dcce.doc_coll_cntrct_event_seq_id desc, dcce.coll_event_nb desc) AS coll_event_tm,
                               FIRST_VALUE(dcce.coll_event_utc_dt) IGNORE NULLS OVER
                               (PARTITION BY dcce.doc_coll_cntrct_intrl_id
                               ORDER BY dcce.doc_coll_cntrct_event_seq_id desc, dcce.coll_event_nb desc) AS coll_event_utc_dt,
                               FIRST_VALUE(dcce.coll_event_utc_tm) IGNORE NULLS OVER
                               (PARTITION BY dcce.doc_coll_cntrct_intrl_id
                               ORDER BY dcce.doc_coll_cntrct_event_seq_id desc, dcce.coll_event_nb desc) AS coll_event_utc_tm
                         FROM DOCMNTRY_COLL_CNTRCT_EVENT DCCE
                              INNER JOIN LatestEvents LES ON LES.doc_coll_cntrct_intrl_id = DCCE.doc_coll_cntrct_intrl_id
                        WHERE DCCE.COLL_EVENT_TYPE_CD = 'CANC'
                       ),
        FulfEvents AS (
                        SELECT DCCE.doc_coll_cntrct_intrl_id,
                               FIRST_VALUE(dcce.coll_event_dt) IGNORE NULLS OVER
                               (PARTITION BY dcce.doc_coll_cntrct_intrl_id
                               ORDER BY dcce.doc_coll_cntrct_event_seq_id desc, dcce.coll_event_nb desc) AS coll_event_dt,
                               FIRST_VALUE(dcce.coll_event_tm) IGNORE NULLS OVER
                               (PARTITION BY dcce.doc_coll_cntrct_intrl_id
                               ORDER BY dcce.doc_coll_cntrct_event_seq_id desc, dcce.coll_event_nb desc) AS coll_event_tm,
                               FIRST_VALUE(dcce.coll_event_utc_dt) IGNORE NULLS OVER
                               (PARTITION BY dcce.doc_coll_cntrct_intrl_id
                               ORDER BY dcce.doc_coll_cntrct_event_seq_id desc, dcce.coll_event_nb desc) AS coll_event_utc_dt,
                               FIRST_VALUE(dcce.coll_event_utc_tm) IGNORE NULLS OVER
                               (PARTITION BY dcce.doc_coll_cntrct_intrl_id
                               ORDER BY dcce.doc_coll_cntrct_event_seq_id desc, dcce.coll_event_nb desc) AS coll_event_utc_tm
                         FROM DOCMNTRY_COLL_CNTRCT_EVENT DCCE
                              INNER JOIN LatestEvents LES ON LES.doc_coll_cntrct_intrl_id = DCCE.doc_coll_cntrct_intrl_id
                        WHERE DCCE.COLL_EVENT_TYPE_CD in ('FULF', 'LIQD')
                       ),
        AmndEvents AS (
                        SELECT DCCE.doc_coll_cntrct_intrl_id,
                               FIRST_VALUE(dcce.coll_event_dt) IGNORE NULLS OVER
                               (PARTITION BY dcce.doc_coll_cntrct_intrl_id
                               ORDER BY dcce.doc_coll_cntrct_event_seq_id desc, dcce.coll_event_nb desc) AS coll_event_dt,
                               FIRST_VALUE(dcce.coll_event_tm) IGNORE NULLS OVER
                               (PARTITION BY dcce.doc_coll_cntrct_intrl_id
                               ORDER BY dcce.doc_coll_cntrct_event_seq_id desc, dcce.coll_event_nb desc) AS coll_event_tm,
                               FIRST_VALUE(dcce.coll_event_utc_dt) IGNORE NULLS OVER
                               (PARTITION BY dcce.doc_coll_cntrct_intrl_id
                               ORDER BY dcce.doc_coll_cntrct_event_seq_id desc, dcce.coll_event_nb desc) AS coll_event_utc_dt,
                               FIRST_VALUE(dcce.coll_event_utc_tm) IGNORE NULLS OVER
                               (PARTITION BY dcce.doc_coll_cntrct_intrl_id
                               ORDER BY dcce.doc_coll_cntrct_event_seq_id desc, dcce.coll_event_nb desc) AS coll_event_utc_tm
                         FROM DOCMNTRY_COLL_CNTRCT_EVENT DCCE
                              INNER JOIN LatestEvents LES ON LES.doc_coll_cntrct_intrl_id = DCCE.doc_coll_cntrct_intrl_id
                        WHERE DCCE.COLL_EVENT_TYPE_CD = 'AMND'
                       ),
        RefuEvents AS (
                        SELECT DCCE.doc_coll_cntrct_intrl_id,
                               FIRST_VALUE(dcce.coll_event_dt) IGNORE NULLS OVER
                               (PARTITION BY dcce.doc_coll_cntrct_intrl_id
                               ORDER BY dcce.doc_coll_cntrct_event_seq_id desc, dcce.coll_event_nb desc) AS coll_event_dt,
                               FIRST_VALUE(dcce.coll_event_tm) IGNORE NULLS OVER
                               (PARTITION BY dcce.doc_coll_cntrct_intrl_id
                               ORDER BY dcce.doc_coll_cntrct_event_seq_id desc, dcce.coll_event_nb desc) AS coll_event_tm,
                               FIRST_VALUE(dcce.coll_event_utc_dt) IGNORE NULLS OVER
                               (PARTITION BY dcce.doc_coll_cntrct_intrl_id
                               ORDER BY dcce.doc_coll_cntrct_event_seq_id desc, dcce.coll_event_nb desc) AS coll_event_utc_dt,
                               FIRST_VALUE(dcce.coll_event_utc_tm) IGNORE NULLS OVER
                               (PARTITION BY dcce.doc_coll_cntrct_intrl_id
                               ORDER BY dcce.doc_coll_cntrct_event_seq_id desc, dcce.coll_event_nb desc) AS coll_event_utc_tm
                         FROM DOCMNTRY_COLL_CNTRCT_EVENT DCCE
                              INNER JOIN LatestEvents LES ON LES.doc_coll_cntrct_intrl_id = DCCE.doc_coll_cntrct_intrl_id
                        WHERE DCCE.COLL_EVENT_TYPE_CD = 'REFU'
                       ),
        BookORAmndEvents AS (
                        SELECT DCCE.doc_coll_cntrct_intrl_id,
                               FIRST_VALUE(dcce.snd_rcv_info_tx) IGNORE NULLS OVER
                               (PARTITION BY dcce.doc_coll_cntrct_intrl_id
                               ORDER BY dcce.doc_coll_cntrct_event_seq_id desc, dcce.coll_event_nb desc) AS snd_rcv_info_tx,
                               FIRST_VALUE(dcce.multitnr_fl) IGNORE NULLS OVER
                               (PARTITION BY dcce.doc_coll_cntrct_intrl_id
                               ORDER BY dcce.doc_coll_cntrct_event_seq_id desc, dcce.coll_event_nb desc) AS multitnr_fl,
                               FIRST_VALUE(dcce.maturity_dt) IGNORE NULLS OVER
                               (PARTITION BY dcce.doc_coll_cntrct_intrl_id
                               ORDER BY dcce.doc_coll_cntrct_event_seq_id desc, dcce.coll_event_nb desc) AS maturity_dt,
                               FIRST_VALUE(dcce.tnr_days) IGNORE NULLS OVER
                               (PARTITION BY dcce.doc_coll_cntrct_intrl_id
                               ORDER BY dcce.doc_coll_cntrct_event_seq_id desc, dcce.coll_event_nb desc) AS tnr_days,
                               FIRST_VALUE(dcce.trnst_days) IGNORE NULLS OVER
                               (PARTITION BY dcce.doc_coll_cntrct_intrl_id
                               ORDER BY dcce.doc_coll_cntrct_event_seq_id desc, dcce.coll_event_nb desc) AS trnst_days,
                               FIRST_VALUE(dcce.paymt_mthd_cd) IGNORE NULLS OVER
                               (PARTITION BY dcce.doc_coll_cntrct_intrl_id
                               ORDER BY dcce.doc_coll_cntrct_event_seq_id desc, dcce.coll_event_nb desc) AS paymt_mthd_cd,
                               FIRST_VALUE(dcce.prncl_amt) IGNORE NULLS OVER
                               (PARTITION BY dcce.doc_coll_cntrct_intrl_id
                               ORDER BY dcce.doc_coll_cntrct_event_seq_id desc, dcce.coll_event_nb desc) AS prncl_amt,
                               FIRST_VALUE(dcce.tot_cmsn_charge_amt) IGNORE NULLS OVER
                               (PARTITION BY dcce.doc_coll_cntrct_intrl_id
                               ORDER BY dcce.doc_coll_cntrct_event_seq_id desc, dcce.coll_event_nb desc) AS tot_cmsn_charge_amt,
                               FIRST_VALUE(dcce.orig_benef_charge_cd) IGNORE NULLS OVER
                               (PARTITION BY dcce.doc_coll_cntrct_intrl_id
                               ORDER BY dcce.doc_coll_cntrct_event_seq_id desc, dcce.coll_event_nb desc) AS orig_benef_charge_cd,
                               FIRST_VALUE(dcce.tot_coll_amt) IGNORE NULLS OVER
                               (PARTITION BY dcce.doc_coll_cntrct_intrl_id
                               ORDER BY dcce.doc_coll_cntrct_event_seq_id desc, dcce.coll_event_nb desc) AS tot_coll_amt,
                               FIRST_VALUE(dcce.coll_crncy_cd) IGNORE NULLS OVER
                               (PARTITION BY dcce.doc_coll_cntrct_intrl_id
                               ORDER BY dcce.doc_coll_cntrct_event_seq_id desc, dcce.coll_event_nb desc) AS coll_crncy_cd,
                               --DCCE.prncl_amt,
                               FIRST_VALUE(dcce.extrl_nsrnc_plcy_intrl_id) IGNORE NULLS OVER
                               (PARTITION BY dcce.doc_coll_cntrct_intrl_id
                               ORDER BY dcce.doc_coll_cntrct_event_seq_id desc, dcce.coll_event_nb desc) AS extrl_nsrnc_plcy_intrl_id,
                               FIRST_VALUE(dcce.prncl_actvy_amt) IGNORE NULLS OVER
                               (PARTITION BY dcce.doc_coll_cntrct_intrl_id
                               ORDER BY dcce.doc_coll_cntrct_event_seq_id desc, dcce.coll_event_nb desc) AS prncl_actvy_amt,
                               FIRST_VALUE(dcce.tot_cmsn_charge_actvy_amt) IGNORE NULLS OVER
                               (PARTITION BY dcce.doc_coll_cntrct_intrl_id
                               ORDER BY dcce.doc_coll_cntrct_event_seq_id desc, dcce.coll_event_nb desc) AS tot_cmsn_charge_actvy_amt,
                               FIRST_VALUE(dcce.tot_coll_actvy_amt) IGNORE NULLS OVER
                               (PARTITION BY dcce.doc_coll_cntrct_intrl_id
                               ORDER BY dcce.doc_coll_cntrct_event_seq_id desc, dcce.coll_event_nb desc) AS tot_coll_actvy_amt
                         FROM DOCMNTRY_COLL_CNTRCT_EVENT DCCE
                              INNER JOIN LatestEvents LES ON LES.doc_coll_cntrct_intrl_id = DCCE.doc_coll_cntrct_intrl_id
                        WHERE DCCE.COLL_EVENT_TYPE_CD in ('BOOK','AMND', 'INIT', 'BISS')
                       ),
        BookORModiEvents AS (
                        SELECT DCCE.doc_coll_cntrct_intrl_id,
                               FIRST_VALUE(dcce.prdct_type_cd) IGNORE NULLS OVER
                               (PARTITION BY dcce.doc_coll_cntrct_intrl_id
                               ORDER BY dcce.doc_coll_cntrct_event_seq_id desc, dcce.coll_event_nb desc) AS prdct_type_cd,
                               FIRST_VALUE(dcce.oprtn_cd) IGNORE NULLS OVER
                               (PARTITION BY dcce.doc_coll_cntrct_intrl_id
                               ORDER BY dcce.doc_coll_cntrct_event_seq_id desc, dcce.coll_event_nb desc) AS oprtn_cd,
                               FIRST_VALUE(dcce.cntrct_entry_user_id) IGNORE NULLS OVER
                               (PARTITION BY dcce.doc_coll_cntrct_intrl_id
                               ORDER BY dcce.doc_coll_cntrct_event_seq_id desc, dcce.coll_event_nb desc) AS cntrct_entry_user_id,
                               FIRST_VALUE(dcce.cntrct_entry_sys_logon_id) IGNORE NULLS OVER
                               (PARTITION BY dcce.doc_coll_cntrct_intrl_id
                               ORDER BY dcce.doc_coll_cntrct_event_seq_id desc, dcce.coll_event_nb desc) AS cntrct_entry_sys_logon_id,
                               FIRST_VALUE(dcce.purch_adv_disc_amt) IGNORE NULLS OVER
                               (PARTITION BY dcce.doc_coll_cntrct_intrl_id
                               ORDER BY dcce.doc_coll_cntrct_event_seq_id desc, dcce.coll_event_nb desc) AS purch_adv_disc_amt,
                               FIRST_VALUE(dcce.loan_id) IGNORE NULLS OVER
                               (PARTITION BY dcce.doc_coll_cntrct_intrl_id
                               ORDER BY dcce.doc_coll_cntrct_event_seq_id desc, dcce.coll_event_nb desc) AS loan_id,
                               FIRST_VALUE(dcce.purch_adv_disc_actvy_amt) IGNORE NULLS OVER
                               (PARTITION BY dcce.doc_coll_cntrct_intrl_id
                               ORDER BY dcce.doc_coll_cntrct_event_seq_id desc, dcce.coll_event_nb desc) AS purch_adv_disc_actvy_amt
                         FROM DOCMNTRY_COLL_CNTRCT_EVENT DCCE
                              INNER JOIN LatestEvents LES ON LES.doc_coll_cntrct_intrl_id = DCCE.doc_coll_cntrct_intrl_id
                        WHERE DCCE.COLL_EVENT_TYPE_CD in ('BOOK','MODI','INIT','BISS')
                       ), 
        NotCCFEvents AS (
                        SELECT DCCE.doc_coll_cntrct_intrl_id,
                               FIRST_VALUE(dcce.brnch_id) IGNORE NULLS OVER
                               (PARTITION BY dcce.doc_coll_cntrct_intrl_id
                               ORDER BY dcce.doc_coll_cntrct_event_seq_id desc, dcce.coll_event_nb desc) AS brnch_id
                         FROM DOCMNTRY_COLL_CNTRCT_EVENT DCCE
                              INNER JOIN LatestEvents LES ON LES.doc_coll_cntrct_intrl_id = DCCE.doc_coll_cntrct_intrl_id
                        WHERE DCCE.COLL_EVENT_TYPE_CD NOT in ('CLOS', 'CANC','FULF', 'LIQD')
                       ),
        LastEventType AS (
                     SELECT DCCE.doc_coll_cntrct_intrl_id,
                            DCCE.coll_event_type_cd
                       FROM DOCMNTRY_COLL_CNTRCT_EVENT DCCE
                            INNER JOIN LatestEvents LE ON LE.doc_coll_cntrct_intrl_id = DCCE.doc_coll_cntrct_intrl_id
                                                    AND LE.coll_event_nb = DCCE.coll_event_nb 
                       )               
                       SELECT
                            DCCE.doc_coll_cntrct_intrl_id DOC_COLL_CNTRCT_INTRL_ID,
                            MAX(LET.coll_event_type_cd) LAST_COLL_EVENT_TYPE_CD,
                            MAX(CCFE.brnch_id) BRNCH_ID,
                            MAX(BES.prdct_type_cd) PRDCT_TYPE_CD,
                            MAX(BES.prdct_sub_type_cd) PRDCT_SUB_TYPE_CD,
                            MAX(BES.doc_fl) DOC_FL,
                            MAX(BAES.multitnr_fl) LAST_MULTITNR_FL,
                                          (CASE WHEN MAX(BMES.prdct_type_cd) in ('IDC', 'IOC','IGC', 'DFC','IOL')
                                                         AND MAX(BMES.oprtn_cd) in ('ADVAN','PYMNT','COLLE','ACCEP','DISCO')
                                                  THEN MAX(BMES.oprtn_cd)
                                                  WHEN MAX(BMES.prdct_type_cd) in ('EDC','AVL','ADL', 'ICL','IBC')
                                                         AND MAX(BMES.oprtn_cd) in ('NEGOT','PYMNT','COLLE','ACCEP','DISCO','PURCH')
                                                  THEN MAX(BMES.oprtn_cd)
                                                  ELSE NULL
                                  END) LAST_OPERATION,
                                          MAX(MES.coll_event_dt) LAST_MODIFIED_DT,
                            MAX(MES.coll_event_tm) LAST_MODIFIED_TM,
                            MAX(MES.coll_event_utc_dt) LAST_MODIFIED_UTC_DT,
                            MAX(MES.coll_event_utc_tm) LAST_MODIFIED_UTC_TM,
                            MAX(BES.trd_fin_cntrct_intrl_id) TRD_FIN_CNTRCT_INTRL_ID,
                            MAX(BES.coll_event_dt) BOOK_DT,
                            MAX(BES.coll_event_tm) BOOK_TM,
                            MAX(BES.coll_event_utc_dt) BOOK_UTC_DT,
                            MAX(BES.coll_event_utc_tm) BOOK_UTC_TM,
                            MAX(BES.val_dt) VAL_DT,
                            MAX(BES.base_dt) BASE_DT,
                            MAX(BAES.maturity_dt) LAST_MATURITY_DT,
                            MAX(CES.coll_event_dt) CLOSED_DT,
                            MAX(CES.coll_event_utc_dt) CLOSED_UTC_DT,
                            MAX(CES.coll_event_tm) CLOSED_TM,
                            MAX(CES.coll_event_utc_tm) CLOSED_UTC_TM,
                            MAX(CAES.coll_event_dt) CNCLD_DT,
                            MAX(CAES.coll_event_tm) CNCLD_TM,
                            MAX(CAES.coll_event_utc_dt) CNCLD_UTC_DT,
                            MAX(CAES.coll_event_utc_tm) CNCLD_UTC_TM,
                            MAX(FES.coll_event_dt) FULLFLD_DT,
                            MAX(FES.coll_event_utc_dt) FULLFLD_UTC_DT,
                            MAX(FES.coll_event_tm) FULLFLD_TM,
                            MAX(FES.coll_event_utc_tm) FULLFLD_UTC_TM,
                            MAX(BAES.tnr_days) LAST_TNR_DAYS,
                            MAX(BAES.trnst_days) LAST_TRNST_DAYS,
                            MAX(BAES.paymt_mthd_cd) LAST_PAYMT_MTHD_CD,
                            MAX(BAES.prncl_amt) LAST_PRNCL_AMT,
                            MAX(BAES.tot_cmsn_charge_amt) LAST_TOT_CMSN_CHARGE_AMT,
                            MAX(BAES.orig_benef_charge_cd) LAST_ORIG_BENEF_CHARGE_CD,
                            MAX(BAES.tot_coll_amt) LAST_TOT_COLL_AMT,
                            MAX(BAES.coll_crncy_cd) LAST_COLL_CRNCY_CD,
                            --TotalLiquidationAmount TOT_LIQUIDATION_AMT
                            --LatestLiquidationDate  LAST_LIQUIDATION_DT
                            MAX(BMES.purch_adv_disc_amt) LAST_PURCH_ADV_DISC_AMT,
                            MAX(BMES.loan_id) LAST_LOAN_ID,
                            MAX(BAES.prncl_amt) LAST_REBATE_AMT,
                            MAX(DCCE.accpt_dt) ACCPT_DT,
                            MAX(DCCE.accptd_tot_coll_amt) ACCPTD_TOT_COLL_AMT,
                                          MAX(DCCE.accptd_coll_crncy_cd) ACCPTD_COLL_CRNCY_CD,
                            MAX(DCCE.accptd_maturity_dt) ACCPTD_MATURITY_DT,
                            MAX(DCCE.accptd_info_tx) ACCPTD_INFO_TX,
                            MAX(RES.coll_event_dt) LAST_REFUSAL_DT,
                            MAX(RES.coll_event_tm) LAST_REFUSAL_TM,
                            MAX(RES.coll_event_utc_dt) LAST_REFUSAL_UTC_DT,
                            MAX(RES.coll_event_utc_tm) LAST_REFUSAL_UTC_TM,
                            MAX(BAES.snd_rcv_info_tx) LAST_SND_RCV_INFO_TX,
                            MAX(BMES.cntrct_entry_sys_logon_id) CNTRCT_ENTRY_SYS_LOGON_ID,
                            MAX(BMES.cntrct_entry_user_id) CNTRCT_ENTRY_USER_ID,
                            MAX(BAES.extrl_nsrnc_plcy_intrl_id) EXTRL_NSRNC_PLCY_INTRL_ID,
                            MAX(DCCE.cstm_1_dt) LAST_CSTM_1_DT,  
                            MAX(DCCE.cstm_2_dt) LAST_CSTM_2_DT,
                            MAX(DCCE.cstm_3_dt) LAST_CSTM_3_DT,
                            MAX(DCCE.cstm_1_rl) LAST_CSTM_1_RL,
                            MAX(DCCE.cstm_2_rl) LAST_CSTM_2_RL,
                            MAX(DCCE.cstm_3_rl) LAST_CSTM_3_RL,
                            MAX(DCCE.cstm_1_tx) LAST_CSTM_1_TX,
                            MAX(DCCE.cstm_2_tx) LAST_CSTM_2_TX,
                            MAX(DCCE.cstm_3_tx) LAST_CSTM_3_TX,
                            MAX(DCCE.cstm_4_tx) LAST_CSTM_4_TX,
                            MAX(DCCE.cstm_5_tx) LAST_CSTM_5_TX,
                            (SELECT MAX(EVENT_NB)
                                   FROM TRADE_FIN_GOOD_SRVC
                                  WHERE doc_coll_cntrct_intrl_id = DCCE.doc_coll_cntrct_intrl_id) LAST_TRD_FIN_GOODSRVC_EVENT_NB,
                            (SELECT MAX(EVENT_NB)
                                   FROM TRADE_FIN_DOC
                                  WHERE doc_coll_cntrct_intrl_id = DCCE.doc_coll_cntrct_intrl_id) LAST_TRD_FIN_DOC_EVENT_NB,                                                                                              
                            (SELECT MAX(EVENT_NB)
                               FROM TRADE_FIN_PARTY
                              WHERE doc_coll_cntrct_intrl_id = DCCE.doc_coll_cntrct_intrl_id) LAST_TRD_FIN_PARTY_EVENT_NB,
                            MAX(BES.src_sys_cd) LAST_SRC_SYS_CD,
                            MAX(BAES.prncl_actvy_amt) LAST_PRNCL_ACTVY_AMT,
                            MAX(BAES.tot_cmsn_charge_actvy_amt) LAST_TOT_CMSN_CHARGE_ACTVY_AMT,
                            MAX(BAES.prncl_actvy_amt) LAST_REBATE_ACTVY_AMT,
                            MAX(BAES.tot_coll_actvy_amt) LAST_TOT_COLL_ACTVY_AMT,
                            MAX(BMES.purch_adv_disc_actvy_amt) LAST_PURCH_ADV_DISC_ACTVY_AMT,
                            MAX(to_char(DCCE.GOOD_SRVC_DESC_TX)) as LAST_GOOD_SRVC_DESC_TX,
                            MAX(DCCE.CHANL_CD) as LAST_CHANL_CD,
                            MAX(DCCE.CHANL_RISK_NB) as LAST_CHANL_RISK_NB,
                            MAX(DCCE.PRDCT_RISK_NB) as LAST_PRDCT_RISK_NB,
                            MAX(DCCE.ACTVY_RISK_NB) as LAST_ACTVY_RISK_NB,
                            MAX(DCCE.ACCPTD_TOT_COLL_ACTVY_AMT) ACCPTD_TOT_COLL_ACTVY_AMT,
                            --MAX(DCCE.prcsng_batch_nm) LAST_PRCSNG_BATCH_NM,
                            --SYSDATE LAST_DATA_DUMP_DT,
                            MAX(AES.coll_event_dt) LAST_AMD_DT,
                            MAX(AES.coll_event_tm) LAST_AMD_TM,
                            MAX(AES.coll_event_utc_dt) LAST_AMD_UTC_DT,
                            MAX(AES.coll_event_utc_tm) LAST_AMD_UTC_TM
                       FROM DOCMNTRY_COLL_CNTRCT_EVENT DCCE
                            LEFT OUTER JOIN LatestEvents LES ON DCCE.doc_coll_cntrct_intrl_id = LES.doc_coll_cntrct_intrl_id
                            LEFT OUTER JOIN BookEvents   BES ON DCCE.doc_coll_cntrct_intrl_id = BES.doc_coll_cntrct_intrl_id
                            LEFT OUTER JOIN ModiEvents   MES ON DCCE.doc_coll_cntrct_intrl_id = MES.doc_coll_cntrct_intrl_id
                            LEFT OUTER JOIN ClosEvents   CES ON DCCE.doc_coll_cntrct_intrl_id = CES.doc_coll_cntrct_intrl_id
                            LEFT OUTER JOIN CancEvents  CAES ON DCCE.doc_coll_cntrct_intrl_id = CAES.doc_coll_cntrct_intrl_id
                            LEFT OUTER JOIN FulfEvents   FES ON DCCE.doc_coll_cntrct_intrl_id = FES.doc_coll_cntrct_intrl_id
                            LEFT OUTER JOIN AmndEvents   AES ON DCCE.doc_coll_cntrct_intrl_id = AES.doc_coll_cntrct_intrl_id
                            LEFT OUTER JOIN RefuEvents   RES ON DCCE.doc_coll_cntrct_intrl_id = AES.doc_coll_cntrct_intrl_id
                            LEFT OUTER JOIN BookORAmndEvents BAES ON DCCE.doc_coll_cntrct_intrl_id = BAES.doc_coll_cntrct_intrl_id
                            LEFT OUTER JOIN BookORModiEvents BMES ON DCCE.doc_coll_cntrct_intrl_id = BMES.doc_coll_cntrct_intrl_id 
                            LEFT OUTER JOIN NotCCFEvents CCFE ON DCCE.doc_coll_cntrct_intrl_id = CCFE.doc_coll_cntrct_intrl_id   
                            LEFT OUTER JOIN LastEventType LET ON DCCE.doc_coll_cntrct_intrl_id = LET.doc_coll_cntrct_intrl_id                           
                       GROUP BY DCCE.DOC_COLL_CNTRCT_INTRL_ID
/*************** ENDING QUERY TEXT  ****************/
) b ON (
a.DOC_COLL_CNTRCT_INTRL_ID = b.DOC_COLL_CNTRCT_INTRL_ID
) WHEN MATCHED THEN UPDATE SET
a.LAST_COLL_EVENT_TYPE_CD = SUBSTR(b.LAST_COLL_EVENT_TYPE_CD,1,4),
a.BRNCH_ID = SUBSTR(b.BRNCH_ID,1,50),
a.PRDCT_TYPE_CD = SUBSTR(b.PRDCT_TYPE_CD,1,3),
a.PRDCT_SUB_TYPE_CD = SUBSTR(b.PRDCT_SUB_TYPE_CD,1,20),
a.DOC_FL = SUBSTR(b.DOC_FL,1,1),
a.LAST_MULTITNR_FL = b.LAST_MULTITNR_FL,
a.LAST_OPERATION = SUBSTR(b.LAST_OPERATION,1,5),
a.LAST_MODIFIED_DT = b.LAST_MODIFIED_DT,
a.LAST_MODIFIED_TM = b.LAST_MODIFIED_TM,
a.LAST_MODIFIED_UTC_DT = b.LAST_MODIFIED_UTC_DT,
a.LAST_MODIFIED_UTC_TM = b.LAST_MODIFIED_UTC_TM,
a.TRD_FIN_CNTRCT_INTRL_ID = SUBSTR(b.TRD_FIN_CNTRCT_INTRL_ID,1,16),
a.BOOK_DT = b.BOOK_DT,
a.BOOK_TM = b.BOOK_TM,
a.BOOK_UTC_DT = b.BOOK_UTC_DT,
a.BOOK_UTC_TM = b.BOOK_UTC_TM,
a.VAL_DT = b.VAL_DT,
a.BASE_DT = b.BASE_DT,
a.LAST_MATURITY_DT = b.LAST_MATURITY_DT,
a.CLOSED_DT = b.CLOSED_DT,
a.CLOSED_UTC_DT = b.CLOSED_UTC_DT,
a.CLOSED_TM = b.CLOSED_TM,
a.CLOSED_UTC_TM = b.CLOSED_UTC_TM,
a.CNCLD_DT = b.CNCLD_DT,
a.CNCLD_TM = b.CNCLD_TM,
a.CNCLD_UTC_DT = b.CNCLD_UTC_DT,
a.CNCLD_UTC_TM = b.CNCLD_UTC_TM,
a.FULLFLD_DT = b.FULLFLD_DT,
a.FULLFLD_UTC_DT = b.FULLFLD_UTC_DT,
a.FULLFLD_TM = b.FULLFLD_TM,
a.FULLFLD_UTC_TM = b.FULLFLD_UTC_TM,
a.LAST_TNR_DAYS = GREATEST(LEAST(b.LAST_TNR_DAYS,9999),-9999),
a.LAST_TRNST_DAYS = GREATEST(LEAST(b.LAST_TRNST_DAYS,9999),-9999),
a.LAST_PAYMT_MTHD_CD = SUBSTR(b.LAST_PAYMT_MTHD_CD,1,1),
a.LAST_PRNCL_AMT = GREATEST(LEAST(b.LAST_PRNCL_AMT,1.0E20),-1.0E20),
a.LAST_TOT_CMSN_CHARGE_AMT = GREATEST(LEAST(b.LAST_TOT_CMSN_CHARGE_AMT,1.0E20),-1.0E20),
a.LAST_ORIG_BENEF_CHARGE_CD = SUBSTR(b.LAST_ORIG_BENEF_CHARGE_CD,1,1),
a.LAST_TOT_COLL_AMT = GREATEST(LEAST(b.LAST_TOT_COLL_AMT,1.0E20),-1.0E20),
a.LAST_COLL_CRNCY_CD = SUBSTR(b.LAST_COLL_CRNCY_CD,1,3),
a.LAST_PURCH_ADV_DISC_AMT = GREATEST(LEAST(b.LAST_PURCH_ADV_DISC_AMT,1.0E20),-1.0E20),
a.LAST_LOAN_ID = SUBSTR(b.LAST_LOAN_ID,1,50),
a.LAST_REBATE_AMT = GREATEST(LEAST(b.LAST_REBATE_AMT,1.0E20),-1.0E20),
a.ACCPT_DT = b.ACCPT_DT,
a.ACCPTD_TOT_COLL_AMT = GREATEST(LEAST(b.ACCPTD_TOT_COLL_AMT,1.0E20),-1.0E20),
a.ACCPTD_COLL_CRNCY_CD = SUBSTR(b.ACCPTD_COLL_CRNCY_CD,1,3),
a.ACCPTD_MATURITY_DT = b.ACCPTD_MATURITY_DT,
a.ACCPTD_INFO_TX = SUBSTR(b.ACCPTD_INFO_TX,1,255),
a.LAST_REFUSAL_DT = b.LAST_REFUSAL_DT,
a.LAST_REFUSAL_TM = b.LAST_REFUSAL_TM,
a.LAST_REFUSAL_UTC_DT = b.LAST_REFUSAL_UTC_DT,
a.LAST_REFUSAL_UTC_TM = b.LAST_REFUSAL_UTC_TM,
a.LAST_SND_RCV_INFO_TX = SUBSTR(b.LAST_SND_RCV_INFO_TX,1,250),
a.CNTRCT_ENTRY_SYS_LOGON_ID = SUBSTR(b.CNTRCT_ENTRY_SYS_LOGON_ID,1,50),
a.CNTRCT_ENTRY_USER_ID = SUBSTR(b.CNTRCT_ENTRY_USER_ID,1,50),
a.EXTRL_NSRNC_PLCY_INTRL_ID = SUBSTR(b.EXTRL_NSRNC_PLCY_INTRL_ID,1,50),
a.LAST_CSTM_1_DT = b.LAST_CSTM_1_DT,
a.LAST_CSTM_2_DT = b.LAST_CSTM_2_DT,
a.LAST_CSTM_3_DT = b.LAST_CSTM_3_DT,
a.LAST_CSTM_1_RL = GREATEST(LEAST(b.LAST_CSTM_1_RL,1.0E20),-1.0E20),
a.LAST_CSTM_2_RL = GREATEST(LEAST(b.LAST_CSTM_2_RL,1.0E20),-1.0E20),
a.LAST_CSTM_3_RL = GREATEST(LEAST(b.LAST_CSTM_3_RL,1.0E20),-1.0E20),
a.LAST_CSTM_1_TX = SUBSTR(b.LAST_CSTM_1_TX,1,255),
a.LAST_CSTM_2_TX = SUBSTR(b.LAST_CSTM_2_TX,1,255),
a.LAST_CSTM_3_TX = SUBSTR(b.LAST_CSTM_3_TX,1,255),
a.LAST_CSTM_4_TX = SUBSTR(b.LAST_CSTM_4_TX,1,255),
a.LAST_CSTM_5_TX = SUBSTR(b.LAST_CSTM_5_TX,1,255),
a.LAST_SRC_SYS_CD = SUBSTR(b.LAST_SRC_SYS_CD,1,3),
a.LAST_PRCSNG_BATCH_NM = 'DLY',
a.LAST_DATA_DUMP_DT = TO_DATE('20230510', 'YYYYMMDD'),
a.LAST_AMD_DT = b.LAST_AMD_DT,
a.LAST_AMD_TM = b.LAST_AMD_TM,
a.LAST_AMD_UTC_DT = b.LAST_AMD_UTC_DT,
a.LAST_AMD_UTC_TM = b.LAST_AMD_UTC_TM,
a.LAST_TRD_FIN_GOODSRVC_EVENT_NB = GREATEST(LEAST(b.LAST_TRD_FIN_GOODSRVC_EVENT_NB,9999999999),-9999999999),
a.LAST_TRD_FIN_DOC_EVENT_NB = GREATEST(LEAST(b.LAST_TRD_FIN_DOC_EVENT_NB,9999999999),-9999999999),
a.LAST_TRD_FIN_PARTY_EVENT_NB = GREATEST(LEAST(b.LAST_TRD_FIN_PARTY_EVENT_NB,9999999999),-9999999999),
a.LAST_PRNCL_ACTVY_AMT = GREATEST(LEAST(b.LAST_PRNCL_ACTVY_AMT,1.0E20),-1.0E20),
a.LAST_TOT_CMSN_CHARGE_ACTVY_AMT = GREATEST(LEAST(b.LAST_TOT_CMSN_CHARGE_ACTVY_AMT,1.0E20),-1.0E20),
a.LAST_REBATE_ACTVY_AMT = GREATEST(LEAST(b.LAST_REBATE_ACTVY_AMT,1.0E20),-1.0E20),
a.LAST_TOT_COLL_ACTVY_AMT = GREATEST(LEAST(b.LAST_TOT_COLL_ACTVY_AMT,1.0E20),-1.0E20),
a.LAST_PURCH_ADV_DISC_ACTVY_AMT = GREATEST(LEAST(b.LAST_PURCH_ADV_DISC_ACTVY_AMT,1.0E20),-1.0E20),
a.LAST_GOOD_SRVC_DESC_TX = SUBSTR(b.LAST_GOOD_SRVC_DESC_TX,1,-1),
a.LAST_CHANL_CD = SUBSTR(b.LAST_CHANL_CD,1,20),
a.LAST_CHANL_RISK_NB = GREATEST(LEAST(b.LAST_CHANL_RISK_NB,999),-999),
a.LAST_PRDCT_RISK_NB = GREATEST(LEAST(b.LAST_PRDCT_RISK_NB,999),-999),
a.LAST_ACTVY_RISK_NB = NVL(GREATEST(LEAST(b.LAST_ACTVY_RISK_NB,999),-999),0),
a.ACCPTD_TOT_COLL_ACTVY_AMT = GREATEST(LEAST(b.ACCPTD_TOT_COLL_ACTVY_AMT,1.0E20),-1.0E20) WHEN NOT MATCHED THEN INSERT (
a.DOC_COLL_CNTRCT_SEQ_ID,
a.DOC_COLL_CNTRCT_INTRL_ID,
a.LAST_COLL_EVENT_TYPE_CD,
a.BRNCH_ID,
a.PRDCT_TYPE_CD,
a.PRDCT_SUB_TYPE_CD,
a.DOC_FL,
a.LAST_MULTITNR_FL,
a.LAST_OPERATION,
a.LAST_MODIFIED_DT,
a.LAST_MODIFIED_TM,
a.LAST_MODIFIED_UTC_DT,
a.LAST_MODIFIED_UTC_TM,
a.TRD_FIN_CNTRCT_INTRL_ID,
a.BOOK_DT,
a.BOOK_TM,
a.BOOK_UTC_DT,
a.BOOK_UTC_TM,
a.VAL_DT,
a.BASE_DT,
a.LAST_MATURITY_DT,
a.CLOSED_DT,
a.CLOSED_UTC_DT,
a.CLOSED_TM,
a.CLOSED_UTC_TM,
a.CNCLD_DT,
a.CNCLD_TM,
a.CNCLD_UTC_DT,
a.CNCLD_UTC_TM,
a.FULLFLD_DT,
a.FULLFLD_UTC_DT,
a.FULLFLD_TM,
a.FULLFLD_UTC_TM,
a.LAST_TNR_DAYS,
a.LAST_TRNST_DAYS,
a.LAST_PAYMT_MTHD_CD,
a.LAST_PRNCL_AMT,
a.LAST_TOT_CMSN_CHARGE_AMT,
a.LAST_ORIG_BENEF_CHARGE_CD,
a.LAST_TOT_COLL_AMT,
a.LAST_COLL_CRNCY_CD,
a.LAST_PURCH_ADV_DISC_AMT,
a.LAST_LOAN_ID,
a.LAST_REBATE_AMT,
a.ACCPT_DT,
a.ACCPTD_TOT_COLL_AMT,
a.ACCPTD_COLL_CRNCY_CD,
a.ACCPTD_MATURITY_DT,
a.ACCPTD_INFO_TX,
a.LAST_REFUSAL_DT,
a.LAST_REFUSAL_TM,
a.LAST_REFUSAL_UTC_DT,
a.LAST_REFUSAL_UTC_TM,
a.LAST_SND_RCV_INFO_TX,
a.CNTRCT_ENTRY_SYS_LOGON_ID,
a.CNTRCT_ENTRY_USER_ID,
a.EXTRL_NSRNC_PLCY_INTRL_ID,
a.LAST_CSTM_1_DT,
a.LAST_CSTM_2_DT,
a.LAST_CSTM_3_DT,
a.LAST_CSTM_1_RL,
a.LAST_CSTM_2_RL,
a.LAST_CSTM_3_RL,
a.LAST_CSTM_1_TX,
a.LAST_CSTM_2_TX,
a.LAST_CSTM_3_TX,
a.LAST_CSTM_4_TX,
a.LAST_CSTM_5_TX,
a.LAST_SRC_SYS_CD,
a.LAST_PRCSNG_BATCH_NM,
a.LAST_DATA_DUMP_DT,
a.LAST_AMD_DT,
a.LAST_AMD_TM,
a.LAST_AMD_UTC_DT,
a.LAST_AMD_UTC_TM,
a.LAST_TRD_FIN_GOODSRVC_EVENT_NB,
a.LAST_TRD_FIN_DOC_EVENT_NB,
a.LAST_TRD_FIN_PARTY_EVENT_NB,
a.LAST_PRNCL_ACTVY_AMT,
a.LAST_TOT_CMSN_CHARGE_ACTVY_AMT,
a.LAST_REBATE_ACTVY_AMT,
a.LAST_TOT_COLL_ACTVY_AMT,
a.LAST_PURCH_ADV_DISC_ACTVY_AMT,
a.LAST_GOOD_SRVC_DESC_TX,
a.LAST_CHANL_CD,
a.LAST_CHANL_RISK_NB,
a.LAST_PRDCT_RISK_NB,
a.LAST_ACTVY_RISK_NB,
a.ACCPTD_TOT_COLL_ACTVY_AMT
) VALUES (
SQ_DOCMNTRY_COLL_CNTRCT.nextval,
SUBSTR(b.DOC_COLL_CNTRCT_INTRL_ID,1,16),
SUBSTR(b.LAST_COLL_EVENT_TYPE_CD,1,4),
SUBSTR(b.BRNCH_ID,1,50),
SUBSTR(b.PRDCT_TYPE_CD,1,3),
SUBSTR(b.PRDCT_SUB_TYPE_CD,1,20),
SUBSTR(b.DOC_FL,1,1),
b.LAST_MULTITNR_FL,
SUBSTR(b.LAST_OPERATION,1,5),
b.LAST_MODIFIED_DT,
b.LAST_MODIFIED_TM,
b.LAST_MODIFIED_UTC_DT,
b.LAST_MODIFIED_UTC_TM,
SUBSTR(b.TRD_FIN_CNTRCT_INTRL_ID,1,16),
b.BOOK_DT,
b.BOOK_TM,
b.BOOK_UTC_DT,
b.BOOK_UTC_TM,
b.VAL_DT,
b.BASE_DT,
b.LAST_MATURITY_DT,
b.CLOSED_DT,
b.CLOSED_UTC_DT,
b.CLOSED_TM,
b.CLOSED_UTC_TM,
b.CNCLD_DT,
b.CNCLD_TM,
b.CNCLD_UTC_DT,
b.CNCLD_UTC_TM,
b.FULLFLD_DT,
b.FULLFLD_UTC_DT,
b.FULLFLD_TM,
b.FULLFLD_UTC_TM,
GREATEST(LEAST(b.LAST_TNR_DAYS,9999),-9999),
GREATEST(LEAST(b.LAST_TRNST_DAYS,9999),-9999),
SUBSTR(b.LAST_PAYMT_MTHD_CD,1,1),
GREATEST(LEAST(b.LAST_PRNCL_AMT,1.0E20),-1.0E20),
GREATEST(LEAST(b.LAST_TOT_CMSN_CHARGE_AMT,1.0E20),-1.0E20),
SUBSTR(b.LAST_ORIG_BENEF_CHARGE_CD,1,1),
GREATEST(LEAST(b.LAST_TOT_COLL_AMT,1.0E20),-1.0E20),
SUBSTR(b.LAST_COLL_CRNCY_CD,1,3),
GREATEST(LEAST(b.LAST_PURCH_ADV_DISC_AMT,1.0E20),-1.0E20),
SUBSTR(b.LAST_LOAN_ID,1,50),
GREATEST(LEAST(b.LAST_REBATE_AMT,1.0E20),-1.0E20),
b.ACCPT_DT,
GREATEST(LEAST(b.ACCPTD_TOT_COLL_AMT,1.0E20),-1.0E20),
SUBSTR(b.ACCPTD_COLL_CRNCY_CD,1,3),
b.ACCPTD_MATURITY_DT,
SUBSTR(b.ACCPTD_INFO_TX,1,255),
b.LAST_REFUSAL_DT,
b.LAST_REFUSAL_TM,
b.LAST_REFUSAL_UTC_DT,
b.LAST_REFUSAL_UTC_TM,
SUBSTR(b.LAST_SND_RCV_INFO_TX,1,250),
SUBSTR(b.CNTRCT_ENTRY_SYS_LOGON_ID,1,50),
SUBSTR(b.CNTRCT_ENTRY_USER_ID,1,50),
SUBSTR(b.EXTRL_NSRNC_PLCY_INTRL_ID,1,50),
b.LAST_CSTM_1_DT,
b.LAST_CSTM_2_DT,
b.LAST_CSTM_3_DT,
GREATEST(LEAST(b.LAST_CSTM_1_RL,1.0E20),-1.0E20),
GREATEST(LEAST(b.LAST_CSTM_2_RL,1.0E20),-1.0E20),
GREATEST(LEAST(b.LAST_CSTM_3_RL,1.0E20),-1.0E20),
SUBSTR(b.LAST_CSTM_1_TX,1,255),
SUBSTR(b.LAST_CSTM_2_TX,1,255),
SUBSTR(b.LAST_CSTM_3_TX,1,255),
SUBSTR(b.LAST_CSTM_4_TX,1,255),
SUBSTR(b.LAST_CSTM_5_TX,1,255),
SUBSTR(b.LAST_SRC_SYS_CD,1,3),
'DLY',
TO_DATE('20230510', 'YYYYMMDD'),
b.LAST_AMD_DT,
b.LAST_AMD_TM,
b.LAST_AMD_UTC_DT,
b.LAST_AMD_UTC_TM,
GREATEST(LEAST(b.LAST_TRD_FIN_GOODSRVC_EVENT_NB,9999999999),-9999999999),
GREATEST(LEAST(b.LAST_TRD_FIN_DOC_EVENT_NB,9999999999),-9999999999),
GREATEST(LEAST(b.LAST_TRD_FIN_PARTY_EVENT_NB,9999999999),-9999999999),
GREATEST(LEAST(b.LAST_PRNCL_ACTVY_AMT,1.0E20),-1.0E20),
GREATEST(LEAST(b.LAST_TOT_CMSN_CHARGE_ACTVY_AMT,1.0E20),-1.0E20),
GREATEST(LEAST(b.LAST_REBATE_ACTVY_AMT,1.0E20),-1.0E20),
GREATEST(LEAST(b.LAST_TOT_COLL_ACTVY_AMT,1.0E20),-1.0E20),
GREATEST(LEAST(b.LAST_PURCH_ADV_DISC_ACTVY_AMT,1.0E20),-1.0E20),
SUBSTR(b.LAST_GOOD_SRVC_DESC_TX,1,-1),
SUBSTR(b.LAST_CHANL_CD,1,20),
GREATEST(LEAST(b.LAST_CHANL_RISK_NB,999),-999),
GREATEST(LEAST(b.LAST_PRDCT_RISK_NB,999),-999),
NVL(GREATEST(LEAST(b.LAST_ACTVY_RISK_NB,999),-999),0),
GREATEST(LEAST(b.ACCPTD_TOT_COLL_ACTVY_AMT,1.0E20),-1.0E20)
)
