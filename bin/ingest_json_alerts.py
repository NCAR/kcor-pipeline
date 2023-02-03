#!/usr/bin/env python

import argparse
import configparser
import datetime
import json
import os


try:
    import mysql
    import mysql.connector
    db_requirements = True
except ModuleNotFoundError as e:
    db_requirements = False


ISO_DT_FORMAT = "%Y-%m-%dT%H:%S:%MZ"


def read_db_config_file(db_config_filename, db_config_section, error=print):
    db_config = configparser.ConfigParser()
    db_config.read(db_config_filename)

    try:
        host     = db_config.get(db_config_section, "host")
        user     = db_config.get(db_config_section, "user")
        password = db_config.get(db_config_section, "password")
    except configparser.NoSectionError:
        error("incomplete database information")

    return(host, user, password)


def get_obsday(dt, cursor):
    hst = dt - datetime.timedelta(hours=10)
    obs_day = hst.date()
    cursor.execute("select day_id from MLSO.mlso_numfiles where obs_day = %s", (obs_day, ))
    for r in cursor:
        return(r[0])
    
    # if you get here there was nothing in the above query, the obs day must be
    # inserted into mlso_numfiles
    add_format = ("insert into MLSO.mlso_numfiles "
                  "(obs_day) "
                  "values (%s)")
    cursor.execute(add_format, (obs_day, ))


def ingest(filenames, host, user, password, error=print):
    try:
        connection = mysql.connector.connect(host=host, user=user, password=password)
        cursor = connection.cursor()
        for f in filenames:
            ingest_file(f, cursor)
            connection.commit()
    except mysql.connector.Error as e:
        error(e)
    finally:
        cursor.close()
        connection.close()


def ingest_file(filename, cursor):
    with open(filename, "r") as f:
        basename = os.path.basename(filename)
        data = json.load(f)
        observations = data["sep_forecast_submission"]["observations"][0]

        if "alert" in observations:
            type = observations["alert"]["alert_type"]
        else:
            return

        if type == "ALERT":
            print(f"ingesting inital alert {basename}...")
            ingest_alert(data, cursor)
        elif type == "SUMMARY":
            print(f"ingesting summary alert {basename}...")
            ingest_summary(data, cursor)
        elif type == "OBSERVER ALERT":
            print(f"ingesting observer alert {basename}...")
            ingest_observer_alert(data, cursor)
        elif type == "CANCEL ALERT":
            print(f"ingesting retraction alert {basename}...")
            ingest_retraction(data, cursor)


def ingest_alert(data, cursor):
    issue_time = datetime.datetime.strptime(data["sep_forecast_submission"]["issue_time"], ISO_DT_FORMAT)
    cme = data["sep_forecast_submission"]["triggers"][0]["cme"]
    start_time = datetime.datetime.strptime(cme["start_time"], ISO_DT_FORMAT)
    pa = cme["pa"]
    speed = cme["speed"]
    height = cme["time_at_height"]["height"]
    time_at_height = datetime.datetime.strptime(cme["time_at_height"]["time"], ISO_DT_FORMAT)
    inputs = data["sep_forecast_submission"]["inputs"][0]
    products = inputs["coronagraph"]["products"][0]
    last_data_time = datetime.datetime.strptime(products["last_data_time"], ISO_DT_FORMAT)

    obs_day = get_obsday(start_time, cursor)

    alert = {"obs_day": obs_day, "alert_type": "initial", "event_type": "cme",
        "found_type": "cme", "issue_time": issue_time,
        "start_time": start_time, "pa": pa, "speed": speed,
        "height": height, "time_at_height": time_at_height,
        "last_data_time": last_data_time}
    add_cmd_format = ("insert into MLSO.kcor_cme_alert "
                  "(obs_day, alert_type, event_type, cme_type, issue_time, start_time, position_angle, speed, height, time_for_height, last_data_time) "
                  "values (%(obs_day)s, %(alert_type)s, %(event_type)s, %(found_type)s, %(issue_time)s, %(start_time)s, %(pa)s, %(speed)s, %(height)s, %(time_at_height)s, %(last_data_time)s)")
    cursor.execute(add_cmd_format, alert)


