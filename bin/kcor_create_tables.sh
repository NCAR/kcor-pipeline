#!/bin/sh

DB_FILE=$1

# must drop all tables in correct order before creating new ones
kcor_drop_table.pl $DB_FILE kcor_mission
kcor_drop_table.pl $DB_FILE kcor_img
kcor_drop_table.pl $DB_FILE kcor_hw
kcor_drop_table.pl $DB_FILE kcor_eng
kcor_drop_table.pl $DB_FILE kcor_cal

kcor_drop_table.pl $DB_FILE kcor_sw
kcor_drop_table.pl $DB_FILE kcor_level
kcor_drop_table.pl $DB_FILE mlso_sgs
kcor_drop_table.pl $DB_FILE mlso_numfiles
kcor_drop_table.pl $DB_FILE mlso_producttype
kcor_drop_table.pl $DB_FILE mlso_filetype

# create tables
mlso_filetype_create_table.pl $DB_FILE
mlso_producttype_create_table.pl $DB_FILE
mlso_numfiles_create_table.pl $DB_FILE
mlso_sgs_create_table.pl $DB_FILE
kcor_level_create_table.pl $DB_FILE
kcor_sw_create_table.pl $DB_FILE

kcor_cal_create_table.pl $DB_FILE
kcor_hw_create_table.pl $DB_FILE
kcor_img_create_table.pl $DB_FILE
kcor_mission_create_table.pl $DB_FILE
kcor_eng_create_table.pl $DB_FILE
