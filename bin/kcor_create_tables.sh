#!/bin/sh

DB_FILE=$1
MLSO_SCRIPTS_DIR=../../mlso-databases/bin

# must drop all tables in correct order before creating new ones
kcor_drop_table.pl $DB_FILE kcor_mission
kcor_drop_table.pl $DB_FILE kcor_img
kcor_drop_table.pl $DB_FILE kcor_raw
kcor_drop_table.pl $DB_FILE kcor_hw
kcor_drop_table.pl $DB_FILE kcor_eng
kcor_drop_table.pl $DB_FILE kcor_cal
kcor_drop_table.pl $DB_FILE kcor_sci

kcor_drop_table.pl $DB_FILE kcor_sw
kcor_drop_table.pl $DB_FILE kcor_level
kcor_drop_table.pl $DB_FILE kcor_quality
kcor_drop_table.pl $DB_FILE mlso_sgs
kcor_drop_table.pl $DB_FILE mlso_numfiles
kcor_drop_table.pl $DB_FILE mlso_producttype
kcor_drop_table.pl $DB_FILE mlso_filetype

# create tables
$MLSO_SCRIPTS_DIR/mlso_filetype_create_table.pl $DB_FILE
$MLSO_SCRIPTS_DIR/mlso_producttype_create_table.pl $DB_FILE
$MLSO_SCRIPTS_DIR/mlso_numfiles_create_table.pl $DB_FILE
$MLSO_SCRIPTS_DIR/mlso_sgs_create_table.pl $DB_FILE
kcor_level_create_table.pl $DB_FILE
kcor_quality_create_table.pl $DB_FILE
kcor_sw_create_table.pl $DB_FILE

kcor_cal_create_table.pl $DB_FILE
kcor_hw_create_table.pl $DB_FILE
kcor_img_create_table.pl $DB_FILE
kcor_raw_create_table.pl $DB_FILE
kcor_mission_create_table.pl $DB_FILE
kcor_eng_create_table.pl $DB_FILE
kcor_sci_create_table.pl $DB_FILE
