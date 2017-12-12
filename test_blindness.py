"""
Checks if the test subject is properly blinded.
"""

import click_log
import click

import logging
import datetime as dt
import re

import pandas as pd

logger = logging.getLogger(__name__)
click_log.basic_config(logger)


def orgmode_date_parser(s):
    if type(s) != str:
        raise Exception(type(s))

    match = re.match(r"<(\d+)-(\d\d)-(\d\d) [A-Z][a-z][a-z]>", s)

    date = dt.date(*[int(num_str) for num_str in match.groups()])
    return date


def check_phenibut_today(df):
    df = df[["Phenibut Blinded", "Phenibut, g", "Think Phenibut Today"]]
    df = df[(df["Phenibut Blinded"] == True) & (df["Think Phenibut Today"] != "Not Applicable")]
    df = df[pd.notnull(df["Phenibut, g"])]
    df["phenibut_not_zero"] = df["Phenibut, g"] != 0
    df["Think Phenibut Today"] = df["Think Phenibut Today"].astype(bool)
    df["correct"] = df["phenibut_not_zero"] == df["Think Phenibut Today"]
    correct = df["correct"].sum()
    total = len(df)
    percentage = correct / total
    print(
        """Think Phenibut Today:
               correct {0}/{1} ({2:.0%})"""
        .format(correct, total, percentage)
    )


@click.command(help=__doc__)
@click_log.simple_verbosity_option(logger)
@click.argument("CSV", type=click.File("r", "utf-8"))
@click.option("--skip_last_lines", "-l", type=int, required=True)
def main(csv, skip_last_lines):
    df = pd.read_csv(
        csv,
        dtype={"Date": str},
        skip_blank_lines=True,
        parse_dates=["Date"],
        date_parser=orgmode_date_parser,
        skipfooter=skip_last_lines,
        engine="python"
    )
    filled_rows = df[df["Date"] != "NaN"]
    #print(filled_rows)
    unique_blinded = frozenset(df["Phenibut Blinded"].unique())
    if unique_blinded != frozenset([True, False]):
        raise ValueError("unique_blinded = {0}".format(unique_blinded))
    assert df["Phenibut Blinded"].dtype == bool

    unique_tpt = frozenset(df["Think Phenibut Today"].unique())
    if unique_tpt != frozenset(["True", "False", "Not Applicable"]):
        raise ValueError("unique Think Phenibut Today = {0}".format(unique_tpt))
    
    check_phenibut_today(df)

if __name__ == '__main__':
    main()
