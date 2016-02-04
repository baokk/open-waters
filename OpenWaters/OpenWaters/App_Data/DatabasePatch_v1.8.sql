﻿/*
Only run this script if upgrading from v1.7x to v1.8x

Version 1.8x Change Log
--------------------
ENHANCEMENTS: 
1. Added import translations: now before importing data you can define a mapping of your data to EPA acceptable data. This is helpful in cases where you receive 
data from labs using codes different from EPA and don't want to have to update the import spreadsheet every time.
2. Additional code cleanup
BUG FIX: 
3. Fix bug when importing samples and other organization has pending samples.
*/

CREATE TABLE [dbo].[T_WQX_IMPORT_TRANSLATE](
	[TRANSLATE_IDX] [int] IDENTITY(1,1) NOT NULL,
	[ORG_ID] [varchar](30) NOT NULL,
	[COL_NAME] [varchar](50) NOT NULL,
	[DATA_FROM] [varchar](150) NOT NULL,
	[DATA_TO] [varchar](150) NULL,
	[CREATE_DT] [datetime] NULL,
	[CREATE_USERID] [varchar](25) NULL,
 CONSTRAINT [PK_WQX_IMPORT_TRANSLATE] PRIMARY KEY CLUSTERED  ([TRANSLATE_IDX] ),
 FOREIGN KEY (ORG_ID) references T_WQX_ORGANIZATION (ORG_ID) 
	ON UPDATE CASCADE 
	ON DELETE CASCADE, 
) ON [PRIMARY];


GO

CREATE PROCEDURE [dbo].[ImportActivityFromTemp]
  @UserID varchar(25),
  @WQXInd varchar(1),
  @ActivityReplaceInd varchar(1)