def ingest_summary(data, cursor):
    issue_time = datetime.datetime.strptime(data["sep_forecast_submission"]["issue_time"], ISO_DT_FORMAT)

    cme = data["sep_forecast_submission"]["triggers"][0]["cme"]
    start_time = datetime.datetime.strptime(cme["start_time"], ISO_DT_FORMAT)
    pa = cme["pa"]
    speed = cme["speed"]
    height = cme["time_at_height"]["height"]
    time_at_height = datetime.datetime.strptime(cme["time_at_height"]["time"], ISO_DT_FORMAT)

    inputs = data["sep_forecast_submission"]["inputs"][0]
    products = inputs["coronagraph"]["products"][0]
    last_data_time = datetime.datetime.strptime(products["last_data_time"], ISO_DT_FORMAT)

    observations = data["sep_forecast_submission"]["observations"][0]
    end_time = datetime.datetime.strptime(observations["alert"]["end_time"], ISO_DT_FORMAT)

    obs_day = get_obsday(start_time, cursor)

    alert = {"obs_day": obs_day, "alert_type": "summary", "event_type": "cme",
        "found_type": "cme", "issue_time": issue_time,
        "start_time": start_time, "end_time": end_time, "pa": pa, "speed": speed,
        "height": height, "time_at_height": time_at_height,
        "last_data_time": last_data_time}
    add_cmd_format = ("insert into MLSO.kcor_cme_alert "
                  "(obs_day, alert_type, event_type, cme_type, issue_time, start_time, end_time, position_angle, speed, height, time_for_height, last_data_time) "
                  "values (%(obs_day)s, %(alert_type)s, %(event_type)s, %(found_type)s, %(issue_time)s, %(start_time)s, %(end_time)s, %(pa)s, %(speed)s, %(height)s, %(time_at_height)s, %(last_data_time)s)")
    cursor.execute(add_cmd_format, alert)


def ingest_observer_alert(data, cursor):
    issue_time = datetime.datetime.strptime(data["sep_forecast_submission"]["issue_time"], ISO_DT_FORMAT)

    observations = data["sep_forecast_submission"]["observations"][0]
    start_time = datetime.datetime.strptime(observations["alert"]["start_time"], ISO_DT_FORMAT)
    comment = observations["alert"]["comment"]

    inputs = data["sep_forecast_submission"]["inputs"][0]
    products = inputs["coronagraph"]["products"][0]
    if "last_data_time" in products:
        last_data_time = datetime.datetime.strptime(products["last_data_time"], ISO_DT_FORMAT)
    else:
        last_data_time = None

    obs_day = get_obsday(start_time, cursor)

    alert = {"obs_day": obs_day, "alert_type": "observer", "event_type": "cme",
        "found_type": "cme", "issue_time": issue_time,
        "start_time": start_time, "last_data_time": last_data_time,
        "comment": comment}
    add_cmd_format = ("insert into MLSO.kcor_cme_alert "
                  "(obs_day, alert_type, event_type, cme_type, issue_time, start_time, last_data_time, comment) "
                  "values (%(obs_day)s, %(alert_type)s, %(event_type)s, %(found_type)s, %(issue_time)s, %(start_time)s, %(last_data_time)s, %(comment)s)")
    cursor.execute(add_cmd_format, alert)


def ingest_retraction(data, cursor):
    issue_time = datetime.datetime.strptime(data["sep_forecast_submission"]["issue_time"], ISO_DT_FORMAT)

    observations = data["sep_forecast_submission"]["observations"][0]
    start_time = datetime.datetime.strptime(observations["alert"]["start_time"], ISO_DT_FORMAT)
    comment = observations["alert"]["comment"]

    inputs = data["sep_forecast_submission"]["inputs"][0]
    products = inputs["coronagraph"]["products"][0]
    last_data_time = datetime.datetime.strptime(products["last_data_time"], ISO_DT_FORMAT)

    obs_day = get_obsday(start_time, cursor)

    alert = {"obs_day": obs_day, "alert_type": "retraction", "event_type": "cme",
        "found_type": "cme", "issue_time": issue_time,
        "start_time": start_time, "last_data_time": last_data_time,
        "comment": comment}
    add_cmd_format = ("insert into MLSO.kcor_cme_alert "
                  "(obs_day, alert_type, event_type, cme_type, issue_time, start_time, last_data_time, comment) "
                  "values (%(obs_day)s, %(alert_type)s, %(event_type)s, %(found_type)s, %(issue_time)s, %(start_time)s, %(last_data_time)s, %(comment)s)")
    cursor.execute(add_cmd_format, alert)


if __name__ == "__main__":
    name = "JSON alert ingestor"
    parser = argparse.ArgumentParser(description=name)

    parser.add_argument("--db-config-filename", "-f", help="database configuration file")
    parser.add_argument("--db-config-section", "-s", help="database configuration section")
    parser.add_argument("filename", nargs="*", type=str, help="JSON file to ingest")

    args = parser.parse_args()

    if not db_requirements:
        args.parser.error("MySQL connector not installed")

    host, user, password = read_db_config_file(args.db_config_filename,
        args.db_config_section, error=parser.error)

    ingest(args.filename, host, user, password, error=parser.error)
