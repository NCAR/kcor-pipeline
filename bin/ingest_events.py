#!/usr/bin/env python

import argparse
import configparser
import csv
import datetime


try:
    import mysql
    import mysql.connector
    db_requirements = True
except ModuleNotFoundError as e:
    db_requirements = False


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
    print(f"ingesting {filename}...")
    n_header_rows = 53
    with open(filename, "r") as f:
        csv_reader = csv.reader(f, delimiter="\t")
        for i in range(n_header_rows):
            next(csv_reader, None)

        for line_offset, row in enumerate(csv_reader):
            filtered_row = [r.strip() for r in row if r.strip(" ") != ""]
            if len(filtered_row) < 5:
                if len(filtered_row) > 0:
                    formatted_row = ', '.join(row)
                    print(f"unparsed line [line {line_offset + n_header_rows}]: {formatted_row}")
                continue
            try:
                event = parse_row(filtered_row)
                event["obs_day"] = get_obsday(event["start_datetime"], cursor)
                ingest_event(event, cursor)
            except ValueError as e:
                formatted_row = ', '.join(row)
                print(f"error parsing line [line {line_offset + n_header_rows}]: {formatted_row}")


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


def ingest_event(event, cursor):
    if event["instrument"].lower() != "kcor": return

    types = ["possible cme", "cme", "jet", "epl", "outflow"]
    found_types = [t for t in types if event["type"].find(t) >= 0]
    if len(found_types) == 0: return
    event["found_type"] = found_types[0]
    print(f"type, found_type: {event['type']}, {event['found_type']}")
    event["confidence_level"] = "high" if event["found_type"].lower() == "cme" else "low"

    add_cmd_format = ("insert into MLSO.kcor_cme_alert "
                  "(obs_day, alert_type, event_type, cme_type, start_time, end_time, confidence_level, comment) "
                  "values (%(obs_day)s, 'analyst', %(type)s, %(found_type)s, %(start_datetime)s, %(end_datetime)s, %(confidence_level)s, %(comment)s)")
    cursor.execute(add_cmd_format, event)


def parse_row(row):
    start_datetime, end_datetime = parse_datetime(row[0], row[1])
    event = {"obs_day": 0, "start_datetime": start_datetime, "end_datetime": end_datetime,
        "limb": row[2], "type": row[3].lower(), "instrument": row[4],
        "comment": row[5] if len(row) > 5 else None}
    return(event)


def parse_datetime(date_expression, time_expression):
    if time_expression[0] == "-":
        d = datetime.datetime.strptime(date_expression, "%m/%d/%Y")
        return([d, d])

    times = time_expression.strip("UT").split("-")
    dts = [datetime.datetime.strptime(f"{date_expression} {t}", "%m/%d/%Y %H%M")
        for t in times]
    return(dts)


if __name__ == "__main__":
    name = "Event log ingestor"
    parser = argparse.ArgumentParser(description=name)

    parser.add_argument("--db-config-filename", "-f", help="database configuration file")
    parser.add_argument("--db-config-section", "-s", help="database configuration section")
    parser.add_argument("filename", nargs="*", type=str, help="file to ingest")

    args = parser.parse_args()

    if not db_requirements:
        args.parser.error("MySQL connector not installed")

    host, user, password = read_db_config_file(args.db_config_filename,
        args.db_config_section, error=parser.error)

    ingest(args.filename, host, user, password, error=parser.error)
