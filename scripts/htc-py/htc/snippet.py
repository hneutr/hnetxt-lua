import subprocess

import htc.constants

def run_quote():
    subprocess.run(
        htc.constants.RUN_X_OF_THE_DAY_COMMAND
        shell=True,
        check=True,
        env=htc.constants.RUN_X_OF_THE_DAY_ENV,
    )