AS
BEGIN
	/*
	DESCRIPTION: COPIES DATA FROM TEMP ACTIVITY AND RESULT TABLES INTO PERMANENT TABLES
	CHANGE LOG: 3/14/2015 DOUG TIMMS, OPEN-ENVIRONMENT.ORG
	5/2/2015 DOUG TIMMS: added ability to update matching activity
	2/3/2016 DOUG TIMMS: fix bug 

	@ActivityReplaceInd: "R": delete existing activity and replace with new one (*recommended*)
						 "U": update existing activity (appending results if found)  (*not recommended)						 
	*/
	SET NOCOUNT ON;

	DECLARE @WQXIndBool bit;
	if @WQXInd='Y' 
		set @WQXIndBool=1;
	else
		set @WQXIndBool=0;


    --delete matching activities 
	if @ActivityReplaceInd='R'
	BEGIN
		delete from T_WQX_ACTIVITY where ACTIVITY_ID in (select ACTIVITY_ID from T_WQX_IMPORT_TEMP_SAMPLE where UPPER(USER_ID)= UPPER(@UserID));
	END


	--insert and update activity case
    merge into T_WQX_ACTIVITY A
    USING (select * from T_WQX_IMPORT_TEMP_SAMPLE where IMPORT_STATUS_CD = 'P' and UPPER(USER_ID) = UPPER(@UserID)) as T
    ON A.ACTIVITY_ID = T.ACTIVITY_ID     
    when MATCHED then 
	    UPDATE SET A.PROJECT_IDX = T.PROJECT_IDX, A.MONLOC_IDX = T.MONLOC_IDX, A.ACT_TYPE = T.ACT_TYPE, A.ACT_MEDIA = T.ACT_MEDIA, A.ACT_SUBMEDIA = T.ACT_SUBMEDIA, 
		A.ACT_START_DT = T.ACT_START_DT, A.ACT_END_DT = T.ACT_END_DT, A.ACT_TIME_ZONE = T.ACT_TIME_ZONE, A.RELATIVE_DEPTH_NAME = T.RELATIVE_DEPTH_NAME, 
		A.ACT_DEPTHHEIGHT_MSR = T.ACT_DEPTHHEIGHT_MSR, A.ACT_DEPTHHEIGHT_MSR_UNIT = T.ACT_DEPTHHEIGHT_MSR_UNIT, A.TOP_DEPTHHEIGHT_MSR = T.TOP_DEPTHHEIGHT_MSR, 
		A.TOP_DEPTHHEIGHT_MSR_UNIT = T.TOP_DEPTHHEIGHT_MSR_UNIT, A.BOT_DEPTHHEIGHT_MSR = T.BOT_DEPTHHEIGHT_MSR, A.BOT_DEPTHHEIGHT_MSR_UNIT = T.BOT_DEPTHHEIGHT_MSR_UNIT, 
		A.DEPTH_REF_POINT = T.DEPTH_REF_POINT, A.ACT_COMMENT = T.ACT_COMMENT, A.BIO_ASSEMBLAGE_SAMPLED = T.BIO_ASSEMBLAGE_SAMPLED, A.BIO_DURATION_MSR = T.BIO_DURATION_MSR, 
		A.BIO_DURATION_MSR_UNIT = T.BIO_DURATION_MSR_UNIT, A.BIO_SAMP_COMPONENT = T.BIO_SAMP_COMPONENT, A.BIO_SAMP_COMPONENT_SEQ = T.BIO_SAMP_COMPONENT_SEQ, 
		A.BIO_REACH_LEN_MSR = T.BIO_REACH_LEN_MSR, A.BIO_REACH_LEN_MSR_UNIT = T.BIO_REACH_LEN_MSR_UNIT, A.BIO_REACH_WID_MSR = T.BIO_REACH_WID_MSR, A.BIO_REACH_WID_MSR_UNIT = T.BIO_REACH_WID_MSR_UNIT, 
		A.BIO_PASS_COUNT = T.BIO_PASS_COUNT, A.BIO_NET_TYPE = T.BIO_NET_TYPE, A.BIO_NET_AREA_MSR = T.BIO_NET_AREA_MSR, A.BIO_NET_AREA_MSR_UNIT = T.BIO_NET_AREA_MSR_UNIT, 
		A.BIO_NET_MESHSIZE_MSR = T.BIO_NET_MESHSIZE_MSR, A.BIO_MESHSIZE_MSR_UNIT = T.BIO_MESHSIZE_MSR_UNIT, A.BIO_BOAT_SPEED_MSR = T.BIO_BOAT_SPEED_MSR, 
		A.BIO_BOAT_SPEED_MSR_UNIT = T.BIO_BOAT_SPEED_MSR_UNIT, A.BIO_CURR_SPEED_MSR = T.BIO_CURR_SPEED_MSR, A.BIO_CURR_SPEED_MSR_UNIT = T.BIO_CURR_SPEED_MSR_UNIT, 
		A.BIO_TOXICITY_TEST_TYPE = T.BIO_TOXICITY_TEST_TYPE, A.SAMP_COLL_METHOD_IDX = T.SAMP_COLL_METHOD_IDX, A.SAMP_COLL_EQUIP = T.SAMP_COLL_EQUIP, 
		A.SAMP_COLL_EQUIP_COMMENT = T.SAMP_COLL_EQUIP_COMMENT, A.SAMP_PREP_IDX = T.SAMP_PREP_IDX, A.SAMP_PREP_CONT_TYPE = T.SAMP_PREP_CONT_TYPE, A.SAMP_PREP_CONT_COLOR = T.SAMP_PREP_CONT_COLOR,
		A.SAMP_PREP_CHEM_PRESERV = T.SAMP_PREP_CHEM_PRESERV, A.SAMP_PREP_THERM_PRESERV = T.SAMP_PREP_THERM_PRESERV, A.SAMP_PREP_STORAGE_DESC = T.SAMP_PREP_STORAGE_DESC,
		A.UPDATE_DT = GetDate(), A.UPDATE_USERID = @UserID, A.ACT_IND = 1, A.WQX_IND = @WQXIndBool, A.WQX_SUBMIT_STATUS = 'U', A.TEMP_SAMPLE_IDX = T.TEMP_SAMPLE_IDX
    when NOT MATCHED then 
		INSERT (ORG_ID, PROJECT_IDX, MONLOC_IDX, ACTIVITY_ID, ACT_TYPE, ACT_MEDIA, ACT_SUBMEDIA, ACT_START_DT, ACT_END_DT, ACT_TIME_ZONE, RELATIVE_DEPTH_NAME, ACT_DEPTHHEIGHT_MSR, ACT_DEPTHHEIGHT_MSR_UNIT, 
		TOP_DEPTHHEIGHT_MSR, TOP_DEPTHHEIGHT_MSR_UNIT, BOT_DEPTHHEIGHT_MSR, BOT_DEPTHHEIGHT_MSR_UNIT, DEPTH_REF_POINT, ACT_COMMENT, BIO_ASSEMBLAGE_SAMPLED, BIO_DURATION_MSR, 
		BIO_DURATION_MSR_UNIT, BIO_SAMP_COMPONENT, BIO_SAMP_COMPONENT_SEQ, BIO_REACH_LEN_MSR, BIO_REACH_LEN_MSR_UNIT, BIO_REACH_WID_MSR, BIO_REACH_WID_MSR_UNIT, BIO_PASS_COUNT,
		BIO_NET_TYPE, BIO_NET_AREA_MSR, BIO_NET_AREA_MSR_UNIT, BIO_NET_MESHSIZE_MSR, BIO_MESHSIZE_MSR_UNIT, BIO_BOAT_SPEED_MSR, BIO_BOAT_SPEED_MSR_UNIT, BIO_CURR_SPEED_MSR, 
		BIO_CURR_SPEED_MSR_UNIT, BIO_TOXICITY_TEST_TYPE, SAMP_COLL_METHOD_IDX, SAMP_COLL_EQUIP, SAMP_COLL_EQUIP_COMMENT, SAMP_PREP_IDX, SAMP_PREP_CONT_TYPE, SAMP_PREP_CONT_COLOR,
		SAMP_PREP_CHEM_PRESERV, SAMP_PREP_THERM_PRESERV, SAMP_PREP_STORAGE_DESC, CREATE_DT, CREATE_USERID, ACT_IND, WQX_IND, WQX_SUBMIT_STATUS, TEMP_SAMPLE_IDX)
		VALUES (T.ORG_ID, T.PROJECT_IDX, T.MONLOC_IDX, T.ACTIVITY_ID, T.ACT_TYPE, T.ACT_MEDIA, T.ACT_SUBMEDIA, T.ACT_START_DT, T.ACT_END_DT, T.ACT_TIME_ZONE, T.RELATIVE_DEPTH_NAME, 
		T.ACT_DEPTHHEIGHT_MSR, T.ACT_DEPTHHEIGHT_MSR_UNIT, T.TOP_DEPTHHEIGHT_MSR, T.TOP_DEPTHHEIGHT_MSR_UNIT, T.BOT_DEPTHHEIGHT_MSR, T.BOT_DEPTHHEIGHT_MSR_UNIT, T.DEPTH_REF_POINT, 
		T.ACT_COMMENT, T.BIO_ASSEMBLAGE_SAMPLED, T.BIO_DURATION_MSR, T.BIO_DURATION_MSR_UNIT, T.BIO_SAMP_COMPONENT, T.BIO_SAMP_COMPONENT_SEQ, T.BIO_REACH_LEN_MSR, T.BIO_REACH_LEN_MSR_UNIT, 
		T.BIO_REACH_WID_MSR, T.BIO_REACH_WID_MSR_UNIT, T.BIO_PASS_COUNT, T.BIO_NET_TYPE, T.BIO_NET_AREA_MSR, T.BIO_NET_AREA_MSR_UNIT, T.BIO_NET_MESHSIZE_MSR, T.BIO_MESHSIZE_MSR_UNIT, 
		T.BIO_BOAT_SPEED_MSR, T.BIO_BOAT_SPEED_MSR_UNIT, T.BIO_CURR_SPEED_MSR,  T.BIO_CURR_SPEED_MSR_UNIT, T.BIO_TOXICITY_TEST_TYPE, T.SAMP_COLL_METHOD_IDX, T.SAMP_COLL_EQUIP, 
		T.SAMP_COLL_EQUIP_COMMENT, T.SAMP_PREP_IDX, T.SAMP_PREP_CONT_TYPE, T.SAMP_PREP_CONT_COLOR, T.SAMP_PREP_CHEM_PRESERV, T.SAMP_PREP_THERM_PRESERV, T.SAMP_PREP_STORAGE_DESC, 
		GetDate(), @UserID, 1, @WQXIndBool, 'U', T.TEMP_SAMPLE_IDX);



	--insert result
	insert into T_WQX_RESULT (ACTIVITY_IDX,	DATA_LOGGER_LINE, RESULT_DETECT_CONDITION, CHAR_NAME, METHOD_SPECIATION_NAME, RESULT_SAMP_FRACTION, RESULT_MSR, RESULT_MSR_UNIT, RESULT_MSR_QUAL, 
	RESULT_STATUS, STATISTIC_BASE_CODE, RESULT_VALUE_TYPE, WEIGHT_BASIS, TIME_BASIS, TEMP_BASIS, PARTICLESIZE_BASIS, PRECISION_VALUE, BIAS_VALUE, 
	CONFIDENCE_INTERVAL_VALUE, UPPER_CONFIDENCE_LIMIT, LOWER_CONFIDENCE_LIMIT, RESULT_COMMENT, DEPTH_HEIGHT_MSR, DEPTH_HEIGHT_MSR_UNIT, DEPTHALTITUDEREFPOINT, 
	BIO_INTENT_NAME, BIO_INDIVIDUAL_ID, BIO_SUBJECT_TAXONOMY, BIO_UNIDENTIFIED_SPECIES_ID, BIO_SAMPLE_TISSUE_ANATOMY, GRP_SUMM_COUNT_WEIGHT_MSR, GRP_SUMM_COUNT_WEIGHT_MSR_UNIT, 
	TAX_DTL_CELL_FORM, TAX_DTL_CELL_SHAPE, TAX_DTL_HABIT, TAX_DTL_VOLTINISM, TAX_DTL_POLL_TOLERANCE, TAX_DTL_POLL_TOLERANCE_SCALE, TAX_DTL_TROPHIC_LEVEL, 
	TAX_DTL_FUNC_FEEDING_GROUP1, TAX_DTL_FUNC_FEEDING_GROUP2, TAX_DTL_FUNC_FEEDING_GROUP3, [FREQ_CLASS_CODE], [FREQ_CLASS_UNIT], [FREQ_CLASS_UPPER], [FREQ_CLASS_LOWER], 
	ANALYTIC_METHOD_IDX, LAB_IDX, LAB_ANALYSIS_START_DT, 
	LAB_ANALYSIS_END_DT, LAB_ANALYSIS_TIMEZONE, RESULT_LAB_COMMENT_CODE, DETECTION_LIMIT, LAB_REPORTING_LEVEL, PQL, LOWER_QUANT_LIMIT, UPPER_QUANT_LIMIT,
	DETECTION_LIMIT_UNIT, LAB_SAMP_PREP_IDX, LAB_SAMP_PREP_START_DT, LAB_SAMP_PREP_END_DT, DILUTION_FACTOR
	)
	select A.ACTIVITY_IDX, R.DATA_LOGGER_LINE, R.RESULT_DETECT_CONDITION, R.CHAR_NAME, R.METHOD_SPECIATION_NAME, R.RESULT_SAMP_FRACTION, R.RESULT_MSR, R.RESULT_MSR_UNIT, R.RESULT_MSR_QUAL, 
	R.RESULT_STATUS, R.STATISTIC_BASE_CODE, R.RESULT_VALUE_TYPE, R.WEIGHT_BASIS, R.TIME_BASIS, R.TEMP_BASIS, R.PARTICLESIZE_BASIS, R.PRECISION_VALUE, R.BIAS_VALUE, 
	R.CONFIDENCE_INTERVAL_VALUE, R.UPPER_CONFIDENCE_LIMIT, R.LOWER_CONFIDENCE_LIMIT, R.RESULT_COMMENT, R.DEPTH_HEIGHT_MSR, R.DEPTH_HEIGHT_MSR_UNIT, R.DEPTHALTITUDEREFPOINT, 
	R.BIO_INTENT_NAME, R.BIO_INDIVIDUAL_ID, R.BIO_SUBJECT_TAXONOMY, R.BIO_UNIDENTIFIED_SPECIES_ID, R.BIO_SAMPLE_TISSUE_ANATOMY, R.GRP_SUMM_COUNT_WEIGHT_MSR, R.GRP_SUMM_COUNT_WEIGHT_MSR_UNIT, 
	R.TAX_DTL_CELL_FORM, r.TAX_DTL_CELL_SHAPE, r.TAX_DTL_HABIT, r.TAX_DTL_VOLTINISM, r.TAX_DTL_POLL_TOLERANCE, r.TAX_DTL_POLL_TOLERANCE_SCALE, r.TAX_DTL_TROPHIC_LEVEL, 
	r.TAX_DTL_FUNC_FEEDING_GROUP1, r.TAX_DTL_FUNC_FEEDING_GROUP2, r.TAX_DTL_FUNC_FEEDING_GROUP3, r.FREQ_CLASS_CODE, r.FREQ_CLASS_UNIT, r.FREQ_CLASS_UPPER, r.FREQ_CLASS_LOWER, 
	r.ANALYTIC_METHOD_IDX, r.LAB_IDX, r.LAB_ANALYSIS_START_DT, 
	r.LAB_ANALYSIS_END_DT, r.LAB_ANALYSIS_TIMEZONE, r.RESULT_LAB_COMMENT_CODE, r.METHOD_DETECTION_LEVEL, r.LAB_REPORTING_LEVEL, r.PQL, r.LOWER_QUANT_LIMIT, r.UPPER_QUANT_LIMIT,
	r.DETECTION_LIMIT_UNIT, r.LAB_SAMP_PREP_IDX, r.LAB_SAMP_PREP_START_DT, r.LAB_SAMP_PREP_END_DT, r.DILUTION_FACTOR
	from T_WQX_IMPORT_TEMP_RESULT R, T_WQX_ACTIVITY A, T_WQX_IMPORT_TEMP_SAMPLE S
	where R.TEMP_SAMPLE_IDX = S.TEMP_SAMPLE_IDX 
	and S.TEMP_SAMPLE_IDX = A.TEMP_SAMPLE_IDX
	and R.IMPORT_STATUS_CD = 'P'
	and UPPER(S.USER_ID) = UPPER(@UserID);


	--insert characteristics into the org reference list if they do not yet exist
	DECLARE @OrgID varchar(30);
	select top 1 @OrgID = ORG_ID from T_WQX_IMPORT_TEMP_SAMPLE where UPPER(USER_ID) = UPPER(@UserID)

	insert into T_WQX_REF_CHAR_ORG (CHAR_NAME, ORG_ID, CREATE_USERID, CREATE_DT)
	select distinct R.char_name , @OrgID, 'SYSTEM', GetDate()
	from T_WQX_ACTIVITY A, T_WQX_RESULT R
	left join T_WQX_REF_CHAR_ORG O on R.CHAR_NAME = O.CHAR_NAME  and O.ORG_ID = @OrgID
	where R.ACTIVITY_IDX = A.ACTIVITY_IDX
	and A.ORG_ID = @OrgID
	and O.CHAR_NAME is null;


	--insert taxa into the org reference list if they do not yet exist
	insert into T_WQX_REF_TAXA_ORG ([BIO_SUBJECT_TAXONOMY], ORG_ID, CREATE_USERID, CREATE_DT)
	select distinct R.[BIO_SUBJECT_TAXONOMY] , @OrgID, 'SYSTEM', GetDate()
	from T_WQX_ACTIVITY A, T_WQX_RESULT R
	left join T_WQX_REF_TAXA_ORG O on R.[BIO_SUBJECT_TAXONOMY]= O.[BIO_SUBJECT_TAXONOMY]  and O.ORG_ID = @OrgID
	where R.ACTIVITY_IDX = A.ACTIVITY_IDX
	and A.ORG_ID = @OrgID
	and O.[BIO_SUBJECT_TAXONOMY] is null
	and NULLIF(R.BIO_SUBJECT_TAXONOMY,'') is not null;


	--update the entry type column for all imported sample
	UPDATE T_WQX_ACTIVITY set ENTRY_TYPE = 'C' where ENTRY_TYPE IS NULL;
	
	UPDATE T_WQX_ACTIVITY set ENTRY_TYPE = 'H' where ORG_ID = @OrgID and CREATE_DT > GetDate()-1 and
	(select count(*) from T_WQX_RESULT R where R.ACTIVITY_IDX = T_WQX_ACTIVITY.ACTIVITY_IDX and CHAR_NAME like '%RBP%') > 0;
	
	UPDATE T_WQX_ACTIVITY set ENTRY_TYPE = 'T' where ORG_ID = @OrgID and CREATE_DT > GetDate()-1 and
	(select count(*) from T_WQX_RESULT R where R.ACTIVITY_IDX = T_WQX_ACTIVITY.ACTIVITY_IDX and len(BIO_SUBJECT_TAXONOMY) > 0) > 0


	--DELETE TEMP DATA
	DELETE FROM T_WQX_IMPORT_TEMP_SAMPLE where UPPER(USER_ID) = UPPER(@UserID);



END

GO